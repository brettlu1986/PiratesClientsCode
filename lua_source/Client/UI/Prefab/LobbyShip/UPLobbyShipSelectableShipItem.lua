-----------------------------------------------------
--File Name    : UPLobbyShipSelectableShipItem.lua
--Author       : chenyixin
--Description  : 舰船船体界面舰船列表Item
-----------------------------------------------------
local luaclass = require("luaclass")
local ListItemBase = require("ListItemBase")
local UPLobbyShipSelectableShipItem = luaclass("UPLobbyShipSelectableShipItem", ListItemBase)

local ItemSystem = require("ItemSystem")
local L10N = require("L10N")
local UISetUtils = require("UISetUtils")
local ItemResDataTable = require("ItemResDataTable")
local UITextDef = require("UITextDef")
local ItemCategoryDef = require("ItemCategoryDef")
-- local LobbyShipDef = require("LobbyShipDef")
local UIResourceDef = require("UIResourceDef")
local ClientEventDef = require("ClientEventDef")

-- local SelectableItemRes = LobbyShipDef.SelectableItemRes
-- local UNSELECTED_NAME_COLOR = LinearColor{R = 0, G = 0, B = 0, A = 0.6}
-- local SELECTED_NAME_COLOR = LinearColor{R = 1, G = 1, B = 1, A = 0.6}
local SKIN_BACKGROUND = UIResourceDef.LOBBY_SHIP_GRADE_BACKGROUND
local ORIGIN_BACKGROUND_INDEX = -1

UPLobbyShipSelectableShipItem.bSelectable = true

local function OnSelectItem(self)
    if self:IsSelected() then
        return 
    end
    -- if self.bSelectable then
        self:SelectItem()
    -- else
        -- if self.ListHelper.OnSelectedChangedDelegate then
            -- self.ListHelper.OnSelectedChangedDelegate:Fire(self.nIndex)
        -- end
    -- end
end

-- local function OnClickedDetail(self)
--     local tbExtraDatas = self.ListHelper.tbExtraDatas
--     if tbExtraDatas.nPreviewIndex and tbExtraDatas.nPreviewIndex == self.nIndex then
--         tbExtraDatas.nPreviewIndex = nil
--         if tbExtraDatas.fnOnBtnDetailUnchecked then
--             tbExtraDatas.fnOnBtnDetailUnchecked(self)
--         end
--     else
--         local nLastPreviewIndex = tbExtraDatas.nPreviewIndex
--         tbExtraDatas.nPreviewIndex = self.nIndex
--         if nLastPreviewIndex then
--             self.ListHelper:RefreshItemByIndex(nLastPreviewIndex)
--         end
--         if tbExtraDatas.fnOnBtnDetailClicked then
--             tbExtraDatas.fnOnBtnDetailClicked(self)
--         end
--     end
--     self.ListHelper:RefreshItemByIndex(self.nIndex)
-- end

local function OnExpirationTimeEnd(self)
    if self.ListHelper.tbExtraDatas.fnOnExpirationTimeEnd then
        self.ListHelper.tbExtraDatas.fnOnExpirationTimeEnd(self)
    end
end

-- local function SetBtnDetailChecked(self)
--     local pWidgetRef = self.pWidgetRef
--     if self.ListHelper.tbExtraDatas.nPreviewIndex and self.ListHelper.tbExtraDatas.nPreviewIndex == self.nIndex then
--         pWidgetRef.btnDetail.WidgetStyle.Normal.DrawAs = ESlateBrushDrawType.Image
--         pWidgetRef.btnDetail.WidgetStyle.Hovered.DrawAs = ESlateBrushDrawType.Image
--     else
--         pWidgetRef.btnDetail.WidgetStyle.Normal.DrawAs = ESlateBrushDrawType.NoDrawType
--         pWidgetRef.btnDetail.WidgetStyle.Hovered.DrawAs = ESlateBrushDrawType.NoDrawType
--     end
-- end

local function OnBtnEquipClicked(self)
    local OwnerSub = self.ListHelper.tbExtraDatas.OwnerSub
    if not OwnerSub then
        logerror("Can not find OwnerSub")
        return
    end

    local nShipSlotIndex = self.ListHelper.Owner:GetCurentSelectedShipSlotIndex()
    local nShipItemId = self.ListHelper:GetSelectedData().nId

    OwnerSub:GetShipPreparationComponent():RequestEquipShip(nShipSlotIndex, nShipItemId)
end

local function SetSelectState(self, bSelect)
    local pWidgetRef = self.pWidgetRef
    -- 设置选中背景
    if bSelect then
        pWidgetRef.KMCheckBox_0:SetCheckedState(ECheckBoxState.Checked)
        -- pWidgetRef.btnDetail:SetVisibility(ESlateVisibility.Collapsed)
        -- pWidgetRef.bdrName:SetBrushColor(SELECTED_NAME_COLOR)
        -- pWidgetRef.txtShipName:SetColorAndOpacity(UIResourceDef.COLOR.BLACK.SLATE_COLOR)
    else
        pWidgetRef.KMCheckBox_0:SetCheckedState(ECheckBoxState.Unchecked)
        -- pWidgetRef.btnDetail:SetVisibility(ESlateVisibility.Visible)
        -- pWidgetRef.bdrName:SetBrushColor(UNSELECTED_NAME_COLOR)
        -- pWidgetRef.txtShipName:SetColorAndOpacity(UIResourceDef.COLOR.WHITE.SLATE_COLOR)
    end
end

-- local function CheckResumePreviewData(self, nPreviewItemId, nCurrentItemId)
--     if not nPreviewItemId then
--         return 
--     end
--     if not self.ListHelper.tbExtraDatas.nPreviewIndex then
--         if nPreviewItemId == nCurrentItemId then
--             self.ListHelper.tbExtraDatas.OwnerSub:ClearResumeData()
--             OnClickedDetail(self)
--         end
--     end
-- end

local function SetSkinItem(self, tbData)
    local pWidgetRef = self.pWidgetRef
    local nShipSkinItemId = tbData.nId
    local nShipItemId = tbData.nShipItemId
    local OwnerSub = self.ListHelper.tbExtraDatas.OwnerSub
    local ShipPreparationComponent = OwnerSub:GetShipPreparationComponent()
    local nGrade = tbData.nGrade

    -- 设置皮肤图片
    local tbItemRes = ItemResDataTable:GetTemplate(tbData.nResId)
    local szImgPath = tbItemRes.szIconPath
    if szImgPath then
        UISetUtils.SetImageBrushRes(pWidgetRef.imgIcon, szImgPath:load())
    end

    -- 设置皮肤名字
    local tbShipSkinTemplate = ItemSystem:GetItemTemplate(nShipSkinItemId)
    pWidgetRef.txtSkinName:SetVisibility(ESlateVisibility.Visible)
    pWidgetRef.txtSkinName:SetText(tbShipSkinTemplate.l10nPrefixName)
    pWidgetRef.txtSkinName:SetColorAndOpacity(KMUMGLibrary.GetSlateColorFromHex(L10N:ToString(UITextDef.ITEM_GRADE_COLOR_TEXT[tbShipSkinTemplate.nGrade])))

    -- 设置舰船名字
    local tbShipTemplate = ItemSystem:GetItemTemplate(nShipItemId)
    pWidgetRef.txtShipName:SetText(tbShipTemplate.l10nName)

    -- 设置选中背景
    SetSelectState(self, self:IsSelected())

    -- 设置锁定状态
    pWidgetRef.imgNew:SetVisibility(ESlateVisibility.Collapsed)
    if ShipPreparationComponent:IsItemUnlocked(nShipSkinItemId) or OwnerSub:IsSourceTypeDefaultOwned(tbData.nSourceType) then
        -- self.bSelectable = true
        pWidgetRef.imgLocked:SetVisibility(ESlateVisibility.Collapsed)
        pWidgetRef.imgIcon:SetIsEnabled(true)
        pWidgetRef.imgBgLeft:SetIsEnabled(true)
        pWidgetRef.imgBgRight:SetIsEnabled(true)
        if ShipPreparationComponent:IsNewShipItem(nShipSkinItemId) then
            pWidgetRef.imgNew:SetVisibility(ESlateVisibility.Visible)
        end
    else
        -- self.bSelectable = false
        pWidgetRef.imgLocked:SetVisibility(ESlateVisibility.HitTestInvisible)
        pWidgetRef.imgIcon:SetIsEnabled(false)
        pWidgetRef.imgBgLeft:SetIsEnabled(false)
        pWidgetRef.imgBgRight:SetIsEnabled(false)

        nGrade = ORIGIN_BACKGROUND_INDEX    -- 未解锁的皮肤背景不显示等级
    end

    local nExpirationTime = ShipPreparationComponent:GetItemExpirationTime(nShipSkinItemId)
    local bExperienced = nExpirationTime ~= ShipPreparationComponent.PERMANENT_ITEM_TIME
    if bExperienced and (nExpirationTime > 0) then
        pWidgetRef.txtExpirationTime:StartTimer(nExpirationTime, 1, UITextDef.TIMER_TEXT_BLOCK_FORMAT_FULL, EMinTimeUnit.Second)
        pWidgetRef.hboxExpirationTime:SetVisibility(ESlateVisibility.HitTestInvisible)
    else
        pWidgetRef.txtExpirationTime:StopTimer()
        pWidgetRef.hboxExpirationTime:SetVisibility(ESlateVisibility.Collapsed)
    end

    -- 设置装配状态
    local bCurrent = OwnerSub:GetShipPreparationComponent():IsEquippedShipSkin(nShipItemId, nShipSkinItemId) 
    if bCurrent then
        pWidgetRef.txtCurrent:SetVisibility(ESlateVisibility.Visible)
    else
        pWidgetRef.txtCurrent:SetVisibility(ESlateVisibility.Hidden)
    end

    -- 设置等级背景
    local pImgRes = SKIN_BACKGROUND[nGrade]:load()
    UISetUtils.SetImageBrushRes(pWidgetRef.imgBgLeft, pImgRes)
    UISetUtils.SetImageBrushRes(pWidgetRef.imgBgRight, pImgRes)

    pWidgetRef.btnEquip:SetVisibility(ESlateVisibility.Collapsed)
    pWidgetRef.imgGlow01:SetVisibility(ESlateVisibility.Collapsed)

    -- 设置详情图标
    -- UISetUtils.SetImageBrushRes(pWidgetRef.imgDetail, SelectableItemRes.Preview:load())
    -- SetBtnDetailChecked(self)
    
    -- if OwnerSub.tbRestoreContext then
    --     CheckResumePreviewData(self, OwnerSub.tbRestoreContext.tbDisplayItemInfo.nPreviewSkinId, nShipSkinItemId)
    -- end
end

local function SetShipItem(self, tbData)
    local pWidgetRef = self.pWidgetRef
    local ShipPreparationComponent = self.ListHelper.tbExtraDatas.OwnerSub:GetShipPreparationComponent()

    pWidgetRef.txtSkinName:SetVisibility(ESlateVisibility.Collapsed)
    pWidgetRef.imgLocked:SetVisibility(ESlateVisibility.Collapsed)
    pWidgetRef.imgNew:SetVisibility(ESlateVisibility.Collapsed)
    pWidgetRef.txtShipName:SetText(tbData.l10nName)

    local nShipItemId = tbData.nId
    local nSkinItemId = ShipPreparationComponent:GetEquippedShipSkinId(nShipItemId)
    nSkinItemId = nSkinItemId and nSkinItemId or nShipItemId
    local tbItemRes = ItemSystem:GetItemResTemplate(nSkinItemId)
    local szPosterPath = tbItemRes.szIconPath
    UISetUtils.SetImageBrushRes(self.pWidgetRef.imgIcon, szPosterPath:load())
    pWidgetRef.imgIcon:SetIsEnabled(true)

    local nExpirationTime = ShipPreparationComponent:GetItemExpirationTime(tbData.nId)
    if nExpirationTime > 0 then
        pWidgetRef.txtExpirationTime:StartTimer(nExpirationTime, 1, UITextDef.TIMER_TEXT_BLOCK_FORMAT_FULL, EMinTimeUnit.Second)
        pWidgetRef.hboxExpirationTime:SetVisibility(ESlateVisibility.HitTestInvisible)
    else
        pWidgetRef.txtExpirationTime:StopTimer()
        pWidgetRef.hboxExpirationTime:SetVisibility(ESlateVisibility.Collapsed)
    end

    -- 设置选中背景
    local bSelected = self:IsSelected()
    SetSelectState(self, bSelected)
    
    if bSelected and not ShipPreparationComponent:IsEquippedShip(nShipItemId) then
        pWidgetRef.btnEquip:SetVisibility(ESlateVisibility.Visible)
        pWidgetRef.imgGlow01:SetVisibility(ESlateVisibility.HitTestInvisible)
    else
        pWidgetRef.btnEquip:SetVisibility(ESlateVisibility.Collapsed)
        pWidgetRef.imgGlow01:SetVisibility(ESlateVisibility.Collapsed)
    end

    local bCurrent = ShipPreparationComponent:IsEquippedShip(nShipItemId)
    if bCurrent then
        pWidgetRef.txtCurrent:SetVisibility(ESlateVisibility.Visible)
    else
        pWidgetRef.txtCurrent:SetVisibility(ESlateVisibility.Hidden)
    end

    -- 还原等级背景
    local pImgRes = SKIN_BACKGROUND[ORIGIN_BACKGROUND_INDEX]:load()
    UISetUtils.SetImageBrushRes(pWidgetRef.imgBgLeft, pImgRes)
    UISetUtils.SetImageBrushRes(pWidgetRef.imgBgRight, pImgRes)
    pWidgetRef.imgBgLeft:SetIsEnabled(true)
    pWidgetRef.imgBgRight:SetIsEnabled(true)

    -- 设置预览图标
    -- pWidgetRef.btnDetail:SetVisibility(ESlateVisibility.Visible)
    -- UISetUtils.SetImageBrushRes(pWidgetRef.imgDetail, SelectableItemRes.Detail:load())
    -- SetBtnDetailChecked(self)
    -- self.bSelectable = true
end

local function OnCheckStateChanged(self, bChecked)
    local pCheckedState = bChecked and ECheckBoxState.Unchecked or ECheckBoxState.Checked
    self.pWidgetRef.KMCheckBox_0:SetCheckedState(pCheckedState)
end

local function OnReceiveEquipShipResult(self, nSlotId, nTemplateId)
    local pWidgetRef = self.pWidgetRef
    if not (pWidgetRef and pWidgetRef:IsVisible()) then
        return
    end
    if pWidgetRef.txtCurrent:GetVisibility() ~= ESlateVisibility.Visible then
        return 
    end
    self:OnRefresh(self.tbData)
end

function UPLobbyShipSelectableShipItem:OnRefresh(tbData)
    local nCategory = self.ListHelper.tbExtraDatas.nCategory
    if nCategory == ItemCategoryDef.SHIP then
        SetShipItem(self, tbData)
    elseif nCategory == ItemCategoryDef.SHIP_SKIN then
        SetSkinItem(self, tbData)
    end
end

function UPLobbyShipSelectableShipItem:OnBindEvent(EventHelper)
    local pWidgetRef = self.pWidgetRef
    EventHelper:RegisterCppDelegate(pWidgetRef.KMButton_0.OnClicked, self, OnSelectItem)
    -- EventHelper:RegisterCppDelegate(pWidgetRef.btnDetail.OnClicked, self, OnClickedDetail)
    EventHelper:RegisterCppDelegate(pWidgetRef.txtExpirationTime.OnCompleteTimer, self, OnExpirationTimeEnd)
    EventHelper:RegisterCppDelegate(pWidgetRef.btnEquip.OnClicked, self, OnBtnEquipClicked)
    EventHelper:RegisterCppDelegate(pWidgetRef.KMCheckBox_0.OnCheckStateChanged, self, OnCheckStateChanged)

    EventHelper:RegisterEvent(ClientEventDef.EV_ON_RECEIVE_EQUIP_SHIP_RESULT, self, OnReceiveEquipShipResult)
end

return UPLobbyShipSelectableShipItem