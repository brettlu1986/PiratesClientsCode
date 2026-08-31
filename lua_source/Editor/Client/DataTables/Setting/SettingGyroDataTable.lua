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

local SettingGyroDataTable = {}

SettingGyroDataTable.szFileName = "client/setting/setting_gyro.tab"

function SettingGyroDataTable:OnEditorDefine(Parser)
    Parser:SetKey("nId")
    Parser:Define("nId", "id", -1, Parser.TypeInt)
    Parser:Define("Parachute", "parachute", 0, Parser.TypeInt)
    Parser:Define("HumanNotAim", "human_not_aim", 0, Parser.TypeInt)
    Parser:Define("HumanAim", "human_aim", 0, Parser.TypeInt)
    Parser:Define("ShipNotAim", "ship_not_aim", 0, Parser.TypeInt)
    Parser:Define("ShipAim2", "ship_aim2", 0, Parser.TypeInt)
    Parser:Define("ShipAim4", "ship_aim4", 0, Parser.TypeInt)
    Parser:Define("ShipAim8", "ship_aim8", 0, Parser.TypeInt)
end

-- [EXPORT BEGIN]
function SettingGyroDataTable:GetTemplate(nId)
    return self.tbContainer[nId] 
end
-- [EXPORT END]

return SettingGyroDataTable
