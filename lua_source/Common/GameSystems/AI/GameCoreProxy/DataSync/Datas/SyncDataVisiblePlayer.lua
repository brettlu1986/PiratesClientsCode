local luaclass = require("luaclass")
local SyncDataBase = require("SyncDataBase")
local SyncDataVisiblePlayer = luaclass("SyncDataVisiblePlayer", SyncDataBase)
local GameObjectSystem = dynamic_require("GameObjectSystem")
local SyncDataUtils = require("SyncDataUtils")
local GameObjectTypeDef = require("GameObjectTypeDef")
local GameCoreAgentLuaPoolManager = require("GameCoreAgentLuaPoolManager")

SyncDataVisiblePlayer.tbVisiblePlayers = nil
SyncDataVisiblePlayer.nFocusPlayerInstanceId = 0

local nMaxVisiblePlayer = 5

local function Distance(nFromX, nFromY, nToX, nToY)
    local nX2 = nFromX - nToX
    nX2 = nX2 * nX2
    local nY2 = nFromY - nToY
    nY2 = nY2 * nY2
    return nX2 + nY2
end

function SyncDataVisiblePlayer:OnSync(tbPack)
    local pAIController = self.pAIController
    if not pAIController then
        tbPack.visible_players = nil
        return
    end
    local tbVisiblePlayers = self.tbVisiblePlayers
    local nNumPlayer = pAIController:UpdateSightEnv()
    if nNumPlayer > 0 then
        local tbOwner = self.tbOwner
        local nX, nY, _ = tbOwner:GetLocationXYZ()
        local nMinDistance = -1
        local nFocusPlayerInstanceId = 0
        local nLuaPoolId = tbOwner:GetServerInstanceId()
        local LuaPool = GameCoreAgentLuaPoolManager:Get(nLuaPoolId, "VisiblePlayer")
        local nNumSyncPlayer = 1
        for i=1,nNumPlayer do
            local nGameObjectUniqueId = pAIController:GetSeenActorId(i)
            if nGameObjectUniqueId > 0 and nNumSyncPlayer <= nMaxVisiblePlayer then
                local tbGameObject = GameObjectSystem:FindByUniqueId(nGameObjectUniqueId)
                if tbGameObject:GetObjectType() == GameObjectTypeDef.PlayerSelf or tbGameObject:GetObjectType() == GameObjectTypeDef.Npc then
                    --LOG("visible human ", tbGameObject.szName)
                    -- 内存持续增加 考虑使用LuaPool
                    local tbState = LuaPool:Get()
                    local nGameObjectId = tbGameObject:GetServerInstanceId()
                    tbState.state = tbState.state or {}
                    local bFocus = self.nFocusPlayerInstanceId == nGameObjectId
                    SyncDataUtils:FillPlayerState(tbGameObject, tbState.state, self.tbOwner.nServerInstanceId, false, bFocus)
                    tbVisiblePlayers[nNumSyncPlayer] = tbState
                    nNumSyncPlayer = nNumSyncPlayer + 1
                    local nDist = Distance(nX, nY, tbState.state.position.x, tbState.state.position.y)
                    if nMinDistance < 0 or nDist < nMinDistance then
                        nMinDistance = nDist
                        nFocusPlayerInstanceId = nGameObjectId
                    end
                end
            end
        end
        for i=nNumSyncPlayer, #tbVisiblePlayers do
            tbVisiblePlayers[i] = nil
        end
        tbPack.visible_players = self.tbVisiblePlayers
        self.nFocusPlayerInstanceId = nFocusPlayerInstanceId
    else
        tbPack.visible_players = nil
        self.nFocusPlayerInstanceId = 0
    end
end


function SyncDataVisiblePlayer:OnStart()
    self.tbVisiblePlayers = {}
end


function SyncDataVisiblePlayer:OnStop()

end

return SyncDataVisiblePlayer