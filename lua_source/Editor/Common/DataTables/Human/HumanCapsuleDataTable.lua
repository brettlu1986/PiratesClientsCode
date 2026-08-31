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
local HumanCapsuleDataTable = {}

HumanCapsuleDataTable.szFileName = "common/ffa/human/human_capsule_size.tab"

function HumanCapsuleDataTable:OnEditorDefine(Parser)
    -- Parser:SetKey("nResID")
    Parser:Define("nResID", "res_id", -1, Parser.TypeInt)
    Parser:Define("nPoseID", "pose_id", -1, Parser.TypeInt)
    Parser:Define("nCapsuleHalfHeight", "capsule_half_height", -1, Parser.TypeFloat)
    Parser:Define("nCapsuleRadius", "capsule_radius", -1, Parser.TypeFloat)
    Parser:Define("nToUpRightHeight", "to_upright_height", -1, Parser.TypeFloat)
    Parser:Define("nToCrouchHeight", "to_crouch_height", -1, Parser.TypeFloat)
end

function HumanCapsuleDataTable:OnEditorParseLine(Parser, tbContainer, tbNewTemplate)
    local szKey = tbNewTemplate.nResID .. tbNewTemplate.nPoseID

    tbContainer[szKey] =  tbNewTemplate
    return true
end 

-- [EXPORT BEGIN]
function HumanCapsuleDataTable:GetTemplate(nTemplateId, nPoseId)
    local szKey = nTemplateId .. nPoseId

    return self.tbContainer[szKey] 
end
-- [EXPORT END]

return HumanCapsuleDataTable
