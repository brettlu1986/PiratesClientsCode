--[[
    IniConfig类中必须有的成员变量与函数
    szFileName : 文件名，不包含路径
    Container: table
    OnParse： 解析函数，参数Parser
--]]

local HumanSwimmingIni = {}
HumanSwimmingIni.szFileName = "common/ffa/human/human_swimming.ini"

function HumanSwimmingIni:OnParse(Parser)
    self.nMaxStamina = Parser:Get("swimming", "max_stamina", -1, Parser.TypeNumber)
    self.nDecreaseValue = Parser:Get("swimming", "decrease_value", -1, Parser.TypeNumber)
    self.nRecoverValue = Parser:Get("swimming", "recover_value", -1, Parser.TypeNumber)
    self.nBuffId = Parser:Get("swimming", "buff_id", -1, Parser.TypeNumber)
    self.nStaminaMinDistance = Parser:Get("swimming", "stamina_min_distance", -1, Parser.TypeNumber)
end

return HumanSwimmingIni
