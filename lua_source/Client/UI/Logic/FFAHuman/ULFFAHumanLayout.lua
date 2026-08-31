-----------------------------------------------------
--File Name    : ULFFAHumanLayout.lua
--Description  : 主界面人和坐骑布局数据读取
-----------------------------------------------------
local luaclass = require("luaclass")
local UILogicBase = require("UILogicBase")
local ULFFAHumanLayout = luaclass("ULFFAHumanLayout", UILogicBase)


local SettingSystemNew = require("SettingSystemNew")
local SettingClassType = require("SettingClassType")
local SettingLayoutFromDef = require("SettingLayoutFromDef")


local function LoadLayoutSetting(self, nFrom)
    local pWidgetRef = self.pWidgetRef
    local SettingLayout = SettingSystemNew:GetInstance(SettingClassType.Setting_Layout)
    local tbAllLayout = SettingLayout:GetCurrentLayoutFrom(nFrom)
    for k, v in pairs(tbAllLayout) do
        if v.nFrom == nFrom then
            local tbTemplate = v.tbTemplate
            local pWidget = pWidgetRef[tbTemplate.szMainWidgetName]
            local pScaleWidget = pWidgetRef[tbTemplate.szMainScaleWidgetName]
            local pAlphaWidget = pWidgetRef[tbTemplate.szMainAlphaWidgetName]
            if pWidget then
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

function ULFFAHumanLayout:OnEnter()
    LoadLayoutSetting(self, SettingLayoutFromDef.HUMAN)
    LoadLayoutSetting(self, SettingLayoutFromDef.VEHICLE)
end

function ULFFAHumanLayout:RefreshLayout()
    LoadLayoutSetting(self, SettingLayoutFromDef.HUMAN)
    LoadLayoutSetting(self, SettingLayoutFromDef.VEHICLE)
end

return ULFFAHumanLayout