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
local LobbyArmorMiscDataTable = {}

local HumanAvatarDef    = require("HumanAvatarDef")
local L10N              = require("L10N")

local FashionSlotCategoryToConfigName = HumanAvatarDef.FashionSlotCategoryToConfigName

local SPECIAL_DESC_MAX_COUNT = 7
local REDUCE_DAMAGE_DESC_MAX_COUNT = 3

LobbyArmorMiscDataTable.szFileName = "client/lobbycaptain/human_armor_misc.tab"


local function ParseSpecialDesc(Parser, NewTemplate)
    local tbSpecialDesc = {}
    for nIdx = 1, SPECIAL_DESC_MAX_COUNT do
        local l10nSpecialDesc = Parser:Get("special_desc_"..nIdx, L10N.NullString, Parser.TypeL10N)
        if l10nSpecialDesc and l10nSpecialDesc ~= L10N.NullString then
            table.insert(tbSpecialDesc, l10nSpecialDesc)
        end
    end
    NewTemplate.tbSpecialDesc = tbSpecialDesc
end

local function ParseReduceDamageDesc(Parser, NewTemplate)
    local tbReduceDamageDesc = {}
    for nIdx = 1, REDUCE_DAMAGE_DESC_MAX_COUNT do
        local l10nReduceDamageDesc = Parser:Get("reduce_damage_desc_"..nIdx, L10N.NullString, Parser.TypeL10N)
        if l10nReduceDamageDesc and l10nReduceDamageDesc ~= L10N.NullString then
            table.insert(tbReduceDamageDesc, l10nReduceDamageDesc)
        end
    end
    NewTemplate.tbReduceDamageDesc = tbReduceDamageDesc
end



function LobbyArmorMiscDataTable:OnEditorDefine(Parser)
    Parser:SetKey("nType")
    Parser:Define("nType",                  "armor_type",                   -1,               Parser.TypeInt)
    Parser:Define("l10nGeneralDesc",        "general_desc",                 L10N.NullString,  Parser.TypeL10N)
    Parser:Define("szAnimKey",              "anim_key",                     "",               Parser.TypeString)
end

function LobbyArmorMiscDataTable:OnEditorParseLine(Parser, tbContainer, tbNewTemplate)
    local tbIcons = tbNewTemplate.tbIcons
    if not tbIcons then
        tbIcons = {}
        tbNewTemplate.tbIcons = tbIcons
    end
    for nSlotType, szConfigName in pairs(FashionSlotCategoryToConfigName) do
        tbIcons[nSlotType] = Parser:Get(szConfigName, "", Parser.TypeString, false)
    end
    ParseSpecialDesc(Parser, tbNewTemplate)
    ParseReduceDamageDesc(Parser, tbNewTemplate)
    return true
end


-- [EXPORT BEGIN]
function LobbyArmorMiscDataTable:GetTemplate(nType)
    return self.tbContainer[nType]
end
-- [EXPORT END]

return LobbyArmorMiscDataTable