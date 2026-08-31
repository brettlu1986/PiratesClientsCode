-----------------------------------------------------
--File Name    : ItemSystem.lua
--Author       : zhiyuan
--Create Time  : 2019-02-26
--Description  : 大厅里的道具系统
-----------------------------------------------------
local ItemSystem = {}

local PlayerSelfHelper = require("GamePlayerSelfHelper")
local Proto = require("ClientProtoNames")
local NetworkManager = dynamic_require("NetworkManager")
local ItemDataTable = require("ItemDataTable")
local ItemCategoryDef = require("ItemCategoryDef")
local ClientEventDef = require("ClientEventDef")
local EventManager = require("EventManager")
local ItemExpireDef = require("ItemExpireDef")

-----------------------------------------local function---------------------------------------------
local function GetItemComponent()
    local PlayerSelf = PlayerSelfHelper:Get()
    local ItemComponent = PlayerSelf.ItemComponent
    if ItemComponent == nil then
        error("GetItemComponent failed!ItemComponent == nil!")
    end
    return ItemComponent
end

local function GetWearComponent()
    local PlayerSelf = PlayerSelfHelper:Get()
    local WearComponent = PlayerSelf.WearComponent
    if WearComponent == nil then
        error("GetWearComponent failed!WearComponent == nil!")
    end
    return WearComponent
end


local function RequestPutOnWear(nInstanceId)
    local c2s_putOnWear =
    {
        instance_id = nInstanceId
    }
    NetworkManager:GetHubServerProxy():SendPacket(Proto.c2s_putOnWear, c2s_putOnWear)
end

local function RequestTakeOffWear(nInstanceId)
    local c2s_takeOffWear =
    {
        instance_id = nInstanceId
    }
    NetworkManager:GetHubServerProxy():SendPacket(Proto.c2s_takeOffWear, c2s_takeOffWear)
end

local function TakeOffItem(self, Item)
    local nTakeOffInstanceId = Item:GetInstanceId()
    local nCategory = Item:GetCategory()
    local WearComponent = GetWearComponent()
    if nCategory == ItemCategoryDef.FASHION then
        WearComponent:UnequipFashionItem(nTakeOffInstanceId)
        EventManager:OnFireEvent(ClientEventDef.EV_UNEQUIP_LOBBY_FASHION, nTakeOffInstanceId)
    elseif nCategory == ItemCategoryDef.DECORATION then
        WearComponent:UnequipDecorationItem(nTakeOffInstanceId)
        EventManager:OnFireEvent(ClientEventDef.EV_UNEQUIP_LOBBY_DECORATION, nTakeOffInstanceId)
    elseif nCategory == ItemCategoryDef.HUMAN_WEAPON_FASHION then
        WearComponent:UnequipWeaponFashionItem(nTakeOffInstanceId)
        EventManager:OnFireEvent(ClientEventDef.EV_UNEQUIP_LOBBY_WEAPON_FASHION, nTakeOffInstanceId)
    end
end

local function PutOnItem(self, Item)
    local nPutOnInstanceId = Item:GetInstanceId()
    local nCategory = Item:GetCategory()
    local WearComponent = GetWearComponent()
    if nCategory == ItemCategoryDef.FASHION then
        local nSubCategory = Item:GetSubCategory()
        local nFashionType = Item.nFashionType
        local nEquippedFashion = WearComponent:GetEquippedFashionItemBySubCategory(nFashionType, nSubCategory)
        if nEquippedFashion ~= nil then
            logerror("Cannot equip same subcategory fashion!", nSubCategory)
        end
        WearComponent:EquipFashionItem(nPutOnInstanceId)
        EventManager:OnFireEvent(ClientEventDef.EV_EQUIP_LOBBY_FASHION, nPutOnInstanceId)
    elseif nCategory == ItemCategoryDef.HUMAN_WEAPON_FASHION then
        WearComponent:EquipWeaponFashionItem(nPutOnInstanceId)
        EventManager:OnFireEvent(ClientEventDef.EV_EQUIP_LOBBY_WEAPON_FASHION, nPutOnInstanceId)
    elseif nCategory == ItemCategoryDef.DECORATION then
        WearComponent:EquipDecorationItem(nPutOnInstanceId)
        EventManager:OnFireEvent(ClientEventDef.EV_EQUIP_LOBBY_DECORATION, nPutOnInstanceId)
    end
end

-----------------------------------------System Init UnInit---------------------------------------------

function ItemSystem:Init()
    return true
end

function ItemSystem:Uninit()
end

-----------------------------------------给外部模块的调用接口---------------------------------------------

-- 获得道具配置
-- @param nItemTemplateId 道具类型id
-- @return tbItemTemplate
function ItemSystem:GetItemTemplate(nItemTemplateId)
    return ItemDataTable:GetTemplate(nItemTemplateId)
end

-- 获得道具资源配置
-- @param nItemTemplateId 道具类型id
-- @return tbItemResTemplate
function ItemSystem:GetItemResTemplate(nItemTemplateId)
    return ItemDataTable:GetResTemplate(nItemTemplateId)
end

-- 获得某个大类型的所有道具配置
-- @param nItemCategory 道具大类
-- @return tbItemTemplates
function ItemSystem:GetItemTemplatesByCategory(nItemCategory)
    return ItemDataTable:GetTemplatesByCategory(nItemCategory)
end

-- 获得某个道具的实例
-- @param nItemInstanceId 道具instanceid
-- @return Item
function ItemSystem:GetItem(nItemInstanceId)
    local ItemComponent = GetItemComponent()
    return ItemComponent:GetItem(nItemInstanceId)
end

-- 获得某个大类型的所有道具列表
-- @param nItemCategory 道具大类
-- @return tbItems 道具列表
function ItemSystem:GetItemsByCategory(nItemCategory)
    local ItemComponent = GetItemComponent()
    return ItemComponent:GetItemsByCategory(nItemCategory)
end

-- 获得某个物品id的所有道具列表
-- @param nItemTemplateId 道具类型id
-- @return tbItems 道具列表
function ItemSystem:GetItemsByTemplateId(nItemTemplateId)
    local ItemComponent = GetItemComponent()
    return ItemComponent:GetItemsByTemplateId(nItemTemplateId)
end

-- 获得某个类型的道具的数量
-- @param nItemTemplateId 道具类型id
-- @return nCount 数量
function ItemSystem:GetItemCount(nItemTemplateId)
    local ItemComponent = GetItemComponent()
    return ItemComponent:GetItemCount(nItemTemplateId)
end

-- 获得已装配的人的时装道具列表
-- @return tbItems 已装配的人的时装道具列表
function ItemSystem:GetEquippedFashionItems()
    local WearComponent = GetWearComponent()
    return WearComponent:GetEquippedFashionItems()
end

function ItemSystem:GetEquippedWeaponFashionItems()
    local WearComponent = GetWearComponent()
    return WearComponent:GetEquippedWeaponFashionItems()
end

function ItemSystem:GetEquippedWeaponFashionItem(nWeaponInstanceType)
    local WearComponent = GetWearComponent()
    return WearComponent:GetEquippedWeaponFashionItem(nWeaponInstanceType)
end

function ItemSystem:GetEquipedFashionItemsByType(nFashionType)
    local WearComponent = GetWearComponent()
    return WearComponent:GetEquipedFashionItemsByType(nFashionType)
end

function ItemSystem:GetEquipedFashionItem(nFashionType, nSlotType)
    local WearComponent = GetWearComponent()
    return WearComponent:GetEquippedFashionItemBySubCategory(nFashionType, nSlotType)
end

-- 获得已装配的人的战备道具列表
-- @return Item 已装配的人的饰品道具
function ItemSystem:GetEquippedDecorationItem()
    local WearComponent = GetWearComponent()
    return WearComponent:GetEquippedDecorationItem()
end

-- 获得道具介绍
-- @param nItemTemplateId 道具类型id
-- @return 道具介绍
function ItemSystem:GetItemIntro(nItemTemplateId)
    local tbTemplate = ItemDataTable:GetTemplate(nItemTemplateId)
    local nCategory = tbTemplate.nCategory
    if nCategory == ItemCategoryDef.SAILOR then
        local SailorComponent = PlayerSelfHelper:Get().SailorComponent
        return SailorComponent:GetSailorIntroduce(nItemTemplateId)
    else
        return tbTemplate.l10nIntro
    end
end

-- 道具是否能使用
-- @param nItemTemplateId 道具类型id
-- @return true表示能使用，false表示不能
function ItemSystem:CanUseInBackpack(nItemTemplateId)
    local tbTemplate = ItemDataTable:GetTemplate(nItemTemplateId)
    local nCategory = tbTemplate.nCategory
    local bCanUseInBackpack = ItemCategoryDef:CanUseInBackpack(nCategory)
    if not bCanUseInBackpack then
        return false
    end
    if nCategory ~= ItemCategoryDef.UNLOCK_ITEM then
        return true
    end
    local nUnlockItemTemplateId = tbTemplate.nUnlockItemTemplateId
    local tbUnlockItemTemplate = ItemDataTable:GetTemplate(nUnlockItemTemplateId)
    if tbUnlockItemTemplate.nExpireType == ItemExpireDef.NORMAL then
        error("Cannot unlock item which expiretype is normal!")
    end
    if tbUnlockItemTemplate.nCategory == ItemCategoryDef.SUIT then
        local bOwned, tbItems = ItemSystem:HasFashionItem(nUnlockItemTemplateId)
        if not bOwned then
            return true
        end
        for _, tbItem in ipairs(tbItems) do
            if tbItem:HasExpiration() then
                return true
            end
        end
        return false
    else
        local tbItems = self:GetItemsByTemplateId(nUnlockItemTemplateId)
        if tbItems == nil or #tbItems == 0 then
            return true
        end
        local bHasNonExpiredItem = false
        for _, v in pairs(tbItems) do
            if not v:HasExpiration() then
                bHasNonExpiredItem = true
                break
            end
        end
        if bHasNonExpiredItem then
            return false
        else
            return true
        end
    end
end


function ItemSystem:IsEquiped(nItemInstanceId)
    local tbItem = ItemSystem:GetItem(nItemInstanceId)
    if tbItem then
        local WearComponent = GetWearComponent()
        local nCategory = tbItem:GetCategory()
        if nCategory == ItemCategoryDef.FASHION then
            return WearComponent:IsHumanFashionEquiped(nItemInstanceId)
        elseif nCategory == ItemCategoryDef.HUMAN_WEAPON_FASHION then
            return WearComponent:IsHumanWeaponFashionEquiped(nItemInstanceId)
        elseif nCategory == ItemCategoryDef.DECORATION then
            return WearComponent:IsDecorationItemEquiped(nItemInstanceId)
        end
        return false
    end
    return false
end

-- @return 是否拥有
-- @return tbItems 如果nItemTemplateId是散件，则返回相应的tbItem，
--                       如果nItemTemplateId是套装，返回包含的所有散件的tbItem
function ItemSystem:HasFashionItem(nItemTemplateId)
    local tbTemplate = self:GetItemTemplate(nItemTemplateId)
    local nCategory = tbTemplate.nCategory
    if nCategory == ItemCategoryDef.SUIT then
        local tbResult = {}
        local tbSubItemTemplateIds = tbTemplate.tbSubItemTemplateIds
        for _, nSubItemTemplateId in ipairs(tbSubItemTemplateIds) do
            local tbData = self:GetItemsByTemplateId(nSubItemTemplateId)
            if #tbData > 0 then
                table.insert(tbResult, tbData[1])
            else
                return false, {}
            end
        end
        return true, tbResult
    elseif nCategory == ItemCategoryDef.FASHION then
        local tbResult = self:GetItemsByTemplateId(nItemTemplateId)
        return #tbResult > 0, tbResult
    else
        logerror("ItemSystem:HasFashionItem, category does not match! id : ", nItemTemplateId)
        return false, {}
    end
end

function ItemSystem:IsEquipedFashionItem(nItemTemplateId)
    local bHas, tbItems = self:HasFashionItem(nItemTemplateId)
    if bHas then
        for _, tbItem in ipairs(tbItems) do
            local nItemInstanceId = tbItem:GetInstanceId()
            if not ItemSystem:IsEquiped(nItemInstanceId) then
                return false
            end
        end
        return true
    else
        return false
    end
end

function ItemSystem:GetHumanFashionFlag()
    local WearComponent = GetWearComponent()
    return WearComponent:GetHumanFashionFlag()
end

-----------------------------------------玩家不同的操作的方法---------------------------------------------
-- 请求出售道具
function ItemSystem:RequestSellItem(nInstanceId, nCount)
    local c2s_SellItem =
    {
        instance_id = nInstanceId,
        count = nCount
    }
    NetworkManager:GetHubServerProxy():SendPacket(Proto.c2s_SellItem, c2s_SellItem)
end

-- 请求使用道具
function ItemSystem:RequestUseItem(nInstanceId, nCount, szParam1, szParam2, szParam3)
    local c2s_UseItem =
    {
        instance_id = nInstanceId,
        count = nCount,
        param1 = szParam1,
        param2 = szParam2,
        param3 = szParam3
    }
    NetworkManager:GetHubServerProxy():SendPacket(Proto.c2s_UseItem, c2s_UseItem)
end

-- 穿上一个人的时装
function ItemSystem:RequestEquipFashionItem(nInstanceId)
    RequestPutOnWear(nInstanceId)
end

-- 脱下一个人的时装
function ItemSystem:RequestUnequipFashionItem(nInstanceId)
    RequestTakeOffWear(nInstanceId)
end

-- 穿脱一体化
function ItemSystem:RequestToFitFashion(tbPutOnInstanceIds, tbTakeOffInstanceIds)
    local tbPutOn = {}
    for _, nInstanceId in ipairs(tbPutOnInstanceIds) do
        local bEquiped = self:IsEquiped(nInstanceId)
        if not bEquiped then
            table.insert(tbPutOn, nInstanceId)
        end
    end

    local tbTakeOff = {}
    for _, nInstanceId in ipairs(tbTakeOffInstanceIds) do
        local bEquiped = self:IsEquiped(nInstanceId)
        if bEquiped then
            table.insert(tbTakeOff, nInstanceId)
        end
    end

    local c2s_fitFashion =
    {
        put_on_instance_id = tbPutOn,
        take_off_instance_id = tbTakeOff
    }
    NetworkManager:GetHubServerProxy():SendPacket(Proto.c2s_fitFashion, c2s_fitFashion)
end

-- 穿上一个人的饰品
function ItemSystem:RequestEquipDecorationItem(nInstanceId)
    -- RequestPutOnWear(nInstanceId)
    local c2s_PutOnDecoration =
    {
        instance_id = nInstanceId
    }
    NetworkManager:GetHubServerProxy():SendPacket(Proto.c2s_PutOnDecoration, c2s_PutOnDecoration)
end

-- 脱下一个人的饰品
function ItemSystem:RequestUnequipDecorationItem()
    local CurrentDecoration = self:GetEquippedDecorationItem()
    if not CurrentDecoration then return end
    local c2s_TakeOffDecoration =
    {
        instance_id = CurrentDecoration:GetInstanceId()
    }
    NetworkManager:GetHubServerProxy():SendPacket(Proto.c2s_TakeOffDecoration, c2s_TakeOffDecoration)
    -- RequestTakeOffWear(CurrentDecoration:GetInstanceId())
end

function ItemSystem:RequestGetCurrentDecoration()
    NetworkManager:GetHubServerProxy():SendPacket(Proto.c2s_GetDecoration)
end

function ItemSystem:RequestGetRenameTimes()
    NetworkManager:GetHubServerProxy():SendPacket(Proto.c2s_GetRenameTimes)
end

function ItemSystem:RequestUpgradeCurrentDecoration(nInstanceId)
    local c2s_UpgradeDecoration =
    {
        instance_id = nInstanceId
    }
    NetworkManager:GetHubServerProxy():SendPacket(Proto.c2s_UpgradeDecoration, c2s_UpgradeDecoration)
end

function ItemSystem:RequestToModifyFashionFlag(nFlag)
    local c2s_dryFashionFlag = {
        flag = nFlag
    }
    NetworkManager:GetHubServerProxy():SendPacket(Proto.c2s_dryFashionFlag, c2s_dryFashionFlag)
end

-----------------------------------------处理server发过来的道具数据同步---------------------------------------------------
-- 获取新道具
function ItemSystem:OnAddItem(tbItemDatas)
    local ItemComponent = GetItemComponent()
    return ItemComponent:AddItems(tbItemDatas)
end

-- 同步Item堆叠数量
function ItemSystem:OnSyncItemStackCount(nInstanceId, nStackCount, nCreateTime)
    EventManager:OnFireEvent(ClientEventDef.EV_CLIENT_LOG_EVENT_ITEM_CONSUME, nInstanceId, nStackCount) --位置不能变
    local ItemComponent = GetItemComponent()
    ItemComponent:SetItemStackCount(nInstanceId, nStackCount)
    if nCreateTime ~= nil and nCreateTime > 0 then
        ItemComponent:SetItemCreateTime(nInstanceId, nCreateTime)
    end
end

-- 同步Item过期时间
function ItemSystem:OnSyncItemExpiredAt(nInstanceId, nExpiredAt)
    local ItemComponent = GetItemComponent()
    ItemComponent:SetItemExpiredAtSeconds(nInstanceId, nExpiredAt)
end

-- 删除道具
function ItemSystem:OnRemoveItem(nInstanceId)
    local ItemComponent = GetItemComponent()
    return ItemComponent:RemoveItem(nInstanceId)
end

-- 同步外装和饰品的变化
function ItemSystem:OnSyncWear(nTakeOffInstanceId, nPutOnInstanceId)
    if nTakeOffInstanceId ~= nil and nTakeOffInstanceId > 0 then
        local ItemNeedTakeOff = self:GetItem(nTakeOffInstanceId)
        if ItemNeedTakeOff == nil then
            logerror("Cannot find item to takeoff!", nTakeOffInstanceId)
        else
            TakeOffItem(self, ItemNeedTakeOff)
        end
    end
    if nPutOnInstanceId ~= nil and nPutOnInstanceId > 0 then
        local ItemNeedPutOn = self:GetItem(nPutOnInstanceId)
        if ItemNeedPutOn == nil then
            logerror("Cannot find item to puton!", nPutOnInstanceId)
        else
            PutOnItem(self, ItemNeedPutOn)
        end
    end
end

function ItemSystem:OnFitFashion(tbTakeOffInstanceIds, tbPutOnInstanceIds)
    if tbTakeOffInstanceIds then
        for _, nTakeOffInstanceId in ipairs(tbTakeOffInstanceIds) do
            if nTakeOffInstanceId ~= nil and nTakeOffInstanceId > 0 then
                local ItemNeedTakeOff = self:GetItem(nTakeOffInstanceId)
                if ItemNeedTakeOff == nil then
                    logerror("Cannot find item to takeoff!", nTakeOffInstanceId)
                else
                    TakeOffItem(self, ItemNeedTakeOff)
                end
            end
        end
    end
    
    if tbPutOnInstanceIds then
        for _, nPutOnInstanceId in ipairs(tbPutOnInstanceIds) do
            if nPutOnInstanceId ~= nil and nPutOnInstanceId > 0 then
                local ItemNeedPutOn = self:GetItem(nPutOnInstanceId)
                if ItemNeedPutOn == nil then
                    logerror("Cannot find item to puton!", nPutOnInstanceId)
                else
                    PutOnItem(self, ItemNeedPutOn)
                end
            end
        end
    end
    EventManager:OnFireEvent(ClientEventDef.EV_LOBBY_FASHION_DO_CHANGED, tbTakeOffInstanceIds, tbPutOnInstanceIds)
end

function ItemSystem:OnHumanFashionFlagModified(nFlag)
    local WearComponent = GetWearComponent()
    WearComponent:SetHumanFashionFlag(nFlag)
    EventManager:OnFireEvent(ClientEventDef.EV_LOBBY_FASHION_FLAG_MODIFIED, nFlag)
end



return ItemSystem
