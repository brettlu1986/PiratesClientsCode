-----------------------------------------------------
--File Name    : UPPickupItem.lua
--Description  : Prefab UPPickupItem
-----------------------------------------------------

local luaclass = require ("luaclass")
local ListItemBase = require("ListItemBase")
local UPPickupItem = luaclass("UPPickupItem", ListItemBase)

local UISetUtils = require("UISetUtils")
local BattleItemDataTable = require("BattleItemDataTable")
local BattleItemResDataTable = require("BattleItemResDataTable")
local BattlePickupSystem = require("BattlePickupSystem")
local UIResourceDef = require("UIResourceDef")
local BattleItemCategoryDef = require("BattleItemCategoryDef")
local BattleItemColorGradeHelper = require("BattleItemColorGradeHelper")
local BattleItemSystemClient = require("BattleItemSystemClient")
local DelayTimer = require("DelayTimer")
local BattleResultServerIni = require("BattleResultServerIni")
local L10N = require("L10N")

local LINEAR_COLOR_NORMAL = KMUMGLibrary.GetLinearColor(0.64, 0.64, 0.64, 1.0)
local LINEAR_COLOR_BETTER = KMUMGLibrary.GetLinearColor(0.98, 0.62, 0.03, 1.0)

UPPickupItem.nInstanceId = nil
UPPickupItem.nItemTemplateId = nil
UPPickupItem.nCount = nil

local function OnItemSelectClicked(self)
    BattlePickupSystem:ManualPickupItem(self.nInstanceId, self.nItemTemplateId, self.nCount)
end


--[[
    public function
]]
function UPPickupItem:OnDestroy()
    if self.tbDelayHandle then
        DelayTimer:ClearTimer(self.tbDelayHandle)
        self.tbDelayHandle = nil
    end
end

function UPPickupItem:OnBindEvent(EventHelper)
    local pWidgetRef = self.pWidgetRef
    EventHelper:RegisterCppDelegate(pWidgetRef.btnSelect.OnClicked , self, OnItemSelectClicked)
end

local function RefreshItemGrade(self, nGrade)
    local pWidgetRef = self.pWidgetRef
    local imgLevel = pWidgetRef.imgLevel
    if nGrade ~= nil and nGrade > 0 then
        imgLevel:SetVisibility(ESlateVisibility_SelfHitTestInvisible)
        local tbLevelSprs = UIResourceDef.ITEM_GRADE_ICON
        local szIconPath = tbLevelSprs[nGrade]
        if szIconPath then
            -- local IconObj = tbLevelSprs[nGrade]:load()
            -- if(IconObj == nil)then
            --     error("UPPickupItem: icon is not found,path="..tostring(szIconPath))
            --     return
            -- end
            -- UISetUtils.SetImageBrushRes(imgLevel, IconObj, true)
            UISetUtils.SetAsyncImageBrushFromSprite(imgLevel, szIconPath, nil)
        end
    else
        imgLevel:SetVisibility(ESlateVisibility_Collapsed)
    end
end

-- 只判断图纸是不是已经有相同的了
local function RefreshHasOwnedSameType(self, tbTemplate)
    local pWidgetRef = self.pWidgetRef
    local txtGiveUp = pWidgetRef.txtGiveUp

    local nCategory = tbTemplate.nCategory
    if nCategory ~= BattleItemCategoryDef.BUILD_KEY_ITEM then
        txtGiveUp:SetVisibility(ESlateVisibility_Collapsed)
        return
    end
    local nItemTemplateId = tbTemplate.nId
    local nItemCount = BattleItemSystemClient:GetUnequippedItemCount(nItemTemplateId)
    if nItemCount > 0 then
        txtGiveUp:SetVisibility(ESlateVisibility_SelfHitTestInvisible)
    else
        txtGiveUp:SetVisibility(ESlateVisibility_Collapsed)
    end
end

function UPPickupItem:SetData(tbData)
    local nItemTemplateId = tbData.template_id
    local tbTemplate = BattleItemDataTable:GetTemplate(nItemTemplateId)
    if not tbTemplate then
        return
    end
    self.nInstanceId = tbData.instance_id
    self.nItemTemplateId = nItemTemplateId
    local pWidgetRef = self.pWidgetRef
    pWidgetRef:SetVisibility(ESlateVisibility_SelfHitTestInvisible)
    pWidgetRef.txtName:SetText(tbTemplate.l10nName)
    pWidgetRef.txtDesc:SetVisibility(ESlateVisibility_SelfHitTestInvisible)

    local bIsLevelUpBox = tbTemplate.nConvertItemTemplateId and tbTemplate.nConvertItemTemplateId == BattleResultServerIni.nRusultEquipLevelupItem
    local bIsLevelUpItem = nItemTemplateId == BattleResultServerIni.nRusultEquipLevelupItem
    if bIsLevelUpBox or bIsLevelUpItem then  
        pWidgetRef.txtDesc:SetText(L10N:Format(tbTemplate.l10nDesc, string.format("%.0f",BattleResultServerIni.nDeadLossPercent * 100)))
    else  
        pWidgetRef.txtDesc:SetText(tbTemplate.l10nDesc)
    end

    RefreshItemGrade(self, tbTemplate.nGrade)

    RefreshHasOwnedSameType(self, tbTemplate)

    local nCategory = tbTemplate.nCategory
    local nCount = 1
    if nCategory == BattleItemCategoryDef.CONVERTIBLE_ITEM then
        nCount = tbTemplate.nConvertItemCount
    else
        nCount = tbData.stack_count
    end
    self.nCount = nCount
    if nCount and nCount > 1 then
        pWidgetRef.txtCount:SetVisibility(ESlateVisibility_SelfHitTestInvisible)
        pWidgetRef.txtCount:SetText(nCount)
    else
        pWidgetRef.txtCount:SetVisibility(ESlateVisibility_Collapsed)
    end

    --耐久
    if nCategory == BattleItemCategoryDef.SHIP_PART or nCategory == BattleItemCategoryDef.HUMAN_ARMOR then
        local nTotalDurability = tbTemplate.nDurability
        local nPercent = tbData.durability / nTotalDurability
        pWidgetRef.pgbDurability:SetPercent(1 - nPercent)
        pWidgetRef.pgbDurability:SetVisibility(ESlateVisibility_SelfHitTestInvisible)
    else
        pWidgetRef.pgbDurability:SetVisibility(ESlateVisibility_Collapsed)
    end

    --local bgResObj = UIResourceDef.FFA_PICK_UP_NORMAL:load()
    local pBgColor = LINEAR_COLOR_NORMAL
    if tbData.bIsBetter then
        pBgColor = LINEAR_COLOR_BETTER
    end
    --UISetUtils.SetImageBrushRes(pWidgetRef.bgImage, bgResObj)
    pWidgetRef.bgImage:SetColorAndOpacity(pBgColor)
    local tbResTemplate = BattleItemResDataTable:GetTemplate(tbTemplate.nResId)
    if tbResTemplate then
        -- local ResObj = tbResTemplate.szIconPath:load()
        -- if ResObj then
        --     UISetUtils.SetButtonBrushRes(pWidgetRef.btnBlueprintItem, ResObj)
        -- else
        --     logerror("[UI]UPPickupItem:SetData, can not find item icon",tbResTemplate.szIconPath)
        -- end
        UISetUtils.SetAsyncImageBrushFromSprite(pWidgetRef.imgIcon, tbResTemplate.szIconPath, nil)
    end

    local pColorGradeImg = BattleItemColorGradeHelper.GetCachedColorGradeImg(nItemTemplateId)
    UISetUtils.SetImageBrushRes(pWidgetRef.imgColour, pColorGradeImg)
end

function UPPickupItem:OnRefresh(tbListData)
    --logdebug("UPPickupItem:OnRefresh")
    if not tbListData then
        log("UPPickupItem:OnRefresh,tbData is nil")
        self.pWidgetRef:SetVisibility(ESlateVisibility_Collapsed)
        return
    end
    self:SetData(tbListData)
end

function UPPickupItem:Hide()
    self.pWidgetRef:SetVisibility(ESlateVisibility_Collapsed)
end

return UPPickupItem
