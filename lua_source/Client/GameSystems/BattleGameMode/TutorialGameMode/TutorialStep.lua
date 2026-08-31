local Proto = require("ClientProtoNames")
local NetworkManager = dynamic_require("NetworkManager")

local function SendPacket(szProto, tbPacket)
    local Socket = NetworkManager:GetHubServerProxy()
    return Socket:SendPacket(szProto, tbPacket)
end

local M = {}

M.STEP_PLAYER_SPAWN_1 = 1
M.STEP_ENTER_TRIGGER_2 = 2
M.STEP_ENEMY_SHIP_DIE_3 = 3
M.STEP_QTE_4 = 4
M.STEP_OCTOPUS_5 = 5

M.STEP_IS_SKIP = false

function M:SendDungeonCompleteStep(nStepId, nCompleteSecond)
    local c2s_NewPlayerStep = 
    {
        step_id = nStepId,
        complete_second = nCompleteSecond,
    }
    SendPacket(Proto.c2s_NewPlayerStep, c2s_NewPlayerStep)
end

return M