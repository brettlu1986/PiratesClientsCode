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
local BackpackDataTable = {}

BackpackDataTable.szFileName = "common/item2/backpack.tab"

function BackpackDataTable:OnEditorDefine(Parser)
    Parser:SetKey("nId")
    Parser:Define("nId", "id", -1, Parser.TypeInt)
    Parser:Define("tbItemCategorys", "item_category", nil, Parser.TypeArrayInt)
    Parser:Define("nTimeLimitSeconds", "time_limit", -1, Parser.TypeInt)
end

-- [EXPORT BEGIN]
function BackpackDataTable:GetTemplate(nBackpackIdId)
    return self.tbContainer[nBackpackIdId]
end
-- [EXPORT END]

-- [EXPORT BEGIN]
function BackpackDataTable:GetAllCategorysInBackpack()
    local tbCategorys = {}
    for _, v1 in pairs(self.tbContainer) do
        local tbItemCategorys = v1.tbItemCategorys
        if tbItemCategorys ~= nil then
            for _, v2 in ipairs(tbItemCategorys) do
                tbCategorys[v2] = true
            end
        end
    end
    return tbCategorys
end
-- [EXPORT END]

-- [EXPORT BEGIN]
function BackpackDataTable:CanInBackpack(nCategory)
    local tbCategorys = self:GetAllCategorysInBackpack()
    return tbCategorys[nCategory] ~= nil
end
-- [EXPORT END]

return BackpackDataTable
