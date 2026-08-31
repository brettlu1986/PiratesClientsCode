-----------------------------------------------------
--File Name    : GuideActionSelectWidget.lua
--Description  : 指引动作
-----------------------------------------------------
local luaclass                          = require("luaclass")
local GuideActionSelectVisibleWidget    = require("GuideActionSelectVisibleWidget")
local GuideActionSelectHouseUp          = luaclass("GuideActionSelectHouseUp", GuideActionSelectVisibleWidget)

local UIManager         = require("UIManager")
local UIDef             = require("UIDef")
local ClientEventDef    = require("ClientEventDef")
----------------------------------------------------------

function GuideActionSelectHouseUp:CheckWidgetVisible()
    self:DebugLog("CheckWidgetVisible")
    local tbWnd = UIManager:GetWnd(UIDef.UI_FFA_MAIN)
    if not tbWnd then
        self:LogError("FFA_MAIN is nil!")
        self:EndAction()
        return
    end
    local pWidget = tbWnd.pWidgetRef.pbFFAHuman.cvsHorse
    local bVisible = pWidget:IsVisible()
    self:DebugLog("CheckWidgetVisible bVisible = " .. tostring(bVisible))
    local EventHelper = self.EventHelper
    if bVisible then
        self:DebugLog("CheckWidgetVisible GuideWnd Activate")
        EventHelper:FireEvent(ClientEventDef.EV_GUIDE_UI_ACTIVATE, true)
    else
        self:DebugLog("CheckWidgetVisible GuideWnd Deactivate")
        EventHelper:FireEvent(ClientEventDef.EV_GUIDE_UI_ACTIVATE, false)
    end
end

return GuideActionSelectHouseUp