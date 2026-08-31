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
local LobbyDecorationResDataTable = {}

LobbyDecorationResDataTable.szFileName = "client/lobbycaptain/decoration_res.tab"

function LobbyDecorationResDataTable:OnEditorDefine(Parser)
    Parser:SetKey("nResId")
    Parser:Define("nResId", "res_id", -1, Parser.TypeInt)
    Parser:Define("tbModelLocationOffset", "model_location_offset", {0,0,0}, Parser.TypeArrayInt)
    Parser:Define("tbModelRotationOffset", "model_rotation_offset", {0,0,0}, Parser.TypeArrayInt)
    Parser:Define("nModelScale", "model_scale", 1, Parser.TypeFloat)
    Parser:Define("szModelResPath", "model_res", "", Parser.TypeString)
    Parser:Define("tbSeasonLocationOffset", "season_location_offset", {0,0,0}, Parser.TypeArrayInt)
    Parser:Define("tbSeasonRotationOffset", "season_rotation_offset", {0,0,0}, Parser.TypeArrayInt)
    Parser:Define("nSeasonScale", "season_scale", 1, Parser.TypeFloat)
    Parser:Define("tbTierBuyLocationOffset", "tier_buy_location_offset", {0,0,0}, Parser.TypeArrayInt)
    Parser:Define("tbTierBuyRotationOffset", "tier_buy_rotation_offset", {0,0,0}, Parser.TypeArrayInt)
    Parser:Define("nTierBuyScale", "tier_buy_scale", 1, Parser.TypeFloat)
end

-- [EXPORT BEGIN]
function LobbyDecorationResDataTable:GetTemplate(nResId)
    return self.tbContainer[nResId]
end
-- [EXPORT END]

return LobbyDecorationResDataTable