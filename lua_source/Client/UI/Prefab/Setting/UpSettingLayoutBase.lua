local luaclass = require ("luaclass")
local PrefabBase = require("PrefabBase")
local UpSettingLayoutBase = luaclass("UpSettingLayoutBase", PrefabBase)

local SettingSystemNew = require("SettingSystemNew")
local SettingClassType = require("SettingClassType")
local SettingLayoutFromDef = require("SettingLayoutFromDef")
--local SettingLayoutDataTable = require("SettingLayoutDataTable")


UpSettingLayoutBase.nFrom = SettingLayoutFromDef.HUMAN
UpSettingLayoutBase.pRoot = nil
UpSettingLayoutBase.nOperationMode = 1

function UpSettingLayoutBase:LoadWidgetSettingData(tbLayoutData)
    local pMovableWidget = self.pWidgetRef[tbLayoutData.tbTemplate.szMovableWidgetName]
    local pAlphaWidget = self.pWidgetRef[tbLayoutData.tbTemplate.szAlphaWidgetName]
    local pScaleWidget = self.pWidgetRef[tbLayoutData.tbTemplate.szScaleWidgetName]
    if not pMovableWidget or not pAlphaWidget or not pScaleWidget then
        logerror("UpSettingLayoutBase:LoadWidgetSettingData,widget is nil,", tbLayoutData.tbTemplate.szMovableWidgetName,
        tbLayoutData.tbTemplate.szAlphaWidgetName, tbLayoutData.tbTemplate.szScaleWidgetName)
        return
    end
    pMovableWidget.Slot:SetPosition(Vector2D{X = tbLayoutData.nX, Y = tbLayoutData.nY})
    pAlphaWidget:SetRenderOpacity(tbLayoutData.nAlpha)
    local SetUserSpecifiedScaleFunc = pScaleWidget.SetUserSpecifiedScale
    if SetUserSpecifiedScaleFunc then
        SetUserSpecifiedScaleFunc(pScaleWidget, tbLayoutData.nScale)
    else
        pScaleWidget:SetRenderScale(Vector2D{X = tbLayoutData.nScale, Y = tbLayoutData.nScale})
    end
    pScaleWidget:SetRenderTransformPivot(pScaleWidget.Slot:GetAlignment())
end

function UpSettingLayoutBase:LoadTargetWidgets(tbTargetWidgetMap)
    if not tbTargetWidgetMap then
        tbTargetWidgetMap = {}
    end
    local pWidgetRef = self.pWidgetRef
    local SettingLayout = SettingSystemNew:GetInstance(SettingClassType.Setting_Layout)
    local tbAllLayout = SettingLayout:GetCurrentLayoutFrom(self.nFrom)
    for k, v in ipairs(tbAllLayout) do
        if v.nFrom == self.nFrom then
            local tbLayoutTemplate = v.tbTemplate
            local tbTargetWidgetData = {}
            tbTargetWidgetData.pMovableWidget = pWidgetRef[tbLayoutTemplate.szMovableWidgetName]
            tbTargetWidgetData.pAlphaWidget = pWidgetRef[tbLayoutTemplate.szAlphaWidgetName]
            tbTargetWidgetData.pScaleWidget = pWidgetRef[tbLayoutTemplate.szScaleWidgetName]
            tbTargetWidgetData.pExpandWidget = pWidgetRef[tbLayoutTemplate.szExpandWidgetName]
            if tbLayoutTemplate.nOperationMode == self.nOperationMode or tbLayoutTemplate.nOperationMode == 0 then
                tbTargetWidgetData.pRoot = self.pRoot
                tbTargetWidgetData.pWidget = pWidgetRef[tbLayoutTemplate.szWidgetName]
                --logdebug("tbLayoutTemplate.szMovableWidgetName=",tbLayoutTemplate.szMovableWidgetName)
                tbTargetWidgetData.pWidgetAnchor = tbTargetWidgetData.pMovableWidget.Slot:GetAnchors()
                tbTargetWidgetData.pWidgetAlignment = tbTargetWidgetData.pMovableWidget.Slot:GetAlignment()
                tbTargetWidgetData.nRemoteId = v.nRemoteId
                tbTargetWidgetData.nFrom = self.nFrom
                tbTargetWidgetData.nScale = v.nScale
                tbTargetWidgetData.nAlpha = v.nAlpha
                tbTargetWidgetMap[v.nRemoteId] = tbTargetWidgetData
            else
                tbTargetWidgetData.pMovableWidget:SetVisibility(ESlateVisibility.Collapsed)
                tbTargetWidgetData.pAlphaWidget:SetVisibility(ESlateVisibility.Collapsed)
                tbTargetWidgetData.pScaleWidget:SetVisibility(ESlateVisibility.Collapsed)
                if tbTargetWidgetData.pExpandWidget then
                    tbTargetWidgetData.pExpandWidget:SetVisibility(ESlateVisibility.Collapsed)
                end
            end
        end
    end
    return tbTargetWidgetMap
end
return UpSettingLayoutBase
