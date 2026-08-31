local luaclass = require("luaclass")
local SyncDataBase = require("SyncDataBase")
local SyncDataVisibleItems = luaclass("SyncDataVisibleItems", SyncDataBase)
local BattleItemSystemServer = require("BattleItemSystemServer")
local BattleItemCategoryDef = require("BattleItemCategoryDef")
local SyncDataUtils = require("SyncDataUtils")
local GameCoreAgentLuaPoolManager = require("GameCoreAgentLuaPoolManager")

SyncDataVisibleItems.tbVisibleItems = nil
SyncDataVisibleItems.tbPackageItems = nil

local nHumanDistTriggerPackageItemList = 500
local nShipDistTriggerPackageItemList = 5000

local tbTempPackageSubItems = { }

local function AddPackageItemList(tbItemList, tbPackageItem, nSize, tbLuaPool)
    local nCount = nSize
    SyncDataUtils:EmptyTable(tbTempPackageSubItems)
    BattleItemSystemServer:FillItemsInSceneItemPackage(tbPackageItem:GetInstanceId(), tbTempPackageSubItems)
    for _,v in pairs(tbTempPackageSubItems) do
        nCount = nCount + 1
        local tbItem = tbLuaPool:Get()
        tbItem.id = v:GetInstanceId()
        tbItem.templateid = v:GetTemplateId()
        tbItem.count = v:GetStackCount()
        tbItemList[nCount] = tbItem
    end
    return nCount
end

function SyncDataVisibleItems:OnSync(tbPack)
    local pAIController = self.pAIController
    local nNumItem = pAIController:GetSeenItemNum()
    if nNumItem > 0 then
        local tbOwner = self.tbOwner
        local nOwnerX, nOwnerY, nOwnerZ  = tbOwner.SAIEntityComponent:GetLocation()
        local nDistTriggerPackageItemList = nHumanDistTriggerPackageItemList
        if tbOwner:IsShip() then
            nDistTriggerPackageItemList = nShipDistTriggerPackageItemList
        end
        local nNumPackageItem = 0
        local tbVisibleItems = self.tbVisibleItems
        local tbPackageItems = self.tbPackageItems
        for i = nNumItem + 1, #tbVisibleItems do
            tbVisibleItems[i] = nil
        end
        local nLuaPoolId = tbOwner:GetServerInstanceId()
        local LuaVisibleItemPool = GameCoreAgentLuaPoolManager:Get(nLuaPoolId, "VisibleItem")
        local LuaPackageItemPool = GameCoreAgentLuaPoolManager:Get(nLuaPoolId, "PackageItem")

        for i=1,nNumItem do
            local nInstanceID, nTemplateID, nX, nY, nZ = pAIController:GetSeenItem(i)
            local tbItem = LuaVisibleItemPool:Get()
            tbItem.id = nInstanceID
            tbItem.templateid = nTemplateID
            tbItem.category = nTemplateID // 1000000
            tbItem.position = tbItem.position or {}
            tbItem.position.x = nX
            tbItem.position.y = nY
            tbItem.position.z = nZ
            -- 内存持续增加 缩放数组导致
            tbVisibleItems[i] = tbItem
            local tbItemObject = BattleItemSystemServer:GetItem(nInstanceID)
            if tbItemObject and tbItemObject:GetCategory() == BattleItemCategoryDef.SCENE_ITEM_PACKAGE then
                if (SyncDataUtils:InRange(nOwnerX, nOwnerY, nOwnerZ, nX, nY, nZ, nDistTriggerPackageItemList)) then
                    nNumPackageItem = AddPackageItemList(tbPackageItems, tbItemObject, nNumPackageItem, LuaPackageItemPool)
                end
            end
            --LOG("visible item ", tbItem.category, v.InstanceID)
        end

        tbPack.visible_items = self.tbVisibleItems
        if nNumPackageItem > 0 then
            -- 内存持续增加 缩放数组导致
            for i=nNumPackageItem + 1, #tbPackageItems do
                tbPackageItems[i] = nil
            end
            tbPack.package_item_list = self.tbPackageItems
        else
            tbPack.package_item_list = nil
        end
    else
        tbPack.visible_items = nil
        tbPack.package_item_list = nil
    end
end


function SyncDataVisibleItems:OnStart()
    self.tbVisibleItems = {}
    self.tbPackageItems = {}
end


function SyncDataVisibleItems:OnStop()

end

return SyncDataVisibleItems