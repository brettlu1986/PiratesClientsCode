local NPCSystem = {}

local EventManager = require("EventManager")
local ClientEventDef = require("ClientEventDef")
local GameObjectSystem = require("GameObjectSystem_C")
local NPCInfoCollector = require("NPCInfoCollector")
local NPCDataTable = require("NPCDataTable")
local GameObjectTypeDef = require("GameObjectTypeDef")
local CommonEventDef = require("CommonEventDef")


NPCSystem.tbNPCList = {}

NPCSystem.ClearListCallback = nil
NPCSystem.UpdateNpcQuestInfo = nil
--  用于记录由于任务完成产生的NPC特效
NPCSystem.tbQuestNpcParticle = {}

function NPCSystem:Init()
    self.tbNPCList = {}    
    NPCInfoCollector:Init()
    self.ClearListCallback = function()
        self.tbNPCList = {}
    end
    EventManager:BindEvent(ClientEventDef.EV_PRE_LOAD_MAP, self.ClearListCallback)
    self.UpdateNpcQuestInfo = function(nNpcID, nType)
        self:OnUpdateNpcHeadInfo(nNpcID, nType)
    end
    EventManager:BindEvent(ClientEventDef.EV_UPDATE_NPC_QUEST_INFO, self.UpdateNpcQuestInfo)
    EventManager:BindEventMethod(CommonEventDef.EV_GAME_OBJECT_POST_ACTOR_CREATE, self, self.AddNPC)
    EventManager:BindEventMethod(CommonEventDef.EV_GAME_OBJECT_PRE_DESTORY, self, self.RemoveNPC)
end

function NPCSystem:Uninit()
    self.tbNPCList = nil
    NPCInfoCollector:Uninit()
    EventManager:UnBindEvent(ClientEventDef.EV_PRE_LOAD_MAP, self.ClearListCallback)
    EventManager:UnBindEvent(ClientEventDef.EV_UPDATE_NPC_QUEST_INFO, self.UpdateNpcQuestInfo)
    EventManager:UnBindEventMethod(CommonEventDef.EV_GAME_OBJECT_POST_ACTOR_CREATE, self, self.AddNPC)
    EventManager:UnBindEventMethod(CommonEventDef.EV_GAME_OBJECT_PRE_DESTORY, self, self.RemoveNPC)    
end

function NPCSystem:AddNPC(GameNpc)
    if(GameNpc.ObjectType == GameObjectTypeDef.Npc and GameNpc.nServerInstanceId > 0) then
        self.tbNPCList[GameNpc.nServerInstanceId] = GameNpc
        GameNpc:SetHumanMovementComponent(false)
        if self.tbQuestNpcParticle[GameNpc.nTemplateId] then 
            GameNpc:SyncNpcRes(self.tbQuestNpcParticle[GameNpc.nTemplateId])
            GameNpc.bEnableInteraction = false 
        end 
    end
end

function NPCSystem:RemoveNPC(GameNpc)
    if(GameNpc.ObjectType == GameObjectTypeDef.Npc and GameNpc.nServerInstanceId > 0) then
        self.tbNPCList[GameNpc.nServerInstanceId] = nil
    end
end

function NPCSystem:GetNPCList()
    return self.tbNPCList
end

function NPCSystem:IsValid(Npc)
    if Npc == nil then
        return false
    end
    return self.tbNPCList[Npc.nServerInstanceId] and true or false
end

function NPCSystem:GetNPCByUEActor(pUEActor)
    local FoundObject = GameObjectSystem:FindByUEActor(pUEActor)
    if FoundObject then
        return self.tbNPCList[FoundObject.nServerInstanceId]
    end
    return nil
end

function NPCSystem:GetNpcByID(nNpcID)
    return self.tbNPCList[nNpcID]
end 

function NPCSystem:GetNpcByTemplateID(nNpcTemplateID)
    local tbGameObjs = GameObjectSystem:GetAllGameObjects()
    if not tbGameObjs then 
        return nil 
    end 
    for k,v in pairs(tbGameObjs) do
        if v.ObjectType == GameObjectTypeDef.Npc and v.nTemplateId == nNpcTemplateID then 
            return v 
        end 
    end
    return nil 
end 

function NPCSystem:OnUpdateNpcHeadInfo(nNpcID)
    local tbNPC = self.tbNPCList[nNpcID]

    if not tbNPC or not tbNPC.NpcQuestComponent then 
        return
    end 

    tbNPC.NpcQuestComponent:UpdateHeadInfo()
end

function NPCSystem:GetInteractionDistance( nNpcTemplateID )
    local tbTemplate = NPCDataTable:GetTemplate(nNpcTemplateID)
    if(tbTemplate == nil) then
        logerror("GameNpc:OnPreCreate failed, nTemplateId:", nNpcTemplateID)
        return 0
    end
    return tbTemplate.nDistance
    -- if(tbTemplate.nShipID ~= -1) then
    --     return NPCIni.nDistanceShip
    -- else
    --     return NPCIni.nDistanceHuman
    -- end
end

--------------------------------------------------------------------------------------------------------
function NPCSystem:FindDataBySceneId(nSceneId)
    return NPCInfoCollector:FindDataBySceneId(nSceneId)
end

function NPCSystem:FindDataByUsage(nSceneId, nUsage)
    local tbRet = {}
    NPCInfoCollector:FindByUsage(nSceneId, nUsage, tbRet)
    return tbRet
end

function NPCSystem:FindDataByTemplateId(nSceneId, nTemplateId)
    return NPCInfoCollector:FindDataByTemplateId(nSceneId, nTemplateId)
end

function NPCSystem:FindDataByRangeTemplateId(nSceneId, nBeginId, nEndId)
    return NPCInfoCollector:FindDataByRangeTemplateId(nSceneId, nBeginId, nEndId)
end

function NPCSystem:AddServerNPCInfo(nSceneId, nActorId, nTemplateId, tbTransform, nUsage)
    NPCInfoCollector:AddServerNPCInfo(nSceneId, nActorId, nTemplateId, tbTransform, nUsage)
end

function NPCSystem:RemoveServerNPCInfo(nActorId)
    NPCInfoCollector:RemoveServerNPCInfo(nActorId)
end

function NPCSystem:FindServerNPCInfo(nUsage)
    local tbRet = {}
    NPCInfoCollector:FindServerNPCInfo(nUsage, tbRet)
    return tbRet
end

return NPCSystem