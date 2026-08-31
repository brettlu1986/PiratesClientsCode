local luaclass = require("luaclass")
local WndBase = require("WndBase")
local UIBlackScreen = luaclass("UIBlackScreen", WndBase)

local BlackScreenHelper = require("BlackScreenHelper")


function UIBlackScreen:OnShow()
    local tbOpenArgs = self.tbOpenArgs
    local FullDisplayCallback = tbOpenArgs.FullDisplayCallback
    local bAutoClose = tbOpenArgs.bAutoClose
    self:PlayAnimation("anim_BlackScreenIn", 0, 1, EUMGSequencePlayMode.Forward, BlackScreenHelper.nBlackScreenInSpeed, function()
        if FullDisplayCallback then
            FullDisplayCallback()
        end
        if bAutoClose then
            self:CloseSelf()
        end
    end)
end

function UIBlackScreen:OnHide()
    self:PlayAnimation("anim_BlackScreenOut", 0, 1, EUMGSequencePlayMode.Forward, BlackScreenHelper.nBlackScreenOutSpeed, function()
        self:HideFinished()
        local CloseCallback = self.tbOpenArgs.CloseCallback
        if CloseCallback then
            CloseCallback()
        end
    end)
    return false
end

return UIBlackScreen