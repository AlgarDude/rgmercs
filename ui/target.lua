local mq         = require('mq')
local ImGui      = require('ImGui')
local Config     = require('utils.config')
local Globals    = require('utils.globals')
local Ui         = require('utils.ui')
local Icons      = require('mq.ICONS')
local Targeting  = require('utils.targeting')
local Icons      = require('mq.ICONS')

local TargetUI   = { _version = '1.0', _name = "TargetUI", _author = 'Derple', }
TargetUI.__index = TargetUI

function TargetUI:RenderContent()
    local target = mq.TLO.Target

    local pctHPs = Targeting.GetTargetPctHPs(target)

    if not target or (target.ID() or 0) == 0 then
        Ui.RenderText("No Target")
        Ui.RenderFancyHPBar("##TargetHPBar0", 0, 25, false, 1.0)
        return
    end

    if math.floor(target.Distance() or 0) >= 350 then
        ImGui.PushStyleColor(ImGuiCol.Text, Globals.Constants.Colors.AssistSpawnFarColor)
    else
        ImGui.PushStyleColor(ImGuiCol.Text, Globals.Constants.Colors.BrightWhite)
    end
    ImGui.PushStyleVar(ImGuiStyleVar.ItemSpacing, ImVec2(0, 0))
    Ui.RenderText("%s (%s) [", target.CleanName() or "", target.ID() or 0)

    ImGui.PushStyleColor(ImGuiCol.Text, ImVec4(Ui.GetConColorBySpawn(target)))
    ImGui.SameLine()
    Ui.RenderText("%d %s", target.Level() or 0, target.Class.ShortName() or "N/A")
    ImGui.PopStyleColor(1)

    ImGui.SameLine()
    Ui.RenderText("] HP: %d%% Dist: %d ", pctHPs, target.Distance() or 0)
    ImGui.PopStyleVar(1)
    ImGui.PopStyleColor(1)

    ImGui.SameLine()
    local los = target.LineOfSight()
    ImGui.TextColored(los and Globals.Constants.Colors.ConditionPassColor or Globals.Constants.Colors.ConditionFailColor, los and Icons.FA_EYE or Icons.FA_EYE_SLASH)
    Ui.Tooltip("Line of Sight")

    if Globals.AutoTargetIsNamed then
        ImGui.SameLine()
        ImGui.TextColored(IM_COL32(52, 200, 52, 255), Icons.FA_ID_BADGE)
        Ui.Tooltip("Named")
    end

    if target.ID() == Globals.ForceTargetID then
        ImGui.SameLine()
        ImGui.TextColored(IM_COL32(52, 200, 200, 255), Icons.FA_BULLSEYE)
        Ui.Tooltip("Forced Target")
    end

    local burning = Globals.LastBurnCheck and (target.ID() or 0) > 0

    if burning then
        ImGui.SameLine()
        ImGui.TextColored(Globals.GetAlternatingColor(), Icons.FA_FIRE)
        Ui.Tooltip("Burning")
    end

    if Config:GetSetting('OverrideHP') > 0 then
        pctHPs = Config:GetSetting('OverrideHP')
    end

    local hpLowOverride, hpHighOverride = nil, nil
    if Config:GetSetting('HPBarStyle') == 2 then
        hpLowOverride  = ImVec4(Ui.GetConColorBySpawn(target))
        hpHighOverride = hpLowOverride
    end

    Ui.RenderFancyHPBar("##TargetHPBar" .. tostring(target.ID()), pctHPs, 25, burning, 1.0, nil, hpLowOverride, hpHighOverride)

    -- buffs
    if target.BuffsPopulated() then
        ImGui.PushStyleVar(ImGuiStyleVar.ItemSpacing, ImVec2(2, 2))
        local buffCount = target.BuffCount() or 0
        local buffsPerRow = math.floor((ImGui.GetContentRegionAvailVec().x - ImGui.GetStyle().ItemSpacing.x) / 20) - 1
        local showBuffName = Config:GetSetting('TargetBuffNameTooltip')
        local showBuffDescription = Config:GetSetting('TargetBuffDescriptionTooltip')
        for i = 1, buffCount do
            local buff = target.Buff(i)
            if buff and buff() and buff.ID() ~= 0 then
                Ui.DrawInspectableSpellIcon(buff.SpellIcon(), buff)
                if showBuffName or showBuffDescription then
                    Ui.Tooltip(string.format("%s%s%s", showBuffName and (buff.RankName() or "Unknown") or "", showBuffName and showBuffDescription and "\n\n" or "",
                        showBuffDescription and (buff.Description() or "No description available.") or ""))
                end
                if i == 1 or i % buffsPerRow ~= 0 then
                    ImGui.SameLine()
                end
            end
        end
        ImGui.PopStyleVar(1)
    end
end

function TargetUI:RenderWindow(flags)
    flags = bit32.bor(flags, ImGuiWindowFlags.NoTitleBar, Config:GetSetting('LockTargetWindow') and bit32.bor(ImGuiWindowFlags.NoMove, ImGuiWindowFlags.NoResize) or 0)
    local open, show = ImGui.Begin(Ui.GetWindowTitle("Target"), Config:GetSetting('ShowTargetWindow'), flags)
    if show then
        self:RenderContent()
    end
    ImGui.End()
    if not open then
        Config:SetSetting('ShowTargetWindow', false)
    end
end

return TargetUI
