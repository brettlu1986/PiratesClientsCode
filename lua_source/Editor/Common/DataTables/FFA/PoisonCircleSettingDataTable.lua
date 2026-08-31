--[[
    DataTable类中必须有的成员变量与函数
    szFileName : 文件名，不包含路径
    tbContainer: table
    OnEditorParseLine： 解析函数，参数Parser

    可选的变量与函数
    OnEditorParseFinished: 参数无，本DataTable读取完毕后触发
    OnGameRequired: 参数无，游戏运行时第一次require时触发
    OnEditorDefine: 定义导出参数    自定义导出标签：
         导出单行：-- [EXPORT]
         导出多行：-- [EXPORT BEGIN] 和 -- [EXPORT END]
--]]
local PoisonCircleSettingDataTable = {}

PoisonCircleSettingDataTable.szFileName = "common/ffa/poison_circle/poison_circle_setting.tab"

function PoisonCircleSettingDataTable:OnEditorDefine(Parser)
    Parser:SetKey("nDungeonId")
    Parser:Define("nDungeonId",         "dungeon_id",                    -1,    Parser.TypeInt)
    Parser:Define("nLandPercent",       "land_percent",                  -1,    Parser.TypeInt)
    Parser:Define("bLandIdEqual",       "land_id_equal",                 false, Parser.TypeBool)
    Parser:Define("nMaxRangeWidth",     "max_range_width",               -1,    Parser.TypeInt)
    Parser:Define("bCompleteRandom",    "completely_random_finalpoint",  false, Parser.TypeBool)
    Parser:Define("nRandomCircleIndex", "random_circle_index",           -1,    Parser.TypeInt)
end

-- [EXPORT BEGIN]
function PoisonCircleSettingDataTable:GetContainer(nDungeonId)
    return self.tbContainer[nDungeonId]
end
-- [EXPORT END]

return PoisonCircleSettingDataTable
