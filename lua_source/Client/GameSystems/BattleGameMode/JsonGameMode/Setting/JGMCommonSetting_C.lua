local luaclass = require("luaclass")
local JGMCommonSetting = require("JGMCommonSetting")
local JGMCommonSetting_C = luaclass("JGMCommonSetting_C", JGMCommonSetting)

-- local Proto = require("ClientProtoNames")
-- local NetworkManager = dynamic_require("NetworkManager")


-- local function SendPacket(szProto, tbPacket)
--     local Socket = NetworkManager:GetHubServerProxy()
--     return Socket:SendPacket(szProto, tbPacket)
-- end

-- function JGMCommonSetting_C:OnAllStepFinished()
--     SendPacket(Proto.c2s_LeaveLocalDungeon)
-- end


return JGMCommonSetting_C