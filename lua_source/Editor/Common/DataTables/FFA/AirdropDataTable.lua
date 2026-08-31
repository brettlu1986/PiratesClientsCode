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
local AirdropDataTable = {}

AirdropDataTable.szFileName = "common/ffa/airdrop.tab"

function AirdropDataTable:OnEditorDefine(Parser)
    Parser:SetKey("nDungeonId")
    Parser:Define("nDungeonId", "dungeon_id", -1, Parser.TypeInt)
    Parser:Define("nEndTime", "end_time", -1, Parser.TypeInt)
    Parser:Define("nCount", "count", -1, Parser.TypeInt)
    Parser:Define("szAirdropInterval", "airdrop_interval", "", Parser.TypeString)
    Parser:Define("nAirdropArea", "airdrop_area", -1, Parser.TypeInt)
    Parser:Define("nFlyHeight", "fly_height", -1, Parser.TypeInt)
    Parser:Define("nFlyVelocity", "fly_velocity", -1, Parser.TypeInt)
    Parser:Define("nDropVelocity", "drop_velocity", -1, Parser.TypeInt)
    Parser:Define("nDropAcceleration", "drop_acceleration", -1, Parser.TypeInt)
    Parser:Define("nTransporterId", "transporter_id", -1, Parser.TypeInt)
    Parser:Define("nAirdropId", "airdrop_id", -1, Parser.TypeInt)
    Parser:Define("nRouteDirection", "route_direction", -1, Parser.TypeInt)
end

-- [EXPORT BEGIN]
function AirdropDataTable:GetTemplate(nID)
    return self.tbContainer[nID]
end
-- [EXPORT END]

-- [EXPORT BEGIN]
function AirdropDataTable:GetContainer()
    return self.tbContainer
end
-- [EXPORT END]

return AirdropDataTable
