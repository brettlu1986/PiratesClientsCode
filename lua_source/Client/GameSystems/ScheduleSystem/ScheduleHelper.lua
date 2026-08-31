local NoobLoginDataTable = require("NoobLoginDataTable")
local GlobalVariableSystem_C = require("GlobalVariableSystem_C")
local SaveGameDef = require("SaveGameDef")
local StringUtil = require("StringUtil")
local ScheduleIni = require("ScheduleIni")
local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
local UIManager = require("UIManager")
local UIDef = require("UIDef")
local EventManager = require("EventManager")
local ClientEventDef = require("ClientEventDef")
local TimeUtil = require("TimeUtil")
local ContinuousDataTable = require("ContinuousDataTable")
local TimedAwardDataTable = require("TimedAwardDataTable")
local Proto = require("ClientProtoNames")
local SeasonSystem = require("SeasonSystem")

local ScheduleHelper = {}
local NOOB_LOGIN_AWARD_MODE = {
    LOGIN_COUNT = 1,
    LOGIN_DAY   = 2,
}
local ONE_DAY = 60 * 60 * 24


function ScheduleHelper:ParseNoobLoginData(nState)
    -- 由低位到高位依次代表第n天的领奖状态,0:未领奖 1:已领奖
    -- 最高位固定为1，最小为两位
    if nState == 0 or nState <= 1 then
        logwarning("ParseNoobLoginData failed: state is error ", nState)
        return
    end 
    local nMaxCount = NoobLoginDataTable:GetCount()
    if nMaxCount > 31 then
        logwarning("ParseNoobLoginData failed: over max count ", nMaxCount)
        return
    end
    local tbData = {}

    -- 确定位数
    local nMaxBit = 0
    for i = nMaxCount, 1, -1 do
        if (nState >> i) & 1 > 0 then
            nMaxBit = i
            break
        end
    end
    for i = nMaxBit, 1, -1 do
        table.insert(tbData, {nDay = i, nState = (nState >> i - 1) & 1})
    end

    local bOver = #tbData == nMaxCount

    local tbRet = {}
    for i = #tbData, 1, -1 do
        table.insert(tbRet, tbData[i])
        if bOver and tbData[i].nState < 1 then
            bOver = false
        end
    end

    if not bOver then
        return tbRet
    end
end

function ScheduleHelper:ParseContinuousData(nDay, nState)
    -- 由低位到高位依次代表第n天的领奖状态,0:未领奖 1:已领奖
    local nMaxCount = ContinuousDataTable:GetCount()
    if nMaxCount > 32 then
        logwarning("ParseContinuousData failed: over max count ", nMaxCount)
        return
    end
    local bOver = nDay == nMaxCount

    local tbData = {}
    for i = nMaxCount, 1, -1 do
        local tbState = {nDay = i, nState = (nState >> i - 1) & 1}
        table.insert(tbData, tbState)
        if tbState.nState == 0 then
            bOver = false
        end
    end
    local tbRet = {}
    for i = nMaxCount, 1, -1 do
        table.insert(tbRet, tbData[i])
    end

    if not bOver then
        return tbRet
    end
end

-- 当玩家当天完成x次比赛，返回大厅时弹出登录大狂欢下一天奖励预览图
function ScheduleHelper:GetAndSetTodayBattleCount(nCount)
    local nCurTime = GlobalVariableSystem_C:GetServerTimeUtc()
    
    local pSaveGameMgr = ClientShell.GetClient(GWorld):GetSaveGameManager()
    
    local szValue = pSaveGameMgr:GetStringDataWithDefault(SaveGameDef.TODAY_BATTLE_COUNT, "")
    local tbValue = StringUtil.Split(szValue, ",")
    local nBattleTime = #tbValue == 2 and tonumber(tbValue[1]) or nCurTime
    local nBattleCount = #tbValue == 2 and tonumber(tbValue[2]) or 0

    local tbCurDayDate = os.date("*t", nCurTime)    
    local tbBattleDayDate = os.date("*t", nBattleTime)    

    local szCurValue = ""
    if tbCurDayDate.yday == tbBattleDayDate.yday then
        nBattleCount = nBattleCount + nCount
    else
        nBattleCount = nCount
    end
    log("ScheduleHelper:GetAndSetTodayBattleCount ", tbCurDayDate.yday, tbBattleDayDate.yday, nCount)
    
    szCurValue = string.format("%s,%s", nCurTime, nBattleCount)
    pSaveGameMgr:AddStringData(SaveGameDef.TODAY_BATTLE_COUNT, szCurValue)
    pSaveGameMgr:Save()

    log("ScheduleHelper:GetAndSetTodayBattleCount ", nBattleCount)
    return nBattleCount
end

-- 战斗完后，判断是否显示登录大狂欢下一天奖励预览图
function ScheduleHelper:VerifyShowNextNoobLoginAward(Component, nBattleCount)
    if ScheduleIni.tbNoobLogin.nAwardMode ~= NOOB_LOGIN_AWARD_MODE.LOGIN_DAY then
        return
    end
    local tbPlayerSelf = GamePlayerSelfHelper:Get()
    if tbPlayerSelf == nil then
        return
    end

    local tbNoobData = Component:GetNoobLogin()
    if tbNoobData == nil or  #tbNoobData >= NoobLoginDataTable:GetCount() then
        return 
    end

    local tbNoobLoginTemp = NoobLoginDataTable:GetTemplate(#tbNoobData)
    if tbNoobLoginTemp == nil then
        return
    end

    local bShowUI = false
    -- 当玩家当天完成x次比赛，返回大厅时弹下一天奖励预览图
    local nCurTime = GlobalVariableSystem_C:GetServerTimeUtc()
    log("VerifyShowNextNoobLoginAward battle count ", nBattleCount)
    for i, v in ipairs(tbNoobLoginTemp.tbGameCount) do
        if nBattleCount == v then
            bShowUI = true
            break
        end
    end
    if bShowUI then
        local pSaveGameMgr = ClientShell.GetClient(GWorld):GetSaveGameManager()
        local szValue = pSaveGameMgr:GetStringDataWithDefault(SaveGameDef.NEXT_NOOB_LOGIN, "")
        local tbValue = StringUtil.Split(szValue, ",")
        local nShowUITime = #tbValue == 2 and tonumber(tbValue[1]) or nCurTime
        local nShowUICount = #tbValue == 2 and tonumber(tbValue[2]) or 0
    
        log("VerifyShowNextNoobLoginAward check count time ", nShowUITime, nShowUICount, nCurTime)
        bShowUI = nCurTime - nShowUITime > ONE_DAY or nShowUICount < #tbNoobLoginTemp.tbGameCount
        if bShowUI then
            pSaveGameMgr:AddStringData(SaveGameDef.NEXT_NOOB_LOGIN, string.format("%d,%d", nCurTime, nShowUICount + 1))
            pSaveGameMgr:Save()
        end
    end

    log("VerifyShowNextNoobLoginAward bshow=", bShowUI)
    if bShowUI then        
        if #tbNoobData == 1 then
            UIManager:OpenWnd(UIDef.UI_SCHEDULE_NOOB_LOGIN_SECOND_DAY, {nDay = #tbNoobData})
        else
            UIManager:OpenWnd(UIDef.UI_SCHEDULE_NOOB_LOGIN_NEXT_DAY, {nDay = #tbNoobData})
        end
    end
end

--==============================--
-- 跨天处理
--==============================-----------------
function ScheduleHelper:NextDayProcessSevenDay(Component)
    local tbData = Component:GetSevenDayCheckIn()
    if tbData then
        local nCount = tbData.check_in_count
        local nCurTime = GlobalVariableSystem_C:GetServerTimeUtc()
        -- [0 - 6 = 星期天 - 星期六]
        local nWeekDay = os.date("%w", nCurTime)
        -- 星期一，签到次数清空
        if nWeekDay == 1 then
            nCount = 0
        end
        log("RefreshNextDayProcessSevenDay ", nCount)
        Component:SetSevenDayCheckIn({can_award = true, check_in_count = nCount})

        EventManager:OnFireEvent(ClientEventDef.EV_ACTIVIEY_SEVENDAY_NEXT_DAY)
    end 
end

function ScheduleHelper:NextDayProcessNoobLogin(Component)
    local tbData = Component:GetNoobLogin()
    if tbData ~= nil then
        log("RefreshNextDayNoobLogin", #tbData)
        if #tbData + 1 <= NoobLoginDataTable:GetCount() then
            local tbTemp = {}
            for i, v in ipairs(tbData) do
                table.insert(tbTemp, v)
            end
            table.insert(tbTemp, {nDay = #tbData + 1, nState = 0})
            Component:SetNoobLogin(tbTemp)
            EventManager:OnFireEvent(ClientEventDef.EV_SCHEDULE_NOOB_LOGIN_REFRESH)
        end
    else
        log("RefreshNextDayNoobLogin over")
    end
end

function ScheduleHelper:NextDayProcessContinous(Component)
    local tbData = Component:GetContinuous()
    if tbData == nil then
        return
    end
    if tbData.nDay < ContinuousDataTable:GetCount() then
        tbData.nDay = tbData.nDay + 1
        EventManager:OnFireEvent(ClientEventDef.EV_SCHEDULE_CONTINUOUS_REFRESH, tbData.nDay)
    end
end

--==============================--
-- 定时处理
--==============================-----------------
function ScheduleHelper:TimerProcessFixed(Component)
    local tbAll = TimedAwardDataTable:GetContainer()

    local nCurTime = GlobalVariableSystem_C:GetServerTimeUtc()
    local nCurHour = tonumber(os.date("%H",nCurTime))
    local nCurMin  = tonumber(os.date("%M",nCurTime))
    local nCurSec  = tonumber(os.date("%S",nCurTime))   
    local nCurHMS  = nCurHour * 3600 + nCurMin * 60 + nCurSec

    local tbAwardState = Proto.s2c_GetTimedAwardInfo_TimedAwardFlag

    local bUpdate = false
    for i, v in ipairs(tbAll) do
        local nStartHMS= v.nStartHour * 3600 + v.nStartMin * 60 + v.nStartSec  
        local nEndHMS  = v.nStopHour * 3600 + v.nStopMin * 60 + v.nStopSec 
        local nState = Component:GetFixedTimeAwardInfo(v.nId)
        if nCurHMS >= nStartHMS and nCurHMS <= nEndHMS then
            if nState == tbAwardState.TIMED_BEFORE then
                log("TimerProcessFixed auto fresh state timed on")
                -- 自动刷新到领取时间
                Component:SetFixedTimeAwardState(v.nId, tbAwardState.TIMED_ON)
                bUpdate = true
            end
        elseif nCurHMS > nEndHMS then
            if nState == tbAwardState.TIMED_ON then
                log("TimerProcessFixed auto fresh state timed out")
                Component:SetFixedTimeAwardState(v.nId, tbAwardState.TIMED_OUT)
                bUpdate = true
            end
        end
    end
    if bUpdate then
        EventManager:OnFireEvent(ClientEventDef.EV_SCHEDULE_FIXED_TIME_AWARD_REFRESH)
    end
end

--==============================--
-- 判断活动是否开启
--==============================-----------------
function ScheduleHelper:IsOpenNoobLogin(Component)
    local tbData = Component:GetNoobLogin()
    return tbData ~= nil
end

function ScheduleHelper:IsOpenBattleStarActivity(Component)
    local nTime = Component:GetBattleStarCloseTime()
    if nTime ~= nil then
        local SeasonComponent = SeasonSystem:GetComponent()
        local nStatus = SeasonComponent:GetNewSeasonStatus()
        return nStatus == Proto.PlayerSeasonStatus.RUNNING
    end
end

function ScheduleHelper:IsOpenContinuous(Component)
    local tbData = Component:GetContinuous()
    return tbData ~= nil
end

--==============================--
-- 判断活动小黄点
--==============================-----------------
function ScheduleHelper:HasTipFixedAward(Component, bSetTip)
    local nTimeOn = Proto.s2c_GetTimedAwardInfo_TimedAwardFlag.TIMED_ON

    local tbAll = TimedAwardDataTable:GetContainer()
    for i, v in ipairs(tbAll) do
        local nState = Component:GetFixedTimeAwardInfo(v.nId)
        if nState == nTimeOn then
            return true
        end
    end
    return false
end

function ScheduleHelper:HasTipSevenDayCheckIn(Component, bSetTip)
    local tbData = Component:GetSevenDayCheckIn()
    if tbData ~= nil then
        return tbData.can_award 
    else
        return false
    end
end

function ScheduleHelper:HasTipNoobLogin(Component, bSetTip)
    local tbData = Component:GetNoobLogin()
    if tbData == nil then
        return false
    else
        return Component:HasNoobLoginAward()
    end
end

function ScheduleHelper:HasTipBattleStarActivity(Component, bSetTip)
    if Component:GetBattleStarCloseTime() == nil then
        return false
    end
    if not ScheduleHelper:IsOpenBattleStarActivity(Component) then
        return
    end
    local pSaveGameMgr = ClientShell.GetClient(GWorld):GetSaveGameManager()
    local nOpenUITime = pSaveGameMgr:GetIntDataWithDefault(SaveGameDef.BATTLE_STAR_SCHEDULE, 0)
    local nCurTime = tonumber(TimeUtil.GetTimeFormatString(GlobalVariableSystem_C:GetServerTimeUtc(), "%Y%m%d"))
    local bRet = nCurTime > nOpenUITime
    if bRet and bSetTip then
        pSaveGameMgr:AddIntData(SaveGameDef.BATTLE_STAR_SCHEDULE, nCurTime)
        pSaveGameMgr:Save()
    end            
    return bRet
end

function ScheduleHelper:HasTipContinuous(Component, bSetTip)
    return Component:HasContinuousAward()
end

function ScheduleHelper:HasTips(Component)
    if Component == nil then
        return false
    else
        return self:HasTipFixedAward(Component) or 
            self:HasTipSevenDayCheckIn(Component) or 
            self:HasTipNoobLogin(Component) or
            self:HasTipBattleStarActivity(Component) or
            self:HasTipContinuous(Component)
    end
end

function ScheduleHelper:HasTipsByLimit(Component)
    if Component == nil then
        return false
    else
        return self:HasTipFixedAward(Component)  
    end
end
-- 

function ScheduleHelper:ProcessScheduleContinuous(Owner, Component)
    if Owner.bInLobby and Owner.bReconnected == nil then
        local bHas = Component:HasContinuousAward()
        if bHas then
            UIManager:OpenWnd(UIDef.UI_SCHEDULE_CONTINUOUS)
            return true
        end
    end
end

function ScheduleHelper:ProcessScheduleNoobLogin(Owner, Component)
    if Owner.bInLobby and Owner.bReconnected == nil then
        if Component:HasNoobLoginAward() then
            UIManager:OpenWnd(UIDef.UI_SCHEDULE_NOOB_LOGIN)
            return true
        end
    end
end

function ScheduleHelper:ProcessSevenDay(Owner, Component)
    if Owner.bInLobby and Owner.bReconnected == nil then
        local tbData = Component:GetSevenDayCheckIn()
        if tbData.can_award then
            UIManager:OpenWnd(UIDef.UI_SEVEN_DAY, { nCheckInCount = tbData.check_in_count, bCanAward = tbData.can_award })
            return true
        end
    end
end

return ScheduleHelper