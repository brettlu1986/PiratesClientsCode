-----------------------------------------------------
--File Name    : SceneItemContainer.lua
--Author       : zhiyuan
--Create Time  : 2018-08-11
--Description  : 整个游戏世界中场景中的物品管理System
-----------------------------------------------------
local BattleItemRoomDef = require("BattleItemRoomDef")
local BattleItemCategoryDef = require("BattleItemCategoryDef")
local NetworkManager = dynamic_require("NetworkManager")
local ProtoDC = require("DungeonCommonProtoNames")
local GameObjectSystem = dynamic_require("GameObjectSystem")
local EventManager = require("EventManager")
local CommonEventDef = require("CommonEventDef")
local SceneItemHelper = require("SceneItemHelper")
local SceneItemActorDef = require("SceneItemActorDef")
local BattleItemSystemHelper = require("BattleItemSystemHelper")

local SceneItemContainer = {}

-- 记录场景中每个物品包对应的物品id列表
-- key : nRoomInstanceId
-- value : ItemRoom
local tbAllItemRoomMap = {}

-- 记录每个玩家都在查看哪些场景物品
-- key : nCharacterInstanceId
-- value : nItemInstanceId:true
local tbCharacterViewSceneItems = {}

-- 记录每个item正在被哪些玩家查看
-- key : nItemInstanceId
-- value: nCharacterInstanceId:true
local tbItemRelatedCharacters = {}

-- 用来生成给客户端查看道具的协议id，为了解决道具太多的问题，需要拆分数据分多次发送
local nMaxViewItemPackageId = 0

local nSceneItemPackageRoomType = BattleItemRoomDef.SCENE_ITEM_ROOM

local VIEW_ITEM_MAX = 50

local BattleItemSystemServer = nil

local function LogSyncSceneItemsDetail(...)
    log("[SyncSceneItemsDetail] server", ...)
end

local function GetSceneItemPackageRoomClass()
    return BattleItemRoomDef:GetItemRoomClass(nSceneItemPackageRoomType)
end

local function GetRoom(nRoomInstanceId)
    return tbAllItemRoomMap[nRoomInstanceId]
end

local function GetCharacterViewItemInstanceIds(nCharacterInstanceId)
    local tbItemInstanceIds = tbCharacterViewSceneItems[nCharacterInstanceId]
    if tbItemInstanceIds == nil then
        return {}
    end
    return tbItemInstanceIds
end

local function GetItemRelatedCharacterInstanceIds(nItemInstanceId)
    local tbRelatedCharacters = tbItemRelatedCharacters[nItemInstanceId]
    if tbRelatedCharacters == nil then
        return {}
    end
    return tbRelatedCharacters
end

local function AddCharacterViewItemInstanceId(nCharacterInstanceId, nItemInstanceId)
    local tbItemInstanceIds = tbCharacterViewSceneItems[nCharacterInstanceId]
    if tbItemInstanceIds == nil then
        tbCharacterViewSceneItems[nCharacterInstanceId] = {}
        tbItemInstanceIds = tbCharacterViewSceneItems[nCharacterInstanceId]
    end
    tbItemInstanceIds[nItemInstanceId] = true

    local tbCharacterInstanceIds = tbItemRelatedCharacters[nItemInstanceId]
    if tbCharacterInstanceIds == nil then
        tbItemRelatedCharacters[nItemInstanceId] = {}
        tbCharacterInstanceIds = tbItemRelatedCharacters[nItemInstanceId]
    end
    tbCharacterInstanceIds[nCharacterInstanceId] = true
end

local function RemoveItemRelatedCharacterInstanceId(nCharacterInstanceId, nItemInstanceId)
    local tbCharacterInstanceIds = tbItemRelatedCharacters[nItemInstanceId]
    if tbCharacterInstanceIds ~= nil then
        tbCharacterInstanceIds[nCharacterInstanceId] = nil
    end
end

local function RemoveAllCharacterViewItemInstanceIds(nCharacterInstanceId)
    local tbItemInstanceIds = GetCharacterViewItemInstanceIds(nCharacterInstanceId)
    if tbItemInstanceIds ~= nil then
        for nItemInstanceId, _ in pairs(tbItemInstanceIds) do
            RemoveItemRelatedCharacterInstanceId(nCharacterInstanceId, nItemInstanceId)
        end
    end
    tbCharacterViewSceneItems[nCharacterInstanceId] = nil
end

local function RemoveCharacterViewItemInstanceId(nCharacterInstanceId, nItemInstanceId)
    local tbItemInstanceIds = tbCharacterViewSceneItems[nCharacterInstanceId]
    if tbItemInstanceIds ~= nil then
        tbItemInstanceIds[nItemInstanceId] = nil
    end
end

local function RemoveAllItemRelatedCharacterInstanceIds(nItemInstanceId)
    local tbCharacterInstanceIds = GetItemRelatedCharacterInstanceIds(nItemInstanceId)
    if tbCharacterInstanceIds ~= nil then
        for nCharacterInstanceId, _ in pairs(tbCharacterInstanceIds) do
            RemoveCharacterViewItemInstanceId(nCharacterInstanceId, nItemInstanceId)
        end
    end
    tbItemRelatedCharacters[nItemInstanceId] = nil
end

local function OnLogout(self, tbPlayer)
    RemoveAllCharacterViewItemInstanceIds(tbPlayer.nServerInstanceId)
end

local function OnPlayerDie(self, tbPlayer)
    RemoveAllCharacterViewItemInstanceIds(tbPlayer.nServerInstanceId)
end

local function CreateActorAndBindToItem(Item, tbTransform, nSceneItemActorType, bRandomPosition, bIsShip, nHumanMovementStateType)
    local tbTransformAfterRandom = tbTransform
    local nYaw = tbTransform.Yaw

    if nSceneItemActorType == SceneItemActorDef.ITEM and bRandomPosition then -- 单个物品要做位置偏移,bRandomPosition在最开始生成地上物品时，如果只有一个，就不随机
        tbTransformAfterRandom, nYaw = Item:GetCreateActorPosition(tbTransform)
    end
    local nActorType = SceneItemActorDef.ITEM
    local nCategory = Item:GetCategory()
    local tbTemplate = Item:GetTemplate()
    if nCategory == BattleItemCategoryDef.SCENE_ITEM_PACKAGE then
        nActorType = nSceneItemActorType
    elseif tbTemplate.bSightFree then
        nActorType = SceneItemActorDef.SIGHT_FREE_ITEM
    end

    local tbParam =
    {
        nResId = tbTemplate.nResId,                         -- 物品的resid，用来显示掉落时的模型
        nItemInstanceId = Item:GetInstanceId(),             -- 物品的唯一标识
        nItemActorType = nActorType,                        -- 1表示单个物品，2表示死亡后箱子，3表示空投箱子（对应枚举SceneItemActorDef）
        bIsShip = bIsShip,                                  -- nil表示不是玩家相关的，true表示船状态，false表示人状态
        nHumanMovementStateType = nHumanMovementStateType,  -- 只有人状态时有效
        nItemTemplateId = Item:GetTemplateId(),             -- 物品的类型id
    }

    local tbSceneActor = SceneItemHelper:Create(tbParam, tbTransformAfterRandom, nYaw)
    Item:SetSceneActor(tbSceneActor)

    EventManager:OnFireEvent(CommonEventDef.EV_SCENE_ITEM_ADD, Item, tbTransformAfterRandom.X, tbTransformAfterRandom.Y, tbTransformAfterRandom.Z)
end

local function DestroyActorAndUnbindToItem(Item)
    SceneItemHelper:Destroy(Item:GetSceneActor().nServerInstanceId)
    Item:SetSceneActor(nil)
end

local function GetOwnerUEControllerUniqueId(nCharacterInstanceId)
    local tbPlayer = GameObjectSystem:FindByInstanceId(nCharacterInstanceId)
    return tbPlayer:GetUEControllerUniqueId()
end

local function GetNextMaxViewItemPackageId()
    nMaxViewItemPackageId = nMaxViewItemPackageId + 1
    return nMaxViewItemPackageId
end

local function SyncSceneItemsDetail(nCharacterInstanceId, tbItemsDetail)
    local nUEControllerUniqueId = GetOwnerUEControllerUniqueId(nCharacterInstanceId)
    NetworkManager:GetRPCNetworkProxy():SendToClient(nUEControllerUniqueId, ProtoDC.d2c_SyncSceneItemsDetail, tbItemsDetail)
end

local function GetNewSceneItemDetail(nViewItemPackageId)
    local tbItemsDetail = {}
    tbItemsDetail.scene_rooms = {}
    tbItemsDetail.items = {}
    tbItemsDetail.package_id = nViewItemPackageId
    return tbItemsDetail
end

local function GetNewRoomData(tbRoom)
    local tbNewRoom = {}
    tbNewRoom.instance_id = tbRoom.instance_id
    tbNewRoom.last_owner_name = tbRoom.last_owner_name
    tbNewRoom.template_id = tbRoom.template_id
    tbNewRoom.items = {}
    return tbNewRoom
end

local function AddSceneItemToDetails(tbItemsDetail, tbItem, tbRoom)
    if tbRoom then
        local tbSceneRoomDatas = tbItemsDetail.scene_rooms
        local tbSceneRoom = nil
        for _, v in ipairs(tbSceneRoomDatas) do
            if v.instance_id == tbRoom.instance_id then
                tbSceneRoom = v
                break
            end
        end
        if tbSceneRoom == nil then
            tbSceneRoom = GetNewRoomData(tbRoom)
            table.insert(tbItemsDetail.scene_rooms, tbSceneRoom)
        end
        table.insert(tbSceneRoom.items, tbItem)
    else
        table.insert(tbItemsDetail.items, tbItem)
    end
end

local function SplitItemsDataAndSyncDetail(nCharacterInstanceId, tbItems, tbNeedSendDetail, nCount, tbNeedSendList, nViewItemPackageId, tbRoom)
    for _, tbItem in ipairs(tbItems) do
        if tbNeedSendDetail == nil then
            tbNeedSendDetail = GetNewSceneItemDetail(nViewItemPackageId)
        end
        AddSceneItemToDetails(tbNeedSendDetail, tbItem, tbRoom)
        nCount = nCount + 1
        if nCount == VIEW_ITEM_MAX then
            table.insert(tbNeedSendList, tbNeedSendDetail)
            tbNeedSendDetail = nil
            nCount = 0
        end
    end
    return tbNeedSendDetail, nCount
end

local function FillBattleItemSystemServer()
    if not BattleItemSystemServer then
        BattleItemSystemServer = BattleItemSystemHelper:GetBattleItemSystemServer()
    end
end

local function SplitDataAndSyncSceneItemsDetail(nCharacterInstanceId, tbItemsDetail, nRequestId)
    local nBeginTime = BattleItemSystemServer:GetViewItemRequestTime(nRequestId)
    local nBeforeSplitTime = getseconds() * 1000
    LogSyncSceneItemsDetail("beforesplit:", nRequestId, nBeforeSplitTime - nBeginTime, nBeforeSplitTime, nBeginTime)
    local tbNeedSendList = {}
    local nCount = 0
    local tbSceneRooms = tbItemsDetail.scene_rooms
    local nViewItemPackageId = GetNextMaxViewItemPackageId()
    local tbNeedSendDetail = GetNewSceneItemDetail(nViewItemPackageId)
    if tbSceneRooms ~= nil and #tbSceneRooms > 0 then
        for _, tbRoom in ipairs(tbSceneRooms) do
            local tbSceneRoom = GetNewRoomData(tbRoom)
            if tbNeedSendDetail == nil then
                tbNeedSendDetail = GetNewSceneItemDetail(nViewItemPackageId)
            end
            table.insert(tbNeedSendDetail.scene_rooms, tbSceneRoom)
            local tbItems = tbRoom.items
            tbNeedSendDetail, nCount = SplitItemsDataAndSyncDetail(nCharacterInstanceId, tbItems, tbNeedSendDetail, nCount, tbNeedSendList, nViewItemPackageId, tbRoom)
        end
    end

    local tbItems = tbItemsDetail.items
    if tbItems ~= nil and #tbItems > 0 then
        tbNeedSendDetail, nCount = SplitItemsDataAndSyncDetail(nCharacterInstanceId, tbItems, tbNeedSendDetail, nCount, tbNeedSendList, nViewItemPackageId)
    end

    if tbNeedSendDetail then
        table.insert(tbNeedSendList, tbNeedSendDetail)
    end

    local nPackageCount = #tbNeedSendList
    for i, v in ipairs(tbNeedSendList) do
        if i == nPackageCount then
            v.is_last_package = true
        end
        SyncSceneItemsDetail(nCharacterInstanceId, v)
    end
    local nEndTime = getseconds() * 1000
    LogSyncSceneItemsDetail("split package:", nRequestId, nEndTime - nBeforeSplitTime, nEndTime, nBeforeSplitTime, nBeginTime)
    local nInterval = nEndTime - nBeginTime
    LogSyncSceneItemsDetail("finish:", nRequestId, nInterval, nEndTime, nBeginTime)
    BattleItemSystemServer:GetAndRemoveViewItemRequestTime(nRequestId)
end

local function SyncSceneItemAdd(nCharacterInstanceId, Item)
    local d2c_SyncAddSceneItem =
    {
        nRoomInstanceId = Item:GetStorageLocation().nOwnerInstanceId,
        item = Item:GetProtoData()
    }
    NetworkManager:GetRPCNetworkProxy():SendToClient(GetOwnerUEControllerUniqueId(nCharacterInstanceId), ProtoDC.d2c_SyncAddSceneItem, d2c_SyncAddSceneItem)
end

local function SyncSceneItemRemove(nCharacterInstanceId, Item)
    local d2c_SyncRemoveSceneItem =
    {
        instance_id = Item:GetInstanceId()
    }
    NetworkManager:GetRPCNetworkProxy():SendToClient(GetOwnerUEControllerUniqueId(nCharacterInstanceId), ProtoDC.d2c_SyncRemoveSceneItem, d2c_SyncRemoveSceneItem)
end

local function SyncScenePackageRemove(nCharacterInstanceId, nInstanceId)
    local d2c_SyncRemoveScenePackage =
    {
        instance_id = nInstanceId
    }
    NetworkManager:GetRPCNetworkProxy():SendToClient(GetOwnerUEControllerUniqueId(nCharacterInstanceId), ProtoDC.d2c_SyncRemoveScenePackage, d2c_SyncRemoveScenePackage)
end

local function AddSingleItemToSceneByType(nItemTemplateId, nItemCount, tbTransform, nSceneItemActorType, bRandomPosition, bIsShip, nHumanMovementStateType)
    local Item = BattleItemSystemServer:CreateItem(nItemTemplateId, nItemCount)
    CreateActorAndBindToItem(Item, tbTransform, nSceneItemActorType, bRandomPosition, bIsShip, nHumanMovementStateType)
    return Item
end

local function RemoveItemRoom(self, ItemRoom, bSyncToClient)
    if bSyncToClient then
        local nOwnerItemInstanceId = ItemRoom:GetRoomId()
        local tbRelatedCharacterInstanceIds = GetItemRelatedCharacterInstanceIds(nOwnerItemInstanceId)
        for nCharacterInstanceId, _ in pairs(tbRelatedCharacterInstanceIds) do
            SyncScenePackageRemove(nCharacterInstanceId, nOwnerItemInstanceId)
        end
    end

    tbAllItemRoomMap[ItemRoom:GetRoomId()] = nil
end

local function SyncSceneItemRemoveToAllRelatedCharacter(nOwnerItemInstanceId, Item)
    local tbRelatedCharacterInstanceIds = GetItemRelatedCharacterInstanceIds(nOwnerItemInstanceId)
    for nCharacterInstanceId, _ in pairs(tbRelatedCharacterInstanceIds) do
        SyncSceneItemRemove(nCharacterInstanceId, Item)
    end
end

local function SyncSceneItemAddToAllRelatedCharacter(nOwnerItemInstanceId, Item)
    local tbRelatedCharacterInstanceIds = GetItemRelatedCharacterInstanceIds(nOwnerItemInstanceId)
    for nCharacterInstanceId, _ in pairs(tbRelatedCharacterInstanceIds) do
        SyncSceneItemAdd(nCharacterInstanceId, Item)
    end
end

local function OnRemoveItem(nOwnerItemInstanceId, Item)
    SyncSceneItemRemoveToAllRelatedCharacter(nOwnerItemInstanceId, Item)
    RemoveAllItemRelatedCharacterInstanceIds(Item:GetInstanceId())
end

local function RemoveItem(self, Item, bSyncToClient)
    if Item:GetSceneActor() then
        DestroyActorAndUnbindToItem(Item)
    end

    local tbStorageLocation = Item:GetStorageLocation()
    local ItemRoom = GetRoom(tbStorageLocation.nOwnerInstanceId)
    if ItemRoom then
        ItemRoom:RemoveItemByInstanceId(Item:GetInstanceId())
        if bSyncToClient then
            local nOwnerItemInstanceId = ItemRoom:GetRoomId()
            OnRemoveItem(nOwnerItemInstanceId, Item)
        end
    else
        OnRemoveItem(Item:GetInstanceId(), Item)
    end
    Item:ClearStorageLocationAndOwner()
    return ItemRoom
end

local function SetActorPickOut(Item)
    if Item == nil then
        logerror("SetActorPickOut failed!Item is nil!")
        return
    end

    local tbActor = Item:GetSceneActor()
    if(not SceneItemHelper:SetPickOut(Item:GetInstanceId(), tbActor)) then
        error(string.format("SetActorPickOut failed! item templateid: %d, instanceid: %d", Item:GetTemplateId(), Item:GetInstanceId()))
    end
end

function SceneItemContainer:Init()
    FillBattleItemSystemServer()
    EventManager:BindEventMethod(CommonEventDef.EV_BATTLE_PLAYER_LOGOUT, self, OnLogout)
    EventManager:BindEventMethod(CommonEventDef.EV_GAME_OBJECT_ON_PAWN_DEAD, self, OnPlayerDie)
    return true
end

function SceneItemContainer:Uninit()
    EventManager:UnBindEventMethod(CommonEventDef.EV_BATTLE_PLAYER_LOGOUT, self, OnLogout)
    EventManager:UnBindEventMethod(CommonEventDef.EV_GAME_OBJECT_ON_PAWN_DEAD, self, OnPlayerDie)
end

-- 某个玩家开始查看场景中的物品
-- @param nCharacterInstanceId LuaCharacter的nServerInstanceId
-- @param tbItemInstanceIds: 物品nItemInstanceId的数组
-- @return 所有相关的地上的物品数据（具体结构还需要根据UI需求定一下）
function SceneItemContainer:BeginViewItemsDetail(nCharacterInstanceId, tbItemInstanceIds, nRequestId)
    RemoveAllCharacterViewItemInstanceIds(nCharacterInstanceId)
    local tbItemsDetail = GetNewSceneItemDetail()
    local tbSceneRoomDatas = tbItemsDetail.scene_rooms
    local tbItemDatas = tbItemsDetail.items

    local tbPlayer = GameObjectSystem:FindByInstanceId(nCharacterInstanceId)

    for _, v in ipairs(tbItemInstanceIds) do
        local Item = BattleItemSystemServer:GetItem(v)
        if Item then
            if not Item:HasOwnerCharacter() then
                -- todo @zhiyuan 检查物品位置是否过远
                local nCategory = Item:GetCategory()
                if nCategory == BattleItemCategoryDef.SCENE_ITEM_PACKAGE then
                    local ItemRoom = GetRoom(v)
                    if ItemRoom == nil then
                        logerror("Item is SCENE_ITEM_PACKAGE but cannot found room!", nCategory, v, Item:GetTemplateId())
                        local GlobalVariableSystem = dynamic_require("GlobalVariableSystem")
                        if(GlobalVariableSystem.bEnableTemplateActor) then
                            local Pos = dynamic_require("BattleTemplateActorSystem"):GetCurrentManager():FindLocationByInstanceId(v)
                            error(string.format("Pos: %f, %f, %f", Pos.X, Pos.Y, Pos.Z))
                        end
                    else
                        local tbRoomData = ItemRoom:GetProtoDataOnServer()
                        local tbRoomItemDatas = tbRoomData.items
                        table.insert( tbSceneRoomDatas, tbRoomData)
                        AddCharacterViewItemInstanceId(nCharacterInstanceId, v)
                        local tbRoomItemInstanceIds = ItemRoom:GetAllItemInstanceIds()
                        for _, v1 in ipairs(tbRoomItemInstanceIds) do
                            local ItemInRoom = BattleItemSystemServer:GetItem(v1)
                            table.insert(tbRoomItemDatas, ItemInRoom:GetProtoData())
                        end
                    end
                else
                    table.insert(tbItemDatas, Item:GetProtoData())
                    AddCharacterViewItemInstanceId(nCharacterInstanceId, v)
                end
            else
                log("[VIEW_ITEMS]Item has owner", nCharacterInstanceId, tbPlayer:GetName(), v)
            end
        else
            log("[VIEW_ITEMS]Item not exist", nCharacterInstanceId, tbPlayer:GetName(), v)
        end
    end
    SplitDataAndSyncSceneItemsDetail(nCharacterInstanceId, tbItemsDetail, nRequestId)
end

-- 某个玩家结束查看场景中的物品
-- @param nCharacterInstanceId LuaCharacter的nServerInstanceId
-- @param tbItemInstanceIds: 物品nItemInstanceId的数组
function SceneItemContainer:EndViewItemsDetail(nCharacterInstanceId, tbItemInstanceIds)
    RemoveAllCharacterViewItemInstanceIds(nCharacterInstanceId)
end

-- 创建一个room
function SceneItemContainer:CreateItemRoom(nRoomInstanceId, szLastOwnerName)
    local tbItemRoomClass = GetSceneItemPackageRoomClass()
    local ItemRoom = tbItemRoomClass()
    ItemRoom:Init(nSceneItemPackageRoomType, nRoomInstanceId)
    if szLastOwnerName ~= nil then
        ItemRoom:SetLastOwnerName(szLastOwnerName)
    end

    tbAllItemRoomMap[nRoomInstanceId] = ItemRoom

    return ItemRoom
end

function SceneItemContainer:AddItemToRoom(ItemRoom, Item)
    local bResult = ItemRoom:AddItem(Item:GetInstanceId())
    -- luacheck: push ignore
    if not bResult then
        -- todo @zhiyuan 考虑背包满了装不进去的情况
    end
    -- luacheck: pop
    Item:SetOwnerCharacter(nil)
    Item:SetStorageLocation(nSceneItemPackageRoomType, ItemRoom:GetRoomId())
    local nOwnerItemInstanceId = ItemRoom:GetRoomId()
    SyncSceneItemAddToAllRelatedCharacter(nOwnerItemInstanceId, Item)
end

function SceneItemContainer:AddItem(NewItemRoom, Item, tbTransform, bIsShip, nHumanMovementStateType)
    if not BattleItemSystemHelper:CanKnownByPlayer(Item:GetTemplateId()) then
        BattleItemSystemServer:DestroyItem(Item:GetInstanceId())
        return
    end

    if NewItemRoom ~= nil then
        assert(NewItemRoom:GetRoomType() == BattleItemRoomDef.SCENE_ITEM_ROOM)
        self:AddItemToRoom(NewItemRoom, Item)
        return
    end
    -- local tbViewItemInstanceIds = GetCharacterViewItemInstanceIds(nCharacterInstanceId)
    -- local bInBox = false
    -- if tbViewItemInstanceIds ~= nil then
    --     for k, _ in pairs(tbViewItemInstanceIds) do
    --         local BattleItemSystemServer = BattleItemSystemHelper:GetBattleItemSystemServer()
    --         local ViewItem = BattleItemSystemServer:GetItem(k)
    --         local nCategory = ViewItem:GetCategory()
    --         if nCategory == BattleItemCategoryDef.SCENE_ITEM_PACKAGE then
    --             local ItemRoom = GetRoom(k)
    --             self:AddItemToRoom(ItemRoom, Item)
    --             bInBox = true
    --             break
    --         end
    --     end
    -- end
    -- if not bInBox then
           CreateActorAndBindToItem(Item, tbTransform, SceneItemActorDef.ITEM, true, bIsShip, nHumanMovementStateType)
    -- end
end

-- 往地上增加很多物品，如果nRoomInstanceId为空，就是自动生成一个nRoomInstanceId，如果是死亡掉落，需要szLastOwnerName这个参数
function SceneItemContainer:AddItemsWhenPlayerDie(nRoomInstanceId, tbItemInstanceIds, szCharacterName, tbTransform)
    if tbItemInstanceIds == nil or #tbItemInstanceIds == 0 then
        return
    end
    local Room = self:CreateItemRoom(nRoomInstanceId, szCharacterName)
    local tbItemInstanceIdsAdded = {}

    for _, nId in pairs(tbItemInstanceIds) do
        local Item = BattleItemSystemServer:GetItem(nId)
        if Item == nil then
            logwarning("Cannot find item when create die box!", nId)
        else
            if BattleItemSystemHelper:CanKnownByPlayer(Item:GetTemplateId()) then
                Item:SetOwnerCharacter(nil)
                Item:SetStorageLocation(nSceneItemPackageRoomType, nRoomInstanceId)
                table.insert(tbItemInstanceIdsAdded, nId)
            else
                BattleItemSystemServer:DestroyItem(nId)
            end
        end
    end

    Room:SetItemInstanceIds(tbItemInstanceIdsAdded)

    EventManager:OnFireEvent(CommonEventDef.EV_SCENE_ITEM_ADD_DIE_BOX, tbItemInstanceIds, tbTransform.X, tbTransform.Y, tbTransform.Z)
end

function SceneItemContainer:CreateSceneItemPackageItemWhenCharacterDie(nItemTemplateId, tbTransform, bIsShip, nHumanMovementStateType)
    log("[DIE BOX]", nItemTemplateId, tbTransform.X, tbTransform.Y, tbTransform.Z)
    return AddSingleItemToSceneByType(nItemTemplateId, nil, tbTransform, SceneItemActorDef.DIE_BOX, nil, bIsShip, nHumanMovementStateType)
end

function SceneItemContainer:CreateSceneItem(nItemTemplateId, nItemCount, tbTransform, nSceneItemActorType, bRandomPosition)
    return AddSingleItemToSceneByType(nItemTemplateId, nItemCount, tbTransform, nSceneItemActorType, bRandomPosition, nil, nil)
end

-- 从地上中移除一个物品
function SceneItemContainer:RemoveItem(Item, bSyncToClient)
    local nItemTemplateId = Item:GetTemplateId()
    local nInstanceId = Item:GetInstanceId()
    if Item:GetCategory() == BattleItemCategoryDef.SCENE_ITEM_PACKAGE then
        return
    end

    local ItemRoom = RemoveItem(self, Item, bSyncToClient)
    if ItemRoom ~= nil and ItemRoom:GetRoomType() == BattleItemRoomDef.SCENE_ITEM_ROOM then
        local nBoxItemTemplateId = ItemRoom:GetRoomId()
        local BoxItem = BattleItemSystemServer:GetItem(nBoxItemTemplateId)

        local tbBoxItemTemplate = BoxItem:GetTemplate()
        if ItemRoom:IsEmpty() then
            if tbBoxItemTemplate.bRemoveWhenEmpty then
                self:RemoveSceneItemPackage(BoxItem, bSyncToClient)
                BattleItemSystemServer:DestroyItem(BoxItem:GetInstanceId())
            end
        else
            if tbBoxItemTemplate.bRemoveHighLight then
                SetActorPickOut(BoxItem)
            end
        end
    end

    EventManager:OnFireEvent(CommonEventDef.EV_SCENE_ITEM_REMOVE, nInstanceId, nItemTemplateId)
end

-- 从地上中移除一个盒子
function SceneItemContainer:RemoveSceneItemPackage(Item, bSyncToClient)
    local nItemInstanceId = Item:GetInstanceId()
    local nServerInstanceId = Item:GetSceneActor():GetServerInstanceId()
    if Item:GetCategory() ~= BattleItemCategoryDef.SCENE_ITEM_PACKAGE then
        return
    end

    local RelatedItemRoom = GetRoom(nItemInstanceId)
    RemoveItemRoom(self, RelatedItemRoom, bSyncToClient)

    RemoveItem(self, Item, bSyncToClient)
    log("[SceneItemContainer]RemoveSceneItemPackage", nItemInstanceId, nServerInstanceId)
end

-- 获得盒子里的物品列表（给机器人AI使用）
function SceneItemContainer:GetItemsInSceneItemPackage(nItemPackageInstanceId)
    local PackageItem = BattleItemSystemServer:GetItem(nItemPackageInstanceId)
    if PackageItem == nil then
        logerror("Cannot find scene item package!", nItemPackageInstanceId)
        return nil
    end
    local nCategory = PackageItem:GetCategory()
    if nCategory ~= BattleItemCategoryDef.SCENE_ITEM_PACKAGE then
        logerror("Item is not a SCENE_ITEM_PACKAGE!", nItemPackageInstanceId, nCategory, PackageItem:GetTemplateId())
        return nil
    end

    local ItemRoom = GetRoom(nItemPackageInstanceId)
    if ItemRoom == nil then
        log("Item is SCENE_ITEM_PACKAGE but cannot found room!", nItemPackageInstanceId, nCategory, PackageItem:GetTemplateId())
        return nil
    end

    return ItemRoom:GetRoomItems(false)
end

-- 获得盒子里的物品列表（给机器人AI使用）
function SceneItemContainer:FillItemsInSceneItemPackage(nItemPackageInstanceId, tbItems)
    local PackageItem = BattleItemSystemServer:GetItem(nItemPackageInstanceId)
    if PackageItem == nil then
        logerror("Cannot find scene item package!", nItemPackageInstanceId)
        return nil
    end
    local nCategory = PackageItem:GetCategory()
    if nCategory ~= BattleItemCategoryDef.SCENE_ITEM_PACKAGE then
        logerror("Item is not a SCENE_ITEM_PACKAGE!", nItemPackageInstanceId, nCategory, PackageItem:GetTemplateId())
        return nil
    end

    local ItemRoom = GetRoom(nItemPackageInstanceId)
    if ItemRoom == nil then
        log("Item is SCENE_ITEM_PACKAGE but cannot found room!", nItemPackageInstanceId, nCategory, PackageItem:GetTemplateId())
        return nil
    end

    local tbItemInstanceIds = ItemRoom:GetAllItemInstanceIds()
    for k, v in pairs(tbItemInstanceIds) do
        local Item = BattleItemSystemServer:GetItem(v)
        if Item == nil then
            error("Cannot find Item! nItemInstanceId:".. v)
        end
        tbItems[k] = Item
    end
end

function SceneItemContainer:GetOwnerItemRoom(Item)
    local tbStorageLocation = Item:GetStorageLocation()
    return GetRoom(tbStorageLocation.nOwnerInstanceId)
end

function SceneItemContainer:GetOwnerRoomActorServerInstanceId(Item)
    local ItemRoom = self:GetOwnerItemRoom(Item)
    if ItemRoom then
        local nRoomId = ItemRoom:GetRoomId()
        local SceneBoxItem = BattleItemSystemServer:GetItem(nRoomId)
        local tbTrigger = SceneBoxItem:GetSceneActor()
        return tbTrigger:GetServerInstanceId()
    else
        return nil
    end
end

function SceneItemContainer:GetOwnerBoxItem(Item)
    local ItemRoom = self:GetOwnerItemRoom(Item)
    if ItemRoom then
        local nRoomId = ItemRoom:GetRoomId()
        return BattleItemSystemServer:GetItem(nRoomId)
    else
        return nil
    end
end

return SceneItemContainer
