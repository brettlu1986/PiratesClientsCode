-----------------------------------------------------
--File Name    : BattleTestAutomationAIShipDataProvider.lua
--Author       : WuJizhou
--Create Time  : 8/30/2019, 3:41:00 PM
--Description  : BattleTestAutomationAIShipDataProvider
-----------------------------------------------------


local ItemDataTable            = require("ItemDataTable")
local ItemCategoryDef          = require("ItemCategoryDef")
local BattleItemDataTable      = require("BattleItemDataTable")
local CheckCanBuildItemHelper  = require("CheckCanBuildItemHelper")
local BattleItemBuildDataTable = require("BattleItemBuildDataTable")

local BattleTestAutomationAIShipDataProvider = {}

BattleTestAutomationAIShipDataProvider.tbWeaponTemplateIds = {}
BattleTestAutomationAIShipDataProvider.tbPartTemplateIds = {}
BattleTestAutomationAIShipDataProvider.tbShipTemplateIds = {}


local function ParseLobbyShipToBattleShip(tbLobbyShipTemplateIds)
    local tbResult = {}
    for _, v in pairs(tbLobbyShipTemplateIds) do
        local tbLobbyItemTemplate = ItemDataTable:GetTemplate(v)
        if tbLobbyItemTemplate.nCategory == ItemCategoryDef.SHIP then
            local nBattleItemTemplateId = tbLobbyItemTemplate.nBattleItemId
            table.insert(tbResult, nBattleItemTemplateId)
        end
    end
    return tbResult
end

local function ParseLobbyShipPartToBattleShipPart(tbLobbyShipPartTemplateIds)
    local tbResult = {}
    for _, nPreparationItemTemplateId in pairs(tbLobbyShipPartTemplateIds) do
        local tbLobbyItemTemplate = ItemDataTable:GetTemplate(nPreparationItemTemplateId)
        if tbLobbyItemTemplate.nCategory == ItemCategoryDef.SHIP_PART then
            local tbBattleItemIdList = tbLobbyItemTemplate.tbBattleItemIdList
            for _, nBattleItemTemplateId in pairs(tbBattleItemIdList) do
                table.insert(tbResult, nBattleItemTemplateId)
            end
        end
    end
    return tbResult
end

local function ParseLobbyShipWeaponToBattleShipWeapon(tbLobbyShipWeaponTemplateIds)
    local tbResult = {}
    for _, nPreparationItemTemplateId in pairs(tbLobbyShipWeaponTemplateIds) do
        local tbLobbyItemTemplate = ItemDataTable:GetTemplate(nPreparationItemTemplateId)
        if tbLobbyItemTemplate.nCategory == ItemCategoryDef.SHIP_WEAPON then
            local nBattleItemTemplateId = tbLobbyItemTemplate.nBattleItemId
            table.insert(tbResult, nBattleItemTemplateId)
        end
    end
    return tbResult
end

function BattleTestAutomationAIShipDataProvider.GetCanBuildShipWeaponItemTemplateIdsOnSlot(nCharacterInstanceId, nSlotIndex, _bIsClient)
    return  CheckCanBuildItemHelper.GetCanBuildShipWeaponItemTemplateIdsOnSlot(nCharacterInstanceId, nSlotIndex, false)
end

function BattleTestAutomationAIShipDataProvider.GetCanBuildShipPartItemTemplateIds(nCharacterInstanceId, _bIsClient)
    return CheckCanBuildItemHelper.GetCanBuildShipPartItemTemplateIds(nCharacterInstanceId, false)
end

function BattleTestAutomationAIShipDataProvider.GetCanBuildShipItemTemplateIds(nCharacterInstanceId, _bIsClient)
    local tbShipTemplateIds = BattleTestAutomationAIShipDataProvider.tbShipTemplateIds[nCharacterInstanceId]
    local tbResult = CheckCanBuildItemHelper.GetCanBuildShipItemTemplateIds(nCharacterInstanceId, false)
    if tbShipTemplateIds then  -- 根据目标舰船对正常候选船进行筛选
        local tbGradeMap = {}
        local nMaxCandidateGrade = 1
        for _, nShipTemplateId in ipairs(tbShipTemplateIds) do
            local tbItemTemplate = BattleItemDataTable:GetTemplate(nShipTemplateId)
            tbGradeMap[tbItemTemplate.nGrade] = nShipTemplateId
            if tbItemTemplate.nGrade > nMaxCandidateGrade then
                nMaxCandidateGrade = tbItemTemplate.nGrade  --设置目标舰船的最大等级
            end
        end
        local tbTemp = {}
        for _, nTemplateId in ipairs(tbResult) do
            local tbItemTemplate = BattleItemDataTable:GetTemplate(nTemplateId)
            local nGrade = tbItemTemplate.nGrade
            local nCandidateTemplateId = tbGradeMap[nGrade]

            if nGrade <= nMaxCandidateGrade and (not nCandidateTemplateId or nCandidateTemplateId == nTemplateId) then
                table.insert(tbTemp, nTemplateId)
            end
        end
        tbResult = tbTemp
    end
    return tbResult
end

function BattleTestAutomationAIShipDataProvider:GetBuildWeaponBlueprints(nCharacterInstanceId)
    local tbWeaponTemplateIds = self.tbWeaponTemplateIds[nCharacterInstanceId]
    local tbResult = {}
    if tbWeaponTemplateIds then
        for _, nItemTemplateId in ipairs(tbWeaponTemplateIds) do
            local tbBuildTemplate = BattleItemBuildDataTable:GetBuildTemplate(nItemTemplateId)
            local nBuildBpTemplateId = tbBuildTemplate.tbKeyItemIds[1]
            if nBuildBpTemplateId then
                table.insert(tbResult, nBuildBpTemplateId)
            end
        end
    end
    return tbResult
end
--设置本场战斗要使用的船的template id
function BattleTestAutomationAIShipDataProvider:SetShipTemplateIds(nPlayerInstanceId, tbLobbyShipTemplateIds)
    local tbTemplateIds = ParseLobbyShipToBattleShip(tbLobbyShipTemplateIds)
    self.tbShipTemplateIds[nPlayerInstanceId] = tbTemplateIds
end

function BattleTestAutomationAIShipDataProvider:SetShipPartTemplateIds(nPlayerInstanceId, tbLobbyShipPartTemplateIds)
    local tbTemplateIds = ParseLobbyShipPartToBattleShipPart(tbLobbyShipPartTemplateIds)
    self.tbPartTemplateIds[nPlayerInstanceId] = tbTemplateIds
end

function BattleTestAutomationAIShipDataProvider:SetShipWeaponTemplateIds(nPlayerInstanceId, tbLobbyShipWeaponTemplateIds)
    local tbTemplateIds = ParseLobbyShipWeaponToBattleShipWeapon(tbLobbyShipWeaponTemplateIds)
    self.tbWeaponTemplateIds[nPlayerInstanceId] = tbTemplateIds
end



function BattleTestAutomationAIShipDataProvider:Init()

end

function BattleTestAutomationAIShipDataProvider:Uninit()

end


return BattleTestAutomationAIShipDataProvider