-----------------------------------------------------
--File Name    : GuideActionHideWidget.lua
--Description  : 指引动作
-----------------------------------------------------
local luaclass = require("luaclass")
local GuideActionFunctional = require("GuideActionFunctional")
local GuideActionHideWidget = luaclass("GuideActionHideWidget",GuideActionFunctional)

local UIManager = require("UIManager")

function GuideActionHideWidget:DoAction(tbTemplate)
    GuideActionHideWidget.super.DoAction(self, tbTemplate)
    local Wnd = UIManager:GetWnd(tbTemplate.szUIName)
    local pWidgetRef = Wnd.pWidgetRef

    for k,v in ipairs(tbTemplate.tbPrefabName)do
        pWidgetRef = pWidgetRef[v]
        if not pWidgetRef then
            self:LogError("GuideActionHideWidget:Begin,can't find prefab,prefab name=",v)
            return
        end
    end

    for k,v in pairs(tbTemplate.tbWidgetName)do
        self:DebugLog("Hidewidget,v="..tostring(v))
        local HiddenWidget = pWidgetRef[v]
        if HiddenWidget then
            HiddenWidget:SetVisibility(ESlateVisibility[self.tbTemplate.szVisibility])--ESlateVisibility.Hidden
        else
            self:LogError("GuideActionHideWidget:Begin,can't find widght,name=",v)
        end
    end
end

return GuideActionHideWidget
