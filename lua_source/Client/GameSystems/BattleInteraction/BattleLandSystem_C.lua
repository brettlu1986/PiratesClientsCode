local luaclass = require("luaclass")
local BattleLandSystemClass = require("BattleLandSystem")
local BattleLandSystem_C = luaclass("BattleInteractionSystem_C", BattleLandSystemClass)

local CommonEventDef = require("CommonEventDef")
local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
local SelfEventHelper = require("SelfEventHelper")
local ClientEventDef = require("ClientEventDef")
local InteractionDef = require("InteractionDef")
local NetworkManager = dynamic_require("NetworkManager")
local ProtoDC = require("DungeonCommonProtoNames")
local ProtoDR = require("DungeonRepProtoNames")
local UIDef = require("UIDef")
local HumanVehicleStateDef = require("HumanVehicleStateDef")
local HumanMovementStateType = require("HumanMovementStateType")
local UIUtils = require("UIUtils")
local UITextDef = require("UITextDef")
local Timer = require("Timer")
local ChangeDisplayIni = require("ChangeDisplayIni")
local SettingSystemNew = require("SettingSystemNew")
local SettingKeyDef = require("SettingKeyDef")
local BattleGameModeSystem  = dynamic_require("BattleGameModeSystem")
local TutorialDungeonIni    = require("TutorialDungeonIni")
local SelfAnimationHelper   = require("SelfAnimationHelper")
local DelayTimer = require("DelayTimer")
local BattleHumanWeaponSystemNew = dynamic_require("BattleHumanWeaponSystemNew")
local HumanCommonIni = require("HumanCommonIni")
local ProgressBarHelper = require("ProgressBarHelper")

BattleLandSystem_C.bCanInteract = false
BattleLandSystem_C.tbTimer = nil
BattleLandSystem_C.bPreInteract = nil
BattleLandSystem_C.pAttachedActor = nil
BattleLandSystem_C.tbDelayTimer = nil
BattleLandSystem_C.bChanging = nil

local BATTLE_CHANGETOSHIP_BAR_ID = 1
local BATTLE_CHANGETOHUMAN_BAR_ID = 8
local INTERVAL = 2
-- local SHIP_TO_HUMAN_ACTOR = "'/Game/Game/OtherObject/AttachedBP/BP_AttachedsShipToHuman.BP_AttachedsShipToHuman_C'"

local function GetRegionDistance(GridTypeManager, pCurLocation, nTargetRegionType)
    local bRet, pNewLocation = GridTypeManager:GetClosestPositionOfRegionType(pCurLocation.X, pCurLocation.Y, nTargetRegionType)
    assert(bRet)
    if bRet then
        local dx = pCurLocation.X - pNewLocation.X
        local dy = pCurLocation.Y - pNewLocation.Y
        return math.sqrt(dx * dx + dy * dy)
    end
    logwarning("BattleLandSystem GetRegionDistance Failed: ", pCurLocation.X, pCurLocation.Y, nTargetRegionType)
    return 0
end

local function SetPreInteract(self, bPreInteract)
    self.bPreInteract = bPreInteract
end

local function IsTutorialDungeon()
    local nDungeonId = BattleGameModeSystem.nDungeonId
    if nDungeonId == TutorialDungeonIni.nDungeonId then
        return true
    end
    return false
end

local function VerifyPlayerSelfPreInteractState(self, bForce)
    local bPreInteract = false

    if self.bCanInteract then 
        local tbPlayerSelf = GamePlayerSelfHelper:Get()
        if tbPlayerSelf == nil then
            return
        end
        local GridTypeManager = CommonShell.GetCommon(GWorld):GetGridTypeManager()
        local pLocation = tbPlayerSelf:GetLocation()
        local nRegionType = GridTypeManager:GetRegionType(pLocation.X, pLocation.Y)

        if tbPlayerSelf:IsHuman() then
            if nRegionType == self.TYPE_OCEAN then
                bPreInteract = true
            elseif nRegionType == self.TYPE_LAND then
                -- logerror("land, ", GetRegionDistance(GridTypeManager, pLocation, self.TYPE_OCEAN))
                if GetRegionDistance(GridTypeManager, pLocation, self.TYPE_OCEAN) <= ChangeDisplayIni.nPreChangeShipDistance then
                    bPreInteract = true
                end
            end
        else
            if nRegionType == self.TYPE_OCEAN then
                -- logerror("ocean, ", GetRegionDistance(GridTypeManager, pLocation, self.TYPE_LAND))
                if GetRegionDistance(GridTypeManager, pLocation, self.TYPE_LAND) <= ChangeDisplayIni.nPreChangeHumanDistance then
                    bPreInteract = true
                end            
            end
        end
    end
    if not bForce and self.bPreInteract ~= nil and self.bPreInteract == bPreInteract then
        return
    end
    
    if bPreInteract then
        bPreInteract = not IsTutorialDungeon()
    end
    self.EventHelper:FireEvent(ClientEventDef.EV_UI_PRE_CHANGE_DISPLAY, bPreInteract)
    SetPreInteract(self, bPreInteract)
end

local function VerifyPlayerSelfInteractState(self)
    if(not self.bCanInteract) then
        return
    end
    
    local nTargetRegionType = self:GetTargetRegionTypeByLocation(GamePlayerSelfHelper:Get())
    if nTargetRegionType ~= nil then
        SetPreInteract(self, false)        
        self.EventHelper:FireEvent(ClientEventDef.EV_UI_CHANGE_DISPLAY, nTargetRegionType ~= nil, InteractionDef.InteractionMode.CHANGE_DISPLAY)    
    else
        VerifyPlayerSelfPreInteractState(self, true)
    end
end

local function OnGridTypeChanged(self, tbGameObject, nRegionType)    
    if(tbGameObject == GamePlayerSelfHelper:Get()) then
        VerifyPlayerSelfInteractState(self)
    end        
end

local function OnRequestChangeDisplay(self)
    local tbPlayerSelf = GamePlayerSelfHelper:Get()
    if tbPlayerSelf ~= nil then
        if not ProgressBarHelper.CanStartHumanProgressBar(tbPlayerSelf, true) then
            return
        end
        local pLocation = tbPlayerSelf:GetLocation()
        log("start change display: ", tbPlayerSelf.szName, pLocation.X, pLocation.Y)

        local HumanMovementStateComponent = tbPlayerSelf.HumanMovementStateComponent
        if HumanMovementStateComponent then 
            local nVehicleState = HumanMovementStateComponent:GetVehicleState()
            if nVehicleState == HumanVehicleStateDef.PreDetachFromVehicle or nVehicleState == HumanVehicleStateDef.PreAttachToVehicle then 
                UIUtils.ShowToast(UITextDef.CANNOT_START_PROGRESSBAR)
                return
            end
            local nMovementState = HumanMovementStateComponent:GetCurrentState()
            if HumanMovementStateComponent.bIsCrouching and nMovementState == HumanMovementStateType.Crawl_State then  
                return 
            end
        end
    end
    self.EventHelper:FireEvent(CommonEventDef.EV_INTERRUPT_CONTINUOUS_RUN)
	NetworkManager:GetRPCNetworkProxy():SendToServer(ProtoDC.c2d_StartChangeDisplay, {})
end

local function OnBreakChangingDisplay(self)
    -- 打断后得在判断下是否还需要show按钮
    VerifyPlayerSelfInteractState(self)
end

local function OnRequestBreakChangingDisplay(self)
	NetworkManager:GetRPCNetworkProxy():SendToServer(ProtoDC.c2d_BreakChangeDisplay, {})
end

local function DestroyTimer(self)
    if self.tbTimer ~= nil then
        self.tbTimer:Clear()
        self.tbTimer = nil
    end

end

local function SetInteract(self, bValue)
    if self.bCanInteract == bValue then
        return
    end
    self.bCanInteract = bValue
    VerifyPlayerSelfPreInteractState(self)
    VerifyPlayerSelfInteractState(self)
end

local function OnParachutionEnd(self)
    log("parachutionend landsystem 1:", os.time())
    SetInteract(self, true)
    log("parachutionend landsystem 2:", os.time())
end

local function OnFFATransportChanged(self, nState)
    if nState == ProtoDR.rFFATransportState_EState.MOVING then
        SetInteract(self, false)
	end
end

local function OnLoadMap(self)
    SetInteract(self, false)
end

local function SetTimer(self)
    local nSettingValue = SettingSystemNew:Get(SettingKeyDef.LocalKeys.CHANGE_DISPLAY)
    if nSettingValue == 0 or IsTutorialDungeon() then
        DestroyTimer(self)
        SetPreInteract(self, false)
        VerifyPlayerSelfInteractState(self)
        -- self.EventHelper:FireEvent(ClientEventDef.EV_UI_PRE_CHANGE_DISPLAY, false)
    else
        if self.tbTimer == nil then
            self.tbTimer = Timer.NewTimerMethod(self, VerifyPlayerSelfPreInteractState, INTERVAL, true)
        end
    end
end

local function OnUIBattleOpen(self, szWndName)
    if szWndName == UIDef.UI_FFA_MAIN then
        SetTimer(self)
        SetInteract(self, true)
    end
end

local function OnProgressChanged(self, nInstanceId, bStart, nProgressBarId, nProgressBarTime)
    local tbPlayerSelf = GamePlayerSelfHelper:Get()
    if not bStart or tbPlayerSelf:GetServerInstanceId() ~= nInstanceId then  
        return 
    end
    if nProgressBarId == BATTLE_CHANGETOSHIP_BAR_ID or nProgressBarId == BATTLE_CHANGETOHUMAN_BAR_ID then
        self.EventHelper:FireEvent(ClientEventDef.EV_UI_CHANGE_DISPLAY, false)
    end
end

local function OnPlayerSelfReady(self)
    VerifyPlayerSelfPreInteractState(self)
end

local function OnSettingChangeDisplay(self)
    SetTimer(self)
end

local function DestroyDelayTimer(self)
    if self.tbDelayTimer ~= nil then  
        DelayTimer:ClearTimer(self.tbDelayTimer)
        self.tbDelayTimer = nil 
    end 
end

local function OnPlayShipToHumanAni(self, _, Owner)
    if not self.bChanging then
        return
    end

    local SelfPlayer = GamePlayerSelfHelper:Get()
    if Owner ~= nil and SelfPlayer ~= Owner then
        return
    end

    SelfAnimationHelper:PlayHumanAnimation(SelfPlayer, SelfAnimationHelper.AnimDef.SHIP_TO_HUMAN)
    self.bChanging = nil

    DestroyDelayTimer(self)
    local nDelayTime = HumanCommonIni.tbHumanCommonData.nDelayReholdTime
    self.tbDelayTimer = DelayTimer:DelayRun(function()
        DestroyDelayTimer(self)
        local nHoldWeapon = self.nHoldWeapon
        if SelfPlayer:IsHuman() and nHoldWeapon ~= 0 then
            BattleHumanWeaponSystemNew:SetCurrentWeapon(SelfPlayer, nHoldWeapon)
            self.nHoldWeapon = 0
        end        
    end, nDelayTime)

end

local function OnPareparePlayShipToHumanAni(self)
    local SelfPlayer = GamePlayerSelfHelper:Get()
    BattleHumanWeaponSystemNew:SaveCurrentWeaponToOwner(SelfPlayer)
    self.bChanging = true
    local tbCurrentWeapon = SelfPlayer.HumanWeaponComponent:GetCurrentWeapon()
    if tbCurrentWeapon then 
        self.nHoldWeapon = SelfPlayer.HumanWeaponComponent:GetCurrentWeaponInstanceId()
        BattleHumanWeaponSystemNew:SetCurrentWeapon(SelfPlayer, 0, true)
    else
        OnPlayShipToHumanAni(self)
    end
end

function BattleLandSystem_C:Init()
    if(not BattleLandSystem_C.super.Init(self)) then
        return false
    end

	self.EventHelper = SelfEventHelper()
	-- self.EventHelper:RegisterEvent(CommonEventDef.EV_GAME_ACTOR_ENTER_VOLUME, self, OnEnterVolume)
	-- self.EventHelper:RegisterEvent(CommonEventDef.EV_GAME_ACTOR_LEAVE_VOLUME, self, OnLeaveVolume)
	self.EventHelper:RegisterEvent(ClientEventDef.EV_UI_REQUEST_CHANGEDISPLAY, self, OnRequestChangeDisplay)
	self.EventHelper:RegisterEvent(ClientEventDef.EV_BATTLE_CHANGINGDISPLAY_BREAK, self, OnBreakChangingDisplay)
	self.EventHelper:RegisterEvent(ClientEventDef.EV_UI_COLLECTION_BREAK, self, OnRequestBreakChangingDisplay)
	self.EventHelper:RegisterEvent(ClientEventDef.EV_FFA_PARACHUTION_END, self, OnParachutionEnd)
    self.EventHelper:RegisterEvent(ClientEventDef.EV_FFA_TRANSPORT_STATE_CHANGED, self, OnFFATransportChanged)
    self.EventHelper:RegisterEvent(ClientEventDef.EV_POST_LOAD_MAP, self, OnLoadMap)
    self.EventHelper:RegisterEvent(ClientEventDef.EV_OPEN_UI, self, OnUIBattleOpen)
    self.EventHelper:RegisterEvent(CommonEventDef.EV_GRID_TYPE_CHANGED, self, OnGridTypeChanged)
    self.EventHelper:RegisterEvent(CommonEventDef.EV_PROGRESS_CHANGED, self, OnProgressChanged)
    self.EventHelper:RegisterEvent(ClientEventDef.EV_PLAYERSELF_READY, self, OnPlayerSelfReady)
    self.EventHelper:RegisterEvent(ClientEventDef.EV_SETTING_CHANGE_DISPLAY, self, OnSettingChangeDisplay)
    self.EventHelper:RegisterEvent(ClientEventDef.EV_PLAY_SHIP_TO_HUMAN_ANI, self, OnPareparePlayShipToHumanAni)
    self.EventHelper:RegisterEvent(ClientEventDef.EV_HUMAN_WEAPON_STATE_CHANGED_CLIENT, self, OnPlayShipToHumanAni) 
    
    return true
end

function BattleLandSystem_C:Uninit() 
    DestroyTimer(self)
    DestroyDelayTimer(self)
	self.EventHelper:UnregisterAll()
    self.EventHelper = nil
    BattleLandSystem_C.super.Uninit(self)
end

return BattleLandSystem_C()