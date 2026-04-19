local mq           = require('mq')
local Logger       = require('utils.logger')

local Signatures   = {}

local registry     = nil
local CACHE_FILE   = mq.configDir .. '/rgmercs/signatures_cache.lua'

local SOURCE_FILES = {
    { prefix = 'Combat',      path = mq.luaDir .. '/rgmercs/utils/combat.lua', },
    { prefix = 'Targeting',   path = mq.luaDir .. '/rgmercs/utils/targeting.lua', },
    { prefix = 'Core',        path = mq.luaDir .. '/rgmercs/utils/core.lua', },
    { prefix = 'Casting',     path = mq.luaDir .. '/rgmercs/utils/casting.lua', },
    { prefix = 'Movement',    path = mq.luaDir .. '/rgmercs/utils/movement.lua', },
    { prefix = 'Comms',       path = mq.luaDir .. '/rgmercs/utils/comms.lua', },
    { prefix = 'Config',      path = mq.luaDir .. '/rgmercs/utils/config.lua', },
    { prefix = 'ItemManager', path = mq.luaDir .. '/rgmercs/utils/item_manager.lua', },
    { prefix = 'Math',        path = mq.luaDir .. '/rgmercs/utils/math.lua', },
    { prefix = 'Rotation',    path = mq.luaDir .. '/rgmercs/utils/rotation.lua', },
    { prefix = 'Strings',     path = mq.luaDir .. '/rgmercs/utils/strings.lua', },
    { prefix = 'Tables',      path = mq.luaDir .. '/rgmercs/utils/tables.lua', },
    { prefix = 'Ui',          path = mq.luaDir .. '/rgmercs/utils/ui.lua', },
}

local function parseFile(path, out)
    local f = io.open(path, 'r')
    if not f then return end

    local pendingDesc   = nil
    local pendingParams = {}
    local pendingRet    = nil
    local inBlock       = false

    for line in f:lines() do
        local commentBody = line:match('^%s*%-%-%-%s?(.*)')
        if commentBody ~= nil then
            inBlock = true
            local pName, pType = commentBody:match('^@param%s+(%S+)%s+(%S+)')
            if pName then
                pendingParams[#pendingParams + 1] = { name = pName, type = pType, }
            else
                local rType = commentBody:match('^@return%s+(%S+)')
                if rType then
                    pendingRet = rType
                elseif commentBody ~= '' and not commentBody:match('^@') and pendingDesc == nil then
                    pendingDesc = commentBody
                end
            end
        else
            if inBlock then
                -- function Foo.Bar(...) or function Foo:Bar(...)
                local funcName = line:match('^function%s+([A-Za-z][A-Za-z0-9_.]+)%s*%(')
                if not funcName then
                    -- colon method: normalize Foo:Bar -> Foo.Bar
                    local obj, meth = line:match('^function%s+([A-Za-z][A-Za-z0-9_]*)%:([A-Za-z][A-Za-z0-9_]*)%s*%(')
                    if obj and meth then funcName = obj .. '.' .. meth end
                end
                if funcName and (#pendingParams > 0 or pendingRet ~= nil) then
                    out[funcName] = {
                        desc   = pendingDesc,
                        params = pendingParams,
                        ret    = pendingRet,
                    }
                end
            end
            -- reset regardless
            pendingDesc   = nil
            pendingParams = {}
            pendingRet    = nil
            inBlock       = false
        end
    end
    f:close()
end

local function buildRegistry()
    local out = {}
    for _, entry in ipairs(SOURCE_FILES) do
        Logger.log_verbose("Signatures: parsing %s", entry.path)
        parseFile(entry.path, out)
    end
    return out
end

-- Static builtins — never cached, merged in at load time.
local BUILTINS = {
    -- Lua globals
    ['print']           = { desc = 'Print values to stdout.', params = { { name = '...', type = 'any', }, }, ret = nil, },
    ['printf']          = { desc = 'Print a formatted string to the console.', params = { { name = 'format', type = 'string', }, { name = '...', type = 'any', }, }, ret = nil, },
    ['tostring']        = { desc = 'Convert a value to string.', params = { { name = 'v', type = 'any', }, }, ret = 'string', },
    ['tonumber']        = { desc = 'Convert a value to number.', params = { { name = 'e', type = 'any', }, { name = 'base', type = 'number?', }, }, ret = 'number|nil', },
    ['type']            = { desc = 'Return the type name of a value.', params = { { name = 'v', type = 'any', }, }, ret = 'string', },
    ['ipairs']          = { desc = 'Iterator for integer-keyed table entries.', params = { { name = 't', type = 'table', }, }, ret = 'function', },
    ['pairs']           = { desc = 'Iterator for all table entries.', params = { { name = 't', type = 'table', }, }, ret = 'function', },
    ['pcall']           = { desc = 'Call function in protected mode.', params = { { name = 'f', type = 'function', }, { name = '...', type = 'any', }, }, ret = 'boolean,...', },
    ['xpcall']          = { desc = 'Call function with a message handler.', params = { { name = 'f', type = 'function', }, { name = 'msgh', type = 'function', }, { name = '...', type = 'any', }, }, ret = 'boolean,...', },
    ['error']           = { desc = 'Raise an error.', params = { { name = 'message', type = 'any', }, { name = 'level', type = 'number?', }, }, ret = nil, },
    ['assert']          = { desc = 'Assert a condition or raise an error.', params = { { name = 'v', type = 'any', }, { name = 'message', type = 'any?', }, }, ret = 'any', },
    ['select']          = { desc = 'Return args from index or count of args.', params = { { name = 'index', type = 'number|string', }, { name = '...', type = 'any', }, }, ret = 'any', },
    ['unpack']          = { desc = 'Unpack table elements as return values.', params = { { name = 't', type = 'table', }, { name = 'i', type = 'number?', }, { name = 'j', type = 'number?', }, }, ret = '...', },
    ['rawget']          = { desc = 'Get table value bypassing __index.', params = { { name = 't', type = 'table', }, { name = 'k', type = 'any', }, }, ret = 'any', },
    ['rawset']          = { desc = 'Set table value bypassing __newindex.', params = { { name = 't', type = 'table', }, { name = 'k', type = 'any', }, { name = 'v', type = 'any', }, }, ret = 'table', },
    ['rawequal']        = { desc = 'Equality check bypassing __eq.', params = { { name = 'v1', type = 'any', }, { name = 'v2', type = 'any', }, }, ret = 'boolean', },
    ['rawlen']          = { desc = 'Length of table or string bypassing __len.', params = { { name = 'v', type = 'table|string', }, }, ret = 'number', },
    ['setmetatable']    = { desc = 'Set the metatable of a table.', params = { { name = 'table', type = 'table', }, { name = 'metatable', type = 'table|nil', }, }, ret = 'table', },
    ['getmetatable']    = { desc = 'Get the metatable of an object.', params = { { name = 'object', type = 'any', }, }, ret = 'table|nil', },
    ['load']            = { desc = 'Load a Lua chunk from a string or function.', params = { { name = 'chunk', type = 'string|function', }, { name = 'chunkname', type = 'string?', }, { name = 'mode', type = 'string?', }, { name = 'env', type = 'table?', }, }, ret = 'function|nil,string', },
    ['dofile']          = { desc = 'Execute a Lua file.', params = { { name = 'filename', type = 'string?', }, }, ret = 'any', },
    ['require']         = { desc = 'Load and return a module.', params = { { name = 'modname', type = 'string', }, }, ret = 'any', },
    ['collectgarbage']  = { desc = 'Control the garbage collector.', params = { { name = 'opt', type = 'string?', }, { name = 'arg', type = 'number?', }, }, ret = 'any', },

    -- string.*
    ['string.format']   = { desc = 'Format a string using printf-style specifiers.', params = { { name = 'format', type = 'string', }, { name = '...', type = 'any', }, }, ret = 'string', },
    ['string.find']     = { desc = 'Find pattern in string, return start/end positions.', params = { { name = 's', type = 'string', }, { name = 'pattern', type = 'string', }, { name = 'init', type = 'number?', }, { name = 'plain', type = 'boolean?', }, }, ret = 'number|nil,number|nil', },
    ['string.match']    = { desc = 'Match pattern in string, return captures.', params = { { name = 's', type = 'string', }, { name = 'pattern', type = 'string', }, { name = 'init', type = 'number?', }, }, ret = 'string|nil,...', },
    ['string.gmatch']   = { desc = 'Iterator over all pattern matches.', params = { { name = 's', type = 'string', }, { name = 'pattern', type = 'string', }, }, ret = 'function', },
    ['string.gsub']     = { desc = 'Replace pattern matches in string.', params = { { name = 's', type = 'string', }, { name = 'pattern', type = 'string', }, { name = 'repl', type = 'string|table|function', }, { name = 'n', type = 'number?', }, }, ret = 'string,number', },
    ['string.sub']      = { desc = 'Extract a substring.', params = { { name = 's', type = 'string', }, { name = 'i', type = 'number', }, { name = 'j', type = 'number?', }, }, ret = 'string', },
    ['string.len']      = { desc = 'Return the length of a string.', params = { { name = 's', type = 'string', }, }, ret = 'number', },
    ['string.lower']    = { desc = 'Convert string to lowercase.', params = { { name = 's', type = 'string', }, }, ret = 'string', },
    ['string.upper']    = { desc = 'Convert string to uppercase.', params = { { name = 's', type = 'string', }, }, ret = 'string', },
    ['string.rep']      = { desc = 'Repeat a string n times.', params = { { name = 's', type = 'string', }, { name = 'n', type = 'number', }, { name = 'sep', type = 'string?', }, }, ret = 'string', },
    ['string.reverse']  = { desc = 'Reverse a string.', params = { { name = 's', type = 'string', }, }, ret = 'string', },
    ['string.byte']     = { desc = 'Return byte values of string characters.', params = { { name = 's', type = 'string', }, { name = 'i', type = 'number?', }, { name = 'j', type = 'number?', }, }, ret = 'number,...', },
    ['string.char']     = { desc = 'Return string from byte values.', params = { { name = '...', type = 'number', }, }, ret = 'string', },
    ['string.dump']     = { desc = 'Return binary representation of a function.', params = { { name = 'function', type = 'function', }, { name = 'strip', type = 'boolean?', }, }, ret = 'string', },

    -- table.*
    ['table.insert']    = { desc = 'Insert element into table.', params = { { name = 't', type = 'table', }, { name = 'pos', type = 'number?', }, { name = 'value', type = 'any', }, }, ret = nil, },
    ['table.remove']    = { desc = 'Remove and return element from table.', params = { { name = 't', type = 'table', }, { name = 'pos', type = 'number?', }, }, ret = 'any', },
    ['table.sort']      = { desc = 'Sort table elements in-place.', params = { { name = 't', type = 'table', }, { name = 'comp', type = 'function?', }, }, ret = nil, },
    ['table.concat']    = { desc = 'Concatenate table elements into a string.', params = { { name = 't', type = 'table', }, { name = 'sep', type = 'string?', }, { name = 'i', type = 'number?', }, { name = 'j', type = 'number?', }, }, ret = 'string', },
    ['table.unpack']    = { desc = 'Unpack table elements as return values.', params = { { name = 't', type = 'table', }, { name = 'i', type = 'number?', }, { name = 'j', type = 'number?', }, }, ret = '...', },
    ['table.move']      = { desc = 'Move elements between tables.', params = { { name = 'a1', type = 'table', }, { name = 'f', type = 'number', }, { name = 'e', type = 'number', }, { name = 't', type = 'number', }, { name = 'a2', type = 'table?', }, }, ret = 'table', },

    -- math.*
    ['math.abs']        = { desc = 'Absolute value.', params = { { name = 'x', type = 'number', }, }, ret = 'number', },
    ['math.ceil']       = { desc = 'Round up to nearest integer.', params = { { name = 'x', type = 'number', }, }, ret = 'number', },
    ['math.floor']      = { desc = 'Round down to nearest integer.', params = { { name = 'x', type = 'number', }, }, ret = 'number', },
    ['math.sqrt']       = { desc = 'Square root.', params = { { name = 'x', type = 'number', }, }, ret = 'number', },
    ['math.max']        = { desc = 'Maximum of given values.', params = { { name = 'x', type = 'number', }, { name = '...', type = 'number', }, }, ret = 'number', },
    ['math.min']        = { desc = 'Minimum of given values.', params = { { name = 'x', type = 'number', }, { name = '...', type = 'number', }, }, ret = 'number', },
    ['math.fmod']       = { desc = 'Floating point modulo.', params = { { name = 'x', type = 'number', }, { name = 'y', type = 'number', }, }, ret = 'number', },
    ['math.modf']       = { desc = 'Return integer and fractional parts.', params = { { name = 'x', type = 'number', }, }, ret = 'number,number', },
    ['math.sin']        = { desc = 'Sine (radians).', params = { { name = 'x', type = 'number', }, }, ret = 'number', },
    ['math.cos']        = { desc = 'Cosine (radians).', params = { { name = 'x', type = 'number', }, }, ret = 'number', },
    ['math.tan']        = { desc = 'Tangent (radians).', params = { { name = 'x', type = 'number', }, }, ret = 'number', },
    ['math.atan']       = { desc = 'Arc tangent. Pass y,x for atan2 behavior.', params = { { name = 'y', type = 'number', }, { name = 'x', type = 'number?', }, }, ret = 'number', },
    ['math.exp']        = { desc = 'e raised to the power x.', params = { { name = 'x', type = 'number', }, }, ret = 'number', },
    ['math.log']        = { desc = 'Logarithm, default base e.', params = { { name = 'x', type = 'number', }, { name = 'base', type = 'number?', }, }, ret = 'number', },
    ['math.pow']        = { desc = 'x raised to the power y.', params = { { name = 'x', type = 'number', }, { name = 'y', type = 'number', }, }, ret = 'number', },
    ['math.random']     = { desc = 'Random number. No args: [0,1). One arg: [1,m]. Two args: [m,n].', params = { { name = 'm', type = 'number?', }, { name = 'n', type = 'number?', }, }, ret = 'number', },
    ['math.randomseed'] = { desc = 'Set random seed.', params = { { name = 'x', type = 'number', }, }, ret = nil, },
    ['math.huge']       = { desc = 'Positive infinity constant.', params = {}, ret = 'number', },
    ['math.pi']         = { desc = 'Pi constant (3.14159...).', params = {}, ret = 'number', },

    -- os.*
    ['os.time']         = { desc = 'Return current time as Unix timestamp.', params = { { name = 'table', type = 'table?', }, }, ret = 'number', },
    ['os.date']         = { desc = 'Format date/time as string or table.', params = { { name = 'format', type = 'string?', }, { name = 'time', type = 'number?', }, }, ret = 'string|table', },
    ['os.clock']        = { desc = 'CPU time used by program in seconds.', params = {}, ret = 'number', },
    ['os.difftime']     = { desc = 'Difference in seconds between two times.', params = { { name = 't2', type = 'number', }, { name = 't1', type = 'number', }, }, ret = 'number', },

    -- io.*
    ['io.open']         = { desc = 'Open a file, return file handle.', params = { { name = 'filename', type = 'string', }, { name = 'mode', type = 'string?', }, }, ret = 'file|nil,string', },
    ['io.close']        = { desc = 'Close a file handle.', params = { { name = 'file', type = 'file?', }, }, ret = 'boolean', },
    ['io.read']         = { desc = 'Read from default input.', params = { { name = '...', type = 'string|number', }, }, ret = 'string|nil', },
    ['io.write']        = { desc = 'Write to default output.', params = { { name = '...', type = 'string|number', }, }, ret = 'file', },
}

local function currentVersion()
    local Config = require('utils.config')
    local base = Config._version .. '-' .. Config._subVersion
    -- include source list so adding files or annotations busts the cache
    local parts = {}
    for _, entry in ipairs(SOURCE_FILES) do
        parts[#parts + 1] = entry.prefix
    end
    return base .. '-' .. table.concat(parts, ',')
end

local function loadCache()
    local f = io.open(CACHE_FILE, 'r')
    if not f then return nil end
    f:close()
    local ok, data = pcall(dofile, CACHE_FILE)
    if ok and type(data) == 'table' then return data end
    return nil
end

local function saveCache(version, sigs)
    mq.pickle(CACHE_FILE, { version = version, signatures = sigs, })
end

--- Load signatures from cache or by parsing source files.
--- Call once after Config is available.
function Signatures.Load()
    if registry then return end
    local version = currentVersion()
    local cached  = loadCache()
    if cached and cached.version == version then
        registry = cached.signatures
    else
        Logger.log_verbose("Signatures: cache miss or version change, parsing sources...")
        registry = buildRegistry()
        saveCache(version, registry)
        local count = 0
        for _ in pairs(registry) do count = count + 1 end
        Logger.log_verbose("Signatures: built registry with %d entries, cached as v%s", count, version)
    end
    -- Builtins are static — merge in every time, never cached.
    for k, v in pairs(BUILTINS) do
        registry[k] = v
    end
end

--- Returns the signature registry table. Signatures.Load() must have been called first.
--- @return table
function Signatures.Get()
    return registry or {}
end

--- Given editor text and cursor offset, returns the module prefix and partial name
--- if the cursor is positioned right after "Prefix." or "Prefix.partial".
--- Returns nil, nil if not at a completion trigger point.
--- @param text      string
--- @param cursorIdx number  0-based byte offset
--- @return string|nil, string|nil
function Signatures.ResolveCompletion(text, cursorIdx)
    local sub   = text:sub(1, cursorIdx)
    -- grab the last token on this line (stops at newline, space, operators, etc.)
    local token = sub:match('([A-Za-z][A-Za-z0-9_.]*)$')
    if not token then return nil, nil end
    local prefix, partial = token:match('^([A-Za-z][A-Za-z0-9_]*)%.([A-Za-z0-9_]*)$')
    if not prefix then return nil, nil end
    -- If the character immediately after the cursor continues the identifier or opens a call,
    -- the token is already fully completed — don't offer the dropdown.
    local nextCh = text:sub(cursorIdx + 1, cursorIdx + 1)
    if nextCh:match('[A-Za-z0-9_(]') then return nil, nil end
    return prefix, partial
end

--- Returns a list of completion candidates for the given prefix and optional partial name.
--- Each entry is { full=string, name=string, sig=table }.
--- @param prefix  string
--- @param partial string|nil
--- @return table
function Signatures.Complete(prefix, partial)
    local results = {}
    local lowerPartial = (partial or ""):lower()
    for key, sig in pairs(Signatures.Get()) do
        local keyPrefix, keyName = key:match('^([A-Za-z][A-Za-z0-9_]*)%.(.+)$')
        if keyPrefix == prefix then
            if partial == '' or keyName:lower():sub(1, #lowerPartial) == lowerPartial then
                results[#results + 1] = { full = key, name = keyName, sig = sig, }
            end
        end
    end
    table.sort(results, function(a, b) return a.name < b.name end)
    return results
end

--- Given the full editor text and a 0-based cursor byte offset, returns all
--- enclosing function call candidates from innermost to outermost. Each entry
--- is { name=string, paramIdx=number }. Caller picks the first with a known sig.
--- @param text      string
--- @param cursorIdx number  0-based byte offset
--- @return table
function Signatures.ResolveAll(text, cursorIdx)
    local sub       = text:sub(1, cursorIdx)
    local results   = {}
    local depth     = 0
    local commas    = 0
    local scanEnd   = #sub
    local scanStart = math.max(1, scanEnd - 2000)

    for i = scanEnd, scanStart, -1 do
        local ch = sub:sub(i, i)
        if ch == ')' then
            depth = depth + 1
        elseif ch == '(' then
            if depth > 0 then
                depth = depth - 1
            else
                -- found an unclosed '(' — extract identifier immediately before it
                -- normalize ':' method calls to '.' so Config:Foo -> Config.Foo
                local before = sub:sub(1, i - 1):match('([A-Za-z][A-Za-z0-9_.:]*)%s*$')
                if before then
                    before = before:gsub(':', '.')
                    results[#results + 1] = { name = before, paramIdx = commas + 1, }
                end
                -- reset for the next outer enclosing call
                commas = 0
                depth  = 0
            end
        elseif ch == ',' and depth == 0 then
            commas = commas + 1
        end
    end

    return results
end

--- Given the full editor text and a 0-based cursor byte offset, returns the function
--- name the cursor is inside and the 1-based active parameter index, or nil, nil.
--- Checks innermost enclosing call first; falls back to outer calls if innermost
--- has no registered signature.
--- @param text      string
--- @param cursorIdx number  0-based byte offset
--- @return string|nil, number|nil
function Signatures.Resolve(text, cursorIdx)
    local candidates = Signatures.ResolveAll(text, cursorIdx)
    if #candidates == 0 then return nil, nil end
    -- Return innermost candidate unconditionally; caller decides if sig exists.
    -- If caller wants fallback it should use ResolveAll directly.
    local c = candidates[1]
    return c.name, c.paramIdx
end

return Signatures
