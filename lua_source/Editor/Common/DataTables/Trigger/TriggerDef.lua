--[[
    DataTable类中必须有的成员变量与函数
    szFileName : 文件名，不包含路径
    tbContainer: table
    OnParseLine： 解析函数，参数Parser

    可选的变量与函数
    OnParsedFinished: 参数无，本DataTable读取完毕后触发
    OnAllFileLoaded: 参数无，所有DataTable读取完毕后触发
--]]
local TriggerDef = {}

TriggerDef.ScaleType = {
    NONE = 0,
    SCALE_WITHOUT_Z = 1,
    SCALE_WITH_Z = 2,
}

return TriggerDef
