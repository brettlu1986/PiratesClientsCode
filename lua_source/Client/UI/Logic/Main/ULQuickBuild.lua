-----------------------------------------------------
--File Name    : ULQuickBuild.lua
--Author       : zhiyuan
--Create Time  : 2019-03-20
--Description  : ffa主界面上快捷建造的ui逻辑
-----------------------------------------------------
local luaclass = require("luaclass")
local UILogicBase = require("UILogicBase")
local ULQuickBuild = luaclass("ULQuickBuild", UILogicBase)

local UIDef = require("UIDef")
local EventManager = require("EventManager")
local CommonEventDef = require("CommonEventDef")
local ClientEventDef = require("ClientEventDef")
local ShipItemHelper = require("ShipItemHelper")
local ShipPartTypeDef = require("ShipPartTypeDef")
local HumanWeaponHelper = require("HumanWeaponHelper")
local ShipWeaponSlotDef = require("ShipWeaponSlotDef")
local HumanArmorSlotDef = require("HumanArmorSlotDef")
local HumanWeaponSlotDef = require("HumanWeaponSlotDef")
local BattleItemDataTable = require("BattleItemDataTable")
local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
local BattleItemCategoryDef = require("BattleItemCategoryDef")
-- local BattleItemSystemHelper = require("BattleItemSystemHelper")
local BattleItemSystemClient = require("BattleItemSystemClient")
local CheckCanBuildItemHelper = require("CheckCanBuildItemHelper")
local BattleItemBuildDataTable = require("BattleItemBuildDataTable")
local ShipWeaponCategoryDataTable = require("ShipWeaponCategoryDataTable")

local QUICK_BUILD_MAX = 2
-- local SHIP_GRADE_ONE = 1
-- local SHIP_GRADE_TWO = 2

local SHIP_PART_MAX_GRADE = 3

local HUMAN_SLOT_INDEX = 1
local SHIP_SLOT_INDEX = 2

local DELAY_REFRESH_SECONDS = 0.5

ULQuickBuild.tbPbBuildItems = nil

ULQuickBuild.tbDelayCheckQuickBuildHandle = nil

local function Contains(tbList, element)
    if tbList == nil then
        return false
    end
    for _, v in ipairs(tbList) do
        if v == element then
            return true
        end
    end
    return false
end

local function FunSort(nItemTemplateIdA, nItemTemplateIdB)
    local tbBuildTemplateA = BattleItemBuildDataTable:GetBuildTemplate(nItemTemplateIdA)
    local tbBuildTemplateB = BattleItemBuildDataTable:GetBuildTemplate(nItemTemplateIdB)
    local nQuickBuildWeightA = tbBuildTemplateA.nQuickBuildWeight
    local nQuickBuildWeightB = tbBuildTemplateB.nQuickBuildWeight
    if nQuickBuildWeightA ~= nQuickBuildWeightB then
        return nQuickBuildWeightA > nQuickBuildWeightB
    end
    return nItemTemplateIdA > nItemTemplateIdB
end

-- local function FuncSortShipWeapon(WeaponTemplateA, WeaponTemplateB)
--     local nSubCategoryA = WeaponTemplateA.nSubCategory
--     local nSubCategoryB = WeaponTemplateB.nSubCategory
--     if nSubCategoryA ~= nSubCategoryB then
--         return nSubCategoryA < nSubCategoryB
--     end
--     return WeaponTemplateA.nId < WeaponTemplateB.nId
-- end

-- local function FillQuickBuildShipWhenNotReserved(tbItemTemplateIds)
--     local nCharacterInstanceId = GamePlayerSelfHelper:GetServerInstanceId()
--     local tbCanBuildShipTemplateIds = CheckCanBuildItemHelper.GetCanBuildShipItemTemplateIds(nCharacterInstanceId, true)
--     if tbCanBuildShipTemplateIds ~= nil and #tbCanBuildShipTemplateIds > 0 then
--         for _, v in ipairs(tbCanBuildShipTemplateIds) do
--             table.insert(tbItemTemplateIds, v)
--             if #tbItemTemplateIds >= QUICK_BUILD_MAX then
--                 break
--             end
--         end
--     end
-- end

-- local function FillQuickBuildShipWeaponWhenNotReserved(tbItemTemplateIds)
--     local nCharacterInstanceId = GamePlayerSelfHelper:GetServerInstanceId()
--     local tbCanBuildShipWeaponTemplates = {}
--     for i = ShipWeaponSlotDef.COMMON_START, ShipWeaponSlotDef.COMMON_END do
--         local tbWeaponItem = BattleItemSystemClient:GetEquippedItem(BattleItemCategoryDef.SHIP_WEAPON, nCharacterInstanceId, i)
--         if not tbWeaponItem then
--             local tbShipWeaponTemplateIds = CheckCanBuildItemHelper.GetCanBuildShipWeaponItemTemplateIdsOnSlot(nCharacterInstanceId, i, true)
--             for _, v in ipairs(tbShipWeaponTemplateIds) do
--                 local tbTemplate = BattleItemDataTable:GetTemplate(v)
--                 if not Contains(tbCanBuildShipWeaponTemplates, tbTemplate) then
--                     table.insert(tbCanBuildShipWeaponTemplates, tbTemplate)
--                 end
--             end
--         end
--     end
--     table.sort(tbCanBuildShipWeaponTemplates, FuncSortShipWeapon)
--     for _, v in ipairs(tbCanBuildShipWeaponTemplates) do
--         table.insert(tbItemTemplateIds, v.nId)
--         if #tbItemTemplateIds >= QUICK_BUILD_MAX then
--             break
--         end
--     end
-- end

-- local function FillQuickBuildShipPartWhenNotReserved(tbItemTemplateIds)
--     local nCharacterInstanceId = GamePlayerSelfHelper:GetServerInstanceId()
--     local tbEquippedParts = BattleItemSystemClient:GetEquippedItems(BattleItemCategoryDef.SHIP_PART, nCharacterInstanceId)
--     for nGrade = 1, SHIP_PART_MAX_GRADE do
--         local bAllGradeIsOk = true
--         for nSlot=1, ShipPartTypeDef.Max do
--             local EquippedItem = tbEquippedParts[nSlot]
--             if EquippedItem == nil or EquippedItem:GetGrade() < nGrade then
--                 bAllGradeIsOk = false
--                 local tbShipPartTemplateIds = CheckCanBuildItemHelper.GetCanBuildShipPartItemTemplateIdsOnSlot(nCharacterInstanceId, nSlot, true)
--                 for _, v in ipairs(tbShipPartTemplateIds) do
--                     local tbTemplate = BattleItemDataTable:GetTemplate(v)
--                     if tbTemplate.nGrade == nGrade then
--                         table.insert(tbItemTemplateIds, v)
--                         if #tbItemTemplateIds >= QUICK_BUILD_MAX then
--                             break
--                         end
--                     end
--                 end
--                 if #tbItemTemplateIds >= QUICK_BUILD_MAX then
--                     break
--                 end
--             end
--         end
--         if not bAllGradeIsOk then
--             break
--         end
--     end
-- end

-- local function FillQuickBuildHumanItemWhenNotReserved(tbItemTemplateIds, nCategory, nSlotCount)
--     local nCharacterInstanceId = GamePlayerSelfHelper:GetServerInstanceId()
--     for nSlotIndex = 1, nSlotCount do
--         local tbHumanWeaponItemTemplateIds = CheckCanBuildItemHelper.GetCanBuildHumanItemTemplateIdsOnSlot(nCharacterInstanceId, nCategory, nSlotIndex, true)
--         for _, v in ipairs(tbHumanWeaponItemTemplateIds) do
--             if not Contains(tbItemTemplateIds, v) then
--                 table.insert(tbItemTemplateIds, v)
--             end
--             if #tbItemTemplateIds >= QUICK_BUILD_MAX then
--                 break
--             end
--         end
--         if #tbItemTemplateIds >= QUICK_BUILD_MAX then
--             break
--         end
--     end
-- end

-- local function FillQuickBuildHumanWeaponWhenNotReserved(tbItemTemplateIds)
--     local nSlotCount = HumanWeaponSlotDef:SlotCount()
--     FillQuickBuildHumanItemWhenNotReserved(tbItemTemplateIds, BattleItemCategoryDef.HUMAN_WEAPON, nSlotCount)
-- end

-- local function FillQuickBuildHumanArmorWhenNotReserved(tbItemTemplateIds)
--     local nSlotCount = HumanArmorSlotDef:SlotCount()
--     FillQuickBuildHumanItemWhenNotReserved(tbItemTemplateIds, BattleItemCategoryDef.HUMAN_ARMOR, nSlotCount)
-- end

local function FillQuickBuildShipPartWhenReserved(tbItemTemplateIds, tbReservedItemTemplate)
    local nCharacterInstanceId = GamePlayerSelfHelper:GetServerInstanceId()
    local nReservedSubCategory = tbReservedItemTemplate.nSubCategory
    local nReservedGrade = tbReservedItemTemplate.nGrade
    local EquippedItem = BattleItemSystemClient:GetEquippedItem(BattleItemCategoryDef.SHIP_PART, nCharacterInstanceId, nReservedSubCategory)
    local nCurrentNeedGrade = 1
    if EquippedItem == nil then
        nCurrentNeedGrade = 1
    else
        local nEquippedGrade = EquippedItem:GetGrade()
        if nEquippedGrade < nReservedGrade then
            nCurrentNeedGrade = nEquippedGrade + 1
        else
            nCurrentNeedGrade = 1
        end
    end

    local tbShipPartTemplateIds = CheckCanBuildItemHelper.GetCanBuildShipPartItemTemplateIdsOnSlot(nCharacterInstanceId, nReservedSubCategory, true)
    for _, v in ipairs(tbShipPartTemplateIds) do
        local tbTemplate = BattleItemDataTable:GetTemplate(v)
        if tbTemplate.nGrade == nCurrentNeedGrade then
            table.insert(tbItemTemplateIds, v)
            if #tbItemTemplateIds >= QUICK_BUILD_MAX then
                break
            end
        end
    end
end

local function FillQuickBuildShipWhenReserved(tbItemTemplateIds, tbReservedItemTemplate)
    local nCharacterInstanceId = GamePlayerSelfHelper:GetServerInstanceId()
    local nReservedGrade = tbReservedItemTemplate.nGrade
    local nCurrentShipItemTemplateId = ShipItemHelper.GetCurrentShipItemTemplateIdOnClient()
    if nCurrentShipItemTemplateId == nil then
        return
    end
    local nNextBuildGrade = CheckCanBuildItemHelper.GetNextCanBuildShipGrade(nCharacterInstanceId, true)
    if nReservedGrade > nNextBuildGrade then
        local tbCanBuildShipTemplateIds = CheckCanBuildItemHelper.GetCanBuildShipItemTemplateIds(nCharacterInstanceId, true)
        for _, v in ipairs(tbCanBuildShipTemplateIds) do
            local tbTemplate = BattleItemDataTable:GetTemplate(v)
            if tbTemplate.nGrade == nNextBuildGrade then
                table.insert(tbItemTemplateIds, v)
                if #tbItemTemplateIds >= QUICK_BUILD_MAX then
                    break
                end
            end
        end
    end
end

local function FillQuickBuildHumanWeaponWhenReserved(tbItemTemplateIds, tbReservedItemTemplate)
    local nCharacterInstanceId = GamePlayerSelfHelper:GetServerInstanceId()
    local nReservedGrade = tbReservedItemTemplate.nGrade
    local nReservedItemTemplateId = tbReservedItemTemplate.nId
    local tbMatchedSlots = HumanWeaponHelper.GetMatchedSlotIndexes(nReservedItemTemplateId)
    for _, nSlotIndex in ipairs(tbMatchedSlots) do
        local tbHumanWeaponTemplateIds = CheckCanBuildItemHelper.GetCanBuildHumanWeaponItemTemplateIdsOnSlot(nCharacterInstanceId, nSlotIndex, true)
        for _, v in ipairs(tbHumanWeaponTemplateIds) do
            local tbTemplate = BattleItemDataTable:GetTemplate(v)
            if BattleItemBuildDataTable:IsSameBaseItemTemplateIds(nReservedItemTemplateId, tbTemplate.nId) and tbTemplate.nGrade <= nReservedGrade then
                if not Contains(tbItemTemplateIds, v) then
                    table.insert(tbItemTemplateIds, v)
                end
                if #tbItemTemplateIds >= QUICK_BUILD_MAX then
                    break
                end
            end
        end
        if #tbItemTemplateIds >= QUICK_BUILD_MAX then
            break
        end
    end
end

local function FillQuickBuildHumanArmorWhenReserved(tbItemTemplateIds, tbReservedItemTemplate)
    local nCharacterInstanceId = GamePlayerSelfHelper:GetServerInstanceId()
    local nReservedArmorCategory = tbReservedItemTemplate.nArmorCategory
    local nReservedGrade = tbReservedItemTemplate.nGrade

    local tbHumanArmorTemplateIds = CheckCanBuildItemHelper.GetCanBuildHumanArmorItemTemplateIdsOnSlot(nCharacterInstanceId, nReservedArmorCategory, true)
    for _, v in ipairs(tbHumanArmorTemplateIds) do
        local tbTemplate = BattleItemDataTable:GetTemplate(v)
        if tbTemplate.nGrade <= nReservedGrade then
            table.insert(tbItemTemplateIds, v)
            if #tbItemTemplateIds >= QUICK_BUILD_MAX then
                break
            end
        end
    end
end

local function GetQuickBuildWhenReserved(nReservedItemTemplateId)
    local tbItemTemplateIds = {}
    local bVerificationResult, _ = BattleItemSystemClient:VerifyItemBuilding(nReservedItemTemplateId)
    if bVerificationResult then
        table.insert(tbItemTemplateIds, nReservedItemTemplateId)
    else
        local tbReservedItemTemplate = BattleItemDataTable:GetTemplate(nReservedItemTemplateId)
        if tbReservedItemTemplate.nCategory == BattleItemCategoryDef.SHIP_PART then
            FillQuickBuildShipPartWhenReserved(tbItemTemplateIds, tbReservedItemTemplate)
        elseif tbReservedItemTemplate.nCategory == BattleItemCategoryDef.SHIP then
            FillQuickBuildShipWhenReserved(tbItemTemplateIds, tbReservedItemTemplate)
        elseif tbReservedItemTemplate.nCategory == BattleItemCategoryDef.HUMAN_WEAPON then
            FillQuickBuildHumanWeaponWhenReserved(tbItemTemplateIds, tbReservedItemTemplate)
        elseif tbReservedItemTemplate.nCategory == BattleItemCategoryDef.HUMAN_ARMOR then
            FillQuickBuildHumanArmorWhenReserved(tbItemTemplateIds, tbReservedItemTemplate)
        end
    end
    return tbItemTemplateIds
end

-- local function GetQuickBuildWhenHumanNotReservedAndShipLowLevel(nCurrentBuildShipGrade)
--     local tbItemTemplateIds = {}
--     FillQuickBuildHumanWeaponWhenNotReserved(tbItemTemplateIds)
--     if #tbItemTemplateIds >= QUICK_BUILD_MAX then
--         return tbItemTemplateIds
--     end

--     FillQuickBuildHumanArmorWhenNotReserved(tbItemTemplateIds)
--     if #tbItemTemplateIds >= QUICK_BUILD_MAX then
--         return tbItemTemplateIds
--     end

--     FillQuickBuildShipWhenNotReserved(tbItemTemplateIds)
--     if #tbItemTemplateIds >= QUICK_BUILD_MAX then
--         return tbItemTemplateIds
--     end

--     if nCurrentBuildShipGrade == SHIP_GRADE_TWO then -- 舰船等级2可以推荐船武器
--         FillQuickBuildShipWeaponWhenNotReserved(tbItemTemplateIds)
--         if #tbItemTemplateIds >= QUICK_BUILD_MAX then
--             return tbItemTemplateIds
--         end
--     end

--     return tbItemTemplateIds
-- end

-- local function GetQuickBuildWhenHumanNotReservedAndShipHighLevel()
--     local tbItemTemplateIds = {}

--     FillQuickBuildShipWeaponWhenNotReserved(tbItemTemplateIds)
--     if #tbItemTemplateIds >= QUICK_BUILD_MAX then
--         return tbItemTemplateIds
--     end

--     FillQuickBuildShipPartWhenNotReserved(tbItemTemplateIds)
--     if #tbItemTemplateIds >= QUICK_BUILD_MAX then
--         return tbItemTemplateIds
--     end

--     FillQuickBuildHumanWeaponWhenNotReserved(tbItemTemplateIds)
--     if #tbItemTemplateIds >= QUICK_BUILD_MAX then
--         return tbItemTemplateIds
--     end

--     FillQuickBuildHumanArmorWhenNotReserved(tbItemTemplateIds)
--     if #tbItemTemplateIds >= QUICK_BUILD_MAX then
--         return tbItemTemplateIds
--     end

--     return tbItemTemplateIds
-- end

-- local function GetQuickBuildWhenHumanNotReserved()
--     local nCharacterInstanceId = GamePlayerSelfHelper:GetServerInstanceId()
--     local nCurrentBuildShipGrade = BattleItemSystemHelper:GetShipBuiltGrade(nCharacterInstanceId, true)

--     if nCurrentBuildShipGrade <= SHIP_GRADE_TWO then -- 舰船等级低
--         return GetQuickBuildWhenHumanNotReservedAndShipLowLevel(nCurrentBuildShipGrade)
--     else -- 舰船等级高
--         return GetQuickBuildWhenHumanNotReservedAndShipHighLevel(nCurrentBuildShipGrade)
--     end
-- end

-- local function GetQuickBuildWhenShipNotReserved()
--     local tbItemTemplateIds = {}
--     local nCharacterInstanceId = GamePlayerSelfHelper:GetServerInstanceId()
--     local nCurrentBuildShipGrade = BattleItemSystemHelper:GetShipBuiltGrade(nCharacterInstanceId, true)

--     if nCurrentBuildShipGrade <= SHIP_GRADE_ONE then -- 舰船等级低优先提示造船
--         FillQuickBuildShipWhenNotReserved(tbItemTemplateIds)
--         if #tbItemTemplateIds >= QUICK_BUILD_MAX then
--             return tbItemTemplateIds
--         end
--     end

--     -- 看看有没有武器空槽位，且可建造武器
--     FillQuickBuildShipWeaponWhenNotReserved(tbItemTemplateIds)
--     if #tbItemTemplateIds >= QUICK_BUILD_MAX then
--         return tbItemTemplateIds
--     end

--     if nCurrentBuildShipGrade >= SHIP_GRADE_TWO then -- 舰船等级高了才提示造零件，人武器，人装备
--         FillQuickBuildShipPartWhenNotReserved(tbItemTemplateIds)
--         if #tbItemTemplateIds >= QUICK_BUILD_MAX then
--             return tbItemTemplateIds
--         end

--         FillQuickBuildHumanWeaponWhenNotReserved(tbItemTemplateIds)
--         if #tbItemTemplateIds >= QUICK_BUILD_MAX then
--             return tbItemTemplateIds
--         end

--         FillQuickBuildHumanArmorWhenNotReserved(tbItemTemplateIds)
--         if #tbItemTemplateIds >= QUICK_BUILD_MAX then
--             return tbItemTemplateIds
--         end
--     end
--     return tbItemTemplateIds
-- end

local function GetQuickBuildShipItemWhenNotReserved()
    local tbItemTemplateIds = {}
    local nCharacterInstanceId = GamePlayerSelfHelper:GetServerInstanceId()

    local tbCanBuildShipTemplatesIds = CheckCanBuildItemHelper.GetCanBuildShipItemTemplateIds(nCharacterInstanceId, true)
    for _, v in ipairs(tbCanBuildShipTemplatesIds) do
        table.insert(tbItemTemplateIds, v)
    end

    for i = ShipWeaponSlotDef.COMMON_START, ShipWeaponSlotDef.COMMON_END do
        local tbWeaponItem = BattleItemSystemClient:GetEquippedItem(BattleItemCategoryDef.SHIP_WEAPON, nCharacterInstanceId, i)
        if not tbWeaponItem or tbWeaponItem:GetTemplate().bDefaultWeapon then
            local tbShipWeaponTemplateIds = CheckCanBuildItemHelper.GetCanBuildShipWeaponItemTemplateIdsOnSlot(nCharacterInstanceId, i, true)
            for _, v in ipairs(tbShipWeaponTemplateIds) do
                table.insert(tbItemTemplateIds, v)
            end
        end
    end

    -- 当前船等级大于等于2，才推荐船零件
    local nCurrentShipItemTemplateId = ShipItemHelper.GetCurrentShipItemTemplateIdOnClient()
    if nCurrentShipItemTemplateId ~= nil then
        local tbShipItemTemplate = BattleItemDataTable:GetTemplate(nCurrentShipItemTemplateId)
        if tbShipItemTemplate and tbShipItemTemplate.nGrade >= 2 then
            for nGrade = 1, SHIP_PART_MAX_GRADE do
                for nSlot=1, ShipPartTypeDef.Max do
                    local tbShipPartTemplateIds = CheckCanBuildItemHelper.GetCanBuildShipPartItemTemplateIdsOnSlot(nCharacterInstanceId, nSlot, true)
                    for _, v in ipairs(tbShipPartTemplateIds) do
                        table.insert(tbItemTemplateIds, v)
                    end
                end
            end
        end
    end

    table.sort(tbItemTemplateIds, FunSort)
    if #tbItemTemplateIds > 0 then
        return tbItemTemplateIds[1]
    end
    return nil
end


local function FillQuickBuildHumanItemWhenNotReserved(tbItemTemplateIds, nCategory, nSlotCount)
    local nCharacterInstanceId = GamePlayerSelfHelper:GetServerInstanceId()
    for nSlotIndex = 1, nSlotCount do
        local tbHumanWeaponItemTemplateIds = CheckCanBuildItemHelper.GetCanBuildHumanItemTemplateIdsOnSlot(nCharacterInstanceId, nCategory, nSlotIndex, true)
        for _, v in ipairs(tbHumanWeaponItemTemplateIds) do
            if not Contains(tbItemTemplateIds, v) then
                table.insert(tbItemTemplateIds, v)
            end
        end
    end
end

local function GetQuickBuildHumanItemWhenNotReserved()
    local tbItemTemplateIds = {}
    FillQuickBuildHumanItemWhenNotReserved(tbItemTemplateIds, BattleItemCategoryDef.HUMAN_WEAPON, HumanWeaponSlotDef:SlotCount())
    FillQuickBuildHumanItemWhenNotReserved(tbItemTemplateIds, BattleItemCategoryDef.HUMAN_ARMOR, HumanArmorSlotDef:SlotCount())
    table.sort(tbItemTemplateIds, FunSort)
    if #tbItemTemplateIds > 0 then
        return tbItemTemplateIds[1]
    end
    return nil
end

local function GetQuickBuildWhenNotReserved()
    -- local tbPlayer = GamePlayerSelfHelper:Get()
    -- if tbPlayer:IsShip() then
    --     return GetQuickBuildWhenShipNotReserved()
    -- elseif tbPlayer:IsHuman() then
    --     return GetQuickBuildWhenHumanNotReserved()
    -- else
    --     logwarning("Player is not ship or human!")
    --     return {}
    -- end
    local tbItemTemplateIds = {}
    local nShipItemTemplateId = GetQuickBuildShipItemWhenNotReserved()
    local nHumanItemTemplateId = GetQuickBuildHumanItemWhenNotReserved()
    if nShipItemTemplateId then
        table.insert(tbItemTemplateIds, nShipItemTemplateId)
    end
    if nHumanItemTemplateId then
        table.insert(tbItemTemplateIds, nHumanItemTemplateId)
    end
    return tbItemTemplateIds
end

local function CheckIsBuildingShipWeapon(tbQuickBuildItemTemplateIds, tbItemTemplateIds, tbBuildingItemTemplate)
    local nBuildingItemTemplateId = tbBuildingItemTemplate.nId
    local nBuildingWeaponSubCategory = tbBuildingItemTemplate.nSubCategory
    local nBuildingWeaponSlot = ShipWeaponCategoryDataTable:GetWeaponSlot(nBuildingWeaponSubCategory)

    for _, v in ipairs(tbItemTemplateIds) do
        if v ~= nBuildingItemTemplateId then
            local tbItemTemplate = BattleItemDataTable:GetTemplate(v)
            if tbItemTemplate.nCategory ~= BattleItemCategoryDef.SHIP_WEAPON then
                table.insert(tbQuickBuildItemTemplateIds, v)
            else
                local nSubCategory = tbItemTemplate.nSubCategory
                local nWeaponSlot = ShipWeaponCategoryDataTable:GetWeaponSlot(nSubCategory)
                if nWeaponSlot ~= nBuildingWeaponSlot then
                    table.insert(tbQuickBuildItemTemplateIds, v)
                end
            end
        end
    end
end

local function CheckIsNotBuildSame(tbQuickBuildItemTemplateIds, tbItemTemplateIds, nBuildingItemTemplateId)
    for _, v in ipairs(tbItemTemplateIds) do
        if v ~= nBuildingItemTemplateId then
            table.insert(tbQuickBuildItemTemplateIds, v)
        end
    end
end

local function CheckIsBuildingShip(tbQuickBuildItemTemplateIds, tbItemTemplateIds, tbBuildingItemTemplate)
    local nBuildingItemTemplateId = tbBuildingItemTemplate.nId
    for _, v in ipairs(tbItemTemplateIds) do
        if v ~= nBuildingItemTemplateId then
            local tbItemTemplate = BattleItemDataTable:GetTemplate(v)
            if tbItemTemplate.nCategory ~= BattleItemCategoryDef.SHIP then
                table.insert(tbQuickBuildItemTemplateIds, v)
            else
                if tbItemTemplate.nGrade ~= tbBuildingItemTemplate.nGrade then
                    table.insert(tbQuickBuildItemTemplateIds, v)
                end
            end
        end
    end
end

local function GetQuickBuildItemTemplateIdsAfterCheckIsBuilding(tbItemTemplateIds)
    local nBuildingItemTemplateId = BattleItemSystemClient:GetBuildingItemTemplateId()
    local tbQuickBuildItemTemplateIds = {}
    if nBuildingItemTemplateId ~= nil then
        local tbBuildingItemTemplate = BattleItemDataTable:GetTemplate(nBuildingItemTemplateId)
        if tbBuildingItemTemplate.nCategory == BattleItemCategoryDef.SHIP_WEAPON then
            CheckIsBuildingShipWeapon(tbQuickBuildItemTemplateIds, tbItemTemplateIds, tbBuildingItemTemplate)
        elseif tbBuildingItemTemplate.nCategory == BattleItemCategoryDef.SHIP_PART then
            CheckIsNotBuildSame(tbQuickBuildItemTemplateIds, tbItemTemplateIds, nBuildingItemTemplateId)
        elseif tbBuildingItemTemplate.nCategory == BattleItemCategoryDef.SHIP then
            CheckIsBuildingShip(tbQuickBuildItemTemplateIds, tbItemTemplateIds, tbBuildingItemTemplate)
        elseif tbBuildingItemTemplate.nCategory == BattleItemCategoryDef.HUMAN_WEAPON then
            CheckIsNotBuildSame(tbQuickBuildItemTemplateIds, tbItemTemplateIds, nBuildingItemTemplateId)
        elseif tbBuildingItemTemplate.nCategory == BattleItemCategoryDef.HUMAN_ARMOR then
            CheckIsNotBuildSame(tbQuickBuildItemTemplateIds, tbItemTemplateIds, nBuildingItemTemplateId)
        end
    else
        tbQuickBuildItemTemplateIds = tbItemTemplateIds
    end
    return tbQuickBuildItemTemplateIds
end

local function GetQuickBuildItemTemplateIds(self)
    local nReservedItemTemplateId = BattleItemSystemClient:GetReservedItemTemplateId()

    local tbItemTemplateIds = nil
    if nReservedItemTemplateId ~= nil then
        tbItemTemplateIds = GetQuickBuildWhenReserved(nReservedItemTemplateId)
    else
        tbItemTemplateIds = GetQuickBuildWhenNotReserved()
    end

    local tbQuickBuildItemTemplateIds = GetQuickBuildItemTemplateIdsAfterCheckIsBuilding(tbItemTemplateIds)

    return tbQuickBuildItemTemplateIds
end

local function OnRefreshQuickBuild(self)
    local tbItemTemplateIds = GetQuickBuildItemTemplateIds(self)
    local nCount = #tbItemTemplateIds
    local tbPbBuildItems = self.tbPbBuildItems
    for i = 1, QUICK_BUILD_MAX do
        tbPbBuildItems[i]:Hidden()
    end
    if nCount > 0 then
        for _, nItemTemplateId in ipairs(tbItemTemplateIds) do
            local tbTemplate = BattleItemDataTable:GetTemplate(nItemTemplateId)
            local nCategory = tbTemplate.nCategory
            if nCategory == BattleItemCategoryDef.SHIP
                or nCategory == BattleItemCategoryDef.SHIP_WEAPON
                or nCategory == BattleItemCategoryDef.SHIP_PART then
                    tbPbBuildItems[SHIP_SLOT_INDEX]:Refresh(nItemTemplateId)
            elseif nCategory == BattleItemCategoryDef.HUMAN_WEAPON
                or nCategory == BattleItemCategoryDef.HUMAN_ARMOR then
                    tbPbBuildItems[HUMAN_SLOT_INDEX]:Refresh(nItemTemplateId)
            end
        end
        EventManager:OnFireEvent(ClientEventDef.EV_FFA_QUICK_BUILD, tbItemTemplateIds)
    end
end

local function OnShipBuildGradeChanged(self, tbPlayer, _)
    if GamePlayerSelfHelper:GetServerInstanceId() == tbPlayer:GetServerInstanceId() then
        OnRefreshQuickBuild(self)
    end
end

local function OnPlayerDie(self, Deader)
    local tbPlayerSelf = GamePlayerSelfHelper:Get()
    if Deader == tbPlayerSelf then
        for _, v in pairs(self.tbPbBuildItems) do
            v:Hidden();
        end
    end
end

function ULQuickBuild:OnLoad()
    local pWidgetRef = self.pWidgetRef
    local PrefabHelper = self.PrefabHelper
    self.tbPbBuildItems = {}
    local tbPbBuildItems = self.tbPbBuildItems
    for i = 1, QUICK_BUILD_MAX do
        tbPbBuildItems[i] = PrefabHelper:BindPrefab(pWidgetRef["pbBuildItem"..i], UIDef.UP_QUICK_BUILD_ITEM)
    end
end

function ULQuickBuild:GetQuickBuildCount()
    local tbItemTemplateIds = GetQuickBuildItemTemplateIds(self)
    local nCount = #tbItemTemplateIds
    return nCount
end

local function RefreshHandleCallBack(self)
    if self.tbDelayCheckQuickBuildHandle ~= nil then
        self.tbDelayCheckQuickBuildHandle:Clear()
        self.tbDelayCheckQuickBuildHandle = nil
    end
    OnRefreshQuickBuild(self)
end

local function NeedRefresh(self)
    if not self.tbDelayCheckQuickBuildHandle then
        self.tbDelayCheckQuickBuildHandle = self.TimerHelper:NewTimerMethod(self, function() RefreshHandleCallBack(self) end, DELAY_REFRESH_SECONDS)
    end
end

function ULQuickBuild:OnBindEvent(EventHelper)
    EventHelper:RegisterEvent(ClientEventDef.EV_BEGIN_ITEM_BUILD, self, NeedRefresh)
    EventHelper:RegisterEvent(ClientEventDef.EV_BATTLE_ITEM_BUILD_CANCEL_CLIENT, self, NeedRefresh)
    EventHelper:RegisterEvent(ClientEventDef.EV_BATTLE_ITEM_ADD_CLIENT, self, NeedRefresh)
    EventHelper:RegisterEvent(ClientEventDef.EV_BATTLE_ITEM_REMOVE_CLIENT, self, NeedRefresh)
    EventHelper:RegisterEvent(ClientEventDef.EV_BATTLE_ITEM_CHANGE_STACKCOUNT_CLIENT, self, NeedRefresh)
    EventHelper:RegisterEvent(ClientEventDef.EV_RESERVE_ITEM_BUILD, self, NeedRefresh)
    EventHelper:RegisterEvent(ClientEventDef.EV_CANCEL_RESERVE_ITEM_BUILD, self, NeedRefresh)
    EventHelper:RegisterEvent(ClientEventDef.EV_SHIP_BUILD_GRADE_CHANGED_CLIENT, self, OnShipBuildGradeChanged)
    EventHelper:RegisterEvent(ClientEventDef.EV_ON_SYNC_SHIP_PREPARATION, self, NeedRefresh)
    EventHelper:RegisterEvent(ClientEventDef.EV_PLAYERSELF_READY, self, NeedRefresh)
    EventHelper:RegisterEvent(CommonEventDef.EV_GAME_OBJECT_ON_PAWN_DEAD, self, OnPlayerDie)
end

return ULQuickBuild