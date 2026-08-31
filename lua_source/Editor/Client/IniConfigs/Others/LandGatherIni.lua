--[[
    IniConfig类中必须有的成员变量与函数
    szFileName : 文件名，不包含路径
    Container: table
    OnParse： 解析函数，参数Parser
--]]

local LandGatherIni = {}
LandGatherIni.szFileName = "client/landgather/land_gather.ini"

function LandGatherIni:OnParse(Parser)
    local tbLandGather = {}
    tbLandGather.nRefreshInterval = Parser:Get("LandGather", "refresh_interval", 10, Parser.TypeNumber)
    tbLandGather.nRefreshPointCount = Parser:Get("LandGather", "refresh_point_count", 1, Parser.TypeNumber)
    tbLandGather.szLogicName = Parser:Get("LandGather", "logic_name", "Logic_BigPort_Royal_LandGather", Parser.TypeString)
    self.tbLandGather = tbLandGather
end

return LandGatherIni
