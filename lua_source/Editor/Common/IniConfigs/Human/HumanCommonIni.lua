--[[
    IniConfig类中必须有的成员变量与函数
    szFileName : 文件名，不包含路径
    Container: table
    OnParse： 解析函数，参数Parser
--]]

local HumanCommonIni = {}
HumanCommonIni.szFileName = "common/ffa/human/human_common.ini"

function HumanCommonIni:OnParse(Parser)
    local tbHumanCommonData = {}
    tbHumanCommonData.nDelayReholdTime = Parser:Get("progress_bar", "delay_rehold_time", -1, Parser.TypeNumber)
    tbHumanCommonData.nMaxAcceleration = Parser:Get("movement", "max_acceleration", 100000, Parser.TypeNumber)

    self.tbHumanCommonData = tbHumanCommonData
end

return HumanCommonIni
