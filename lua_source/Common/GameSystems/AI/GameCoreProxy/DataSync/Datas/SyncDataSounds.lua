local luaclass = require("luaclass")
local SyncDataBase = require("SyncDataBase")
local SyncDataSounds = luaclass("SyncDataSounds", SyncDataBase)
local GameCoreAgentLuaPoolManager = require("GameCoreAgentLuaPoolManager")

SyncDataSounds.tbSounds = nil

function SyncDataSounds:OnSync(tbPack)
    local pAIController = self.pAIController
    local tbSounds = self.tbSounds
    local nNumSound = pAIController:UpdateSoundEnv()
    for i = nNumSound + 1, #tbSounds do
        tbSounds[i] = nil
    end
    local LuaPool = GameCoreAgentLuaPoolManager:Get(self.tbOwner:GetServerInstanceId(), "Sound")
    for i=1,nNumSound do
        local nType, nX, nY, nZ = pAIController:GetHeardSound(i)
        local tbSound = tbSounds[i] or LuaPool:Get()
        tbSound.location = tbSound.location or {}
        tbSound.location.x = nX
        tbSound.location.y = nY
        tbSound.location.z = nZ
        tbSound.type = nType
        tbSounds[i] = tbSound
    end
    tbPack.heard_sounds = self.tbSounds
end


function SyncDataSounds:OnStart()
    self.tbSounds = {}
end


function SyncDataSounds:OnStop()

end

return SyncDataSounds