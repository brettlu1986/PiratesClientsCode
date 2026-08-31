-----------------------------------------------------
--File Name    : ShipItemOperationHelper.lua
--Author       : Xu Weihua
--Create Time  : 2018-09-07
--Description  : Ship item category behaviour helper.
-----------------------------------------------------


local luaclass = require("luaclass")
local ItemCategoryOperationHelperBase = require("ItemCategoryOperationHelperBase")
local ShipItemOperationHelper = luaclass("ShipItemOperationHelper", ItemCategoryOperationHelperBase)
local BattleItemDataTable = require("BattleItemDataTable")
local ItemBuildingVerificationFailureDef = require("ItemBuildingVerificationFailureDef")
local GameObjectSystem = dynamic_require("GameObjectSystem")
local ShipGradeDataTable = require("ShipGradeDataTable")
local BattleItemSystemHelper = require("BattleItemSystemHelper")
local BattleItemCategoryDef = require("BattleItemCategoryDef")

ShipItemOperationHelper.nMaxSlot = 1

--------------------------------------------------------------------------------------------------------------

function ShipItemOperationHelper:CheckItemSlotCompatibility(nCharacterInstanceId, nOwnerItemInstanceId, nSlotIndex, tbShip, bIsClient)
    return nSlotIndex == 1
end

-- 是否可以自动拾取
function ShipItemOperationHelper:CanAutoPickUpOnClient(tbItemObject)
    return false, false
end

-- 是否可以手动拾取
function ShipItemOperationHelper:CanManuallyPickUpOnClient(tbItemObject)
    return true
end

-- 获得装配的位置(客户端方法)
function ShipItemOperationHelper:GetAvailableEquipmentSlotForItemOnClient(nItemTemplateId, bNeedEmptySlot)
    local nCharacterInstanceId = self:GetPlayerServerInstanceIdOnClient()
    return nCharacterInstanceId, 1
end

-- 获得装配的位置id(客户端方法)
function ShipItemOperationHelper:GetAvailableEquipmentSlotForItemWithOwnerOnClient(nOwnerInstanceId, nItemTemplateId, bNeedEmptySlot)
    return 1
end

-- 是否可以自动拾取（服务端方法，给机器人AI使用）
function ShipItemOperationHelper:CanAutoPickUpOnServer(nCharacterInstanceId, Item)
    return false
end

-- 获得装配的位置（服务端方法）
function ShipItemOperationHelper:GetAvailableEquipmentSlotForItemOnServer(nCharacterInstanceId, nItemTemplateId, bNeedEmptySlot)
    return nCharacterInstanceId, 1
end

-- 获得装配的位置id（服务端方法）
function ShipItemOperationHelper:GetAvailableEquipmentSlotForItemWithOwnerOnServer(nCharacterInstanceId, nOwnerInstanceId, nItemTemplateId, bNeedEmptySlot)
    return 1
end

local function FillFailures(nFailureType)
    local tbFailure = {}
    tbFailure.nType = nFailureType
    tbFailure.Params = nil
    local tbFailures = {}
    table.insert(tbFailures, tbFailure)
    return tbFailures
end

local function VerifyCustomBuildingConditions(tbPlayer, nItemTemplateId, bIsClient)
    -- Get the current ship building level of the self player.
    local nCharacterInstanceId = tbPlayer:GetServerInstanceId()

    local ActiveShipItem = BattleItemSystemHelper:GetEquippedItem(
        nCharacterInstanceId, BattleItemCategoryDef.SHIP, nCharacterInstanceId, 1, bIsClient)

    if ActiveShipItem ~= nil then
        if ActiveShipItem:GetTemplateId() == nItemTemplateId then
            local tbFailures = FillFailures(ItemBuildingVerificationFailureDef.SAME_SHIP)
            return false, tbFailures
        end
    end

    local nCurBuiltGrade = BattleItemSystemHelper:GetShipBuiltGrade(nCharacterInstanceId, bIsClient)
    local nMaxGrade = ShipGradeDataTable:GetMaxGrade()
    local nNextBuildLevel = nCurBuiltGrade + 1
    if nNextBuildLevel > nMaxGrade then
        nNextBuildLevel = nMaxGrade
    end
    -- Get the necessary building level of the ship item and compare it against the player's building level.
    local nBuildingLevel = BattleItemDataTable:GetTemplate(nItemTemplateId).nBuildingLevel
    if nNextBuildLevel < nBuildingLevel then
        local tbFailures = FillFailures(ItemBuildingVerificationFailureDef.INACCEPTABLE_PLAYER_SHIP_BUILDING_LEVEL)
        return false, tbFailures
    end

    return true, nil
end

function ShipItemOperationHelper:VerifyCustomBuildingConditionsOnClient(nItemTemplateId, _)
    local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
    local PlayerSelf = GamePlayerSelfHelper:Get()
    return VerifyCustomBuildingConditions(PlayerSelf, nItemTemplateId, true)
end

function ShipItemOperationHelper:VerifyCustomBuildingConditionsOnServer(nCharacterInstanceId, nItemTemplateId, _)
    local tbPlayer = GameObjectSystem:FindByInstanceId(nCharacterInstanceId)
    return VerifyCustomBuildingConditions(tbPlayer, nItemTemplateId, false)
end


return ShipItemOperationHelper