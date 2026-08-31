local luaclass = require("luaclass")
local SyncDataBase = require("SyncDataBase")
local SyncDataSmokes = luaclass("SyncDataSmokes", SyncDataBase)
local GameCoreAgentLuaPoolManager = require("GameCoreAgentLuaPoolManager")

SyncDataSmokes.tbVisibleSmokes = nil
SyncDataSmokes.tbFogData = nil

-- luacheck: push ignore
local function LOG(...)
    log("CJ->SyncDataSmokes:", ...)
end

-- luacheck: pop

function SyncDataSmokes:OnSync(tbPack)
    local pSmokeDetectComponent = self.pAIController.SmokeDetectComponent
    pSmokeDetectComponent:SyncSmoke()
    local nNumSmoke = pSmokeDetectComponent:GetNumSmoke()
    if nNumSmoke > 0 then
        local tbOwner = self.tbOwner
        local tbVisibleSmokes = self.tbVisibleSmokes
        local nNumSyncnNumSmoke = 1
        local tbFogData = self.tbFogData
        local nLuaPoolId = tbOwner:GetServerInstanceId()
        local LuaPool = GameCoreAgentLuaPoolManager:Get(nLuaPoolId, "Smoke")
        for i=1,nNumSmoke do
            local nX, nY, nZ, nRadius, nRemainTime = pSmokeDetectComponent:GetSmoke(i)
            if nRemainTime > 0 then
                local tbState = LuaPool:Get()
                tbState.radius = nRadius
                tbState.x = nX
                tbState.y = nY
                tbState.z = nZ
                tbState.remain_time = nRemainTime
                tbVisibleSmokes[nNumSyncnNumSmoke] = tbState
                nNumSyncnNumSmoke = nNumSyncnNumSmoke + 1
            end
        end
        if tbFogData.trigger then
            local tbFogState = LuaPool:Get()
            tbFogState.radius = tbFogData.radius
            tbFogState.x = tbFogData.x
            tbFogState.y = tbFogData.y
            tbFogState.z = tbFogData.z
            tbFogState.remain_time = 100000
            tbVisibleSmokes[nNumSyncnNumSmoke] = tbFogState
            nNumSyncnNumSmoke = nNumSyncnNumSmoke + 1
        end
        for i=nNumSyncnNumSmoke, #tbVisibleSmokes do
            tbVisibleSmokes[i] = nil
        end
        tbPack.smokes = tbVisibleSmokes
    else
        tbPack.smokes = nil
    end
end


function SyncDataSmokes:OnStart()
    self.tbVisibleSmokes = {}
    self.tbFogData = require("GameCoreProxyClient").tbFogData
end


function SyncDataSmokes:OnStop()

end

return SyncDataSmokes