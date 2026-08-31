-----------------------------------------------------
--File Name    : ULFFAMainLayout.lua
--Description  : 主界面布局数据读取
-----------------------------------------------------
local luaclass = require("luaclass")
local UILogicBase = require("UILogicBase")
local ULFFAMainLayout = luaclass("ULFFAMainLayout", UILogicBase)

local SettingSystemNew = require("SettingSystemNew")
local SettingClassType = require("SettingClassType")
local SettingLayoutFromDef = require("SettingLayoutFromDef")

local PICK_BOX_LOCAL_ID = 12
local PICK_ITEM_LOCAL_ID = 13

local function LoadLayoutSetting(self, nFrom)
    local pWidgetRef = self.pWidgetRef
    local SettingLayout = SettingSystemNew:GetInstance(SettingClassType.Setting_Layout)
    local tbAllLayout = SettingLayout:GetCurrentLayoutFrom(nFrom)
    for k, v in pairs(tbAllLayout) do
        if v.nFrom == SettingLayoutFromDef.COMMON and v.nLocalId ~= PICK_BOX_LOCAL_ID and v.nLocalId ~= PICK_ITEM_LOCAL_ID then
            local tbTemplate = v.tbTemplate
            --logdebug("tbTemplate.szMainWidgetName,tbTemplate.szAlphaWidgetName,tbTemplate.szScaleWidgetName=",tbTemplate.szMainWidgetName,tbTemplate.szAlphaWidgetName,tbTemplate.szScaleWidgetName)
            local pWidget = pWidgetRef[tbTemplate.szMainWidgetName]
            local pAlphaWidget = self.pWidgetRef[tbTemplate.szMainAlphaWidgetName]
            local pScaleWidget = self.pWidgetRef[tbTemplate.szMainScaleWidgetName]
            if pWidget and pAlphaWidget and pScaleWidget then
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


function ULFFAMainLayout:OnEnter()
    LoadLayoutSetting(self, self.Owner.nLayoutFrom)
end

function ULFFAMainLayout:RefreshLayout()
    LoadLayoutSetting(self, self.Owner.nLayoutFrom)
end

return ULFFAMainLayout