-----------------------------------------------------
--File Name    : UPFFAHuman.lua
--Description  : UPFFAHuman
-----------------------------------------------------
local luaclass = require ("luaclass")
local UPFFABase = require("UPFFABase")
local UPFFAHuman = luaclass("UPFFAHuman", UPFFABase)

local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
local UISetUtils = require("UISetUtils")
local UIUtils = require("UIUtils")
local ClientEventDef = require("ClientEventDef")
local CommonEventDef = require("CommonEventDef")
local BattleItemDataTable = require("BattleItemDataTable")
local BattleItemCategoryDef = require("BattleItemCategoryDef")
local HumanMovementStateType = require("HumanMovementStateType")
local HumanWeaponDef = require("HumanWeaponDef")
local BattleItemSystemHelper = require("BattleItemSystemHelper")
local HumanWeaponStateDef = require("HumanWeaponStateDef")
local ProtoDR = require("DungeonRepProtoNames")
local ControlModeSystem = require("ControlModeSystem")
local ControlModeDef = require("ControlModeDef")
local HumanCapsuleDataTable = require("HumanCapsuleDataTable")
local GameCameraModeGroupDef = require("GameCameraModeGroupDef")
local GameCameraSystem = require("GameCameraSystem")
local DelayTimer = require("DelayTimer")
local BattleHumanWeaponSystemNew = require("BattleHumanWeaponSystemNew_C")
local HumanWeaponMisc = require("HumanWeaponMisc")
local HumanThrownItemDef = require("HumanThrownItemDef")
local GameObjectSystem = dynamic_require("GameObjectSystem")
local SettingSystemNew = require("SettingSystemNew")
local SettingKeyDef = require("SettingKeyDef")
local BattleGameModeSystem = dynamic_require("BattleGameModeSystem")
local TutorialDungeonIni = require("TutorialDungeonIni")
local DestructibleObjectInteractionalSystem = require("DestructibleObjectInteractionalSystem_C")
local GlobalVariableSystem = dynamic_require("GlobalVariableSystem")
local SelfAnimationHelper = require("SelfAnimationHelper")
local CameraIni = require("CameraIni")

local HumanWeaponType = HumanWeaponMisc.Type
local ThrownItemCategory = HumanThrownItemDef.ItemCategory

local OPEN_DOOR_IMG = "PaperSprite'/Game/UI/FFA/Textures/UI_FFAMain/Frames/Spr_OpenDoor_01.Spr_OpenDoor_01'"
local CLOSE_DOOR_IMG = "PaperSprite'/Game/UI/FFA/Textures/UI_FFAMain/Frames/Spr_CloseDoor_01.Spr_CloseDoor_01'"

UPFFAHuman.OneSecondTimer = nil
UPFFAHuman.ulHumanAim = nil
UPFFAHuman.ulHumanFightBtn = nil
UPFFAHuman.ulFFAHumanThrownItem = nil
UPFFAHuman.ulFFAHumanArmor = nil
UPFFAHuman.ulFFAHumanWeapon = nil
UPFFAHuman.ulFreeView = nil
UPFFAHuman.ulFFAHumanVehicle = nil
UPFFAHuman.ulFFAHumanMovement = nil
UPFFAHuman.btnBoomCancel = nil
UPFFAHuman.tbAddItem = {}
UPFFAHuman.tbCompositeEventHandle = nil
UPFFAHuman.bInhibitAttack = false
UPFFAHuman.bZoomIn = false
UPFFAHuman.tbTimerObject = nil
UPFFAHuman.bActivate = false

UPFFAHuman.fInhibitAttackDistance = 1
UPFFAHuman.bAimBtnEnable = nil

local HUMAN_AIM_SOCKET = "AimSocket"
local ZERO_VEC = Vector{X = 0, Y = 0, Z = 0}
local SETTING_CLOSE = 0
local SETTING_AIMOPEN = 1

local function GetSelfWeaponComponent()
    return GamePlayerSelfHelper:Get().HumanWeaponComponent
end

--获取当前武器是否是 可瞄准发射的武器
local function GetCurrentAimWeapon()
    local WeaponComponent = GetSelfWeaponComponent()
    local nWeaponInstanceId = WeaponComponent:GetCurrentWeaponInstanceId()
    local WeaponItem = BattleItemSystemHelper:GetItem(nWeaponInstanceId, true)

    if nWeaponInstanceId == 0 or WeaponItem == nil then
        log("UPFFAHuman:GetCurrentAimWeapon,tbWeaponItem is nil, nNewWeapon=",nWeaponInstanceId)
        return nil
    elseif (WeaponItem:GetCategory() == BattleItemCategoryDef.HUMAN_THROWN_ITEM) then
        return nil
    else
        local nPrimaryCategory = WeaponItem:GetTemplate().nPrimaryCategory
        if nPrimaryCategory == HumanWeaponDef.WeaponPrimaryCategory.Melee then
            return nil
        end
    end
    return WeaponItem
end


--如果武器有准镜配件，配件属性会覆盖武器属性
local function GetWeaponCameraMoveScale(Weapon)
    local CameraMoveScale = Vector()
    local tbProperty = Weapon:GetProperty(true)
    CameraMoveScale.X = tbProperty.nOpenAimCameraHMoveScale or 1
    CameraMoveScale.Y = tbProperty.nOpenAimCameraVMoveScale or 1
    CameraMoveScale.Z = tbProperty.nOpenAimCameraRate or 1-- the fov rate

    local nOffsetToAim = tbProperty.nOffsetToAim or 0

    return CameraMoveScale, nOffsetToAim
end

local function UpdateLeftHandFireBtn(self)
    local btnFight1 = self.pWidgetRef.btnFight1
    local PlayerSelf = GamePlayerSelfHelper:Get()
    local HumanMovementStateComponent = PlayerSelf.HumanMovementStateComponent
    if (HumanMovementStateComponent and HumanMovementStateComponent:GetCurrentState() == HumanMovementStateType.Swimming) or self.ulFFAHumanVehicle.bInVehicle then
        btnFight1:SetVisibility(ESlateVisibility.Hidden)
    else
        local nValue = SettingSystemNew:Get(SettingKeyDef.LocalKeys.FIRE_BY_LEFT_HAND)
        if nValue == SETTING_CLOSE then
            btnFight1:SetVisibility(ESlateVisibility.Hidden)
        elseif nValue == SETTING_AIMOPEN then
            btnFight1:SetVisibility(self.bZoomIn and ESlateVisibility.Visible or ESlateVisibility.Hidden)
        else
            btnFight1:SetVisibility(ESlateVisibility.Visible)
        end    
    end
end

local function ExitFreeViewInAim(self, bDetach)
    self.EventHelper:FireEvent(ClientEventDef.EV_EXIT_FREE_VIEW, bDetach)
    local GCMgr = GameplayStatics.GetPlayerCameraManager(GWorld, 0)
    if GCMgr and GCMgr.UnInitCameraActorParam and bDetach then 
        GCMgr:UnInitCameraActorParam()
    end
end

local function IsTutorialDungeon()
    local nDungeonId = BattleGameModeSystem.nDungeonId
    if nDungeonId == TutorialDungeonIni.nDungeonId then
        return true
    end
    return false
end

--gyro and aim assist
local function CheckHumanSettingEnable(self, bAim)
    local GCMgr = GameplayStatics.GetPlayerCameraManager(GWorld, 0)
    if IsTutorialDungeon() then   
        GCMgr.EnableGyro = false
        return
    end

    -- SettingSystemNew:SetUseDefaultSaveId(true)
    local nGyroValue = SettingSystemNew:Get(SettingKeyDef.LocalKeys.HUMAN_GYRO)
    local nAimValue = SettingSystemNew:Get(SettingKeyDef.LocalKeys.AIM_ASSIST)
    -- SettingSystemNew:SetUseDefaultSaveId(false)
    
    if nGyroValue == SETTING_AIMOPEN then
        GCMgr.EnableGyro = bAim
    end
    if nAimValue == SETTING_AIMOPEN then  
        local PlayerSelf = GamePlayerSelfHelper:Get()
        if PlayerSelf and PlayerSelf:IsHuman() then 
            local pUEActor = PlayerSelf.pUEActor
            pUEActor.EnableNewAim = bAim
        end
    end

end
--瞄准
local function SetCameraState(self, bZoomIn)
    if(self.bZoomIn == bZoomIn or self.EventHelper == nil) then
        return
    end
    self.bZoomIn = bZoomIn

    local HumanWeaponComponent = GetSelfWeaponComponent()
    if not HumanWeaponComponent then return end

    local CurrentWeapon = GetCurrentAimWeapon()
    if not CurrentWeapon then  return end

    local tbTemplate = CurrentWeapon:GetTemplate()
    if not tbTemplate then  return end

    -- local bUseAimUi = tbTemplate.bUseSniperUi

    if bZoomIn then
        local nCameraMoveScale, nOffsetToAim = GetWeaponCameraMoveScale(CurrentWeapon)
        local nAimArmLen = 0
        if tbTemplate.nWeaponCategory == HumanWeaponDef.WeaponCategory.Bow then
            nAimArmLen = 0
        end

        -- local bDetach = not bUseAimUi
        --ExitFreeViewInAim(self, bDetach)
        ExitFreeViewInAim(self, true)
        self.EventHelper:FireEvent(ClientEventDef.EV_ACTIVE_CAMERA_GROUP, GameCameraModeGroupDef.HumanAiming, {
            nTargetArmLen = nAimArmLen,
            nAimRate = nCameraMoveScale.Z,
            nMoveXScale = nCameraMoveScale.X,
            nMoveYScale = nCameraMoveScale.Y,
            szAimSocket = HUMAN_AIM_SOCKET,
            nOffsetToAim = nOffsetToAim,
            CameraOffset = ZERO_VEC,
        })
        self.ulHumanAim:RefreshCenterAim(self.bInhibitAttack, true)
    else
        self.EventHelper:FireEvent(ClientEventDef.EV_DEACTIVE_CAMERA_GROUP, GameCameraModeGroupDef.HumanAiming, {bWithAnim = true} )
        if not self.bInhibitAttack then
            if HumanWeaponComponent and not HumanWeaponComponent.bInhibitAttack then
                local nCurrentState = HumanWeaponComponent:GetCurrentState()
                if nCurrentState ~= HumanWeaponStateDef.RELOADING then
                    self.ulHumanAim:RefreshCenterAim(false, false)
                end
            end
        end
    end
    -- HumanWeaponComponent:ChangeUEActorStateForAim(bZoomIn)
        
    CheckHumanSettingEnable(self, bZoomIn)
    self.ulFreeView:HideFreeCameraButton(bZoomIn)
    self.EventHelper:FireEvent(ClientEventDef.EV_FFA_AIM_STATE_CHANGED, bZoomIn)
    UpdateLeftHandFireBtn(self)
end

local function CheckWinAimCamera(self)
    local PlayerSelf = GamePlayerSelfHelper:Get()
    if PlayerSelf and PlayerSelf:IsHuman() and PlayerSelf.HumanWeaponComponent then
        if PlayerSelf.HumanWeaponComponent:IsAiming() then
            self.EventHelper:FireEvent(ClientEventDef.EV_DEACTIVE_CAMERA_GROUP, GameCameraModeGroupDef.HumanAiming, {bWithAnim = false} )
            PlayerSelf.HumanWeaponComponent:ChangeUEActorStateForAim(false)
        end
    end
end


local function OnAimStateChanged(self, bIsChecked)
    local pWidgetRef = self.pWidgetRef
    local PlayerSelf = GamePlayerSelfHelper:Get()

    if PlayerSelf and PlayerSelf:IsHuman() then 
        local pUEActor = PlayerSelf.pUEActor
        if  pUEActor then  
            local bPickUpPlay = SelfAnimationHelper:IsHumanMontagePlaying(PlayerSelf, SelfAnimationHelper.AnimDef.PICK_UP)
            if (not pUEActor:IsJumpAnimOver()) or (pUEActor.CharacterMovement.MovementMode == EMovementMode.MOVE_Falling) or bPickUpPlay then
                pWidgetRef.chkAim:SetCheckedState(ECheckBoxState.Unchecked)
                log("[CanNotAim] :", pUEActor:IsJumpAnimOver(), pUEActor.CharacterMovement.MovementMode == EMovementMode.MOVE_Falling, bPickUpPlay)
                return 
            end
        end

    end

    local bSucess  = BattleHumanWeaponSystemNew:RequestSetAim(bIsChecked)
    if(not bSucess) then
        local FailCheckState = bIsChecked and ECheckBoxState.Unchecked or ECheckBoxState.Checked
        pWidgetRef.chkAim:SetCheckedState(FailCheckState)
        if bIsChecked then
            UIUtils.ShowToast(UISetUtils.GetL10NTextByKey("FFA_HUMAN_CAN_NOT_AIM"), 1)
        end
        log("[CanNotAim] : request set aim false")
        return
    else
        local bCurChecked = pWidgetRef.chkAim:GetCheckedState() == ECheckBoxState.Checked
        if bCurChecked ~= bIsChecked then
            local SuccessCheckState = bIsChecked and ECheckBoxState.Checked or ECheckBoxState.Unchecked
            pWidgetRef.chkAim:SetCheckedState(SuccessCheckState)
        end
    end
    SetCameraState(self, bIsChecked)
end

local function OnAimStateClicked(self)
    local bChecked = self.pWidgetRef.chkAim:IsChecked()
    OnAimStateChanged(self, not bChecked)
end

local function IsShowAimCamera(nNewWeapon)
    if not nNewWeapon or nNewWeapon == 0 then
        return false
    else
        local tbWeaponItem = BattleItemSystemHelper:GetItem(nNewWeapon, true)
        if not tbWeaponItem then
            log("UPFFAHuman:IsShowAimCamera,tbWeaponItem is nil, nNewWeapon=",nNewWeapon)
            return false
        elseif(tbWeaponItem:GetCategory() == BattleItemCategoryDef.HUMAN_THROWN_ITEM) then
            return false
        else
            local tbTemplate = tbWeaponItem:GetTemplate()
            local nPrimaryCategory = tbTemplate.nPrimaryCategory
            local nWeaponCategory = tbTemplate.nWeaponCategory
            if nPrimaryCategory == HumanWeaponDef.WeaponPrimaryCategory.Melee or 
                nWeaponCategory == HumanWeaponDef.WeaponCategory.Wand then
                return false
            end
        end
    end
    return true
end



local function RefreshExplosiveBtn(self, nCurrentWeaponId)
    local bShowThrow = false
    if nCurrentWeaponId and nCurrentWeaponId ~= 0 then
        local tbWeaponItem = BattleItemSystemHelper:GetItem(nCurrentWeaponId, true)
        if not tbWeaponItem then
            log("UPFFAHuman:RefreshExplosiveBtn,tbWeaponItem is nil, nNewWeapon=",nCurrentWeaponId)
            return
        end
        if(tbWeaponItem:GetCategory() == BattleItemCategoryDef.HUMAN_THROWN_ITEM) then
            local tbTemplate = tbWeaponItem:GetTemplate()
            if tbTemplate.nThrownItemCategory ~= ThrownItemCategory.Hit then
                bShowThrow = true
            end
        end
    end
    self:SetThrowTrojectoryVisible(bShowThrow)
end

local function SetAimBtnsVisible(self, bVisible)
    if bVisible and self.bAimBtnEnable then  
        self.pWidgetRef.btnAim:SetVisibility(ESlateVisibility.Visible)
        self.pWidgetRef.chkAim:SetVisibility(ESlateVisibility.Visible)
    else   
        self.pWidgetRef.btnAim:SetVisibility(ESlateVisibility.Collapsed)
        self.pWidgetRef.chkAim:SetVisibility(ESlateVisibility.Collapsed)
    end
end

local function RefreshAimBtn(self, nCurrentWeaponId)
    local HumanWeaponComponent = GamePlayerSelfHelper:Get().HumanWeaponComponent
    if not nCurrentWeaponId then
        if not HumanWeaponComponent then
            return false
        end
        nCurrentWeaponId = HumanWeaponComponent:GetCurrentWeaponInstanceId()
    end
    if IsShowAimCamera(nCurrentWeaponId) then
        SetAimBtnsVisible(self, true)
    else
        SetAimBtnsVisible(self, false)
    end
    return true
end


local function ExitOpenAimCamera(self)
    local chkAim = self.pWidgetRef.chkAim

    local bChecked = chkAim:GetCheckedState() == ECheckBoxState.Checked
    if bChecked then
        self.pWidgetRef.chkAim:SetCheckedState(ECheckBoxState.UnChecked)
    end

    local WeaponComponent = GetSelfWeaponComponent()
    local bAiming = WeaponComponent and WeaponComponent:IsAiming() or false
    if not bAiming then  --可能这时候按钮是aim是按下，但是此时武器aiming状态已经退出，比如趴下移动
        --self.pWidgetRef.chkAim:SetCheckedState(ECheckBoxState.UnChecked)
        if GameCameraSystem:IsCameraLogicActive(GameCameraModeGroupDef.HumanAiming) then
            self:ChangeClientAimState(false)
        end
    else
        local bSuccess = BattleHumanWeaponSystemNew:RequestSetAim(false)
        if bSuccess then
            self:ChangeClientAimState(false)
        end
    end
end

local function RefreshAim(self, nCurrentWeaponId)
    local bSuccess = RefreshAimBtn(self, nCurrentWeaponId)
    if bSuccess then
        if not nCurrentWeaponId then
            local HumanWeaponComponent = GamePlayerSelfHelper:Get().HumanWeaponComponent
            if not HumanWeaponComponent then
                return false
            end
            local nCurrentState = HumanWeaponComponent:GetCurrentState()
            if nCurrentState == HumanWeaponStateDef.RELOADING then
                return false
            end
            nCurrentWeaponId = HumanWeaponComponent:GetCurrentWeaponInstanceId()
            assert(nCurrentWeaponId)
        end
        self.ulHumanAim:OnCurrentWeaponChanged(nCurrentWeaponId)
    end
end

-- local function IsAimAdsorptionWeapon(nWeaponInstanceId)
--     local WeaponItem = BattleItemSystemHelper:GetItem(nWeaponInstanceId, true)
--     local tbTemplate = nil

--     if nWeaponInstanceId == 0 or WeaponItem == nil then
--         return false
--     elseif (WeaponItem:GetCategory() == BattleItemCategoryDef.HUMAN_THROWN_ITEM) then
--         return false
--     else
--         local nPrimaryCategory = WeaponItem:GetTemplate().nPrimaryCategory
--         if nPrimaryCategory == HumanWeaponDef.WeaponPrimaryCategory.Melee then
--             tbTemplate = WeaponItem:GetTemplate()
--             return true, tbTemplate.nAdsorpRange, tbTemplate.nAdsorpScale, tbTemplate.nAdsorpMinRange
--         end
--     end
--     tbTemplate = WeaponItem:GetTemplate()
--     return true, tbTemplate.nAdsorpRange, tbTemplate.nAdsorpScale, tbTemplate.nAdsorpMinRange 
-- end

-- local function EnableOldAssist(self, Owner, nNewWeaponId) 
--     local bGun, nEffectRange, nScale, nEffectMinRange = IsAimAdsorptionWeapon(nNewWeaponId)
--     if bGun then 
--         local nRange = nEffectRange * 100
--         if nEffectRange ~= 0 then 
--             Owner.pUEActor:EnableFireAssistant(true, nRange, nScale, nEffectMinRange * 100)
--         else   
--             Owner.pUEActor:EnableFireAssistant(false, 0, 0, 0)
--         end
--     else  
--         Owner.pUEActor:EnableFireAssistant(false, 0, 0, 0)
--     end
-- end



local function EnableNewAssist(self, Owner, nNewWeaponId)
    local nRange, bEnable, nRubAssistHScale, nRubAssistVScale, nRubAssistSpeed, nFovRate = 0, false, 0, 0, 0, 1
    local nTrackMaxPercent, nTrackMinDistance, nTrackSpeedPercent, nTrackEffMinSpeed, nTrackInterpPercent = 0, 0, 0, 0, 0
    local bOpenRubAssist, bOpenTrackAssist, bOpenFireAssist = false, false, false
    local WeaponItem = BattleItemSystemHelper:GetItem(nNewWeaponId, true)
    if WeaponItem and WeaponItem:GetCategory() ~= BattleItemCategoryDef.HUMAN_THROWN_ITEM then   
        local nPrimaryCategory = WeaponItem:GetTemplate().nPrimaryCategory
        if nPrimaryCategory ~= HumanWeaponDef.WeaponPrimaryCategory.Melee then
            local tbTemplate = WeaponItem:GetTemplate()
            nRange, bEnable, nRubAssistHScale, nRubAssistVScale, nRubAssistSpeed, nFovRate = 
            tbTemplate.nAssistDistance * 100, true, 1 - tbTemplate.nAssistHReduceRate, 1 - tbTemplate.nAssistVReduceRate, tbTemplate.nAssistReducePercent, tbTemplate.nOpenAimCameraRate
            nTrackMaxPercent, nTrackMinDistance, nTrackSpeedPercent, nTrackEffMinSpeed, nTrackInterpPercent =
            CameraIni.nTrackMaxPercent, CameraIni.nTrackMinDistance, tbTemplate.nTrackSpeedPercent, tbTemplate.nTrackEffMinSpeed, tbTemplate.nTrackInterpPercent
            bOpenRubAssist, bOpenTrackAssist, bOpenFireAssist = CameraIni.bOpenRubAssist, CameraIni.bOpenTrackAssist, CameraIni.bOpenFireAssist
        end
    end
    -- logdebug("enable value 1", nRange, bEnable, nRubAssistHScale, nRubAssistVScale, nRubAssistSpeed, CameraIni.nMinSphereSize, CameraIni.nMaxSphereSize, nFovRate)
    -- logdebug("enable value 2", nTrackMaxPercent, nTrackMinDistance, nTrackSpeedPercent, nTrackEffMinSpeed, nTrackInterpPercent)
    Owner.pUEActor:EnableAssist(bEnable, nRange, nRubAssistHScale, nRubAssistVScale, nRubAssistSpeed, CameraIni.nMinSphereSize, CameraIni.nMaxSphereSize, nFovRate,
        nTrackMaxPercent, nTrackMinDistance, nTrackSpeedPercent, nTrackEffMinSpeed, nTrackInterpPercent,
        bOpenRubAssist, bOpenTrackAssist,bOpenFireAssist
    )
end

local function FireAimAbsorption(self, OwnerPlayer, nAdsorpSpeed, nAdsorpInterp)
    -- logdebug("speed :", nAdsorpSpeed, CameraIni.bOpenFireAssist)
    if OwnerPlayer and OwnerPlayer:IsHuman() then  
        OwnerPlayer.pUEActor:FireAimAdsorption(nAdsorpSpeed, nAdsorpInterp)
    end
end

local function OnHumanWeaponChangeStart(self, Owner, nNewWeaponId)
    if GamePlayerSelfHelper:GetServerInstanceId()  ~= Owner:GetServerInstanceId() then
        return
    end
    --客户端收到开始换武器的消息， 不管要换的武器是什么，如果开镜都要先退出开镜
    local HumanWeaponComponent = GamePlayerSelfHelper:Get().HumanWeaponComponent
    if not nNewWeaponId or not HumanWeaponComponent then
        return
    end

    -- EnableOldAssist(self, Owner, nNewWeaponId)
    EnableNewAssist(self, Owner, nNewWeaponId)
    ExitOpenAimCamera(self)
end

local function OnAddItem(self, NewItem)
    self.tbAddItem[NewItem:GetInstanceId()] = true
end

local function OnRemoveItem(self,nItemInstanceId)
    self.tbAddItem[nItemInstanceId] = nil
end

local function OnWeaponChangedComposite(self)
    --logdebug("OnWeaponChangeComposite............")
    local nCurrentMode = ControlModeSystem:GetCurrentModeType()
    if nCurrentMode ~= ControlModeDef.HUMAN then
        return
    end
    self.ulFFAHumanWeapon:Refresh()
    RefreshAim(self, self.nWeaponChangedNewWeapon)
    self.ulFFAHumanReloadButton:Refresh(self.nWeaponChangedNewWeapon)
    RefreshExplosiveBtn(self, self.nWeaponChangedNewWeapon)
    self.ulHumanFightBtn:Refresh(self.nWeaponChangedNewWeapon)
end

local function OnWeaponChangedCompositeVerify(self, Handle, ...)
    local tbParem = {...}
    if Handle == ClientEventDef.EV_BATTLE_ITEM_ADD_CLIENT then
        local nInstanceId = tbParem[1]:GetInstanceId()
        --logdebug("OnWeaponChangedCompositeVerify,EV_BATTLE_ITEM_ADD_CLIENT:nInstanceId,self.nWeaponChangedNewWeapon=",nInstanceId,self.nWeaponChangedNewWeapon)
        if self.nWeaponChangedNewWeapon == nInstanceId then
            return true
        end
        return false
    elseif Handle == CommonEventDef.EV_HUMAN_CURRENT_WEAPON_CHANGED then
        local nPlayerId = tbParem[3]
        local nNewWeapon = tbParem[1]
        --self.nWeaponChangedNewWeapon = nNewWeapon
        --logdebug("OnWeaponChangedCompositeVerify,EV_HUMAN_CURRENT_WEAPON_CHANGED:self.tbAddItem[nNewWeapon]=",self.tbAddItem[nNewWeapon])
        if nPlayerId == GamePlayerSelfHelper:GetServerInstanceId() then
            self.nWeaponChangedNewWeapon = nNewWeapon
            if self.tbAddItem[nNewWeapon] or nNewWeapon == 0 then
                return true
            end
        end
        return false
    end
end


local function OnOpenUI(self, szWndName)
    --logdebug("the open window name is ",szWndName)
    self.ulFreeView:OnOpenUI(szWndName)
    self.ulHumanFightBtn:OnOpenUI(szWndName)
end

local function BindEventOnShipOrHumanState(self)
    if self.tbCompositeEventHandle then
        return
    end 
    local EventHelper = self.EventHelper
    --组合事件
    self.tbCompositeEventHandle = EventHelper:BeginCompositeOrEvent(self, OnWeaponChangedComposite, OnWeaponChangedCompositeVerify)
    EventHelper:RegisterEvent(CommonEventDef.EV_HUMAN_CURRENT_WEAPON_CHANGED, self, nil)
    EventHelper:RegisterEvent(ClientEventDef.EV_BATTLE_ITEM_ADD_CLIENT, self, OnAddItem)
    EventHelper:EndCompositeEvent()
    --
end

local function UnbindEventOnShipOrHumanState(self)
    self.tbAddItem = {}
    local EventHelper = self.EventHelper
    EventHelper:UnregisterEvent(CommonEventDef.EV_HUMAN_CURRENT_WEAPON_CHANGED)
    EventHelper:UnregisterEvent(ClientEventDef.EV_BATTLE_ITEM_ADD_CLIENT)
    if self.tbCompositeEventHandle then
        EventHelper:UnRegisterComposite(self.tbCompositeEventHandle)
        self.tbCompositeEventHandle = nil
    end
end

local function OnFFATransportChanged(self, nState)
    if nState == ProtoDR.rFFATransportState_EState.MOVING then
        UnbindEventOnShipOrHumanState(self)
    end
end

local function OnFFAProcessStateChanged(self, nState)
    if nState == ProtoDR.rFFAProcessState_EState.PARACHUTING then
        UnbindEventOnShipOrHumanState(self)
    end
end

local function OnParachutionEnd(self, bIsShip)
    BindEventOnShipOrHumanState(self)
end

local function GetInhibitOffset(nState)
    local pUEActor = GamePlayerSelfHelper:Get().pUEActor
    if not pUEActor then  
        return nil 
    end 
    if nState == HumanMovementStateType.UpRight_State then
        return pUEActor.InhibitUpRight
    elseif nState == HumanMovementStateType.Crouch_State then
        return pUEActor.InhibitCrouch
    elseif nState == HumanMovementStateType.Crawl_State then
        return pUEActor.InhibitCrawl
    end
    return nil
end

local function SetAimBtnEnable(self, bEnable)
    self.bAimBtnEnable = bEnable
    -- local tbCurrentWeapon = GamePlayerSelfHelper:Get().HumanWeaponComponent:GetCurrentWeapon()
    -- if tbCurrentWeapon and tbCurrentWeapon:IsType(HumanWeaponType.GUN) and bEnable then
    --     SetAimBtnsVisible(self, true)
    -- end
end

local function OnWeaponStateChanged(self, nCurrentState, Owner)
    if Owner:GetServerInstanceId() ~= GamePlayerSelfHelper:GetServerInstanceId() then
        self:SetCheckRange(Owner)
        return
    end

    local WeaponComponent = Owner.HumanWeaponComponent
    local bAiming = WeaponComponent:IsAiming()
    --
    self:SetCheckRange()

    local bShowReloadBtn = nCurrentState == HumanWeaponStateDef.ATTACKING
                            or bAiming
                            or nCurrentState == HumanWeaponStateDef.HOLDED

    local bShowReloadInStandalone = GlobalVariableSystem.bIsStandalone and 
             nCurrentState == HumanWeaponStateDef.HOLDING 
    if bShowReloadBtn or bShowReloadInStandalone then
        SetAimBtnsVisible(self, true)
        RefreshAimBtn(self)
        self.ulFFAHumanReloadButton:Refresh()
    else
        SetAimBtnsVisible(self, false)
        self.ulFFAHumanReloadButton:HideButton()
    end

    local tbCurrentWeapon = Owner.HumanWeaponComponent:GetCurrentWeapon()
    if(nCurrentState == HumanWeaponStateDef.HOLDED
        and tbCurrentWeapon
        and tbCurrentWeapon:IsType(HumanWeaponType.THROW)) then

        if not tbCurrentWeapon:IsThrowWeaponHit() then
            self:SetThrowTrojectoryVisible(true)
        end
    end

end

--  Other Player Inhibit Attack
local function OnActorInhibitAttack(self, Acotr, bInhibitAttack, fDistance)
    fDistance = fDistance - Acotr.CapsuleComponent:GetUnscaledCapsuleRadius()
    Acotr:SetInhibitAttack(bInhibitAttack)
    if bInhibitAttack then
        Acotr.PitchPercentOnInhibitAttack = 1 - (fDistance / self.fInhibitAttackDistance)
        -- logdebug("self.fInhibitAttackDistance fDistance", fDistance, "self.fInhibitAttackDistance", self.fInhibitAttackDistance, PlayerSelf.pUEActor.PitchPercentOnInhibitAttack)
    end
end

local function OnInhibitAttack(self, bInhibitAttack, fDistance)
    self.bInhibitAttack = bInhibitAttack
    local PlayerSelf = GamePlayerSelfHelper:Get()
    PlayerSelf.pUEActor:SetInhibitAttack(bInhibitAttack)
    fDistance = fDistance - PlayerSelf.pUEActor.CapsuleComponent:GetUnscaledCapsuleRadius()
    if bInhibitAttack then
        PlayerSelf.pUEActor.PitchPercentOnInhibitAttack = 1 - (fDistance / self.fInhibitAttackDistance)
        -- logdebug("self.fInhibitAttackDistance fDistance", fDistance, "self.fInhibitAttackDistance", self.fInhibitAttackDistance, PlayerSelf.pUEActor.PitchPercentOnInhibitAttack)
    end

    local HumanWeaponComponent = PlayerSelf.HumanWeaponComponent
    -- HumanWeaponComponent.bInhibitAttack = bInhibitAttack
    local nCurrentState = HumanWeaponComponent:GetCurrentState()
    if bInhibitAttack then
         --这样传参数是为了 显示阻挡ui的时候把瞄准ui全隐藏
        self.ulHumanAim:RefreshCenterAim(true, true)
    else
        if HumanWeaponComponent:GetCurrentWeapon() and not HumanWeaponComponent:IsAiming() and nCurrentState ~= HumanWeaponStateDef.RELOADING then
            self.ulHumanAim:RefreshCenterAim(false, false)
        elseif HumanWeaponComponent:IsAiming()  then
            self.ulHumanAim:RefreshCenterAim(false, true)
        end
    end
    self.EventHelper:FireEvent(ClientEventDef.EV_INHIBIT_ATTACK_ACTIVE, self.bInhibitAttack )
end

local function RestoreUIStateForReconnect(self)

    local PlayerSelf = GamePlayerSelfHelper:Get()
    local HumanMovementStateComponent = PlayerSelf.HumanMovementStateComponent
    if HumanMovementStateComponent then 
        self.ulFFAHumanMovement:RestoreUIStateForReconnect(HumanMovementStateComponent)
        self.ulFFAHumanVehicle:OnVehicleStateChange(PlayerSelf, HumanMovementStateComponent:GetVehicleState(), nil)
    end
end

local function OnPawnDead(self, tbDeader, tbCauser, nLastDamageType)
    local tbPlayer = GamePlayerSelfHelper:Get()
    if tbPlayer and tbPlayer:IsHuman() and tbPlayer:GetServerInstanceId() == tbDeader.nServerInstanceId then
        self.ulHumanAim:RefreshCenterAim(false, false)
    end
end

local function OnBowAttackStateChanged(self, bFocus, nAnimTime)
    if bFocus then
        self.pWidgetRef.txtBoomName:SetText(UISetUtils.GetL10NTextByKey("UI_STATIC_CANCEL_BOW_ATTACK"))
        self.btnBoomCancel:SetVisibility(ESlateVisibility.Visible)
    else
        self.pWidgetRef.txtBoomName:SetText(UISetUtils.GetL10NTextByKey("UI_STATIC_CANCEL_THROW"))
        self.btnBoomCancel:SetVisibility(ESlateVisibility.Collapsed)
    end
end

local function OnSwitchDoorClicked(self)
    DestructibleObjectInteractionalSystem:RequestSwitchDoor()
end

local function OnShowDoorSwitch(self, bShow, bOpen)
    log("OnShowDoorSwitch", bShow, bOpen)
    if bShow then
        self.pWidgetRef.cpSwitchDoor:SetVisibility(ESlateVisibility.Visible)
        local l10nText = bOpen and UISetUtils.GetL10NTextByKey("SWITCH_DOOR_OPEN") or UISetUtils.GetL10NTextByKey("SWITCH_DOOR_CLOSE")
        self.pWidgetRef.txtSwitchDoor:SetText(l10nText)
        UISetUtils.SetButtonBrushRes(self.pWidgetRef.btnSwitchDoor, bOpen and OPEN_DOOR_IMG:load() or CLOSE_DOOR_IMG:load())
    else
        self.pWidgetRef.cpSwitchDoor:SetVisibility(ESlateVisibility.Collapsed)
    end
end

function UPFFAHuman:SetThrowTrojectoryVisible(bVisible)
    local pWidgetRef = self.pWidgetRef
    if bVisible then
        pWidgetRef.chkThrow:SetVisibility(ESlateVisibility.Visible)
        local WeaponComponent = GetSelfWeaponComponent()
        if WeaponComponent and WeaponComponent:IsLastHighThrow() then
            pWidgetRef.chkThrow:SetCheckedState(ECheckBoxState.Unchecked)
        else
            pWidgetRef.chkThrow:SetCheckedState(ECheckBoxState.Checked)
        end
    else
        pWidgetRef.chkThrow:SetVisibility(ESlateVisibility.Collapsed)
    end
end

function UPFFAHuman:ChangeClientAimState(bNewAim)
    local pWidgetRef = self.pWidgetRef
    if pWidgetRef then
        SetCameraState(self, bNewAim)
        local bChecked = pWidgetRef.chkAim:GetCheckedState() == ECheckBoxState.Checked
        if bNewAim and not bChecked then
            pWidgetRef.chkAim:SetCheckedState(ECheckBoxState.Checked)
        elseif not bNewAim and bChecked then
            pWidgetRef.chkAim:SetCheckedState(ECheckBoxState.UnChecked)
        end
    end
end

function UPFFAHuman:OnCreate()
    self.nExplosionTime = 0
    self.btnBoomCancel = nil
end

function UPFFAHuman:OnLoad()
    local pWidgetRef = self.pWidgetRef
    
    self.btnBoomCancel = pWidgetRef.btnBoomcancel
    -- self.bShowAutoSwiming = true
    self.bAimBtnEnable = true

    SetAimBtnsVisible(self, false)
    -- pWidgetRef.btnAuto:SetVisibility(ESlateVisibility.Hidden)

    local UILogicHelper = self.UILogicHelper
    self.ulHumanAim = UILogicHelper:CreateUILogic("ULHumanAim")
    self.ulHumanFightBtn = UILogicHelper:CreateUILogic("ULHumanFightButton")
    self.ulFreeView = UILogicHelper:CreateUILogic("ULHumanFreeView")
    self.ulFFAHumanThrownItem = UILogicHelper:CreateUILogic("ULFFAHumanThrownItem")
    self.ulFFAHumanArmor = UILogicHelper:CreateUILogic("ULFFAHumanArmor")
    self.ulFFAHumanWeapon = UILogicHelper:CreateUILogic("ULFFAHumanWeapon")
    self.ulFFAHumanReloadButton = UILogicHelper:CreateUILogic("ULFFAHumanReloadButton")
    self.ulHumanLayout = UILogicHelper:CreateUILogic("ULFFAHumanLayout")
    self.ulFFAHumanVehicle = UILogicHelper:CreateUILogic("ULFFAHumanVehicle")
    self.ulFFAHumanMovement = UILogicHelper:CreateUILogic("ULFFAHumanMovement")
end

function UPFFAHuman:OnBindEvent(EventHelper)
    local pWidgetRef = self.pWidgetRef
   -- EventHelper:RegisterCppDelegate(pWidgetRef.chkAim.OnCheckStateChanged , self, OnAimStateChanged)
    EventHelper:RegisterCppDelegate(pWidgetRef.btnAim.OnClicked , self, OnAimStateClicked)
    EventHelper:RegisterCppDelegate(pWidgetRef.btnSwitchDoor.OnClicked, self, OnSwitchDoorClicked)

    -- EventHelper:RegisterCppDelegate(pWidgetRef.btnStopHorse.OnClicked, self, OnStopVehicle)
    EventHelper:RegisterCppDelegate(pWidgetRef.ImgInhibit.OnInhibitAttack           , self, OnInhibitAttack)
    --EventHelper:RegisterEvent(CommonEventDef.EV_HUMAN_CURRENT_WEAPON_CHANGED, self, OnWeaponChanged)

    EventHelper:RegisterEvent(CommonEventDef.EV_MOVEMENT_CRAWL_CHANGE_AIM_STATE, self, OnAimStateChanged)

    EventHelper:RegisterEvent(ClientEventDef.EV_OPEN_UI, self, OnOpenUI)
    EventHelper:RegisterEvent(ClientEventDef.EV_BATTLE_ITEM_REMOVE_CLIENT, self, OnRemoveItem)
    EventHelper:RegisterEvent(ClientEventDef.EV_FFA_TRANSPORT_STATE_CHANGED, self, OnFFATransportChanged)
    EventHelper:RegisterEvent(ClientEventDef.EV_FFA_PROCESS_STATE_CHANGED, self, OnFFAProcessStateChanged)
    EventHelper:RegisterEvent(ClientEventDef.EV_FFA_PARACHUTION_END, self, OnParachutionEnd)
    EventHelper:RegisterEvent(ClientEventDef.EV_START_CHANGE_HUMAN_WEAPON, self, OnHumanWeaponChangeStart)
    
    EventHelper:RegisterEvent(ClientEventDef.EV_SET_AIM_BTN_ENABLE, self, SetAimBtnEnable)
    EventHelper:RegisterEvent(ClientEventDef.EV_SHOW_DOOR_SWITCH, self, OnShowDoorSwitch)

    pWidgetRef.ImgInhibit.IgnoreType = "PM_Ground"
    BindEventOnShipOrHumanState(self)
end

function UPFFAHuman:Activate(tbParam)

    local PlayerSelf = GamePlayerSelfHelper:Get()
    local EventHelper = self.EventHelper
    
    EventHelper:RegisterEvent(CommonEventDef.EV_HUMAN_WEAPON_STATE_CHANGED, self, OnWeaponStateChanged)
    EventHelper:RegisterEvent(ClientEventDef.EV_EXIT_OPEN_AIM_CAMERA, self, ExitOpenAimCamera)
    EventHelper:RegisterEvent(ClientEventDef.EV_CHECK_WIN_AIM_CAMERA, self, CheckWinAimCamera)
    EventHelper:RegisterEvent(CommonEventDef.EV_GAME_OBJECT_ON_PAWN_DEAD, self, OnPawnDead)
    EventHelper:RegisterEvent(ClientEventDef.EV_HUMAN_WEAPON_ACCUMULATE, self, OnBowAttackStateChanged)
    EventHelper:RegisterEvent(ClientEventDef.EV_TO_FIRE_AIM_ABSORPTION, self, FireAimAbsorption)
    EventHelper:RegisterEvent(ClientEventDef.EV_SETTING_LEFT_HAND_FIRE, self, UpdateLeftHandFireBtn)

    RefreshAim(self)

    self.ulHumanAim:Activate()
    self.ulHumanFightBtn:Activate()
    self.ulFreeView:Activate()
    self.ulFFAHumanArmor:Activate()
    self.ulFFAHumanWeapon:Activate()
    self.ulFFAHumanReloadButton:Activate()
    self.ulFFAHumanThrownItem:Activate()
    self.ulFFAHumanVehicle:Activate()
    self.ulFFAHumanMovement:Activate()

    local HumanWeaponComponent = PlayerSelf.HumanWeaponComponent
    if HumanWeaponComponent:GetCurrentState() == HumanWeaponStateDef.HOLDED then
        self:SetCheckRange()
    end

    RestoreUIStateForReconnect(self)
    
    self.bActivate = true
    self.EventHelper:FireEvent(ClientEventDef.EV_UI_ON_FFAHUMAN_ACTIVATE)

    local DelegateMgr = CommonShell.GetCommon(GWorld):GetGameDelegateManager()

    local GameMisc = DelegateMgr.GameMisc
    self.OnActorInhibitAttackDelegate = EventHelper:RegisterCppDelegate(GameMisc.OnActorInhibitAttack, self, OnActorInhibitAttack)

    local WeaponInhibitManager = CommonShell.GetCommon(GWorld):GetWeaponInhibitManager()
    WeaponInhibitManager.IgnoreType = "PM_Ground"

    local bShow, bOpen = DestructibleObjectInteractionalSystem:GetInteractionObjectState()
    OnShowDoorSwitch(self, bShow, bOpen)
end

function UPFFAHuman:Deactivate()
    local pWidgetRef = self.pWidgetRef
    self.bZoomIn = false
    pWidgetRef.chkAim:SetCheckedState(ECheckBoxState.Unchecked)
    pWidgetRef.chkThrow:SetVisibility(ESlateVisibility.Collapsed)
    pWidgetRef.btnBoomCancel:SetVisibility(ESlateVisibility.Collapsed)

    local EventHelper = self.EventHelper
    EventHelper:UnregisterEvent(CommonEventDef.EV_HUMAN_WEAPON_STATE_CHANGED)
    EventHelper:UnregisterEvent(CommonEventDef.EV_HUMAN_MOVEMENT_STATE_CHANGED)
    EventHelper:UnregisterEvent(ClientEventDef.EV_EXIT_OPEN_AIM_CAMERA)
    
    EventHelper:UnregisterEvent(ClientEventDef.EV_IN_VEHICLE_AREA)
    EventHelper:UnregisterEvent(CommonEventDef.EV_ON_VEHICLE_STATE_CHANGE)
    EventHelper:UnregisterEvent(ClientEventDef.EV_APP_WILL_DEACTIVE)
    EventHelper:UnregisterEvent(ClientEventDef.EV_OPERATION_MODE_CHANGED)
    EventHelper:UnregisterEvent(ClientEventDef.EV_CHECK_WIN_AIM_CAMERA)
    EventHelper:UnregisterEvent(ClientEventDef.EV_ON_REQUEST_VEHICLE_FAILED)
    EventHelper:UnregisterEvent(CommonEventDef.EV_GAME_OBJECT_ON_PAWN_DEAD)
    EventHelper:UnregisterEvent(ClientEventDef.EV_HUMAN_WEAPON_ACCUMULATE)
    EventHelper:UnregisterEvent(ClientEventDef.EV_TO_FIRE_AIM_ABSORPTION)
    EventHelper:UnregisterEvent(ClientEventDef.EV_SETTING_LEFT_HAND_FIRE)

    self.pWidgetRef.ImgInhibit:SetCheckRange(0)
    -- self.pWidgetRef.ImgAimPoint:SetVisibility(ESlateVisibility_Collapsed)

    self.ulHumanAim:Deactivate()
    self.ulHumanFightBtn:Deactivate()
    self.ulFreeView:Deactivate()
    self.ulFFAHumanArmor:Deactivate()
    self.ulFFAHumanWeapon:Deactivate()
    self.ulFFAHumanReloadButton:Deactivate()
    self.ulFFAHumanThrownItem:Deactivate()
    self.ulFFAHumanVehicle:Deactivate()
    self.ulFFAHumanMovement:Deactivate()

    if self.tbTimerObject then
        DelayTimer:ClearTimer(self.tbTimerObject)
        self.tbTimerObject = nil
    end

    if self.EventReciever and self.EventReciever.Uninit then
        self.EventReciever:Uninit()
    end

    self.bOtherPostProcess = nil
    self.bActivate = false
    if self.OnActorInhibitAttackDelegate then 
        EventHelper:UnregisterCppDelegate(self.OnActorInhibitAttackDelegate)    
        self.OnActorInhibitAttackDelegate = nil 
    end
end

function UPFFAHuman:RefreshLayout()
    self.ulHumanLayout:RefreshLayout()
end

function UPFFAHuman.UseAcceleration(bUse)
    local HumanMovementStateComponent =  GamePlayerSelfHelper:Get().HumanMovementStateComponent
    local tbVehicle = GameObjectSystem:FindByInstanceId(HumanMovementStateComponent:GetVehicleInstanceId())
    if tbVehicle then
        tbVehicle.pUEActor.bUseAcceleration = bUse
    end
end

local function UpdateInhibit(self, bSelfPlayer, Player, OffsetLocation)
    if bSelfPlayer then 
        local ImgInhibit = self.pWidgetRef.ImgInhibit
        ImgInhibit:SetCheckRange(Player.fInhibitAttackDistance)
        ImgInhibit.OffsetLocation = OffsetLocation
    else
        local WeaponInhibitManager = CommonShell.GetCommon(GWorld):GetWeaponInhibitManager()
        WeaponInhibitManager:AddActor(Player.pUEActor, Player.fInhibitAttackDistance, OffsetLocation)
    end 
end

function UPFFAHuman:SetCheckRange(Player)
    local PlayerSelf = Player
    local bSelf = false
    if not PlayerSelf then 
        PlayerSelf = GamePlayerSelfHelper:Get()
        bSelf = true
    end
    local HumanWeaponComponent = PlayerSelf.HumanWeaponComponent
    if not HumanWeaponComponent then
        return
    end
 
    local HumanMovementStateComponent = PlayerSelf.HumanMovementStateComponent
    if not HumanMovementStateComponent then
        return
    end

    -- local bAiming = HumanWeaponComponent:IsAiming()
    local nCurrentWeaponState = HumanWeaponComponent:GetCurrentState()
    --
    -- if nCurrentWeaponState ~= HumanWeaponStateDef.HOLDED and nCurrentWeaponState ~= HumanWeaponStateDef.HOLDING and not bAiming then
    -- Reload 时不能Block 否则动作会穿帮
    -- or nCurrentWeaponState == HumanWeaponStateDef.RELOADING 
    if nCurrentWeaponState == HumanWeaponStateDef.UNHOLDED or nCurrentWeaponState == HumanWeaponStateDef.UNHOLDING then 
        PlayerSelf.fInhibitAttackDistance = 0
        UpdateInhibit(self, bSelf, PlayerSelf)
        return 
    end

    local nCurrentMovementState = HumanMovementStateComponent:GetCurrentState()

    local pLocation = GetInhibitOffset(nCurrentMovementState)
    
    if not pLocation then
        return 
        -- ImgInhibit.OffsetLocation = OffsetLocation
    end
    local OffsetLocation = Vector{X = pLocation.X, Y = pLocation.Y , Z = pLocation.Z}

    local tbWeaponProperty

    local tbCurrentWeapon = HumanWeaponComponent:GetCurrentWeapon()
    if(tbCurrentWeapon) then
        tbWeaponProperty = tbCurrentWeapon:GetProperty()
    end
    if tbWeaponProperty then
        local nPrimaryCategory = tbWeaponProperty.nPrimaryCategory

        local bIsThrowItem = false

        local tbTemplate = BattleItemDataTable:GetTemplate(tbCurrentWeapon.nTemplateId)
        local nCategory = tbTemplate.nCategory        

            bIsThrowItem = nCategory == BattleItemCategoryDef.HUMAN_THROWN_ITEM
 
        if nPrimaryCategory ~= HumanWeaponDef.WeaponPrimaryCategory.Melee and not bIsThrowItem then
            -- if nCurrentMovementState == HumanMovementStateType.Crawl_State then
            local nTemplateId = PlayerSelf:GetHumanTemplateId()
            local CapsuleData = HumanCapsuleDataTable:GetTemplate(nTemplateId, HumanMovementStateType.UpRight_State)
            local CurrentCapsuleData = HumanCapsuleDataTable:GetTemplate(nTemplateId, nCurrentMovementState)
            if CapsuleData and CurrentCapsuleData then 
                local nOffset = CapsuleData.nCapsuleHalfHeight - CurrentCapsuleData.nCapsuleHalfHeight
            -- self.pWidgetRef.ImgInhibit:SetCheckRange(0)
            -- return
                OffsetLocation.Z = OffsetLocation.Z + nOffset
            end
            -- end
            -- logdebug("tbWeaponProperty.nWeaponLength", tbWeaponProperty.nWeaponLength, "nCrawl", nCrawl)
            PlayerSelf.fInhibitAttackDistance = tbWeaponProperty.nWeaponLength  
            -- self.fInhibitAttackDistance = self.fInhibitAttackDistance
        else
            PlayerSelf.fInhibitAttackDistance = 0
        end
    else
        PlayerSelf.fInhibitAttackDistance = 0
    end
    UpdateInhibit(self, bSelf, PlayerSelf, OffsetLocation)
end

return UPFFAHuman