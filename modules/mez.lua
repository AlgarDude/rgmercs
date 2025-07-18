-- Sample Basic Class Module
local mq        = require('mq')
local Config    = require('utils.config')
local Combat    = require("utils.combat")
local Core      = require("utils.core")
local Targeting = require("utils.targeting")
local Casting   = require("utils.casting")
local Ui        = require("utils.ui")
local Comms     = require("utils.comms")
local Modules   = require("utils.modules")
local Strings   = require("utils.strings")
local Tables    = require("utils.tables")
local Files     = require("utils.files")
local Logger    = require("utils.logger")
local Set       = require("mq.Set")
local Icons     = require('mq.ICONS')

require('utils.datatypes')

local Module                   = { _version = '0.1a', _name = "Mez", _author = 'Derple', }
Module.__index                 = Module

Module.ModuleLoaded            = false
Module.CombatState             = "None"

Module.TempSettings            = {}
Module.TempSettings.MezImmune  = {}
Module.TempSettings.MezTracker = {}
Module.FAQ                     = {}
Module.ClassFAQ                = {}

Module.DefaultConfig           = {
    -- [ MEZ ] --
    ['MezAECount']                             = {
        DisplayName = "Mez AE Count",
        Category = "Mez",
        Tooltip = "Mez if you have at least [X] on xtarget",
        FAQ = "How do I set my AE mes limits?",
        Answer = "Set your [MezAECount] Setting to the minimum number of Mobs on Xtarget before using AE Mez.",
        Default = 3,
        Min = 1,
        Max = 20,
    },
    ['MezOn']                                  = {
        DisplayName = "Enable Mezzing",
        Category = "Mez",
        Default = true,
        Tooltip = "Enables mezzing all forms of mezzing as a quick toggle, select particular actions to use below.",
        FAQ = "How do I turn on Mez?",
        Answer = "Toggle [MezOn] to the on position.",
    },
    ['DoSTMez']                                = {
        DisplayName = "ST Mez Song/Spells",
        Category = "Mez",
        Default = true,
        Tooltip = "Set to enable use of ST mez spells/songs.",
        RequiresLoadoutChange = true,
        FAQ = "How come my character is only using the AE Mez?",
        Answer = "To use Single Target mez turn on [DoSTMez].",
    },
    ['DoAEMez']                                = {
        DisplayName = "AE Mez Song/Spells",
        Category = "Mez",
        Default = true,
        Tooltip = "Set to enable use of AE mez spells/songs.",
        RequiresLoadoutChange = true,
        FAQ = "How come my character is only using the ST Mez?",
        Answer = "To use AE mez turn on AE Mez in the mez options..",
    },
    ['DoAAMez']                                = {
        DisplayName = "Use Mez AA",
        Category = "Mez",
        Default = true,
        Tooltip = "Use Beam of Slumber(ENC) or Dirge of the Sleepwalker(BRD) when able.",
        FAQ = "Why am I not using XXX AA to mez?",
        Answer = "Currently Beam of Slumber and Dirge of the Sleepwalker are supported. Feedback is always welcome!",
    },
    ['MezStartCount']                          = {
        DisplayName = "Mez Start Count",
        Category = "Mez",
        Default = 2,
        Min = 1,
        Max = 20,
        Tooltip = "Sets # of mobs needed to start using Mez spells. ( Default 2 )",
        FAQ = "How do I control when to cast Mez?",
        Answer = "You can adjust your [MezStartCount] to set how many mobs are on XTarget before casting Mez spells",
    },
    ['MaxMezCount']                            = {
        DisplayName = "Max Mez Count",
        Category = "Mez",
        Default = 13,
        Min = 1,
        Max = 20,
        Tooltip = "Maximum # of mobs to CC ( Default is 13 )",
        FAQ = "My Character stops mezzing and there are still mobs in camp, why?",
        Answer = "You may hae the [MaxMezCount] set too low, increase it to allow more mobs to be mezzed. (max value = 20)",
    },
    ['MezRadius']                              = {
        DisplayName = "Mez Radius",
        Category = "Mez Range",
        Default = 100,
        Min = 1,
        Max = 200,
        Tooltip = "Radius for mobs to be in to start Mezing, An area twice this size is monitored for aggro mobs",
        FAQ = "I keep trying to mez mobs that are too far away, how do I fix this?",
        Answer = "Adnust your [MezRadius] to the distance you want to start mezzing mobs.",
    },
    ['MezZRadius']                             = {
        DisplayName = "Mez ZRadius",
        Category = "Mez Range",
        Default = 15,
        Min = 1,
        Max = 200,
        Tooltip =
        "Height radius (z-value) for mobs to be in to start mezzing. An area twice this size is monitored for aggro mobs. If you're enchanter is not mezzing on hills -- increase this value.",
        FAQ = "I can't get my enchanter to mez mobs on hills, how do I fix this?",
        Answer = "Adjust your [MezZRadius] to the height above/below you want to start mezzing mobs.",
    },
    ['AutoLevelRange']                         = {
        DisplayName = "Auto Level Range",
        Category = "Mez Target",
        Default = true,
        Tooltip = "Set to enable automatic mez level detection based on spells.",
        FAQ = "I'm Lazy and hate updating my thresholds. How do I make my character do it for me?",
        Answer = "Turning on [AutoLevelRange] will automatically adjust the level range for mezzing based on the spells you have.",
    },
    ['MezMinLevel']                            = {
        DisplayName = "Mez Min Level",
        Category = "Mez Target",
        Default = 0,
        Min = 1,
        Max = 200,
        Tooltip = "Minimum Level a mob must be to Mez - Below this lvl are ignored. 0 means no mobs ignored. NOTE: AutoLevelRange must be OFF!",
        ConfigType = "Advanced",
        FAQ = "Why do I keep mezzing the Grey con mobs?",
        Answer = "You may have your [MezMinLevel] set too low, increase it to avoid mezzing grey con mobs.",
    },
    ['MezMaxLevel']                            = {
        DisplayName = "Mez Max Level",
        Category = "Mez Target",
        Default = 0,
        Min = 1,
        Max = 200,
        Tooltip = "Maximum Level a mob must be to Mez - Above this lvl are ignored. 0 means no mobs ignored. NOTE: AutoLevelRange must be OFF!",
        ConfigType = "Advanced",
        FAQ = "Why won't my enchanter mez this mob? His new spell should work on it.",
        Answer = "You most likely have [AutoLevelRange] turned off and forgot to increase the [MezMaxLevel] to the max for this spell.",
    },
    ['MezStopHPs']                             = {
        DisplayName = "Mez Stop HPs",
        Category = "Mez Target",
        Default = 80,
        Min = 1,
        Max = 100,
        Tooltip = "Mob HP% to stop trying to mez",
        FAQ = "I keep trying to mez mobs that are about to die -- how do I fix this?",
        Answer = "Adjust your [MezStopHPs] to the HP% you want to stop trying to mez mobs.",
    },
    ['SafeAEMez']                              = {
        DisplayName = "AE Mez Safety Check",
        Category = "Mez",
        Index = 3,
        Tooltip =
        "Check to ensure there aren't neutral mobs in range we could aggro if AE mez is used. May result in non-use due to false positives.",
        Default = false,
        FAQ = "Can you better explain the AE Mez Safety Check?",
        Answer = "If the option is enabled, the script will use various checks to determine if a non-hostile or not-aggroed NPC is present and avoid use of the mez.\n" ..
            "Unfortunately, the script currently cannot always discern whether an NPC is (un)attackable, so at times this may lead to the mez not being used when it is safe to do so.",
    },
    [string.format("%s_Popped", Module._name)] = {
        DisplayName = Module._name .. " Popped",
        Type = "Custom",
        Category = "Custom",
        Tooltip = Module._name .. " Pop Out Into Window",
        Default = false,
        FAQ = "Can I pop out the " .. Module._name .. " module into its own window?",
        Answer =
        "You can set the click the popout button at the top of a tab or heading to pop it into its own window.\n Simply close the window and it will snap back to the main window.",
    },
}

Module.DefaultCategories       = Set.new({})
for k, v in pairs(Module.DefaultConfig) do
    if v.Type ~= "Custom" then
        Module.DefaultCategories:add(v.Category)
    end
    Module.FAQ[k] = { Question = v.FAQ or 'None', Answer = v.Answer or 'None', Settings_Used = k, }
end

local function getConfigFileName()
    local oldFile = mq.configDir ..
        '/rgmercs/PCConfigs/' ..
        Module._name .. "_" .. Config.Globals.CurServer .. "_" .. Config.Globals.CurLoadedChar .. '.lua'
    local newFile = mq.configDir ..
        '/rgmercs/PCConfigs/' ..
        Module._name .. "_" .. Config.Globals.CurServer .. "_" .. Config.Globals.CurLoadedChar .. "_" .. Config.Globals.CurLoadedClass:lower() .. '.lua'

    if Files.file_exists(newFile) then
        return newFile
    end

    Files.copy_file(oldFile, newFile)

    return newFile
end

function Module:SaveSettings(doBroadcast)
    mq.pickle(getConfigFileName(), self.settings)

    if doBroadcast == true then
        Comms.BroadcastUpdate(self._name, "LoadSettings")
    end
end

function Module:LoadSettings()
    Logger.log_debug("\ar%s\ao Mez Module Loading Settings for: %s.", Config.Globals.CurLoadedClass,
        Config.Globals.CurLoadedChar)
    local settings_pickle_path = getConfigFileName()

    local config, err = loadfile(settings_pickle_path)
    if err or not config then
        Logger.log_error("\ay[%s]: Unable to load module settings file(%s), creating a new one!",
            Config.Globals.CurLoadedClass, settings_pickle_path)
        self.settings = {}
        self:SaveSettings(false)
    else
        self.settings = config()
    end

    if not self.settings or not self.DefaultCategories or not self.DefaultConfig then
        Logger.log_error("\arFailed to Load Mez Config for Classs: %s", Config.Globals.CurLoadedClass)
        return
    end

    local settingsChanged = false
    -- Setup Defaults
    self.settings, settingsChanged = Config.ResolveDefaults(self.DefaultConfig, self.settings)

    if settingsChanged then
        self:SaveSettings(false)
    end
end

function Module:GetSettings()
    return self.settings
end

function Module:GetDefaultSettings()
    return self.DefaultConfig
end

function Module:GetSettingCategories()
    return self.DefaultCategories
end

function Module.New()
    local newModule = setmetatable({ settings = {}, }, Module)
    return newModule
end

function Module:Init()
    Logger.log_debug("\agInitializing Mez Module...")
    self:LoadSettings()

    self.ModuleLoaded = true

    return { self = self, settings = self.settings, defaults = self.DefaultConfig, categories = self.DefaultCategories, }
end

function Module:ShouldRender()
    return Modules:ExecModule("Class", "CanMez")
end

function Module:Render()
    if not self.settings[self._name .. "_Popped"] then
        if ImGui.SmallButton(Icons.MD_OPEN_IN_NEW) then
            self.settings[self._name .. "_Popped"] = not self.settings[self._name .. "_Popped"]
            self:SaveSettings(false)
        end
        Ui.Tooltip(string.format("Pop the %s tab out into its own window.", self._name))
        ImGui.NewLine()
    end

    ---@type boolean|nil
    local pressed = false

    if self.ModuleLoaded then
        -- CCEd targets
        if ImGui.CollapsingHeader("CC Target List") then
            ImGui.Indent()
            if ImGui.BeginTable("MezzedList", 4, bit32.bor(ImGuiTableFlags.Resizable, ImGuiTableFlags.Borders)) then
                ImGui.PushStyleColor(ImGuiCol.Text, 1.0, 0.0, 1.0, 1)
                ImGui.TableSetupColumn('Id', (ImGuiTableColumnFlags.WidthFixed), 70.0)
                ImGui.TableSetupColumn('Duration', (ImGuiTableColumnFlags.WidthFixed), 150.0)
                ImGui.TableSetupColumn('Name', (ImGuiTableColumnFlags.WidthFixed), 250.0)
                ImGui.TableSetupColumn('Spell', (ImGuiTableColumnFlags.WidthStretch), 150.0)
                ImGui.PopStyleColor()
                ImGui.TableHeadersRow()
                for id, data in pairs(self.TempSettings.MezTracker) do
                    ImGui.TableNextColumn()
                    ImGui.Text(tostring(id))
                    ImGui.TableNextColumn()
                    if data.duration > 30000 then
                        ImGui.PushStyleColor(ImGuiCol.Text, 0.02, 0.8, 0.02, 1)
                    elseif data.duration > 15000 then
                        ImGui.PushStyleColor(ImGuiCol.Text, 0.8, 0.8, 0.02, 1)
                    else
                        ImGui.PushStyleColor(ImGuiCol.Text, 0.8, 0.02, 0.02, 1)
                    end
                    ImGui.Text(tostring(Strings.FormatTime(math.max(0, data.duration / 1000))))
                    ImGui.PopStyleColor()
                    ImGui.TableNextColumn()
                    ImGui.Text(data.name)
                    ImGui.TableNextColumn()
                    ImGui.Text(data.mez_spell)
                end
                ImGui.EndTable()
            end
            ImGui.Unindent()
        end

        ImGui.Separator()
        -- Immune targets
        if ImGui.CollapsingHeader("Immune Target List") then
            ImGui.Indent()
            if ImGui.BeginTable("Immune", 2, bit32.bor(ImGuiTableFlags.None, ImGuiTableFlags.Borders)) then
                ImGui.PushStyleColor(ImGuiCol.Text, 1.0, 0.0, 1.0, 1)
                ImGui.TableSetupColumn('Id', (ImGuiTableColumnFlags.WidthFixed), 70.0)
                ImGui.TableSetupColumn('Name', (ImGuiTableColumnFlags.WidthStretch), 250.0)
                ImGui.PopStyleColor()
                ImGui.TableHeadersRow()
                for id, data in pairs(self.TempSettings.MezImmune) do
                    ImGui.TableNextColumn()
                    ImGui.Text(tostring(id))
                    ImGui.TableNextColumn()
                    ImGui.Text(data.name)
                end
                ImGui.EndTable()
            end
            ImGui.Unindent()
        end

        ImGui.Separator()

        if ImGui.CollapsingHeader("Config Options") then
            self.settings, pressed, _ = Ui.RenderSettings(self.settings, self.DefaultConfig,
                self.DefaultCategories)
            if pressed then
                self:SaveSettings(false)
            end
        end
    end
end

function Module:Pop()
    self.settings[self._name .. "_Popped"] = not self.settings[self._name .. "_Popped"]
    self:SaveSettings(false)
end

function Module:HandleMezBroke(mobName, breakerName)
    Logger.log_debug("%s broke mez on ==> %s", breakerName, mobName)
    Comms.HandleAnnounce(string.format("\ar MEZ Broken: %s woke up \ag -> \ay %s \ag <- \ax", breakerName, mobName), Config:GetSetting('MezAnnounceGroup'),
        Config:GetSetting('MezAnnounce'))
end

function Module:AddImmuneTarget(mobId, mobData)
    if self.TempSettings.MezImmune[mobId] ~= nil then return end

    self.TempSettings.MezImmune[mobId] = mobData
end

function Module:IsMezImmune(mobId)
    return self.TempSettings.MezImmune[mobId] ~= nil
end

function Module:ResetMezStates()
    self.TempSettings.MezImmune = {}
    self.TempSettings.MezTracker = {}
end

function Module:GetMezSpell()
    if Core.MyClassIs("BRD") then
        return Modules:ExecModule("Class", "GetResolvedActionMapItem", "MezSong")
    end
    if Core.MyClassIs("ENC") and (Config:GetSetting('TwincastMez', true) or 0) > 1 then
        local twincastMez = Modules:ExecModule("Class", "GetResolvedActionMapItem", "TwinCastMez")
        if twincastMez and twincastMez() then return twincastMez end
    end
    return Modules:ExecModule("Class", "GetResolvedActionMapItem", "MezSpell")
end

function Module:GetAEMezSpell()
    if Core.MyClassIs("BRD") then
        return Modules:ExecModule("Class", "GetResolvedActionMapItem", "MezAESong")
    end

    return Modules:ExecModule("Class", "GetResolvedActionMapItem", "MezAESpell")
end

function Module:MezNow(mezId, useAE, useAA)
    -- First thing we target the mob if we haven't already targeted them.
    Core.DoCmd("/attack off")
    local currentTargetID = mq.TLO.Target.ID()

    Targeting.SetTarget(mezId, true)

    local mezSpell = self:GetMezSpell()
    local aeMezSpell = self:GetAEMezSpell()

    if useAE then
        if not aeMezSpell or not aeMezSpell() then return end
        Logger.log_debug("Performing AE MEZ --> %d", mezId)

        if not Casting.SpellReady(aeMezSpell) then
            -- previous code checked for the enchanter class, but AAready will simply return false on any other class
            -- lets only try to use beam of slumber if we are in global, since a beam may not catch everything.
            if useAA and self.settings.DoAAMez and Casting.AAReady("Beam of Slumber") then
                -- This is a beam AE so I need ot face the target and cast.
                Core.DoCmd("/face fast")
                -- Delay to wait till face finishes
                mq.delay(5)
                Comms.HandleAnnounce(string.format("\aw I AM \ar AE AA MEZZING \ag Beam of Slumber"), Config:GetSetting('MezAnnounceGroup'),
                    Config:GetSetting('MezAnnounce'))
                Casting.UseAA("Beam of Slumber", mezId)
                Comms.HandleAnnounce(string.format("\aw I JUST CAST \ar AE AA MEZ \ag Beam of Slumber"), Config:GetSetting('MezAnnounceGroup'),
                    Config:GetSetting('MezAnnounce'))
                mq.doevents()
                return
            elseif (mq.TLO.Me.GemTimer(aeMezSpell.RankName())() or -1) == 0 then
                local maxWaitToMez = 1500 + (mq.TLO.Window("CastingWindow").Open() and (mq.TLO.Me.Casting.MyCastTime() or 3000) or 0)
                while maxWaitToMez > 0 do
                    Logger.log_verbose("MEZ: Waiting for cast or movement to finish to use AE Mez.")
                    if Casting.SpellReady(aeMezSpell) then
                        break
                    end
                    mq.delay(50)
                    mq.doevents()
                    maxWaitToMez = maxWaitToMez - 50
                end
                if maxWaitToMez <= 0 and not Casting.SpellReady(aeMezSpell) then
                    Logger.log_verbose("Mez: Timeout while waiting to use AE Mez (%s).", aeMezSpell)
                    return
                end
            else
                Logger.log_verbose("Mez: Our AEMez Spell (%s) or AA does not appear to be ready.", aeMezSpell)
            end

            if Casting.SpellReady(aeMezSpell) then
                Comms.HandleAnnounce(string.format("\aw I AM \ar AE SPELL MEZZING \ag %s", aeMezSpell.RankName()), Config:GetSetting('MezAnnounceGroup'),
                    Config:GetSetting('MezAnnounce'))

                if Core.MyClassIs("brd") then
                    Casting.UseSong(aeMezSpell.RankName(), mezId, false, 2)
                else
                    Casting.UseSpell(aeMezSpell.RankName(), mezId, false, true, true, 2)
                end
                Comms.HandleAnnounce(string.format("\aw I JUST CAST \ar AE SPELL MEZ \ag %s", aeMezSpell.RankName()), Config:GetSetting('MezAnnounceGroup'),
                    Config:GetSetting('MezAnnounce'))
            end
        end
        -- In case they're mez immune
        mq.doevents()
    else
        Logger.log_debug("Performing Single Target MEZ --> %d", mezId)
        if useAA and Core.MyClassIs("brd") and Casting.AAReady("Dirge of the Sleepwalker") and self.settings.DoAAMez then
            -- Bard AA Mez is Dirge of the Sleepwalker
            -- Only bards have single target AA Mez
            -- Cast and Return
            Comms.HandleAnnounce("\aw I AM USING \ar BRD AA MEZ \ag Dirge of the Sleepwalker", Config:GetSetting('MezAnnounceGroup'),
                Config:GetSetting('MezAnnounce'))
            Casting.UseAA("Dirge of the Sleepwalker", mezId)
            Comms.HandleAnnounce("\aw I JUST CAST \ar BRD AA MEZ \ag Dirge of the Sleepwalker", Config:GetSetting('MezAnnounceGroup'),
                Config:GetSetting('MezAnnounce'))

            mq.doevents()

            if Casting.GetLastCastResultId() == Config.Constants.CastResults.CAST_SUCCESS then
                Comms.HandleAnnounce(string.format("\ar JUST MEZZED \aw -> \ay %s <- Using: \at%s",
                    mq.TLO.Spawn(mezId).CleanName(), "Dirge of the Sleepwalker"), Config:GetSetting('CharmAnnounceGroup'), Config:GetSetting('CharmAnnounce'))
            else
                Comms.HandleAnnounce(string.format("\ar MEZ Failed: \ag -> \ay %s \ag <-", mq.TLO.Spawn(mezId).CleanName()), Config:GetSetting('MezAnnounceGroup'),
                    Config:GetSetting('MezAnnounce'))
            end

            mq.doevents()

            return
        end

        if not mezSpell or not mezSpell() then return end

        if not Casting.SpellReady(mezSpell) then
            if (mq.TLO.Me.GemTimer(mezSpell.RankName())() or -1) == 0 then
                local maxWaitToMez = 1500 + (mq.TLO.Window("CastingWindow").Open() and (mq.TLO.Me.Casting.MyCastTime() or 3000) or 0)
                while maxWaitToMez > 0 do
                    Logger.log_verbose("MEZ: Waiting for cast or movement to finish to use ST Mez.")
                    if aeMezSpell and aeMezSpell() and Targeting.GetXTHaterCount() >= self.settings.MezAECount and ((mq.TLO.Me.GemTimer(aeMezSpell.RankName())() or -1) == 0 or (self.settings.DoAAMez and mq.TLO.Me.AltAbilityReady("Beam of Slumber"))) then
                        Logger.log_debug("Mez: Waiting for single mez to be ready, but high number of targets, let's check if AE Mez is needed again before we start singles.")
                        self:AEMezCheck()
                        return
                    end
                    if Casting.SpellReady(mezSpell) then
                        break
                    end
                    mq.delay(50)
                    mq.doevents()
                    maxWaitToMez = maxWaitToMez - 50
                end
                if maxWaitToMez <= 0 and not Casting.SpellReady(mezSpell) then
                    Logger.log_verbose("Mez: Timeout while waiting to use ST Mez (%s).", mezSpell)
                end
            else
                Logger.log_verbose("Mez: Our ST Mez Spell (%s) does not appear to be ready.", mezSpell)
            end
        end

        if Casting.SpellReady(mezSpell) then
            if Core.MyClassIs("brd") then
                -- TODO SongNow MezSpell
                Casting.UseSong(mezSpell.RankName(), mezId, false, 2)
            else
                -- This may not work for Bards but will work for NEC/ENCs
                Casting.UseSpell(mezSpell.RankName(), mezId, false, false, true, 2)
            end

            -- In case they're mez immune
            mq.doevents()

            if Casting.GetLastCastResultId() == Config.Constants.CastResults.CAST_SUCCESS then
                Comms.HandleAnnounce(string.format("\ar JUST MEZZED \aw -> \ay %s \aw <- Using: \at%s",
                        mq.TLO.Spawn(mezId).CleanName(), mezSpell.RankName()), Config:GetSetting('MezAnnounceGroup'),
                    Config:GetSetting('MezAnnounce'))
            else
                Comms.HandleAnnounce(string.format("\ar MEZ Failed \ag -> \ay %s \ag <-", mq.TLO.Spawn(mezId).CleanName()), Config:GetSetting('MezAnnounceGroup'),
                    Config:GetSetting('MezAnnounce'))
            end
        end

        mq.doevents()
    end

    Targeting.SetTarget(currentTargetID, true)
end

function Module:AEMezCheck()
    if not Config:GetSetting('DoAEMez') then return end

    local mezNPCFilter = string.format("npc radius %d targetable los playerstate 4", self.settings.MezRadius)
    local mezNPCPetFilter = string.format("npcpet radius %d targetable los playerstate 4", self.settings.MezRadius)
    local aeCount = mq.TLO.SpawnCount(mezNPCFilter)() + mq.TLO.SpawnCount(mezNPCPetFilter)()

    local aeMezSpell = self:GetAEMezSpell()

    if not aeMezSpell or not aeMezSpell() then return end

    if not aeMezSpell.AERange() or aeMezSpell.AERange() == 0 then
        Logger.log_warn("\arWarning AE Mez Spell: %s has no AERange!", aeMezSpell.RankName.Name())
    end

    -- Make sure the mobs of concern are within range
    if aeCount < self.settings.MezAECount then return end

    if Config:GetSetting('SafeAEMez') then --not Core.MyClassIs("brd") then
        -- Get the nearest spawn meeting our npc search criteria
        local angryMobCount = 0
        local mobCount = 999

        if Core.MyClassIs("brd") then
            --using MezRadius because our instrument-modified song range is not exposed and would require excessive code to determine (checking base(1) of focus2 itemspell and math, etc)
            angryMobCount = mq.TLO.SpawnCount(string.format("npc xtarhater radius %d", Config:GetSetting('MezRadius')))()
            mobCount = mq.TLO.SpawnCount(string.format("npc radius %d", Config:GetSetting('MezRadius')))()
        else --I think this can all be refactored to something simpler (we need to check from the AutoTarget, which is who we end up casting on), will look later. -- Algar 1/7/2025
            local nearestSpawn = mq.TLO.NearestSpawn(1, mezNPCFilter)
            if not nearestSpawn or not nearestSpawn() then
                nearestSpawn = mq.TLO.NearestSpawn(1, mezNPCPetFilter)
            end

            if not nearestSpawn or not nearestSpawn() then
                return
            end
            -- Next make sure casting our AE won't anger more mobs -- I'm lazy and not checking the AERange of the AA. I'm gonna assume if the
            -- AERange of the normal spell will piss them off, then the AA probably would too.
            angryMobCount = mq.TLO.SpawnCount(string.format("npc xtarhater loc %0.2f, %0.2f radius %d", nearestSpawn.X(),
                nearestSpawn.Y(), aeMezSpell.AERange() or 0))()
            mobCount = mq.TLO.SpawnCount(string.format("npc loc %0.2f, %0.2f radius %d", nearestSpawn.X(),
                nearestSpawn.Y(), aeMezSpell.AERange() or 0))()
        end
        if mobCount > angryMobCount then return end
    end

    self:StopCast()

    -- Call MezNow and pass the AE flag and allow it to use the AA if the Spell isn't ready.
    Logger.log_debug("\awNOTICE:\ax Re-targeting to our main assist's mob.")

    if Combat.FindBestAutoTargetCheck() then
        Combat.FindBestAutoTarget()
        self:MezNow(Config.Globals.AutoTargetID, true, true)
    end

    mq.doevents()
end

function Module:RemoveCCTarget(mobId)
    if mobId == 0 then return end
    self.TempSettings.MezTracker[mobId] = nil
end

function Module:AddCCTarget(mobId)
    if mobId == 0 then return end

    if #self.TempSettings.MezTracker >= self.settings.MaxMezCount and self.TempSettings.MezTracker[mobId] == nil then
        Logger.log_debug("\awNOTICE:\ax Unable to mez %d - mez list is full", mobId)
        return false
    end

    if self:IsMezImmune(mobId) then
        Logger.log_debug("\awNOTICE:\ax Unable to mez %d - it is immune", mobId)
        return false
    end

    self:StopAttack()

    Targeting.SetTarget(mobId)

    self.TempSettings.MezTracker[mobId] = {
        name = mq.TLO.Target.CleanName(),
        duration = mq.TLO.Target.Mezzed.Duration() or 0,
        last_check = os.clock() * 1000,
        mez_spell = mq.TLO
            .Target.Mezzed() or "None",
    }
end

function Module:IsValidMezTarget(mobId)
    local spawn = mq.TLO.Spawn(mobId)

    -- Is the mob ID in our mez immune list? If so, skip.
    if self:IsMezImmune(mobId) then
        Logger.log_debug("\ayUpdateMezList: Skipping Mob ID: %d Name: %s Level: %d as it is in our immune list.",
            spawn.ID(), spawn.CleanName(), spawn.Level())
        return false
    end
    -- Here's where we can add a necro check to see if the spawn is undead or not. If it's not
    -- undead it gets added to the mez immune list.
    if spawn and spawn.Body.Name():lower() == "giant" then
        Logger.log_debug(
            "\ayUpdateMezList: Adding ID: %d Name: %s Level: %d to our immune list as it is a giant.", spawn.ID(),
            spawn.CleanName(),
            spawn.Level())
        self:AddImmuneTarget(spawn.ID(), { id = spawn.ID(), name = spawn.CleanName(), })
        return false
    end

    if spawn and not spawn.LineOfSight() then
        Logger.log_debug("\ayUpdateMezList: Skipping Mob ID: %d Name: %s Level: %d - No LOS.", spawn.ID(),
            spawn.CleanName(), spawn.Level())
        return false
    end

    if (spawn.PctHPs() or 0) < self.settings.MezStopHPs then
        Logger.log_debug("\ayUpdateMezList: Skipping Mob ID: %d Name: %s Level: %d - HPs too low.", spawn.ID(),
            spawn.CleanName(), spawn.Level())
        return false
    end

    if (spawn.Distance() or 999) > self.settings.MezRadius then
        Logger.log_debug("\ayUpdateMezList: Skipping Mob ID: %d Name: %s Level: %d - Out of Mez Radius",
            spawn.ID(), spawn.CleanName(), spawn.Level())
        return false
    end

    return true
end

function Module:UpdateMezList()
    local searchTypes = { "npc", "npcpet", }

    local mezSpell = self:GetMezSpell()

    if not mezSpell or not mezSpell() then
        Logger.log_verbose("\ayayUpdateMezList: No mez spell - bailing!")
        return
    end

    for _, t in ipairs(searchTypes) do
        local minLevel = self.settings.MezMinLevel
        local maxLevel = self.settings.MezMaxLevel

        if self.settings.AutoLevelRange and mezSpell and mezSpell() then
            minLevel = 0
            maxLevel = mezSpell.MaxLevel()
        end
        local searchString = string.format("%s radius %d zradius %d range %d %d targetable playerstate 4", t,
            self.settings.MezRadius * 2, self.settings.MezZRadius * 2, minLevel, maxLevel)

        local mobCount = mq.TLO.SpawnCount(searchString)()
        Logger.log_debug("\ayUpdateMezList: Search String: '\at%s\ay' -- Count :: \am%d", searchString, mobCount)
        for i = 1, mobCount do
            local spawn = mq.TLO.NearestSpawn(i, searchString)

            if spawn and spawn() and spawn.ID() > 0 then
                Logger.log_debug(
                    "\ayUpdateMezList: Processing MobCount %d -- ID: %d Name: %s Level: %d BodyType: %s", i, spawn.ID(),
                    spawn.CleanName(), spawn.Level(),
                    spawn.Body.Name())

                if self:IsValidMezTarget(spawn.ID()) then
                    Logger.log_debug("\agAdding to CC List: %d -- ID: %d Name: %s Level: %d BodyType: %s", i,
                        spawn.ID(), spawn.CleanName(), spawn.Level(), spawn.Body.Name())
                    self:AddCCTarget(spawn.ID())
                end
            end
        end
    end

    mq.doevents()
end

function Module:ProcessMezList()
    -- Assume by default we never need to block for mez. We'll set this if-and-only-if
    -- we need to mez but our ability is on cooldown.
    Core.DoCmd("/attack off")
    Logger.log_debug("\ayProcessMezList() :: Loop")
    local mezSpell = self:GetMezSpell()

    if not mezSpell or not mezSpell() then return end

    if Tables.GetTableSize(self.TempSettings.MezTracker) <= 1 then
        -- If we have only one spawn we're tracking, we don't need to be mezzing
        Logger.log_debug("\ayProcessMezList(%d) :: No Mob requires mez.")
        return
    end

    if not self.settings.DoSTMez and Targeting.GetXTHaterCount() < self.settings.MezAECount then
        Logger.log_debug("\ayProcessMezList(%d) :: Single Target Mezzing is off and under the needed AE count threshold, returning.")
        return
    end

    local removeList = {}
    for id, data in pairs(self.TempSettings.MezTracker) do
        local spawn = mq.TLO.Spawn(id)
        Logger.log_debug("\ayProcessMezList(%d) :: Checking...", id)

        if not spawn or not spawn() or spawn.Dead() or Targeting.TargetIsType("corpse", spawn) or (spawn.ID() or 0) == Config.Globals.AutoTargetID then
            table.insert(removeList, id)
            Logger.log_debug("\ayProcessMezList(%d) :: Can't find mob removing...", id)
        else
            if self:IsMezImmune(id) then
                -- somehow added an immune mod to our tracker...
                Logger.log_debug("\ayProcessMezList(%d) :: Mob id is in immune list - removing...", id)
                table.insert(removeList, id)
            else
                -- Our mob is still alive, but their mez timer isn't up or they're out of x/y range
                -- Only worry about mezzing if their mez timer less than the time it will take to cast
                -- the mez spell. MyCastTime is in ms, timer is in deciseconds.
                -- We already fudge the mez timer when we set it.
                local spell = mezSpell
                if data.duration > (spell.MyCastTime() / 100) or spawn.Distance() > self.settings.MezRadius or not spawn.LineOfSight() then
                    Logger.log_debug("\ayProcessMezList(%d) :: Timer(%s > %s) Distance(%d) LOS(%s)", id,
                        Strings.FormatTime(data.duration / 1000),
                        Strings.FormatTime(spell.MyCastTime() / 100), spawn.Distance(),
                        Strings.BoolToColorString(spawn.LineOfSight()))
                else
                    if id == Config.Globals.AutoTargetID then
                        Logger.log_debug("\ayProcessMezList(%d) :: Mob is MA's target skipping", id)
                        table.insert(removeList, id)
                    else
                        Logger.log_debug("\ayProcessMezList(%d) :: Mob needs mezed.", id)

                        self:StopAttack()

                        self:StopCast()

                        -- Algar note 4/5/2025: This entire thing could likely be refactored. It works much better than before, where we would have ae mez checked once and then we would use 6 single target mezzes instead.
                        -- The choice of using the autotarget for an AEMez really sucks on targets that die quickly; but I suppose the mez isn't as important if they do.
                        -- There are also instances where we recast the AEMez because the autotarget hasn't updated in time, meaning, only the autotarget isn't mezzed, but better too often than not enough for the sake of the user.
                        -- Overall, AE and ST Mez seem to play much better together with the addition of the check below.
                        -- Additionally, the AE Mez checks will now still use the mez list instead of being fire and forget.

                        --mez the thing, if it isn't (an AE mez or someone else's mez may have hit it before we got to it). If it is, we will update timer below.
                        Targeting.SetTarget(id)
                        ---@diagnostic disable-next-line: undefined-field -- [Doesn't like the .ID on group assist target, but it is valid]
                        if self.settings.DoAEMez and not mq.TLO.Target.Mezzed() and mq.TLO.Me.GroupAssistTarget.ID() ~= id then
                            --lets make sure we didn't have more mobs dogpile on, making an AE mez more appropriate
                            local aeMezSpell = self:GetAEMezSpell()
                            if aeMezSpell and aeMezSpell() and Targeting.GetXTHaterCount() >= self.settings.MezAECount and ((mq.TLO.Me.GemTimer(aeMezSpell.RankName())() or -1) == 0 or (self.settings.DoAAMez and mq.TLO.Me.AltAbilityReady("Beam of Slumber"))) then
                                Logger.log_debug("High number of targets, let's check if AE Mez is needed again before we start singles.")
                                self:AEMezCheck()
                            end
                        end

                        --lets check to see if it is mezzed now/again and use a single target mez if necessary:
                        Targeting.SetTarget(id)
                        if id ~= Config.Globals.AutoTargetID and self.settings.DoSTMez and not mq.TLO.Target.Mezzed() then
                            Logger.log_debug("Single target mez is (still) needed.")
                            self:MezNow(id, false, true)
                        end

                        if mq.TLO.Target.Mezzed.ID() then
                            -- update the timer.
                            self:AddCCTarget(id)
                        end
                    end
                end
            end
        end
    end

    for _, id in ipairs(removeList) do
        self:RemoveCCTarget(id)
    end

    mq.doevents()
end

function Module:DoMez()
    local mezSpell = self:GetMezSpell()
    local aeMezSpell = self:GetAEMezSpell()
    if aeMezSpell and aeMezSpell() and Targeting.GetXTHaterCount() >= self.settings.MezAECount and ((mq.TLO.Me.GemTimer(aeMezSpell.RankName())() or -1) == 0 or (self.settings.DoAAMez and mq.TLO.Me.AltAbilityReady("Beam of Slumber"))) then
        self:AEMezCheck()
    end

    self:UpdateTimings()

    if Targeting.GetXTHaterCount() >= self.settings.MezStartCount then
        self:UpdateMezList()
    end

    local tableSize = Tables.GetTableSize(self.TempSettings.MezTracker)
    if mezSpell and mezSpell() and tableSize >= 1 then
        self:ProcessMezList()
    else
        Logger.log_verbose("DoMez() : Skipping Mez list processing: Spell(%s) Ready(%s) TableSize(%d)", mezSpell and mezSpell() or "None",
            mezSpell and mezSpell() and Strings.BoolToColorString(mq.TLO.Me.SpellReady(mezSpell.RankName.Name())()) or "NoSpell",
            tableSize)
    end
end

function Module:UpdateTimings()
    for _, data in pairs(self.TempSettings.MezTracker) do
        local timeDelta = (os.clock() * 1000) - data.last_check

        data.duration = data.duration - timeDelta

        data.last_check = os.clock() * 1000
    end
end

function Module:GiveTime(combat_state)
    if not Core.IsMezzing() then return end

    -- dead... whoops
    if mq.TLO.Me.Hovering() then return end

    if self.CombatState ~= combat_state and combat_state == "Downtime" then
        self:ResetMezStates()
    end

    self.CombatState = combat_state

    self:DoMez()
end

function Module:OnDeath()
end

function Module:OnZone()
    self:ResetMezStates()
    -- Zone Handler
end

function Module:OnCombatModeChanged()
end

function Module:DoGetState()
    -- Reture a reasonable state if queried
    return "TODO"
end

function Module:GetCommandHandlers()
    return { module = self._name, CommandHandlers = {}, }
end

function Module:GetFAQ()
    return { module = self._name, FAQ = self.FAQ or {}, }
end

function Module:GetClassFAQ()
    return { module = self._name, FAQ = self.ClassFAQ or {}, }
end

---@param cmd string
---@param ... string
---@return boolean
function Module:HandleBind(cmd, ...)
    local params = ...
    local handled = false
    -- /rglua cmd handler
    return handled
end

function Module:Shutdown()
    Logger.log_debug("Mez Module Unloaded.")
end

mq.bind("/rgupmez", function()
    Modules:ExecModule("Mez", "UpdateMezList")
end)

function Module:StopAttack()
    if mq.TLO.Me.Combat() then
        Logger.log_debug("\awMEZ:\ax Stopping attack to avoid breaking mez.")
        Core.DoCmd("/attack off")
        mq.delay(500, function() return not mq.TLO.Me.Combat() end)
    end
end

function Module:StopCast()
    if mq.TLO.Me.Casting() then
        Logger.log_debug("\awMEZ:\ax Stopping cast or song so I can mez.")
        mq.TLO.Me.StopCast()
        mq.delay("3s", function() return not mq.TLO.Window("CastingWindow").Open() end)
    end
end

return Module
