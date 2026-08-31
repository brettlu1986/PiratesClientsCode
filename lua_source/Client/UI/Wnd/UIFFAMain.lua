---------------------------------------------------
--File Name    : UIFFAMain.lua
--Description  : 人形战斗主界面
-----------------------------------------------------
local luaclass = require("luaclass")
local WndBase = require("WndBase")
local UIFFAMain = luaclass("UIFFAMain", WndBase)

-- local UIUtils = require("UIUtils")
local UISetUtils = require("UISetUtils")
local UIDef = require("UIDef")
local UIManager = require("UIManager")
local ClientEventDef = require("ClientEventDef")
local ControlModeDef = require("ControlModeDef")
local UIResourceDef = require("UIResourceDef")
local EventManager = require("EventManager")
local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
local UITextDef = require("UITextDef")
local FriendIni = require("FriendIni")
local CommonEventDef = require("CommonEventDef")

local DelayTimer = require("DelayTimer")
--local UEActorHelper = require("UEActorHelper")
local WorldMapUtil = require("WorldMapUtil")
local ProtoDR = require("DungeonRepProtoNames")
local ParachutionSystem_C = require("ParachutionSystem_C")
local SettingLayoutFromDef = require("SettingLayoutFromDef")

local HumanVehicleStateDef = require("HumanVehicleStateDef")
local ControlModeSystem = require("ControlModeSystem")
local GlobalVariableSystem = dynamic_require("GlobalVariableSystem")
-- local SaveGameDef = require("SaveGameDef")
local UIUtils = require("UIUtils")
local SettingSystemNew = require("SettingSystemNew")
local SettingKeyDef = require("SettingKeyDef")
local MiniMapSystem = require("MiniMapSystem")
local BattleGameModeSystem = dynamic_require("BattleGameModeSystem")
local StringUtil = require("StringUtil")
local GVoiceSDKSystem = require("GVoiceSDKSystem")
local SettingClassType = require("SettingClassType")
local PCInputControlHelper = require("PCInputControlHelper")

local FFA_SWITCH_INDEX = {
    [ControlModeDef.HUMAN] = 0,
    [ControlModeDef.SHIP] = 0,
    [ControlModeDef.TRANSPORTNEW] = 1
}

local BATTLE_SWITCH_INDEX = {
    [ControlModeDef.HUMAN] = 0,
    [ControlModeDef.SHIP] = 1,
}

local VIRTUALSTICK_CLASS = {
    [ControlModeDef.HUMAN] = UIDef.UP_HUMAN_VIRTUALSTICK,
    [ControlModeDef.TRANSPORT] = UIDef.UP_HUMAN_VIRTUALSTICK,
    [ControlModeDef.TRANSPORTNEW] = UIDef.UP_HUMAN_VIRTUALSTICK,
    [ControlModeDef.SHIP] = UIDef.UP_SHIP_VIRTUALSTICK
}

local VIRTUALSTICK_ICON = {
    [ControlModeDef.TRANSPORT] = UIResourceDef.FFA_VIRTUALSTICK_HUMAN_ICON,
    [ControlModeDef.HUMAN] = UIResourceDef.FFA_VIRTUALSTICK_HUMAN_ICON,
    [ControlModeDef.SHIP] = UIResourceDef.FFA_VIRTUALSTICK_SHIP_ICON,
    [ControlModeDef.TRANSPORTNEW] = UIResourceDef.FFA_VIRTUALSTICK_HUMAN_ICON,
}

local VIRTUALSTICK_CONTINUOUS_ENABLE = {
    [ControlModeDef.TRANSPORT] = false,
    [ControlModeDef.HUMAN] = true,
    [ControlModeDef.SHIP] = true,
    [ControlModeDef.TRANSPORTNEW] = false,
}

local CHANGEDISPLAY_NORMAL_ICON = {
    [ControlModeDef.HUMAN] = UIResourceDef.FFA_CHANGE_TO_SHIP_NORMAL,
    [ControlModeDef.SHIP] = UIResourceDef.FFA_CHANGE_TO_HUMAN_NORMAL,
}

local CHANGEDISPLAY_PRESS_ICON = {
    [ControlModeDef.HUMAN] = UIResourceDef.FFA_CHANGE_TO_SHIP_PRESS,
    [ControlModeDef.SHIP] = UIResourceDef.FFA_CHANGE_TO_HUMAN_PRESS,
}

local CHANGEDISPLAY_DISABLED_ICON = {
    [ControlModeDef.HUMAN] = UIResourceDef.FFA_CHANGE_TO_SHIP_DISABLED,
    [ControlModeDef.SHIP] = UIResourceDef.FFA_CHANGE_TO_HUMAN_DISABLED,    
}

local LAYOUT_FROM =
{
    [ControlModeDef.HUMAN] = SettingLayoutFromDef.HUMAN,
    [ControlModeDef.SHIP] = SettingLayoutFromDef.SHIP,
    [ControlModeDef.TRANSPORTNEW] = SettingLayoutFromDef.HUMAN,
}

--local RESULT_DELAY_TIME = 2.5    --弹出结算界面的延迟时间
--local DEAD_POST_PROCESS_ACTOR = "Class'/Game/Game/Misc/BP_DeadPostProcess.BP_DeadPostProcess_C'"
local tbSettingOperationMode = SettingSystemNew:GetInstance(SettingClassType.Setting_OperationMode)
local tbOperationModeDef = tbSettingOperationMode.ModeDef
local PRESS_TIME_OUT = 10

UIFFAMain.pbRadarMap = nil
UIFFAMain.pbCompass = nil
UIFFAMain.pbMainTips = nil
UIFFAMain.pbMainChatQuickView = nil
UIFFAMain.pbMainChat = nil
UIFFAMain.pbLobbyMisson = nil
UIFFAMain.pbVoiceMicCtr = nil
UIFFAMain.pbVoiceSpeakerCtr = nil

UIFFAMain.ulFFAToast = nil
UIFFAMain.ulPickupButton = nil
UIFFAMain.ulBattleInfo = nil
UIFFAMain.ulFFAItemPanel = nil
UIFFAMain.ulBuildingMaterials = nil
UIFFAMain.ulBuffList = nil
UIFFAMain.ulAttackWarningPanel = nil
UIFFAMain.ulPlayerStatusPanel = nil
UIFFAMain.ulRescuingPanel = nil
UIFFAMain.ulQuickBuild = nil
UIFFAMain.ulFFAMainProgressBar = nil
UIFFAMain.uiBattlePointTip = nil

UIFFAMain.tbControlModePrefab = {}
UIFFAMain.DelayHandle = nil
UIFFAMain.nLayoutFrom = SettingLayoutFromDef.HUMAN
UIFFAMain.bChangeDisplayEnable = true

UIFFAMain.nVoiceMicPressedStart = 0
UIFFAMain.nVoiceMicPressedEnd = 0
UIFFAMain.bVoiceMicOnPressed = false

UIFFAMain.pVoicePressTimer = nil
UIFFAMain.pDealyEffectTimer = nil
UIFFAMain.nCutoutSpacerWidth = 0
UIFFAMain.pbCutoutScreenAdapter = nil

local function OnVehicleStateChange(self, Player, nState, nVehicleId)
    local PlayerSelf = GamePlayerSelfHelper:Get()
    if Player.ObjectType == PlayerSelf.ObjectType then
        if not (self.pbCurrrentVirtualStick and ControlModeSystem.CurrentMode) then 
            return
        end
        self.pbCurrrentVirtualStick:SetCurrentLayoutFromByVehicleState(nState)
        if nState ~= HumanVehicleStateDef.None then 
            local nOperationMode = tbSettingOperationMode:GetVehicleOperationMode()
            if nOperationMode ~= tbSettingOperationMode.ModeDef.WithJoystick then
                self.pWidgetRef.pbVirtualJoystick:SetVisibility(ESlateVisibility.Collapsed)
            else
                self.pWidgetRef.pbVirtualJoystick:SetVisibility(ESlateVisibility.Visible)
            end
            self.pbCurrrentVirtualStick:SetContinuousEnable(false)
            self.pbCurrrentVirtualStick.pWidgetRef.chkSprintImmediately:SetVisibility(ESlateVisibility.Collapsed)
        else
            if not ControlModeSystem.CurrentMode or ControlModeSystem.CurrentMode:GetModeType() ~= ControlModeDef.TRANSPORTNEW then
                self.pWidgetRef.pbVirtualJoystick:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
            end
            if ControlModeSystem.CurrentMode:GetModeType() == ControlModeDef.HUMAN then
                self.pbCurrrentVirtualStick:SetContinuousEnable(true)
                self.pbCurrrentVirtualStick.pWidgetRef.chkSprintImmediately:SetVisibility(ESlateVisibility.Visible)
            end
        end
    end
end

local function RefreshShipVehicleLayout(self, nForm)
    local nCurrentMode = ControlModeSystem.CurrentMode:GetModeType()
    if nCurrentMode == ControlModeDef.HUMAN and nForm == SettingLayoutFromDef.VEHICLE then
        local GamePlayer = GamePlayerSelfHelper:Get()
        local HumanMovementStateComponent = GamePlayer.HumanMovementStateComponent
        local PlayerInputComponent = GamePlayer.pUEActor.PlayerInputComponent
        local nState = HumanMovementStateComponent:GetVehicleState()
        if HumanMovementStateComponent then
            OnVehicleStateChange(self, GamePlayer, nState, nil)
        end
        if PlayerInputComponent and nState ~= HumanVehicleStateDef.None then
            local nOperationMode = tbSettingOperationMode:GetVehicleOperationMode()
            PlayerInputComponent.UseGesture = nOperationMode == tbSettingOperationMode.ModeDef.WithJoystick
            log("RefreshShipVehicleLayout, PlayerInputComponent.UseGesture = ", nOperationMode == tbOperationModeDef.WithJoystick)
        end
    elseif nCurrentMode == ControlModeDef.SHIP and nForm == SettingLayoutFromDef.SHIP then
        local pbSailControl = self.tbControlModePrefab[ControlModeDef.SHIP].pbSailControl
        local nOperationMode = tbSettingOperationMode:GetShipOperationMode()
        if nOperationMode == tbOperationModeDef.WithJoystick then
            self.pWidgetRef.pbFFAShip.pbSailControl:SetVisibility(ESlateVisibility.Collapsed)
            if pbSailControl then
                pbSailControl:SailControlUnbindKeyboard()
            end
            self.pWidgetRef.pbVirtualJoystick:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
            if self.pbCurrrentVirtualStick then
                self.PrefabHelper:UnbindPrefab(self.pbCurrrentVirtualStick)
                self.pbCurrrentVirtualStick = nil
            end
            self.pbCurrrentVirtualStick = self.PrefabHelper:BindPrefab(self.pWidgetRef.pbVirtualJoystick, VIRTUALSTICK_CLASS[nCurrentMode])
            self.pbCurrrentVirtualStick:SetVirtualJoystickIcon(VIRTUALSTICK_ICON[nCurrentMode])
            log("[Joystick] RefreshShipVehicleLayout SetVirtualJoystickIcon, nCurrentMode, szIcon=", nCurrentMode, VIRTUALSTICK_ICON[nCurrentMode])
            self.pbCurrrentVirtualStick:SetContinuousEnable(VIRTUALSTICK_CONTINUOUS_ENABLE[nCurrentMode])
        elseif nOperationMode == tbOperationModeDef.WithButton then
            self.pWidgetRef.pbFFAShip.pbSailControl:SetVisibility(ESlateVisibility.Visible)
            if pbSailControl then
                pbSailControl:SailControlBindKeyboard()
            end
            self.pWidgetRef.pbVirtualJoystick:SetVisibility(ESlateVisibility.Collapsed)
            if self.pbCurrrentVirtualStick then
                self.PrefabHelper:UnbindPrefab(self.pbCurrrentVirtualStick)
                self.pbCurrrentVirtualStick = nil
            end
        end
    end
end

local function ControlModeActivate(self, nControlMode, nFFASwitchIndex, nBattleSwitchIndex, tbParam)
    self.nLayoutFrom = LAYOUT_FROM[nControlMode]
    local pWidgetRef = self.pWidgetRef
    if nFFASwitchIndex then
        pWidgetRef.swtFFA:SetActiveWidgetIndex(nFFASwitchIndex)
    end
    -- local pSaveGameMgr = ClientShell.GetClient(GWorld):GetSaveGameManager()
    local nShipOpMode = tbSettingOperationMode:GetShipOperationMode()
    if nBattleSwitchIndex then
        pWidgetRef.swtBattle:SetActiveWidgetIndex(nBattleSwitchIndex)
        if nControlMode == ControlModeDef.SHIP then
            if nShipOpMode == tbOperationModeDef.WithJoystick then
                pWidgetRef.pbFFAShip.pbSailControl:SetVisibility(ESlateVisibility.Collapsed)
            elseif nShipOpMode == tbOperationModeDef.WithButton then
                pWidgetRef.pbFFAShip.pbSailControl:SetVisibility(ESlateVisibility.Visible)
            end
        end
    end
    local szVirtualStickPrefabName = VIRTUALSTICK_CLASS[nControlMode]
    if (nControlMode == ControlModeDef.SHIP) and (nShipOpMode == tbOperationModeDef.WithButton) then
        szVirtualStickPrefabName = nil
    end
    if szVirtualStickPrefabName then
        pWidgetRef.pbVirtualJoystick:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
        self.pbCurrrentVirtualStick = self.PrefabHelper:BindPrefab(pWidgetRef.pbVirtualJoystick, szVirtualStickPrefabName)
        self.pbCurrrentVirtualStick:SetVirtualJoystickIcon(VIRTUALSTICK_ICON[nControlMode])
        log("[Joystick] ControlModeActivate SetVirtualJoystickIcon, nCurrentMode, szIcon=", nControlMode, VIRTUALSTICK_ICON[nControlMode])
        self.pbCurrrentVirtualStick:SetContinuousEnable(VIRTUALSTICK_CONTINUOUS_ENABLE[nControlMode])
    else
        pWidgetRef.pbVirtualJoystick:SetVisibility(ESlateVisibility.Collapsed)
    end
    local pbControlMode = self.tbControlModePrefab[nControlMode]
    if pbControlMode then
        pbControlMode:Activate(tbParam)
    end
    self.ulPickupButton:Activate()
    self.pbCompass:Activate()
    self.pbTeamMainHead:Activate()
    self.ulBattleTeam:Activate()
    if (nControlMode == ControlModeDef.SHIP) or (nControlMode == ControlModeDef.HUMAN) then
        self.ulPlayerStatusPanel:Activate()
    end

    local nState = ParachutionSystem_C:GetState()
    if nState then
        if nState >= ProtoDR.rFFAProcessState_EState.COUNTDOWN and nState < ProtoDR.rFFAProcessState_EState.MATINEE then
            -- pWidgetRef.ovlSelectPoint:SetVisibility(ESlateVisibility.Visible)
            EventManager:OnFireEvent(ClientEventDef.EV_UI_SELECT_POINT_BTN)
        else
            UIManager:CloseWnd(UIDef.UI_COUNT_DOWN2)
            -- pWidgetRef.ovlSelectPoint:SetVisibility(ESlateVisibility.Collapsed)
        end
   end
    
    self.ulMainLayout:RefreshLayout()
    self.ulPickupButton:RefreshLayout()
end

local function ControlModeDeactivate(self, nControlMode)
    local pbControlMode = self.tbControlModePrefab[nControlMode]
    if pbControlMode then
        pbControlMode:Deactivate()
    end
    if self.pbCurrrentVirtualStick then
        self.PrefabHelper:UnbindPrefab(self.pbCurrrentVirtualStick)
        self.pbCurrrentVirtualStick = nil
    end
    UIManager:ResetCurrentState()
    self.ulPickupButton:Deactivate(nControlMode)
    self.ulPlayerStatusPanel:Deactivate()
    self.pbCompass:Deactivate()
    self.ulBattleTeam:Deactivate()
end

local function OnControlModeActivate(self, nControlMode, tbParam)
    ControlModeActivate(self, nControlMode, FFA_SWITCH_INDEX[nControlMode], BATTLE_SWITCH_INDEX[nControlMode], tbParam)
    self.ulFFAItemPanel:OnControlModeChanged(nControlMode)

    local GamePlayer = GamePlayerSelfHelper:Get()
    local HumanMovementStateComponent = GamePlayer.HumanMovementStateComponent
    if HumanMovementStateComponent then
        OnVehicleStateChange(self, GamePlayer, HumanMovementStateComponent:GetVehicleState(), nil)
    end

    if nControlMode == ControlModeDef.HUMAN then
        PCInputControlHelper:UnregisterShipHandle()
        if PCInputControlHelper.bUsePCControlMode then
            PCInputControlHelper:RegisterHumanHandle()
        end
    elseif nControlMode == ControlModeDef.SHIP then
        PCInputControlHelper:UnregisterHumanHandle()
        if PCInputControlHelper.bUsePCControlMode then
            PCInputControlHelper:RegisterShipHandle()
        end
    end
end

local function OnControlModeDeactivate(self, nControlMode)
    ControlModeDeactivate(self, nControlMode)
end

local function OnSayClicked(self)
    --UIUtils.ShowToast(UISetUtils.GetL10NTextByKey("FFA_FUNCTION_NOT_OPEN"), 1)
    self.pbMainChat:ToggleActivate()
end

local function OnQuestClicked(self)
    self.pbLobbyMisson:ToggleActivate()
end

local function OnFriendClicked(self)
    self.pbFriend:ToggleActivate()
end

local function OnVoiceMicClicked(self)
    local pbVoiceMicCtr = self.pbVoiceMicCtr
    local nMicOption = pbVoiceMicCtr:GetCurrentMicOption()
    local nPressInterval = self.nVoiceMicPressedEnd - self.nVoiceMicPressedStart
    if nMicOption < pbVoiceMicCtr.PRESSALL or pbVoiceMicCtr.bVisible or nPressInterval < 1 then
        self.pbVoiceMicCtr:Toggle()
    end
end

local function ClearVoiceMicPressTimer(self)
    if self.pVoicePressTimer then
        DelayTimer:ClearTimer(self.pVoicePressTimer)
        self.pVoicePressTimer = nil
    end
end

local function ClearDelayEffectTimer(self)
    if self.pDealyEffectTimer then
        DelayTimer:ClearTimer(self.pDealyEffectTimer)
        self.pDealyEffectTimer = nil
    end
end

local function OnVoiceMicReleased(self)
    local pbVoiceMicCtr = self.pbVoiceMicCtr
    local nMicOption = pbVoiceMicCtr:GetCurrentMicOption()
    local pWidgetRef = self.pWidgetRef
    if nMicOption == pbVoiceMicCtr.PRESSALL or nMicOption == pbVoiceMicCtr.PRESSTEAM then
        self.nVoiceMicPressedEnd = os.time()
        GVoiceSDKSystem:EnableMic(false)
        self.bVoiceMicOnPressed = false
        pWidgetRef.imgPress:SetVisibility(ESlateVisibility_Collapsed)
        ClearVoiceMicPressTimer(self)
        ClearDelayEffectTimer(self)
    end
end

local function OnVoiceMicPressed(self)
    local pbVoiceMicCtr = self.pbVoiceMicCtr
    local nMicOption = pbVoiceMicCtr:GetCurrentMicOption()
    local pWidgetRef = self.pWidgetRef
    if nMicOption == pbVoiceMicCtr.PRESSALL or nMicOption == pbVoiceMicCtr.PRESSTEAM then
        self.nVoiceMicPressedStart = os.time()
        GVoiceSDKSystem:EnableMic(true)
        self.bVoiceMicOnPressed = true
        ClearDelayEffectTimer(self)
        self.pDealyEffectTimer = DelayTimer:DelayRun(function() pWidgetRef.imgPress:SetVisibility(ESlateVisibility_HitTestInvisible) end, 0.5)
        ClearVoiceMicPressTimer(self)
        self.pVoicePressTimer = DelayTimer:DelayRun(function() OnVoiceMicReleased(self) end, PRESS_TIME_OUT)
    end
end

local function OnVoiceSpeakerClicked(self)
    if self.bVoiceMicOnPressed then
        return
    end
    self.pbVoiceSpeakerCtr:Toggle()
end

local function OnSetClicked(self)
    -- local Dialog = UIUtils.CreateDialog("游戏设置")
    -- local pbFFASetting = self.PrefabHelper:CreatePrefab(UIDef.UP_FFA_SETTING)
    -- Dialog:SetView(pbFFASetting.pWidgetRef)
    -- Dialog:SetPositiveButtonVisible(false)
    -- Dialog:SetNegativeButtonVisible(false)
    -- Dialog:ShowDialog()
    UIManager:OpenWnd(UIDef.UI_SETTING)
end

local function OnChangeDisplayClicked(self)
    local tbPlayerSelf = GamePlayerSelfHelper:Get()
    local GridTypeManager = CommonShell.GetCommon(GWorld):GetGridTypeManager()
    local pLocation = tbPlayerSelf:GetLocation()
    local nRegionType = GridTypeManager:GetRegionType(pLocation.X, pLocation.Y)

    if tbPlayerSelf:IsHuman() and tbPlayerSelf.HumanWeaponComponent and tbPlayerSelf.HumanWeaponComponent:IsAttacking() then
        UIUtils.ShowToast(UISetUtils.GetL10NTextByKey("CANNOT_CHANGE_TO_SHIP_WHILE_ATTACKING"))
        return
    end

    if nRegionType == EPiratesGridRegionType.Shore or 
        nRegionType == EPiratesGridRegionType.Port then
        EventManager:OnFireEvent(ClientEventDef.EV_UI_REQUEST_CHANGEDISPLAY)
    else
        if tbPlayerSelf:IsHuman() then
            UIUtils.ShowToast(UISetUtils.GetL10NTextByKey("CHANGE_TO_SHIP"))
        else
            UIUtils.ShowToast(UISetUtils.GetL10NTextByKey("CHANGE_TO_HUMAN"))
        end
        MiniMapSystem:ShowPort()
    end
end

local function OnSelectBornPointClicked(self)
    UIManager:OpenWnd(UIDef.UI_FFA_SELECT_BORNPOINT)
end

local function OnFFAChangeDisplayEnable(self, bEnable)
    self.bChangeDisplayEnable = bEnable
end

local function OnSetChangeDisplayVisible(self, bVisible)
    local pWidgetRef = self.pWidgetRef
    local btnChangeDisplay = pWidgetRef.btnChangeDisplay
    if not self.bChangeDisplayEnable then
        return
    end
    if bVisible then
        local bIsShip = GamePlayerSelfHelper:Get():IsShip()
        local nControlMode = bIsShip and ControlModeDef.SHIP or ControlModeDef.HUMAN
        local pNormalRes = CHANGEDISPLAY_NORMAL_ICON[nControlMode]:load()
        local pPressedRes = CHANGEDISPLAY_PRESS_ICON[nControlMode]:load()
        UISetUtils.SetButtonNormalBrushRes(btnChangeDisplay, pNormalRes)
        UISetUtils.SetButtonHoveredBrushRes(btnChangeDisplay, pNormalRes)
        UISetUtils.SetButtonPressedBrushRes(btnChangeDisplay, pPressedRes)
        btnChangeDisplay:SetVisibility(ESlateVisibility.Visible)
        pWidgetRef.txtChangeDisplay:SetText(bIsShip and UITextDef.UI_INTERACTION_CHANGEHUMAN or UITextDef.UI_INTERACTION_CHANGESHIP)
        pWidgetRef.txtChangeDisplay:SetColorAndOpacity(UIResourceDef.COLOR.WHITE.SLATE_COLOR)
    else
        btnChangeDisplay:SetVisibility(ESlateVisibility.Collapsed)
    end
end

local function OnSetPreChangeDisplayVisible(self, bVisible)
    local pWidgetRef = self.pWidgetRef
    local btnChangeDisplay = pWidgetRef.btnChangeDisplay
    if not self.bChangeDisplayEnable then
        return
    end
    local nSettingValue = SettingSystemNew:Get(SettingKeyDef.LocalKeys.CHANGE_DISPLAY)

    if bVisible and nSettingValue > 0 then
        local bIsShip = GamePlayerSelfHelper:Get():IsShip()
        local nControlMode = bIsShip and ControlModeDef.SHIP or ControlModeDef.HUMAN
        local pRes = CHANGEDISPLAY_DISABLED_ICON[nControlMode]:load()
        UISetUtils.SetButtonNormalBrushRes(btnChangeDisplay, pRes)
        UISetUtils.SetButtonHoveredBrushRes(btnChangeDisplay, pRes)
        UISetUtils.SetButtonPressedBrushRes(btnChangeDisplay, pRes)
        btnChangeDisplay:SetVisibility(ESlateVisibility.Visible)
        pWidgetRef.txtChangeDisplay:SetText(bIsShip and UITextDef.UI_INTERACTION_CHANGEHUMAN or UITextDef.UI_INTERACTION_CHANGESHIP)
        pWidgetRef.txtChangeDisplay:SetColorAndOpacity(UIResourceDef.COLOR.GREY.SLATE_COLOR)
    else
        btnChangeDisplay:SetVisibility(ESlateVisibility.Collapsed)
    end    
end

-- local function DeadPostProcess(self)
--     --死亡镜头不需要模糊处理 暂时先注释掉
--     --UEActorHelper:CreateActor(DEAD_POST_PROCESS_ACTOR)
-- end


-- 获得物品事件处理
local function OnBattleItemAdd(self, Item)
    self.ulFFAItemPanel:OnBattleItemAdd(Item)
    self.ulBuildingMaterials:OnItemAdded(Item)
end

-- 移除物品事件处理
local function OnBattleItemRemove(self, nInstanceId, nTemplateId)
    self.ulFFAItemPanel:OnBattleItemRemove(nTemplateId)
    self.ulBuildingMaterials:OnItemRemoved(nTemplateId)
end

-- 物品堆叠数量变化处理
local function OnBattleItemChangeStackCount(self, Item)
    self.ulFFAItemPanel:OnBattleItemChangeStackCount(Item)
    self.ulBuildingMaterials:OnItemChangeStackCount(Item)
end

-- 物品位置变化处理（如装弹之后没有移除事件，只有位置改变事件）
local function OnBattleItemChangeStorageLocation(self)
    self.ulFFAItemPanel:OnBattleItemChangeStorageLocation()
end

-- 物品建造成功事件
local function OnBuildFinish(self)
    self.ulBuildingMaterials:OnItemChanged()
end

-- 舰船可建造等级变化事件
local function OnBuildGradeChanged(self, tbPlayer, _)
    if GamePlayerSelfHelper:GetServerInstanceId() == tbPlayer:GetServerInstanceId() then
        self.ulBuildingMaterials:OnItemChanged()
    end
end

-- 收到战备数据同步
local function OnSyncShipPreparation(self)
    self.ulBuildingMaterials:OnItemChanged()
end

local function OnFFASetting(self, tbPacket)
    local nCurTime = GlobalVariableSystem:GetLocalTime()
    local nRemainTime = tbPacket.nCountDownEndTime - nCurTime
    if nRemainTime > 0  then
        UIManager:OpenWnd(UIDef.UI_COUNT_DOWN2, {nTime = nRemainTime + GlobalVariableSystem:GetLocalTime()})
    end
end

local function OnOpenUI(self, szWndName)
    if not UIDef.FFA_HALF_SCREEN[szWndName] then
        self.pWidgetRef:InterruptTouch()
    end
    self.ulPickupButton:OnOpenUI(szWndName)
end

local function OnFFAProcessStateChanged(self, nState)
    if nState >= ProtoDR.rFFAProcessState_EState.COUNTDOWN and nState < ProtoDR.rFFAProcessState_EState.MATINEE then
        -- self.pWidgetRef.ovlSelectPoint:SetVisibility(ESlateVisibility.Visible)
        EventManager:OnFireEvent(ClientEventDef.EV_UI_SELECT_POINT_BTN)
    end
    if nState == ProtoDR.rFFAProcessState_EState.MATINEE then
        UIManager:CloseWnd(UIDef.UI_COUNT_DOWN2)
        -- self.pWidgetRef.ovlSelectPoint:SetVisibility(ESlateVisibility.Collapsed)
    elseif nState == ProtoDR.rFFAProcessState_EState.PARACHUTING then
        UIManager:CloseWnd(UIDef.UI_TEAM_MEMBER_OFFLINE)
    end
end

local function RefreshPing(self)
    local nPing = ExtendBlueprintFunctions.GetPing(GWorld)
    self.pWidgetRef.txtPing:SetText(nPing.."ms")
    -- if nPing < 120  then
    --     self.pWidgetRef.txtPing:SetColorAndOpacity(UIResourceDef.COLOR.WHITE.SLATE_COLOR)
    -- elseif nPing < 200  then
    --     self.pWidgetRef.txtPing:SetColorAndOpacity(UIResourceDef.COLOR.YELLOW.SLATE_COLOR)
    -- else
    --     self.pWidgetRef.txtPing:SetColorAndOpacity(UIResourceDef.COLOR.RED.SLATE_COLOR)
    -- end
end



local function OnLayoutChanged(self)
    self.ulMainLayout:RefreshLayout()
    self.pbRadarMap:RefreshMapViewSize()
    self.tbControlModePrefab[ControlModeDef.HUMAN]:RefreshLayout()
    self.tbControlModePrefab[ControlModeDef.SHIP]:RefreshLayout()
    if self.pbCurrrentVirtualStick then
        self.pbCurrrentVirtualStick:RefreshLayout()
    end
    self.ulPickupButton:RefreshLayout()
end

local function OnQuestNew(self)
    self.pWidgetRef.ovlMission:SetVisibility(ESlateVisibility.Visible)
end

local function InterruptTouch(self)
    self.pWidgetRef:InterruptTouch()
end

-- local function OnFFATeamChanged(self, tbBattleTeamInfo)
--     local pWidgetRef = self.pWidgetRef
--     local tbTeamInfo = TeamWatchClientHelper.GetCurrentTeamInfo()
--     if not tbTeamInfo then
--         return
--     end
--     if #tbTeamInfo > 1 then
--         pWidgetRef.btnTalk01:SetVisibility(ESlateVisibility.Visible)
--         pWidgetRef.btnTalk02:SetVisibility(ESlateVisibility.Visible)
--     else
--         pWidgetRef.btnTalk01:SetVisibility(ESlateVisibility.Collapsed)
--         pWidgetRef.btnTalk02:SetVisibility(ESlateVisibility.Collapsed)
--     end
--     self.EventHelper:UnregisterEvent(ClientEventDef.EV_FFA_TEAM_INFO_CHANGED, self, OnFFATeamChanged)
-- end

function UIFFAMain:OnLoad()
    local pWidgetRef = self.pWidgetRef
    local PrefabHelper = self.PrefabHelper
    local UILogicHelper = self.UILogicHelper
    pWidgetRef.bTopWindow = false
    self.bVoiceMicOnPressed = false

    --prefab
    local tbControlModePrefab = self.tbControlModePrefab
    tbControlModePrefab[ControlModeDef.HUMAN] = PrefabHelper:BindPrefab(pWidgetRef.pbFFAHuman)
    tbControlModePrefab[ControlModeDef.SHIP] = PrefabHelper:BindPrefab(pWidgetRef.pbFFAShip)
    -- tbControlModePrefab[ControlModeDef.TRANSPORT] = PrefabHelper:BindPrefab(pWidgetRef.pbFFATransport)
    tbControlModePrefab[ControlModeDef.TRANSPORTNEW] = PrefabHelper:BindPrefab(pWidgetRef.pbFFATransport2, UIDef.UP_FFATRANSPORTNEW)

    self.pbCutoutScreenAdapter = PrefabHelper:BindPrefab(pWidgetRef.pbCutoutScreenAdapter)
    self.nCutoutSpacerWidth = self.pbCutoutScreenAdapter:GetCutoutSpacerWidth()
    self.pbRadarMap = PrefabHelper:BindPrefab(pWidgetRef.pbRadarMap, UIDef.UP_RADAR_MAP)
    self.pbCompass = PrefabHelper:BindPrefab(pWidgetRef.pbCompass)
    self.pbMainTips = PrefabHelper:BindPrefab(pWidgetRef.pbMainTips)
    self.pbLobbyMisson = PrefabHelper:BindPrefab(pWidgetRef.pbLobbyMisson)
    self.pbTeamMainHead = PrefabHelper:BindPrefab(pWidgetRef.pbTeamMainHead)
    self.pbMainChatQuickView = PrefabHelper:BindPrefab(pWidgetRef.pbMainChatQuickView)
    self.pbMainChat = PrefabHelper:BindPrefab(pWidgetRef.pbMainChat)
    self.pbFloatNumPanel = PrefabHelper:BindPrefab(pWidgetRef.pbFloatNumPanel)
    self.pbVoiceMicCtr = PrefabHelper:BindPrefab(pWidgetRef.pbFFAMainTalk01)
    -- self.pbVoiceMicCtr:DelaySetDefaultOption()
    self.pbVoiceSpeakerCtr = PrefabHelper:BindPrefab(pWidgetRef.pbFFAMainTalk02)
    local nDungeonId = BattleGameModeSystem.nDungeonId
    if nDungeonId == FriendIni.tbFFA.nTraningCampId then
        self.pbFriend = PrefabHelper:BindPrefab(pWidgetRef.pbFriend)
        pWidgetRef.btnFriend:SetVisibility(ESlateVisibility_Visible)
    end
    -- self.pbVoiceSpeakerCtr:DelaySetDefaultOption()
    --logic
    self.ulFFAToast = UILogicHelper:CreateUILogic("ULFFAToastBoard")
    self.ulPickupButton = UILogicHelper:CreateUILogic("ULPickupButton")

    if GlobalVariableSystem:IsInTrainingCamp(nDungeonId) then
        self.ulBattleInfo = UILogicHelper:CreateUILogic("ULTrainingCampBattleInfo")
    else
        self.ulBattleInfo = UILogicHelper:CreateUILogic("ULBattleInfo")
    end

    self.ulFFAItemPanel = UILogicHelper:CreateUILogic("ULFFAItemPanel")
    self.ulBuildingMaterials = UILogicHelper:CreateUILogic("ULBuildingMaterials")
    self.ulBuffList = UILogicHelper:CreateUILogic("ULBuffList")
    self.ulAttackWarningPanel = UILogicHelper:CreateUILogic("ULAttackWarningPanel")
    self.ulPlayerStatusPanel = UILogicHelper:CreateUILogic("ULPlayerStatusPanel")
    self.ulRescuingPanel = UILogicHelper:CreateUILogic("ULRescuingPanel")
    self.ulBattleTeam = UILogicHelper:CreateUILogic("ULBattleTeam")
    self.ulQuickBuild = UILogicHelper:CreateUILogic("ULQuickBuild")
    self.ulMainLayout = UILogicHelper:CreateUILogic("ULFFAMainLayout")
    self.ulFFAMainProgressBar = UILogicHelper:CreateUILogic("ULFFAMainProgressBar")
    self.uiBattlePointTip = UILogicHelper:CreateUILogic("ULBattlePointTip")

    pWidgetRef.btnTalk01:SetVisibility(ESlateVisibility_Collapsed)
    pWidgetRef.btnTalk02:SetVisibility(ESlateVisibility_Collapsed)
    pWidgetRef.imgPress:SetVisibility(ESlateVisibility_Collapsed)

    local ulFFAMainStaticLayout = UILogicHelper:CreateUILogic("ULFFAMainStaticLayout")
    ulFFAMainStaticLayout:Init()
end

function UIFFAMain:OnBindEvent(EventHelper)
    local pWidgetRef = self.pWidgetRef
    EventHelper:RegisterCppDelegate(pWidgetRef.btnSay.OnClicked                     , self, OnSayClicked)
    EventHelper:RegisterCppDelegate(pWidgetRef.btnSet.OnClicked                     , self, OnSetClicked)
    EventHelper:RegisterCppDelegate(pWidgetRef.btnChangeDisplay.OnClicked           , self, OnChangeDisplayClicked)
    EventHelper:RegisterCppDelegate(pWidgetRef.btnSelectBornPoint.OnClicked         , self, OnSelectBornPointClicked)
    EventHelper:RegisterCppDelegate(pWidgetRef.btnSoulMisson.OnClicked              , self, OnQuestClicked)
    EventHelper:RegisterCppDelegate(pWidgetRef.btnFriend.OnClicked              , self, OnFriendClicked)
    EventHelper:RegisterCppDelegate(pWidgetRef.btnTalk01.OnClicked                  , self, OnVoiceSpeakerClicked)
    EventHelper:RegisterCppDelegate(pWidgetRef.btnTalk02.OnClicked                  , self, OnVoiceMicClicked)
    EventHelper:RegisterCppDelegate(pWidgetRef.btnTalk02.OnPressed                  , self, OnVoiceMicPressed)
    EventHelper:RegisterCppDelegate(pWidgetRef.btnTalk02.OnReleased                  , self, OnVoiceMicReleased)

    EventHelper:RegisterEvent(ClientEventDef.EV_FFA_CONTROL_MODE_ACTIVATE           , self, OnControlModeActivate)
    EventHelper:RegisterEvent(ClientEventDef.EV_FFA_CONTROL_MODE_DEACTIVATE         , self, OnControlModeDeactivate)
    EventHelper:RegisterEvent(ClientEventDef.EV_UI_CHANGE_DISPLAY                   , self, OnSetChangeDisplayVisible)
    EventHelper:RegisterEvent(ClientEventDef.EV_UI_PRE_CHANGE_DISPLAY               , self, OnSetPreChangeDisplayVisible)
    EventHelper:RegisterEvent(ClientEventDef.EV_BATTLE_ITEM_ADD_CLIENT              , self, OnBattleItemAdd)
    EventHelper:RegisterEvent(ClientEventDef.EV_BATTLE_ITEM_REMOVE_CLIENT           , self, OnBattleItemRemove)
    EventHelper:RegisterEvent(ClientEventDef.EV_BATTLE_ITEM_CHANGE_STACKCOUNT_CLIENT, self, OnBattleItemChangeStackCount)
    EventHelper:RegisterEvent(ClientEventDef.EV_SHIP_BUILD_FINISH_CLIENT            , self, OnBuildFinish)
    EventHelper:RegisterEvent(ClientEventDef.EV_SHIP_BUILD_GRADE_CHANGED_CLIENT     , self, OnBuildGradeChanged)
    EventHelper:RegisterEvent(ClientEventDef.EV_BATTLE_ITEM_CHANGE_STORAGE_LOCATION_CLIENT , self, OnBattleItemChangeStorageLocation)
    EventHelper:RegisterEvent(ClientEventDef.EV_OPEN_UI                             , self, OnOpenUI)
    EventHelper:RegisterEvent(ClientEventDef.EV_FFA_PROCESS_STATE_CHANGED           , self, OnFFAProcessStateChanged)
    EventHelper:RegisterEvent(CommonEventDef.EV_ON_VEHICLE_STATE_CHANGE             , self, OnVehicleStateChange)
    EventHelper:RegisterEvent(ClientEventDef.EV_QUEST_NEW                           , self, OnQuestNew)
    EventHelper:RegisterEvent(ClientEventDef.EV_LAYOUT_CHANGED                      , self, OnLayoutChanged)
    EventHelper:RegisterEvent(ClientEventDef.EV_LAYOUT_STYLE_CHANGED                , self, OnLayoutChanged)
    EventHelper:RegisterEvent(ClientEventDef.EV_ON_SYNC_SHIP_PREPARATION            , self, OnSyncShipPreparation)
    EventHelper:RegisterEvent(ClientEventDef.EV_FFA_SETTING                         , self, OnFFASetting)
    EventHelper:RegisterEvent(ClientEventDef.EV_FFA_CHANGE_DISPLAY_ENABLE           , self, OnFFAChangeDisplayEnable)
    EventHelper:RegisterEvent(ClientEventDef.EV_OPERATION_MODE_CHANGED              , self, RefreshShipVehicleLayout)
    EventHelper:RegisterEvent(ClientEventDef.EV_GUIDE_INTERRUPT_TOUCH               , self, InterruptTouch)

    -- EventHelper:RegisterEvent(ClientEventDef.EV_FFA_TEAM_INFO_CHANGED               , self, OnFFATeamChanged)
end

function UIFFAMain:OnEnter()
    if GlobalVariableSystem:IsStandalone() then
        self.pWidgetRef.txtPing:SetVisibility(ESlateVisibility.Collapsed)
    else
        -- 非常临时的做法，lua里不应该有这么频繁的Tick
        self.TimerHelper:NewTimerMethod(self, RefreshPing, 1, true)
        -- 设置DungeonSessionId
        local szDungeonSessionId = BattleGameModeSystem:GetShortDungeonSessionId()
        if not StringUtil.IsEmptyString(szDungeonSessionId) then
            self.pWidgetRef.txtDungeonSessionId:SetText(szDungeonSessionId)
        else
            self.pWidgetRef.txtDungeonSessionId:SetVisibility(ESlateVisibility.Collapsed)
        end
    end
end

function UIFFAMain:OnHide()
    if self.DelayHandle then
        DelayTimer:ClearTimer(self.DelayHandle)
        self.DelayHandle = nil
    end
    WorldMapUtil.nCurrentSliderValue = 0
    PCInputControlHelper:Uninit()
    ClearVoiceMicPressTimer(self)
end

function UIFFAMain:SwitchToPCControlMode(bPC)
	if bPC then
		PCInputControlHelper:Init(self)
	else
		PCInputControlHelper:Uninit()
    end
end

return UIFFAMain