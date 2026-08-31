--[[
    IniConfig类中必须有的成员变量与函数
    szFileName : 文件名，不包含路径
    Container: table
--]]

local CreateRoleIni = {}
CreateRoleIni.szFileName = "common/name/create_role.ini"

function CreateRoleIni:OnParse(Parser)
    self.nMinNameLen              = Parser:Get("name_length", "min_len"            , -1, Parser.TypeNumber)
    self.nMaxNameLen             = Parser:Get("name_length", "max_len"        , -1, Parser.TypeNumber)
end

return CreateRoleIni
