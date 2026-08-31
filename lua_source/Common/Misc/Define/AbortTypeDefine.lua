local AbortTypeDefine = {}

local nTempAbortId = 1

local function Define(szName)
    AbortTypeDefine[szName] = nTempAbortId
    nTempAbortId = nTempAbortId + 1
end

Define("CANCEL")
Define("HUMAN_DISPLACEMENT")
Define("HUMAN_INJURED")
Define("SHIP_INJURED")
Define("HUMAN_MOVE")
Define("SHIP_MOVE")
Define("SHIP_POSTURE_CHANGE")
Define("SHIP_ROTATE")
Define("HUMAN_WEAPON_STATE_CHANGE")
Define("HUMAN_WEAPON_SLOT_CHANGE")
Define("SHIP_WEAPON_SWITCH")
Define("HUMAN_FIRE")
Define("SHIP_FIRE")
Define("HUMAN_PICK_UP")
Define("SHIP_PICK_UP")
Define("HUMAN_JUMP")
Define("HUMAN_CROUCH")
Define("HUMAN_CRAWL")
Define("HUMAN_SWIM")
Define("SHIP_AIM")
Define("SERIOUS_INJURY")
Define("SHIP_BULLET_LOAD")
Define("PLAYER_DEAD")
Define("PLAYER_BURN")
Define("PLAYER_DYING")
Define("HUMAN_PROGRESS_BAR")
Define("DOOR_SWITCHED")

return AbortTypeDefine
