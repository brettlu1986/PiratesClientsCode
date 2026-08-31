local MatchmakingSystem = {}

local NetworkManager = dynamic_require("NetworkManager")
local Proto = require("ClientProtoNames")

local DEFAULT_MATCHMAKING_MODE = 4
local DEFAULT_SELECT_DUNGEON = 100011
local DEFAULT_AUTO_MATCHMAKING = true
local TRAINING_DUNGEON_ID = 110001
local DEFAULT_ROOM = ""

MatchmakingSystem.bMatchmaking = nil
MatchmakingSystem.nSelectDungeon = DEFAULT_SELECT_DUNGEON
MatchmakingSystem.nMatchmakingMode = DEFAULT_MATCHMAKING_MODE
MatchmakingSystem.bAutoMatchmaking = DEFAULT_AUTO_MATCHMAKING
MatchmakingSystem.szRoom = DEFAULT_ROOM

function MatchmakingSystem:Init()
    self.bMatchmaking = nil
    return true
end

function MatchmakingSystem:Uninit()

end

function MatchmakingSystem:OnStartMatchmaking(bSuccess)
    self.bMatchmaking = bSuccess
end

function MatchmakingSystem:OnCancelMatchmaking(bSuccess)
    if bSuccess then
        self.bMatchmaking = false
    end
end

function MatchmakingSystem:StartMatchmaking()
    local nMatchmakingMode, bAutoMatchmaking = nil
    if self:IsTrainingMode() then
        nMatchmakingMode = 4
        bAutoMatchmaking = false
    else
        nMatchmakingMode = self.nMatchmakingMode
        bAutoMatchmaking = self.bAutoMatchmaking
    end
    local c2s_StartMatchmaking =
    {
        dungeon_id = self.nSelectDungeon,
        team_mode = nMatchmakingMode,
        auto_team_formation = bAutoMatchmaking,
        room = self.szRoom
    }
    local Socket = NetworkManager:GetHubServerProxy()
    return Socket:SendPacket(Proto.c2s_StartMatchmaking, c2s_StartMatchmaking)
end

function MatchmakingSystem:CancelMatchMaking()
    local Socket = NetworkManager:GetHubServerProxy()
    return Socket:SendPacket(Proto.c2s_CancelMatchmaking)
end

function MatchmakingSystem:RequestOpenTime(nDungeonId, nTeamModeId)
    local c2s_MatchmakingOpenTime =
    {
        mode = {
            dungeon_template_id = nDungeonId,
            team_mode = nTeamModeId,
        }
    }
    local Socket = NetworkManager:GetHubServerProxy()
    return Socket:SendPacket(Proto.c2s_MatchmakingOpenTime, c2s_MatchmakingOpenTime)
end

function MatchmakingSystem:IsMatchmaking()
    return self.bMatchmaking
end

function MatchmakingSystem:SetAutoMatchmaking(bAutoMatchmaking)
    log("MatchmakingSystem:SetAutoMatchmaking",bAutoMatchmaking)
    self.bAutoMatchmaking = bAutoMatchmaking
end

function MatchmakingSystem:IsAutoMatchmaking()
    return self.bAutoMatchmaking
end

function MatchmakingSystem:SetSelectDungeon(nSelectDungeon)
    log("MatchmakingSystem:SetSelectDungeon",nSelectDungeon)
    self.nSelectDungeon = nSelectDungeon
end

function MatchmakingSystem:GetSelectDungeon()
    return self.nSelectDungeon
end

function MatchmakingSystem:SetMatchmakingMode(nMatchmakingMode)
    log("MatchmakingSystem:SetMatchmakingMode",nMatchmakingMode)
    self.nMatchmakingMode = nMatchmakingMode
end

function MatchmakingSystem:GetMatchmakingMode()
    return self.nMatchmakingMode
end

function MatchmakingSystem:SetMatchmakingRoom(szRoom)
    self.szRoom = szRoom
end

function MatchmakingSystem:IsTrainingMode()
    return self.nSelectDungeon == TRAINING_DUNGEON_ID
end

return MatchmakingSystem
