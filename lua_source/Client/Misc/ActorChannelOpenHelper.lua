-- 处理actor channel open时需要做的操作
local ActorChannelOpenHelper = {}

local BattleShipMovementComponent = dynamic_require("BattleShipMovementComponent")
local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
local GameObjectTypeDef = require("GameObjectTypeDef")
local TemplateTypeDef = require("TemplateTypeDef")
local NPCDataTable = require("NPCDataTable")

local pDungeonCommonActorShell = nil

local function ProcessShipMovement(pUEActor, nShipTemplateId)
    if(pUEActor.ShipMovementComponent) then
        BattleShipMovementComponent.InitMovementData(pUEActor.ShipMovementComponent, nShipTemplateId)
    end
end

function ActorChannelOpenHelper.OnProcess(pUEActor, nUniqueId, nServerInstanceId)
    local tbGamePlayerSelf = GamePlayerSelfHelper:Get()
    if(tbGamePlayerSelf == nil) then
        log("ActorChannelOpenHelper.OnProcess, no playerself", nUniqueId, nServerInstanceId)
        return
    end

    if(pDungeonCommonActorShell == nil) then
        pDungeonCommonActorShell = CommonShell.GetCommon(GWorld):GetCommonActorShell()
    end

    local pMessageRef = pDungeonCommonActorShell:GetActorSpawnInitData(pUEActor)
    if(pMessageRef == nil) then
        log("ActorChannelOpenHelper.OnProcess, no initdata", nUniqueId, nServerInstanceId)
        return
    end
    local tbInitProtoData = msgtoluatable(pMessageRef)
    if(tbInitProtoData == nil) then
        log("ActorChannelOpenHelper.OnProcess, msgtoluatable(pMessageRef) failed", nUniqueId, nServerInstanceId)
        return
    end

    local nType = tbInitProtoData.script_type
    if(nType == GameObjectTypeDef.PlayerSelf
        and tbGamePlayerSelf.nPlayerId ~= tbInitProtoData.player_id) then
        nType = GameObjectTypeDef.PlayerOther
    end

    if(nType == GameObjectTypeDef.PlayerSelf or nType == GameObjectTypeDef.PlayerOther) then
        if(tbInitProtoData.template_type == TemplateTypeDef.SHIP) then
            local nShipTemplateId = tbInitProtoData.template_id
            ProcessShipMovement(pUEActor, nShipTemplateId)
        end
    elseif(nType == GameObjectTypeDef.Npc) then
        local tbNpcTemplate = NPCDataTable:GetTemplate(tbInitProtoData.template_id)
        if(tbNpcTemplate == nil) then
            logerror("ActorChannelOpenHelper.OnProcess failed, tbNpcTemplate:", tbInitProtoData.template_id, debug.traceback())
            return
        end
        if(tbNpcTemplate.nType == TemplateTypeDef.SHIP) then
            local nShipTemplateId = tbNpcTemplate.nTypeID
            ProcessShipMovement(pUEActor, nShipTemplateId)
        end
    end
end

return ActorChannelOpenHelper