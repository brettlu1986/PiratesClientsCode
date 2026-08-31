-----------------------------------------------------
--File Name    : HeadIconResDataTable.lua
--Author       : Chang Nan
--Create Time  : 2017-10-14
--Description  : 头像资源配置表
-----------------------------------------------------

local HeadIconResDataTable = {}

HeadIconResDataTable.szFileName = "common/res/head_icon_res.tab"

function HeadIconResDataTable:OnEditorDefine(Parser)
    Parser:SetKey("nId")
    Parser:Define("nId", "id", -1, Parser.TypeInt)
    Parser:Define("szPath", "icon", nil, Parser.TypeString)
    Parser:Define("szFFAResultPath", "ffa_result_icon", nil, Parser.TypeString)
end

-- [EXPORT BEGIN]
function HeadIconResDataTable:GetResPath( nTemplateId )
    local tbRet = self.tbContainer[nTemplateId]
    if tbRet then 
        return tbRet.szPath
    end 

    return nil 
end
-- [EXPORT END]

-- [EXPORT BEGIN]
function HeadIconResDataTable:GetTemplate( nTemplateId )
    return self.tbContainer[nTemplateId]
end
-- [EXPORT END]

return HeadIconResDataTable