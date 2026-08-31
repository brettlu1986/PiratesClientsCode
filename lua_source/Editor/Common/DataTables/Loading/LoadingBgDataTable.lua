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

-- 玩家活跃度活动表

local LoadingBgDataTable = {}
LoadingBgDataTable.szFileName = "client/ui/loading_bg.tab"



function LoadingBgDataTable:OnEditorParseLine(Parser, tbContainer, tbNewTemplate)
    local nId        = Parser:Get("scene_id", -1, Parser.TypeInt, true)
    local szImgPath  = Parser:Get("img_path", "", Parser.TypeString, false)
    tbContainer[nId] = szImgPath

    return true
end


-- [EXPORT BEGIN]
function  LoadingBgDataTable:GetContainer()
    return self.tbContainer
end
-- [EXPORT END]

-- [EXPORT BEGIN]
function LoadingBgDataTable:GetTemplate(nId)
    return self.tbContainer[nId]
end
-- [EXPORT END]

return LoadingBgDataTable