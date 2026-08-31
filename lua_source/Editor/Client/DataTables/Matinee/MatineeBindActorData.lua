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
local MatineeBindActorData = {}

MatineeBindActorData.szFileName = "client/matinee/matinee_bind.tab"

function MatineeBindActorData:OnEditorDefine(Parser)
    -- Parser:SetKey("nID")
    Parser:Define("nID", "bind_id", -1, Parser.TypeInt)
    Parser:Define("nRace", "race", -1, Parser.TypeInt)
    Parser:Define("nSex", "sex", -1, Parser.TypeInt)
    Parser:Define("szActorPath", "actor_path", nil, Parser.TypeString)
    Parser:Define("szBindTarget", "bind_target", nil, Parser.TypeString)
    Parser:Define("szReplaceMesh", "replace_mesh_name", nil, Parser.TypeString)
end

function MatineeBindActorData:OnEditorParseLine(Parser, tbContainer, tbNewTemplate)
    if tbNewTemplate.nRace > 0 and tbNewTemplate.nSex > 0 then 
        if self.tbContainer[tbNewTemplate.nID] == nil then 
            tbContainer[tbNewTemplate.nID] = {}
        end
        tbContainer[tbNewTemplate.nID][tbNewTemplate.nRace * 100 + tbNewTemplate.nSex] = tbNewTemplate
    else 
        tbContainer[tbNewTemplate.nID] = tbNewTemplate
    end 
    return true
end 
 
-- [EXPORT BEGIN]
function MatineeBindActorData:GetTemplate(nID, nRace, nSex)
    local tbRet = self.tbContainer[nID]
    if tbRet.nRace ~= nil then 
        return tbRet
    end 
    if nRace ~= nil and nSex ~= nil then 
        return tbRet[nRace * 100 + nSex]
    end 
    
    return nil 
end
-- [EXPORT END]

return MatineeBindActorData
