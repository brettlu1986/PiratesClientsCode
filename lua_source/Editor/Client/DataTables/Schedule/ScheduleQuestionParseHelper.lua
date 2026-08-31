local ScheduleQuestionParseHelper = {}

local TimeUtil = require("TimeUtil")

function ScheduleQuestionParseHelper.ParseExceptionalScheduleLine(Parser, NewTemplate)
    NewTemplate.nRewardId       = Parser:Get("reward", 0, Parser.TypeInt)
end

function ScheduleQuestionParseHelper.ParseExceptionalTimeLine(Parser, NewTemplate)

    local szStopTime = Parser:Get("stop_time", "", Parser.TypeString)
    local nStopTime, szError1 = TimeUtil.GetTimeByString(szStopTime)
    if nStopTime == nil then
        error("get schedule stop time failed! time id:"..NewTemplate.nId..", error:"..szError1)
    end
    NewTemplate.nStopTime = nStopTime

    NewTemplate.nNeedLoginDays = Parser:Get("days", 0, Parser.TypeInt)
end

function ScheduleQuestionParseHelper.ParseExceptionalTaskLine(Parser, tbScheduleTemplate, tbTaskTemplate)
    
end

return ScheduleQuestionParseHelper