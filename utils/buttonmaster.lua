local mq                       = require('mq')
local Comms                    = require('utils.comms')
local Config                   = require('utils.config')
local ConfigShare              = require('utils.rg_config_share')
local Globals                  = require('utils.globals')
local Tables                   = require('utils.tables')

local ButtonMaster             = { _version = '1.0', _name = "ButtonMaster", _author = 'Derple', }

ButtonMaster.Library           = require('extras.buttonmaster_sets')
ButtonMaster.SortedSetNames    = nil
ButtonMaster.SourceCharacters  = {
    { Name = "Algarshd", Label = "MainTank", Classes = { "WAR", "SHD", "PAL", }, ExclusiveGroup = "Tank", },
    { Name = "Algarpal", Label = "Offtank", Classes = { "PAL", "SHD", "WAR", }, ExclusiveGroup = "Tank", },
    { Name = "Algarclr", Label = "Cleric", Classes = { "CLR", }, },
    { Name = "Algardru", Label = "Druid", Classes = { "DRU", }, },
    { Name = "Algarenc", Label = "Enchanter", Classes = { "ENC", }, },
    { Name = "Algarnec", Label = "Necromancer", Classes = { "NEC", }, },
    { Name = "Algarshm", Label = "Shaman", Classes = { "SHM", }, },
    { Name = "Algarwar", Label = "Warrior", Classes = { "WAR", }, },
}

for _, character in ipairs(ButtonMaster.SourceCharacters) do
    character.Pattern = "%f[%w]" .. character.Name:gsub("%a", function(letter) return string.format("[%s%s]", letter:lower(), letter:upper()) end) .. "%f[%W]"
end

local function sendImport(object)
    Comms.Actors.send({ script = 'buttonmaster', server = Globals.CurServer, character = mq.TLO.Me.DisplayName(), },
                      { script = "ButtonMaster", from = "RGMercs", event = "ImportObject", object = object, })
end

function ButtonMaster.IsRunning()
    return mq.TLO.Lua.Script('buttonmaster').Status() == 'RUNNING'
end

function ButtonMaster.GetSortedSetNames()
    if not ButtonMaster.SortedSetNames then
        ButtonMaster.SortedSetNames = {}
        for setName in pairs(ButtonMaster.Library.Sets) do
            table.insert(ButtonMaster.SortedSetNames, setName)
        end
        table.sort(ButtonMaster.SortedSetNames)
    end
    return ButtonMaster.SortedSetNames
end

function ButtonMaster.GetSetButtons(setName)
    local setButtons = {}
    for index, buttonKey in pairs(ButtonMaster.Library.Sets[setName] or {}) do
        if ButtonMaster.Library.Buttons[buttonKey] then
            table.insert(setButtons, { Index = index, Key = buttonKey, Button = ButtonMaster.Library.Buttons[buttonKey], })
        end
    end
    table.sort(setButtons, function(a, b) return a.Index < b.Index end)
    return setButtons
end

function ButtonMaster.GetResolvedButton(buttonKey)
    local button = Tables.DeepCopy(ButtonMaster.Library.Buttons[buttonKey])
    button.Cmd = button.Cmd:gsub("/ss%f[ /] *", "/rgl smartsend ")
    local characterNames = ButtonMaster.GetCharacterNames()
    for _, character in ipairs(ButtonMaster.SourceCharacters) do
        local replacement = characterNames[character.Name] or ""
        if replacement:len() > 0 then
            button.Cmd = button.Cmd:gsub(character.Pattern, replacement)
        end
    end
    return button
end

function ButtonMaster.GetButtonShareCode(buttonKey)
    return ConfigShare.ExportConfig({ Type = "Button", Button = ButtonMaster.GetResolvedButton(buttonKey), })
end

function ButtonMaster.GetCharacterNames()
    return Config:GetSetting('ButtonMasterNames') or {}
end

function ButtonMaster.SetCharacterName(sourceName, newName)
    local characterNames = Tables.DeepCopy(ButtonMaster.GetCharacterNames())
    characterNames[sourceName] = newName:len() > 0 and newName or nil
    Config:SetSetting('ButtonMasterNames', characterNames)
end

function ButtonMaster.AutoDetectCharacterNames()
    local peers = Comms.GetPeers(true)
    table.sort(peers)

    local characterNames = Tables.DeepCopy(ButtonMaster.GetCharacterNames())
    local detectedCount = 0
    local usedPeers = {}
    for _, character in ipairs(ButtonMaster.SourceCharacters) do
        local groupUsedPeers = character.ExclusiveGroup and (usedPeers[character.ExclusiveGroup] or {}) or {}
        local detectedPeer = nil
        for _, class in ipairs(character.Classes) do
            for _, peer in ipairs(peers) do
                local heartbeat = Comms.GetPeerHeartbeat(peer).Data or {}
                if heartbeat.Server == Globals.CurServer and heartbeat.Class == class and not groupUsedPeers[peer] then
                    detectedPeer = peer
                    characterNames[character.Name] = heartbeat.Name
                    break
                end
            end
            if detectedPeer then break end
        end

        if detectedPeer then
            detectedCount = detectedCount + 1
            if character.ExclusiveGroup then
                groupUsedPeers[detectedPeer] = true
                usedPeers[character.ExclusiveGroup] = groupUsedPeers
            end
        end
    end

    if detectedCount > 0 then
        Config:SetSetting('ButtonMasterNames', characterNames)
    end
    return detectedCount
end

function ButtonMaster.ImportSet(setName)
    local sharableSet = { Type = "Set", Key = setName, Set = {}, Buttons = {}, }
    for _, entry in ipairs(ButtonMaster.GetSetButtons(setName)) do
        sharableSet.Set[entry.Index] = entry.Key
        sharableSet.Buttons[entry.Key] = ButtonMaster.GetResolvedButton(entry.Key)
    end
    sendImport(sharableSet)
end

function ButtonMaster.ImportButton(buttonKey)
    sendImport({ Type = "Button", Button = ButtonMaster.GetResolvedButton(buttonKey), })
end

return ButtonMaster
