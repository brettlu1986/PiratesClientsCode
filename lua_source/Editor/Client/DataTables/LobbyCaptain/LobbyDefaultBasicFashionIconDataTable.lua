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
local LobbyDefaultBasicFashionIconDataTable = {}
local HumanAvatarDef = require("HumanAvatarDef")

local FashionSlotCategoryToConfigName = HumanAvatarDef.FashionSlotCategoryToConfigName

LobbyDefaultBasicFashionIconDataTable.szFileName = "client/lobbycaptain/basic_default_fashion_icon.tab"

function LobbyDefaultBasicFashionIconDataTable:OnEditorDefine(Parser)
    Parser:SetKey("nId")
    Parser:Define("nId", "appearance_id", -1, Parser.TypeInt)
    Parser:Define("nNumberIndex", "number_index", -1, Parser.TypeInt)
end

function LobbyDefaultBasicFashionIconDataTable:OnEditorParseLine(Parser, tbContainer, tbNewTemplate)
    local tbIcons = tbNewTemplate.tbIcons
    if not tbIcons then
        tbIcons = {}
        tbNewTemplate.tbIcons = tbIcons
    end
    for nSlotType, szConfigName in pairs(FashionSlotCategoryToConfigName) do
        tbIcons[nSlotType] = Parser:Get(szConfigName, "", Parser.TypeString, false)
    end
    return true
end

-- [EXPORT BEGIN]
function LobbyDefaultBasicFashionIconDataTable:GetTemplate(nId)
    return self.tbContainer[nId]
end


-- [EXPORT END]

return LobbyDefaultBasicFashionIconDataTable