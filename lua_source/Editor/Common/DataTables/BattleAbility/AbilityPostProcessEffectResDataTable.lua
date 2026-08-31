-----------------------------------------------------
--File Name    : AbilityPostProcessEffectResDataTable.lua
--Author       : Song Fuhao
--Create Time  : 2018-03-26
--Description  : 后处理效果资源配置表
-----------------------------------------------------

local AbilityPostProcessEffectResDataTable = {}

AbilityPostProcessEffectResDataTable.szFileName = "common/res/ability_post_process_effect_res.tab"

function AbilityPostProcessEffectResDataTable:OnEditorDefine(Parser)
    Parser:SetKey("nId")
    Parser:Define("nId"         , "id"          , -1    , Parser.TypeInt)
    Parser:Define("szDataRes"   , "data_res"    , nil   , Parser.TypeString)
    Parser:Define("nPriority"   , "priority"    , 1     , Parser.TypeInt)
end

-- [EXPORT BEGIN]
function AbilityPostProcessEffectResDataTable:GetTemplate(nTemplateId)
    return self.tbContainer[nTemplateId]
end
-- [EXPORT END]

return AbilityPostProcessEffectResDataTable
