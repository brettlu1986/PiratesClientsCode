-----------------------------------------------------
--File Name    : PlayerNewItemRecordComponent.lua
--Author       : WuJizhou
--Create Time  : 6/5/2019, 3:40:51 PM
--Description  : PlayerNewItemRecordComponent
-----------------------------------------------------
local luaclass = require("luaclass")
local GameComponentBaseClass = require("GameComponentBase")
local PlayerNewItemRecordComponent = luaclass("PlayerNewItemRecordComponent", GameComponentBaseClass)
local SaveGameDef = require("SaveGameDef")
local StringUtil = require("StringUtil")
local SelfEventHelper = require("SelfEventHelper")
local ClientEventDef = require("ClientEventDef")
local ItemCategoryDef = require("ItemCategoryDef")
-- local CaptainUIHelper = require("CaptainUIHelper")
-- local CaptainUIMiscDef = require("CaptainUIMiscDef")
local ItemSystem = require("ItemSystem")
local BackpackDataTable = require("BackpackDataTable")
local HumanWeaponDefaultDataTable = require("HumanWeaponDefaultDataTable")
-- local UIFashionSlotCategory = CaptainUIMiscDef.UIFashionSlotCategory
-- local UIDecorationSlotCategory = CaptainUIMiscDef.UIDecorationSlotCategory

PlayerNewItemRecordComponent.tbAllNewFashions = {}
PlayerNewItemRecordComponent.tbAllNewWeaponFashions = {}
-- PlayerNewItemRecordComponent.tbAllNewDecorations = {}
PlayerNewItemRecordComponent.tbAllNewItemsInBackpack = {}
PlayerNewItemRecordComponent.bHasNewItemInBackpack = false

local function ParseTableKeyFromGameData(szGameSaveKey, tbData)
    local pSaveGameMgr = ClientShell.GetClient(GWorld):GetSaveGameManager()
    local szData = pSaveGameMgr:GetStringDataWithDefault(szGameSaveKey , "")
    local tbInstanceIds = StringUtil.Split(szData, ",")
    for _, szInstanceId in pairs(tbInstanceIds) do
        local nInstanceId = tonumber(szInstanceId)
        tbData[nInstanceId] = true
    end
end

local function SerializeIntOrStringListToGameData(szGameSaveKey, tbData)
    local szData = table.concat(tbData, ",")
    local pSaveGameMgr = ClientShell.GetClient(GWorld):GetSaveGameManager()
    pSaveGameMgr:AddStringData(szGameSaveKey, szData)
    pSaveGameMgr:Save()
end

local function SerializeTableKeyToGameData(szGameSaveKey, tbData)
    local tbToSerialize = {}
    for k, v in pairs(tbData) do
        if v then
            table.insert(tbToSerialize, k)
        end
    end
    SerializeIntOrStringListToGameData(szGameSaveKey, tbToSerialize)
end

local function SerializeBoolToGameData(szKey, bHint)
    local pSaveGameMgr = ClientShell.GetClient(GWorld):GetSaveGameManager()
	pSaveGameMgr:AddBoolData(szKey, bHint)
	pSaveGameMgr:Save()
end

local function ParseBoolFromGameData(szKey)
    local pSaveGameMgr = ClientShell.GetClient(GWorld):GetSaveGameManager()
	return pSaveGameMgr:GetBoolDataWithDefault(szKey, false)
end


-----------------------human fashion------------------------

local function InitAllFashionNew(self)
    ParseTableKeyFromGameData(SaveGameDef.FASHION_NEW_ITEMS, self.tbAllNewFashions)
end

local function SaveFashionGameData(self)
    SerializeTableKeyToGameData(SaveGameDef.FASHION_NEW_ITEMS, self.tbAllNewFashions)
end

local function MarkNewFashion(self, nInstanceId)
    if not self.tbAllNewFashions[nInstanceId] then
        self.tbAllNewFashions[nInstanceId] = true;
        SaveFashionGameData(self)
        self.EventHelper:FireEvent(ClientEventDef.EV_NEW_ITEM_RECORD_STATE_CHANGED, nInstanceId)
    end
end


local function UnmarkNewFashion(self, nInstanceId)
    if self.tbAllNewFashions[nInstanceId] then
        self.tbAllNewFashions[nInstanceId] = nil
        SaveFashionGameData(self)
        self.EventHelper:FireEvent(ClientEventDef.EV_NEW_ITEM_RECORD_STATE_CHANGED, nInstanceId)
    end
end


-----------------------human weapon fashion------------------------

local function InitAllHumanWeaponFashionNew(self)
    ParseTableKeyFromGameData(SaveGameDef.WAEPON_FASHION_NEW_ITEMS, self.tbAllNewWeaponFashions)
end


local function SaveHumanWeaponFashionGameData(self)
    SerializeTableKeyToGameData(SaveGameDef.WAEPON_FASHION_NEW_ITEMS, self.tbAllNewWeaponFashions)
end


local function MarkNewHumanWeaponFashion(self, nInstanceId)
    if not self.tbAllNewWeaponFashions[nInstanceId] then
        self.tbAllNewWeaponFashions[nInstanceId] = true;
        SaveHumanWeaponFashionGameData(self)
        self.EventHelper:FireEvent(ClientEventDef.EV_NEW_ITEM_RECORD_STATE_CHANGED, nInstanceId)
    end
end

local function UnmarkNewHumanWeaponFashion(self, nInstanceId)
    if self.tbAllNewWeaponFashions[nInstanceId] then
        self.tbAllNewWeaponFashions[nInstanceId] = nil
        SaveHumanWeaponFashionGameData(self)
        self.EventHelper:FireEvent(ClientEventDef.EV_NEW_ITEM_RECORD_STATE_CHANGED, nInstanceId)
    end
end



local function InitAllNewItemsInBackpack(self)
    ParseTableKeyFromGameData(SaveGameDef.NEW_ITEMS_IN_BACKPACK, self.tbAllNewItemsInBackpack)
end

local function InitHasNewItemInBackpack(self)
    self.bHasNewItemInBackpack = ParseBoolFromGameData(SaveGameDef.HAVE_NEW_ITEMS_IN_BACKPACK)
end


local function SaveAllNewItemsInBackpack(self)
    SerializeTableKeyToGameData(SaveGameDef.NEW_ITEMS_IN_BACKPACK, self.tbAllNewItemsInBackpack)
end

local function SaveHasNewItemInBackpack(self)
    SerializeBoolToGameData(SaveGameDef.HAVE_NEW_ITEMS_IN_BACKPACK, self.bHasNewItemInBackpack)
end


local function CheckHasNewItemsInBackpack(self)
    local bHasNewItems = false
    -- luacheck: push ignore
    for _, v in pairs(self.tbAllNewItemsInBackpack) do
        bHasNewItems = true
    end
    -- luacheck: pop
    if not bHasNewItems and self.bHasNewItemInBackpack then
        self:UnmarkHasNewItemsInBackpack()
    end
end

local function CheckItemInstanceIds(self)
    local tbItemsAlreadyRemoved = {}
    for k, _ in pairs(self.tbAllNewItemsInBackpack) do
        local tbItem = ItemSystem:GetItem(k)
        if tbItem == nil then
            table.insert(tbItemsAlreadyRemoved, k)
        end
    end
    for _, v in ipairs(tbItemsAlreadyRemoved) do
        self.tbAllNewItemsInBackpack[v] = nil
    end
end


-- local function InitAllDecorationNew(self)
--     ParseTableKeyFromGameData(SaveGameDef.DECORATION_NEW_ITEMS, self.tbAllNewDecorations)
-- end

-- local function SaveDecorationGameData(self)
--     SerializeTableKeyToGameData(SaveGameDef.DECORATION_NEW_ITEMS, self.tbAllNewDecorations)
-- end




local function OnItemAdded(self, tbItem)
    local nCategory = tbItem:GetCategory()
    local nInstanceId = tbItem:GetInstanceId()
    if nCategory == ItemCategoryDef.FASHION then
        MarkNewFashion(self, nInstanceId)
    elseif nCategory == ItemCategoryDef.HUMAN_WEAPON_FASHION then
        MarkNewHumanWeaponFashion(self, nInstanceId)
    -- elseif nCategory == ItemCategoryDef.DECORATION then
    --     self:MarkNewDecoration(nInstanceId)
    --     CaptainUIHelper.SetDecorationSlotHintState(UIDecorationSlotCategory.All, true)
    end
    self:MarkNewItemsInBackpack(nInstanceId)
end

local function OnItemChangeStackCount(self, nInstanceId, _, bAdd)
    if bAdd then
        self:MarkNewItemsInBackpack(nInstanceId)
    end
end

local function OnItemRemoved(self, nInstanceId)
    if self:IsItemInBackpackMarkedNew(nInstanceId) then
        self:UnmarkNewItemsInBackpack(nInstanceId)
    end
end

local function OnItemSelected(self, nInstanceId)
    local tbItem = ItemSystem:GetItem(nInstanceId)
    local nCategory = tbItem:GetCategory()
    if nCategory == ItemCategoryDef.FASHION then
        UnmarkNewFashion(self, nInstanceId)
    elseif nCategory == ItemCategoryDef.HUMAN_WEAPON_FASHION then
        UnmarkNewHumanWeaponFashion(self, nInstanceId)
    end
end

function PlayerNewItemRecordComponent:IsNewHumanFashion(nInstanceId)
    if nInstanceId then
        return self.tbAllNewFashions[nInstanceId]
    end
end

function PlayerNewItemRecordComponent:HasNewHumanFashion()
    local tbFashions = self.tbAllNewFashions
    local bRet = false
    for k, v in pairs(tbFashions) do
        if v then
            bRet = true
            break
        end
    end
    return bRet
end

function PlayerNewItemRecordComponent:HasNewHumanFashionByFashionType(nFashionType)
    local tbFashions = self.tbAllNewFashions
    local bRet = false
    for nInstanceId, v in pairs(tbFashions) do
        if v then
            local tbItem = ItemSystem:GetItem(nInstanceId)
            if tbItem then
                local tbTemplate = tbItem:GetTemplate()
                if tbTemplate.nFashionType == nFashionType then
                    bRet = true
                    break
                end
            end
        end
    end
    return bRet
end

function PlayerNewItemRecordComponent:HasNewHumanFashionByFashionAndSlotType(nFashionType, nSlotType)
    local tbFashions = self.tbAllNewFashions
    local bRet = false
    for nInstanceId, v in pairs(tbFashions) do
        if v then
            local tbItem = ItemSystem:GetItem(nInstanceId)
            if tbItem then
            local tbTemplate = tbItem:GetTemplate()
                if tbTemplate.nFashionType == nFashionType and tbTemplate.nSubCategory == nSlotType then
                    bRet = true
                    break
                end
            end
        end
    end
    return bRet
end


function PlayerNewItemRecordComponent:HasNewHumanSuitByFashionType(nFashionType)
    local tbSuit = {}
    local tbFashions = self.tbAllNewFashions
    local bRet = false
    for nInstanceId, v in pairs(tbFashions) do
        if v then
            local tbItem = ItemSystem:GetItem(nInstanceId)
            if tbItem then
                local tbTemplate = tbItem:GetTemplate()
                local nSuitId = tbTemplate.nSuitId
                if tbTemplate.nFashionType == nFashionType and nSuitId then
                    
                    local tb = tbSuit[nSuitId]
                    if not tb then
                        tb = {}
                        tbSuit[nSuitId] = tb
                        local tbSuitTemplate = ItemSystem:GetItemTemplate(nSuitId)
                        tb.nTargetCount = #tbSuitTemplate.tbSubItemTemplateIds
                        tb.nCurrentCount = 0
                    end
                    tb.nCurrentCount = tb.nCurrentCount + 1
                    if tb.nCurrentCount == tb.nTargetCount then
                        bRet = true
                        break
                    end
                end
            end
        end
    end
    return bRet
end

function PlayerNewItemRecordComponent:HasNewHumanWeaponFashion()
    local tbWeaponFashions = self.tbAllNewWeaponFashions
    local bRet = false
    for k, v in pairs(tbWeaponFashions) do
        if v then
            bRet = true
            break
        end
    end
    return bRet
end

function PlayerNewItemRecordComponent:IsNewHumanWeaponFashion(nInstanceId)
    local tbWeaponFashions = self.tbAllNewWeaponFashions
    return tbWeaponFashions[nInstanceId]
end

function PlayerNewItemRecordComponent:HasNewHumanWeaponFashionByRangeType(nRangeType)
    local tbWeaponFashions = self.tbAllNewWeaponFashions
    local bRet = false
    for nInstanceId, v in pairs(tbWeaponFashions) do
        if v then
            local Item = ItemSystem:GetItem(nInstanceId)
            if Item then
                local nWeaponInstanceType = Item:GetSubCategory()
                local tbInstanceData = HumanWeaponDefaultDataTable:GetAllLevelData(nWeaponInstanceType)
                if tbInstanceData and tbInstanceData.nRangeType == nRangeType then
                    bRet = true
                    break
                end
            end
        end
    end
    return bRet
end

function PlayerNewItemRecordComponent:HasNewHumanWeaponFashionByInstanceType(nInstanceType)
    local tbWeaponFashions = self.tbAllNewWeaponFashions
    local bRet = false
    for nInstanceId, v in pairs(tbWeaponFashions) do
        if v then
            local Item = ItemSystem:GetItem(nInstanceId)
            if Item then
                local nWeaponInstanceType = Item:GetSubCategory()
                if nWeaponInstanceType == nInstanceType then
                    bRet = true
                    break
                end
            end
        end
    end
    return bRet
end




function PlayerNewItemRecordComponent:IsDecorationMarkedNew(nInstanceId)
    return false
    -- return self.tbAllNewDecorations[nInstanceId]
end

function PlayerNewItemRecordComponent:MarkNewDecoration(nInstanceId)
    -- self.tbAllNewDecorations[nInstanceId] = true;
    -- SaveDecorationGameData(self)
    -- self.EventHelper:FireEvent(ClientEventDef.EV_NEW_ITEM_RECORD_STATE_CHANGED)
end

function PlayerNewItemRecordComponent:UnmarkNewDecoration(nInstanceId)
    -- local tb = self.tbAllNewDecorations
    -- tb[nInstanceId] = nil;
    -- SaveDecorationGameData(self)
    -- self.EventHelper:FireEvent(ClientEventDef.EV_NEW_ITEM_RECORD_STATE_CHANGED)
end

function PlayerNewItemRecordComponent:MarkNewItemsInBackpack(nInstanceId)
    local Item = ItemSystem:GetItem(nInstanceId)
    local nCategory = Item:GetCategory()
    if BackpackDataTable:CanInBackpack(nCategory) then
        self.tbAllNewItemsInBackpack[nInstanceId] = true
        SaveAllNewItemsInBackpack(self)
        self.bHasNewItemInBackpack = true
        SaveHasNewItemInBackpack(self)
        self.EventHelper:FireEvent(ClientEventDef.EV_CHANGE_NEW_STATE_IN_BACKPACK)
    end
end

function PlayerNewItemRecordComponent:UnmarkNewItemsInBackpack(nInstanceId)
    self.tbAllNewItemsInBackpack[nInstanceId] = nil;
    SaveAllNewItemsInBackpack(self)
    CheckHasNewItemsInBackpack(self)
    self.EventHelper:FireEvent(ClientEventDef.EV_CHANGE_NEW_STATE_IN_BACKPACK)
end

function PlayerNewItemRecordComponent:IsItemInBackpackMarkedNew(nInstanceId)
    return self.tbAllNewItemsInBackpack[nInstanceId]
end

function PlayerNewItemRecordComponent:HasNewItemInBackpack()
    return self.bHasNewItemInBackpack
end

function PlayerNewItemRecordComponent:UnmarkHasNewItemsInBackpack()
    self.bHasNewItemInBackpack = false
    SaveHasNewItemInBackpack(self)
    self.EventHelper:FireEvent(ClientEventDef.EV_CHANGE_NEW_STATE_IN_BACKPACK)
end

-------base api from GameComponentBaseClass--------
function PlayerNewItemRecordComponent:OnCreate(Owner, tbParams)
    PlayerNewItemRecordComponent.super.OnCreate(self, Owner, tbParams)
    InitAllFashionNew(self)
    InitAllHumanWeaponFashionNew(self)
    -- InitAllDecorationNew(self)
    InitAllNewItemsInBackpack(self)
    InitHasNewItemInBackpack(self)

    self.EventHelper = SelfEventHelper()
    self.EventHelper:RegisterEvent(ClientEventDef.EV_ADD_LOBBY_ITEM, self, OnItemAdded)
    self.EventHelper:RegisterEvent(ClientEventDef.EV_CHANGE_LOBBY_ITEM_STACK_COUNT, self, OnItemChangeStackCount)
    self.EventHelper:RegisterEvent(ClientEventDef.EV_REMOVE_LOBBY_ITEM, self, OnItemRemoved)
    self.EventHelper:RegisterEvent(ClientEventDef.EV_SELECT_LOBBY_ITEM, self, OnItemSelected)
    return true
end

function PlayerNewItemRecordComponent:OnPostCreate()
    CheckItemInstanceIds(self)
    CheckHasNewItemsInBackpack(self)
end

function PlayerNewItemRecordComponent:OnDestroy()
    PlayerNewItemRecordComponent.super.OnDestroy(self)
    -- self.tbAllNewFashions = {}
    -- self.tbAllNewDecorations = {}
    self.tbAllNewItemsInBackpack = {}
    self.bHasNewItemInBackpack = false
    self.EventHelper:UnregisterAll()
    self.EventHelper = nil
end

return PlayerNewItemRecordComponent