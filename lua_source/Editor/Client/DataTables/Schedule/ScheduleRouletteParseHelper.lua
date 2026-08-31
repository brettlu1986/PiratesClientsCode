local ScheduleRouletteParseHelper = {}

local StringUtil = require("StringUtil")
local TimeUtil = require("TimeUtil")

function ScheduleRouletteParseHelper.ParseExceptionalScheduleLine(Parser, NewTemplate)
    NewTemplate.szTaskPath = Parser:Get("task_path", nil, Parser.TypeString)
    NewTemplate.tbTaskIds = Parser:Get("task_ids", nil, Parser.TypeArrayInt)
    NewTemplate.nTicketId     = Parser:Get("ticket_id", 0, Parser.TypeInt)
    NewTemplate.nRewardTimes  = Parser:Get("reward_times", 0, Parser.TypeInt)
    NewTemplate.nLuckyValue   = Parser:Get("lucky", 0, Parser.TypeInt)
    NewTemplate.nLuckyLimit   = Parser:Get("lucky_limit", 0, Parser.TypeInt)
    NewTemplate.tbRewards     = Parser:Get("reward_pool", {}, Parser.TypeArrayInt)
    local tbRewardWeight= Parser:Get("reward_weight", {}, Parser.TypeArrayInt)
    if #tbRewardWeight ~= #NewTemplate.tbRewards then
        error("ScheduleRouletteParseHelper.ParseExceptionalScheduleLine: reward count invalid")
    end

    NewTemplate.tbRewardPool = {}
    NewTemplate.nMaxReward = 0
    local nMaxWeight = 0
    for i, v in ipairs(NewTemplate.tbRewards) do
        NewTemplate.tbRewardPool[v] = tbRewardWeight[i]
        if tbRewardWeight[i] > nMaxWeight then
            nMaxWeight = tbRewardWeight[i]
            NewTemplate.nMaxReward = v
        end
    end

    local szClientTask = Parser:Get("client_task_ids", nil, Parser.TypeString)
    if szClientTask == nil then
        error("ScheduleRouletteParseHelper.ParseExceptionalScheduleLine: client task is nil")
    end

    local tbClientTaskIds = {}
    local tbMainTasks = StringUtil.Split(szClientTask, ";")
    for i, v in ipairs(tbMainTasks) do
        local tbTask = StringUtil.Split(v, ",")
        local tbTaskId = {}
        for nIndex, szValue in ipairs(tbTask) do
            table.insert(tbTaskId, tonumber(szValue))
        end
        table.insert(tbClientTaskIds, tbTaskId)
    end 

    NewTemplate.tbClientTaskIds = tbClientTaskIds
end

function ScheduleRouletteParseHelper.ParseExceptionalTimeLine(Parser, NewTemplate)
    local szStartTime = Parser:Get("start_time", "", Parser.TypeString)
    local nStartTime, szError = TimeUtil.GetTimeByString(szStartTime)
    if nStartTime == nil then
        error("get schedule start time failed! time id:"..NewTemplate.nId..", error:"..szError)
    end
    NewTemplate.nStartTime = nStartTime

    local szStopTime = Parser:Get("stop_time", "", Parser.TypeString)
    local nStopTime, szError1 = TimeUtil.GetTimeByString(szStopTime)
    if nStopTime == nil then
        error("get schedule stop time failed! time id:"..NewTemplate.nId..", error:"..szError1)
    end
    NewTemplate.nStopTime = nStopTime
end

function ScheduleRouletteParseHelper.ParseExceptionalTaskLine(Parser, tbScheduleTemplate, tbTaskTemplate)
    
end

return ScheduleRouletteParseHelper