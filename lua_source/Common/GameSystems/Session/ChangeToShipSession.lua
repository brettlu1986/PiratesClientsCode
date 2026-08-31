local luaclass = require("luaclass")
local SessionBase = require("SessionBase")
local ChangeToShipSession = luaclass("ChangeToShipSession", SessionBase)

local GameObjectSystem = dynamic_require("GameObjectSystem")
local GameObjectTypeDef = require("GameObjectTypeDef")
local TemplateTypeDef = require("TemplateTypeDef")
local SessionHelper = require("SessionHelper")
local EventManager = require("EventManager")
local CommonEventDef = require("CommonEventDef")

ChangeToShipSession.tbData = nil

function ChangeToShipSession:OnStarted(tbParams)
    ChangeToShipSession.super.OnStarted(self, tbParams)

    self.tbData = {}

    local tbGameObject = tbParams.tbGameObject
    assert(tbGameObject)
    assert(tbGameObject.ObjectType == GameObjectTypeDef.PlayerSelf or tbGameObject.ObjectType == GameObjectTypeDef.Npc)
    log(string.format("ChangeToShip instanceid: %d", tbGameObject:GetServerInstanceId()))

    -- 不用外面传的shipid了，用自身的
    -- local nShipId = tbParams.nShipId
    -- assert(nShipId ~= nil)
    -- if(nShipId ~= nil) then
    --     logdebug(debug.traceback())
    -- else
    --     log("Go back to docked ship, instanceid:", tbGameObject:GetServerInstanceId())
    -- end

    assert(not tbGameObject:IsDead())
    EventManager:OnFireEvent(CommonEventDef.EV_START_CHANGEDISPLAY, tbGameObject, TemplateTypeDef.SHIP)

    local nLastTemplateType = tbGameObject:GetTemplateType()
    local tbTransform = SessionHelper.VerifyObjectNewTransform(tbGameObject, tbParams.tbTransform)
    local nCampType = tbGameObject.BattleCampComponent:GetCampType()

    GameObjectSystem:DestroyUEActor(tbGameObject)

    local tbPlayerStart = {}
    tbPlayerStart.Transform = tbTransform
    tbPlayerStart.CampType = nCampType

    local tbSpawnInfo = {}
    tbSpawnInfo.tbStartJsonData = tbPlayerStart
    tbSpawnInfo.nTemplateType = TemplateTypeDef.SHIP
    tbSpawnInfo.szName = tbGameObject.szName
    tbSpawnInfo.szTag = tbGameObject.szTag

    if(tbGameObject.ObjectType == GameObjectTypeDef.PlayerSelf) then
        local tbPrepareInfo = tbGameObject.tbPrepareInfo
        tbSpawnInfo.nTemplateId = tbPrepareInfo.tbShipInfo.nTypeId
        local bPossess = (not tbGameObject.bIsBot) and tbGameObject:GetUEController() ~= nil

        local bRet = GameObjectSystem:SpawnPlayerSelfUEActorInGameMode(tbGameObject, tbGameObject.tbPrepareInfo, tbSpawnInfo, bPossess)
        if(not bRet) then
            error(string.format("ChangeToShip failed, the returned player is nil, playerid = %d, instanceid = %d", tbGameObject.nPlayerId, tbGameObject:GetServerInstanceId()))
        end
    elseif(tbGameObject.ObjectType == GameObjectTypeDef.Npc) then
        tbSpawnInfo.nTemplateId = tbGameObject:GetTemplateId()
        tbSpawnInfo.tbJsonData = tbPlayerStart
        tbPlayerStart.nSubGroupIndex = tbGameObject.nSubGroupIndex
        tbSpawnInfo.nGroupIndex = tbGameObject.nGroupIndex
        GameObjectSystem:SpawnNpcUEActorInGameMode(tbGameObject, tbSpawnInfo, tbGameObject.tbCustomData)
    else
        assert(false)
    end

    self:FinishSelf()

    local bTemplateTypeChanged = nLastTemplateType ~= TemplateTypeDef.SHIP
    EventManager:OnFireEvent(CommonEventDef.EV_END_CHANGEDISPLAY, tbGameObject, bTemplateTypeChanged)
end

function ChangeToShipSession:OnFinished()
    ChangeToShipSession.super.OnFinished(self)
end

function ChangeToShipSession:GetData()
    return self.tbData
end

return ChangeToShipSession