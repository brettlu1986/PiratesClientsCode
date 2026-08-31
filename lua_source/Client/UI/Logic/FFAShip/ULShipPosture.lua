
local luaclass = require("luaclass")
local UILogicBase = require("UILogicBase")
local ULShipPosture = luaclass("ULShipPosture", UILogicBase)

local UIDef = require("UIDef")
local FFAItemIni = require("FFAItemIni")
local ClientEventDef = require("ClientEventDef")
local ShipMovementDef = require("ShipMovementDef")
local SettingSystemNew = require("SettingSystemNew")
local SettingClassType = require("SettingClassType")
local GamePlayerSelfHelper = require("GamePlayerSelfHelper")

local LuaPosture = ShipMovementDef.ShipPostureDef

ULShipPosture.nPosture = LuaPosture.FullSail
ULShipPosture.bCachePosture = false

local function SetPosture(self, nPosture)
    local MovementComponent = GamePlayerSelfHelper:Get().BattleShipMovementComponent
    if MovementComponent then
        self.EventHelper:FireEvent(ClientEventDef.EV_UI_SHIP_SET_POSTURE, self.nPosture, nPosture)
        return MovementComponent:SetPosture(nPosture)
    end
end

local function GetPosture(self)
    local MovementComponent = GamePlayerSelfHelper:Get().BattleShipMovementComponent
    if MovementComponent then
        return MovementComponent:GetPosture()
    else
        return LuaPosture.FullSail
    end
end

local function UpdateCheckBoxState(self)
    self.pWidgetRef.chkPostureReef:SetIsChecked(self.nPosture == LuaPosture.Reef)
    self.pWidgetRef.chkPostureHalfSail:SetIsChecked(self.nPosture == LuaPosture.HalfSail)
end

local function OnPostureReefStateChanged(self, bIsChecked)
    self.bCachePosture = false
    self.pWidgetRef.chkPostureReef:SetIsChecked(not bIsChecked)
    SetPosture(self, bIsChecked and LuaPosture.Reef or LuaPosture.FullSail)
end

local function OnPostureHalfSailStateChanged(self, bIsChecked)
    self.bCachePosture = false
    self.pWidgetRef.chkPostureReef:SetIsChecked(not bIsChecked)
    SetPosture(self, bIsChecked and LuaPosture.HalfSail or LuaPosture.FullSail)
end

local function OnShipInputDataChanged(self, pInputData)
    local nPosture = enumtoint(pInputData.Posture)
    if nPosture ~= self.nPosture then
        self.nPosture = nPosture
        UpdateCheckBoxState(self)
    end
end

------------------------------------
-- For Pickup Begin
local function ChangePostureByPickupState(self, nPosture)
    SetPosture(self, nPosture)
end

local function OnClickPickupBox(self)
    local tbSettingPickUp = SettingSystemNew:GetInstance(SettingClassType.Setting_PickUp)
    -- SettingSystemNew:SetUseDefaultSaveId(true)
    local bAutoChangeSail = tbSettingPickUp:IsAutoChangeSail()
    -- SettingSystemNew:SetUseDefaultSaveId(false)
    if not bAutoChangeSail then
        return
    end

    if self.nPosture ~= LuaPosture.FullSail then
        return
    end

    local tbShipPickupBox = FFAItemIni.tbShipPickupBox
    ChangePostureByPickupState(self, tbShipPickupBox.nPosture)
    self.bCachePosture = true
end

local function OnLeavePickupBox(self)
    if not self.bCachePosture then
        return
    end
    ChangePostureByPickupState(self, LuaPosture.FullSail)
    self.bCachePosture = false
end

local function OnCloseUI(self, szWndName)
    if szWndName ~= UIDef.UI_PICKUP_BOX then
        return
    end
    if not self.bCachePosture then
        return
    end
    ChangePostureByPickupState(self, LuaPosture.FullSail)
    self.bCachePosture = false
end
-- For Pickup End
------------------------------------

function ULShipPosture:Activate()
    if self.bCachePosture then
        ChangePostureByPickupState(self, LuaPosture.FullSail)
        self.bCachePosture = false
    end

    self.nPosture = GetPosture(self)
    UpdateCheckBoxState(self)

    self.EventHelper:RegisterCppDelegate(self.pWidgetRef.chkPostureReef.OnCheckStateChanged, self, OnPostureReefStateChanged)
    self.EventHelper:RegisterCppDelegate(self.pWidgetRef.chkPostureHalfSail.OnCheckStateChanged, self, OnPostureHalfSailStateChanged)

    local DelegateComponent = GamePlayerSelfHelper:Get().DelegateComponent
    self.EventHelper:RegisterLuaDelegate(DelegateComponent.OnShipInputDataChanged, OnShipInputDataChanged, self)

    self.EventHelper:RegisterEvent(ClientEventDef.EV_ON_CLICK_PICKUP_BOX, self, OnClickPickupBox)
    self.EventHelper:RegisterEvent(ClientEventDef.EV_ON_LEAVE_PICKUP_BOX, self, OnLeavePickupBox)
    self.EventHelper:RegisterEvent(ClientEventDef.EV_PRE_CLOSE_UI, self, OnCloseUI)

    -- 用于PC操作
    self.EventHelper:RegisterEvent(ClientEventDef.EV_UI_SHIP_REEF_PC, self, OnPostureReefStateChanged)
    self.EventHelper:RegisterEvent(ClientEventDef.EV_UI_SHIP_HALF_SAIL_PC, self, OnPostureHalfSailStateChanged)
end

function ULShipPosture:Deactivate()
    self.EventHelper:UnregisterAll()
end

return ULShipPosture
