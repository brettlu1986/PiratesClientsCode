local luaclass = require("luaclass")
local PlayerCppDelegateProcessorClass = require("PlayerCppDelegateProcessor")
local PlayerCppDelegateProcessor_C = luaclass("PlayerCppDelegateProcessor_C", PlayerCppDelegateProcessorClass)
-- local GameObjectSystem = dynamic_require("GameObjectSystem")
local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
-- local ClientEventDef = require("ClientEventDef")
-- local EventManager = require("EventManager")


-- local function CheckPawnReady(tbPlayerController, tbPawn)
--     if EngineExtActorShell.HasActorBegunPlay(tbPawn:GetModelActor()) then
--         EventManager:OnFireEvent(ClientEventDef.EV_PLAYERSELF_READY, self)
--     else
--         local fnCallback = function(tbInPawn)
--             if tbInPawn == tbPawn then
--                 CheckPawnReady(tbPlayerController, tbPawn)
--                 EventManager:UnBindEvent(CommonEventDef.EV_SHIP_BATTLE_PAWN_SELF_ON_BEGIN_PLAY, fnCallback)
--             end
--         end
--         EventManager:BindEvent(CommonEventDef.EV_SHIP_BATTLE_PAWN_SELF_ON_BEGIN_PLAY, fnCallback)
--     end
-- end

-- TODO: 待处理
--local function SetPawnToController(nPcUniqueId, nPawnUniqueId)
    -- local tbGamePlayer = GameObjectSystem:FindByUniqueId(nPcUniqueId)
    -- if tbGamePlayer == nil then
    --     logerror("Cannot find PlayerController with UniqueId:", nPcUniqueId)
    -- end
    -- local tbPawn = BattleActorManager:FindBattleActor(nPawnUniqueId)
    -- if tbPawn == nil then
    --     logerror("Cannot find Pawn with UniqueId:", nPawnUniqueId)
    -- end
    -- if tbPlayerController ~= nil and tbPawn ~= nil then
    --     tbPlayerController:SetPawn(tbPawn)
    --     CheckPawnReady(tbPlayerController, tbPawn)
    -- end
--end

-- This function will be called only when run as standalone mode
-- function PlayerCppDelegateProcessor_C:OnPlayerControllerPostPossess(tbPlayerController, tbPawn)
--     PlayerCppDelegateProcessor_C.super.OnPlayerControllerPostPossess(self, tbPlayerController, tbPawn)
--     CheckPawnReady(tbPlayerController, tbPawn)
-- end

-- function PlayerCppDelegateProcessor_C:OnBeginSpectating(nUniqueId)
--     PlayerCppDelegateProcessor_C.super.OnBeginSpectating(self, nUniqueId)

-- end

-- function PlayerCppDelegateProcessor_C:OnEndSpectating(nUniqueId)
--     PlayerCppDelegateProcessor_C.super.OnEndSpectating(self, nUniqueId)
-- end

-- 这函数保证了controller和pawn分别设到了对方身上
local function OnClientRestart(pController, nPcUniqueId, nPCNetGuid, pPawn, nPawnUniqueId, nPawnNetGuid)
    log("OnClientRestart", nPcUniqueId, nPCNetGuid, nPawnUniqueId, nPawnNetGuid)
    
    local GamePlayerSelf = GamePlayerSelfHelper:Get()
    if(GamePlayerSelf == nil) then
        logerror("OnClientRestart failed, can not find player self")        
        return
    end
    local HumanMovementStateComponent = GamePlayerSelf.HumanMovementStateComponent

    --if(not GamePlayerSelf.bReady) then
    --这里需要考虑人船切换的情况，以及上下载具的情况，还有断线重连时人在载具上的情况
    if not HumanMovementStateComponent or not HumanMovementStateComponent:IsInVehicle() or not GamePlayerSelf.bReady then 
        GamePlayerSelf:OnClientRestart(nPCNetGuid, nPawnNetGuid)
        --EventManager:OnFireEvent(ClientEventDef.EV_CLIENT_RESTART, nPcUniqueId, nPCNetGuid, nPawnUniqueId, nPawnNetGuid)
        GamePlayerSelfHelper:Get():VerifyReplicatedPlayerReady()
    end
end

function PlayerCppDelegateProcessor_C:OnClientWasKicked(szKickReason)
    log("Player was kicked. Reason: ", szKickReason)
    ClientShell.GetClient(GWorld):GetDungeonShell():DisconnectFromDungeonServer(false)
end

function PlayerCppDelegateProcessor_C:Init()
    PlayerCppDelegateProcessor_C.super.Init(self)
    -- Register Gameplay Delegate
    local DelegateMgr = ClientShell.GetClient(GWorld):GetGameDelegateManager()

    self:Register(DelegateMgr.Player.OnClientRestart, OnClientRestart)
    self:RegisterMethod(DelegateMgr.Player.OnClientWasKicked, self, self.OnClientWasKicked)

   
    return true
end

return PlayerCppDelegateProcessor_C
