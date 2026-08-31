
local PlayerStateDef = {}

local nIndex = 1

local function Define(szStateName)
    PlayerStateDef[szStateName] = nIndex
    nIndex = nIndex + 1
end

function PlayerStateDef.Init()
    -- normal
    Define("PS_NORMAL")

    -- fishing
    Define("PS_FISHING_STAND")
    Define("PS_FISHING_WAIT")
    -- Define("PS_FISHING_SUCESS")
    -- Define("PS_FISHING_FAIL")
    -- Define("PS_FISHING_LEAVE")
end

PlayerStateDef.Init()

return PlayerStateDef
