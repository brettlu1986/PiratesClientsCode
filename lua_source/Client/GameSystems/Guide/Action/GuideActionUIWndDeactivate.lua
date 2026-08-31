-----------------------------------------------------
--File Name    : GuideActionUIWndDeactivate.lua
--Description  : 指引动作
-----------------------------------------------------
local luaclass                      = require("luaclass")
local GuideActionFunctional         = require("GuideActionFunctional")
local GuideActionUIWndDeactivate    = luaclass("GuideActionUIWndDeactivate",GuideActionFunctional)


local UIManager         = require("UIManager")
local ClientEventDef    = require("ClientEventDef")

function GuideActionUIWndDeactivate:DoAction(tbTemplate)
    GuideActionUIWndDeactivate.super.DoAction(self, tbTemplate)
    local Wnd = UIManager:GetWnd(tbTemplate.szUIName)
    if not Wnd then
        self:LogError("GuideActionUIWndDeactivate:Begin, invalid Wnd=", tbTemplate.szUIName)
        return
    end
    --暂停或激活ui窗口逻辑 tbTemplate.bEnable
    self.EventHelper:OnFireEvent(ClientEventDef.EV_UI_DEACTIVE, tbTemplate.szUIName, tbTemplate.bEnable)
end

return GuideActionUIWndDeactivate
