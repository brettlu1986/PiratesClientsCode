-----------------------------------------------------
--File Name    : BattleItemComponentClient.lua
--Author       : zhiyuan
--Create Time  : 2018-08-24
--Description  : 客户端的战斗物品component
-----------------------------------------------------
local luaclass = require("luaclass")
local BattleItemComponentBase = require("BattleItemComponentBase")
local BattleItemComponentClient = luaclass("BattleItemComponentClient", BattleItemComponentBase)

-- 预约要建造的道具
BattleItemComponentClient.nReservedItemTemplateId = nil

BattleItemComponentClient.nBuildingItemTemplateId = nil

BattleItemComponentClient.tbShipPreparationTemplateIds = nil

-- 舰船皮肤
-- self.tbShipSkinIds[nBattleItemShipTemplateId] = nSkinId
BattleItemComponentClient.tbShipSkinIds = nil

function BattleItemComponentClient:OnCreate(Owner, tbParams)
    BattleItemComponentClient.super.OnCreate(self, Owner, tbParams)
    self.bIsClient = true
end

function BattleItemComponentClient:SetReservedItemTemplateId(nReservedItemTemplateId)
    self.nReservedItemTemplateId = nReservedItemTemplateId
end

function BattleItemComponentClient:ClearReservedItemTemplateId()
    self.nReservedItemTemplateId = nil
end

function BattleItemComponentClient:GetReservedItemTemplateId()
    return self.nReservedItemTemplateId
end

function BattleItemComponentClient:SetBuildingItemTemplateId(nBuildingItemTemplateId)
    self.nBuildingItemTemplateId = nBuildingItemTemplateId
end

function BattleItemComponentClient:ClearBuildingItemTemplateId()
    self.nBuildingItemTemplateId = nil
end

function BattleItemComponentClient:GetBuildingItemTemplateId()
    return self.nBuildingItemTemplateId
end

function BattleItemComponentClient:SetShipPreparationTemplatesIds(tbShipPreparationTemplateIds)
    self.tbShipPreparationTemplateIds = tbShipPreparationTemplateIds
end

function BattleItemComponentClient:GetShipPreparationTemplatesIds()
    return self.tbShipPreparationTemplateIds
end

-- 设置舰船皮肤
function BattleItemComponentClient:SetShipSkinIds(tbShipSkinIds)
    self.tbShipSkinIds = tbShipSkinIds
end

-- 获得舰船皮肤
function BattleItemComponentClient:GetShipSkinIds()
    return self.tbShipSkinIds
end


return BattleItemComponentClient