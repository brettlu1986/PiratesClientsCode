-- NPC角色

local luaclass = require("luaclass")
local GameCharacterClass = dynamic_require("GameCharacter")
local GamePlayer = luaclass("GamePlayer", GameCharacterClass)
local GlobalVariableSystem = dynamic_require("GlobalVariableSystem")

GamePlayer.nPlayerId = -1
GamePlayer.nToken = -1
-- 服务器准备信息，从hubserver传过来的信息
GamePlayer.tbPrepareInfo = nil
GamePlayer.szGuildName = nil
GamePlayer.szPlayerSessionId = nil

function GamePlayer:ParseCreateData(tbCreateData)
    if(not GamePlayer.super.ParseCreateData(self, tbCreateData)) then
        return false
    end

    self.nPlayerId = tbCreateData.nPlayerId
    self.szPlayerSessionId = tbCreateData.szPlayerSessionId
    self.tbPrepareInfo = tbCreateData.tbPrepareInfo
    self.szGuildName = tbCreateData.szGuildName
    self.nToken = tbCreateData.nToken
    if(self.nPlayerId == nil) then
        logerror("GamePlayer:OnPreCreate failed, the playerid is nil, the InstanceID: ", self:GetServerInstanceId())
        return false
    end
    return true    
end

function GamePlayer:BindUEActor(pUEActor)
    GamePlayer.super.BindUEActor(self, pUEActor)
    if self:IsHuman() then
        pUEActor:SetPlayerId(self.nPlayerId)
    end     
end

function GamePlayer:BindReplicatedUEActor(pUEActor, tbCreateData, tbCustomData)
    log("GamePlayer:BindReplicatedUEActor", EngineExtActorShell.GetActorNetGuid(pUEActor))

    self:UnbindUEActor()

    if(tbCreateData ~= nil) then
        if(not self:ParseCreateData(tbCreateData)) then
            logerror("GameObject:RestoreUEActor parse create data failed, ", self:GetServerInstanceId())
            return false
        end
    end

    self.tbCustomData = tbCustomData
    self:BindUEActor(pUEActor)   

    return true
end

function GamePlayer:GetPlayerId()
    return self.nPlayerId
end

function GamePlayer:GetDebugInfo()
    local tbRet = GamePlayer.super.GetDebugInfo(self)
    tbRet.nPlayerId = self.nPlayerId
    return tbRet
end

function GamePlayer:OnActorCreated(pUEActor)
    GamePlayer.super.OnActorCreated(self, pUEActor)
    if(GlobalVariableSystem.bIsInDungeon) then
        CommonShell.GetCommon(GWorld):GetGridTypeManager():AddActor(pUEActor)
    end
end
return GamePlayer
