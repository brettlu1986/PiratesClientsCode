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
local NpcWeaponDataTable = {}

-- [EXPORT]
local BattleItemDataTable = require("BattleItemDataTable")
-- [EXPORT]
local BattleItemCategoryDef = require("BattleItemCategoryDef")

NpcWeaponDataTable.szFileName = "common/ffa/ai/npc/npc_weapon.tab"

function NpcWeaponDataTable:OnEditorDefine(Parser)
    Parser:Define("nNpcLevel", "npc_level", -1, Parser.TypeInt)
    Parser:Define("bIsShip", "is_ship", false, Parser.TypeBool)
    Parser:Define("nItemCategory", "item_category", -1, Parser.TypeInt)
    Parser:Define("nWeaponCategory", "weapon_category", -1, Parser.TypeInt)
    Parser:Define("nAttackIntervalSeconds", "attack_interval_seconds", -1, Parser.TypeInt)
    Parser:Define("nBestDistance", "best_distance", -1, Parser.TypeInt)
    Parser:Define("nMaxDistance", "max_distance", -1, Parser.TypeInt)
    Parser:Define("nWeight", "weight", -1, Parser.TypeFloat)
end

function NpcWeaponDataTable:OnEditorParseLine(Parser, tbContainer, tbNewTemplate)
    local tbLevelTemplates = tbContainer[tbNewTemplate.nNpcLevel]
    if not tbLevelTemplates then
        tbLevelTemplates = {}
        tbContainer[tbNewTemplate.nNpcLevel] = tbLevelTemplates
    end
    local tbIsShipTemplates = tbLevelTemplates[tbNewTemplate.bIsShip]
    if not tbIsShipTemplates then
        tbIsShipTemplates = {}
        tbLevelTemplates[tbNewTemplate.bIsShip] = tbIsShipTemplates
    end
    local nItemCategory = tbNewTemplate.nItemCategory
    local tbTemplates = tbIsShipTemplates[nItemCategory]
    if tbTemplates == nil then
        tbIsShipTemplates[nItemCategory] = {}
        tbTemplates = tbIsShipTemplates[nItemCategory]
    end
    tbTemplates[tbNewTemplate.nWeaponCategory] = tbNewTemplate

    return true
end

-- [EXPORT BEGIN]
function NpcWeaponDataTable:GetTemplate(nNpcLevel, bIsShip, nItemCategory, nWeaponCategory)
    local tbLevelTemplates = self.tbContainer[nNpcLevel]
    if tbLevelTemplates == nil then
        return nil
    end
    local tbIsShipTemplates = tbLevelTemplates[bIsShip]
    if not tbIsShipTemplates then
        return nil
    end
    local tbTemplates = tbIsShipTemplates[nItemCategory]
    if not tbTemplates then
        return nil
    end
    return tbTemplates[nWeaponCategory]
end
-- [EXPORT END]

-- [EXPORT BEGIN]
function NpcWeaponDataTable:GetWeaponConfig(nNpcLevel, bIsShip, nItemTemplateId)
    local tbItemTemplate = BattleItemDataTable:GetTemplate(nItemTemplateId)
    local nCategory = tbItemTemplate.nCategory
    local tbTemplate = nil
    if nCategory == BattleItemCategoryDef.HUMAN_WEAPON then
        tbTemplate = self:GetTemplate(nNpcLevel, bIsShip, nCategory, tbItemTemplate.nWeaponCategory)
    else
        tbTemplate = self:GetTemplate(nNpcLevel, bIsShip, nCategory, tbItemTemplate.nSubCategory)
    end

    return tbTemplate
end
-- [EXPORT END]

return NpcWeaponDataTable
