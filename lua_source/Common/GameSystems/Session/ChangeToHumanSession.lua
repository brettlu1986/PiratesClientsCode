local luaclass = require("luaclass")
local SessionBase = require("SessionBase")
local ChangeToHumanSession = luaclass("ChangeToHumanSession", SessionBase)

local GameObjectSystem = dynamic_require("GameObjectSystem")
local GameObjectTypeDef = require("GameObjectTypeDef")
local TemplateTypeDef = require("TemplateTypeDef")
local SessionHelper = require("SessionHelper")
local CommonEventDef = require("CommonEventDef")
local EventManager = require("EventManager")

ChangeToHumanSession.tbData = nil

function ChangeToHumanSession:OnStarted(tbParams)
    ChangeToHumanSession.super.OnStarted(self, tbParams)

    self.tbData = {}

    local tbGameObject = tbParams.tbGameObject
    -- assert(tbGameObject:IsShip())
    assert(tbGameObject)
    assert(tbGameObject.ObjectType == GameObjectTypeDef.PlayerSelf or tbGameObject.ObjectType == GameObjectTypeDef.Npc)
    log(string.format("ChangeToHuman instanceid: %d", tbGameObject:GetServerInstanceId()))

    -- 不用外面传的humanid了，用自身的
    -- local nHumanId = tbParams.nHumanId
    -- assert(nHumanId ~= nil)

    assert(not tbGameObject:IsDead())
    EventManager:OnFireEvent(CommonEventDef.EV_START_CHANGEDISPLAY, tbGameObject, TemplateTypeDef.HUMAN)

    local nLastTemplateType = tbGameObject:GetTemplateType()
    local tbTransform = SessionHelper.VerifyObjectNewTransform(tbGameObject, tbParams.tbTransform)
    local nCampType = tbGameObject.BattleCampComponent and tbGameObject.BattleCampComponent:GetCampType() or 0
    if(tbGameObject.pUEActor) then
        GameObjectSystem:DestroyUEActor(tbGameObject)
    end

    local tbPlayerStart = {}
    tbPlayerStart.Transform = tbTransform
    tbPlayerStart.CampType = nCampType

    local tbSpawnInfo = {}
    tbSpawnInfo.tbStartJsonData = tbPlayerStart
    tbSpawnInfo.nTemplateType = TemplateTypeDef.HUMAN
    tbSpawnInfo.szName = tbGameObject.szName
    tbSpawnInfo.szTag = tbGameObject.szTag

    if(tbGameObject.ObjectType == GameObjectTypeDef.PlayerSelf) then
        local tbPrepareInfo = tbGameObject.tbPrepareInfo
        tbSpawnInfo.nTemplateId = tbPrepareInfo.nHumanId
        local bPossess = (not tbGameObject.bIsBot) and tbGameObject:GetUEController() ~= nil

        local bRet = GameObjectSystem:SpawnPlayerSelfUEActorInGameMode(tbGameObject, tbPrepareInfo, tbSpawnInfo, bPossess)
        if(not bRet) then
            error(string.format("ChangeToHuman failed, the returned player is nil, playerid = %d, instanceid = %d", tbGameObject.nPlayerId, tbGameObject:GetServerInstanceId()))
        end
    elseif(tbGameObject.ObjectType == GameObjectTypeDef.Npc) then
        tbSpawnInfo.nTemplateId = tbGameObject.nTemplateId
        tbSpawnInfo.nX = tbTransform.X
        tbSpawnInfo.nY = tbTransform.Y
        tbSpawnInfo.nZ = tbTransform.Z
        tbSpawnInfo.nYaw = tbTransform.Yaw
        tbSpawnInfo.tbJsonData = tbPlayerStart
        tbPlayerStart.nSubGroupIndex = tbGameObject.nSubGroupIndex
        tbSpawnInfo.nGroupIndex = tbGameObject.nGroupIndex
        GameObjectSystem:SpawnNpcUEActorInGameMode(tbGameObject, tbSpawnInfo, tbGameObject.tbCustomData)
    else
        assert(false)
    end

    self:FinishSelf()

    local bTemplateTypeChanged = nLastTemplateType ~= TemplateTypeDef.HUMAN
    EventManager:OnFireEvent(CommonEventDef.EV_END_CHANGEDISPLAY, tbGameObject, bTemplateTypeChanged)
end

function ChangeToHumanSession:OnFinished()
    ChangeToHumanSession.super.OnFinished(self)
end

function ChangeToHumanSession:GetData()
    return self.tbData
end

return ChangeToHumanSession