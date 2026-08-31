-----------------------------------------------------
--File Name    : GameTestAutomationBattleDataHelper.lua
--Author       : WuJizhou
--Create Time  : 9/6/2019, 5:47:22 PM
--Description  : GameTestAutomationBattleDataHelper
-----------------------------------------------------
local Proto                         = require("ClientProtoNames")
local ItemSystem                    = require("ItemSystem")
local ItemDataTable                 = require("ItemDataTable")
local ItemCategoryDef               = require("ItemCategoryDef")
local GameTestAutomationLogHelper   = require("GameTestAutomationLogHelper")

local NetworkManager    = dynamic_require("NetworkManager")

local GameTestAutomationBattleDataHelper = {}

local INVALID_INSTANCE_ID = -1

local tbAllCandidates = {}
local tbCandidatesIndices = {}


local function GetItemInstanceId(nTemplateId)
    local tbItems = ItemSystem:GetItemsByTemplateId(nTemplateId)
    if tbItems and (#tbItems > 0) then
        return tbItems[1]:GetInstanceId()
    end
    return INVALID_INSTANCE_ID
end

local function GMAddItems(tbTemplateIds)
    local szParam = ""
    for _, nTemplateId in ipairs(tbTemplateIds) do
        szParam =   szParam .. " ".. nTemplateId .. " 1"
    end
    local szGM = "gm multi-add-item"
    szGM = szGM .. szParam
    KismetSystemLibrary.ExecuteConsoleCommand(GWorld, szGM, nil)
end

local function RequestToAddItems(nCategory)
    local tbTemplates = ItemDataTable:GetTemplatesByCategory(nCategory)
    local tbTemplateIds = {}
    for nTemplateId, tbTemplate in pairs(tbTemplates) do
        local nInstanceId = GetItemInstanceId(nTemplateId)
        if nInstanceId == INVALID_INSTANCE_ID then
            table.insert(tbTemplateIds, nTemplateId)
        end
    end
    GMAddItems(tbTemplateIds)
end

function GameTestAutomationBattleDataHelper:InitCandidateData(tbCategory)
    for _, nCategory in ipairs(tbCategory) do
        local tbTemplates = ItemDataTable:GetTemplatesByCategory(nCategory)
        local tbCandidates = tbAllCandidates[nCategory]
        if not tbCandidates then
            tbCandidates = {}
            tbAllCandidates[nCategory] = tbCandidates
        end

        for nTemplateId, tbTemplate in pairs(tbTemplates) do
            table.insert(tbCandidates, nTemplateId)
        end
        local nCount = #tbCandidates
        tbCandidatesIndices[nCategory] = math.random(1, nCount)
    end
end

-- return templateid
function GameTestAutomationBattleDataHelper:PickUpItemForBattle(nCategory)
    local tbCandidates = tbAllCandidates[nCategory]
    local nCurrentIdx = tbCandidatesIndices[nCategory]
    -- for _, v in ipairs(tbCandidates) do
    --     GameTestAutomationLogHelper.LogDebug(nCategory, v)
    -- end
    GameTestAutomationLogHelper.LogDebug(nCategory, "nCurrentIdx", nCurrentIdx, "total count", #tbCandidates)
    nCurrentIdx = nCurrentIdx + 1
    if nCurrentIdx > #tbCandidates then
        nCurrentIdx = 1
    end
    tbCandidatesIndices[nCategory] = nCurrentIdx
    return tbCandidates[nCurrentIdx]
end


function GameTestAutomationBattleDataHelper:RequestToEquipShip(nTemplateId, nSlotId)
    local nInstanceId = GetItemInstanceId(nTemplateId)
    local c2s_EquipShip = {
        ship_instance_id = nInstanceId,
        slot_id = nSlotId
    }
    GameTestAutomationLogHelper.LogDebug("RequestToEquipShip", nInstanceId, nTemplateId)
    NetworkManager:GetHubServerProxy():SendPacket(Proto.c2s_EquipShip, c2s_EquipShip)
end

function GameTestAutomationBattleDataHelper:RequestToEquipShipWeapon(nTemplateId)
    local nInstanceId = GetItemInstanceId(nTemplateId)
    local c2s_ChooseShipWeapon = {
        ship_weapon_instance_id = nInstanceId
    }
    GameTestAutomationLogHelper.LogDebug("RequestToEquipShipWeapon", nInstanceId, nTemplateId)
    NetworkManager:GetHubServerProxy():SendPacket(Proto.c2s_ChooseShipWeapon, c2s_ChooseShipWeapon)
end

function GameTestAutomationBattleDataHelper:RequestToEquipShipPart(nTemplateId)
    local nInstanceId = GetItemInstanceId(nTemplateId)
    local c2s_ChooseShipPart = {
        ship_part_instance_id = nInstanceId
    }
    GameTestAutomationLogHelper.LogDebug("RequestToEquipShipPart", nInstanceId, nTemplateId)
    NetworkManager:GetHubServerProxy():SendPacket(Proto.c2s_ChooseShipPart, c2s_ChooseShipPart)
end

function GameTestAutomationBattleDataHelper:RequestToAddAllShips()
    RequestToAddItems(ItemCategoryDef.SHIP)
end

function GameTestAutomationBattleDataHelper:RequestToAddAllShipWeapons()
    RequestToAddItems(ItemCategoryDef.SHIP_WEAPON)
end

function GameTestAutomationBattleDataHelper:RequestToAddAllShipParts()
    RequestToAddItems(ItemCategoryDef.SHIP_PART)
end

-- 返回本场战斗中需要建造的目标船，以及前置船，即本局战斗就按照这条线路来建造
function GameTestAutomationBattleDataHelper:GetThisBattleShipTemplateId()
    local tbCandidates = tbAllCandidates[ItemCategoryDef.SHIP]
    local nCurrentIdx = tbCandidatesIndices[ItemCategoryDef.SHIP]
    if tbCandidates then
        local nShipTemplateId = tbCandidates[nCurrentIdx]
        return nShipTemplateId
    end
end


function GameTestAutomationBattleDataHelper:GetThisBattleShipWeaponTemplateId()
    local tbCandidates = tbAllCandidates[ItemCategoryDef.SHIP_WEAPON]
    if tbCandidates then
        local nCurrentIdx = tbCandidatesIndices[ItemCategoryDef.SHIP_WEAPON]
        return tbCandidates[nCurrentIdx]
    end
end

return GameTestAutomationBattleDataHelper