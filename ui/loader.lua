local mq       = require('mq')
local ImGui    = require('ImGui')
local ImAnim   = require('ImAnim')
local ImagesUI = require('ui.images')
local Config   = require('utils.config')
local Globals  = require('utils.globals')
local Ui       = require("utils.ui")

-- seed the rng
math.randomseed(mq.gettime())

local LoaderUI           = { _version = '1.0', _name = "LoaderUI", _author = 'Derple', }
LoaderUI.__index         = LoaderUI
LoaderUI.Initialized     = false

-- Shared constants
LoaderUI.imgEndSize      = 60
LoaderUI.settleDuration  = 0.7

-- Lissajous animation constants
LoaderUI.imgStartSize    = 220
LoaderUI.flyDuration     = 1.0

-- Drop animation constants
LoaderUI.dropDuration    = 1.5

-- Animation state
-- "lissajous" | "drop" (chosen randomly on init)
LoaderUI.animType        = (math.floor(math.random() * 100) % 2 == 0) and "lissajous" or "drop"
-- lissajous: "flying" | "settling" | "done" | "donedone"
-- drop:      "dropping" | "done" | "donedone"
LoaderUI.animState       = LoaderUI.animType == "lissajous" and "flying" or "dropping"

LoaderUI.animStartTime   = nil
LoaderUI.flyPos          = { x = 0, y = 0, }
LoaderUI.settleStartTime = nil
LoaderUI.dropBigSize     = 0

-- ImAnim IDs
LoaderUI.animId          = ImHashStr("loader_anim")
LoaderUI.chSize          = ImHashStr("loader_size")
LoaderUI.chX             = ImHashStr("loader_x")
LoaderUI.chY             = ImHashStr("loader_y")
LoaderUI.chDropY         = ImHashStr("loader_drop_y")
LoaderUI.chDropSize      = ImHashStr("loader_drop_size")

-- `Renders the lissajous fly-then-settle animation`
-- `--- @param self LoaderUI`
-- `--- @param dl ImDrawList foreground draw list`
-- `--- @param display ImVec2 display size`
-- `--- @param finalX number target screen X of the image top-left`
-- `--- @param finalY number target screen Y of the image top-left`
-- `--- @param dt number delta time`
-- `--- @return boolean true while animation is still running`
local function renderLissajous(self, dl, display, finalX, finalY, dt)
    if self.animState == "flying" then
        if not self.animStartTime then self.animStartTime = Globals.GetTimeSeconds() end
        local cx      = display.x / 2
        local cy      = display.y / 2

        local offset  = ImAnim.OscillateVec2(
            self.animId,
            ImVec2(cx * 0.65, cy * 0.55),
            ImVec2(0.477, 0.318),
            IamWaveType.Sine,
            ImVec2(math.pi / 4, 0),
            dt)
        local ix      = cx + offset.x
        local iy      = cy + offset.y
        self.flyPos.x = ix
        self.flyPos.y = iy

        local half    = self.imgStartSize / 2
        dl:AddImage(ImagesUI.imgDisplayed:GetTextureID(),
            ImVec2(ix - half, iy - half),
            ImVec2(ix + half, iy + half))

        if Globals.GetTimeSeconds() - self.animStartTime >= self.flyDuration then
            self.animState       = "settling"
            self.settleStartTime = Globals.GetTimeSeconds()
        end
        return true
    elseif self.animState == "settling" then
        local targetCX = finalX + self.imgEndSize / 2
        local targetCY = finalY + self.imgEndSize / 2

        local size     = ImAnim.TweenFloat(self.animId, self.chSize, self.imgEndSize, self.settleDuration,
            ImAnim.EasePreset(IamEaseType.InQuart), IamPolicy.Crossfade, dt, self.imgStartSize)
        local cx       = ImAnim.TweenFloat(self.animId, self.chX, targetCX, self.settleDuration,
            ImAnim.EasePreset(IamEaseType.OutBounce), IamPolicy.Crossfade, dt, self.flyPos.x)
        local cy       = ImAnim.TweenFloat(self.animId, self.chY, targetCY, self.settleDuration,
            ImAnim.EasePreset(IamEaseType.OutBounce), IamPolicy.Crossfade, dt, self.flyPos.y)
        local half     = size / 2

        dl:AddImage(ImagesUI.imgDisplayed:GetTextureID(),
            ImVec2(cx - half, cy - half),
            ImVec2(cx + half, cy + half))

        if Globals.GetTimeSeconds() - self.settleStartTime >= self.settleDuration then
            self.animState     = "done"
            self.animEndedTime = Globals.GetTimeMS()
        end
        return true
    end

    return false
end

-- `Renders the big-drop-and-bounce animation`
-- `--- @param self LoaderUI`
-- `--- @param dl ImDrawList foreground draw list`
-- `--- @param display ImVec2 display size`
-- `--- @param finalX number target screen X of the image top-left`
-- `--- @param finalY number target screen Y of the image top-left`
-- `--- @param dt number delta time`
-- `--- @return boolean true while animation is still running`
local function renderDrop(self, dl, display, finalX, finalY, dt)
    if self.animState == "dropping" then
        if self.dropBigSize == 0 then
            self.dropBigSize   = math.min(display.x, display.y) * 0.65
            self.animStartTime = Globals.GetTimeSeconds()
        end

        local targetCX = finalX + self.imgEndSize / 2
        local targetCY = finalY + self.imgEndSize / 2
        local startCY  = display.y / 2 - self.dropBigSize / 2

        local size     = ImAnim.TweenFloat(self.animId, self.chDropSize, self.imgEndSize, self.dropDuration,
            ImAnim.EasePreset(IamEaseType.OutExpo), IamPolicy.Crossfade, dt, self.dropBigSize)
        local cy       = ImAnim.TweenFloat(self.animId, self.chDropY, targetCY, self.dropDuration,
            ImAnim.EasePreset(IamEaseType.OutBounce), IamPolicy.Crossfade, dt, startCY)
        local cx       = ImAnim.TweenFloat(self.animId, self.chX, targetCX, self.dropDuration,
            ImAnim.EasePreset(IamEaseType.OutBounce), IamPolicy.Crossfade, dt, display.x / 2)
        local half     = size / 2

        dl:AddImage(ImagesUI.imgDisplayed:GetTextureID(),
            ImVec2(cx - half, cy - half),
            ImVec2(cx + half, cy + half))

        if Globals.GetTimeSeconds() - self.animStartTime >= self.dropDuration then
            self.animState     = "done"
            self.animEndedTime = Globals.GetTimeMS()
        end
        return true
    end

    return false
end

-- `Dispatches to the chosen animation renderer and handles the shared done states`
-- `--- @param self LoaderUI`
-- `--- @param display ImVec2 display size`
-- `--- @param finalX number target screen X of the image top-left`
-- `--- @param finalY number target screen Y of the image top-left`
-- `--- @return boolean true while animation is still running`
local function renderAnimImage(self, display, finalX, finalY)
    local dl = ImGui.GetForegroundDrawList()
    local dt = Ui.GetDeltaTime()

    if self.animState == "done" then
        if Globals.GetTimeMS() - self.animEndedTime >= 450 then
            self.animState = "donedone"
        end
        return false
    end

    if self.animType == "lissajous" then
        return renderLissajous(self, dl, display, finalX, finalY, dt)
    else
        return renderDrop(self, dl, display, finalX, finalY, dt)
    end
end

function LoaderUI:RenderLoader(initPctComplete, initMsg)
    if not self.Initialized then
        ImagesUI:InitLoader()
        self.Initialized = true
    end

    local display = ImGui.GetIO().DisplaySize
    local winX    = display.x / 2 - 200
    local winY    = display.y / 3 - 75

    -- Approximate screen position of the image inside the loader window (~8px window padding)
    local finalX  = winX + 8
    local finalY  = winY + 8

    ImGui.PushStyleVar(ImGuiStyleVar.WindowRounding, 15)
    ImGui.PushStyleVar(ImGuiStyleVar.FrameRounding, 15)
    ImGui.PushStyleVar(ImGuiStyleVar.WindowBorderSize, 1.25)
    ImGui.PushStyleVar(ImGuiStyleVar.Alpha, 100)
    ImGui.SetNextWindowSize(ImVec2(400, 80), ImGuiCond.Always)
    ImGui.SetNextWindowPos(ImVec2(winX, winY), ImGuiCond.Always)

    ImGui.Begin("RGMercs Loader", nil,
        bit32.bor(ImGuiWindowFlags.NoTitleBar, ImGuiWindowFlags.NoResize, ImGuiWindowFlags.NoMove, ImGuiWindowFlags.NoScrollbar, ImGuiWindowFlags.NoFocusOnAppearing))

    local animRunning = renderAnimImage(self, display, finalX, finalY)

    if animRunning then
        ImGui.Dummy(ImVec2(60, 60))
    else
        ImGui.Image(ImagesUI.imgDisplayed:GetTextureID(), ImVec2(60, 60))
    end
    ImGui.SameLine()
    Ui.RenderText("RGMercs %s: Loading...", Config._version)
    ImGui.SetCursorPosY(ImGui.GetCursorPosY() - 35)
    ImGui.SetCursorPosX(ImGui.GetCursorPosX() + 70)
    Ui.RenderAnimatedPercentage("RGMercsLoadProgressBar", initPctComplete, 16, 0, Globals.Constants.Colors.LightBlue, Globals.Constants.Colors.Green, initMsg)
    ImGui.PopStyleVar(4)
    ImGui.End()
end

function LoaderUI:IsDone()
    return self.animState == "donedone"
end

return LoaderUI
