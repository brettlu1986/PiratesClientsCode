-----------------------------------------------------
--File Name    : WearComponent.lua
--Author       : zhiyuan
--Create Time  : 2019-03-14
--Description  : 时装和饰品的component
-----------------------------------------------------
local luaclass = require("luaclass")
local GameComponentBase = require("GameComponentBase")
local WearComponent = luaclass("WearComponent", GameComponentBase)
local ClientEventDef = require("ClientEventDef")
local EventManager = require("EventManager")
local ItemSystem = require("ItemSystem")

-- 已装配的时装instanceId列表
WearComponent.tbEquippedFashionItemInstanceIds = nil

-- 已装配的饰品instanceId列表
WearComponent.nEquippedDecorationInstanceId = nil

WearComponent.tbEquippedWeaponFashionItemInstanceIds = nil

-- 人时装标识数据
WearComponent.nHumanFashionExtraFlag = 0

-----------------------------------------local function---------------------------------------------

local function GetItem(self, nInstanceId)
    local ItemComponent = self.Owner.ItemComponent
    return ItemComponent:GetItem(nInstanceId)
end

local function FindIndexInList(tbList, nData)
    local nIndex = -1
    if tbList ~= nil then
        for i, v in ipairs(tbList) do
            if nData == v then
                nIndex = i
                break
            end
        end
    end
    return nIndex
end

local function GetItems(self, tbItemInstanceIds)
    local tbItems = {}
    if tbItemInstanceIds ~= nil then
        for _, v in ipairs(tbItemInstanceIds) do
            local Item = GetItem(self, v)
            table.insert(tbItems, Item)
        end
    end
    return tbItems
end

-----------------------------------------初始化---------------------------------------------
local function OnPlayerDataSync(self, tbPlayerData)
    ItemSystem:RequestGetCurrentDecoration()
end

-- tbParams:repeated Item
function WearComponent:OnCreate(Owner, tbParams)
    WearComponent.super.OnCreate(self, Owner, tbParams)
    if tbParams == nil then
        tbParams = {}
    end

    self.tbEquippedFashionItemInstanceIds = tbParams.fashion
    self.nEquippedDecorationInstanceId = tbParams.decoration
    self.tbEquippedWeaponFashionItemInstanceIds = tbParams.weapon_fashion
    self:SetHumanFashionFlag(tbParams.dry_fashion_flag)

    if self.tbEquippedFashionItemInstanceIds == nil then
        self.tbEquippedFashionItemInstanceIds = {}
    end

    if self.tbEquippedWeaponFashionItemInstanceIds == nil then
        self.tbEquippedWeaponFashionItemInstanceIds = {}
    end

    if self.nEquippedDecorationInstanceId ~= nil and self.nEquippedDecorationInstanceId <= 0 then
        self.nEquippedDecorationInstanceId = nil
    end

    EventManager:BindEventMethod(ClientEventDef.EV_PLAYERDATA_SYNC, self, OnPlayerDataSync)

    return true
end

function WearComponent:OnDestroy()
    EventManager:UnBindEventMethod(ClientEventDef.EV_PLAYERDATA_SYNC, self, OnPlayerDataSync)

end

-----------------------------------------时装相关---------------------------------------------

function WearComponent:IsHumanFashionEquiped(nInstanceId)
    for _, nId in ipairs(self.tbEquippedFashionItemInstanceIds) do
        if nId == nInstanceId then
            return true
        end
    end
    return false
end

function WearComponent:GetEquippedFashionItems()
    return GetItems(self, self.tbEquippedFashionItemInstanceIds)
end

function WearComponent:GetEquippedWeaponFashionItems()
    return GetItems(self, self.tbEquippedWeaponFashionItemInstanceIds)
end

function WearComponent:GetEquippedWeaponFashionItem(nWeaponInstanceType)
    local tbItems = self:GetEquippedWeaponFashionItems()
    for _, v in ipairs(tbItems) do
        if v:GetTemplate().nSubCategory == nWeaponInstanceType then
            return v
        end
    end
end

function WearComponent:GetEquipedFashionItemsByType(nFashionType)
    local tbResult = {}
    local tbEquippedFashionItems = self:GetEquippedFashionItems()
    for _, v in ipairs(tbEquippedFashionItems) do
        if v:GetTemplate().nFashionType == nFashionType then
            table.insert(tbResult, v)
        end
    end
    return tbResult
end

function WearComponent:GetEquippedFashionItemBySubCategory(nFashionType, nSubCategory)
    local tbEquippedFashionItems = self:GetEquippedFashionItems()
    for _, v in ipairs(tbEquippedFashionItems) do
        if v:GetTemplate().nFashionType == nFashionType and v:GetSubCategory() == nSubCategory then
            return v
        end
    end
    return nil
end



function WearComponent:EquipFashionItem(nInstanceId)
    table.insert(self.tbEquippedFashionItemInstanceIds, nInstanceId)
end

function WearComponent:UnequipFashionItem(nInstanceId)
    local tbEquippedFashionItemInstanceIds = self.tbEquippedFashionItemInstanceIds
    local nIndex = FindIndexInList(tbEquippedFashionItemInstanceIds, nInstanceId)
    if nIndex > 0 then
        table.remove(tbEquippedFashionItemInstanceIds, nIndex)
    else
        logerror("UnequipFashionItem ERROR! instanceId not equip!", nInstanceId)
    end
end

function WearComponent:IsHumanWeaponFashionEquiped(nInstanceId)
    for _, nId in ipairs(self.tbEquippedWeaponFashionItemInstanceIds) do
        if nId == nInstanceId then
            return true
        end
    end
    return false
end

function WearComponent:EquipWeaponFashionItem(nInstanceId)
    table.insert(self.tbEquippedWeaponFashionItemInstanceIds, nInstanceId)
end

function WearComponent:UnequipWeaponFashionItem(nInstanceId)
    local tbEquippedWeaponFashionItemInstanceIds = self.tbEquippedWeaponFashionItemInstanceIds
    local nIndex = FindIndexInList(tbEquippedWeaponFashionItemInstanceIds, nInstanceId)
    if nIndex > 0 then
        table.remove(tbEquippedWeaponFashionItemInstanceIds, nIndex)
    else
        logerror("UnequipWeaponFashionItem ERROR! instanceId not equip!", nInstanceId)
    end
end

function WearComponent:SetHumanFashionFlag(nFlag)
    self.nHumanFashionExtraFlag = nFlag
end

function WearComponent:GetHumanFashionFlag()
    return self.nHumanFashionExtraFlag
end

-----------------------------------------战备相关---------------------------------------------

function WearComponent:GetEquippedDecorationItem()
    local nEquippedDecorationInstanceId = self.nEquippedDecorationInstanceId
    if nEquippedDecorationInstanceId == nil then
        return nil
    end
    return GetItem(self, nEquippedDecorationInstanceId)
end

function WearComponent:EquipDecorationItem(nInstanceId)
    if self.nEquippedDecorationInstanceId ~= nil then
        log("EquipDecorationItem ERROR! Already equip one decoration!", self.nEquippedDecorationInstanceId)
    end
    self.nEquippedDecorationInstanceId = nInstanceId
end

function WearComponent:UnequipDecorationItem(nInstanceId)
    if self.nEquippedDecorationInstanceId ~= nInstanceId then
        log("UnequipDecorationItem ERROR! instanceId not format!",self.nEquippedDecorationInstanceId, nInstanceId)
    end
    self.nEquippedDecorationInstanceId = nil
end

function WearComponent:IsDecorationItemEquiped(nInstanceId)
    if nInstanceId then
        return self.nEquippedDecorationInstanceId == nInstanceId
    end
    return false
end

return WearComponent
