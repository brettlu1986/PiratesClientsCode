--[[
    IniConfig类中必须有的成员变量与函数
    szFileName : 文件名，不包含路径
    Container: table
    OnParse： 解析函数，参数Parser
--]]

local OceanGatherIni = {}
OceanGatherIni.szFileName = "client/oceangather/ocean_gather.ini"

function OceanGatherIni:OnParse(Parser)
    local tbOceanGather = {}
    tbOceanGather.nRefreshInterval = Parser:Get("OceanGather", "refresh_interval", 10, Parser.TypeNumber)
    tbOceanGather.nRefreshRadiusMin = Parser:Get("OceanGather", "refresh_radius_min", 30000, Parser.TypeNumber)
    tbOceanGather.nRefreshRadiusMax  = Parser:Get("OceanGather", "refresh_radius_max", 100000, Parser.TypeNumber)
    tbOceanGather.nRefreshAngle = Parser:Get("OceanGather", "refresh_angle", 30, Parser.TypeNumber)
    tbOceanGather.nRefreshPointCount = Parser:Get("OceanGather", "refresh_point_count", 1, Parser.TypeNumber)
    tbOceanGather.nPointCountMax = Parser:Get("OceanGather", "point_count_max", 2, Parser.TypeNumber)
    tbOceanGather.nAutoGatherRadius = Parser:Get("OceanGather", "auto_gather_radius", 1000, Parser.TypeNumber)
    self.tbOceanGather = tbOceanGather
end

return OceanGatherIni
