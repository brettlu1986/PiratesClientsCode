-----------------------------------------------------
--File Name    : UILobbyShipWeapon.lua
--Author       : chenyixin
--Description  : 舰船武器界面
-----------------------------------------------------
local luaclass = require("luaclass")
local WndBase = require("WndBase")
local UILobbyShipWeapon = luaclass("UILobbyShipWeapon", WndBase)

local ShipWeaponCategoryDataTable = require("ShipWeaponCategoryDataTable")

-- local UIUtils = require("UIUtils")
-- local UISetUtils = require("UISetUtils")
local ClientEventDef = require("ClientEventDef")
local ItemDataTable = require("ItemDataTable")
local SelfVerticalListHelper = require("SelfVerticalListHelper")
local CostCurrencyHelper = require("CostCurrencyHelper")

UILobbyShipWeapon.OwnerSub = nil
UILobbyShipWeapon.tbTemplateData = nil  -- 武器分类相关数据

UILobbyShipWeapon.tbWeaponDetail = nil
UILobbyShipWeapon.nCurrentSelectedSlot = nil

UILobbyShipWeapon.nPreSelectedWeaponId = nil
UILobbyShipWeapon.nPreSelectedCategory = nil
UILobbyShipWeapon.pbWindowFrame = nil
UILobbyShipWeapon.ulLobbyShipBdrRotate = nil
UILobbyShipWeapon.ulLobbyShipBuy = nil

UILobbyShipWeapon.ListHelper = nil
UILobbyShipWeapon.tbSelectedWeaponItem = nil
UILobbyShipWeapon.tbResumeData = {}

local WEAPON_PLATFORM_TAG = "taizi"

-- 位置分类
local POSITION_CATEGORY_COUNT = 3
local POSITION_CATEGORY_NAME = "pbTabPosition"
UILobbyShipWeapon.nSelectedSlot = 1
UILobbyShipWeapon.tbSlots = {}

--[[
    GetWeaponDetailData: 生成UPLobbyShipWeaponDetail所需信息
    tbWeaponDetailData = {
        tbTemplate,     -- 当前武器的tbItemTemplate
        bUnlocked,      -- 当前武器是否已解锁
    }
]]
local function GetWeaponDetailData(tbTemplate, bUnlocked)
    return {
        tbTemplate = tbTemplate,
        bUnlocked = bUnlocked,
    }
end

--[[
    tbResumeData = {
        nSlot,      -- 当前选中的位置分类
        nWeaponId,      -- 当前选中的武器Id
    }
]]
local function SetResumeData(self)
    local tbResumeData = {
        nSlot = self.nSelectedSlot,
        nWeaponId = self.ListHelper.tbExtraDatas.nSelectedItemId,
    }
    -- logdebug("Set", t2s(tbResumeData))
    self.OwnerSub:UpdateDisplayItemInfo(tbResumeData)
end

local function GetSesumeData(self)
    local tbResumeData = self.OwnerSub.tbRestoreContext and self.OwnerSub.tbRestoreContext.tbDisplayItemInfo
    self.OwnerSub:ClearResumeData()
    if not tbResumeData then
        tbResumeData = {}
    end
    return tbResumeData
end

-----------------------------
-- widget 设置
-----------------------------

local function SetWeaponDetailData(self, tbWeaponDetail, tbWeapon, bUnlocked)
    if not tbWeaponDetail then
        logerror("[LobbyShip] UILobbyShipWeapon.SetWeaponDetailData tbWeaponDetail is nil.")
        return
    end

    local tbWeaponDetailData = GetWeaponDetailData(tbWeapon, bUnlocked)
    local OwnerSub = self.OwnerSub
    tbWeaponDetail:SetData(tbWeaponDetailData)
    OwnerSub:CreateWeaponActorById(tbWeapon.nId)
    self.ulLobbyShipBuy:Update(tbWeapon)
    self.ulLobbyShipBuy:UpdateActiveState(tbWeapon)
    local ShipPreparationComponent = OwnerSub:GetShipPreparationComponent()
    if ShipPreparationComponent:IsNewShipItem(tbWeapon.nId) then
        ShipPreparationComponent:UnmarkNewShipItem(tbWeapon.nId)
    end
end

local function RefreshSlotTabTips(self)
    local ShipPreparationComponent = self.OwnerSub:GetShipPreparationComponent()
    for nSlot, tbSlot in pairs(self.tbSlots) do
        tbSlot:SetShowTips(ShipPreparationComponent:CheckWeaponSlotHasNewWeapon(nSlot))
    end
end

-----------------------------
-- 事件们
-----------------------------
local function OnBtnBackClicked(self)
    if not self.OwnerSub then
        return
    end
    self.OwnerSub:Return(self:GetWndName())
end

-- UP_LobbyShipWeaponDetail切换武器按钮点击事件
local function OnUpdateWeaponDisplay(self, tbWeapon)

    local tbWeaponDetail = self.tbWeaponDetail
    local ShipPreparationComponent = self.OwnerSub:GetShipPreparationComponent()
    local bUnlocked = ShipPreparationComponent:IsItemUnlocked(tbWeapon.nId)
    SetWeaponDetailData(self, tbWeaponDetail, tbWeapon, bUnlocked)
end


local function OnWeaponSlotClicked(self, nSlot)
    local nLastPos = self.nSelectedSlot
    if nLastPos then
        self.tbSlots[nLastPos]:SetSelected(false)
    end
    if nSlot then
        self.tbSlots[nSlot]:SetSelected(true)
    end
    self.nSelectedSlot = nSlot

    local tbCategoryTemplates = self.tbTemplateData[nSlot]
    local nSelectedItemId = self.tbResumeData.nWeaponId
    self.tbResumeData.nWeaponId = nil
    if not nSelectedItemId then
        nSelectedItemId = self.OwnerSub:GetShipPreparationComponent():GetActiveWeaponId(tbCategoryTemplates[1].nCategory)
    end
    self.ListHelper.tbExtraDatas.nSelectedItemId = nSelectedItemId
    self.ListHelper:SetData(tbCategoryTemplates)
    SetResumeData(self)
end

local function OnWeaponSelectedChanged(self, tbWeaponItem)
    local tbTemplate = tbWeaponItem:GetWeaponTemplate()
    self.ListHelper.tbExtraDatas.nSelectedItemId = tbTemplate.nId
    OnUpdateWeaponDisplay(self, tbTemplate)

    SetResumeData(self)
end

local function OnWeaponClicked(self, tbWeaponItem)
    if self.tbSelectedWeaponItem then
        self.tbSelectedWeaponItem:UnselectItem()
    end
    tbWeaponItem:SelectItem()
    self.tbSelectedWeaponItem = tbWeaponItem
end

-- 收到武器启用结果
local function OnReceiveActivateWeaponResult(self, nPartCategory, nTemplateId)
    local tbWeapon = self.tbWeaponDetail:GetWeaponTemplate()
    if tbWeapon.nSubCategory == nPartCategory and tbWeapon.nId == nTemplateId then
        self.ulLobbyShipBuy:UpdateActiveState(tbWeapon)
        -- UIUtils.ShowToast(UISetUtils.GetL10NTextByKey("UI_STATIC_SHIP_WEAPON_ACTIVATED"))
    end
    self.ListHelper:RequestListRefresh()
end

local function OnRefreshShipTipIcon(self, bNew, nTemplateId)
    if bNew and nTemplateId and nTemplateId == self.tbWeaponDetail:GetDisplayWeaponId() and self:IsVisible() then
        local tbTemplate = ItemDataTable:GetTemplate(nTemplateId)
        self.ulLobbyShipBuy:Update(tbTemplate)
        self.ulLobbyShipBuy:UpdateActiveState(tbTemplate)
        self.OwnerSub:GetShipPreparationComponent():UnmarkNewShipItem(nTemplateId)
    end

    if self:IsVisible() then
        RefreshSlotTabTips(self)
        self.ListHelper:RequestListRefresh()
    end
end

-----------------------------
-- 初始化
-----------------------------
-- 初始化武器分类相关数据
local function InitWeaponData(self)
    local tbTemplateData = {}
    for _, tbTemplate in pairs(ShipWeaponCategoryDataTable:GetTemplates()) do
        local nWeaponSlot = tbTemplate.nWeaponSlot
        tbTemplateData[nWeaponSlot] = tbTemplateData[nWeaponSlot] or {}
        if tbTemplate.bDisplayOnLobby then
            table.insert(tbTemplateData[nWeaponSlot], tbTemplate)
        end
    end
    for i, v in ipairs(tbTemplateData) do
        table.sort(v, function(A, B) return A.nCategory < B.nCategory end)
    end
    self.tbTemplateData = tbTemplateData
end

local function InitWeaponDetail(self)
    local tbWeaponDetail = self.PrefabHelper:BindPrefab(self.pWidgetRef.pbLobbyShipWeaponDetail)
    self.tbWeaponDetail = tbWeaponDetail
end

local function InitWeaponSlot(self)
    local pWidgetRef = self.pWidgetRef
    for i = 1, POSITION_CATEGORY_COUNT do
        local tbSlotTab = self.PrefabHelper:BindPrefab(pWidgetRef[POSITION_CATEGORY_NAME..i], "UP_TabButtonLobbyShip")
        tbSlotTab:Init(i)
        self.tbSlots[i] = tbSlotTab
    end
end

local function BindWeaponSlotEvent(self, EventHelper)
    for _, tbSlotTab in pairs(self.tbSlots) do
        tbSlotTab:BindCallback(function(nSlot)
            OnWeaponSlotClicked(self, nSlot)
        end)
    end
end

local function OnShopNotEnoughCurrency(self, tbShoppingGoods)
    if not tbShoppingGoods.currency_auto_exchange then
        CostCurrencyHelper:FirstCostFailed()
    else
        CostCurrencyHelper:SecondCostFailed()
    end
end

-----------------------------
-- override
-----------------------------
function UILobbyShipWeapon:OnLoad()
    local tbOpenArgs = self.tbOpenArgs
    self.OwnerSub = tbOpenArgs.OwnerSub
    self.nPreSelectedWeaponId = tbOpenArgs.nItemTemplateId

    self.pbWindowFrame = self.PrefabHelper:BindPrefab(self.pWidgetRef.pbWindowFrame)
    self.pbWindowFrame:SetBackDelegate(OnBtnBackClicked, self)
    InitWeaponData(self)
    InitWeaponDetail(self)
    InitWeaponSlot(self)

    self.ListHelper = SelfVerticalListHelper()
    self.ListHelper:Init(self, self.pWidgetRef.vListSubCategory)
    self.ListHelper.tbExtraDatas.OwnerSub = self.OwnerSub
    self.ListHelper.tbExtraDatas.fnOnWeaponClicked = function (tbWeaponItem)
        OnWeaponClicked(self, tbWeaponItem)
    end
    self.ListHelper.tbExtraDatas.fnOnWeaponSelectedChanged = function (tbWeaponItem)
        OnWeaponSelectedChanged(self, tbWeaponItem)
    end

    self.ulLobbyShipBdrRotate = self.UILogicHelper:CreateUILogic("ULLobbyShipBdrRotate")
    self.ulLobbyShipBuy = self.UILogicHelper:CreateUILogic("ULLobbyShipBuy")
end

function UILobbyShipWeapon:OnUnload()
    if self.ListHelper then
        self.ListHelper:Uninit()
        self.ListHelper = nil
    end
end

function UILobbyShipWeapon:OnShow()
    self.OwnerSub:ShowShipDisplayScene(true)

    local pWidgetRef = self.pWidgetRef
    pWidgetRef.bdrUnlockCondition:SetVisibility(ESlateVisibility.Collapsed)
    self.tbResumeData = GetSesumeData(self)
    local nResumeSlot = self.tbResumeData and self.tbResumeData.nSlot
    local nSelectedSlot = nResumeSlot and nResumeSlot or 1
    OnWeaponSlotClicked(self, nSelectedSlot)
    self.tbResumeData.nSlot = nil

    local pPlatformActor = self.OwnerSub:GetSubLevelActorByTag(self:GetWndName(), WEAPON_PLATFORM_TAG)
    self.ulLobbyShipBdrRotate:SetRotateActor(pPlatformActor)

    RefreshSlotTabTips(self)

    self:PlayAnimation("anim_LobbyShipWeaponIn", 0, 1, EUMGSequencePlayMode.Forward, 1)
end

function UILobbyShipWeapon:OnHide()
    self.ulLobbyShipBdrRotate:ResetActorRotation()
    self.nCurrentSelectedSlot = nil
end

function UILobbyShipWeapon:OnBindEvent(EventHelper)
    EventHelper:RegisterEvent(ClientEventDef.EV_ON_RECEIVE_ACTIVATE_SHIP_WEAPON_RESULT, self, OnReceiveActivateWeaponResult)
    EventHelper:RegisterEvent(ClientEventDef.EV_ON_REFRESH_SHIP_TIP_ICON, self, OnRefreshShipTipIcon)
    EventHelper:RegisterEvent(ClientEventDef.EV_SHOP_NOT_ENOUGH_CURRENCY, self, OnShopNotEnoughCurrency)

    BindWeaponSlotEvent(self, EventHelper)
end

return UILobbyShipWeapon