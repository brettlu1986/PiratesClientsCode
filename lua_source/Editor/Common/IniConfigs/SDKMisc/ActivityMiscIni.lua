--[[
    IniConfig类中必须有的成员变量与函数
    szFileName : 文件名，不包含路径
    Container: table
    OnParse： 解析函数，参数Parser
--]]

local ActivityMiscIni = {}
ActivityMiscIni.szFileName = "common/activity/ActivityMisc.ini"

function ActivityMiscIni:OnParse(Parser)
    local tbSurvey = {}
    tbSurvey.Target_Battle_Count = Parser:Get("SURVEY", "target_battle_count", -1, Parser.TypeNumber)
    tbSurvey.Url = Parser:Get("SURVEY", "survey_url", -1, Parser.TypeString)

    tbSurvey.QuestionUrl = Parser:Get("SURVEY", "question_survey_url", "", Parser.TypeString)

    self.tbSurvey = tbSurvey
end

return ActivityMiscIni
