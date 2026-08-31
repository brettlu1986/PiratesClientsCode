-----------------------------------------------------
--File Name    : ULFFAShipLayout.lua
--Description  : 主界面船布局数据读取
-----------------------------------------------------
local luaclass = require("luaclass")
local UILogicBase = require("UILogicBase")
local ULFFAShipLayout = luaclass("ULFFAShipLayout", UILogicBase)

local SettingLayoutFromDef = require("SettingLayoutFromDef")
local SettingSystemNew = require("SettingSystemNew")
local SettingClassType = require("SettingClassType")


local function LoadLayoutSetting(self)
    local pWidgetRef = self.pWidgetRef
    local SettingLayout = SettingSystemNew:GetInstance(SettingClassType.Setting_Layout)
    local tbAllLayout = SettingLayout:GetCurrentLayoutFrom(SettingLayoutFromDef.SHIP)
    for k, v in pairs(tbAllLayout) do
        if v.nFrom == SettingLayoutFromDef.SHIP then
            local tbTemplate = v.tbTemplate
            local pWidget = pWidgetRef[tbTemplate.szMainWidgetName]
            local pScaleWidget = pWidgetRef[tbTemplate.szMainScaleWidgetName]
            local pAlphaWidget = pWidgetRef[tbTemplate.szMainAlphaWidgetName]
            if pWidget and pScaleWidget and pAlphaWidget then
                pWidget.Slot:SetPosition(Vector2D{X = v.nX, Y = v.nY})
                pAlphaWidget:SetRenderOpacity(v.nAlpha)
                local SetUserSpecifiedScaleFunc = pScaleWidget.SetUserSpecifiedScale
                if SetUserSpecifiedScaleFunc then
                    SetUserSpecifiedScaleFunc(pScaleWidget, v.nScale)
                else
                    pScaleWidget:SetRenderTransformPivot(pScaleWidget.Slot:GetAlignment())
                    pScaleWidget:SetRenderScale(Vector2D{X = v.nScale, Y = v.nScale})
                end
            end
        end
    end
end


function ULFFAShipLayout:OnEnter()
    LoadLayoutSetting(self)
end

function ULFFAShipLayout:RefreshLayout()
    LoadLayoutSetting(self)
end

return ULFFAShipLayout