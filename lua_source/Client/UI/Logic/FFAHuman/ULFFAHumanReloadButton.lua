-----------------------------------------------------
--File Name    : ULFFAHumanReloadButton.lua
--Author       : WuJizhou
--Create Time  : 4/2/2019, 4:09:07 PM
--Description  : ULFFAHumanReloadButton
-----------------------------------------------------
local luaclass = require("luaclass")
local UILogicBase = require("UILogicBase")

local ULFFAHumanReloadButton = luaclass("ULFFAHumanReloadButton", UILogicBase)

local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
local FFAHumanUIHelper = require("FFAHumanUIHelper")
local BattleHumanWeaponSystemNew = require("BattleHumanWeaponSystemNew_C")
-- local GlobalVariableSystem = require("GlobalVariableSystem_C")
local CommonEventDef = require("CommonEventDef")
local HumanWeaponStateDef = require("HumanWeaponStateDef")
local BattleResultSystem = dynamic_require("BattleResultSystem")
local BattleResultDef = require("BattleResultDef")
local ClientEventDef = require("ClientEventDef")

local bReloading = false
local bLastAim = false

local function RefreshReloadBtnVisibility(self, nCurrentWeaponId)
    local pWidgetRef = self.pWidgetRef
    if not nCurrentWeaponId then
        local HumanWeaponComponent = FFAHumanUIHelper.GetSelfWeaponComponent()
        if not HumanWeaponComponent then
            pWidgetRef.btnReload:SetVisibility(ESlateVisibility.Collapsed)
            return
        end
        nCurrentWeaponId = HumanWeaponComponent:GetCurrentWeaponInstanceId()
    end
    pWidgetRef.cpgbReload:SetVisibility(ESlateVisibility.Collapsed)
    pWidgetRef.txtReload:SetVisibility(ESlateVisibility.Collapsed)
    pWidgetRef.ovlReload:SetVisibility(ESlateVisibility.Collapsed)
    local bNotVisible = FFAHumanUIHelper.IsEmptyInHand(nCurrentWeaponId)
                        or FFAHumanUIHelper.IsMeleeWeaponInHand(nCurrentWeaponId)
                        or FFAHumanUIHelper.IsThrownItemInHand(nCurrentWeaponId)
    if bNotVisible then
        pWidgetRef.btnReload:SetVisibility(ESlateVisibility.Collapsed)
    else
        pWidgetRef.btnReload:SetVisibility(ESlateVisibility.Visible)
    end
end

local function CheckToRecoverAim(self, bCancel)
    local PlayerSelf = GamePlayerSelfHelper:Get()
    local bFalling = false  
    if PlayerSelf and PlayerSelf.pUEActor then  
        bFalling = PlayerSelf.pUEActor.CharacterMovement.MovementMode == EMovementMode.MOVE_Falling
    end  

    local bWin = BattleResultSystem:GetBattleResult() == BattleResultDef.WIN   
    if bCancel or bFalling or bWin then  
        bLastAim = false
    end
    if bLastAim then  
        local bSuccess = BattleHumanWeaponSystemNew:RequestSetAim(true)
        if bSuccess then
            self.Owner:ChangeClientAimState(true)
            bLastAim = false
        end
    end
end

local function OnHumanWeaponReloadDeactivate(self, nPlayerId, bCancel)
    if nPlayerId ~= GamePlayerSelfHelper:GetServerInstanceId() then
        return
    end
    local pWidgetRef = self.pWidgetRef
    pWidgetRef.cpgbReload:StopAnimation()
    pWidgetRef.cpgbReload:SetVisibility(ESlateVisibility.Collapsed)
    pWidgetRef.txtReload:StopTimer()
    pWidgetRef.txtReload:SetVisibility(ESlateVisibility.Collapsed)

    pWidgetRef.txtReload2:StopTimer()
    pWidgetRef.ovlReload:SetVisibility(ESlateVisibility.Collapsed)
    pWidgetRef.btnReload:SetRenderOpacity(1)
    local HumanWeaponComponent = FFAHumanUIHelper.GetSelfWeaponComponent()
    if not self.Owner.bInhibitAttack then
        if HumanWeaponComponent and not HumanWeaponComponent.bInhibitAttack then
            local nCurrentWeaponId = HumanWeaponComponent:GetCurrentWeaponInstanceId()
            if not HumanWeaponComponent:IsAiming() then
                self.Owner.ulHumanAim:OnCurrentWeaponChanged(nCurrentWeaponId)
                self.Owner.ulHumanAim:RefreshCenterAim(false, false)
            end
        end
    end
    bReloading = false

    if not HumanWeaponComponent:IsAiming() then
        CheckToRecoverAim(self, bCancel)
    end
end

local function CheckToUnAim(self)
    local WeaponComponent = GamePlayerSelfHelper:Get().HumanWeaponComponent
    local bAim = WeaponComponent and WeaponComponent:IsAiming() or false

    if bAim then 
        local bSuccess = BattleHumanWeaponSystemNew:RequestSetAim(false)
        if bSuccess then
            self.Owner:ChangeClientAimState(false)
            bLastAim = true
        end
    end
end

local function OnHumanWeaponReloadActivate(self, nTime, nPlayerId)
    if nPlayerId ~= GamePlayerSelfHelper:GetServerInstanceId() then
        return
    end

    if nTime > 0 then
        bReloading = true
        local pWidgetRef = self.pWidgetRef
        pWidgetRef.cpgbReload:StartAnimation(0, 1, nTime)
        pWidgetRef.cpgbReload:SetVisibility(ESlateVisibility.HitTestInvisible)
        pWidgetRef.txtReload:SetDetailMode(1)
        pWidgetRef.txtReload:StartTimer(nTime , 0.1, {"s"}, EMinTimeUnit.Second)
        pWidgetRef.txtReload:SetVisibility(ESlateVisibility.HitTestInvisible)

        pWidgetRef.ovlReload:SetVisibility(ESlateVisibility.HitTestInvisible)
        pWidgetRef.cpgbReload2:SetPercent(0)
        pWidgetRef.cpgbReload2.AnimDuration = nTime
        pWidgetRef.cpgbReload2:SetPercent(1, true)
        pWidgetRef.txtReload2:SetDetailMode(1)
        pWidgetRef.txtReload2:StartTimer(nTime , 0.1, {"s"}, EMinTimeUnit.Second)
        pWidgetRef.btnReload:SetRenderOpacity(0)
        self.Owner.ulHumanAim:RefreshCenterAim(true, true)
    else
        OnHumanWeaponReloadDeactivate(self, nPlayerId)
    end

    CheckToUnAim(self)
end

--装填
local function OnReloadClicked(self)
    local WeaponComponent = FFAHumanUIHelper.GetSelfWeaponComponent()
    if WeaponComponent:GetCurrentState() == HumanWeaponStateDef.ATTACKING then
        return
    end
    BattleHumanWeaponSystemNew:RequestReload()
end

local function BeginPickUp(self)
    if bLastAim then  
        bLastAim = false
    end
end

function ULFFAHumanReloadButton:Refresh(nNewWeapon)
    RefreshReloadBtnVisibility(self, nNewWeapon)
end

function ULFFAHumanReloadButton:HideButton()
    self.pWidgetRef.btnReload:SetVisibility(ESlateVisibility.Collapsed)
end

function ULFFAHumanReloadButton:Activate()
    if not bReloading then
        RefreshReloadBtnVisibility(self)
    end
end

function ULFFAHumanReloadButton:Deactivate()
end

----------life cycle----------

function ULFFAHumanReloadButton:OnLoad()
    bReloading = false
    local pWidgetRef = self.pWidgetRef
    pWidgetRef.txtReload:SetPrecision(1)
    pWidgetRef.txtReload2:SetPrecision(1)
end


function ULFFAHumanReloadButton:OnBindEvent( EventHelper )
    EventHelper:RegisterCppDelegate(self.pWidgetRef.btnReload.OnClicked, self, OnReloadClicked)
    EventHelper:RegisterEvent(CommonEventDef.EV_HUMAN_WEAPON_RELOADED_DEACTIVATE, self, OnHumanWeaponReloadDeactivate)
    EventHelper:RegisterEvent(CommonEventDef.EV_HUMAN_WEAPON_RELOADED_ACTIVATE, self, OnHumanWeaponReloadActivate)
    EventHelper:RegisterEvent(ClientEventDef.EV_BATTLE_BEGIN_PICKUP, self, BeginPickUp)
end


-- function ULFFAHumanReloadButton:OnUnbindEvent( EventHelper )
-- end

return ULFFAHumanReloadButton