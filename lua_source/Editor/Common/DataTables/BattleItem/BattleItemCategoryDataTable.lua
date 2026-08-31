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
local BattleItemCategoryDataTable = {}

local BattleItemRoomDef = require("BattleItemRoomDef")

BattleItemCategoryDataTable.szFileName = "common/ffa/item/item_category.tab"

function BattleItemCategoryDataTable:OnEditorDefine(Parser)
    Parser:Define("nCategory", "category", -1, Parser.TypeInt)
    Parser:Define("nEquippedRoomType", "equipped_room_type", -1, Parser.TypeInt)
    Parser:Define("szItemCategoryOperationHelper", "item_category_operation_helper", nil, Parser.TypeString)
    Parser:Define("nBackpackType", "backpack_type", -1, Parser.TypeInt)
end

function BattleItemCategoryDataTable:OnEditorParseLine(Parser, tbContainer, tbNewTemplate)
    local nCategory = tbNewTemplate.nCategory
    local nBackpackType = tbNewTemplate.nBackpackType
    if nBackpackType > 0 and not BattleItemRoomDef:IsInventoryRoom(nBackpackType) then
        error("Parse item_category.tab nBackpackType failed! nCategory: ".. tbNewTemplate.nCategory .. ", nBackpackType:" .. nBackpackType)
    end

    local nEquippedRoomType = tbNewTemplate.nEquippedRoomType
    if nEquippedRoomType > 0 and not BattleItemRoomDef:IsEquipmentRoom(nEquippedRoomType) then
        error("Parse item_category.tab nEquippedRoomType failed! nCategory: ".. tbNewTemplate.nCategory .. ", nEquippedRoomType:" .. nEquippedRoomType)
    end

    self.tbContainer[nCategory] = tbNewTemplate
    return true
end

-- [EXPORT BEGIN]
function BattleItemCategoryDataTable:GetTemplate(nId)
    return self.tbContainer[nId]
end
-- [EXPORT END]

-- [EXPORT BEGIN]
function BattleItemCategoryDataTable:GetAllTemplate()
    return self.tbContainer
end
-- [EXPORT END]

-- [EXPORT BEGIN]
function BattleItemCategoryDataTable:GetEquippedRoomType(nCategory)
    local tbTemplate = self.tbContainer[nCategory]
    if tbTemplate == nil then
        error("BattleItemCategoryDataTable:GetEquippedRoomType error! nCategory" .. nCategory)
    end
    return tbTemplate.nEquippedRoomType
end
-- [EXPORT END]

-- [EXPORT BEGIN]
function BattleItemCategoryDataTable:GetOperationHelper(nCategory)
    local tbTemplate = self.tbContainer[nCategory]
    if tbTemplate == nil then
        error("BattleItemCategoryDataTable:GetOperationHelper error! nCategory" .. nCategory)
    end
    return tbTemplate.szItemCategoryOperationHelper
end
-- [EXPORT END]

-- [EXPORT BEGIN]
function BattleItemCategoryDataTable:CanInUnequippedRoom(nCategory)
    local tbTemplate = self.tbContainer[nCategory]
    if tbTemplate == nil then
        error("BattleItemCategoryDataTable:CanInUnequippedRoom error! nCategory" .. nCategory)
    end
    return tbTemplate.nBackpackType > 0
end
-- [EXPORT END]

-- [EXPORT BEGIN]
function BattleItemCategoryDataTable:CanInEquippedRoom(nCategory)
    local tbTemplate = self.tbContainer[nCategory]
    if tbTemplate == nil then
        error("BattleItemCategoryDataTable:CanInEquippedRoom error! nCategory" .. nCategory)
    end
    return tbTemplate.nEquippedRoomType > 0
end
-- [EXPORT END]

-- [EXPORT BEGIN]
function BattleItemCategoryDataTable:GetUnequippedRoomType(nCategory)
    local tbTemplate = self.tbContainer[nCategory]
    if tbTemplate == nil then
        error("BattleItemCategoryDataTable:GetUnequippedRoomType error! nCategory" .. nCategory)
    end
    return tbTemplate.nBackpackType
end
-- [EXPORT END]

return BattleItemCategoryDataTable
