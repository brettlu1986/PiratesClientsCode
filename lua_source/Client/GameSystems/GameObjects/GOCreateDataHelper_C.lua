local luaclass = require("luaclass")
local GOCreateDataHelperClass = require("GOCreateDataHelper")
local GOCreateDataHelper_C = luaclass("GOCreateDataHelper_C", GOCreateDataHelperClass)

local SceneDataTable = require("SceneDataTable")
local GameWorldDef = require("GameWorldDefine")
local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
local TemplateTypeDef = require("TemplateTypeDef")
local GlobalVariableSystem = require("GlobalVariableSystem_C")

----------------------------------------------------------------------------------------
-- PlayerSelf
-- 登录创建玩家自己，hub协议数据
function GOCreateDataHelper_C:ParsePlayerSelfHubData(tbProtoData)
    -- s2c_PlayerData
    local tbRet = {}
    if(GlobalVariableSystem.bEnableNewLobbyServer) then
        local tbData = tbProtoData.data
        -- 新服务器instanceid就是playerid
        tbRet.nServerInstanceId = tbData.id
        tbRet.szName = tbData.name
        tbRet.nPlayerId = tbData.id

        tbRet.nTemplateType = TemplateTypeDef.HUMAN
        tbRet.nTemplateId = GamePlayerSelfHelper:GetHumanTemplateId(tbData)
        tbRet.bCreateUEActor = false
    else
        tbRet.nServerInstanceId = tbProtoData.actor_id
        tbRet.szName = tbProtoData.name
        tbRet.nPlayerId = tbProtoData.nPlayerId

        local tbPlayerData = tbProtoData.data
        local tbSceneData = SceneDataTable:GetTemplate(tbPlayerData.scene.scene_id)
        if(tbSceneData == nil) then
            logerror("ParsePlayerSelfHubNewData failed, cannot find sceneid: ", tbPlayerData.scene.scene_id)
            return nil
        end

        if tbSceneData.nType == GameWorldDef.Type.OCEAN then
            tbRet.nTemplateType = TemplateTypeDef.SHIP
            tbRet.nTemplateId = GamePlayerSelfHelper:GetShipTemplateId(tbPlayerData.ship_list)
        else
            tbRet.nTemplateType = TemplateTypeDef.HUMAN
            tbRet.nTemplateId = GamePlayerSelfHelper:GetHumanTemplateId(tbPlayerData.avatar)
        end

        local tbTrans = tbPlayerData.scene.transform
        tbRet.nLocationX = tbTrans.x
        tbRet.nLocationY = tbTrans.y
        tbRet.nLocationZ = tbTrans.z
        tbRet.nRotationYaw = tbTrans.yaw
        tbRet.bCreateUEActor = false
    end

    return tbRet
end

-- 进入野外大世界恢复主角Actor用
function GOCreateDataHelper_C:ParsePlayerSelfHubRestoreData(bIsOcean, tbGamePlayerSelf, nNewServerInstanceId, tbTransform)
    local tbRet = {}
    tbRet.nServerInstanceId = nNewServerInstanceId
    tbRet.szName = tbGamePlayerSelf:GetName()

    local nTemplateId = nil
    if bIsOcean then
        nTemplateId = tbGamePlayerSelf.LobbyPropertyComponent.nShipTemplateId
        tbRet.nTemplateType = TemplateTypeDef.SHIP
    else
        nTemplateId = tbGamePlayerSelf.LobbyPropertyComponent.nHumanTemplateId
        tbRet.nTemplateType = TemplateTypeDef.HUMAN
    end

    tbRet.nPlayerId = tbGamePlayerSelf.nPlayerId
    tbRet.nTemplateId = nTemplateId
    tbRet.bCreateUEActor = true

    if(tbTransform) then
        tbRet.nLocationX = tbTransform.x
        tbRet.nLocationY = tbTransform.y
        tbRet.nLocationZ = tbTransform.z
        tbRet.nRotationYaw = tbTransform.yaw
    else
        local pLocation = tbGamePlayerSelf:GetLocation(true)
        tbRet.nLocationX = pLocation.X
        tbRet.nLocationY = pLocation.Y
        tbRet.nLocationZ = pLocation.Z
        tbRet.nRotationYaw = tbGamePlayerSelf:GetRotation(true).Yaw
    end
    return tbRet
end

-- 恢复主角Object用
function GOCreateDataHelper_C:ParsePlayerSelfObjectRestoreData(bIsShip, szName, nTemplateId,
    nNewServerInstanceId, nPlayerId, tbTransform)
    local tbRet = {}
    tbRet.nServerInstanceId = nNewServerInstanceId
    tbRet.szName = szName

    if bIsShip then
        tbRet.nTemplateType = TemplateTypeDef.SHIP
    else
        tbRet.nTemplateType = TemplateTypeDef.HUMAN
    end

    tbRet.nPlayerId = nPlayerId
    tbRet.nTemplateId = nTemplateId
    tbRet.bCreateUEActor = false

    if(tbTransform) then
        tbRet.nLocationX = tbTransform.x
        tbRet.nLocationY = tbTransform.y
        tbRet.nLocationZ = tbTransform.z
        tbRet.nRotationYaw = tbTransform.yaw
    end
    return tbRet
end

-- 联网副本客户端收到replicated数据后
function GOCreateDataHelper_C:ParsePlayerReplicatedData(pUEActor, nServerInstanceId, tbInitProtoData)
    local tbRet = {}
    tbRet.nServerInstanceId = nServerInstanceId
    tbRet.szName = tbInitProtoData.name
    tbRet.nTemplateType = tbInitProtoData.template_type
    tbRet.nPlayerId = tbInitProtoData.player_id
    tbRet.nTemplateId = tbInitProtoData.template_id
    tbRet.nHumanId = tbInitProtoData.human_id

    local pLocation = EngineExtActorShell.GetActorLocation(pUEActor)
    tbRet.nLocationX = pLocation.X
    tbRet.nLocationY = pLocation.Y
    tbRet.nLocationZ = pLocation.Z
    tbRet.nRotationYaw = EngineExtActorShell.GetActorRotation(pUEActor).Yaw
    return tbRet
end

---------------------------------------------------------------------------------------
-- PlayerOther
function GOCreateDataHelper_C:ParsePlayerOtherHubData(tbProtoData)
    -- s2c_PlayerCreate

    local tbRet = {}
    local tbActorInfo = tbProtoData.actor
    local tbPlayerInfo = tbProtoData.player

    tbRet.nServerInstanceId = tbActorInfo.actor_id
    tbRet.szName = tbPlayerInfo.name
    tbRet.nPlayerId = tbPlayerInfo.player_id
    tbRet.nTemplateId = tbActorInfo.template_id

    local tbTrans = nil
    if tbActorInfo.actor_is_ship then
        tbRet.nTemplateType = TemplateTypeDef.SHIP
        tbTrans = tbActorInfo.ship_move_data.transform
    else
        tbRet.nTemplateType = TemplateTypeDef.HUMAN
        tbTrans = tbActorInfo.human_move_data.transform
    end

    tbRet.nLocationX = tbTrans.x
    tbRet.nLocationY = tbTrans.y
    tbRet.nLocationZ = tbTrans.z
    tbRet.nRotationYaw = tbTrans.yaw
    return tbRet
end

---------------------------------------------------------------------------------------
-- Npc
function GOCreateDataHelper_C:ParseNpcHubData(tbProtoData)
    -- s2c_NpcCreate

    local tbRet = {}
    tbRet.nServerInstanceId = tbProtoData.actor_id
    --tbRet.bIsShip = true  -- 根据npc模板自己判断
    tbRet.nTemplateId = tbProtoData.npc_template_id

    local tbTrans = tbProtoData.transform
    tbRet.nLocationX = tbTrans.x
    tbRet.nLocationY = tbTrans.y
    tbRet.nLocationZ = tbTrans.z
    tbRet.nRotationYaw = tbTrans.yaw
    tbRet.szNameArg = tbProtoData.name_arg
    tbRet.nVfxID = tbProtoData.vfx
    return tbRet
end

function GOCreateDataHelper_C:ParseNpcReplicatedData(pUEActor, nServerInstanceId, tbInitProtoData)
    local tbRet = {}
    tbRet.nServerInstanceId = nServerInstanceId
    --tbRet.bIsShip = true  -- 根据npc模板自己判断
    tbRet.nTemplateId = tbInitProtoData.template_id
    tbRet.szName = tbInitProtoData.name
    tbRet.szTag = tbInitProtoData.tag

    local pLocation = EngineExtActorShell.GetActorLocation(pUEActor)
    tbRet.nLocationX = pLocation.X
    tbRet.nLocationY = pLocation.Y
    tbRet.nLocationZ = pLocation.Z
    tbRet.nRotationYaw = EngineExtActorShell.GetActorRotation(pUEActor).Yaw
    return tbRet
end

---------------------------------------------------------------------------------------
-- Trigger
function GOCreateDataHelper_C:ParseTriggerHubData(tbProtoData)
    local tbRet = {}
    tbRet.nServerInstanceId = tbProtoData.actor_id
    tbRet.nTemplateId = -1
    tbRet.nResId = tbProtoData.res_id

    tbRet.nShapeType = tbProtoData.shape_type -- GameTriggerClass.SHAPE_TYPE_CIRCLE   -- 写死圆，以后有需求再开
    tbRet.nRadius = tbProtoData.radius
    tbRet.nBoxX = tbProtoData.box_x
    tbRet.nBoxY = tbProtoData.box_y
    tbRet.nBoxZ = tbProtoData.box_z

    local tbTrans = tbProtoData.transform
    tbRet.nLocationX = tbTrans.x
    tbRet.nLocationY = tbTrans.y
    tbRet.nLocationZ = tbTrans.z
    tbRet.nRotationYaw = tbTrans.yaw
    return tbRet
end

function GOCreateDataHelper_C:ParseTriggerReplicatedData(pUEActor, nServerInstanceId, tbInitProtoData)
    local tbRet = {}
    tbRet.nServerInstanceId = nServerInstanceId
    tbRet.nTemplateId = -1

    local pLocation = EngineExtActorShell.GetActorLocation(pUEActor)
    tbRet.nLocationX = pLocation.X
    tbRet.nLocationY = pLocation.Y
    tbRet.nLocationZ = pLocation.Z
    tbRet.nRotationYaw = EngineExtActorShell.GetActorRotation(pUEActor).Yaw
    tbRet.nResId = tbInitProtoData.res_id
    tbRet.nShapeType = tbInitProtoData.shape_type
    tbRet.nRadius = tbInitProtoData.radius
    tbRet.nBoxX = tbInitProtoData.box_x
    tbRet.nBoxY = tbInitProtoData.box_y
    tbRet.nBoxZ = tbInitProtoData.box_z
    tbRet.tbCustomData = tbInitProtoData.custom_data
    return tbRet
end

---------------------------------------------------------------------------------------
-- Dummy-TODO
-- hub 传过来的数据
function GOCreateDataHelper_C:ParseDummyHubData(tbProtoData)
    local tbRet = {}
    tbRet.nServerInstanceId = tbProtoData.actor_id
    tbRet.nTemplateId = tbProtoData.template_id
    local tbTrans = tbProtoData.transform
    tbRet.nLocationX = tbTrans.x
    tbRet.nLocationY = tbTrans.y
    tbRet.nLocationZ = tbTrans.z
    tbRet.nRotationYaw = tbTrans.yaw
    return tbRet
end

-- DS replicate 过来的数据
function GOCreateDataHelper_C:ParseDummyReplicatedData(pUEActor, nServerInstanceId, tbInitProtoData)
    local tbRet = {}
    tbRet.nServerInstanceId = nServerInstanceId
    tbRet.nTemplateId = tbInitProtoData.template_id

    local pLocation = EngineExtActorShell.GetActorLocation(pUEActor)
    tbRet.nLocationX = pLocation.X
    tbRet.nLocationY = pLocation.Y
    tbRet.nLocationZ = pLocation.Z
    tbRet.nRotationYaw = EngineExtActorShell.GetActorRotation(pUEActor).Yaw
    return tbRet
end

------------------------------------------------------------------------------------------
-- Destructible object
-- DS replicate 过来的数据
function GOCreateDataHelper_C:ParseDestructibleObjectReplicatedData(pUEActor, nServerInstanceId, tbInitProtoData)
    local tbRet = {}
    tbRet.nServerInstanceId = nServerInstanceId
    tbRet.nTemplateId = tbInitProtoData.template_id

    local pLocation = EngineExtActorShell.GetActorLocation(pUEActor)
    tbRet.nLocationX = pLocation.X
    tbRet.nLocationY = pLocation.Y
    tbRet.nLocationZ = pLocation.Z
    tbRet.nRotationYaw = EngineExtActorShell.GetActorRotation(pUEActor).Yaw
    
    local pScale = EngineExtActorShell.GetActorScale3D(pUEActor)
    tbRet.nScaleX = pScale.X
    tbRet.nScaleY = pScale.Y
    tbRet.nScaleZ = pScale.Z

    return tbRet
end

return GOCreateDataHelper_C()
