-----------------------------------------------------
--File Name    : SurveyAwardPacketProcessor.lua
--Author       : Edward J
--Create Time  : 2020-02-17
--Description  : paket process of survery award
-----------------------------------------------------
local luaclass                          = require("luaclass")
local NetMessageProcessorBase           = require("NetMessageProcessorBase")
local SurveyAwardPacketProcessor        = luaclass("SurveyAwardPacketProcessor", NetMessageProcessorBase)

local Proto                = require("ClientProtoNames")
local NetworkManager       = dynamic_require("NetworkManager")
local SurveyHelper         = require("SurveyHelper")
local UIUtils              = require("UIUtils")
local UISetUtils           = require("UISetUtils")
local EventManager         = require("EventManager")
local ClientEventDef       = require("ClientEventDef")
-----------------------------------------------------

local function OnGetSurvey(self, tbPacket, nSenderUniqueId)
    local bStatus = tbPacket.received_award
    SurveyHelper.SetFinishStatus(bStatus)
end

local function OnGetSurveyAward(self, tbPacket, nSenderUniqueId)
    local return_code = tbPacket.return_code
    if return_code == Proto.ReturnCode.NOOB_SURVEY_RECEIVED_AWARD then
        UIUtils.ShowToast(UISetUtils.GetL10NTextByKey("SURVEY_ALREADY_GET_AWARD"), 0.2)
    end
    SurveyHelper.SetFinishStatus(true)
    EventManager:OnFireEvent(ClientEventDef.EV_GV_ON_CLICK_SURVEY)
end

function SurveyAwardPacketProcessor:Init()
    SurveyAwardPacketProcessor.super.Init(self)
    self:SetBinder(NetworkManager:GetHubServerProxy())
    self:RegisterPackets()
    return true
end

function SurveyAwardPacketProcessor:Uninit()
    SurveyAwardPacketProcessor.super.Uninit(self)
end

function SurveyAwardPacketProcessor:RegisterPackets()
    self:BindMethod(Proto.s2c_GetSurvey, self, OnGetSurvey)
    self:BindMethod(Proto.s2c_GetSurveyAward, self, OnGetSurveyAward)
end

return SurveyAwardPacketProcessor()