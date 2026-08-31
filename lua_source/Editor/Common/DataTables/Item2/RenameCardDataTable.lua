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
local RenameCardDataTable = {}

RenameCardDataTable.szFileName = "common/item2/sub/usable/rename_card.tab"

function RenameCardDataTable:OnEditorDefine(Parser)
    Parser:SetKey("nTime")
    Parser:Define("nTime", "times", -1, Parser.TypeInt)
    Parser:Define("nCount", "count", "", Parser.TypeInt)
end

-- [EXPORT BEGIN]
function RenameCardDataTable:GetTemplate(nId)
    local tbData = self.tbContainer[nId]
    if not tbData then   
        local nMaxIdx = 1
        for k, v in pairs(self.tbContainer) do  
            if k >= nMaxIdx then   
                nMaxIdx = k
            end
        end
        tbData = self.tbContainer[nMaxIdx]
    end
    return tbData
end

-- [EXPORT END]

return RenameCardDataTable
