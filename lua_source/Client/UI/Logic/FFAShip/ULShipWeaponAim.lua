-----------------------------------------------------
--File Name    : ULShipWeaponAim.lua
--Author       : Song Fuhao
--Create Time  : 2020-08-11
--Description  : 舰船武器准镜UI逻辑
-----------------------------------------------------
local luaclass = require("luaclass")
local UILogicBase = require("UILogicBase")
local BattleItemSystemClient = require("BattleItemSystemClient")
local BattleItemCategoryDef = require("BattleItemCategoryDef")
local BattleShipWeaponSystem = dynamic_require("BattleShipWeaponSystem")
local ShipWeaponAttachmentTypeDef = require("ShipWeaponAttachmentTypeDef")
local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
local ClientEventDef = require("ClientEventDef")
local CameraGameHelper = require("CameraGameHelper")
local GameCameraModeGroupDef = require("GameCameraModeGroupDef")
local PropName = require("PropName")
local UIDef = require("UIDef")
local UIManager = require("UIManager")
local PropValueBindHandle = require("PropValueBindHandle")
local CommonEventDef = require("CommonEventDef")
local CameraIni = require("CameraIni")

local ULShipWeaponAim = luaclass("ULShipWeaponAim", UILogicBase)

ULShipWeaponAim.bIsInAim = false

local function LOG(...)
    log("[ULShipWeaponAim]", ...)
end

local function GetShipAimingParams(tbPlayer)
    local ActiveWeapon = BattleShipWeaponSystem:GetActiveWeaponItem(tbPlayer)
    if not ActiveWeapon then
        return nil
    end
    local nActiveWeaponInstanceId = ActiveWeapon:GetInstanceId()
    local tbSight = BattleItemSystemClient:GetEquippedItem(
        BattleItemCategoryDef.SHIP_WEAPON_ATTACHMENT,
        nActiveWeaponInstanceId,
        ShipWeaponAttachmentTypeDef.SIGHT)
    if not tbSight then
        return nil
    end
    local nTelescopeScale = tbPlayer.ShipBattlePropertyComponent:GetProp(PropName.nTelescopeScale)
    if nTelescopeScale <= 0 then
        return nil
    end
    local tbSightTemplate = tbSight:GetTemplate()
    if not tbSightTemplate then
        return nil
    end
    return {
        nTargetArmLen = CameraIni.nShipAimArmLen,
        nAimRate = nTelescopeScale,
        nMoveXScale = tbSightTemplate.nCameraMoveScaleX,
        nMoveYScale = tbSightTemplate.nCameraMoveScaleY,
    }
end

local function SetIsInAim(self, bIsInAim)
    LOG("SetIsInAim", bIsInAim)
    BattleShipWeaponSystem:RequestChangeAimState(bIsInAim)
end

local function TryToSwitchCamera(self)
    LOG("TryToSwitchCamera")
    if self.bIsInAim then
        local tbShipAimingParams = GetShipAimingParams(GamePlayerSelfHelper:Get())
        if tbShipAimingParams then
            LOG("Switch to aiming camera")
            self.EventHelper:FireEvent(ClientEventDef.EV_ACTIVE_CAMERA_GROUP, GameCameraModeGroupDef.ShipAiming, tbShipAimingParams)
        else
            SetIsInAim(self, false)
            return false
        end
    elseif CameraGameHelper.IsShipAiming() then
        LOG("Switch to common camera")
        self.EventHelper:FireEvent(ClientEventDef.EV_DEACTIVE_CAMERA_GROUP, GameCameraModeGroupDef.ShipAiming,  { bWithAnim = false })
    end
    return true
end

local function OnIsInAimChanged(self, bIsInAim)
    LOG("OnIsInAimChanged", bIsInAim)
    if self.bIsInAim ~= bIsInAim then
        self.bIsInAim = bIsInAim
        if TryToSwitchCamera(self) then
            local pUEActor = GamePlayerSelfHelper:GetUEActor()
            if pUEActor then
                if bIsInAim then
                    -- Visible particle only(we won't hide wave)
                    pUEActor:ActivateParticle(bIsInAim)
                    -- Hide Ship
                    pUEActor:SetActorHiddenInGame(bIsInAim)
                else
                    -- Hide Ship
                    pUEActor:SetActorHiddenInGame(bIsInAim)

                    -- Visible particle only(we won't hide wave)
                    pUEActor:ActivateParticle(bIsInAim)
                end

            end
            self.pWidgetRef.chkAim:SetIsChecked(bIsInAim)
        end
    end
end

local function OnShipAimStateChanged(self, tbCharacter, bIsInAim)
    if GamePlayerSelfHelper:IsPlayerSelf(tbCharacter) then
        OnIsInAimChanged(self, bIsInAim)
    end
end

local function OnTelescopeScaleChanged(self, nTelescopeScale)
    LOG("OnTelescopeScaleChanged", nTelescopeScale)
    local pVisibility = (nTelescopeScale > 0) and ESlateVisibility.Visible or ESlateVisibility.Collapsed
    self.pWidgetRef.chkAim:SetVisibility(pVisibility)
end

local function OnChkAimCheckStateChanged(self, bIsChecked)
    LOG("OnChkAimCheckStateChanged", bIsChecked)
    self.pWidgetRef.chkAim:SetIsChecked(not bIsChecked)
    SetIsInAim(self, bIsChecked)
end

local function ToggleAimPC(self)
    local bIsChecked = self.pWidgetRef.chkAim:IsChecked()
    OnChkAimCheckStateChanged(self, not bIsChecked)
end

local function CheckWinAimCamera(self)
    local tbPlayer = GamePlayerSelfHelper:Get()
    if tbPlayer and tbPlayer:IsShip() and self.bIsInAim then
        OnIsInAimChanged(self, false)
        tbPlayer.pUEActor:SetMastVisible(true)
    end
end

-- 恢复准镜相关逻辑，如果恢复的时候处于开镜状态，则主动关镜
local function RestoreAim(self)
    local tbPlayer = GamePlayerSelfHelper:Get()
    local ShipBattlePropertyComponent = tbPlayer.ShipBattlePropertyComponent
    local nTelescopeScale = ShipBattlePropertyComponent:GetProp(PropName.nTelescopeScale)
    OnTelescopeScaleChanged(self, nTelescopeScale)
    if self.bIsInAim then
        OnIsInAimChanged(self, false)
    end
end

local function BindEventInternal(self)
    local EventHelper = self.EventHelper
    local tbPlayer = GamePlayerSelfHelper:Get()
    local PropComponent = tbPlayer.ShipBattlePropertyComponent
    EventHelper:RegisterHandle(PropValueBindHandle:Bind(PropComponent, PropName.nTelescopeScale, OnTelescopeScaleChanged, self))
    EventHelper:RegisterEvent(CommonEventDef.EV_ON_SHIP_AIM_STATE_CHANGED, self, OnShipAimStateChanged)
    EventHelper:RegisterEvent(ClientEventDef.EV_CHECK_WIN_AIM_CAMERA, self, CheckWinAimCamera)
    EventHelper:RegisterEvent(ClientEventDef.EV_UI_SHIP_TOGGLE_AIM_PC, self, ToggleAimPC)
    EventHelper:RegisterCppDelegate(self.pWidgetRef.chkAim.OnCheckStateChanged, self, OnChkAimCheckStateChanged)
end

function ULShipWeaponAim:OnLoad()
    local tbWnd = UIManager:GetWnd(UIDef.UI_FFA_MAIN)
    if tbWnd then
        self.pWidgetRef.chkAim:SetTouchInputUserWidget(tbWnd.pWidgetRef)
    end
end

function ULShipWeaponAim:Activate()
    LOG("Activate")
    RestoreAim(self)
    BindEventInternal(self)
end

function ULShipWeaponAim:Deactivate()
    LOG("Deactivate")
    self.EventHelper:UnregisterAll()
end

return ULShipWeaponAim