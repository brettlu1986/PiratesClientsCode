-----------------------------------------------------
--File Name    : GuideActionSelectShipBuildItem.lua
--Description  : 指引动作
-----------------------------------------------------
local luaclass                          = require("luaclass")
local GuideActionSelectWidget           = require("GuideActionSelectWidget")
local GuideActionSelectShipBuildItem    = luaclass("GuideActionSelectShipBuildItem", GuideActionSelectWidget)
----------------------------------------------------------
local UIManager         = require("UIManager")
local UIDef             = require("UIDef")
----------------------------------------------------------
function GuideActionSelectShipBuildItem:GetSelectWidgets()
    self:DebugLog(" GuideActionSelectShipBuildItem GetSelectWidgets tbWidgetName" .. tostring(self.tbTemplate.tbWidgetName[1]))  
    local tbSelectWidgets = {}
    local tbTemplate = self.tbTemplate
    local nShipLevel = tonumber(tbTemplate.tbParam[1])
    local nShipItemIndex = tonumber(tbTemplate.tbParam[2])
    local szWrapBoxName = "wboxShip" .. nShipLevel
    local pBuildWnd = UIManager:GetWnd(UIDef.UI_BUILD_ITEM)
    self:DebugLog(" GuideActionSelectShipBuildItem GetSelectWidgets nShipLevel = " .. tostring(nShipLevel) .. " nShipItemIndex = " .. tostring(nShipItemIndex))
    if not pBuildWnd then
        return tbSelectWidgets
    end
    local pWidget = pBuildWnd.pWidgetRef[szWrapBoxName]:GetChildAt(nShipItemIndex)
    self:DebugLog(" GuideActionSelectShipBuildItem GetSelectWidgets pWidget = " .. tostring(pWidget.btnPass))
    table.insert(tbSelectWidgets, pWidget.btnPass)
    return tbSelectWidgets
end

return GuideActionSelectShipBuildItem
