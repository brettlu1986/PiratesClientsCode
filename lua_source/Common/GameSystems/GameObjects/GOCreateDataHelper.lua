local luaclass = require("luaclass")
local GOCreateDataHelper = luaclass("GOCreateDataHelper")

local GameObjectTypeDef = require("GameObjectTypeDef")
local DungeonCommonProtoNames = require("DungeonCommonProtoNames")
local TemplateTypeDef = require("TemplateTypeDef")


-- function GOCreateDataHelper:Reset()
--     local tbData = self.tbCreateData
--     if(tbData == nil) then
--         tbData = {}
--         self.tbCreateData = tbData
--     end

--     tbData.nServerInstanceId = -1
--     tbData.nTemplateId = -1
--     tbData.szName = ""
--     tbData.nLocationX = 0
--     tbData.nLocationY = 0
--     tbData.nLocationZ = 0
--     tbData.nRotationYaw = 0
--     tbData.bIsShip = true
--     tbData.nPlayerId = -1
-- end

function GOCreateDataHelper:ParsePlayerSelfGameModeData(tbPrepareInfo, nServerInstanceId, tbSpawnInfo)
    local tbRet = {}
    tbRet.bCreateUEActor = tbSpawnInfo.bCreateUEActor
    tbRet.nServerInstanceId = nServerInstanceId
    tbRet.szName = tbPrepareInfo.szPlayerName

    if tbSpawnInfo.nTemplateType ~= nil then
        tbRet.nTemplateType = tbSpawnInfo.nTemplateType
    else
        tbRet.nTemplateType = TemplateTypeDef.SHIP
    end

    tbRet.nPlayerId = tbPrepareInfo.nPlayerId
    tbRet.szPlayerSessionId = tbPrepareInfo.szPlayerSessionId
    tbRet.nHumanId = tbPrepareInfo.nHumanId
    tbRet.tbPrepareInfo = tbPrepareInfo
    tbRet.nToken = tbPrepareInfo.nToken
    if(tbSpawnInfo.nTemplateId ~= nil) then
        tbRet.nTemplateId = tbSpawnInfo.nTemplateId
    else
        if tbRet.nTemplateType == TemplateTypeDef.SHIP then
            tbRet.nTemplateId = tbPrepareInfo.tbShipInfo.nTypeId
        else
            tbRet.nTemplateId = tbRet.nHumanId
        end
    end

    local tbStartJsonData = tbSpawnInfo.tbStartJsonData
    if tbStartJsonData ~= nil then
        local tbTransform = tbStartJsonData.Transform
        tbRet.nLocationX = tbTransform.X
        tbRet.nLocationY = tbTransform.Y
        tbRet.nLocationZ = tbTransform.Z
        tbRet.nRotationYaw = tbTransform.Yaw
    end

    tbRet.szInitProtoName = DungeonCommonProtoNames.PlayerActorInitData
    tbRet.tbInitProtoData = 
    {
        script_type = GameObjectTypeDef.PlayerSelf,
        template_id = tbRet.nTemplateId,
        name = tbRet.szName,
        player_id = tbRet.nPlayerId,
        human_id = tbRet.nHumanId,
        ship_res = {},
        template_type = tbRet.nTemplateType,
    }

    return tbRet
end

------------------------------------------------------------------------------------
-- Npc
-- function GOCreateDataHelper:ParseNpcGameModeData(nServerInstanceId, nTemplateId, 
--     nX, nY, nZ, nYaw, nGroupIndex, szTag, tbJsonData, szName, bCreateUEActor)
function GOCreateDataHelper:ParseNpcGameModeData(nServerInstanceId, tbSpawnInfo)

    local tbRet = {}
    tbRet.nServerInstanceId = nServerInstanceId
    tbRet.nTemplateId = tbSpawnInfo.nTemplateId
    tbRet.nLocationX = tbSpawnInfo.nX
    tbRet.nLocationY = tbSpawnInfo.nY
    tbRet.nLocationZ = tbSpawnInfo.nZ
    tbRet.nRotationYaw = tbSpawnInfo.nYaw
    tbRet.nGroupIndex = tbSpawnInfo.nGroupIndex or 0
    local tbJsonData = tbSpawnInfo.tbJsonData
    if(tbJsonData) then
        tbRet.nSubGroupIndex = tbJsonData.SubGroupIndex
    end
    tbRet.szTag = tbSpawnInfo.szTag    
    tbRet.szName = tbSpawnInfo.szName or ""
    tbRet.bCreateUEActor = tbSpawnInfo.bCreateUEActor == nil or tbSpawnInfo.bCreateUEActor

    tbRet.szInitProtoName = DungeonCommonProtoNames.NpcActorInitData
    tbRet.tbInitProtoData = 
    {
        script_type = GameObjectTypeDef.Npc,
        template_id = tbRet.nTemplateId,
        name = tbRet.szName,
        tag = tbRet.szTag
    }
    return tbRet
end

------------------------------------------------------------------------------------
-- Trigger
function GOCreateDataHelper:ParseTriggerGameModeData(nServerInstanceId, tbSpawnInfo)
    local tbRet = {}
    local tbJsonData = tbSpawnInfo.tbJsonData
    local tbCustomData = tbSpawnInfo.tbCustomData
    local tbTransform = tbJsonData.Transform
    tbRet.nServerInstanceId = nServerInstanceId
    tbRet.nTemplateId = -1
    tbRet.nLocationX = tbTransform.X
    tbRet.nLocationY = tbTransform.Y
    tbRet.nLocationZ = tbTransform.Z
    tbRet.nRotationYaw = tbTransform.Yaw
    tbRet.nResId = tbJsonData.ResId
    tbRet.nTriggerId = tbJsonData.TriggerId
    tbRet.nCollisionType = tbJsonData.CollisionType or 0
    tbRet.nGroupIndex = tbJsonData.GroupIndex
    tbRet.nSubGroupIndex = tbJsonData.SubGroupIndex
    tbRet.szTag = tbJsonData.Tag
    tbRet.tbCustomData = tbCustomData

    local tbShapeInfo = tbJsonData.Shape
    tbRet.nShapeType = tbShapeInfo.Type
    tbRet.nRadius = tbShapeInfo.Radius
    tbRet.nBoxX = tbShapeInfo.BoxX
    tbRet.nBoxY = tbShapeInfo.BoxY
    tbRet.nBoxZ = tbShapeInfo.BoxZ
    tbRet.szInitProtoName = DungeonCommonProtoNames.TriggerActorInitData
    tbRet.tbInitProtoData = 
    {
        script_type = GameObjectTypeDef.Trigger,
        res_id = tbJsonData.ResId,
        shape_type = tbShapeInfo.Type,
        radius = tbShapeInfo.Radius,
        box_x = tbShapeInfo.BoxX,
        box_y = tbShapeInfo.BoxY,
        box_z = tbShapeInfo.BoxZ,
        collision_type = tbJsonData.CollisionType,
        custom_data = tbCustomData,
    }
    return tbRet
end

------------------------------------------------------------------------------------
-- Dummy
function GOCreateDataHelper:ParseDummyGameModeData(nServerInstanceId, nTemplateId, tbTransform, tbScale, szTag)
    local tbRet = {}
    tbRet.nServerInstanceId = nServerInstanceId
    tbRet.nTemplateId = nTemplateId

    tbRet.nLocationX = tbTransform.X
    tbRet.nLocationY = tbTransform.Y
    tbRet.nLocationZ = tbTransform.Z
    tbRet.nRotationYaw = tbTransform.Yaw
    tbRet.szTag = szTag

    if tbScale ~= nil then
        tbRet.nScaleX = tbScale.X
        tbRet.nScaleY = tbScale.Y
        tbRet.nScaleZ = tbScale.Z
    end

    tbRet.szInitProtoName = DungeonCommonProtoNames.DummyActorInitData
    tbRet.tbInitProtoData = 
    {
        script_type = GameObjectTypeDef.Dummy,
        template_id = nTemplateId
    }
    return tbRet
end


function GOCreateDataHelper:ParseVehicleGameModeData(nServerInstanceId, nTemplateId, VehicleType, tbSpawnInfo)
    local tbRet = {}
    tbRet.nServerInstanceId = nServerInstanceId
    tbRet.nTemplateId = nTemplateId
    
    tbRet.nLocationX = tbSpawnInfo.X
    tbRet.nLocationY = tbSpawnInfo.Y
    tbRet.nLocationZ = tbSpawnInfo.Z
    tbRet.nRotationYaw = tbSpawnInfo.Yaw


    tbRet.szInitProtoName = DungeonCommonProtoNames.DummyActorInitData
    tbRet.tbInitProtoData = 
    {
        script_type = VehicleType,
        template_id = nTemplateId
    }
    return tbRet
end

function GOCreateDataHelper:ParseDestructibleObjectGameModeData(nServerInstanceId, nTemplateId, tbTransform, tbScale, tbJsonData)
    local tbRet = {}
    tbRet.nServerInstanceId = nServerInstanceId
    tbRet.nTemplateId = nTemplateId
    
    tbRet.nLocationX = tbTransform.X
    tbRet.nLocationY = tbTransform.Y
    tbRet.nLocationZ = tbTransform.Z
    tbRet.nRotationYaw = tbTransform.Yaw

    tbRet.nScaleX = tbScale.X
    tbRet.nScaleY = tbScale.Y
    tbRet.nScaleZ = tbScale.Z

    tbRet.szInitProtoName = DungeonCommonProtoNames.DestructibleActorInitData
    tbRet.tbInitProtoData = 
    {
        script_type = GameObjectTypeDef.DestructibleObject,
        template_id = nTemplateId,
    }
    return tbRet
end

return GOCreateDataHelper()
