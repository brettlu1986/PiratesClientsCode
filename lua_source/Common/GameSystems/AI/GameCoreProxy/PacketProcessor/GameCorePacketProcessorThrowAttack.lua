local luaclass = require("luaclass")
local GameCorePacketProcessorAction = require("GameCorePacketProcessorAction")
local GameCorePacketProcessorThrowAttack = luaclass("GameCorePacketProcessorThrowAttack", GameCorePacketProcessorAction)

local HumanWeaponMisc = require("HumanWeaponMisc")
local HumanWeaponType = HumanWeaponMisc.Type
local BattleItemCategoryDef = require("BattleItemCategoryDef")
local ShipFiringOperationDef = require("ShipFiringOperationDef")
local ShipThrownItemSubCategoryDef = require("ShipThrownItemSubCategoryDef")
local GlobalVariableSystem = dynamic_require("GlobalVariableSystem")
local BattleShipWeaponSystem = dynamic_require("BattleShipWeaponSystem")

local tbThrowWeaponParam = {pLocation = Vector()}

-- luacheck: push ignore
local function LOG(...)
    log("CJ->GameCorePacketProcessorThrowAttack:", ...)
end
-- luacheck: pop

local function ShipThrowAttack(self, tbPlayer, x, y, z)
    local nCharacterInstanceId = tbPlayer:GetServerInstanceId()
    local ActiveWeapon = BattleShipWeaponSystem:GetActiveWeaponItem(tbPlayer)
    if (not ActiveWeapon) or ActiveWeapon:GetCategory() ~= BattleItemCategoryDef.SHIP_THROWN_ITEM then
        logerror("GameCoreBotAgent-> Ship throw attack failed! No current ship thrown weapon!", nCharacterInstanceId)
        return
    end
    local tbAgent = self.tbAgent
    local pAIController = tbAgent.pAIController
    ActiveWeapon:SetReplacedViewerActor(pAIController)
    if ActiveWeapon:GetSubCategory() == ShipThrownItemSubCategoryDef.CARRONADE then
        ActiveWeapon:SetTargetLocation(x, y, z)
    end
    if BattleShipWeaponSystem:Fire(tbPlayer, ShipFiringOperationDef.START) then
        LOG("Ship throw attack start", nCharacterInstanceId, x, y, z)
        if BattleShipWeaponSystem:Fire(tbPlayer, ShipFiringOperationDef.END) then
            LOG("Ship throw attack end", nCharacterInstanceId, x, y, z)
        end
    else
        logerror("GameCoreBotAgent-> Ship throw attack failed!", nCharacterInstanceId, x, y, z)
    end
end

local function HumanThrowAttack(self, tbPlayer, x, y, z)
    local nCharacterInstanceId = tbPlayer:GetServerInstanceId()
    local tbAgent = self.tbAgent
    local WeaponComponent = tbPlayer.HumanWeaponComponent
    local tbCurrentWeapon = WeaponComponent:GetCurrentWeapon()
    if not tbCurrentWeapon then
        logerror("GameCoreBotAgent-> Throw attack failed! No current weapon!", nCharacterInstanceId)
        return
    end
    if not tbCurrentWeapon:IsType(HumanWeaponType.THROW) then
        logerror("GameCoreBotAgent-> Throw attack failed! Current weapon is not human thrown item!", nCharacterInstanceId, tbCurrentWeapon:GetTemplateId(), tbCurrentWeapon:GetType(), tbPlayer:GetServerInstanceId() )
        return
    end
    local now = GlobalVariableSystem:GetDSTimeSeconds()
    local tbProperty = tbCurrentWeapon:GetProperty()
    local nCD = tbProperty.nCD
    if now - tbAgent.nLastThrowAttackTime < nCD then
        logerror("GameCoreBotAgent-> Throw attack failed! CD time limit!", nCharacterInstanceId, now - tbAgent.nLastThrowAttackTime, nCD)
        return
    end
    tbThrowWeaponParam.pLocation.X = x
    tbThrowWeaponParam.pLocation.Y = y
    tbThrowWeaponParam.pLocation.Z = z
    WeaponComponent:CheatAttack(nil, nil, tbThrowWeaponParam)
    tbAgent.nLastThrowAttackTime = now
    LOG("Human throw attack", nCharacterInstanceId, x, y, z)
end

function GameCorePacketProcessorThrowAttack:DoAction(tbPacket)
    local tbAgent = self.tbAgent
    local tbPlayer = tbAgent:GetGameObject()
    if tbPlayer:IsHuman() then
        HumanThrowAttack(self, tbPlayer, tbPacket.x, tbPacket.y, tbPacket.z)
    else
        ShipThrowAttack(self, tbPlayer, tbPacket.x, tbPacket.y, tbPacket.z)
    end
end


return GameCorePacketProcessorThrowAttack