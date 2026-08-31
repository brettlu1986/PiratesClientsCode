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
local SoundExperienceDataTable = {}

SoundExperienceDataTable.szFileName = "client/battle_experience/sound_experience.tab"

function SoundExperienceDataTable:OnEditorDefine(Parser)
    Parser:SetKey("nId")
    Parser:Define("nId", "id", -1, Parser.TypeInt)
    Parser:Define("nSoundEffectId", "sound_effect_id", -1, Parser.TypeInt)
    Parser:Define("nSoundCd", "cd", 0, Parser.TypeInt)
    Parser:Define("nPriority", "priority", 0, Parser.TypeInt)    
end

-- [EXPORT BEGIN]
function SoundExperienceDataTable:GetTemplate(nId)
    return self.tbContainer[nId]
end
-- [EXPORT END]

return SoundExperienceDataTable
