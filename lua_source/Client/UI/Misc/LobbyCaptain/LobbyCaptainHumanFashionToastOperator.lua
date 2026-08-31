-----------------------------------------------------
--File Name    : LobbyCaptainHumanFashionToastOperator.lua
--Description  :
-----------------------------------------------------

local luaclass = require("luaclass")
local LobbyCaptainHumanFashionToastOperator = luaclass("LobbyCaptainHumanFashionToastOperator")

local L10N = require("L10N")
local HumanAvatarDef = require("HumanAvatarDef")
local UITextDef = require("UITextDef")
local ItemSystem = require("ItemSystem")
local HumanAvatarHelper = require("HumanAvatarHelper")
local UIUtils = require("UIUtils")
local ItemCategoryDef = require("ItemCategoryDef")

local FashionType = HumanAvatarDef.FashionType
local FashionSlotCategory = HumanAvatarDef.FashionSlotCategory

local FASHION_ARMOR_NAME = UITextDef.FASHION_ARMOR_NAME

local function ShowToast(l10nText)
    UIUtils.ShowToast(l10nText)
end

local function IsOverrideByBasic(nFashionType)
    local nValue = ItemSystem:GetHumanFashionFlag()
    local bOverride = HumanAvatarHelper.IsOverrideByBasicFashion(nValue, nFashionType)
    return bOverride
end

local function TryToToastBasicAffectArmor(nItemTemplateId)
    if not ItemSystem:HasFashionItem(nItemTemplateId) then
        return
    end
    local tbResult = {}
    local bShow = false
    for _, nFashionType in pairs(FashionType) do
        if nFashionType ~= FashionType.Basic then
            if IsOverrideByBasic(nFashionType) then
                bShow = true
                local l10nName = L10N:Format(UITextDef.LOBBY_CAPTAIN_HINT_WORD_WITH_COMMA, FASHION_ARMOR_NAME[nFashionType])
                table.insert(tbResult, l10nName)
            else
                table.insert(tbResult, L10N.NullString)
            end
        end

    end
    if bShow then
        local l10nMessage = L10N:FormatFromTable(UITextDef.LOBBY_CAPTAIN_HINT_FOUR_ITEMS, tbResult)
        l10nMessage = L10N:Format(UITextDef.LOBBY_CAPTAIN_HINT_BASIC_AFFECT_ARMOR, l10nMessage)
        ShowToast(l10nMessage)
    end
end


local function TryToToastShowSingleFashionOverlay(nItemTemplateId, tbExtraData)
    local tbItemTemplate = ItemSystem:GetItemTemplate(nItemTemplateId)
    if #tbItemTemplate.tbOverlaySlots == 0 then
        return
    end
    local tbOverlay = {}
    for _, nSlotType in ipairs(tbItemTemplate.tbOverlaySlots) do
        tbOverlay[nSlotType] = true
    end
    local nSubCategory = tbItemTemplate.nSubCategory
    local nFashionType = tbItemTemplate.nFashionType
    local l10nName = tbItemTemplate.l10nName
    local tbList = {}
    local bShow = false
    for _, nSlotType in pairs(FashionSlotCategory) do
        if nSlotType ~= nSubCategory then
            if not tbOverlay[nSlotType] then
                table.insert(tbList, L10N.NullString)
            else
                local nFittingTemplateId = tbExtraData[nSlotType]
                if nFittingTemplateId and nSlotType ~= nSubCategory then
                    local tbFittingItemTemplate = ItemSystem:GetItemTemplate(nFittingTemplateId)
                    table.insert(tbList, L10N:Format(UITextDef.LOBBY_CAPTAIN_HINT_WORD_WITH_COMMA, tbFittingItemTemplate.l10nName))
                    bShow = true
                else
                    local tbItem = ItemSystem:GetEquipedFashionItem(nFashionType, nSlotType)
                    if tbItem then
                        table.insert(tbList, L10N:Format(UITextDef.LOBBY_CAPTAIN_HINT_WORD_WITH_COMMA, tbItem:GetName()))
                        bShow = true
                    else
                        table.insert(tbList, L10N.NullString)
                    end
                end
            end
        end
    end


    if bShow then
        local  l10nNameBeOverlay = L10N:FormatFromTable(UITextDef.LOBBY_CAPTAIN_HINT_THREE_ITEMS, tbList)
        ShowToast(L10N:Format(UITextDef.LOBBY_CAPTAIN_HINT_TO_OVERLAY, l10nName, l10nNameBeOverlay))
    end
end

local function ShowSuitToast(nTemplateId, tbExtraData)
    local tbItemTemplate = ItemSystem:GetItemTemplate(nTemplateId)
    if ItemSystem:HasFashionItem(nTemplateId) then
        ShowToast(L10N:Format(UITextDef.LOBBY_CAPTAIN_HINT_WEAR_SUIT, tbItemTemplate.l10nName))
    end
    for _, nItemTemplateId in ipairs(tbItemTemplate.tbSubItemTemplateIds) do
        TryToToastShowSingleFashionOverlay(nItemTemplateId, tbExtraData)
    end
end


local function ShowFashionToast(nItemTemplateId, tbExtraData)
    local tbItemTemplate = ItemSystem:GetItemTemplate(nItemTemplateId)
    local nSlotType = tbItemTemplate.nSubCategory
    local nFashionType = tbItemTemplate.nFashionType
    local l10nName = tbItemTemplate.l10nName
    local l10nNameOverlay
    local tbSlotState = {}
    for _, nTemplateId in pairs(tbExtraData) do
        tbItemTemplate = ItemSystem:GetItemTemplate(nTemplateId)
        if tbItemTemplate.nSubCategory ~= nSlotType then
            tbSlotState[tbItemTemplate.nSubCategory] = true
            for _, nOverlaySlot in ipairs(tbItemTemplate.tbOverlaySlots) do
                if nOverlaySlot == nSlotType then
                    l10nNameOverlay = tbItemTemplate.l10nName
                    break
                end
            end
        end
    end
    if not l10nNameOverlay then
        for _, nTempSlotType in pairs(FashionSlotCategory) do
            if nTempSlotType ~= nSlotType and not tbSlotState[nTempSlotType] then
                local tbItem = ItemSystem:GetEquipedFashionItem(nFashionType, nTempSlotType)
                if tbItem then
                    local tbTemplate = tbItem:GetTemplate()
                    local tbOverlaySlot = tbTemplate.tbOverlaySlots
                    for _, nOverlaySlot in ipairs(tbOverlaySlot) do
                        if nOverlaySlot == nSlotType then
                            l10nNameOverlay = tbTemplate.l10nName
                            break
                        end
                    end
                end
            end
        end
    end

    if l10nNameOverlay then
        ShowToast(L10N:Format(UITextDef.LOBBY_CAPTAIN_HINT_BE_OVERLAY, l10nNameOverlay,l10nName))
    else
        TryToToastShowSingleFashionOverlay(nItemTemplateId, tbExtraData)
    end

end

local function TryToToastUnownedFashion(nItemTemplateId)
    local bOwned, _ = ItemSystem:HasFashionItem(nItemTemplateId)
    if not bOwned then
        ShowToast(UITextDef.LOBBY_CAPTAIN_HINT_FITTING)
    end
end

function LobbyCaptainHumanFashionToastOperator:OnPickItem(nItemTemplateId, tbExtraData)
    local tbItemTemplate = ItemSystem:GetItemTemplate(nItemTemplateId)
    local nCategory = tbItemTemplate.nCategory
    if nCategory ~= ItemCategoryDef.FASHION and 
        nCategory ~= ItemCategoryDef.SUIT then
            return
    end

    if ItemSystem:IsEquipedFashionItem(nItemTemplateId) then
        return
    end

    if tbItemTemplate.nFashionType == FashionType.Basic then
        TryToToastBasicAffectArmor(nItemTemplateId)
    end

    TryToToastUnownedFashion(nItemTemplateId)

    if nCategory == ItemCategoryDef.SUIT then
        ShowSuitToast(nItemTemplateId, tbExtraData)
    elseif nCategory == ItemCategoryDef.FASHION then
        ShowFashionToast(nItemTemplateId, tbExtraData)
    end
end

function LobbyCaptainHumanFashionToastOperator:OnFlagChanged(nFashionType)
    local bOverride = IsOverrideByBasic(nFashionType)
    if bOverride then
        local l10nText = L10N:Format(UITextDef.LOBBY_CAPTAIN_HINT_USING_BASIC, FASHION_ARMOR_NAME[nFashionType])
        ShowToast(l10nText)
    end
end



function LobbyCaptainHumanFashionToastOperator:Init()
end

function LobbyCaptainHumanFashionToastOperator:Uninit()
end


return LobbyCaptainHumanFashionToastOperator