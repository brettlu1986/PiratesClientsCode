local luaclass = require("luaclass")
local PrefabBase = require("PrefabBase")
local UPBuilItemTipsBase = luaclass("UPBuilItemTipsBase", PrefabBase)
local BattleItemDataTable = require("BattleItemDataTable")
local BattleItemCategoryDef = require("BattleItemCategoryDef")
local BattleItemSystemClient = require("BattleItemSystemClient")
local ClientEventDef = require("ClientEventDef")
local LuaDelegateClass = require("LuaDelegate")
local UIToolTipHelper = require("UIToolTipHelper")
local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
local CheckCanBuildItemHelper = require("CheckCanBuildItemHelper")
local UIDef = require("UIDef")
local UISetUtils = require("UISetUtils")
local UIResourceDef = require("UIResourceDef")
local UITextDef = require("UITextDef")
-- local ShipItemHelper = require("ShipItemHelper")
local BattleItemBuildDataTable = require("BattleItemBuildDataTable")

UPBuilItemTipsBase.nChoosenItemTemplateId = nil
UPBuilItemTipsBase.bReserved = nil

UPBuilItemTipsBase.OnItemButtonPressedDelegate = nil
UPBuilItemTipsBase.OnItemButtonReleasedDelegate = nil

UPBuilItemTipsBase.nKeyItemId = nil
UPBuilItemTipsBase.bNotShowPrice = nil
UPBuilItemTipsBase.bIsCurrent = nil

UPBuilItemTipsBase.pBtnKeyItem = nil
UPBuilItemTipsBase.pImgKeyItem = nil
UPBuilItemTipsBase.pTxtItemCount = nil

UPBuilItemTipsBase.pbBuildingCostMaterials = nil
UPBuilItemTipsBase.pHBoxCost = nil

UPBuilItemTipsBase.pBtnBuild = nil
UPBuilItemTipsBase.pBtnReserve = nil
UPBuilItemTipsBase.pTxtReserve = nil

UPBuilItemTipsBase.pTxtCurrent = nil

local function GetEquippedItem(nItemTemplateId, nSlotIndex)
    local nCharacterInstanceId = GamePlayerSelfHelper:GetServerInstanceId()
    return CheckCanBuildItemHelper.GetSameSlotEquippedItem(nCharacterInstanceId, nItemTemplateId, nSlotIndex, true)
end

local function HiddenTips(self)
    UIToolTipHelper:HideTip()
end

local function ShowItemTips(self, nItemTemplateId, pPressedWidgetRef)
    if not nItemTemplateId then
        return
    end
    local tbTemplate = BattleItemDataTable:GetTemplate(nItemTemplateId)
    local tbTipData = {
        szTitle = tbTemplate.l10nName,
        szDetail = tbTemplate.l10nDetailedDesc,
    }
    UIToolTipHelper:ShowTipInAutoLayout(UIToolTipHelper.TipType.TEXT_TIP, tbTipData, pPressedWidgetRef)
end

local function OnItemButtonPressed(self, nItemTemplateId, pPressedWidgetRef)
    ShowItemTips(self, nItemTemplateId, pPressedWidgetRef)
end

local function OnItemButtonReleased(self)
    HiddenTips(self)
end

local function OnBuildBtnClicked(self)
    BattleItemSystemClient:RequestBuildItem(self.nChoosenItemTemplateId, self.nSlotIndex)
end

local function OnReserveBtnClicked(self)
    if self.bReserved then
        BattleItemSystemClient:CancelReserveItemBuild(self.nChoosenItemTemplateId)
    else
        BattleItemSystemClient:ReserveItemBuild(self.nChoosenItemTemplateId)
    end
end

local function OnKeyItemButtonPressed(self)
    self.OnItemButtonPressedDelegate:Fire(self.nKeyItemId, self.pBtnKeyItem)
end

local function OnKeyItemButtonReleased(self)
    self.OnItemButtonReleasedDelegate:Fire()
end

local function RefreshReserveButton(self)
    local nReservedItemTemplateId = BattleItemSystemClient:GetReservedItemTemplateId()

    if nReservedItemTemplateId == nil or nReservedItemTemplateId ~= self.nChoosenItemTemplateId then
        if self.pTxtReserve then
            self.pTxtReserve:SetText(UITextDef.UI_STATIC_FFA_RESERVE_ITEM_BUILD)
        end
        self.bReserved = false
    else
        if self.pTxtReserve then
            self.pTxtReserve:SetText(UITextDef.UI_STATIC_FFA_CANCEL_RESERVE_ITEM_BUILD)
        end
        self.bReserved = true
    end
end

local function OnReserveItemBuild(self, nReservedItemInstanceId)
    if nReservedItemInstanceId == self.nChoosenItemTemplateId then
        RefreshReserveButton(self)
    end
end

local function OnCancelReserveItemBuild(self, nCancelReservedItemInstanceId)
    if nCancelReservedItemInstanceId == self.nChoosenItemTemplateId then
        RefreshReserveButton(self)
    end
end

local function GetShipPartCanBuildAndLock(self, tbItemTemplate)
    local nCanBuildGrade = 1
    local nItemTemplateId = tbItemTemplate.nId
    local EquippedItem = GetEquippedItem(nItemTemplateId)
    if EquippedItem then
        nCanBuildGrade = EquippedItem:GetGrade() + 1
    end
    local bCanBuild = false
    local bLock = false
    if tbItemTemplate.nGrade <= nCanBuildGrade then
        local bVerificationResult, _ = BattleItemSystemClient:VerifyItemBuilding(nItemTemplateId, self.nSlotIndex)
        bCanBuild = bVerificationResult
        bLock = false
    else
        bCanBuild = false
        bLock = true
    end
    return bCanBuild, bLock
end

local function GetShipWeaponCanBuild(self, nChoosenItemTemplateId)
    local bVerificationResult, _ = BattleItemSystemClient:VerifyItemBuilding(nChoosenItemTemplateId, self.nSlotIndex)
    return bVerificationResult
end

local function GetHumanItemCanBuildAndLock(self, tbItemTemplate, nSlotIndex)
    local nItemTemplateId = tbItemTemplate.nId
    local EquippedItem = GetEquippedItem(nItemTemplateId, nSlotIndex)
    local bCanBuild = false
    local bLock = false
    if EquippedItem then
        local nCanBuildGrade = EquippedItem:GetGrade() + 1
        if tbItemTemplate.nGrade == nCanBuildGrade then
            local bVerificationResult, _ = BattleItemSystemClient:VerifyItemBuilding(nItemTemplateId, self.nSlotIndex)
            bCanBuild = bVerificationResult
            bLock = false
        else
            bCanBuild = false
            bLock = true
        end
    end

    return bCanBuild, bLock
end

local function RefreshBuildingCostMaterials(self, tbBuildTemplate, szName)
    if self.pbBuildingCostMaterials then
        self.pbBuildingCostMaterials:Refresh(tbBuildTemplate, szName)
    end
end

local function GetCanBuildAndLock(self, nChoosenItemTemplateId, nSlotIndex)
    local tbItemTemplate = BattleItemDataTable:GetTemplate(nChoosenItemTemplateId)
    if not tbItemTemplate then
        error("GetCanBuildAndLock cannot find item template, nChoosenItemTemplateId = " .. tostring(nChoosenItemTemplateId))
        return
    end
    local nCategory = tbItemTemplate.nCategory
    if nCategory == BattleItemCategoryDef.SHIP_PART then
        return GetShipPartCanBuildAndLock(self, tbItemTemplate)
    elseif nCategory == BattleItemCategoryDef.SHIP_WEAPON or nCategory == BattleItemCategoryDef.SHIP then
        return GetShipWeaponCanBuild(self, nChoosenItemTemplateId)
    elseif nCategory == BattleItemCategoryDef.HUMAN_WEAPON then
        return GetHumanItemCanBuildAndLock(self, tbItemTemplate, nSlotIndex)
    elseif nCategory == BattleItemCategoryDef.HUMAN_ARMOR then
        return GetHumanItemCanBuildAndLock(self, tbItemTemplate)
    end
end

local function OnItemChanged(self)
    if self.pWidgetRef:IsVisible() then
        self:Refresh(self.nChoosenItemTemplateId, self.bNotShowPrice, self.nSlotIndex)
    end
end

-------------------
-- 控件设置
-------------------
function UPBuilItemTipsBase:Collapsed()
    self.pWidgetRef:SetVisibility(ESlateVisibility.Collapsed)
end

function UPBuilItemTipsBase:RefreshCurrent()
    local nCurrentShipTemplateId = self:GetCurrentItemTemplateId()
    if nCurrentShipTemplateId == self.nChoosenItemTemplateId then
        if self.pTxtCurrent then
            self.pTxtCurrent:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
        end
        return true
    else
        if self.pTxtCurrent then
            self.pTxtCurrent:SetVisibility(ESlateVisibility.Collapsed)
        end
        return false
    end
end

function UPBuilItemTipsBase:RefreshBuildKeyItem(tbBuildTemplate)
    local tbKeyItemIds = tbBuildTemplate.tbKeyItemIds
    if tbKeyItemIds == nil or #tbKeyItemIds == 0 then
        if self.pBtnKeyItem then
            self.pBtnKeyItem:SetVisibility(ESlateVisibility.Collapsed)
        end
        self.nKeyItemId = nil
    else
        if self.pBtnKeyItem then
            self.pBtnKeyItem:SetVisibility(ESlateVisibility.Visible)
        end
        local nKeyItemId = tbKeyItemIds[1] -- 这里的假设是只有一种关键材料，且只需要一个
        self.nKeyItemId = nKeyItemId
        local nNeedCount = 1
        local tbBuildKeyItemTemplate = BattleItemDataTable:GetTemplate(nKeyItemId)
        if self.pImgKeyItem then
            local szCostIconPath = tbBuildKeyItemTemplate.szCostIconPath
            UISetUtils.SetImageBrushRes(self.pImgKeyItem, szCostIconPath:load(), true)
        end
        if self.pTxtItemCount then
            self.pTxtItemCount:SetText(nNeedCount)
            local nKeyItemCount = BattleItemSystemClient:GetUnequippedItemCount(nKeyItemId)
            if nKeyItemCount >= nNeedCount then
                self.pTxtItemCount:SetColorAndOpacity(UIResourceDef.COLOR.WHITE.SLATE_COLOR)
            else
                self.pTxtItemCount:SetColorAndOpacity(UIResourceDef.COLOR.RED.SLATE_COLOR)
            end
        end
    end
end

-------------------
-- LifeCycle
-- 这里会绑定一些通用的事件和delegate, 所以需要调一下
-------------------
function UPBuilItemTipsBase:OnLoad()
    self.OnItemButtonPressedDelegate = LuaDelegateClass()
    self.OnItemButtonReleasedDelegate = LuaDelegateClass()
end

function UPBuilItemTipsBase:OnBindEvent(EventHelper)   

    EventHelper:RegisterLuaDelegate(self.OnItemButtonPressedDelegate, OnItemButtonPressed, self)
    EventHelper:RegisterLuaDelegate(self.OnItemButtonReleasedDelegate, OnItemButtonReleased, self)

    EventHelper:RegisterEvent(ClientEventDef.EV_RESERVE_ITEM_BUILD, self, OnReserveItemBuild)
    EventHelper:RegisterEvent(ClientEventDef.EV_CANCEL_RESERVE_ITEM_BUILD, self, OnCancelReserveItemBuild)

    EventHelper:RegisterEvent(ClientEventDef.EV_BATTLE_ITEM_ADD_CLIENT, self, OnItemChanged)
    EventHelper:RegisterEvent(ClientEventDef.EV_BATTLE_ITEM_REMOVE_CLIENT, self, OnItemChanged)
    EventHelper:RegisterEvent(ClientEventDef.EV_BATTLE_ITEM_CHANGE_STACKCOUNT_CLIENT, self, OnItemChanged)
end

-------------------
-- 绑定控件引用
-- 这些控件每个UP都有且行为一致, 但无法保证控件名一致, 所以需要绑定一下
-------------------
--[[
    绑定关键建造材料相关控件, 例如在 UP_BuildItemTipsNew.uasset 中对应的控件名为
    pBtnKeyItem: kmButtonKeyItem,
    pImgKeyItem: imgBuildKeyItem,
    pTxtItemCount: txtBuildKeyItemCostCount
]]
function UPBuilItemTipsBase:BindKeyItem(pBtnKeyItem, pImgKeyItem, pTxtItemCount)
    self.pBtnKeyItem = pBtnKeyItem
    self.pImgKeyItem = pImgKeyItem
    self.pTxtItemCount = pTxtItemCount
    local EventHelper = self.EventHelper
    EventHelper:RegisterCppDelegate(pBtnKeyItem.OnPressed, self, OnKeyItemButtonPressed)
    EventHelper:RegisterCppDelegate(pBtnKeyItem.OnReleased, self, OnKeyItemButtonReleased)
end

--[[
    绑定建造按钮相关控件, 例如在 UP_BuildItemTipsNew.uasset 中对应的控件名为
    pBtnBuild: kmbtnBuild
    pBtnReserve: kmbtnReserve
    pTxtReserve: txtReserve
]]
function UPBuilItemTipsBase:BindBuildAndReserve(pBtnBuild, pBtnReserve, pTxtReserve)
    self.pBtnBuild = pBtnBuild
    self.pBtnReserve = pBtnReserve
    self.pTxtReserve = pTxtReserve
    local EventHelper = self.EventHelper
    EventHelper:RegisterCppDelegate(pBtnBuild.OnClicked, self, OnBuildBtnClicked)
    EventHelper:RegisterCppDelegate(pBtnReserve.OnClicked, self, OnReserveBtnClicked)
end

--[[
    绑定橙色的"当前"信息显示
]]
function UPBuilItemTipsBase:BindTxtCurrent(pTxtCurrent)
    self.pTxtCurrent = pTxtCurrent
end

--[[
    绑定建造消耗材料相关控件, 由于涉及到BindPrefab, 要在OnLoad()中绑定
    例如在 UP_BuildItemTipsNew.uasset 中对应的控件名为
    pbBuildingCostMaterialsWidgetRef: pbBuildingCostMaterials
    pHBoxCost: hboxCost
]]
function UPBuilItemTipsBase:BindPbBuildingCostMaterials(pbBuildingCostMaterialsWidgetRef, pHBoxCost)
    self.pHBoxCost = pHBoxCost
    self.pbBuildingCostMaterials = self.PrefabHelper:BindPrefab(pbBuildingCostMaterialsWidgetRef, UIDef.UP_BUILDING_COST_MATERIALS)
    self.pbBuildingCostMaterials:SetOnItemButtonPressedDelegate(self.OnItemButtonPressedDelegate)
    self.pbBuildingCostMaterials:SetOnItemButtonReleasedDelegate(self.OnItemButtonReleasedDelegate)
end

-------------------
-- 以下需要每个UP自己override
-------------------
--[[
    获取当前装配的ItemTemplateId, 在RefreshCurrent()中会用到
]]
function UPBuilItemTipsBase:GetCurrentItemTemplateId()
end

--[[
    刷新信息显示, 调这个会统一刷新建造信息
]]
function UPBuilItemTipsBase:Refresh(nChoosenItemTemplateId, bNotShowPrice, nSlotIndex)
    self.bNotShowPrice = bNotShowPrice
    self.nChoosenItemTemplateId = nChoosenItemTemplateId
    self.nSlotIndex = nSlotIndex
    self.bIsCurrent = self:RefreshCurrent()
    self.pWidgetRef:SetVisibility(ESlateVisibility.Visible)

    HiddenTips(self)

    local bCanBuild, _bLock = GetCanBuildAndLock(self, nChoosenItemTemplateId, nSlotIndex)
    -- 建造信息
    if not bNotShowPrice then
        local tbBuildTemplate = BattleItemBuildDataTable:GetBuildTemplate(nChoosenItemTemplateId)
        if tbBuildTemplate then
            RefreshBuildingCostMaterials(self, tbBuildTemplate)
            self:RefreshBuildKeyItem(tbBuildTemplate)
            if self.pBtnBuild then
                self.pBtnBuild:SetIsEnabled(bCanBuild)
            end
        else
            bNotShowPrice = true
        end 
    end
    -- 设置是否显示建造信息
    if self.pHBoxCost then
        local pHBoxVisibility = bNotShowPrice and ESlateVisibility.Collapsed or ESlateVisibility.SelfHitTestInvisible
        self.pHBoxCost:SetVisibility(pHBoxVisibility)
    end

    local pBtnVisibility = bNotShowPrice and ESlateVisibility.Collapsed or ESlateVisibility.Visible
    if self.pBtnBuild then
        self.pBtnBuild:SetVisibility(pBtnVisibility)
    end
    if self.pBtnReserve then
        self.pBtnReserve:SetVisibility(pBtnVisibility)
    end
    
    RefreshReserveButton(self)
end

return UPBuilItemTipsBase