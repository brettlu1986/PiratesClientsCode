local luaclass = require ("luaclass")
local PrefabBase = require("PrefabBase")
local UPSettingUse = luaclass("UPSettingUse", PrefabBase)

local UIDef = require("UIDef")
local SettingLayoutFromDef = require("SettingLayoutFromDef")
local SettingSystemNew = require("SettingSystemNew")
local SettingClassType = require("SettingClassType")

local SUB_PREFAB_WIDGET_NAME =
{
    [SettingLayoutFromDef.HUMAN] = "pbHumanSub",
    [SettingLayoutFromDef.SHIP] = "pbShipSub",
    [SettingLayoutFromDef.VEHICLE] = "pbVehicleSub",
}

local LAYOUT_FROM =
{
    SettingLayoutFromDef.HUMAN,
    SettingLayoutFromDef.SHIP,
    SettingLayoutFromDef.VEHICLE,
}
local DEFAULT_FROM = SettingLayoutFromDef.HUMAN

UPSettingUse.tbSubPrefab = {}

local function OnSelectFrom(self, nFrom)
    for k, v in pairs(LAYOUT_FROM) do
        if v ~= nFrom then
            self.tbSubPrefab[v]:ClearSelect()
        end
    end
end

function UPSettingUse:OnLoad()
    for k, v in pairs(LAYOUT_FROM) do
        local pbSub = self.PrefabHelper:BindPrefab(self.pWidgetRef[SUB_PREFAB_WIDGET_NAME[v]], UIDef.UP_SETTING_USE_SUB)
        local tbSettingOperationMode= SettingSystemNew:GetInstance(SettingClassType.Setting_OperationMode)
        local nOperationMode = tbSettingOperationMode.ModeDef.WithButton
        pbSub:SetData(v, DEFAULT_FROM, function()
            OnSelectFrom(self, v)
        end)
        if v == SettingLayoutFromDef.SHIP then
            nOperationMode = tbSettingOperationMode:GetShipOperationMode()
        elseif v == SettingLayoutFromDef.VEHICLE then
            nOperationMode = tbSettingOperationMode:GetVehicleOperationMode()
        end
        pbSub:InitControlMode(nOperationMode)
        self.tbSubPrefab[v] = pbSub
    end
end



return UPSettingUse
