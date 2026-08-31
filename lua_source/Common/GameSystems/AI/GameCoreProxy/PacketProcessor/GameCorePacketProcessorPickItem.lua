local luaclass = require("luaclass")
local GameCorePacketProcessorAction = require("GameCorePacketProcessorAction")
local GameCorePacketProcessorPickItem = luaclass("GameCorePacketProcessorPickItem", GameCorePacketProcessorAction)

local Proto                         = require("GameCoreClientProtoNames")
local BattleItemSystemServer    = require("BattleItemSystemServer")
local BattleItemCategoryDef = require("BattleItemCategoryDef")
local SyncDataUtils         = require("SyncDataUtils")

-- luacheck: push ignore
local function LOG(...)
    log("CJ->GameCorePacketProcessorPickItem:", ...)
end
-- luacheck: pop

local tbTempPackageSubItems = { }

function GameCorePacketProcessorPickItem:DoAction(tbPacket)
    local nItemInstanceId = tbPacket.itemid
    local tbGameObject = self.tbAgent:GetGameObject()
    local nOwnerInstanceId = tbGameObject.nServerInstanceId
    local tbItem = BattleItemSystemServer:GetItem(nItemInstanceId)
    if tbItem and BattleItemSystemServer:CheckItemReady(nItemInstanceId) then
        if not BattleItemSystemServer:CheckPickupDistance(tbGameObject, tbItem) then
            self:ReportActionResult(Proto.ActionType.Pick, 1)
            return
        end
        if tbItem:GetCategory() == BattleItemCategoryDef.SCENE_ITEM_PACKAGE then
            SyncDataUtils:EmptyTable(tbTempPackageSubItems)
            BattleItemSystemServer:FillItemsInSceneItemPackage(nItemInstanceId, tbTempPackageSubItems)
            for _,v in pairs(tbTempPackageSubItems) do
                if BattleItemSystemServer:CanAutoPickUp(nOwnerInstanceId, v) then
                    BattleItemSystemServer:PickUpSceneItem(nOwnerInstanceId, v:GetInstanceId())
                    LOG("pick in package ", nOwnerInstanceId, v:GetInstanceId(), v:GetTemplateId())
                end
            end
        else
            BattleItemSystemServer:PickUpSceneItem(nOwnerInstanceId, nItemInstanceId)
            LOG("pick item ", nOwnerInstanceId, nItemInstanceId, tbItem:GetTemplateId())
        end
        self:ReportActionResult(Proto.ActionType.Pick, 0)
    else
        self:ReportActionResult(Proto.ActionType.Pick, 2)
    end
end


return GameCorePacketProcessorPickItem