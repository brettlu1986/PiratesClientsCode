local luaclass = require("luaclass")
local CppDelegateProcessorBaseClass = require("CPPDelegateProcessorBase")
local ActorCppDelegateProcessor = luaclass("ActorCppDelegateProcessor", CppDelegateProcessorBaseClass)
local GlobalVariableSystem = dynamic_require("GlobalVariableSystem")
local BattleGameModeSystem = dynamic_require("BattleGameModeSystem")
local GameObjectSystem = dynamic_require("GameObjectSystem")
local GameObjectTypeDef = require("GameObjectTypeDef")

function ActorCppDelegateProcessor:OnPawnPreBeginPlay(pUEActor, nUniqueId, nInstanceId)
    local tbGameObject = GameObjectSystem:FindByInstanceId(nInstanceId)
    if(tbGameObject) then
        GameObjectSystem:BindUEActor(tbGameObject, pUEActor)
        tbGameObject:OnActorPreCreated(pUEActor)
    end
end

function ActorCppDelegateProcessor:OnPawnPostBeginPlay(pUEActor, nUniqueId, nInstanceId)
    local tbGameObject = GameObjectSystem:FindByInstanceId(nInstanceId)
    if(tbGameObject) then
        tbGameObject:OnActorCreated(pUEActor)
    end
end

function ActorCppDelegateProcessor:OnPawnEndPlay(pUEActor, nUniqueId, nServerInstanceId)
    local tbGameObject = GameObjectSystem:FindByUniqueId(nUniqueId)
    if(tbGameObject == nil) then
        log("ActorCppDelegateProcessor:OnEndPlay ignore", nUniqueId)
        return
    end

    log("OnPawnEndPlay", nUniqueId, nServerInstanceId)
    GameObjectSystem:UnbindUEActor(tbGameObject, nUniqueId)
end

--local tbLoggedIds = {} --临时防止log刷屏，解决问题后删掉
function ActorCppDelegateProcessor:OnPawnFellOutOfWorld(pUEActor, nUniqueId, nServerInstanceId)
    if(not GlobalVariableSystem:IsServerLogic()) then
        return
    end

    local tbGameObject = GameObjectSystem:FindByUniqueId(nUniqueId)
    if(tbGameObject == nil or tbGameObject.ObjectType ~= GameObjectTypeDef.PlayerSelf) then
        log("ActorCppDelegateProcessor:OnPawnFellOutOfWorld ignore", nUniqueId)
--[[
        if tbGameObject and not tbLoggedIds[nUniqueId] then
            tbLoggedIds[nUniqueId] = true
            local X, Y, Z = EngineExtActorShell.GetActorLocationXYZ(tbGameObject.pUEActor)
            logwarning("ActorCppDelegateProcessor:OnPawnFellOutOfWorld ObjectType,nInstanceId Pos:",
            tbGameObject.ObjectType, tbGameObject:GetServerInstanceId(), X, Y, Z)
        end
]]
        return
    end

    tbGameObject:SetLocation(0, 0, 200)
    log("OnPawnFellOutOfWorld, KickPlayer", nUniqueId, nServerInstanceId)
    BattleGameModeSystem:KickPlayer(tbGameObject)
    --tbGameObject:KillSelf()
    -- GameObjectSystem:UnbindUEActor(tbGameObject)
end

local function OnPawnLeavingGame(self, pUEActor, nUniqueId, nServerInstanceId)
    local tbGamePlayer = GameObjectSystem:FindByInstanceId(nServerInstanceId)
    local pUEController = tbGamePlayer:GetUEController()
    if pUEController ~= nil then
        pUEController:UnPossess()
    end
end

function ActorCppDelegateProcessor:Init()
    ActorCppDelegateProcessor.super.Init(self)

    local DelegateMgr = CommonShell.GetCommon(GWorld):GetGameDelegateManager().Actor
    self:RegisterMethod(DelegateMgr.OnPawnPreBeginPlay, self, self.OnPawnPreBeginPlay)
    self:RegisterMethod(DelegateMgr.OnPawnPostBeginPlay, self, self.OnPawnPostBeginPlay)
    self:RegisterMethod(DelegateMgr.OnPawnEndPlay, self, self.OnPawnEndPlay)
    self:RegisterMethod(DelegateMgr.OnPawnFellOutOfWorld, self, self.OnPawnFellOutOfWorld)
    self:RegisterMethod(DelegateMgr.OnPawnLeavingGame, self, OnPawnLeavingGame)

    return true
end

return ActorCppDelegateProcessor
