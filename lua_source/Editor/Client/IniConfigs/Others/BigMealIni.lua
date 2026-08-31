--[[
    IniConfig类中必须有的成员变量与函数
    szFileName : 文件名，不包含路径
    Container: table
    OnParse： 解析函数，参数Parser
--]]

local BigMealIni = {}
BigMealIni.szFileName = "common/questdaily/meal.ini"

function BigMealIni:OnParse(Parser)
    local tbMeal = {}
    tbMeal.nLimitFoodCount = Parser:Get("meal", "limit_food_count", -1, Parser.TypeNumber)
    tbMeal.nQuestionNum = Parser:Get("meal", "question_number", -1, Parser.TypeNumber)
    tbMeal.nErrorAnswerAward  = Parser:Get("meal", "answer_error_award", -1, Parser.TypeNumber)
    tbMeal.nCloseQuestionSecond = Parser:Get("meal", "close_question_second", 0, Parser.TypeNumber)
    tbMeal.tbFreeFood = Parser:Get("meal", "free_food_item_id", {}, Parser.TypeArrayNumber)
    tbMeal.tbLimitFood = Parser:Get("meal", "limit_food_item_id", {}, Parser.TypeArrayNumber)
    tbMeal.nLimitFoodPrice = Parser:Get("meal", "limit_food_price", 0, Parser.TypeNumber)
    self.tbMeal = tbMeal
end

return BigMealIni
