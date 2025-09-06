local Console             = require('utils.console')
local Config              = require('utils.config')
local Ui                  = require('utils.ui')
local Icons               = require('mq.ICONS')
local Logger              = require("utils.logger")

local ConsoleUI           = { _version = '1.0', _name = "ConsoleUI", _author = 'Derple', }
ConsoleUI.__index         = ConsoleUI
ConsoleUI.logFilter       = ""
ConsoleUI.logFilterLocked = true

function ConsoleUI:DrawConsole(showPopout)
    local RGMercsConsole = Console:GetConsole("##RGMercs", Config:GetMainOpacity())

    if RGMercsConsole then
        if showPopout then
            if ImGui.SmallButton(Icons.MD_OPEN_IN_NEW) then
                Config:SetSetting('PopOutConsole', true)
            end
            Ui.Tooltip("Pop the Console out into its own window.")
            ImGui.NewLine()
        end

        local changed
        if ImGui.BeginTable("##debugoptions", 2, ImGuiTableFlags.None) then
            ImGui.TableSetupColumn("Opt Name", bit32.bor(ImGuiTableColumnFlags.WidthFixed, ImGuiTableColumnFlags.NoResize), 100)
            ImGui.TableSetupColumn("Opt Value", ImGuiTableColumnFlags.WidthStretch)
            ImGui.TableNextColumn()
            local logToFile = Config:GetSetting('LogToFile')
            logToFile, changed = Ui.RenderOptionToggle("##log_to_file",
                "", logToFile)
            if changed then
                Config:SetSetting('LogToFile', logToFile)
            end
            ImGui.TableNextColumn()
            ImGui.Text("Log to File")
            ImGui.TableNextColumn()
            ImGui.Text("Debug Level")
            ImGui.TableNextColumn()
            local logLevel = Config:GetSetting('LogLevel')

            logLevel, changed = ImGui.Combo("##Debug Level",
                logLevel, Config.Constants.LogLevels,
                #Config.Constants.LogLevels)

            if changed then
                Config:SetSetting('LogLevel', logLevel)
            end
            ImGui.TableNextColumn()
            ImGui.Text("Log Filter")
            ImGui.SameLine()
            if ImGui.Button(self.logFilterLocked and Icons.FA_LOCK or Icons.FA_UNLOCK, 22, 22) then
                self.logFilterLocked = not self.logFilterLocked
            end
            ImGui.TableNextColumn()
            ImGui.BeginDisabled(self.logFilterLocked)

            self.logFilter, changed = ImGui.InputText("##logfilter", self.logFilter)

            ImGui.EndDisabled()

            if changed then
                if self.logFilter:len() == 0 then
                    Logger.clear_log_filter()
                else
                    Logger.set_log_filter(self.logFilter)
                end
            end
            ImGui.EndTable()
        end

        if ImGui.CollapsingHeader("RGMercs Output", ImGuiTreeNodeFlags.DefaultOpen) then
            local cur_x, cur_y = ImGui.GetCursorPos()
            local contentSizeX, contentSizeY = ImGui.GetContentRegionAvail()
            if not RGMercsConsole.opacity then
                local scroll = ImGui.GetScrollY()
                ImGui.Dummy(contentSizeX, 410)
                ImGui.SetCursorPos(cur_x, cur_y)
                RGMercsConsole:Render(ImVec2(contentSizeX, math.min(400, contentSizeY + scroll)))
            else
                RGMercsConsole:Render(ImVec2(contentSizeX, math.max(200, (contentSizeY - 10))))
            end
            ImGui.Separator()
        end
    end
end

return ConsoleUI
