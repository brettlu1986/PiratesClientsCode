-----------------------------------------------------
--File Name    : ItemCategoryOperationHelperBase.lua
--Author       : zhiyuan
--Create Time  : 2018-08-23
--Description  : 物品操作helper的基类
-----------------------------------------------------
local luaclass = require("luaclass")
local ItemCategoryOperationHelperBase = luaclass("ItemCategoryOperationHelperBase")

local BattleItemSystemHelper = require("BattleItemSystemHelper")

-- 最大槽位个数，槽位index需要从1开始且连续
ItemCategoryOperationHelperBase.nMaxSlot = 0

------------------------------------------客户端服务端共用的方法-----------------------------------------------

-- 检查SlotIndex是否合法
-- 此方法可以override
-- 如果slot都是从1开始，那只需要定义好ItemOperationHelperBase.nMaxSlot的值就可以，不需要override
-- @param nSlotIndex 槽位ID
function ItemCategoryOperationHelperBase:IsSlotIndexValid(nSlotIndex)
    if nSlotIndex == nil then
        return false
    end
    return nSlotIndex >= 0 and nSlotIndex <= self.nMaxSlot
end

-- 检查物品和槽位是否兼容
-- @param nCharacterInstanceId LuaCharacter的ServerInstanceId
-- @param nOwnerInstanceId 拥有者的InstanceId。
--        如果装在船上或者人上的，nOwnerInstanceId就是LuaCharacter的nServerInstanceId
--        如果是装在武器上的，就是武器的nItemInstanceId
-- @param nSlotIndex 槽位index
-- @param Item 物品实例
-- @param bIsClient true表示在客户端运行，false表示在服务端运行
-- @return
function ItemCategoryOperationHelperBase:CheckItemSlotCompatibility(nCharacterInstanceId, nOwnerInstanceId, nSlotIndex, Item, bIsClient)
    return false
end

-- 当Owner被替换时是否自动装配
function ItemCategoryOperationHelperBase:CanAutoEquipWhenOwnerChanged()
    return false
end

-- 是否玩家可见
function ItemCategoryOperationHelperBase:CanKnownByPlayer(nItemTemplateId)
    return true
end

-------------------------------------------客户端方法----------------------------------------------------------------

function ItemCategoryOperationHelperBase:GetPlayerServerInstanceIdOnClient()
    local BattleItemSystemClient = BattleItemSystemHelper:GetBattleItemSystemClient()
    return BattleItemSystemClient:GetPlayerServerInstanceId()
end

-- 是否可以自动拾取, 客户端方法
-- @param Item 被检查的物品
-- @return bIsBetter, bAutoPickUp
-- bIsBetter true表示需要给出的提示让玩家拾取，false表示不需要
-- bAutoPickUp true表示可以自动拾取，false表示不能自动拾取
function ItemCategoryOperationHelperBase:CanAutoPickUpOnClient(Item)
    return false, false
end

-- 是否可以手动拾取, 客户端方法
-- @param Item 被检查的物品
-- @return true表示可以手动拾取，false表示不能手动拾取
function ItemCategoryOperationHelperBase:CanManuallyPickUpOnClient(Item)
    return false
end

-- 校验物品建造的特殊条件(客户端方法)
-- @param nItemTemplateId 物品的类型id
-- @return bSucceeded, tbFailures
--         bSucceeded为true表示校验成功，false表示校验失败
--         tbFailures 表示失败原因的列表，eg：
--         local tbFailures = {}
--         local tbFailure = {}
--         tbFailure.nType = ItemBuildingVerificationFailureDef.MATERIALS_NOT_ENOUGH
--         tbFailure.Params = nil --不同类型的参数不同，详情见ItemBuildingVerificationFailureDef
--         table.insert(tbFailures, tbFailure)
function ItemCategoryOperationHelperBase:VerifyCustomBuildingConditionsOnClient(nItemTemplateId, nSlotIndex)
    return true, nil
end

-- 获得装配位置(客户端方法)
-- @param nItemTemplateId物品的类型id
-- @param bNeedEmptySlot true表示必须是空槽位
-- @return
-- 返回值：nOwnerInstanceId, nSlotIndex (如果找不到装配位置，就返回 -1,-1)
function ItemCategoryOperationHelperBase:GetAvailableEquipmentSlotForItemOnClient(nItemTemplateId, bNeedEmptySlot)
    return -1,-1
end

-- 获得装配位置index(客户端方法)
-- @param nOwnerInstanceId 拥有者的InstanceId。
--        如果装在船上或者人上的，nOwnerInstanceId就是LuaCharacter的nServerInstanceId
--        如果是装在武器上的，就是武器的nItemInstanceId
-- @param nItemTemplateId物品的类型id
-- @param bNeedEmptySlot true表示必须是空槽位
-- @return nSlotIndex (如果找不到装配位置，就返回 -1)
function ItemCategoryOperationHelperBase:GetAvailableEquipmentSlotForItemWithOwnerOnClient(nOwnerInstanceId, nItemTemplateId, bNeedEmptySlot)
    return -1
end


---------------------------------------------服务端方法-----------------------------------------------------------------

-- 是否可以自动拾取, 服务端方法，给机器人AI使用
-- @param nCharacterInstanceId LuaCharacter的ServerInstanceId
-- @param Item 被检查的物品
-- @return bAutoPickUp
-- bAutoPickUp true表示可以自动拾取，false表示不能自动拾取
function ItemCategoryOperationHelperBase:CanAutoPickUpOnServer(nCharacterInstanceId, Item)
    return false
end

-- 获得在装备槽位上剩余还可以安装的叠加数量，可以叠加安装的物品才需要override这个方法
function ItemCategoryOperationHelperBase:GetRemainStackCountOnEquipmentSlot(nCharacterInstanceId, nOwnerInstanceId, nSlotIndex, nItemTemplateId)
    return 1
end

-- 获得装配位置（服务端方法）
-- @param nCharacterInstanceId LuaCharacter的ServerInstanceId
-- @param nItemTemplateId物品的类型id
-- @param bNeedEmptySlot true表示必须是空槽位
-- @return
-- 返回值：nOwnerInstanceId, nSlotIndex (如果找不到装配位置，就返回 -1,-1)
function ItemCategoryOperationHelperBase:GetAvailableEquipmentSlotForItemOnServer(nCharacterInstanceId, nItemTemplateId, bNeedEmptySlot)
    return -1,-1
end

-- 获得装配位置（服务端方法）
-- @param nCharacterInstanceId LuaCharacter的ServerInstanceId
-- @param nOwnerInstanceId 拥有者的InstanceId。
--        如果装在船上或者人上的，nOwnerInstanceId就是LuaCharacter的nServerInstanceId
--        如果是装在武器上的，就是武器的nItemInstanceId
-- @param nItemTemplateId物品的类型id
-- @param bNeedEmptySlot true表示必须是空槽位
-- @return nSlotIndex (如果找不到装配位置，就返回 -1)
function ItemCategoryOperationHelperBase:GetAvailableEquipmentSlotForItemWithOwnerOnServer(nCharacterInstanceId, nOwnerInstanceId, nItemTemplateId, bNeedEmptySlot)
    return -1
end

-- 校验物品建造的特殊条件（服务端方法）
-- @param nCharacterInstanceId LuaCharacter的ServerInstanceId
-- @param nItemTemplateId 物品的类型id
-- @return bSucceeded, tbFailures
--         bSucceeded为true表示校验成功，false表示校验失败
--         tbFailures 表示失败原因的列表，eg：
--         local tbFailures = {}
--         local tbFailure = {}
--         tbFailure.nType = ItemBuildingVerificationFailureDef.MATERIALS_NOT_ENOUGH
--         tbFailure.Params = nil --不同类型的参数不同，详情见ItemBuildingVerificationFailureDef
--         table.insert(tbFailures, tbFailure)
function ItemCategoryOperationHelperBase:VerifyCustomBuildingConditionsOnServer(nCharacterInstanceId, nItemTemplateId, nSlotIndex)
    return true, nil
end

-- 是否可以卸下
-- @param nCharacterInstanceId LuaCharacter的ServerInstanceId
-- @param Item 被检查的物品
-- @return bSuccess, BattleItemUnequipCheckFailureDef
function ItemCategoryOperationHelperBase:CanUnequipOnServer(nCharacterInstanceId, Item)
    return true, nil
end

-- 是否可以扔掉
-- @param nCharacterInstanceId LuaCharacter的ServerInstanceId
-- @param Item 被检查的物品
-- @return bSuccess, BattleItemThrowAwayCheckFailureDef
function ItemCategoryOperationHelperBase:CanThrowAwayOnServer(nCharacterInstanceId, Item)
    return true, nil
end

-- 加到玩家身上之前的处理
-- @param nCharacterInstanceId LuaCharacter的ServerInstanceId
-- @param Item 准备增加的物品
-- @return Item 最终加给玩家的物品
function ItemCategoryOperationHelperBase:BeforeAddedToCharacterOnServer(nCharacterInstanceId, Item)
    return Item
end

-- 建造后
-- @param nCharacterInstanceId LuaCharacter的ServerInstanceId
-- @param Item 建造的物品
function ItemCategoryOperationHelperBase:AfterBuiltOnServer(nCharacterInstanceId, Item)
end

-- 拾取后
-- @param nCharacterInstanceId LuaCharacter的ServerInstanceId
-- @param Item 拾取的物品
function ItemCategoryOperationHelperBase:AfterPickedUpOnServer(nCharacterInstanceId, Item)
end

return ItemCategoryOperationHelperBase
