local luaclass = require("luaclass")
local SyncDataBase = require("SyncDataBase")
local SyncDataVisibleTorpedo = luaclass("SyncDataVisibleTorpedo", SyncDataBase)
local GameCoreAgentLuaPoolManager = require("GameCoreAgentLuaPoolManager")

SyncDataVisibleTorpedo.tbVisibleTorpedo = nil

local nMaxVisiblenTorpedo = 5

function SyncDataVisibleTorpedo:OnSync(tbPack)
    local pAIController = self.pAIController
    local tbOwner = self.tbOwner
    if tbOwner:IsShip() then
        local tbVisibleTorpedo = self.tbVisibleTorpedo
        local nNumTorpedo = pAIController:GetVisibleTorpedoNum()
        if nNumTorpedo > 0 then
            local nNumSyncTorpedo = 1
            local nSelfTeamId = tbOwner.SAIEntityComponent:GetTeamId()
            local nLuaPoolId = tbOwner:GetServerInstanceId()
            local LuaPool = GameCoreAgentLuaPoolManager:Get(nLuaPoolId, "VisibleTorpedo")
            for i=1,nNumTorpedo do
                local nTorpedoUniqueId, nRadius, nX, nY, nZ, nTeamId, nBoomTime = pAIController:GetVisibleTorpedo(i)
                if nTorpedoUniqueId > 0 and nNumSyncTorpedo <= nMaxVisiblenTorpedo then
                    local tbState = LuaPool:Get()
                    tbState.id = nTorpedoUniqueId
                    tbState.is_enemy = (nSelfTeamId ~= nTeamId)
                    tbState.radius = nRadius
                    tbState.x = nX
                    tbState.y = nY
                    tbState.z = nZ
                    tbState.boom_time = nBoomTime
                    tbVisibleTorpedo[nNumSyncTorpedo] = tbState
                    nNumSyncTorpedo = nNumSyncTorpedo + 1
                end
            end
            for i=nNumSyncTorpedo, #tbVisibleTorpedo do
                tbVisibleTorpedo[i] = nil
            end
            tbPack.visible_torpedos = tbVisibleTorpedo
        else
            tbPack.visible_torpedos = nil
        end
    else
        tbPack.visible_torpedos = nil
    end
end


function SyncDataVisibleTorpedo:OnStart()
    self.tbVisibleTorpedo = {}
end


function SyncDataVisibleTorpedo:OnStop()

end

return SyncDataVisibleTorpedo