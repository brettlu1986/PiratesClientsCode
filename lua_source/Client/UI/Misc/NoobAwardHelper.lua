-----------------------------------------------------
--File Name    : NoobAwardHelper.lua
--Author       : Edward J
--Create Time  : 2020-06-19
--Description  : 
-----------------------------------------------------
local Proto             = require("ClientProtoNames")
local NetworkManager    = dynamic_require("NetworkManager")
local NoobAwardHelper = {}

local UISetUtils            = require("UISetUtils")
local UIUtils               = require("UIUtils")
local EventManager          = require("EventManager")
local ClientEventDef        = require("ClientEventDef")
-----------------------------------------------------
local EVENT_AWARD_STATE = {
    [Proto.NoobAwardType.SURVEY] = ClientEventDef.EV_NOOB_SURVEY_AWARD_STATE,
    [Proto.NoobAwardType.NOOB_SHIP] = ClientEventDef.EV_NOOB_GUIDE_AWARD_STATE,
}

local EVENT_AWARD = {
    [Proto.NoobAwardType.SURVEY] = ClientEventDef.EV_NOOB_SURVEY_AWARD,
    [Proto.NoobAwardType.NOOB_SHIP] = ClientEventDef.EV_NOOB_GUIDE_AWARD,
}
-----------------------------------------------------

function NoobAwardHelper.GetNoobAwardState(eAwardType)
    local Socket = NetworkManager:GetHubServerProxy()
    local c2s_GetAward = {}
    c2s_GetAward.award_type = eAwardType
	Socket:SendPacket(Proto.c2s_GetNoobAwardState, c2s_GetAward)
end

function NoobAwardHelper.GetNoobAward(eAwardType)
    local Socket = NetworkManager:GetHubServerProxy()
	local c2s_GetAward = {}
    c2s_GetAward.award_type = eAwardType
	Socket:SendPacket(Proto.c2s_ReceiveNoobAward, c2s_GetAward)
end

function NoobAwardHelper.OnRecieveAwardState(eAwardType, bGet)
    bGet = bGet == nil and false or bGet
    EventManager:OnFireEvent(EVENT_AWARD_STATE[eAwardType], eAwardType, bGet)
end

function NoobAwardHelper.OnRecieveNoobAward(eAwardType, rc)
    if rc == Proto.ReturnCode.NOOB_AWARD_RECEIVED then
        local szTostKey = eAwardType == Proto.NoobAwardType.SURVEY and "SURVEY_ALREADY_GET_AWARD" or "NOOB_GUIDE_AWRAD_ALREADY_GET"
        UIUtils.ShowToast(UISetUtils.GetL10NTextByKey(szTostKey), 0.2)
        return
    end
    EventManager:OnFireEvent(EVENT_AWARD[eAwardType])
end

return NoobAwardHelper