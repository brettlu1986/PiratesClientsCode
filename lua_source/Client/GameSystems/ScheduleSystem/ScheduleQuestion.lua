-- [[
--调查问卷
-- ]]


local luaclass = require("luaclass")
local ScheduleBase = require("ScheduleBase")
local ScheduleQuestion = luaclass("ScheduleQuestion", ScheduleBase)
local EventManager = require("EventManager")
local Proto = require("ClientProtoNames")
local ClientEventDef = require("ClientEventDef")
local UIManager = require("UIManager")
local UIDef = require("UIDef")
local ScheduleTable = require("ScheduleTable")
local ScheduleTypeDef = require("ScheduleTypeDef")

ScheduleQuestion.nRewardId = nil 
ScheduleQuestion.nRewardState = nil

function ScheduleQuestion:Init(Owner, tbTemp, szName)
    local bResult = ScheduleQuestion.super.Init(self, Owner, tbTemp, szName)
    self.nRewardId = self.tbTemplate.tbScheduleData.nRewardId
    return bResult
end

function ScheduleQuestion:Uninit()
    ScheduleQuestion.super.Uninit(self)
end

function ScheduleQuestion:Activate()
    self:RequestGetQuestionActivityInfo()
    ScheduleQuestion.super.Activate(self)
end

function ScheduleQuestion:Deactivate()
    UIManager:CloseWnd(UIDef.UI_LOBBY_SCHEDULE_QUESTION)
    ScheduleQuestion.super.Deactivate(self)
end

function ScheduleQuestion:RequestGetQuestionActivityInfo()
    self.Owner:SendPacket(Proto.c2s_GetQuestionActivityInfo)
end

function ScheduleQuestion:RequestGetQuestionReward()
    self.Owner:SendPacket(Proto.c2s_GetQuestionReward)
end

function ScheduleQuestion:RecvGetQuestionReward(tbPacket)
    if tbPacket.return_code == Proto.ReturnCode.OK then 
        self.nRewardState = tbPacket.reward_state
        EventManager:OnFireEvent(ClientEventDef.EV_QUESTION_REFRESH)
    else 
        log("[Question] get question reward error code:", tbPacket.return_code )
    end
end

function ScheduleQuestion:RecvGetQuestionActivityInfo(tbPacket)
    if tbPacket.return_code ~= Proto.ReturnCode.OK then
        log("ScheduleSeaAdventure:RecvGetRollActivityInfo ", tbPacket.return_code)
        EventManager:OnFireEvent(ClientEventDef.EV_ON_NEXT_POP)
        self:Deactivate()
        return
    end

    local ScheduleTemp = ScheduleTable:GetTemplateByType(ScheduleTypeDef.QUESTION)
    self:SetData({nId = ScheduleTemp.nId})

    self.nRewardState = tbPacket.reward_state

    EventManager:OnFireEvent(ClientEventDef.EV_ON_NEXT_POP)
    EventManager:OnFireEvent(ClientEventDef.EV_QUESTION_REFRESH)
end

function ScheduleQuestion:IsOpen()
    return self.nRewardState == nil or self.nRewardState == Proto.RewardState.RECEIVE
end

function ScheduleQuestion:GetRewardState()
    return self.nRewardState
end

function ScheduleQuestion:CanPush()
    return true
end

function ScheduleQuestion:NextDayProcess()
    if self:IsOpen() then
        self:RequestGetQuestionActivityInfo()
    end
end

function ScheduleQuestion:ProcessQuestion() 
    if self.Owner.bInLobby and self.Owner.bReconnected == nil then
        if self:IsOpen() then
            UIManager:OpenWnd(UIDef.UI_LOBBY_SCHEDULE_QUESTION)
            return true
        end
    end
    return false
end

function ScheduleQuestion:OnItemUpdate(nItemTemplateId, bAdd)
end

function ScheduleQuestion:HasTip()
    return self.nRewardState ~= nil and self.nRewardState == Proto.RewardState.RECEIVE
end

return ScheduleQuestion