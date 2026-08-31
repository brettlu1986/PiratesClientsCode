-----------------------------------------------------
--File Name    : GuideActionOpenUI.lua
--Description  : 指引动作
-----------------------------------------------------
local luaclass                  = require("luaclass")
local GuideActionFunctional     = require("GuideActionFunctional")
local GuideActionOpenUI         = luaclass("GuideActionOpenUI", GuideActionFunctional)


local UIManager = require("UIManager")

function GuideActionOpenUI:DoAction(tbTemplate)
    GuideActionOpenUI.super.DoAction(self, tbTemplate)
    self:DebugLog("GuideActionOpenUI:OnTimerFunc")
    local szUIName = tbTemplate.szUIName
    if szUIName then
        if tbTemplate.bEnable then
            UIManager:OpenWnd(szUIName)
        else
            UIManager:CloseWnd(szUIName)
        end
    else
        self:LogError("GuideActionOpenUI,szUIName is nil")
    end
end

return GuideActionOpenUI
