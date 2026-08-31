-----------------------------------------------------
--File Name    : UILobbyShipHull.lua
--Author       : chenyixin
--Description  : 舰船船体
-----------------------------------------------------
local luaclass = require("luaclass")
local UILobbyShipBase = require("UILobbyShipBase")
local UILobbyShipHull = luaclass("UILobbyShipHull", UILobbyShipBase)

local SelfVerticalListHelper = require("SelfVerticalListHelper")
local ItemSystem = require("ItemSystem")
local ShopSystem = require("ShopSystem")
local UISetUtils = require("UISetUtils")
local L10N = require("L10N")
local UIUtils = require("UIUtils")

local ItemCategoryDef = require("ItemCategoryDef")
local ClientEventDef = require("ClientEventDef")
local ShipSlotDataTable = require("ShipSlotDataTable")
local CostCurrencyHelper = require("CostCurrencyHelper")
local CurrencyIni = require("CurrencyIni")

UILobbyShipHull.OwnerSub = nil
UILobbyShipHull.ListHelper = nil
UILobbyShipHull.tbSelectedEquippedItem = nil
UILobbyShipHull.tbEquippedItems = {}

UILobbyShipHull.tbDelayTimer = nil

UILobbyShipHull.bIsDrag = false
UILobbyShipHull.nLastPosX = 0

UILobbyShipHull.pbWindowFrame = nil
UILobbyShipHull.ulLobbyShipBuy = nil

UILobbyShipHull.tbResumeData = {}
UILobbyShipHull.ShipListAnimPlayMode = nil

UILobbyShipHull.nCurrentDisplayIndex = nil

--[[
    self.self.tbCurrentDisplayData = {} 
    {
        nIndex,         -- 当前选中的船位
        nShipItemId,    -- 当前选中的船Id
        nSkinItemId,    -- 当前选中的皮肤Id, 为nil时列表为船列表
        nDetailMode,    -- 属性详情面板展开状态, 0关闭, 1基本信息, 2详细信息
    }
]]

local ZERO_VECTOR2D = Vector2D{X = 0, Y = 0}
local SHIP_SHOP_ID = 1
-- local WND_KEY = "Hull"
local DEFAULT_INDEX = 1
local SHIP_SLOT_COUNT = 4

local UNEXCHANGED_ID = CurrencyIni.tbExchange.nUnchangedId

local function UpdateShipDisplay(self, nShipItemId)
    if not self.OwnerSub then
        logerror("Can not find OwnerSub")
        return
    end
    if not self.tbSelectedEquippedItem then
        return 
    end
    local OwnerSub = self.OwnerSub
    local nIndex = self.tbSelectedEquippedItem.nIndex
    if nShipItemId then
        local tbTemplate = ItemSystem:GetItemTemplate(nShipItemId)
        local nBattleItemId = tbTemplate.nBattleItemId
        local ShipPreparationComponent = OwnerSub:GetShipPreparationComponent()
        nShipItemId = ShipPreparationComponent:GetEquippedShipSkinId(nShipItemId)
    
        local tbModify = OwnerSub:GetShipModelModifyByKey("Hull", nShipItemId)
        OwnerSub:CreateShipActorById(nShipItemId, nIndex, tbModify)
        self:SetShipBattleId(nBattleItemId)
    else
        OwnerSub:DestroyShipActorByIndex(nIndex)
        self:SetShipBattleId()
    end
    local nViewBlendTime = self.nViewBlendTime
    if not self.nCurrentDisplayIndex or self.nCurrentDisplayIndex == nIndex then
        nViewBlendTime = nil
    end
    OwnerSub:ShowShipDisplayScene(true, nIndex, nViewBlendTime)
    self.nCurrentDisplayIndex = nIndex
end

local function UpdateShipSkinDisplay(self, nSkinItemId)
    if not self.OwnerSub then
        logerror("Can not find OwnerSub")
        return
    end
    if not self.tbSelectedEquippedItem then
        return 
    end
    local OwnerSub = self.OwnerSub

    local tbModify = self.OwnerSub:GetShipModelModifyByKey("Hull", nSkinItemId)
    OwnerSub:CreateShipActorById(nSkinItemId, self.tbSelectedEquippedItem.nIndex, tbModify)
end

local function GetDefaultSlotIndex(self)
    local tbEquippedShipIds = self.OwnerSub.tbEquippedShipIds
    local nIndex = DEFAULT_INDEX
    for i, nId in pairs(tbEquippedShipIds) do
        if nId > 0 then
            nIndex = i
            break
        end
    end
    return nIndex
end

local function GetResumeData(self)
    local tbOpenArgs = self.tbOpenArgs
    local tbDisplayItemInfo = self.OwnerSub.tbRestoreContext and self.OwnerSub.tbRestoreContext.tbDisplayItemInfo
    self.OwnerSub:ClearResumeData()

    if tbDisplayItemInfo then
        self.tbResumeData = tbDisplayItemInfo
    elseif tbOpenArgs.nShipTemplateId then
        if tbOpenArgs.nIndex then
            self.tbResumeData.nIndex = tbOpenArgs.nIndex
        else
            self.tbResumeData.nIndex = GetDefaultSlotIndex(self)
        end
        self.tbResumeData.nShipItemId = tbOpenArgs.nShipTemplateId
        if tbOpenArgs.nShipSkinTemplateId then
            self.tbResumeData.nSkinItemId = tbOpenArgs.nShipSkinTemplateId
        end
    end
    return self.tbResumeData
end

----------------- widget设置 ----------------------------------------------------

-- local function SetListWidgetVisible(self, bVisible, bWithCheck)
--     if bVisible then
--         if not bWithCheck or self.bShowShipList then
--             self.pWidgetRef.KMVerticalList_0:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
--             self.bShowShipList = true
--         end
--     else
--         if not bWithCheck or not self.bShowShipList then
--             self.pWidgetRef.KMVerticalList_0:SetVisibility(ESlateVisibility.Collapsed)
--             self.bShowShipList = false
--             self.ulLobbyShipBuy:Update()
--         end
--     end
-- end

local function SetShipListData(self)
    local ShipPreparationComponent = self.OwnerSub:GetShipPreparationComponent()
    local tbShipList = ShipPreparationComponent:GetUnequippedShipTemplates()
    local nCurrentShipItemId = self.tbSelectedEquippedItem.nShipItemId
    if nCurrentShipItemId and nCurrentShipItemId > 0 then
        local tbCurrentShipTemplate = ItemSystem:GetItemTemplate(nCurrentShipItemId)
        if tbCurrentShipTemplate then
            table.insert(tbShipList, 1, tbCurrentShipTemplate)
        end
    end
    if #tbShipList > 0 then
        self.ListHelper.tbExtraDatas.nCategory = ItemCategoryDef.SHIP
        self.ListHelper.tbExtraDatas.nPreviewIndex = nil
        self.ListHelper:SetData(tbShipList, true)
    end
    return #tbShipList
end

local function SetShipSkinListData(self)
    local nShipItemId = self.tbSelectedEquippedItem.nShipItemId
    local ShipPreparationComponent = self.OwnerSub:GetShipPreparationComponent()
    local tbDatas = ShipPreparationComponent:GetSortedShipSkinTemplatesByShipId(nShipItemId)
    local nSelectedIndex = nil
    for i, tbTemplate in pairs(tbDatas) do
        if tbTemplate.nShipItemId == nShipItemId then
            if ShipPreparationComponent:IsEquippedShipSkin(nShipItemId, tbTemplate.nId) then
                nSelectedIndex = i
            end
        end
    end
    self.ListHelper.tbExtraDatas.nCategory = ItemCategoryDef.SHIP_SKIN
    self.ListHelper:SetData(tbDatas, true)
    if nSelectedIndex then
        self.ListHelper:SetSelectedIndex(nSelectedIndex)
    end
end

local function OnSelectEmptySlot(self)
    if not self.OwnerSub then
        logerror("Can not find OwnerSub")
        return
    end
    local OwnerSub = self.OwnerSub

    local nIndex = self.tbSelectedEquippedItem.nIndex
    OwnerSub:DestroyShipActorByIndex(nIndex)
    OwnerSub:ShowShipDisplayScene(true, nIndex, self.nViewBlendTime)
end

local function RefreshAllEquippedItemsDisplay(self)
    if not self.tbEquippedItems then
        return
    end
    for _, tbEquippedItem in pairs(self.tbEquippedItems) do
        tbEquippedItem:RefreshDisplay()
    end 
end

local function SetShowShipList(self, bShow, bWithAnim, fnCallback)
    local pWidgetRef = self.pWidgetRef
    local SetVisibility = function()
        local pVisibility = bShow and ESlateVisibility.SelfHitTestInvisible or ESlateVisibility.Collapsed
        pWidgetRef.KMVerticalList_0:SetVisibility(pVisibility)
        pWidgetRef.vboxDetailContent:SetVisibility(pVisibility)
    end

    if not bShow then
        pWidgetRef.vboxDetailContent:SetVisibility(ESlateVisibility.Collapsed)
    end

    if bWithAnim then
        if bShow then
            SetVisibility()
        end
        local pPlayMode = bShow and EUMGSequencePlayMode.Forward or EUMGSequencePlayMode.Reverse
        if pPlayMode == self.ShipListAnimPlayMode then
            return
        end
        self:StopAnimation("anim_LobbyShipHullShipList")
        self.ShipListAnimPlayMode = pPlayMode
        self:PlayAnimation("anim_LobbyShipHullShipList", 0, 1, pPlayMode, 1, function()
            self.ShipListAnimPlayMode = nil
            SetVisibility()
            if fnCallback then
                fnCallback()
            end
        end)
    else
        SetVisibility()
        if fnCallback then
            fnCallback()
        end
    end
end

local function SetShowSkinList(self, bShow, bWithAnim, fnCallback)
    local pWidgetRef = self.pWidgetRef

    -- 动画前设的
    if bShow then
        pWidgetRef.KMVerticalList_0:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
    else
        pWidgetRef.vboxList:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
    end

    -- 动画后设的
    local SetVisibility = function()
        if bShow then
            pWidgetRef.vboxList:SetVisibility(ESlateVisibility.Collapsed)
            pWidgetRef.VboxDetailContent:SetVisibility(ESlateVisibility.Collapsed)
            pWidgetRef.KMVerticalList_0:SetRenderTranslation(ZERO_VECTOR2D)
            pWidgetRef.KMVerticalList_0:SetRenderOpacity(1)
        else
            pWidgetRef.KMVerticalList_0:SetVisibility(ESlateVisibility.Collapsed)
            pWidgetRef.VboxDetailContent:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
            pWidgetRef.vboxList:SetRenderTranslation(ZERO_VECTOR2D)
            pWidgetRef.vboxList:SetRenderOpacity(1)
            pWidgetRef.bdrChangedEffects:SetVisibility(ESlateVisibility.Collapsed)
        end
    end

    if bWithAnim then
        self:StopAnimation("anim_LobbyShipHullShipList")
        self.ShipListAnimPlayMode = nil
        local pPlayMode = bShow and EUMGSequencePlayMode.Forward or EUMGSequencePlayMode.Reverse
        self:PlayAnimation("anim_LobbyShipHullShipList", 0, 1, pPlayMode, 1, function()
            SetVisibility()
            if fnCallback then
                fnCallback()
            end
        end)
    else
        SetVisibility()
        if fnCallback then
            fnCallback()
        end
    end
end

local function SwitchToSkinList(self, bShowSkinList)
    local pPlayMode = bShowSkinList and EUMGSequencePlayMode.Reverse or EUMGSequencePlayMode.Forward
    self:StopAnimation("anim_ListOut")
    self:PlayAnimation("anim_ListOut", 0, 1, pPlayMode, 1)
end

local function ShowWnd(self, bWithAnim)
    local pWidgetRef = self.pWidgetRef
    pWidgetRef.bdrChangedEffects:SetVisibility(ESlateVisibility.Collapsed)
    pWidgetRef.vboxDetailContent:SetVisibility(ESlateVisibility.Collapsed)
    pWidgetRef.vboxList:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
    pWidgetRef.vboxList:SetRenderTranslation(ZERO_VECTOR2D)
    pWidgetRef.vboxList:SetRenderOpacity(1)
    local SetVisibility = function()
    end
    
    if bWithAnim then
        self:StopAnimation("anim_LobbyShipHullIn")
        self:PlayAnimation("anim_LobbyShipHullIn", 0, 1, EUMGSequencePlayMode.Forward, 1, SetVisibility)
    else
        SetVisibility()
    end

    SetShowShipList(self, false, false)
end

local function SelectListItemById(self, nItemId)
    local tbShipDatas = self.ListHelper:GetData()
    for i, tbTemplate in pairs(tbShipDatas) do
        if tbTemplate.nId == nItemId then
            self.ListHelper:SetSelectedIndex(i)
            return i
        end
    end
    return nil
end

-----------------------------
-- Requests
-----------------------------
local function DoRequestUnlockShipSlot(self, nCurrencyId, nPrice, nSlotId)
    local ShipPreparationComponent = self.OwnerSub:GetShipPreparationComponent()

    local firstRequest = function ()
        ShipPreparationComponent:RequestUnlockShipSlot(nSlotId, false)
    end

    local secondRequest = nil
    if nCurrencyId == UNEXCHANGED_ID then
        secondRequest = function ()
            ShipPreparationComponent:RequestUnlockShipSlot(nSlotId, true)
        end
    end
    CostCurrencyHelper:SetData(nCurrencyId, nPrice, firstRequest, secondRequest, UISetUtils.GetL10NTextByKey("RETURN_CODE_MONEY_IS_NOT_ENOUGH_UNLOCK_SHIP_SLOT"))
    CostCurrencyHelper:FirstRequest()
end

local function RequestUnlockShipSlot(self, tbEquippedItem)
    local nIndex = tbEquippedItem.nIndex
    local tbSlotTemplate = ShipSlotDataTable:GetTemplate(nIndex)
    local nPrice = tbSlotTemplate.nPrice
    local l10nTitle = UISetUtils.GetL10NTextByKey("LOBBY_SHIP_UNLOCK_SLOT_DILOG_TITLE")
    local l10nMessage = UISetUtils.GetL10NTextByKey("LOBBY_SHIP_UNLOCK_SLOT_DILOG_MESSAGE")
    l10nMessage = L10N:Format(l10nMessage, nPrice)
    UIUtils.ShowChoiceDialog(l10nTitle, l10nMessage,
    function()
        self.tbSelectedEquippedItem:SetCheckedState(true)
        tbEquippedItem:SetCheckedState(false)
        DoRequestUnlockShipSlot(self, tbSlotTemplate.nCurrencyId, nPrice, tbEquippedItem.nIndex)
    end,
    function()
        self.tbSelectedEquippedItem:SetCheckedState(true)
        tbEquippedItem:SetCheckedState(false)
    end
    )
end

-----------------------------
-- widget事件们
-----------------------------

local function OnItemTabChecked(self, tbEquippedItem)
    local tbLastEquippedItem = self.tbSelectedEquippedItem
    self.tbSelectedEquippedItem = tbEquippedItem
    local nIndex = tbEquippedItem.nIndex
    self:SetCurrentDisplayData("nIndex", nIndex)
    self.tbResumeData.nIndex = nil
    local bHideListAnim = true
    local tbSelectedData = self.ListHelper:GetSelectedData()
    if (not tbSelectedData) or tbSelectedData and tbSelectedData.nId == tbEquippedItem.nShipItemId then
        bHideListAnim = false
    end
    if not self.tbResumeData.nShipItemId then
        self.ListHelper:UnselectCurrentItem()
    end

    if tbLastEquippedItem then
        tbLastEquippedItem:RefreshDisplay()
    end

    if tbEquippedItem:IsUnlocked() then
        if tbEquippedItem:IsEquipped() then
            self.pWidgetRef.btnSkin:SetIsEnabled(true)
            -- UpdateShipDisplay(self, tbEquippedItem.nShipItemId)
        else
            OnSelectEmptySlot(self)
            local tbShipList = self.OwnerSub:GetShipPreparationComponent():GetUnequippedShipTemplates()
            if (not tbShipList) or (#tbShipList == 0) then
                tbEquippedItem:SetNoEquipableShip()
            end
        end
    else
        self.tbSelectedEquippedItem = tbLastEquippedItem
        RequestUnlockShipSlot(self, tbEquippedItem)
    end

    if not self.tbResumeData.nIndex then
        self:SetDetailVisible(false, true)
    end

    if self.tbResumeData.nSkinItemId then
        return
    end

    SetShowShipList(self, false, bHideListAnim, function()
        if not tbEquippedItem:IsUnlocked() then
            return 
        end
        if SetShipListData(self) > 0 then
            local bWithAnim = self.tbCurrentDisplayData.nShipItemId == nil
            SetShowShipList(self, true, bWithAnim)
            self.ListHelper:ScrollToTop(true)
            if self.tbResumeData.nShipItemId then
                return
            end
            if not SelectListItemById(self, tbEquippedItem.nShipItemId) then
                self.ListHelper:SetSelectedIndex(DEFAULT_INDEX)
            end
        elseif self.tbCurrentDisplayData.nShipItemId then
            SetShowShipList(self, false, true)
        -- else
            -- if tbLastEquippedItem then
            --     tbLastEquippedItem:RefreshDisplay()
            -- end
            -- tbEquippedItem:SetNoEquipableShip()
        end
    end)
end

local function OnItemTabCheckStateChanged(self, tbEquippedItem)
    if self.tbSelectedEquippedItem then
        if self.tbSelectedEquippedItem.nIndex == tbEquippedItem.nIndex then
            tbEquippedItem:SetCheckedState(true, true)
            return
        end
        self.tbSelectedEquippedItem:SetCheckedState(false)
    end

    tbEquippedItem:SetCheckedState(true)
end

local function OnItemBtnDeleteEquipmentClicked(self, tbEquippedItem)
    local nShipSlotId = tbEquippedItem.nIndex
    self.OwnerSub:GetShipPreparationComponent():RequestUnequipShip(nShipSlotId)
end

local function OnBuyClicked(self, tbEquippedItem)
    ShopSystem:OpenShop(SHIP_SHOP_ID)
    UIUtils.BottomMenuUnselectAll()
end

local function OnBtnBackClicked(self)
    if not self.OwnerSub then
        return
    end
    if self:IsAnimationPlaying("anim_LobbyShipHullShipList") then
        return 
    end

    if self.tbCurrentDisplayData.nSkinItemId then
        self.ListHelper:UnselectCurrentItem()
        self.OwnerSub:ShowShipDisplayScene(true, self.tbCurrentDisplayData.nIndex, self.nViewBlendTime)
        SwitchToSkinList(self, true)
        SetShowSkinList(self, false, true, function()
            if SetShipListData(self) > 0 then
                SetShowShipList(self, true, true)
                if not SelectListItemById(self, self.tbCurrentDisplayData.nSkinItemId) then
                    self.ListHelper:SetSelectedIndex(DEFAULT_INDEX)
                end
            end
        end)
    else
        self.OwnerSub:Return(self:GetWndName())
    end
end

local function OnShipListSelectedChanged(self, nIndex)
    if not self:IsVisible() then
        return
    end
    local tbSelectedData = self.ListHelper:GetSelectedData()
    local nShipItemId = tbSelectedData and tbSelectedData.nId
    self:SetCurrentDisplayData("nShipItemId", nShipItemId)
    self.tbResumeData.nShipItemId = nil
    self.pWidgetRef.btnSkin:SetIsEnabled(self.OwnerSub:GetShipPreparationComponent():IsEquippedShip(nShipItemId))
    UpdateShipDisplay(self, nShipItemId)
end

local function OnSkinListSelectedChanged(self, nIndex)
    if not self:IsVisible() then
        return
    end
    self.ListHelper:RequestListRefresh()
    local tbSelectedData = self.ListHelper:GetSelectedData()
    local nSkinItemId = tbSelectedData and tbSelectedData.nId
    self:SetCurrentDisplayData("nSkinItemId", nSkinItemId)
    self.tbResumeData.nSkinItemId = nil
    UpdateShipSkinDisplay(self, nSkinItemId)
    self:SetSkinChangedEffectData(tbSelectedData)
    if tbSelectedData then
        self.OwnerSub:RequestEquipShipSkin(tbSelectedData)
    end
    local ShipPreparationComponent = self.OwnerSub:GetShipPreparationComponent()
    if ShipPreparationComponent:IsNewShipItem(nSkinItemId) then
        ShipPreparationComponent:UnmarkNewShipItem(nSkinItemId)
    end
end

local function OnListSelectedChanged(self, nIndex)
    if not self:IsVisible() then
        return
    end
    local nCategory = self.ListHelper.tbExtraDatas.nCategory

    if nCategory == ItemCategoryDef.SHIP then
        OnShipListSelectedChanged(self, nIndex)
        -- RequestEquipShip(self)
    elseif nCategory == ItemCategoryDef.SHIP_SKIN then
        OnSkinListSelectedChanged(self, nIndex)
    end

    self.ulLobbyShipBuy:Update(self.ListHelper:GetSelectedData())
end

local function OnSelectableShipItemExpirationEnd(self, pbItem)
    if not self:IsVisible() then
        return
    end
    local nCategory = self.ListHelper.tbExtraDatas.nCategory
    if nCategory == ItemCategoryDef.SHIP then
        if SetShipListData(self) > 0 then
            if not SelectListItemById(self, self.tbSelectedEquippedItem.nShipItemId) then
                self.ListHelper:SetSelectedIndex(DEFAULT_INDEX)
            end
        elseif self.tbCurrentDisplayData.nShipItemId then
            SetShowShipList(self, false, true)
        else    
            self.tbSelectedEquippedItem:SetNoEquipableShip()
        end
    elseif nCategory == ItemCategoryDef.SHIP_SKIN then
        SetShipSkinListData(self)
    end
end

local function OnBtnSkinClicked(self)
    local pWidgetRef = self.pWidgetRef
    self.OwnerSub:ShowShipDisplayScene(true, self.tbCurrentDisplayData.nIndex + SHIP_SLOT_COUNT, self.nViewBlendTime)
    pWidgetRef.vBoxList:SetVisibility(ESlateVisibility.HitTestInvisible)
    SwitchToSkinList(self, false)
    SetShowShipList(self, false, true)
    self.TimerHelper:NewDelayRunTimer(function()
        SetShipSkinListData(self)
        SetShowSkinList(self, true, true)
        self:SetDetailVisible(false, false)
    end, 0.5)
end

local function OnBtnSkinDisableClicked(self)
    UIUtils.ShowToast(UISetUtils.GetL10NTextByKey("LOBBY_SHIP_NOT_EQUIPPED"))
end

local function OnMouseButtonDown(self, pGeometry, pMouseEvent)
    self.bIsDrag = true
    self.nLastPosX = KismetInputLibrary.PointerEvent_GetScreenSpacePosition(pMouseEvent).X
    return WidgetBlueprintLibrary.Handled()
end

local function OnMouseMove(self, pGeometry, pMouseEvent)
    if self.bIsDrag then
        local nCurrentPosX = KismetInputLibrary.PointerEvent_GetScreenSpacePosition(pMouseEvent).X
        self.OwnerSub:RotateActorByIndex(self.tbSelectedEquippedItem.nIndex, nCurrentPosX - self.nLastPosX)
        self.nLastPosX = nCurrentPosX
    end
    return WidgetBlueprintLibrary.Handled()
end

local function OnMouseButtonUp(self, pGeometry, pMouseEvent)
    self.bIsDrag = false
    return WidgetBlueprintLibrary.Handled()
end

local function SelectEquippedItemByIndex(self, nIndex)
    if not nIndex or nIndex <= 0 then
        return 
    end
    OnItemTabCheckStateChanged(self, self.tbEquippedItems[nIndex])
end

-----------------------------
-- OnReceiveResults
-----------------------------

local function OnShopNotEnoughCurrency(self, bAutoExchange)
    if not bAutoExchange then
        CostCurrencyHelper:FirstCostFailed()
    else
        CostCurrencyHelper:SecondCostFailed()
    end
end

local function OnReceiveUnlockShipSlotResult(self, nSlotId)
    local tbUnlockedEquippedItem = self.tbEquippedItems[nSlotId]
    self.tbSelectedEquippedItem:SetCheckedState(false)
    self.tbSelectedEquippedItem = tbUnlockedEquippedItem
    self.tbSelectedEquippedItem:SetEmpty()
    self:SetShipBattleId()
    OnItemTabChecked(self, tbUnlockedEquippedItem)
    self.OwnerSub:LoadShipEquipmentInfo()
    tbUnlockedEquippedItem:SetCheckedState(true)
end

local function OnReceiveUnequipShipResult(self, nSlotId)
    self.tbSelectedEquippedItem:SetEmpty()
    RefreshAllEquippedItemsDisplay(self)
    self.OwnerSub:DestroyShipActorByIndex(nSlotId)
    self:SetShipBattleId()
    OnItemTabChecked(self, self.tbSelectedEquippedItem)
    self.OwnerSub:LoadShipEquipmentInfo()

    self.EventHelper:FireEvent(ClientEventDef.EV_ON_REFRESH_SHIP_TIP_ICON)
end

local function OnAddItem(self, Item)
    SetShipListData(self)
end

local function OnReceiveEquipShipResult(self, nSlotId, nTemplateId)
    if not nSlotId == self.tbSelectedEquippedItem.nIndex then
        return
    end
    self.tbSelectedEquippedItem:SetShipInfoByItemId(nTemplateId)
    self.tbSelectedEquippedItem:OnShipEquipped()
    RefreshAllEquippedItemsDisplay(self)        -- 刷一遍红点

    -- if SetShipListData(self) > 0 then
    --     if not SelectListItemById(self, nTemplateId) then
    --         self.ListHelper:SetSelectedIndex(DEFAULT_INDEX)
    --     end
    -- end
    self.ListHelper:SetSelectedIndex(self.ListHelper:GetSelectedIndex())
    self.OwnerSub:LoadShipEquipmentInfo()

    local ShipPreparationComponent = self.OwnerSub:GetShipPreparationComponent()
    if ShipPreparationComponent:IsNewShipItem(nTemplateId) then
        ShipPreparationComponent:UnmarkNewShipItem(nTemplateId)
    else
        self.EventHelper:FireEvent(ClientEventDef.EV_ON_REFRESH_SHIP_TIP_ICON)
    end
end


local function OnReceiveShipSkinChanged(self, nShipItemId)
    if nShipItemId ~= self.tbSelectedEquippedItem.nShipItemId then
        return
    end

    -- UpdateShipDisplay(self, nShipItemId)
    -- SetShowList(self, false)
    self.ListHelper:SetSelectedIndex(self.ListHelper:GetSelectedIndex())
    self.tbSelectedEquippedItem:OnSkinChanged()
end


----------------- 初始化 ---------------------------------------------------------

local function InitEquipment(self)
    if not self.OwnerSub then
        return
    end
    local tbEquippedShipIds = self.OwnerSub.tbEquippedShipIds
    if not tbEquippedShipIds then
        return
    end

    for nIndex, nId in pairs(tbEquippedShipIds) do
        local tbShipEquippedItem = self.PrefabHelper:BindPrefab(self.pWidgetRef["pbLobbyshipTab0"..nIndex])
        tbShipEquippedItem:SetShipInfoByItemId(nId)
        tbShipEquippedItem.nIndex = nIndex
        tbShipEquippedItem:BindCallbacks(
            function (tbEquippedItem)
                OnItemTabCheckStateChanged(self, tbEquippedItem)
            end,
            function (tbEquippedItem)
                OnItemBtnDeleteEquipmentClicked(self, tbEquippedItem)
            end,
            function (tbEquippedItem)
                OnBuyClicked(self, tbEquippedItem)
            end,
            function (tbEquippedItem)
                OnItemTabChecked(self, tbEquippedItem)
            end
        )
    self.tbEquippedItems[nIndex] = tbShipEquippedItem
    end

end

local function InitShipList(self)
    self.ListHelper = SelfVerticalListHelper()
    self.ListHelper:Init(self, self.pWidgetRef.KMVerticalList_0)
    self.ListHelper.OnSelectedChangedDelegate:Bind(OnListSelectedChanged, self)
    self.ListHelper.tbExtraDatas.fnOnExpirationTimeEnd = function(pbItem)
        OnSelectableShipItemExpirationEnd(self, pbItem)
    end

    self.ListHelper.tbExtraDatas.OwnerSub = self.OwnerSub
    self.ListHelper:SetAutoScrollEnabled(false)
end

----------------- overrides ---------------------------------------------------

function UILobbyShipHull:OnLoad()
    UILobbyShipHull.super.OnLoad(self)
    self.pbWindowFrame:SetBackDelegate(OnBtnBackClicked, self)

    self.ulLobbyShipBuy = self.UILogicHelper:CreateUILogic("ULLobbyShipBuy")
    self:SetShowDetailAnim("anim_LobbyShipHullShipDetail")

    InitEquipment(self)
    InitShipList(self)
end

function UILobbyShipHull:OnUnload()
    if self.ListHelper then
        self.ListHelper:Uninit()
        self.ListHelper = nil
    end
end

function UILobbyShipHull:OnExit()
    UILobbyShipHull.super.OnExit(self)
    ShowWnd(self, false)
    self.tbSelectedEquippedItem:SetCheckedState(false)
    self.tbSelectedEquippedItem = nil
    self:SetDetailVisible(false, false)
    self.tbCurrentDisplayData = {}
    self.ShipListAnimPlayMode = nil
    self.ListHelper:UnselectCurrentItem()
    self.TimerHelper:ClearAllTimer()
    self.nCurrentDisplayIndex = nil
end

function UILobbyShipHull:OnShow()
    local tbResumeData = GetResumeData(self)
    self.ulLobbyShipBuy:Update()
    
    RefreshAllEquippedItemsDisplay(self)

    if tbResumeData.nIndex then
        SelectEquippedItemByIndex(self, tbResumeData.nIndex)
    else
        SelectEquippedItemByIndex(self, GetDefaultSlotIndex(self))
    end

    local nCameraIndex = self.tbCurrentDisplayData.nIndex
    if not tbResumeData.nSkinItemId then
        if tbResumeData.nDetailMode and tbResumeData.nDetailMode > 0 then
            ShowWnd(self, false)
            self:SetDetailVisible(true, false)
        else
            self:SetDetailVisible(false, false)
            ShowWnd(self, true)
        end
    else
        SetShowSkinList(self, true, false)
        self:SetDetailVisible(false, false)
        if nCameraIndex then
            nCameraIndex = nCameraIndex + SHIP_SLOT_COUNT
        end
        -- ShowWnd(self, false)
    end
    SelectListItemById(self, tbResumeData.nSkinItemId and tbResumeData.nSkinItemId or tbResumeData.nShipItemId)

    self.OwnerSub:ShowShipDisplayScene(true, nCameraIndex)
end

function UILobbyShipHull:OnBindEvent(EventHelper)
    UILobbyShipHull.super.OnBindEvent(self, EventHelper)
    local pWidgetRef = self.pWidgetRef
    EventHelper:RegisterCppDelegate(pWidgetRef.btnSkin.OnClicked, self, OnBtnSkinClicked)
    EventHelper:RegisterCppDelegate(pWidgetRef.btnSkin.OnDisableClicked, self, OnBtnSkinDisableClicked)
    EventHelper:RegisterCppDelegate(pWidgetRef.bdrRotate.OnMouseButtonDownEvent, self, OnMouseButtonDown)
    EventHelper:RegisterCppDelegate(pWidgetRef.bdrRotate.OnMouseMoveEvent, self, OnMouseMove)
    EventHelper:RegisterCppDelegate(pWidgetRef.bdrRotate.OnMouseButtonUpEvent, self, OnMouseButtonUp)

    EventHelper:RegisterEvent(ClientEventDef.EV_ON_RECEIVE_EQUIP_SHIP_RESULT, self, OnReceiveEquipShipResult)
    EventHelper:RegisterEvent(ClientEventDef.EV_ON_RECEIVE_UNLOCK_SHIP_SLOT_RESULT, self, OnReceiveUnlockShipSlotResult)
    EventHelper:RegisterEvent(ClientEventDef.EV_ON_RECEIVE_SHIP_SKIN_CHANGED, self, OnReceiveShipSkinChanged)
    EventHelper:RegisterEvent(ClientEventDef.EV_ON_RECEIVE_UNEQUIP_SHIP_RESULT, self, OnReceiveUnequipShipResult)
    EventHelper:RegisterEvent(ClientEventDef.EV_ADD_LOBBY_ITEM, self, OnAddItem)
    EventHelper:RegisterEvent(ClientEventDef.EV_ON_RECEIVE_UNLOCK_SHIP_SLOT_NOT_ENOUGH_MONEY, self, OnShopNotEnoughCurrency)
    EventHelper:RegisterEvent(ClientEventDef.EV_SHOP_NOT_ENOUGH_CURRENCY, self, OnShopNotEnoughCurrency)

end

function UILobbyShipHull:GetCurentSelectedShipSlotIndex()
    return self.tbSelectedEquippedItem.nIndex
end

return UILobbyShipHull