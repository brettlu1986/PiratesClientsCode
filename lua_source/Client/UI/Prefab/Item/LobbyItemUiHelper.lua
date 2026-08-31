local LobbyItemUiHelper = {}

local UIResourceDef = require("UIResourceDef")
local UISetUtils = require("UISetUtils")
local ItemDataTable = require("ItemDataTable")
local ItemCategoryDef = require("ItemCategoryDef")
local BuildingDataTable = require("BuildingDataTable")
local L10N = require("L10N")
local UITextDef = require("UITextDef")

local GetL10NTextByKey = UISetUtils.GetL10NTextByKey

local COUNT_TITLE_HAS_LIMIT = GetL10NTextByKey("UP_LOBBY_BACKPACK_TIPS_COUNT_TITLE_HAS_LIMIT")
local COUNT_TITLE_NO_LIMIT = GetL10NTextByKey("UP_LOBBY_BACKPACK_TIPS_COUNT_TITLE_NO_LIMIT")

function LobbyItemUiHelper.SetSelected(pWidgetRef, bSelected)
    local imgSelected = pWidgetRef.imgSelected
    if bSelected then
        imgSelected:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
    else
        imgSelected:SetVisibility(ESlateVisibility.Collapsed)
    end
end

function LobbyItemUiHelper.SetGradeColorImage(pWidgetRef, nGrade)
    local szGradeIcon = UIResourceDef.ITEM_COLOR_GRADE_BG[nGrade]
    UISetUtils.SetImageBrushRes(pWidgetRef.imgPackItemBg, szGradeIcon:load())
end

function LobbyItemUiHelper.SetGradeImage(pWidgetRef, nCategory, nGrade)
    local imgGrade = pWidgetRef.imgGrade
    if nCategory == ItemCategoryDef.SAILOR then
        imgGrade:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
        local szGradeIcon = UIResourceDef.SAILOR_GRADE_ICONS[nGrade + 1]
        UISetUtils.SetImageBrushRes(imgGrade, szGradeIcon:load())
    else
        imgGrade:SetVisibility(ESlateVisibility.Collapsed)
    end
end

function LobbyItemUiHelper.SetGradeHalfColorImage(tbUiDefRes ,pWidgetRef, nGrade)
    local szGradeIcon = tbUiDefRes[nGrade]
    UISetUtils.SetImageBrushRes(pWidgetRef.ImgGradeLeft, szGradeIcon:load())
    UISetUtils.SetImageBrushRes(pWidgetRef.ImgGradeRight, szGradeIcon:load())
end


function LobbyItemUiHelper.SetIconImage(pWidgetRef, nTemplateId)
    local tbItemResTemplate = ItemDataTable:GetResTemplate(nTemplateId)
    local szIconPath = tbItemResTemplate.szIconPath
    UISetUtils.SetButtonBrushRes(pWidgetRef.btnItem, szIconPath:load())
end

function LobbyItemUiHelper.SetAsyncIconImage(pWidgetRef, nTemplateId)
    local tbItemResTemplate = ItemDataTable:GetResTemplate(nTemplateId)
    local szIconPath = tbItemResTemplate.szIconPath
    UISetUtils.SetAsyncImageBrushFromSprite(pWidgetRef.imgItem, szIconPath)
end

function LobbyItemUiHelper.SetCount(pWidgetRef, nCount)
    pWidgetRef.txtCount:SetText(nCount)
end

function LobbyItemUiHelper.SetButtonCanClick(pWidgetRef, bCanClick)
    if bCanClick then
        pWidgetRef.btnItem:SetVisibility(ESlateVisibility.Visible)
    else
        pWidgetRef.btnItem:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
    end
end

function LobbyItemUiHelper.SetCountTitleAndCount(Item, pCountTitleWidgetRef, pCountWidgetRef)
    local nCount = Item:GetStackCount()
    if Item:HasHoldLimit() then
        local szCount = nCount .."/".. Item:GetHoldLimit()
        pCountTitleWidgetRef:SetText(COUNT_TITLE_HAS_LIMIT)
        pCountWidgetRef:SetText(szCount)
    else
        pCountTitleWidgetRef:SetText(COUNT_TITLE_NO_LIMIT)
        pCountWidgetRef:SetText(nCount)
    end
end

function LobbyItemUiHelper.ShowTryTxt(pWidgetRef, nTemplateId)
    local tbItemTemplate = ItemDataTable:GetTemplate(nTemplateId)
    local nCategory = tbItemTemplate.nCategory
    local bdrTry = pWidgetRef.bdrTry
    if nCategory == ItemCategoryDef.UNLOCK_ITEM then
        bdrTry:SetVisibility(ESlateVisibility.HitTestInvisible)
    else
        bdrTry:SetVisibility(ESlateVisibility.Collapsed)
    end
end


function LobbyItemUiHelper.GetBuildingSizeDesc(tbItemTemplate)
    if tbItemTemplate.nCategory == ItemCategoryDef.DECORATIVE_BUILDING then
        local nBuildingId = tbItemTemplate.nBuildingId
        local tbBuildingTemplate = BuildingDataTable:GetTemplate(nBuildingId)
        return L10N:Format(UITextDef.HOMELAND_BUILDING_SIZE_FORMAT, tbBuildingTemplate.nLength, tbBuildingTemplate.nWidth)
    else
        return ""
    end
end

function LobbyItemUiHelper.ShowNew(pWidgetRef, bNew)
    local imgNew = pWidgetRef.imgNew
    if bNew then
        imgNew:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
    else
        imgNew:SetVisibility(ESlateVisibility.Collapsed)
    end
end

function LobbyItemUiHelper.ShowMultiple(pWidgetRef, nMultiple)
    local bdrMultiple = pWidgetRef.bdrMultiple
    if bdrMultiple == nil then
        return
    end
    if nMultiple then
        bdrMultiple:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
        pWidgetRef.txtMultiple:SetText(L10N:Format(UITextDef.COMMON_MULTIPLE, nMultiple))
    else
        bdrMultiple:SetVisibility(ESlateVisibility.Collapsed)        
    end
end

return LobbyItemUiHelper