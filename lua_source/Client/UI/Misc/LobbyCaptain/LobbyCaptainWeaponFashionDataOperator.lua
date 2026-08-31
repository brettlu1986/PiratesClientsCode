-----------------------------------------------------
--File Name    : LobbyCaptainWeaponFashionDataOperator.lua
--Description  :
-----------------------------------------------------

local luaclass = require("luaclass")
local LobbyCaptainDataOperator = require("LobbyCaptainDataOperator")
local LobbyCaptainWeaponFashionDataOperator = luaclass("LobbyCaptainWeaponFashionDataOperator", LobbyCaptainDataOperator)

local ItemSystem = require("ItemSystem")
local ItemCategoryDef = require("ItemCategoryDef")
local EventManager = require("EventManager")
local ClientEventDef = require("ClientEventDef")

-- {WeaponInstanceType : Template Id}
LobbyCaptainWeaponFashionDataOperator.tbCurrentData = {}

local function GetCurrentData(self)
    local tbData = self.tbCurrentData
    if not tbData then
        tbData = {}
        self.tbCurrentData = tbData
    end
    return tbData
end

local function CheckOwned(nItemTemplateId)
    local tbItems = ItemSystem:GetItemsByTemplateId(nItemTemplateId)
    local bResult = #tbItems > 0
    return bResult, tbItems
end

local function RequestToTakeOffItem(tbItems)
    local tbInstanceIds = {}
    for _, tbItem in ipairs(tbItems) do
        table.insert(tbInstanceIds, tbItem:GetInstanceId())
    end
    ItemSystem:RequestToFitFashion({}, tbInstanceIds)
end

local function UnfittingSingleFashion(self, nItemTemplateId, tbItemTemplate)
    local nWeaponInstanceType =  tbItemTemplate.nSubCategory
    local tbFashionData = GetCurrentData(self)
    tbFashionData[nWeaponInstanceType] = nil
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
    local nWeaponInstanceType =  tbItemTemplate.nSubCategory
    local tbFashionData = GetCurrentData(self)
    tbFashionData[nWeaponInstanceType] = nItemTemplateId
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

local function FireSelectItemEvent(self, tbItem)
    EventManager:OnFireEvent(ClientEventDef.EV_SELECT_LOBBY_ITEM, tbItem:GetInstanceId())
end

function LobbyCaptainWeaponFashionDataOperator:ProcessOnPickItem(nItemTemplateId)
    local tbItemTemplate = ItemSystem:GetItemTemplate(nItemTemplateId)
    if tbItemTemplate.nCategory == ItemCategoryDef.HUMAN_WEAPON_FASHION then
        ProcessOnPickSingleFashion(self, nItemTemplateId, tbItemTemplate)
        local tbItems = ItemSystem:GetItemsByTemplateId(nItemTemplateId)
        if tbItems and #tbItems > 0 then
            FireSelectItemEvent(self, tbItems[1])
        end
    else
        logerror("LobbyCaptainWeaponFashionDataOperator:ProcessOnPickItem item category does not match! id : ", nItemTemplateId)
    end
end

function LobbyCaptainWeaponFashionDataOperator:ProcessOnUnpickItem(nItemTemplateId)
    local tbItemTemplate = ItemSystem:GetItemTemplate(nItemTemplateId)
    if tbItemTemplate.nCategory == ItemCategoryDef.HUMAN_WEAPON_FASHION then
        ProcessOnUnpickSingleFashion(self, nItemTemplateId, tbItemTemplate)
    else
        logerror("LobbyCaptainWeaponFashionDataOperator:ProcessOnUnpickItem item category does not match! id : ", nItemTemplateId)
    end
end


function LobbyCaptainWeaponFashionDataOperator:ClearFashionData(nWeaponInstanceType)
    local tbData = GetCurrentData(self)
    tbData[nWeaponInstanceType] = nil
end

function LobbyCaptainWeaponFashionDataOperator:ClearAllFashionData()
    self.tbCurrentData = {}
end

function LobbyCaptainWeaponFashionDataOperator:GetFashionData(nWeaponInstanceType)
    local tbData = GetCurrentData(self)
    return tbData[nWeaponInstanceType]
end

function LobbyCaptainWeaponFashionDataOperator:OnFashionDoChanged(tbTakeOffInstanceIds, tbPutOnInstanceIds)
    for _, nInstanceId in ipairs(tbPutOnInstanceIds) do
        local tbItem = ItemSystem:GetItem(nInstanceId)
        local tbTemplate = tbItem:GetTemplate()
        local nWeaponInstanceType = tbTemplate.nSubCategory
        self:ClearFashionData(nWeaponInstanceType)
    end
end

return LobbyCaptainWeaponFashionDataOperator