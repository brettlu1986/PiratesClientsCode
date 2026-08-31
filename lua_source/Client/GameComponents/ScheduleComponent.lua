local luaclass = require("luaclass")
local GameComponentBase = require("GameComponentBase")
local ScheduleComponent = luaclass("ScheduleComponent", GameComponentBase)
----------------------------------------------------------------------------------
ScheduleComponent.tbNoobLogin = nil --新手登录活动
ScheduleComponent.nBattleStarCloseTime = nil

ScheduleComponent.tbSevenDayCheckIn = nil  -- 七日登陆  {check_in_count, can_award} 

ScheduleComponent.tbFixedTimeAwards = nil  -- 定时登录

ScheduleComponent.tbContinuous = nil -- 连续登录

local NOOBLOGINSTATE = {
    UNREACH = -1,
    UNGET = 0,
    GETED = 1
}


function ScheduleComponent:OnCreate(Owner, tbParams)
    ScheduleComponent.super.OnCreate(self, Owner, tbParams)
end

function ScheduleComponent:OnDestroy()
    ScheduleComponent.super.OnDestroy(self)
end

function ScheduleComponent:SetNoobLogin(tbData)
    self.tbNoobLogin = tbData
end

function ScheduleComponent:SetGetNoobLoginAward(nDay)
    if self.tbNoobLogin == nil then
        logwarning("ScheduleComponent:SetGetNoobLoginAward is over", nDay)
        return
    end
    for i, v in ipairs(self.tbNoobLogin) do
        if v.nDay == nDay then
            v.nState = NOOBLOGINSTATE.GETED
            return
        end
    end
end

function ScheduleComponent:GetNoobLogin()
    return self.tbNoobLogin
end

function ScheduleComponent:HasNoobLoginAward() 
    if self.tbNoobLogin then
        for i, v in ipairs(self.tbNoobLogin) do
            if v.nState == NOOBLOGINSTATE.UNGET then
                return true
            end
        end        
    end
    return false
end

function ScheduleComponent:SetBattleStarCloseTime(nTime)
    self.nBattleStarCloseTime = nTime
end

function ScheduleComponent:GetBattleStarCloseTime()
    return self.nBattleStarCloseTime
end

function ScheduleComponent:SetSevenDayCheckIn(tbData)
    self.tbSevenDayCheckIn = tbData
end

function ScheduleComponent:SetSevenDayCheckInCanAward()
    if self.tbSevenDayCheckIn then
        self.tbSevenDayCheckIn.can_award = true
    end
end

function ScheduleComponent:GetSevenDayCheckIn() 
    return self.tbSevenDayCheckIn
end

function ScheduleComponent:SetFixedTimeAwardInfo(tbTimedAwards)
    self.tbFixedTimeAwards = tbTimedAwards
end

function ScheduleComponent:SetFixedTimeAwardState(nId, nState)
    if self.tbFixedTimeAwards == nil then
        logerror("SetGetFixedTimeAward but fixed time award is nil")
        return
    end
    for i, v in ipairs(self.tbFixedTimeAwards) do
        if v.template_id == nId then
            v.award_flag = nState
        end
    end
end

function ScheduleComponent:GetFixedTimeAwardInfo(nId)
    if self.tbFixedTimeAwards ~= nil then
        for i, v in ipairs(self.tbFixedTimeAwards) do
            if v.template_id == nId then
                return v.award_flag
            end
        end
    end
end

function ScheduleComponent:SetContinuous(nDay, tbStates)
    if tbStates ~= nil then
        self.tbContinuous = {}
        self.tbContinuous.nDay = nDay
        self.tbContinuous.tbState = tbStates
    else
        self.tbContinuous = nil
    end
end

function ScheduleComponent:GetContinuous()
    return self.tbContinuous
end

function ScheduleComponent:HasContinuousAward()
    if self.tbContinuous ~= nil then
        for i = 1, self.tbContinuous.nDay do
            if self.tbContinuous.tbState[i].nState == 0 then
                return true
            end
        end
    end
    return false
end

return ScheduleComponent