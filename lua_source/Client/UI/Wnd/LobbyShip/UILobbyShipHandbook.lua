-----------------------------------------------------
--File Name    : UILobbyShipHandbook.lua
--Author       : chenyixin
--Description  : 舰船图鉴
-----------------------------------------------------
local luaclass = require("luaclass")
local UILobbyShipBase = require("UILobbyShipBase")
local UILobbyShipHandbook = luaclass("UILobbyShipHandbook", UILobbyShipBase)

local SelfVerticalListHelper = require("SelfVerticalListHelper")
local ClientEventDef = require("ClientEventDef")
local ItemCategoryDef = require("ItemCategoryDef")
local CostCurrencyHelper = require("CostCurrencyHelper")

local DEFAULT_SHIP_INDEX = 1
local NONE_INDEX = -1
local SHIP_WND_NAME = "Handbook"
local ZERO_VECTOR2D = Vector2D{X = 0, Y = 0}

UILobbyShipHandbook.ShipListHelper = nil
UILobbyShipHandbook.SkinListHelper = nil
UILobbyShipHandbook.tbShipTitle = nil

UILobbyShipHandbook.pbWindowFrame = nil
UILobbyShipHandbook.ulLobbyShipHandbook = nil
UILobbyShipHandbook.ulLobbyShipBuy = nil

--[[ 
    self.tbCurrentDisplayData = {} 
        {
            nShipItemId,    -- 当前选中的船Id
            nSkinItemId,    -- 当前选中的皮肤Id, 为nil时皮肤列表收起
            nDetailMode,    -- 属性详情面板展开状态, 0关闭, 1基本信息, 2详细信息
        }
-- ]]

local function LOG(...)
    log("[LobbyShip] UILobbyShipHandbook", ...)
end

local function GetSortedShipListData(self)
    local ShipPreparationComponent = self.OwnerSub:GetShipPreparationComponent()
    local tbShipTemplates = ShipPreparationComponent:GetShipTemplates()
    local tbSortedDatas = {}
    for _, tbShip in pairs(tbShipTemplates) do
        local tbData = self.ulLobbyShipHandbook:GetShipData(tbShip, ShipPreparationComponent)
        table.insert(tbSortedDatas, tbData)
    end

    table.sort(tbSortedDatas, function(A, B)
        --[[
            舰船列表排序方式为：优先按等级排序；
            同一等级下，先按是否拥有排序；
            再按大型船、中型船、小型船3类依次排序;
            再按nSortIndex排序
        ]]
        if A.nGrade ~= B.nGrade then
            return A.nGrade < B.nGrade
        end

        if A.nShipOwningState ~= B.nShipOwningState then
            return A.nShipOwningState < B.nShipOwningState
        end

        if A.nSubCategory ~= B.nSubCategory then
            return A.nSubCategory < B.nSubCategory
        end

        return A.nSortIndex < B.nSortIndex
    end)
    
    return tbSortedDatas
end

local function GetResumeData(self)
    local tbOpenArgs = self.tbOpenArgs
    local tbDisplayItemInfo = self.OwnerSub.tbRestoreContext and self.OwnerSub.tbRestoreContext.tbDisplayItemInfo
    self.OwnerSub:ClearResumeData()

    if tbDisplayItemInfo then
        self.tbCurrentDisplayData = tbDisplayItemInfo
    elseif tbOpenArgs.nShipTemplateId then
        self:SetCurrentDisplayData("nShipItemId", tbOpenArgs.nShipTemplateId)
        if tbOpenArgs.nShipSkinTemplateId then
            self:SetCurrentDisplayData("nSkinItemId", tbOpenArgs.nShipSkinTemplateId)
        end
    end
    
end

--------- Widget设置 ------------------------------------------------------------

local function UpdateShipSkinList(self)
    local tbShipData = self.ShipListHelper:GetSelectedData()
    local nShipItemId = tbShipData.nShipItemId
    local ShipPreparationComponent = self.OwnerSub:GetShipPreparationComponent()
    local tbDatas = ShipPreparationComponent:GetSortedShipSkinTemplatesByShipId(nShipItemId)


    self.SkinListHelper:SetData(tbDatas, true)
end

local function SelectSkinItemByIndex(self, nIndex, bScrollTo)
    if not nIndex then
        return nil
    end
    self.SkinListHelper:SetSelectedIndex(nIndex)
    if bScrollTo then
        self.SkinListHelper:ScrollToIndex(nIndex)
    end

    return self.SkinListHelper:GetSelectedData()
end

local function SelectSkinItemById(self, nSkinItemId)
    local tbDatas = self.SkinListHelper:GetData()
    local nShipItemId = self.tbCurrentDisplayData.nShipItemId
    if not nSkinItemId then
        nSkinItemId = self.tbCurrentDisplayData.nSkinItemId
    end
    
    local nIndex = nil
    local nDefaultOwnedIndex = nil
    local nEquippedIndex = nil
    for i, tbTemplate in pairs(tbDatas) do
        if nSkinItemId and nSkinItemId == tbTemplate.nId then
            nIndex = i
        end
        if self.OwnerSub:GetShipPreparationComponent():IsEquippedShipSkin(nShipItemId, tbTemplate.nId) then
            nEquippedIndex = i
        end
        if self.OwnerSub:IsSourceTypeDefaultOwned(tbTemplate.nSourceType) then
            nDefaultOwnedIndex = i
        end
    end

    -- 优先级: 输入Id > 穿着的 > 默认拥有的
    nIndex = nIndex and nIndex or (nEquippedIndex and nEquippedIndex or nDefaultOwnedIndex)
    SelectSkinItemByIndex(self, nIndex, true)

    return nIndex
end

local function SelectShipItemByIndex(self, nIndex, bScrollTo)
    if not nIndex then
        return nil
    end
    self.ShipListHelper:SetSelectedIndex(nIndex)
    if bScrollTo then
        self.ShipListHelper:ScrollToIndex(nIndex)
    end
    local tbShipData = self.ShipListHelper:GetSelectedData()
    self.tbShipTitle:SetData(tbShipData)

    return tbShipData
end

local function SelectShipItemById(self, nShipItemId)
    local tbSortedDatas = self.ShipListHelper:GetData()

    if not nShipItemId then
        nShipItemId = self.tbCurrentDisplayData.nShipItemId
    end

    local nIndex = nil
    if nShipItemId then
        for i, tbData in pairs(tbSortedDatas) do
            if tbData.nShipItemId == nShipItemId then
                nIndex = i
                break
            end
        end
    end

    if nIndex then
        SelectShipItemByIndex(self, nIndex, true)
    end
    return nIndex
end

local function GetSelectedSkinItemId(self)
    local tbSkinData = self.SkinListHelper:GetSelectedData()
    if tbSkinData then
        return tbSkinData.nId
    elseif self.tbCurrentDisplayData.nSkinItemId then
        SelectSkinItemById(self, self.tbCurrentDisplayData.nSkinItemId)
        return self.tbCurrentDisplayData.nSkinItemId
    else
        return -1
    end
end

local function UpdateShipList(self)
    local tbSortedDatas = GetSortedShipListData(self)
    self.ShipListHelper:SetData(tbSortedDatas)
end

local function UpdateShipDisplay(self)
    if not self:IsVisible() then
        LOG("UpdateShipDisplay wnd is not visible")
        return
    end
    local tbShipData = self.ShipListHelper:GetSelectedData()
    local tbSkinData = self.SkinListHelper:GetSelectedData()
    local nSkinItemId = tbSkinData and tbSkinData.nId
    if nSkinItemId then
        self.ulLobbyShipBuy:Update(tbSkinData)
    else
        nSkinItemId = self.OwnerSub:GetShipPreparationComponent():GetEquippedShipSkinId(tbShipData.nShipItemId)
        self.ulLobbyShipBuy:Update(tbShipData.tbTemplate)
    end
    local nShipId = nSkinItemId and nSkinItemId or tbShipData.nShipItemId
    self.ulLobbyShipHandbook:UpdateShipDisplay(nShipId, tbShipData)

    local tbModify = self.OwnerSub:GetShipModelModifyByKey(SHIP_WND_NAME, nShipId)
    self.OwnerSub:CreateShipActorById(nShipId, 1, tbModify)
end

local function RefreshBtnSkin(self)
    local pWidgetRef = self.pWidgetRef
    local tbShipData = self.ShipListHelper:GetSelectedData()
    if tbShipData.bHaveNewSkin then
        pWidgetRef.btnSkin:HideTipIcon(false)
    else
        pWidgetRef.btnSkin:HideTipIcon(true)
    end
end

local function SwitchToSkinList(self, bShowSkinList)
    local pPlayMode = bShowSkinList and EUMGSequencePlayMode.Forward or EUMGSequencePlayMode.Reverse
    self:StopAnimation("anim_ListOut")
    self:PlayAnimation("anim_ListOut", 0, 1, pPlayMode, 1)
end

---------- Requests & Receives ------------------------------------------------

local function OnAddItem(self, Item)
    UpdateShipList(self)
    UpdateShipSkinList(self)
end

local function OnReceiveShipSkinChanged(self, nShipItemId)
    UpdateShipList(self)
    self.SkinListHelper:RequestListRefresh()
    if self.ShipListHelper:GetSelectedData().nShipItemId ~= nShipItemId then
        return
    end
    -- UpdateShipDisplay(self)
end

local function OnShopNotEnoughCurrency(self, tbShoppingGoods)
    if not tbShoppingGoods.currency_auto_exchange then
        CostCurrencyHelper:FirstCostFailed()
    else
        CostCurrencyHelper:SecondCostFailed()
    end
end

local function SetSkinListVisible(self, bVisible, bWitnAnim, fnCallback)
    local pWidgetRef = self.pWidgetRef
    local SetVisibility = function()
        local pVisibility = bVisible and ESlateVisibility.Collapsed or ESlateVisibility.SelfHitTestInvisible
        pWidgetRef.vBoxShipList:SetVisibility(pVisibility)
        pWidgetRef.vBoxDetailContent:SetVisibility(pVisibility)
        pWidgetRef.pbShipTitle:SetVisibility(pVisibility)
        if bVisible then
            self:SetCurrentDisplayData("nSkinItemId", GetSelectedSkinItemId(self))
        else
            self:SetCurrentDisplayData("nSkinItemId", nil)
            pWidgetRef.bdrChangedEffects:SetVisibility(ESlateVisibility.Collapsed)
            pWidgetRef.hBoxSkinList:SetVisibility(ESlateVisibility.Collapsed)
        end
        if fnCallback then
            fnCallback()
        end
    end

    if bVisible then
        pWidgetRef.hBoxSkinList:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
        pWidgetRef.vBoxDetailContent:SetVisibility(ESlateVisibility.Collapsed)
        pWidgetRef.pbShipTitle:SetVisibility(ESlateVisibility.Collapsed)
    else
        pWidgetRef.vBoxShipList:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
    end
    
    if bWitnAnim then
        self:StopAnimation("anim_LobbyShipHandBoodIn_ShipSkin")
        local pPlayMode = bVisible and EUMGSequencePlayMode.Forward or EUMGSequencePlayMode.Reverse
        self:PlayAnimation("anim_LobbyShipHandBoodIn_ShipSkin", 0, 1, pPlayMode, 1, SetVisibility)
        SwitchToSkinList(self, bVisible)
    else
        SetVisibility()
    end
end

local function ShowWnd(self, bWithAnim)
    local pWidgetRef = self.pWidgetRef
    pWidgetRef.bdrChangedEffects:SetVisibility(ESlateVisibility.Collapsed)
    local SetVisibility = function()
        pWidgetRef.vboxShipList:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
        pWidgetRef.vboxDetailContent:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
        pWidgetRef.pbLobbyShipDetail:SetVisibility(ESlateVisibility.Hidden)
        pWidgetRef.hBoxSkinList:SetVisibility(ESlateVisibility.Hidden)
        pWidgetRef.pbShipTitle:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
        pWidgetRef.pbShipTitle:SetRenderTranslation(ZERO_VECTOR2D)
        pWidgetRef.pbShipTitle:SetRenderOpacity(1)
    end

    if bWithAnim then
        self:StopAnimation("anim_LobbyShipHandBookIn_ShipListIn")
        self:PlayAnimation("anim_LobbyShipHandBookIn_ShipListIn", 0, 1, EUMGSequencePlayMode.Forward, 1, SetVisibility)
    else
        SetVisibility()
    end
end

---------- widget事件 -----------------------------------------------------------

local function OnShipListSelectedChanged(self, nIndex)
    if nIndex == NONE_INDEX then
        LOG("OnShipListSelectedChanged select NONE_INDEX")
        return
    end

    UpdateShipDisplay(self)
    RefreshBtnSkin(self)

    local tbShipData = self.ShipListHelper:GetSelectedData()
    local nId = tbShipData.tbTemplate.nId
    LOG("OnShipListSelectedChanged tbShipData", nIndex, nId)
    local ShipPreparationComponent = self.OwnerSub:GetShipPreparationComponent()
    if ShipPreparationComponent:IsNewShipItem(nId) then
        ShipPreparationComponent:UnmarkNewShipItem(nId)
    end
    self:SetCurrentDisplayData("nShipItemId", nId)
end

local function OnExpirationTimeEnd(self)
    UpdateShipList(self)
end

local function OnBtnSkinClicked(self)
    UpdateShipSkinList(self)
    SelectSkinItemById(self)
    SetSkinListVisible(self, true, true)
    self:SetDetailVisible(false, false)
    self.OwnerSub:ShowShipDisplayScene(true, 2, self.nViewBlendTime)
end


-- 皮肤列表选择
local function OnSkinListSelectedChanged(self, nIndex)
    if nIndex == NONE_INDEX then
        LOG("OnSkinListSelectedChanged select NONE_INDEX")
        return
    end
    
    local tbDataList = self.SkinListHelper:GetData()
    if not tbDataList then
        return
    end
    UpdateShipDisplay(self)

    local tbSkinItem = tbDataList[nIndex]
    if tbSkinItem then
        self:SetCurrentDisplayData("nSkinItemId", tbSkinItem.nId)
        
        self.OwnerSub:RequestEquipShipSkin(tbSkinItem)
        self.SkinListHelper:RefreshItemByIndex(nIndex)
        self:SetSkinChangedEffectData(tbSkinItem)
        
        local ShipPreparationComponent = self.OwnerSub:GetShipPreparationComponent()
        if ShipPreparationComponent:IsNewShipItem(tbSkinItem.nId) then
            ShipPreparationComponent:UnmarkNewShipItem(tbSkinItem.nId)
        end
    end
end

local function OnBtnBackClicked(self)
    if self.tbCurrentDisplayData.nSkinItemId then
        self.SkinListHelper:UnselectCurrentItem()
        SetSkinListVisible(self, false, true)
        UpdateShipDisplay(self)
        RefreshBtnSkin(self)
        self.OwnerSub:ShowShipDisplayScene(true, 1, self.nViewBlendTime)
    else
        self.OwnerSub:Return(self:GetWndName())
    end
end

--------- 初始化 -----------------------------------------------------------------

local function InitShipList(self)
    self.ShipListHelper = SelfVerticalListHelper()
    self.ShipListHelper:Init(self, self.pWidgetRef.KMVerticalList_0)
    self.ShipListHelper.OnSelectedChangedDelegate:Bind(OnShipListSelectedChanged, self)
    self.ShipListHelper.tbExtraDatas.OwnerSub = self.OwnerSub
end

local function InitSkinList(self)
    self.SkinListHelper = SelfVerticalListHelper()
    self.SkinListHelper:Init(self, self.pWidgetRef.vListSkin)
    self.SkinListHelper.OnSelectedChangedDelegate:Bind(OnSkinListSelectedChanged, self)
    self.SkinListHelper.tbExtraDatas.OwnerSub = self.OwnerSub
    self.SkinListHelper.tbExtraDatas.nCategory = ItemCategoryDef.SHIP_SKIN
end

local function InitShipTitle(self)
    local tbShipTitle = self.PrefabHelper:BindPrefab(self.pWidgetRef.pbShipTitle)
    tbShipTitle:BindCallbacks(
        function()
            OnExpirationTimeEnd(self)
        end
    )
    self.tbShipTitle = tbShipTitle
end

----------------- overrides ---------------------------------------------------

function UILobbyShipHandbook:OnLoad()
    UILobbyShipHandbook.super.OnLoad(self)
    self.pbWindowFrame:SetBackDelegate(OnBtnBackClicked, self)

    self.ulLobbyShipHandbook = self.UILogicHelper:CreateUILogic("ULLobbyShipHandbook")
    self.ulLobbyShipBuy = self.UILogicHelper:CreateUILogic("ULLobbyShipBuy")

    self:SetShowDetailAnim("anim_LobbyShipHandBookIn_DetailsIn")

    InitShipTitle(self)

    InitSkinList(self)
    InitShipList(self)
end

function UILobbyShipHandbook:OnUnload()
    self.ShipListHelper:Uninit()
    self.ShipListHelper = nil

    self.SkinListHelper:Uninit()
    self.SkinListHelper = nil
end

function UILobbyShipHandbook:OnShow()
    local pWidgetRef = self.pWidgetRef
    pWidgetRef.vboxDetailContent:SetVisibility(ESlateVisibility.Collapsed)
    pWidgetRef.btnDetail:SetVisibility(ESlateVisibility.Visible)

    UpdateShipList(self)
    GetResumeData(self)

    local nIndex = SelectShipItemById(self)
    if not nIndex then
        SelectShipItemByIndex(self, DEFAULT_SHIP_INDEX)
    end

    local nCameraIndex = 1
    if self.tbCurrentDisplayData.nSkinItemId then
        UpdateShipSkinList(self)
        SetSkinListVisible(self, true, false)
        nCameraIndex = 2
    elseif self.tbCurrentDisplayData.nDetailMode and self.tbCurrentDisplayData.nDetailMode > 0 then
        ShowWnd(self, false)
        self:SetDetailVisible(true, false)
    else
        self:SetDetailVisible(false, false)
        ShowWnd(self, true)
    end

    self.OwnerSub:ShowShipDisplayScene(true, nCameraIndex)

end

function UILobbyShipHandbook:OnExit()
    UILobbyShipHandbook.super.OnExit(self)
    ShowWnd(self, false)
    self.ShipListHelper:UnselectCurrentItem()
    self.SkinListHelper:UnselectCurrentItem()
    self.tbCurrentDisplayData = {}

    self:StopAnimation("anim_LobbyShipHandBoodIn_ShipSkin")
    self:StopAnimation("anim_LobbyShipHandBookIn_DetailsIn")
    self:StopAnimation("anim_LobbyShipHandBookIn_ShipListIn")

end

function UILobbyShipHandbook:OnBindEvent(EventHelper)
    UILobbyShipHandbook.super.OnBindEvent(self, EventHelper)
    local pWidgetRef = self.pWidgetRef

    EventHelper:RegisterCppDelegate(pWidgetRef.btnSkin.OnClicked, self, OnBtnSkinClicked)

    EventHelper:RegisterEvent(ClientEventDef.EV_ADD_LOBBY_ITEM, self, OnAddItem)
    EventHelper:RegisterEvent(ClientEventDef.EV_CHANGE_LOBBY_ITEM_EXPIRED_AT, self, OnAddItem)
    EventHelper:RegisterEvent(ClientEventDef.EV_ON_RECEIVE_SHIP_SKIN_CHANGED, self, OnReceiveShipSkinChanged)
    EventHelper:RegisterEvent(ClientEventDef.EV_SHOP_NOT_ENOUGH_CURRENCY, self, OnShopNotEnoughCurrency)
end

return UILobbyShipHandbook