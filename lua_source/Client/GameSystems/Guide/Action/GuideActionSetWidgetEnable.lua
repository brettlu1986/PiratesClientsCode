-----------------------------------------------------
--File Name    : GuideActionSetWidgetEnable.lua
--Description  : 指引动作
-----------------------------------------------------
local luaclass                      = require("luaclass")
local GuideActionFunctional         = require("GuideActionFunctional")
local GuideActionSetWidgetEnable    = luaclass("GuideActionSetWidgetEnable", GuideActionFunctional)

local UIManager = require("UIManager")

----------------------------------------------------------

function GuideActionSetWidgetEnable:DoAction(tbTemplate)
    GuideActionSetWidgetEnable.super.DoAction(self, tbTemplate)
    local Wnd = UIManager:GetWnd(tbTemplate.szUIName)
    if not Wnd then
        self:LogError("wnd nil,uiname="..tostring(tbTemplate.szUIName))
        return
    end
    local pWidgetRef = Wnd.pWidgetRef
    for k,v in ipairs(tbTemplate.tbPrefabName)do
        pWidgetRef = pWidgetRef[v]
        if not pWidgetRef then
            self:LogError("GuideActionSetWidgetEnable:Begin,not found prefab,prefab name="..v)
            return
        end
    end
    self:LogError("GuideActionSetWidgetEnable:Begin,szVisibility = " .. tostring(tbTemplate.szVisibility))
    for k,v in ipairs(tbTemplate.tbWidgetName)do
        local SelectWidget = pWidgetRef[v]
        if SelectWidget then
            SelectWidget:SetIsEnabled(tbTemplate.bEnable)
        else
            self:LogError("GuideActionShowWidget:Begin,can't find widght,name=",v)
        end
    end
end

return GuideActionSetWidgetEnable
