local AIHelper = {}
local PropName = require("PropName")
local GameObjectTypeDef = require("GameObjectTypeDef")
local ParachutingNewIni = require("ParachutingNewIni")
local GlobalVariableSystem = dynamic_require("GlobalVariableSystem")
local BattleItemCategoryDef     = require("BattleItemCategoryDef")
local ShipWeaponSlotDef         = require("ShipWeaponSlotDef")
local HumanWeaponSlotDef        = require("HumanWeaponSlotDef")
local SAILogicDef               = require("SAILogicDef")
local HumanMovementStateType    = require("HumanMovementStateType")
local BattlePrepareSystem       = require("BattlePrepareSystem")


function AIHelper.GetActivedAIController(tbGameObject)
    return tbGameObject.SAIComponent:GetAIController()
end

function AIHelper.ToggleBotName(tbGameObject, bShow)
    if tbGameObject:IsShip() then
        local ShipBattlePropertyComponent = tbGameObject.ShipBattlePropertyComponent
        ShipBattlePropertyComponent:SetPropOriginValue(PropName.nShipBotType, bShow and 1 or 0)
    else
        local HumanBattlePropertyComponent = tbGameObject.HumanBattlePropertyComponent
        HumanBattlePropertyComponent:SetPropOriginValue(PropName.nHumanBotType, bShow and 1 or 0)
    end
end

function AIHelper.IsAIControlled(tbGameObject)
    if not GlobalVariableSystem:IsServerLogic() then
        error("AIHelper.IsAIControlled must used in server")
        return false
    end
    if GameObjectTypeDef.PlayerSelf == tbGameObject.ObjectType then
        if tbGameObject.SAIComponent:IsEnabled() then
            return true
        end
    elseif GameObjectTypeDef.Npc == tbGameObject.ObjectType then
        return true
    end
    if GlobalVariableSystem.bEnableAIGameCore then
        local GameCoreProxyClient = require("GameCoreProxyClient")
        if GameCoreProxyClient:IsAgent(tbGameObject) then
            return true
        end
    end
    return false
end

function AIHelper.IngoreShipPartItemDamage(tbGameObject)
    if not GlobalVariableSystem:IsServerLogic() then
        error("AIHelper.IngoreShipPartItemDamage must be used in server")
        return false
    end
    if GameObjectTypeDef.PlayerSelf == tbGameObject.ObjectType then
        if AIHelper:IsRunningAILogic(tbGameObject, SAILogicDef.Bot) then
            return true
        end
    elseif GameObjectTypeDef.Npc == tbGameObject.ObjectType then
        return true
    end
    return false
end

function AIHelper.IsAICustomPreparationItem(tbGameObject)
    if not GlobalVariableSystem:IsServerLogic() then
        error("AIHelper.IsAICustomPreparationItem must used in server")
        return false
    end
    if  AIHelper:IsRunningAILogic(tbGameObject, SAILogicDef.Bot) or
        AIHelper:IsRunningAILogic(tbGameObject, SAILogicDef.NpcBattle) then
        return true
        end
    return false
end

function AIHelper.GetDelayTime()
    local nLauchTime = ParachutingNewIni.tbLaunch.nLaunchTime
    local nOpenParachuteTime = ParachutingNewIni.tbLaunch.nOperateHeight / ParachutingNewIni.tbParachuteNoOpen.nNormalFallSpeed
    return math.max( 0, nLauchTime + nOpenParachuteTime + 5)
end

function AIHelper.ReportDamageEvent(tbDamaged, tbCauser, nDamage)
    if tbDamaged and tbDamaged.pUEActor and tbCauser and tbCauser.pUEActor and
    AIHelper.IsAIControlled(tbDamaged) then
        local pEventLocation = tbCauser.pUEActor:K2_GetActorLocation()
        local pHitLocation = tbDamaged.pUEActor:K2_GetActorLocation()
        AISense_Damage.ReportDamageEvent(GWorld, tbDamaged.pUEActor, tbCauser.pUEActor, nDamage, pEventLocation,
        pHitLocation)
    end
end

function AIHelper.ReportSoundEvent(tbLocation, tbCauser, nLoudness, nRange, szTag)
    if tbCauser and tbCauser.pUEActor then
        if not tbLocation then
            tbLocation = tbCauser.pUEActor:K2_GetActorLocation()
        end
        AISense_Hearing.ReportNoiseEvent(GWorld, tbLocation, nLoudness, tbCauser.pUEActor, nRange, szTag)
    end
end


function AIHelper.RegisterWithPerceptionSystem(pUEActor)
    if pUEActor and isvalidhandle(pUEActor) and pUEActor.AIPerceptionStimuliSource then
        pUEActor.AIPerceptionStimuliSource:RegisterWithPerceptionSystem()
    end
end

function AIHelper.UnregisterFromPerceptionSystem(pUEActor)
    if pUEActor and isvalidhandle(pUEActor) and pUEActor.AIPerceptionStimuliSource then
        pUEActor.AIPerceptionStimuliSource:UnregisterFromPerceptionSystem()
    end
end

function AIHelper.HasAttackableWeapon(tbGameObject)
    local BattleItemSystemServer    = require("BattleItemSystemServer")
    if tbGameObject:IsShip() then
        local tbOwner = tbGameObject
        local AILogic = AIHelper:GetAILogic(tbOwner)
        for i=ShipWeaponSlotDef.COMMON_START, ShipWeaponSlotDef.COMMON_END do
            local tbWeapon = BattleItemSystemServer:GetEquippedItem(tbOwner:GetServerInstanceId(), BattleItemCategoryDef.SHIP_WEAPON,
            tbOwner:GetServerInstanceId(), i)
            if tbWeapon and AILogic:CanUseWeapon(tbWeapon:GetTemplateId()) then
                return true
            end
        end
        return false
    elseif tbGameObject:IsHuman() then
        local tbOwner = tbGameObject
        local WeaponComponent = tbOwner.HumanWeaponComponent
        local AILogic = AIHelper:GetAILogic(tbOwner)
        for i=1,HumanWeaponSlotDef:SlotCount() do
            local tbWeapon = BattleItemSystemServer:GetEquippedItem(tbOwner:GetServerInstanceId(), BattleItemCategoryDef.HUMAN_WEAPON,
            tbOwner:GetServerInstanceId(), i)
            if tbWeapon and AILogic:CanUseWeapon(tbWeapon:GetTemplateId()) then
                return true
            end
        end
        local tbThrowItems = BattleItemSystemServer:GetUnequippedItemsByCategory(tbOwner:GetServerInstanceId(),
        BattleItemCategoryDef.HUMAN_THROWN_ITEM)
        for _,v in ipairs(tbThrowItems) do
            if WeaponComponent and AILogic:CanUseWeapon(v:GetTemplateId()) then
                return true
            end
        end
        return false
    end
end

function AIHelper.OnDying(tbGameObject, bIsDying)
    local BattleItemSystemServer    = require("BattleItemSystemServer")
    if tbGameObject:IsHuman() and not bIsDying then
        -- 如果是人，从濒死状态回来是蹲着的，在这里机器人要站起来
        tbGameObject.HumanMovementStateComponent:SetMovementState(HumanMovementStateType.UpRight_State)
    end
    if bIsDying then
        if tbGameObject:IsHuman() then
            tbGameObject.HumanWeaponComponent:CancelReload()
        else
            local nCharacterInstanceId = tbGameObject:GetServerInstanceId()
            local tbEquippedWeapons = BattleItemSystemServer:GetEquippedItems(nCharacterInstanceId, BattleItemCategoryDef.SHIP_WEAPON, nCharacterInstanceId)
            for _, WeaponItem in pairs(tbEquippedWeapons) do
                WeaponItem:InterruptBulletLoading()
            end
        end
    end
end

function AIHelper:IsAIEnabled(tbGameObject)
    return tbGameObject.SAIComponent:IsEnabled()
end

function AIHelper:GetAILogic(tbGameObject)
    return tbGameObject.SAIComponent:GetLogic()
end

function AIHelper:IsRunningAILogic(tbGameObject, nID)
    return tbGameObject.SAIComponent.nActiveLogicId == nID and tbGameObject.SAIComponent.bRunning
end

function AIHelper:GetAISystem(tbGameObject, nID)
    return tbGameObject.SAIComponent:GetSystem(nID)
end

function AIHelper:ShouldSkipParachute(tbGameObject)
    local  BotAISystem = dynamic_require("BotAISystem")
    local  AITemmateSystem = require("AITemmateSystem")
    return BotAISystem:IsBot(tbGameObject) and not AITemmateSystem:IsTeammate(tbGameObject)
end

function AIHelper:HasRealPlayerTeammate(tbPlayer)
    if tbPlayer and GameObjectTypeDef.PlayerSelf == tbPlayer:GetObjectType() then
        local BattleTeamSystem = require("BattleTeamSystem")
        local nPlayerId = tbPlayer.nPlayerId
        local tbMembers = BattleTeamSystem:GetTeamMembersByPlayer(tbPlayer)
        for i,v in ipairs(tbMembers) do
            if v.nPlayerId ~= nPlayerId and not BattlePrepareSystem:IsBot(v.nPlayerId) then
                return true
            end
        end
    end
    return false
end

return AIHelper