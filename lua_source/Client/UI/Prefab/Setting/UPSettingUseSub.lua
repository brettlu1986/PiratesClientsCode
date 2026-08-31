local luaclass = require("luaclass")
local PrefabBase = require("PrefabBase")
local UPSettingUseSub = luaclass("UPSettingUseSub", PrefabBase)

local SettingLayoutFromDef = require("SettingLayoutFromDef")
local UISetUtils = require("UISetUtils")
local UIResourceDef = require("UIResourceDef")
local SettingSystemNew = require("SettingSystemNew")
local SettingClassType = require("SettingClassType")
local ClientEventDef = require("ClientEventDef")

local tbSettingOperationMode = SettingSystemNew:GetInstance(SettingClassType.Setting_OperationMode)
local tbOperationModeDef = tbSettingOperationMode.ModeDef

local tbLayoutTitle =
{
    [SettingLayoutFromDef.HUMAN] = UISetUtils.GetL10NTextByKey("SETTING_LAYOUT_HUMAN"),
    [SettingLayoutFromDef.SHIP] = UISetUtils.GetL10NTextByKey("SETTING_LAYOUT_SHIP"),
    [SettingLayoutFromDef.VEHICLE] = UISetUtils.GetL10NTextByKey("SETTING_LAYOUT_VEHICLE"),
}

UPSettingUseSub.nFrom = SettingLayoutFromDef.HUMAN

local function OnSetClicked(self)
    local SettingLayout = SettingSystemNew:GetInstance(SettingClassType.Setting_Layout)
    SettingLayout:EnterLayout(self.nFrom)
end

local function OnSelectClicked(self)
    self.pWidgetRef.imgSelect:SetVisibility(ESlateVisibility_SelfHitTestInvisible)
    self.pWidgetRef.btnSet:SetVisibility(ESlateVisibility_Visible)
    if self.SelectCallback then
        self.SelectCallback()
    end
end

local function SetOperationMode(self, nOperationMode)
    
    if self.nFrom == SettingLayoutFromDef.SHIP then
        tbSettingOperationMode:SetShipOperationMode(nOperationMode)
    elseif self.nFrom == SettingLayoutFromDef.VEHICLE then
        tbSettingOperationMode:SetVehicleOperationMode(nOperationMode)
    end
    self.EventHelper:FireEvent(ClientEventDef.EV_OPERATION_MODE_CHANGED, self.nFrom)
end

local function OnButtonModeChecked(self, bState)
    self.pWidgetRef.KMCheckBox_0:SetIsChecked(bState)
    self.pWidgetRef.KMCheckBox_1:SetIsChecked(not bState)
    SetOperationMode(self, bState and tbOperationModeDef.WithButton or tbOperationModeDef.WithJoystick)
end

local function OnVirtualJoystickModeChecked(self, bState)
    if self.nFrom == SettingLayoutFromDef.HUMAN then
        if not bState then
            self.pWidgetRef.KMCheckBox_1:SetIsChecked(true)
        end
        return
    end
    self.pWidgetRef.KMCheckBox_1:SetIsChecked(bState)
    self.pWidgetRef.KMCheckBox_0:SetIsChecked(not bState)
    SetOperationMode(self, bState and tbOperationModeDef.WithJoystick or tbOperationModeDef.WithButton)
end

local function SetHumanSettingUseSub(self)
    local pButtonBoxPos = self.pWidgetRef.KMCheckBox_0.Slot:GetPosition()
    self.pWidgetRef.KMCheckBox_1.Slot:SetPosition(pButtonBoxPos)
    self.pWidgetRef.KMCheckBox_1:SetIsChecked(true)
    self.pWidgetRef.KMCheckBox_1:SetVisibility(ESlateVisibility_Visible)
    self.pWidgetRef.KMCheckBox_0:SetVisibility(ESlateVisibility_Collapsed)
end

function UPSettingUseSub:InitControlMode(nOperationMode)
    if self.nFrom == SettingLayoutFromDef.HUMAN then
        return 
    end
    self.pWidgetRef.KMCheckBox_0:SetVisibility(ESlateVisibility_Visible)
    self.pWidgetRef.KMCheckBox_1:SetVisibility(ESlateVisibility_Visible)
    self.pWidgetRef.KMCheckBox_0:SetIsChecked(nOperationMode == tbOperationModeDef.WithButton)
    self.pWidgetRef.KMCheckBox_1:SetIsChecked(nOperationMode == tbOperationModeDef.WithJoystick)
end

function UPSettingUseSub:OnBindEvent(EventHelper)
    EventHelper:RegisterCppDelegate(self.pWidgetRef.btnSet.OnClicked, self, OnSetClicked)
    EventHelper:RegisterCppDelegate(self.pWidgetRef.btnSelect.OnClicked, self, OnSelectClicked)
    EventHelper:RegisterCppDelegate(self.pWidgetRef.KMCheckBox_0.OnCheckStateChanged, self, OnButtonModeChecked)
    EventHelper:RegisterCppDelegate(self.pWidgetRef.KMCheckBox_1.OnCheckStateChanged, self, OnVirtualJoystickModeChecked)
end

function UPSettingUseSub:SetData(nFrom, nDefaultFrom, SelectCallback)
    self.nFrom = nFrom
    self.SelectCallback = SelectCallback
    self.pWidgetRef.txtName:SetText(tbLayoutTitle[nFrom])
    local pIcon = UIResourceDef.SETTING_LAYOUT_ICON[nFrom]:load()
    if pIcon then
        UISetUtils.SetImageBrushRes(self.pWidgetRef.imgItem, pIcon, true)
    end
    if nFrom == nDefaultFrom then
        self.pWidgetRef.imgSelect:SetVisibility(ESlateVisibility_SelfHitTestInvisible)
        self.pWidgetRef.btnSet:SetVisibility(ESlateVisibility_Visible)
    else
        self:ClearSelect()
    end

    if self.nFrom == SettingLayoutFromDef.HUMAN then
        SetHumanSettingUseSub(self)
    end
    
end

function UPSettingUseSub:ClearSelect()
    self.pWidgetRef.imgSelect:SetVisibility(ESlateVisibility_Collapsed)
    self.pWidgetRef.btnSet:SetVisibility(ESlateVisibility_Collapsed)
end

return UPSettingUseSub