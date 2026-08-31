
local luaclass = require("luaclass")
local UILogicBase = require("UILogicBase")
local ULShipWeaponPanel = luaclass("ULShipWeaponPanel", UILogicBase)

local UIDef = require("UIDef")
local MathUtil = require("MathUtil")
local UIManager = require("UIManager")
local ResourceManager = require("ResourceManager")
local SettingSystemNew = require("SettingSystemNew")
local ShipFiringOperationDef = require("ShipFiringOperationDef")
local ShipWeaponCategoryDataTable = require("ShipWeaponCategoryDataTable")
local SoundManager = require("SoundManager")
local SettingKeyDef = require("SettingKeyDef")
local ClientEventDef = require("ClientEventDef")
local ShipWeaponSlotDef = require("ShipWeaponSlotDef")
local UISetUtils = require("UISetUtils")
local InputHandle = require("InputHandle")
local BattleItemDataTable = require("BattleItemDataTable")
local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
local BattleItemCategoryDef = require("BattleItemCategoryDef")
local CommonEventDef = require("CommonEventDef")
local UIResourceDef = require("UIResourceDef")
local BattleShipWeaponSystem = dynamic_require("BattleShipWeaponSystem")

local REQUEST_FIRE_INTERVAL     = 0.1
local SETTING_CLOSE             = 0
local SETTING_AIMOPEN           = 1
local BULLET_RELOAD_INTERVAL    = 0.1
local TIMER_TEXT_PRECISION      = 1
local TIMER_TEXT_DETAIL_MODE    = 1
local TIMEFORMAT                = {"s"}
local SHIP_WEAPON_SLOT_NAME     = "pbShipWeaponSlot"

ULShipWeaponPanel.tbFireResLoadingStatus= nil
ULShipWeaponPanel.tbFiringButtonState   = nil
ULShipWeaponPanel.pbShipWeaponCannon    = nil
ULShipWeaponPanel.tbShipWeaponSlot      = nil
ULShipWeaponPanel.bBtnFirePressed       = false

local function LOG(...)
    log("[ULShipWeaponPanel]", ...)
end

local function IsActiveWeaponItem(WeaponItem)
    return BattleShipWeaponSystem:GetActiveWeaponItem_C() == WeaponItem
end

-----------------------------------------------------------------------
-- 开火按钮UI相关逻辑
-----------------------------------------------------------------------
local function UpdateBtnFireRes(self, szWeaponFireNormal, szWeaponFirePressed)
    local btnFireLeft = self.pWidgetRef.btnFireLeft
    local btnFireRight = self.pWidgetRef.btnFireRight
    if szWeaponFireNormal then
        local pWeaponFireNormal = szWeaponFireNormal:load()
        UISetUtils.SetButtonNormalBrushRes(btnFireLeft, pWeaponFireNormal)
        UISetUtils.SetButtonHoveredBrushRes(btnFireLeft, pWeaponFireNormal)
        UISetUtils.SetButtonNormalBrushRes(btnFireRight, pWeaponFireNormal)
        UISetUtils.SetButtonHoveredBrushRes(btnFireRight, pWeaponFireNormal)
    end
    if szWeaponFirePressed then
        local pWeaponFirePressed = szWeaponFirePressed:load()
        UISetUtils.SetButtonPressedBrushRes(btnFireLeft, pWeaponFirePressed)
        UISetUtils.SetButtonPressedBrushRes(btnFireRight, pWeaponFirePressed)
    end
end

-- 更新左侧开火按钮显隐
local function UpdateBtnFireLeftVisible(self)
    local nValue = SettingSystemNew:Get(SettingKeyDef.LocalKeys.FIRE_BY_LEFT_HAND)
    if nValue == SETTING_CLOSE then
        self.pWidgetRef.btnFireLeft:SetVisibility(ESlateVisibility.Collapsed)
    elseif nValue == SETTING_AIMOPEN then
        self.pWidgetRef.btnFireLeft:SetVisibility(BattleShipWeaponSystem:GetIsInAim_C() and ESlateVisibility.Visible or ESlateVisibility.Collapsed)
    else
        self.pWidgetRef.btnFireLeft:SetVisibility(self.pWidgetRef.btnFireRight:GetVisibility())
    end
end

-----------------------------------------------------------------------
-- 开火相关逻辑(这块逻辑之后还会整理，大体思路是将开火状态同步到DS，由DS来开火)
-----------------------------------------------------------------------
local function ClearFireTimer(self)
    if self.TimerHelper then
        self.TimerHelper:ClearTimer(self.FiredTimer)
    end
    self.FiredTimer = nil
end

-- 任意一个开火按钮/按键按下时都会触发这个
local function OnPressedBtnFire(self)
    if not self.bBtnFirePressed then
        self.bBtnFirePressed = true
        local ActiveWeaponItem = BattleShipWeaponSystem:GetActiveWeaponItem_C()
        if ActiveWeaponItem and ActiveWeaponItem:GetTemplate().bAllowRepeatFiring then
            self.FiredTimer = self.TimerHelper:NewTimer(function()
                BattleShipWeaponSystem:RequestFire(ShipFiringOperationDef.START)
            end, REQUEST_FIRE_INTERVAL, true)
        end
        BattleShipWeaponSystem:RequestFire(ShipFiringOperationDef.START)
    end
end

-- 所有开火按钮/按键松开时执行这个
local function OnReleasedBtnFire(self)
    if self.bBtnFirePressed then
        self.bBtnFirePressed = false
        ClearFireTimer(self)
        BattleShipWeaponSystem:RequestFire(ShipFiringOperationDef.END)
    end
end

-- 点击取消开火的时候执行
local function OnClickedBtnCancelFire(self)
    if self.bBtnFirePressed then
        self.bBtnFirePressed = false
        ClearFireTimer(self)
        BattleShipWeaponSystem:RequestFire(ShipFiringOperationDef.CANCEL)
    end
end

-- 是否有任意开火按钮按下
local function IsAnyFiringButtonPressed(self)
    for _,bPressed in pairs(self.tbFiringButtonState) do
        if bPressed then
            return true
        end
    end
    return false
end

-- 开火按钮状态改变
local function OnFiringButtonStateChange(self, szKey, bPressed)
    self.tbFiringButtonState[szKey] = bPressed
    if IsAnyFiringButtonPressed(self) then
        OnPressedBtnFire(self)
    else
        OnReleasedBtnFire(self)
    end
end

-- 清楚所有开火按钮的状态
local function ClearFiringButtonState(self)
    if IsAnyFiringButtonPressed(self) then
        OnReleasedBtnFire(self)
    end
    self.tbFiringButtonState = {}
end

-----------------------------------------------------------------------
-- 装弹相关逻辑
-----------------------------------------------------------------------
local function OnCpgbLoadAnimationFinished(self)
    LOG("OnCpgbLoadAnimationFinished")
    local pWidgetRef = self.pWidgetRef
    pWidgetRef.btnLoad:SetVisibility(ESlateVisibility.Visible)
    pWidgetRef.cpgbLoad:SetVisibility(ESlateVisibility.Collapsed)
    pWidgetRef.cpgbLoad:StopAnimation()
    pWidgetRef.txtLoadingTime:StopTimer()
    pWidgetRef.txtLoadingTime:SetVisibility(ESlateVisibility.Collapsed)
    self.EventHelper:FireEvent(ClientEventDef.EV_SHIP_WEAPON_LOAD_FINISH)
end

local function OnCpgbLoadAnimationStart(self, nLoadingTime, nLoadingStartTime)
    LOG("OnCpgbLoadAnimationStart", nLoadingTime, nLoadingStartTime)
    local nRemainLoadingTime = MathUtil.Clamp(nLoadingStartTime + nLoadingTime - getseconds(), 0, nLoadingTime)
    if (nLoadingTime > 0) and (nRemainLoadingTime > 0) then
        local nRemainPercent = 1 - MathUtil.Clamp(nRemainLoadingTime / nLoadingTime, 0, 1)
        local pWidgetRef = self.pWidgetRef
        pWidgetRef.btnLoad:SetVisibility(ESlateVisibility.Collapsed)
        pWidgetRef.cpgbLoad:SetVisibility(ESlateVisibility.HitTestInvisible)
        pWidgetRef.cpgbLoad:StartAnimation(nRemainPercent, 1, nRemainLoadingTime)
        pWidgetRef.txtLoadingTime:StartTimer(nRemainLoadingTime , BULLET_RELOAD_INTERVAL, TIMEFORMAT, EMinTimeUnit.Second)
        pWidgetRef.txtLoadingTime:SetVisibility(ESlateVisibility.HitTestInvisible)
    end
end

local function OnShipWeaponBulletLoadEnded(self, tbCharacter, WeaponItem)
    if GamePlayerSelfHelper:IsNotPlayerSelf(tbCharacter) then
        return
    end
    local nWeaponSlot = WeaponItem:GetWeaponSlot()
    LOG("OnShipWeaponBulletLoadEnded", nWeaponSlot)
    local pbShipWeaponSlot = self.tbShipWeaponSlot[nWeaponSlot]
    if pbShipWeaponSlot then
        pbShipWeaponSlot:OnShipWeaponBulletLoadEnded()
    end

    SoundManager:PlaySoundEffect(UIResourceDef.SC_SHIP_WEAPON_LOAD)

    -- 装弹按钮只显示激活武器CD
    if IsActiveWeaponItem(WeaponItem) then
        OnCpgbLoadAnimationFinished(self)
    end
end

local function OnShipWeaponBulletLoadBegan(self, tbCharacter, WeaponItem, nLoadingTime, nLoadingStartTime)
    if GamePlayerSelfHelper:IsNotPlayerSelf(tbCharacter) then
        return
    end
    local nWeaponSlot = WeaponItem:GetWeaponSlot()
    LOG("OnShipWeaponBulletLoadBegan", nWeaponSlot, nLoadingTime, nLoadingStartTime)
    local pbShipWeaponSlot = self.tbShipWeaponSlot[nWeaponSlot]
    if pbShipWeaponSlot then
        pbShipWeaponSlot:OnShipWeaponBulletLoadBegan(nLoadingTime, nLoadingStartTime)
    end

    -- 装弹按钮只显示激活武器CD
    if IsActiveWeaponItem(WeaponItem) then
        OnCpgbLoadAnimationStart(self, nLoadingTime, nLoadingStartTime)
    end
end

local function OnClickedBtnLoad(self)
    BattleShipWeaponSystem:RequestLoadBullet()
end

-----------------------------------------------------------------------
-- 武器激活相关逻辑
-----------------------------------------------------------------------
local function ToggleWeaponSlotActiveState(nWeaponSlot)
    local WeaponItem = BattleShipWeaponSystem:GetEquippedWeaponItem_C(nWeaponSlot)
    if WeaponItem then
        local ActiveWeaponItem = BattleShipWeaponSystem:GetActiveWeaponItem_C()
        if WeaponItem == ActiveWeaponItem then
            BattleShipWeaponSystem:RequestActivateWeaponItem()
        else
            BattleShipWeaponSystem:RequestActivateWeaponItem(WeaponItem)
        end
    end
end

local function OnShipWeaponEquipped(self, tbCharacter, nSlot, WeaponItem)
    if GamePlayerSelfHelper:IsNotPlayerSelf(tbCharacter) or (nSlot == ShipWeaponSlotDef.THROW) then
        return
    end
    LOG("OnShipWeaponEquipped", nSlot, WeaponItem and WeaponItem:GetTemplateId())
    local pbWeaponSlot = self.tbShipWeaponSlot[nSlot]
    if pbWeaponSlot then
        pbWeaponSlot:SetWeaponItem(WeaponItem)
    end
    if WeaponItem:IsInBulletLoading() then
        local nLoadingTime = WeaponItem:GetBulletLoadingTime()
        local nLoadingStartTime = WeaponItem:GetBulletLoadingStartTime()
        OnShipWeaponBulletLoadBegan(self, tbCharacter, WeaponItem, nLoadingTime, nLoadingStartTime)
    end
end

local function OnShipWeaponUnequipped(self, tbCharacter, nSlot, WeaponItem)
    if GamePlayerSelfHelper:IsNotPlayerSelf(tbCharacter) or (nSlot == ShipWeaponSlotDef.THROW) then
        return
    end
    LOG("OnShipWeaponUnequipped", nSlot, WeaponItem and WeaponItem:GetTemplateId())
    local pbWeaponSlot = self.tbShipWeaponSlot[nSlot]
    if pbWeaponSlot then
        pbWeaponSlot:SetWeaponItem(nil)
    end
end

local function OnShipActiveWeaponItemChanged(self, tbCharacter, NewActiveWeaponItem, OldActiveWeaponItem)
    if GamePlayerSelfHelper:IsNotPlayerSelf(tbCharacter) then
        return
    end
    if (not NewActiveWeaponItem) and (not OldActiveWeaponItem) then
        LOG("OnShipActiveWeaponItemChanged nil, nil")
        for _, pbWeaponSlot in pairs(self.tbShipWeaponSlot) do
            pbWeaponSlot:SetActive(false)
        end
    else
        local nOldActiveSlot = OldActiveWeaponItem and OldActiveWeaponItem:GetWeaponSlot()
        local nNewActiveSlot = NewActiveWeaponItem and NewActiveWeaponItem:GetWeaponSlot()
        LOG("OnShipActiveWeaponItemChanged", nOldActiveSlot, nNewActiveSlot)
        local pbLastWeaponSlot = self.tbShipWeaponSlot[nOldActiveSlot]
        if pbLastWeaponSlot then
            pbLastWeaponSlot:SetActive(false)
        end
        local pbActiveWeaponSlot = self.tbShipWeaponSlot[nNewActiveSlot]
        if pbActiveWeaponSlot then
            pbActiveWeaponSlot:SetActive(true)
        end
    end
    if NewActiveWeaponItem then
        self.pWidgetRef.btnFireRight:SetVisibility(ESlateVisibility.Visible)
        -- Cannon才有准心和装填
        if NewActiveWeaponItem:GetCategory() == BattleItemCategoryDef.SHIP_WEAPON then
            self.pbShipWeaponCannon:SetVisible(true)
            self.pWidgetRef.ovlLoad:SetVisibility(ESlateVisibility.Visible)

            -- 刷新装填进度
            if NewActiveWeaponItem:IsInBulletLoading() then
                local nLoadingTime = NewActiveWeaponItem:GetBulletLoadingTime()
                local nLoadingStartTime = NewActiveWeaponItem:GetBulletLoadingStartTime()
                OnCpgbLoadAnimationStart(self, nLoadingTime, nLoadingStartTime)
            else
                OnCpgbLoadAnimationFinished(self)
            end

            local nSubCategory = NewActiveWeaponItem:GetSubCategory()
            local tbTemplate = ShipWeaponCategoryDataTable:GetTemplate(nSubCategory)
            UpdateBtnFireRes(self, tbTemplate.szFireNormalRes, tbTemplate.szFirePressedRes)
        else
            self.pbShipWeaponCannon:SetVisible(false)
            self.pWidgetRef.ovlLoad:SetVisibility(ESlateVisibility.Collapsed)

            local tbTemplate = NewActiveWeaponItem:GetTemplate()
            UpdateBtnFireRes(self, tbTemplate.szFireNormalRes, tbTemplate.szFirePressedRes)
        end
    else
        OnCpgbLoadAnimationFinished(self)
        self.pbShipWeaponCannon:SetVisible(false)
        self.pWidgetRef.ovlLoad:SetVisibility(ESlateVisibility.Collapsed)
        self.pWidgetRef.btnFireRight:SetVisibility(ESlateVisibility.Collapsed)
    end
    UpdateBtnFireLeftVisible(self)
end

-----------------------------------------------------------------------
-- 舰船UI状态恢复相关逻辑
-----------------------------------------------------------------------
-- 恢复武器的已装备状态
local function RestoreEquipWeapon(self)
    local tbPlayer = GamePlayerSelfHelper:Get()
    for nSlot=ShipWeaponSlotDef.COMMON_START, ShipWeaponSlotDef.COMMON_END do
        local WeaponItem = BattleShipWeaponSystem:GetEquippedWeaponItem_C(nSlot)
        if WeaponItem then
            OnShipWeaponEquipped(self, tbPlayer, nSlot, WeaponItem)
        else
            OnShipWeaponUnequipped(self, tbPlayer, nSlot, nil)
        end
    end
end

-- 恢复当前激活的武器
local function RestoreActiveWeapon(self)
    local nActiveSlot = BattleShipWeaponSystem:GetActiveWeaponSlot_C()
    LOG("RestoreActiveWeapon nActiveSlot =", nActiveSlot)
    for nSlot, pbWeaponSlot in pairs(self.tbShipWeaponSlot) do
        pbWeaponSlot:SetActive(nActiveSlot == nSlot)
    end
end

-----------------------------------------------------------------------
-- 图标资源异步加载逻辑
-----------------------------------------------------------------------
-- 标记资源异步加载状态
local function MarkResAsyncLoadStatus(self, szRes, pObject, nHandle, bLoaded)
    local tbStatus = self.tbFireResLoadingStatus[szRes]
    if tbStatus then
        tbStatus.pObject = tbStatus.pObject or pObject
        tbStatus.bLoaded = tbStatus.bLoaded or bLoaded -- nHandle不会变，此处设置or bLoaded，是为了防止直接加载完成了之后才返回的nHandle
    else
        self.tbFireResLoadingStatus[szRes] = {
            nHandle = nHandle,
            pObject = pObject,
            bLoaded = bLoaded
        }
    end
end

-- 异步加载开火按钮资源(准星一起异步加载了)
local function AsyncLoadFireButtonRes(self)
    LOG("[AsyncLoad] start async load")
    local OnAsyncLoadFinished = function(szRes, pObject, nHandle)
        LOG("[AsyncLoad] load finished", szRes)
        MarkResAsyncLoadStatus(self, szRes, pObject, nHandle, true)
    end
    local AsyncLoad = function(szRes)
        if not self.tbFireResLoadingStatus[szRes] then
            LOG("[AsyncLoad] load", szRes)
            local nHandle = ResourceManager:LoadAsync(szRes, OnAsyncLoadFinished, true)
            MarkResAsyncLoadStatus(self, szRes, nil, nHandle, false)
        end
    end
    self.tbFireResLoadingStatus = {}
    local tbCategoryTemplates = ShipWeaponCategoryDataTable:GetTemplates()
    for _, tbTemplate in pairs(tbCategoryTemplates) do
        AsyncLoad(tbTemplate.szFireNormalRes)
        AsyncLoad(tbTemplate.szFirePressedRes)
        AsyncLoad(tbTemplate.szCrosshairsRes)
    end
    local tbThrownItemTemplates = BattleItemDataTable:GetTemplatesByCategory(BattleItemCategoryDef.SHIP_THROWN_ITEM)
    for _,tbTemplate in pairs(tbThrownItemTemplates) do
        AsyncLoad(tbTemplate.szFireNormalRes)
        AsyncLoad(tbTemplate.szFirePressedRes)
    end
end

-- 取消异步加载的资源，并进行释放
local function CancelAsyncLoadFireButtonRes(self)
    LOG("[AsyncLoad] start cancel async load")
    for szRes, tbStatus in pairs(self.tbFireResLoadingStatus) do
        if tbStatus.bLoaded then
            LOG("[AsyncLoad] unhold", szRes)
            ResourceManager:Unhold(tbStatus.pObject)
        else
            LOG("[AsyncLoad] cancel load", szRes)
            ResourceManager:CancelLoadAsync(tbStatus.nHandle)
        end
    end
    self.tbFireResLoadingStatus = nil
end

-----------------------------------------------------------------------
-- 其他local逻辑处理
-----------------------------------------------------------------------
-- 初始化需要透传触摸事件的UI控件
local function InitTouchInputUserWidget(self)
    local tbWnd = UIManager:GetWnd(UIDef.UI_FFA_MAIN)
    if tbWnd then
        self.pWidgetRef.chkPostureReef:SetTouchInputUserWidget(tbWnd.pWidgetRef)
        self.pWidgetRef.chkPostureHalfSail:SetTouchInputUserWidget(tbWnd.pWidgetRef)
        self.pWidgetRef.btnLoad:SetTouchInputUserWidget(tbWnd.pWidgetRef)
        self.pWidgetRef.btnFireRight:SetTouchInputUserWidget(tbWnd.pWidgetRef)
    end
end

-- 初始化武器槽位UI
local function InitWeaponSlot(self)
    self.tbShipWeaponSlot = {}
    for i=ShipWeaponSlotDef.COMMON_START, ShipWeaponSlotDef.COMMON_END do
        self.tbShipWeaponSlot[i] = self.PrefabHelper:BindPrefab(self.pWidgetRef[SHIP_WEAPON_SLOT_NAME..i])
        self.tbShipWeaponSlot[i]:Init(i)
        self.tbShipWeaponSlot[i]:SetActive(false)
    end
end

local function BindEventInternal(self)
    local EventHelper = self.EventHelper
    EventHelper:RegisterEvent(ClientEventDef.EV_ON_SHIP_WEAPON_EQUIPPED_CLIENT          , self, OnShipWeaponEquipped)
    EventHelper:RegisterEvent(ClientEventDef.EV_ON_SHIP_WEAPON_UNEQUIPPED_CLIENT        , self, OnShipWeaponUnequipped)
    EventHelper:RegisterEvent(ClientEventDef.EV_ON_SHIP_WEAPON_BULLET_LOAD_BEGAN_CLIENT , self, OnShipWeaponBulletLoadBegan)
    EventHelper:RegisterEvent(ClientEventDef.EV_ON_SHIP_WEAPON_BULLET_LOAD_ENDED_CLIENT , self, OnShipWeaponBulletLoadEnded)
    EventHelper:RegisterEvent(ClientEventDef.EV_SETTING_LEFT_HAND_FIRE                  , self, UpdateBtnFireLeftVisible)
    EventHelper:RegisterEvent(CommonEventDef.EV_ON_SHIP_AIM_STATE_CHANGED               , self, UpdateBtnFireLeftVisible)
    EventHelper:RegisterEvent(CommonEventDef.EV_ON_SHIP_ACTIVE_WEAPON_ITEM_CHANGED      , self, OnShipActiveWeaponItemChanged)
    EventHelper:RegisterEvent(ClientEventDef.EV_RELEASE_FIGHT_BTN                       , self, function() OnFiringButtonStateChange(self, "RightButton"  , false) end)

    EventHelper:RegisterCppDelegate(self.pWidgetRef.btnLoad.OnClicked                   , self, OnClickedBtnLoad)
    EventHelper:RegisterCppDelegate(self.pWidgetRef.btnCancelFire.OnClicked             , self, OnClickedBtnCancelFire)
    EventHelper:RegisterCppDelegate(self.pWidgetRef.cpgbLoad.OnAnimationFinished        , self, OnCpgbLoadAnimationFinished)

    EventHelper:RegisterCppDelegateFunc(self.pWidgetRef.btnFireLeft.OnPressed           , function() OnFiringButtonStateChange(self, "LeftButton"   , true) end)
    EventHelper:RegisterCppDelegateFunc(self.pWidgetRef.btnFireLeft.OnReleased          , function() OnFiringButtonStateChange(self, "LeftButton"   , false) end)
    EventHelper:RegisterCppDelegateFunc(self.pWidgetRef.btnFireRight.OnPressed          , function() OnFiringButtonStateChange(self, "RightButton"  , true) end)
    EventHelper:RegisterCppDelegateFunc(self.pWidgetRef.btnFireRight.OnReleased         , function() OnFiringButtonStateChange(self, "RightButton"  , false) end)

    EventHelper:RegisterHandle(InputHandle:BindKeyPressed (EInputKey.LeftMouseButton    , function() OnFiringButtonStateChange(self, "LeftMouse", true) end))
    EventHelper:RegisterHandle(InputHandle:BindKeyReleased(EInputKey.LeftMouseButton    , function() OnFiringButtonStateChange(self, "LeftMouse", false) end))
    EventHelper:RegisterHandle(InputHandle:BindKeyPressed (EInputKey.F                  , function() OnFiringButtonStateChange(self, "KeyF", true) end))
    EventHelper:RegisterHandle(InputHandle:BindKeyReleased(EInputKey.F                  , function() OnFiringButtonStateChange(self, "KeyF", false) end))
    EventHelper:RegisterHandle(InputHandle:BindKeyPressed (EInputKey.One                , function() ToggleWeaponSlotActiveState(ShipWeaponSlotDef.HEAD) end))
    EventHelper:RegisterHandle(InputHandle:BindKeyPressed (EInputKey.Two                , function() ToggleWeaponSlotActiveState(ShipWeaponSlotDef.SIDE) end))
    EventHelper:RegisterHandle(InputHandle:BindKeyPressed (EInputKey.Three              , function() ToggleWeaponSlotActiveState(ShipWeaponSlotDef.DECK) end))
    EventHelper:RegisterHandle(InputHandle:BindKeyPressed (EInputKey.Four               , function() ToggleWeaponSlotActiveState(ShipWeaponSlotDef.THROW) end))
    EventHelper:RegisterHandle(InputHandle:BindKeyPressed (EInputKey.C                  , OnClickedBtnCancelFire, self))
end

function ULShipWeaponPanel:OnLoad()
    self.tbFiringButtonState = {}
    self.pWidgetRef.txtLoadingTime:SetPrecision(TIMER_TEXT_PRECISION)
    self.pWidgetRef.txtLoadingTime:SetDetailMode(TIMER_TEXT_DETAIL_MODE)
    self.pbShipWeaponCannon = self.PrefabHelper:BindPrefab(self.pWidgetRef.pbShipWeaponCannon)

    InitTouchInputUserWidget(self)
    InitWeaponSlot(self)
    AsyncLoadFireButtonRes(self)
end

function ULShipWeaponPanel:OnUnload()
    CancelAsyncLoadFireButtonRes(self)
end

function ULShipWeaponPanel:OnExit()
    self:Deactivate()
end

function ULShipWeaponPanel:Activate()
    LOG("Activate")
    BindEventInternal(self)
    RestoreEquipWeapon(self)
    RestoreActiveWeapon(self)
    UpdateBtnFireLeftVisible(self)
end

function ULShipWeaponPanel:Deactivate()
    LOG("Deactivate")
    ClearFireTimer(self)
    self.EventHelper:UnregisterAll()
    ClearFiringButtonState(self)
end

return ULShipWeaponPanel