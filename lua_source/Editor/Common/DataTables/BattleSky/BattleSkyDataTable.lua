--[[
    DataTable类中必须有的成员变量与函数
    szFileName : 文件名，不包含路径
    Container: table
    OnEditorParseLine： 解析函数，参数Parser

    可选的变量与函数
    OnEditorParseFinished: 参数无，本DataTable读取完毕后触发
    OnGameRequired: 参数无，游戏运行时第一次require时触发
    OnEditorDefine: 定义导出参数    自定义导出标签：
         导出单行：-- [EXPORT] 
         导出多行：-- [EXPORT BEGIN] 和 -- [EXPORT END]
--]]
local BattleSkyDataTable = {}

BattleSkyDataTable.szFileName = "common/battlesky/battle_sky.tab"

function BattleSkyDataTable:OnEditorDefine(Parser)
    Parser:SetKey("nConfigId")
    Parser:Define("nConfigId", "id", -1, Parser.TypeInt)
    Parser:Define("nSkyChangeWeight", "sky_change_weight", 0, Parser.TypeInt)
    Parser:Define("tbFixTimes", "fix_sky_time", nil, Parser.TypeArrayInt)
    Parser:Define("tbRandomSkyTime", "random_sky_time_array", nil, Parser.TypeArrayInt)
    Parser:Define("tbRandomWeight", "random_weight_array", nil, Parser.TypeArrayInt)
end

-- [EXPORT BEGIN]
function BattleSkyDataTable:GetTemplate(nConfigId)
    return self.tbContainer[nConfigId]
end
-- [EXPORT END]

return BattleSkyDataTable