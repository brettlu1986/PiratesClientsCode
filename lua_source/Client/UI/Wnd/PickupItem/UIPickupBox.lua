-----------------------------------------------------
--File Name    : UIPickupBox.lua
--Description  : 拾取箱子界面
-----------------------------------------------------
local luaclass = require("luaclass")
local WndBase = require("WndBase")
local UIPickupBox = luaclass("UIPickupBox", WndBase)

local ClientEventDef = require("ClientEventDef")
local SelfVerticalListHelper = require("SelfVerticalListHelper")
local UIDef = require("UIDef")
local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
local L10N = require("L10N")
local UISetUtils = require("UISetUtils")
local DelayTimer = require("DelayTimer")
local BattleItemDataTable = require("BattleItemDataTable")
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
local BattlePickPosDef = require("BattlePickPosDef")
local HumanMovementStateType = require("HumanMovementStateType")
local GameObjectTypeDef = require("GameObjectTypeDef")
local BattlePickupIni = require("BattlePickupIni")

local OPEN_POS =
{
    CENTER = 1,
    LEFT = 2
}

local AUTO_PICK_DELAY = BattlePickupIni.tbBattlePickup.nAutoPickupDelay
local FIRST_AUTO_PICK_DELAY = BattlePickupIni.tbBattlePickup.nFirstAutoPickupDelay
local PICKUP_TIMEOUT = 1

local MAX_COLUMNS = 3



local PICK_BOX_LOCAL_ID = 12
local CUSTOM_PICK_POS = BattlePickPosDef.CustomPos
local DEFAULT_PICK_POS = BattlePickPosDef.DefaultPos

UIPickupBox.tbListData = {}
UIPickupBox.ListHelper = nil
UIPickupBox.nCurrentAutoInstanceId = nil
UIPickupBox.nItemTemplateId = nil
UIPickupBox.nCount = nil
UIPickupBox.tbDelayPickHandle = nil
UIPickupBox.tbDelayResetHandle = nil
UIPickupBox.tbDelayCloseHandle = nil
UIPickupBox.tbBoxLayoutData = nil
UIPickupBox.bFirstPickup = nil
UIPickupBox.tbOpenWndName = nil

local function SetRootPos(self, nOpenPos)
    -- local RootPos = nOpenPos
    -- if not RootPos or not OPEN_POS_COORDINATE[RootPos] then
    --     RootPos = OPEN_POS.CENTER
    -- end
    local nX = self.tbBoxLayoutData.nX + DEFAULT_PICK_POS[UIDef.UI_PICKUP_BOX].X_OFFSET * self.tbBoxLayoutData.nScale
    local nY = self.tbBoxLayoutData.nY + DEFAULT_PICK_POS[UIDef.UI_PICKUP_BOX].Y_OFFSET * self.tbBoxLayoutData.nScale

    local szOpenWndName = BattlePickPosDef.GetFirstPriorityWnd(self.tbOpenWndName)
    if szOpenWndName then
        local tbCustomPos = CUSTOM_PICK_POS[szOpenWndName][UIDef.UI_PICKUP_BOX]
        if tbCustomPos then
            nX = self.tbBoxLayoutData.nX + tbCustomPos.X_OFFSET * self.tbBoxLayoutData.nScale
            nY = self.tbBoxLayoutData.nY + tbCustomPos.Y_OFFSET * self.tbBoxLayoutData.nScale
            nX = nX + tbCustomPos.X_SHIFT_OFFSET
        end
    end
    self.pWidgetRef.bdrClose.Slot:SetPosition(Vector2D{X = nX, Y = nY})
end

local function IsUnableAutoPickupState(self)
    if self.tbDelayPickHandle then
        log("UIPickupBox:IsUnableAutoPickupState return 1")
        return true
    end
    local PlayerSelf = GamePlayerSelfHelper:Get()
    local ProgressBarComponent = PlayerSelf.ProgressBarComponent
    if ProgressBarComponent and ProgressBarComponent:IsInProgress() then
        log("UIPickupBox:IsUnableAutoPickupState return 2")
        return true
    end

    local HumanWeaponComponent = GamePlayerSelfHelper:Get().HumanWeaponComponent
    if HumanWeaponHelper.IsHumanAiming(PlayerSelf) then
        local szAnimKey = "PickUp"
        HumanWeaponComponent:StopCurrentMontage(szAnimKey)
        log("UIPickupBox:IsUnableAutoPickupState return 3")
        return true
    end
    
    if HumanWeaponComponent then
        local nCurrentState = HumanWeaponComponent:GetCurrentState()
        if nCurrentState == HumanWeaponStateDef.RELOADING or nCurrentState == HumanWeaponStateDef.ATTACKING then
            log("UIPickupBox:IsUnableAutoPickupState return 4")
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
        end, PICKUP_TIMEOUT, "UIPickupBox DelayPickup")
    end
end

local function AutoPickup(self, tbItems)
    log("UIPickupBox:AutoPickup start")
    -- 读条中不自动拾取
    if IsUnableAutoPickupState(self) then
        return
    end
    local SelfServerId = GamePlayerSelfHelper:Get():GetServerInstanceId()
    for k, v in ipairs(tbItems) do
        log("UIPickupBox:AutoPickup,",v.instance_id, v.bIsAutoPickUp, SelfServerId, v.last_owner_character_instance_id)
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
            self.tbDelayPickHandle = DelayTimer:DelayRun(function() DelayPickup(self) end, nAutoPickupDelay, "UIPickupBox AutoPickup")
            
            break
        end
    end
    log("UIPickupBox:AutoPickup end")
end

local function SeparationData(self, tbItems, nRoomInstanceId)
    local tbData = {}
    local nRowCount = math.ceil(#tbItems / 3)
    for i = 1, nRowCount do
        tbData = {}
        tbData.nRoomInstanceId = nRoomInstanceId
        tbData.tbItemList = {}
        for j = 1, MAX_COLUMNS do
            local nIndex = (i - 1) * MAX_COLUMNS + j
            local tbItemData = tbItems[nIndex]
            if tbItemData then
                table.insert(tbData.tbItemList, tbItemData)
            end
        end
        table.insert(self.tbListData, tbData)
    end
end

local function RefreshData(self)
    local t1 = getseconds() * 1000
    log("UIPickupBox:RefreshData start", t1)
    local tbSceneRooms = BattlePickupSystem:GetAllBoxViewData()
    if not tbSceneRooms or #tbSceneRooms == 0 then
        local tbRequestIds = BattlePickupSystem:GetAllBoxRequestIds()
        if not tbRequestIds or #tbRequestIds == 0 then
            self:CloseSelf()
            return
        end
    else
        local bEmpty = true
        for k, v in ipairs(tbSceneRooms) do
            if v.items and #v.items > 0 then
                bEmpty = false
            end
        end
        if bEmpty then
            self.EventHelper:FireEvent(ClientEventDef.EV_BATTLE_PICKUP_CLEAR)
        end
    end
    local t2 = getseconds() * 1000
    local tbItems = BattlePickupSystem:GetViewDataByPickType(BattlePickTypeDef.ITEM)
    local t3 = getseconds() * 1000
    self.tbListData = {}
    log("UIPickupBox:RefreshData, room count",#tbSceneRooms)
    for k, v in ipairs(tbSceneRooms)do
        --logdebug("k=",k)
        local tbData = {}
        tbData.bTitle = true
        tbData.nRoomInstanceId = v.instance_id
        tbData.nRoomItemTemplateId = v.template_id
        if v.last_owner_name and v.last_owner_name ~= "" then
            tbData.szLastOwnerName = L10N:Format(UISetUtils.GetL10NTextByKey("UI_FFA_PICKUP_BOX"), v.last_owner_name)
        else
            local tbBoxTemplate = BattleItemDataTable:GetTemplate(v.template_id)
            tbData.szLastOwnerName = tbBoxTemplate.l10nName
        end
        table.insert(self.tbListData, tbData)
        SeparationData(self, v.items, v.instance_id)
        log("UIPickupBox:RefreshData",self.nCurrentAutoInstanceId, BattlePickupSystem.nProgressBarId,v.instance_id)
        if not self.nCurrentAutoInstanceId and not BattlePickupSystem.nProgressBarId then
            AutoPickup(self, v.items)
        end
    end
    if tbItems and #tbItems > 0 then
        local tbData = {}
        tbData.bTitle = true
        tbData.szLastOwnerName = UISetUtils.GetL10NTextByKey("UI_FFA_PICKUP_NEARBY")
        table.insert(self.tbListData, tbData)
        SeparationData(self, tbItems, nil)
        log("UIPickupBox:RefreshData",self.nCurrentAutoInstanceId, BattlePickupSystem.nProgressBarId)
        if not self.nCurrentAutoInstanceId and not BattlePickupSystem.nProgressBarId then
            AutoPickup(self, tbItems)
        end
    end
    local t4= getseconds() * 1000
    self.ListHelper:SetData(self.tbListData)
    local t5 = getseconds() * 1000
    log("UIPickupBox:RefreshData end", t1, t5, t2-t1, t3-t2, t4-t3, t5-t4, t5-t1)
end


local function OnPickupFinish(self, nInstanceId)
    if self.nCurrentAutoInstanceId == nInstanceId then
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
    end
end

local function LoadPickupSetting(self)
    local nFrom = SettingLayoutFromDef.HUMAN
    local SettingLayout = SettingSystemNew:GetInstance(SettingClassType.Setting_Layout)
    local nBoxRemoteId = SettingLayout:ConvertToCurrentStyleRemoteId(nFrom, PICK_BOX_LOCAL_ID)
    self.tbBoxLayoutData = SettingLayout:GetLayout(nFrom, nBoxRemoteId)
    local pBoxWidget = self.pWidgetRef.bdrClose
    local bIsFFABackpackVisible = UIManager:IsWndVisible(UIDef.UI_FFABACKPACK)
    if bIsFFABackpackVisible then
        SetRootPos(self, OPEN_POS.LEFT)
    else
        SetRootPos(self, OPEN_POS.CENTER)
    end
    pBoxWidget:SetRenderOpacity(self.tbBoxLayoutData.nAlpha)
    pBoxWidget:SetRenderScale(Vector2D{X = self.tbBoxLayoutData.nScale, Y = self.tbBoxLayoutData.nScale})
end

local function OnFreeViewEnd(self)
    self.pWidgetRef.bdrClose:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
end

local function OnUserWidgetTouchEnded(self, pGeometry, pMouseEvent)
    self.EventHelper:FireEvent(ClientEventDef.EV_USER_WIDGET_TOUCH_END, UIDef.UI_PICKUP_BOX, pGeometry, pMouseEvent)
end

local function OnLeavePickupTrigger(self, nPickType, nInstanceId)
    local tbRequestIds = BattlePickupSystem:GetAllBoxRequestIds()
    if not tbRequestIds or #tbRequestIds == 0 then
        if self.tbDelayCloseHandle then
            DelayTimer:ClearTimer(self.tbDelayCloseHandle)
            self.tbDelayCloseHandle = nil
        end
        self.tbDelayCloseHandle = DelayTimer:RunNextTick(function()
            self.tbDelayCloseHandle = nil
            RefreshData(self)
        end, "UIPickupBox OnLeavePickupTrigger, request id count is 0")
        return
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

local function OnWeaponStateChanged(self, nCurrentState, Owner)
    if Owner:GetServerInstanceId() ~= GamePlayerSelfHelper:GetServerInstanceId() then
        return
    end
    RefreshData(self)
end

local function OnClosePickClicked(self)
    BattlePickupSystem:SetBoxAutoOpen(false)
    self:CloseSelf()
end

local function OnMovementStateChanged(self, tbCharacter, nOldState, nNewState)
    if tbCharacter.ObjectType == GameObjectTypeDef.PlayerSelf then
        log("UIPickupBox:OnMovementStateChanged,nOldState, nNewState=",nOldState, nNewState)
        if nOldState == HumanMovementStateType.Jumping_SpeelWall and nNewState == HumanMovementStateType.UpRight_State then
            RefreshData(self)
        end
    end
end

function UIPickupBox:OnLoad()
    local PrefabHelper = self.PrefabHelper
    PrefabHelper:BindPrefab(self.pWidgetRef.pbCutoutScreenAdapter)
    self.ListHelper = SelfVerticalListHelper()
    self.ListHelper:Init(self, self.pWidgetRef.kmvlistBox, {})
end

function UIPickupBox:OnBindEvent(EventHelper)
    EventHelper:RegisterCppDelegate(self.pWidgetRef.btnClosePick.OnClicked, self, OnClosePickClicked)
    EventHelper:RegisterCppDelegate(self.pWidgetRef.OnTouchEndedEvent, self, OnUserWidgetTouchEnded)
    EventHelper:RegisterEvent(ClientEventDef.EV_BATTLE_PICKUP_REMOVE, self, OnBattlePickupRemove)
    EventHelper:RegisterEvent(ClientEventDef.EV_BATTLE_PICKUP_LEAVE, self, OnLeavePickupTrigger)
    EventHelper:RegisterEvent(ClientEventDef.EV_BATTLE_ITEM_SYNC_SCENE_ITEM, self, OnBattleItemSyncSceneItem)
    EventHelper:RegisterEvent(ClientEventDef.EV_BATTLE_REFRESH_PICKUP_LIST, self, OnBattleRefreshPickupList)
    EventHelper:RegisterEvent(ClientEventDef.EV_PICK_UP_FINISH, self, OnPickupFinish)
    EventHelper:RegisterEvent(ClientEventDef.EV_OPEN_UI, self, OnOpenUI)
    EventHelper:RegisterEvent(ClientEventDef.EV_PRE_CLOSE_UI, self, OnCloseUI)
    EventHelper:RegisterEvent(ClientEventDef.EV_FFA_AIM_STATE_CHANGED, self, OnFFAAimStateChanged)
    EventHelper:RegisterEvent(ClientEventDef.EV_FREE_VIEW_START, self, OnFreeViewStart)
    EventHelper:RegisterEvent(ClientEventDef.EV_FREE_VIEW_END, self, OnFreeViewEnd)
    EventHelper:RegisterEvent(ClientEventDef.EV_LAYOUT_CHANGED, self, LoadPickupSetting)
    EventHelper:RegisterEvent(ClientEventDef.EV_FFA_CLOSE_PICKUP, self, OnClosePickClicked)
    EventHelper:RegisterEvent(CommonEventDef.EV_HUMAN_WEAPON_STATE_CHANGED, self, OnWeaponStateChanged)
    EventHelper:RegisterEvent(CommonEventDef.EV_HUMAN_MOVEMENT_STATE_CHANGED, self, OnMovementStateChanged)
end

function UIPickupBox:OnShow()
    BattlePickupSystem:SetBoxAutoOpen(true)
    local tbOpenArgs = self.tbOpenArgs
    self.tbOpenWndName = tbOpenArgs.tbOpenWndName and tbOpenArgs.tbOpenWndName or {}
    self.nCurrentAutoInstanceId = nil
    self.bFirstPickup = true
    RefreshData(self)
    OnFFAAimStateChanged(self, tbOpenArgs.bOpenAim)
    OnFreeViewStart(self)
    LoadPickupSetting(self)
    SetRootPos(self)
end

function UIPickupBox:OnExit()
    --BattleItemSystemClient:RequestEndViewSceneItems()
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
        UIManager:CloseWnd(szWndName)
        log("[DebugPickupExchange] UI_PickupBox关闭，同时关闭 UI_PickupExchangeItem")
    end
end

function UIPickupBox:OnDestroy()
    self.ListHelper:Uninit()
end

return UIPickupBox