local luaclass = require("luaclass")
local BattleInteractionSystem = luaclass("BattleInteractionSystem")

local GameObjectSystem = dynamic_require("GameObjectSystem")
local MatineeSystem = dynamic_require("MatineeSystem")
local GlobalVariableSystem = dynamic_require("GlobalVariableSystem")

local EventManager = require("EventManager")
local CommonEventDef = require("CommonEventDef")

local NetworkManager = dynamic_require("NetworkManager")
local ProtoDC = require("DungeonCommonProtoNames")
local D2CHelper = require("D2CHelper")
local GameObjectTypeDef = require("GameObjectTypeDef")

BattleInteractionSystem.tbPlayingMatinee = nil
BattleInteractionSystem.tbMatineeStopObjects = nil
BattleInteractionSystem.bCollectionStart = false 

function BattleInteractionSystem:Init()
    self:ResetPlayingMatinee()

    if GlobalVariableSystem:IsServerLogic() then
        EventManager:BindEventMethod(CommonEventDef.EV_BATTLE_COLLECTION_START, self, self.CollectionStart)
        EventManager:BindEventMethod(CommonEventDef.EV_BATTLE_COLLECTION_END, self, self.OnCollectionEnd)
        EventManager:BindEventMethod(CommonEventDef.EV_BATTLE_INTERACTIONDLG_START_NPC, self, self.OnStartInteraction)
        EventManager:BindEventMethod(CommonEventDef.EV_GAME_OBJECT_ON_PAWN_DEAD, self, self.OnPlayerDead)
    end
    return true 
end

function BattleInteractionSystem:Uninit()
    if GlobalVariableSystem:IsServerLogic() then
        EventManager:UnBindEventMethod(CommonEventDef.EV_BATTLE_COLLECTION_START, self, self.CollectionStart)
        EventManager:UnBindEventMethod(CommonEventDef.EV_BATTLE_COLLECTION_END, self, self.OnCollectionEnd)
        EventManager:UnBindEventMethod(CommonEventDef.EV_BATTLE_INTERACTIONDLG_START_NPC, self, self.OnStartInteraction)
        EventManager:UnBindEventMethod(CommonEventDef.EV_GAME_OBJECT_ON_PAWN_DEAD, self, self.OnPlayerDead)
    end
end

function BattleInteractionSystem:ResetPlayingMatinee()
    self.tbPlayingMatinee = nil
    self.tbMatineeStopObjects = {}
end

function BattleInteractionSystem:OnPlayMatinee(nMatineeId, tbParent, fnOnComplete, bClientOnly, bPause)
    if bClientOnly and (not GlobalVariableSystem:IsClient()) then
        log("Server skips playing client only matinee", nMatineeId)
        return
    end

    if self.tbPlayingMatinee ~= nil or #self.tbMatineeStopObjects > 0 then
        logerror("BattleInteractionSystem:OnPlayMatinee failed. MatineeId - PlayingMatinee - StopMoveObjects count:",
            nMatineeId, self.tbPlayingMatinee, #self.tbMatineeStopObjects)
        return nil
    end

    local matinee = MatineeSystem:PlayMatinee(nMatineeId, false, function(tbMatinee)
        log("play matinee callback")
        if fnOnComplete then 
            fnOnComplete(tbMatinee)
        end 
        self:MatineeEnd(tbMatinee)
    end)
    if matinee ~= nil then
        EventManager:OnFireEvent(CommonEventDef.EV_BATTLE_MATINEE_PLAY, nMatineeId, matinee)

        if bPause then
            self.tbMatineeStopObjects = self:StopMove()
        end

        self.tbPlayingMatinee = matinee
    else
        if GlobalVariableSystem:IsClient() then
            logerror("PlayMatinee failed. Matineed", nMatineeId)
        end
    end
    return matinee
end

function BattleInteractionSystem:OnStopMatinee()
    if self.tbPlayingMatinee ~= nil then
        self.tbPlayingMatinee:StopMatinee()
    else
        log("Skip stop matinee. Matinee nil.")
    end
end

function BattleInteractionSystem:MatineeEnd(tbMatinee)
    log("BattleInteractionSystem:MatineeEnd")

    self:ResumeMove(self.tbMatineeStopObjects)
    self:ResetPlayingMatinee()
    -- Force to stop playing matinee on clients to ensure server and clients are in sync.
    self:StopMatinee()

    EventManager:OnFireEvent(CommonEventDef.EV_BATTLE_MATINEE_END)
end

function BattleInteractionSystem:OnShowDialog(nDialogId)
end

function BattleInteractionSystem:DialogEnd()
end

function BattleInteractionSystem:PlayMatinee(nMatineeId, bClientOnly, bPause)
    bClientOnly = bClientOnly or false
    bPause = bPause or false

    if bClientOnly and bPause and (not GlobalVariableSystem:IsClient()) then
        -- 防止Client上Pause，Server上没有Pause的不一致情况出现
        logerror("BattleInteractionSystem:PlayMatinee. Play matinee from server set both ClientOnly and Pause true is not allowed. Play matinee", nMatineeId, " failed.")
        return
    end

    local tbPacket = 
    {
        matinee_id = nMatineeId,
        client_only = bClientOnly,
        pause = bPause
    }
    NetworkManager:GetRPCNetworkProxy():Multicast(ProtoDC.d2c_PlayMatinee, tbPacket, false)
    self:OnPlayMatinee(nMatineeId, nil, nil, bClientOnly, bPause)
end

function BattleInteractionSystem:LocalPlayMatinee(nMatineeId, tbParent, fnOnComplete, bPause)
    if bPause and (not GlobalVariableSystem:IsStandaloneServer()) then
        -- 防止server上Pause，Client上没有pause，或者相反的不一致情况出现
        logerror("BattleInteractionSystem:LocalPlayMatinee. Pause set to true in non-standalone env is illegal.")
        return
    end
    local bClientOnly = GlobalVariableSystem:IsClient()
    self:OnPlayMatinee(nMatineeId, tbParent, fnOnComplete, bClientOnly, bPause)
end

function BattleInteractionSystem:PlayerPlayMatinee(tbPlayer, nMatineeId)
    local tbPacket = 
    {
        matinee_id = nMatineeId,
        client_only = true,
        pause = false
    }
    NetworkManager:GetRPCNetworkProxy():SendToClient(tbPlayer:GetUEControllerUniqueId(), ProtoDC.d2c_PlayMatinee, tbPacket)
end

function BattleInteractionSystem:StopMatinee()
    if GlobalVariableSystem:IsServerLogic() then
        NetworkManager:GetRPCNetworkProxy():Multicast(ProtoDC.d2c_StopMatinee, nil, false)
    end
    
    self:OnStopMatinee()
end

function BattleInteractionSystem:ShowDialog(nDialogId, bDialogBoard)
    local tbPacket = 
    {
        dialog_id = nDialogId,
        dialog_board = bDialogBoard,
    }
    NetworkManager:GetRPCNetworkProxy():Multicast(ProtoDC.d2c_ShowDialog, tbPacket, false)
end

function BattleInteractionSystem:PlayerShowDialog(tbPlayer, nDialogId)
    local tbPacket = 
    {
        dialog_id = nDialogId
    }
    NetworkManager:GetRPCNetworkProxy():SendToClient(tbPlayer:GetUEControllerUniqueId(), ProtoDC.d2c_ShowDialog, tbPacket)
end

function BattleInteractionSystem:ShowHeadDialog(tbShip, nDialogId)
    local pShip = tbShip.pUEActor
    if isvalidhandle(pShip) then
        local pRPCComponent = pShip.RPCComponent
        if pRPCComponent ~= nil then
            pRPCComponent:ShowBubbleForAll(nDialogId)
        end
    end
end

function BattleInteractionSystem:StopMove()
    local tbStopMoveObjects = {}
    local tbGameObjects = GameObjectSystem:GetAllGameObjects()
    for _, tbGameObject in pairs(tbGameObjects) do
        local pUEActor = tbGameObject.pUEActor
        if isvalidhandle(pUEActor) then
            local pShipMovementComponent = pUEActor.ShipMovementComponent
            if pShipMovementComponent ~= nil and pShipMovementComponent:IsActive() then
                pShipMovementComponent:Deactivate()
                table.insert(tbStopMoveObjects, tbGameObject)
            end
        end
    end
    return tbStopMoveObjects
end

function BattleInteractionSystem:ResumeMove(tbObjects)
    if tbObjects ~= nil then
        for _, tbGameObject in pairs(tbObjects) do
            if tbGameObject.pUEActor ~= nil and tbGameObject.pUEActor.ShipMovementComponent ~= nil then
                tbGameObject.pUEActor.ShipMovementComponent:Activate()
            end
        end
    end
end

function BattleInteractionSystem:CollectionStart(nResoueId, nPlayerServerInstanceId)
    if not self.bCollectionStart then 
        self.bCollectionStart = true
    end 
    local tbPacket = 
    {
        nresoueid = nResoueId,
    }
    -- NetworkManager:GetRPCNetworkProxy():Multicast(ProtoDC.d2c_StartCollection,tbPacket)
    local tbplayer = GameObjectSystem:FindByInstanceId(nPlayerServerInstanceId)
    if tbplayer then
        NetworkManager:GetRPCNetworkProxy():SendToClient(tbplayer:GetUEControllerUniqueId(), ProtoDC.d2c_StartCollection, tbPacket)
    end
end

function BattleInteractionSystem:OnCollectionEnd(nNpcServerInstanceId, nPlayerServerInstanceId)
    if not self.bCollectionStart then 
        return 
    end     
    self.bCollectionStart = false
    local tbplayer = GameObjectSystem:FindByInstanceId(nPlayerServerInstanceId)
    if tbplayer then
        NetworkManager:GetRPCNetworkProxy():SendToClient(tbplayer:GetUEControllerUniqueId(), ProtoDC.d2c_InteractionEnd)
    end
end

function BattleInteractionSystem:OnPlayerDead(tbDeadActor)
    if tbDeadActor and tbDeadActor.ObjectType == GameObjectTypeDef.PlayerSelf then
        NetworkManager:GetRPCNetworkProxy():SendToClient(tbDeadActor:GetUEControllerUniqueId(), ProtoDC.d2c_InteractionEnd)
    end    
end 

function BattleInteractionSystem:OnStartInteraction(nNpcServerInstanceId, nPlayerServerInstanceId)
    local tbNpc = GameObjectSystem:FindByInstanceId(nNpcServerInstanceId)
    if tbNpc ~= nil then
        local pUEActor = tbNpc.pUEActor
        if pUEActor.ShipMovementComponent then 
            pUEActor.ShipMovementComponent:Brake()
        end
    end
   
    local tbPlayer = GameObjectSystem:FindByInstanceId(nPlayerServerInstanceId)
    if tbPlayer ~= nil and tbPlayer.pUEActor ~= nil and tbPlayer.pUEActor.ShipMovementComponent ~= nil then
        D2CHelper:PlayerSwitchCommonHandlerMode(tbPlayer)
        tbPlayer.pUEActor.ShipMovementComponent:StopMovementImmediately()
    end
    self:OnCollectionEnd(nNpcServerInstanceId, nPlayerServerInstanceId)
end

return BattleInteractionSystem()