--[[
    IniConfig类中必须有的成员变量与函数
    szFileName : 文件名，不包含路径
    Container: table
    OnParse： 解析函数，参数Parser
--]]

local QnaIni = {}
QnaIni.szFileName = "common/questdaily/qna.ini"

function QnaIni:OnParse(Parser)
    local tbQna = {}
    tbQna.nAnswerSecond = Parser:Get("qna", "answer_second", -1, Parser.TypeNumber)
    tbQna.nQuestionNum = Parser:Get("qna", "question_number", -1, Parser.TypeNumber)
    tbQna.nErrorAnswerAward  = Parser:Get("qna", "answer_error_award", -1, Parser.TypeNumber)
    tbQna.nCloseQuestionSecond = Parser:Get("qna", "close_question_second", 0, Parser.TypeNumber)
    tbQna.nWrongScore = Parser:Get("qna", "wrong_score", 0, Parser.TypeNumber)
    self.tbQna = tbQna
end

return QnaIni
