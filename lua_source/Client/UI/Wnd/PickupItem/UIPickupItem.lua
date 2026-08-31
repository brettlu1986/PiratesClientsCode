-----------------------------------------------------
--File Name    : UIPickupItem.lua
--Description  : 拾取掉落物界面
-----------------------------------------------------
local luaclass = require("luaclass")
local WndBase = require("WndBase")
local UIPickupItem = luaclass("UIPickupItem", WndBase)

local ClientEventDef = require("ClientEventDef")
local SelfVerticalListHelper = require("SelfVerticalListHelper")
local UIDef = require("UIDef")
local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
local DelayTimer = require("DelayTimer")
local BattlePickupSystem = require("BattlePickupSystem")
local BattlePickTypeDef = require("BattlePickTypeDef")
local GameCameraModeGroupDef = require("GameCameraModeGroupDef")
local GameCameraSystem = require("GameCameraSystem")
local UIManager = require("UIManager")
local SettingSystemNew = require("SettingSystemNew")
local SettingClassType = require("SettingClassType")
local SettingLayoutFromDef = require("SettingLayoutFromDef")
local HumanWeaponHelper = require("HumanWeaponHelper")
local HumanWeaponStateDef = require("HumanWeaponStateDef")
local CommonEventDef = require("CommonEventDef")
local GameObjectTypeDef = require("GameObjectTypeDef")
local HumanVehicleStateDef = require("HumanVehicleStateDef")
local BattlePickPosDef = require("BattlePickPosDef")
local HumanMovementStateType = require("HumanMovementStateType")
local BattlePickupIni = require("BattlePickupIni")

local AUTO_PICK_DELAY = BattlePickupIni.tbBattlePickup.nAutoPickupDelay
local FIRST_AUTO_PICK_DELAY = BattlePickupIni.tbBattlePickup.nFirstAutoPickupDelay
local PICKUP_TIMEOUT = 1


local PICK_ITEM_LOCAL_ID = 13
local CUSTOM_PICK_POS = BattlePickPosDef.CustomPos
local DEFAULT_PICK_POS = BattlePickPosDef.DefaultPos

UIPickupItem.ListHelper = nil
UIPickupItem.nCurrentAutoInstanceId = nil
UIPickupItem.nItemTemplateId = nil
UIPickupItem.nCount = nil
UIPickupItem.tbDelayPickHandle = nil
UIPickupItem.tbDelayResetHandle = nil
UIPickupItem.tbDelayCloseHandle = nil
UIPickupItem.tbItemLayoutData = nil
UIPickupItem.bFirstPickup = nil
UIPickupItem.tbOpenWndName = nil

local function SetRootPos(self)
    local nX = self.tbItemLayoutData.nX + DEFAULT_PICK_POS[UIDef.UI_PICKUP_ITEM].X_OFFSET * self.tbItemLayoutData.nScale
    local nY = self.tbItemLayoutData.nY + DEFAULT_PICK_POS[UIDef.UI_PICKUP_ITEM].Y_OFFSET * self.tbItemLayoutData.nScale
    local szOpenWndName = BattlePickPosDef.GetFirstPriorityWnd(self.tbOpenWndName)
    if szOpenWndName then
        local tbCustomPos = CUSTOM_PICK_POS[szOpenWndName][UIDef.UI_PICKUP_ITEM]
        if tbCustomPos then
            nX = self.tbItemLayoutData.nX + tbCustomPos.X_OFFSET * self.tbItemLayoutData.nScale
            nY = self.tbItemLayoutData.nY + tbCustomPos.Y_OFFSET * self.tbItemLayoutData.nScale
            nX = nX + tbCustomPos.X_SHIFT_OFFSET
        end
    end
    self.pWidgetRef.bdrClose.Slot:SetPosition(Vector2D{X = nX, Y = nY})
end

local function IsUnableAutoPickupState(self)
    if self.tbDelayPickHandle then
        log("UIPickupItem:IsUnableAutoPickupState return 1")
        return true
    end
    local PlayerSelf = GamePlayerSelfHelper:Get()
    local ProgressBarComponent = PlayerSelf.ProgressBarComponent
    if ProgressBarComponent and ProgressBarComponent:IsInProgress() then
        log("UIPickupItem:IsUnableAutoPickupState return 2")
        return true
    end

    local HumanWeaponComponent = GamePlayerSelfHelper:Get().HumanWeaponComponent
    if HumanWeaponHelper.IsHumanAiming(PlayerSelf) then
        local szAnimKey = "PickUp"
        HumanWeaponComponent:StopCurrentMontage(szAnimKey)
        log("UIPickupItem:IsUnableAutoPickupState return 3")
        return true
    end

    if HumanWeaponComponent then
        local nCurrentState = HumanWeaponComponent:GetCurrentState()
        if nCurrentState == HumanWeaponStateDef.RELOADING or nCurrentState == HumanWeaponStateDef.ATTACKING then
            log("UIPickupItem:IsUnableAutoPickupState return 4")
            return true
        end
    end
end

local function DelayPickup(self)
    self.tbDelayPickHandle = nil
    if IsUnableAutoPickupState(self) then
        self.nCurrentAutoInstanceId = nil
        self.nItemTemplateId = nil
        self.nCount = nil
        return
    end
    local bResult = BattlePickupSystem:RequestPickupItem(self.nCurrentAutoInstanceId, self.nItemTemplateId, self.nCount)
    if not bResult then
        self.nCurrentAutoInstanceId = nil
        self.nItemTemplateId = nil
        self.nCount = nil
        return
    end
    if self.nCurrentAutoInstanceId then
        self.tbDelayResetHandle = DelayTimer:DelayRun(function()
            self.nCurrentAutoInstanceId = nil
            self.nItemTemplateId = nil
            self.nCount = nil
            self.tbDelayResetHandle = nil
        end, PICKUP_TIMEOUT, "UIPickupItem DelayPickup")
    end
end

local function AutoPickup(self, tbItems)
    log("UIPickupItem:AutoPickup start")
    -- 读条中不自动拾取
    if IsUnableAutoPickupState(self) then
        return
    end
    local SelfServerId = GamePlayerSelfHelper:Get():GetServerInstanceId()
    for k, v in ipairs(tbItems) do
        log("UIPickupItem:AutoPickup,",v.instance_id, v.bIsAutoPickUp, SelfServerId, v.last_owner_character_instance_id)
        if v.bIsAutoPickUp and SelfServerId ~= v.last_owner_character_instance_id then
            self.nCurrentAutoInstanceId = v.instance_id
            self.nItemTemplateId = v.template_id
            local nAutoPickUpCount = v.nAutoPickUpCount
            if not nAutoPickUpCount then
                self.nCount = v.stack_count
            else
                self.nCount = math.min(nAutoPickUpCount, v.stack_count)
            end
            local nAutoPickupDelay = AUTO_PICK_DELAY
            if self.bFirstPickup then
                self.bFirstPickup = false
                nAutoPickupDelay = FIRST_AUTO_PICK_DELAY
            end
            self.tbDelayPickHandle = DelayTimer:DelayRun(function() DelayPickup(self) end, nAutoPickupDelay, "UIPickupItem AutoPickup")
            break
        end
    end
    log("UIPickupItem:AutoPickup start")
end

local function RefreshData(self)
    log("UIPickupItem:RefreshData start")
    local t1 = getseconds() * 1000
    local tbItems = BattlePickupSystem:GetViewDataByPickType(BattlePickTypeDef.ITEM)
    local t2 = getseconds() * 1000
    --log("UIPickupItem:GetViewDataByPickType end")
    if not tbItems or #tbItems == 0 then
        local tbRequestIds = BattlePickupSystem:GetRequestIdsByPickType(BattlePickTypeDef.ITEM)
        if not tbRequestIds or #tbRequestIds == 0 then
            self.EventHelper:FireEvent(ClientEventDef.EV_BATTLE_PICKUP_CLEAR)
            self:CloseSelf()
            return
        end
    end
    local t3 = getseconds() * 1000
    --log("UIPickupItem:RefreshData SetData")
    self.ListHelper:SetData(tbItems)
    local t4 = getseconds() * 1000
    log("UIPickupItem:RefreshData",self.nCurrentAutoInstanceId, BattlePickupSystem.nProgressBarId)
    if not self.nCurrentAutoInstanceId and not BattlePickupSystem.nProgressBarId then
        AutoPickup(self, tbItems)
    end
    local t5 = getseconds() * 1000
    log("UIPickupItem:RefreshData end", t1, t2-t1, t3-t2, t4-t3, t5-t4, t5-t1)
end

local function OnPickupFinish(self, nInstanceId)
    if nInstanceId == self.nCurrentAutoInstanceId then
        self.nCurrentAutoInstanceId = nil
        self.nItemTemplateId = nil
        self.nCount = nil
        if self.tbDelayResetHandle then
            DelayTimer:ClearTimer(self.tbDelayResetHandle)
            self.tbDelayResetHandle = nil
        end
    end
    RefreshData(self)
end

local function OnBattleItemSyncSceneItem(self)
    RefreshData(self)
end

local function OnBattlePickupRemove(self)
    RefreshData(self)
end

local function OnBattleRefreshPickupList(self)
    RefreshData(self)
end

local function OnLeavePickupTrigger(self, nPickType, nInstanceId)
    if nPickType == BattlePickTypeDef.ITEM then
        local tbRequestIds = BattlePickupSystem:GetRequestIdsByPickType(BattlePickTypeDef.ITEM)
        if not tbRequestIds or #tbRequestIds == 0 then
            if self.tbDelayCloseHandle then
                DelayTimer:ClearTimer(self.tbDelayCloseHandle)
                self.tbDelayCloseHandle = nil
            end
            self.tbDelayCloseHandle = DelayTimer:RunNextTick(function()
                self.tbDelayCloseHandle = nil
                RefreshData(self)
            end, "UIPickupItem OnLeavePickupTrigger, request id count is 0")
            return
        end
        RefreshData(self)
    end
end


local function OnOpenUI(self, szWndName)
    if CUSTOM_PICK_POS[szWndName] then
        self.tbOpenWndName[szWndName] = true
        SetRootPos(self)
    end
end


local function OnCloseUI(self, szWndName)
    if CUSTOM_PICK_POS[szWndName] then
        self.tbOpenWndName[szWndName] = nil
        SetRootPos(self)
    end
end

local function OnFFAAimStateChanged(self, bOpenAim)
    if bOpenAim then
        self.pWidgetRef:SetVisibility(ESlateVisibility.Collapsed)
    else
        self.pWidgetRef:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
    end
end

local function OnFreeViewStart(self)
    --如果是在freeview mode下，屏蔽输入事件
    if GameCameraSystem:IsCameraLogicActive(GameCameraModeGroupDef.HumanFreeView) then
        self.pWidgetRef.bdrClose:SetVisibility(ESlateVisibility.HitTestInvisible)
    else
        self.pWidgetRef.bdrClose:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
    end
end

local function OnFreeViewEnd(self)
    self.pWidgetRef.bdrClose:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
end

local function OnUserWidgetTouchEnded(self, pGeometry, pMouseEvent)
    self.EventHelper:FireEvent(ClientEventDef.EV_USER_WIDGET_TOUCH_END, UIDef.UI_PICKUP_ITEM, pGeometry, pMouseEvent)
end

local function LoadPickupSetting(self)
    local nFrom = SettingLayoutFromDef.HUMAN
    local SettingLayout = SettingSystemNew:GetInstance(SettingClassType.Setting_Layout)
    local nItemRemoteId = SettingLayout:ConvertToCurrentStyleRemoteId(nFrom, PICK_ITEM_LOCAL_ID)
    self.tbItemLayoutData = SettingLayout:GetLayout(nFrom, nItemRemoteId)
    local pItemWidget = self.pWidgetRef.bdrClose
    SetRootPos(self)
    pItemWidget:SetRenderOpacity(self.tbItemLayoutData.nAlpha)
    pItemWidget:SetRenderScale(Vector2D{X = self.tbItemLayoutData.nScale, Y = self.tbItemLayoutData.nScale})
end

local function OnWeaponStateChanged(self, nCurrentState, Owner)
    if Owner:GetServerInstanceId() ~= GamePlayerSelfHelper:GetServerInstanceId() then
        return
    end
    RefreshData(self)
end

local function OnVehicleStateChange(self, Player, nState, nVehicleId)
    if Player.ObjectType == GameObjectTypeDef.PlayerSelf then
        if nState == HumanVehicleStateDef.None or nState == HumanVehicleStateDef.DetachFromVehicle then
            RefreshData(self)
        end
    end
end

local function OnClosePickClicked(self)
    BattlePickupSystem:SetItemAutoOpen(false)
    self:CloseSelf()
end

local function OnMovementStateChanged(self, tbCharacter, nOldState, nNewState)
    if tbCharacter.ObjectType == GameObjectTypeDef.PlayerSelf then
        log("UIPickupItem:OnMovementStateChanged,nOldState, nNewState=",nOldState, nNewState)
        if nOldState == HumanMovementStateType.Jumping_SpeelWall and nNewState == HumanMovementStateType.UpRight_State then
            RefreshData(self)
        end
    end
end

function UIPickupItem:OnLoad()
    local PrefabHelper = self.PrefabHelper
    PrefabHelper:BindPrefab(self.pWidgetRef.pbCutoutScreenAdapter)
    self.ListHelper = SelfVerticalListHelper()
    self.ListHelper:Init(self, self.pWidgetRef.kmvlistItem, {}, UIDef.UP_PICKUP_ITEM)
end

function UIPickupItem:OnBindEvent(EventHelper)
    EventHelper:RegisterCppDelegate(self.pWidgetRef.btnClosePick.OnClicked, self, OnClosePickClicked)
    EventHelper:RegisterCppDelegate(self.pWidgetRef.OnTouchEndedEvent, self, OnUserWidgetTouchEnded)
    EventHelper:RegisterEvent(ClientEventDef.EV_BATTLE_ITEM_SYNC_SCENE_ITEM, self, OnBattleItemSyncSceneItem)
    EventHelper:RegisterEvent(ClientEventDef.EV_BATTLE_PICKUP_REMOVE, self, OnBattlePickupRemove)
    EventHelper:RegisterEvent(ClientEventDef.EV_BATTLE_REFRESH_PICKUP_LIST, self, OnBattleRefreshPickupList)
    EventHelper:RegisterEvent(ClientEventDef.EV_BATTLE_PICKUP_LEAVE, self, OnLeavePickupTrigger)
    EventHelper:RegisterEvent(ClientEventDef.EV_OPEN_UI, self, OnOpenUI)
    EventHelper:RegisterEvent(ClientEventDef.EV_PRE_CLOSE_UI, self, OnCloseUI)
    EventHelper:RegisterEvent(ClientEventDef.EV_PICK_UP_FINISH, self, OnPickupFinish)
    EventHelper:RegisterEvent(ClientEventDef.EV_FFA_AIM_STATE_CHANGED, self, OnFFAAimStateChanged)
    EventHelper:RegisterEvent(ClientEventDef.EV_FREE_VIEW_START, self, OnFreeViewStart)
    EventHelper:RegisterEvent(ClientEventDef.EV_FREE_VIEW_END, self, OnFreeViewEnd)
    EventHelper:RegisterEvent(ClientEventDef.EV_LAYOUT_CHANGED, self, LoadPickupSetting)
    EventHelper:RegisterEvent(CommonEventDef.EV_HUMAN_WEAPON_STATE_CHANGED, self, OnWeaponStateChanged)
    EventHelper:RegisterEvent(CommonEventDef.EV_ON_VEHICLE_STATE_CHANGE, self, OnVehicleStateChange)
    EventHelper:RegisterEvent(CommonEventDef.EV_HUMAN_MOVEMENT_STATE_CHANGED, self, OnMovementStateChanged)
end

function UIPickupItem:OnShow()
    local tbOpenArgs = self.tbOpenArgs
    self.tbOpenWndName = tbOpenArgs.tbOpenWndName and tbOpenArgs.tbOpenWndName or {}
    self.nCurrentAutoInstanceId = nil
    self.nItemTemplateId = nil
    self.nCount = nil
    self.bFirstPickup = true
    RefreshData(self)
    OnFreeViewStart(self)
    LoadPickupSetting(self)
    SetRootPos(self)
end


function UIPickupItem:OnExit()
    if self.tbDelayPickHandle then
        DelayTimer:ClearTimer(self.tbDelayPickHandle)
        self.tbDelayPickHandle = nil
    end
    if self.tbDelayResetHandle then
        DelayTimer:ClearTimer(self.tbDelayResetHandle)
        self.tbDelayResetHandle = nil
    end
    if self.tbDelayCloseHandle then
        DelayTimer:ClearTimer(self.tbDelayCloseHandle)
        self.tbDelayCloseHandle = nil
    end

    local szWndName = UIDef.UI_PICKUP_EXCHANGE_ITEM
    if UIManager:IsWndOpen(szWndName) then
        log("[DebugPickupExchange] UI_PickupItem关闭，同时关闭 UI_PickupExchangeItem")
        UIManager:CloseWnd(szWndName)
    end
end

function UIPickupItem:OnDestroy()
    self.ListHelper:Uninit()
end

return UIPickupItem