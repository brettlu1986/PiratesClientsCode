-----------------------------------------------------
--File Name    : LobbyCaptainHumanFashionDataOperator.lua
--Description  :
-----------------------------------------------------

local luaclass = require("luaclass")
local LobbyCaptainDataOperator = require("LobbyCaptainDataOperator")
local LobbyCaptainHumanFashionDataOperator = luaclass("LobbyCaptainHumanFashionDataOperator", LobbyCaptainDataOperator)

local ItemSystem = require("ItemSystem")
local ItemCategoryDef = require("ItemCategoryDef")
local EventManager = require("EventManager")
local ClientEventDef = require("ClientEventDef")
local HumanAvatarDef = require("HumanAvatarDef")


--{FashionType : {FashionSlotCategory : ItemTemplateId}}
LobbyCaptainHumanFashionDataOperator.tbCurrentData = nil

local FashionSlotCategory = HumanAvatarDef.FashionSlotCategory

local function GetCurrentData(self)
    local tbData = self.tbCurrentData
    if not tbData then
        tbData = {}
        self.tbCurrentData = tbData
    end
    return tbData
end

local function CheckOwned(nItemTemplateId)
    local bResult, tbResult = ItemSystem:HasFashionItem(nItemTemplateId)
    return bResult, tbResult
end

local function RequestToTakeOffItem(tbItems)
    local tbInstanceIds = {}
    for _, tbItem in ipairs(tbItems) do
        table.insert(tbInstanceIds, tbItem:GetInstanceId())
    end
    ItemSystem:RequestToFitFashion({}, tbInstanceIds)
end

local function UnfittingSingleFashion(self, nItemTemplateId, tbItemTemplate)
    local nFashionType =  tbItemTemplate.nFashionType
    local tbFashionData = self:GetFashionData(nFashionType)
    local nSlotCategory = tbItemTemplate.nSubCategory
    tbFashionData[nSlotCategory] = nil
end

local function RequestToPutOnItem(tbPutOnItems, tbTakeOffItems)
    local tbTakeOffInstanceIds = {}
    if tbTakeOffItems then
        for _, tbItem in ipairs(tbTakeOffItems) do
            table.insert(tbTakeOffInstanceIds, tbItem:GetInstanceId())
        end
    end

    local tbInstanceIds = {}
    for _, tbItem in ipairs(tbPutOnItems) do
        local nInstanceId = tbItem:GetInstanceId()
        local bEquiped = ItemSystem:IsEquiped(nInstanceId)
        if not bEquiped then
            table.insert(tbInstanceIds, nInstanceId)
        end
    end
    ItemSystem:RequestToFitFashion(tbInstanceIds, tbTakeOffInstanceIds)
end

local function FittingSingleFashion(self, nItemTemplateId, tbItemTemplate)
    local nFashionType =  tbItemTemplate.nFashionType
    local tbFashionData = self:GetFashionData(nFashionType)
    local nSlotCategory = tbItemTemplate.nSubCategory
    tbFashionData[nSlotCategory] = nItemTemplateId
end


local function ProcessOnPickSuit(self, nItemTemplateId, tbItemTemplate)
    local bOwned, tbItems = CheckOwned(nItemTemplateId)
    if bOwned then
        local bEquiped = true
        for _, tbItem in pairs(tbItems) do
            local nInstanceId = tbItem:GetInstanceId()
            if not ItemSystem:IsEquiped(nInstanceId) then
                bEquiped = false
                break
            end
        end
        if bEquiped then
            local tbSubItemTemplateIds = tbItemTemplate.tbSubItemTemplateIds
            for _, nSubItemTemplateId in ipairs(tbSubItemTemplateIds) do
                local tbSubItemTemplate = ItemSystem:GetItemTemplate(nSubItemTemplateId)
                UnfittingSingleFashion(self, nSubItemTemplateId, tbSubItemTemplate)
            end
            EventManager:OnFireEvent(ClientEventDef.EV_LOBBY_CAPTAIN_FITTING_AVATAR_ITEM, nItemTemplateId, tbItemTemplate)
        else
            RequestToPutOnItem(tbItems)
        end
    else
        local tbSubItemTemplateIds = tbItemTemplate.tbSubItemTemplateIds
        for _, nSubItemTemplateId in ipairs(tbSubItemTemplateIds) do
            local tbSubItemTemplate = ItemSystem:GetItemTemplate(nSubItemTemplateId)
            FittingSingleFashion(self, nSubItemTemplateId, tbSubItemTemplate)
        end
        EventManager:OnFireEvent(ClientEventDef.EV_LOBBY_CAPTAIN_FITTING_AVATAR_ITEM, nItemTemplateId, tbItemTemplate)
    end
end

local function ProcessOnPickSingleFashion(self, nItemTemplateId, tbItemTemplate)
    local bOwned, tbItems = CheckOwned(nItemTemplateId)
    if bOwned then
        local tbItem = tbItems[1]
        local nInstanceId = tbItem:GetInstanceId()
        if ItemSystem:IsEquiped(nInstanceId) then
            UnfittingSingleFashion(self, nItemTemplateId, tbItemTemplate)
            EventManager:OnFireEvent(ClientEventDef.EV_LOBBY_CAPTAIN_FITTING_AVATAR_ITEM, nItemTemplateId, tbItemTemplate)
        else
            RequestToPutOnItem(tbItems)
        end
    else
        FittingSingleFashion(self, nItemTemplateId, tbItemTemplate)
        EventManager:OnFireEvent(ClientEventDef.EV_LOBBY_CAPTAIN_FITTING_AVATAR_ITEM, nItemTemplateId, tbItemTemplate)
    end
end



local function ProcessOnUnpickSingleFashion(self, nItemTemplateId, tbItemTemplate)
    local bOwned, tbItems = CheckOwned(nItemTemplateId)
    if bOwned then
        RequestToTakeOffItem(tbItems)
    else
        UnfittingSingleFashion(self, nItemTemplateId, tbItemTemplate)
        EventManager:OnFireEvent(ClientEventDef.EV_LOBBY_CAPTAIN_UNFITTING_AVATAR_ITEM, nItemTemplateId, tbItemTemplate)
    end
end

local function ProcessOnUnpickSuit(self, nItemTemplateId, tbItemTemplate)
    local bOwned, tbItems = CheckOwned(nItemTemplateId)
    if bOwned then
        RequestToTakeOffItem(tbItems)
    else
        local tbSubItemTemplateIds = tbItemTemplate.tbSubItemTemplateIds
        for _, nSubItemTemplateId in ipairs(tbSubItemTemplateIds) do
            local tbSubItemTemplate = ItemSystem:GetItemTemplate(nSubItemTemplateId)
            UnfittingSingleFashion(self, nSubItemTemplateId, tbSubItemTemplate)
        end
        EventManager:OnFireEvent(ClientEventDef.EV_LOBBY_CAPTAIN_UNFITTING_AVATAR_ITEM, nItemTemplateId, tbItemTemplate)
    end
end

local function FireSelectItemEvent(self, tbItem)
    EventManager:OnFireEvent(ClientEventDef.EV_SELECT_LOBBY_ITEM, tbItem:GetInstanceId())
end


function LobbyCaptainHumanFashionDataOperator:ProcessOnPickItem(nItemTemplateId)
    local tbItemTemplate = ItemSystem:GetItemTemplate(nItemTemplateId)
    if tbItemTemplate.nCategory == ItemCategoryDef.SUIT then
        ProcessOnPickSuit(self, nItemTemplateId, tbItemTemplate)
        local bHas, tbItems = ItemSystem:HasFashionItem(nItemTemplateId)
        if bHas then
            for _, tbItem in ipairs(tbItems) do
                FireSelectItemEvent(self, tbItem)
            end
        end
    elseif tbItemTemplate.nCategory == ItemCategoryDef.FASHION then
        ProcessOnPickSingleFashion(self, nItemTemplateId, tbItemTemplate)
        local tbItems = ItemSystem:GetItemsByTemplateId(nItemTemplateId)
        if tbItems and #tbItems > 0 then
            FireSelectItemEvent(self, tbItems[1])
        end
    else
        logerror("LobbyCaptainHumanFashionDataOperator:ProcessOnPickItem item category does not match! id : ", nItemTemplateId)
    end
end

function LobbyCaptainHumanFashionDataOperator:ProcessOnUnpickItem(nItemTemplateId)
    local tbItemTemplate = ItemSystem:GetItemTemplate(nItemTemplateId)
    if tbItemTemplate.nCategory == ItemCategoryDef.SUIT then
        ProcessOnUnpickSuit(self, nItemTemplateId, tbItemTemplate)
    elseif tbItemTemplate.nCategory == ItemCategoryDef.FASHION then
        ProcessOnUnpickSingleFashion(self, nItemTemplateId, tbItemTemplate)
    else
        logerror("LobbyCaptainHumanFashionDataOperator:ProcessOnPickItem item category does not match! id : ", nItemTemplateId)
    end
end

function LobbyCaptainHumanFashionDataOperator:GetFashionData(nFashionType)
    local tbData = GetCurrentData(self)
    local tbResult = tbData[nFashionType]
    if not tbResult then
        tbResult = {}
        tbData[nFashionType] = tbResult
    end
    return tbResult
end

function LobbyCaptainHumanFashionDataOperator:ClearFashionData(nFashionType)
    local tbData = GetCurrentData(self)
    tbData[nFashionType] = {}
end

function LobbyCaptainHumanFashionDataOperator:ClearAllFashionData()
    self.tbCurrentData = {}
end


function LobbyCaptainHumanFashionDataOperator:OnFashionDoChanged(tbTakeOffInstanceIds, tbPutOnInstanceIds)
    for _, nInstanceId in ipairs(tbPutOnInstanceIds) do
        local tbItem = ItemSystem:GetItem(nInstanceId)
        local tbTemplate = tbItem:GetTemplate()
        local nFashionType = tbTemplate.nFashionType
        local nSlotCategory = tbTemplate.nSubCategory
        local tbData = self:GetFashionData(nFashionType)
        tbData[nSlotCategory] = nil
    end
end

function LobbyCaptainHumanFashionDataOperator:FindSuitComposed(nFashionType)
    local tbFashionData = self:GetFashionData(nFashionType)
    local tbSuitId = {}
    for _, nSlotType in pairs(FashionSlotCategory) do
        local nTemplateId = tbFashionData[nSlotType]
        local tbTemplate
        if nTemplateId then
            tbTemplate = ItemSystem:GetItemTemplate(nTemplateId)
        else
            local tbItem = ItemSystem:GetEquipedFashionItem(nFashionType, nSlotType)
            if tbItem then
                tbTemplate = tbItem:GetTemplate()
            end
        end
        if tbTemplate then
            local nSuitId = tbTemplate.nSuitId
            if nSuitId then
                local tb = tbSuitId[nSuitId]
                if not tb then
                    tb = {}
                    tbSuitId[nSuitId] = tb
                end
                table.insert(tb, tbTemplate.nId)
            end
        end
    end
    local nResultSuitTemplateId
    for nSuitTemplateId, tbData in pairs(tbSuitId) do
        local tbSuitTemplate = ItemSystem:GetItemTemplate(nSuitTemplateId)
        if #tbSuitTemplate.tbSubItemTemplateIds == #tbData then
            nResultSuitTemplateId = nSuitTemplateId
            break
        end
    end
    return nResultSuitTemplateId
end


return LobbyCaptainHumanFashionDataOperator