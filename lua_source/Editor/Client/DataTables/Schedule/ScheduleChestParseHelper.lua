local ScheduleChestParseHelper = {}
local StringUtil = require("StringUtil")
local TimeUtil = require("TimeUtil")

function ScheduleChestParseHelper.ParseExceptionalScheduleLine(Parser, NewTemplate)
    NewTemplate.szTaskPath = Parser:Get("task_path", nil, Parser.TypeString)
    NewTemplate.tbTaskIds = Parser:Get("task_ids", nil, Parser.TypeArrayInt)
    NewTemplate.nBoxCount = Parser:Get("box_count", 0, Parser.TypeInt)
    NewTemplate.nKeyId  = Parser:Get("key_id", 0, Parser.TypeInt)

    local szClientTask = Parser:Get("client_task_ids", nil, Parser.TypeString)
    if szClientTask == nil then
        error("ScheduleChestParseHelper.ParseExceptionalScheduleLine: client task is nil")
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

function ScheduleChestParseHelper.ParseExceptionalTimeLine(Parser, NewTemplate)
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

function ScheduleChestParseHelper.ParseExceptionalTaskLine(Parser, tbScheduleTemplate, tbTaskTemplate)
    
end

return ScheduleChestParseHelper