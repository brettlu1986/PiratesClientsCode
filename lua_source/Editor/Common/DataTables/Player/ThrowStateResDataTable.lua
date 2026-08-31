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
local ThrowStateResDataTable = {}

ThrowStateResDataTable.szFileName = "common/res/throw_state_res.tab"

function ThrowStateResDataTable:OnEditorDefine(Parser)
    Parser:Define("nId", "id", -1, Parser.TypeInt)
    
    Parser:Define("nEquipId", "equip_id", nil, Parser.TypeInt)
    Parser:Define("nThrowState", "throw_state", nil, Parser.TypeInt)
    Parser:Define("tbMovementState", "state_id", nil, Parser.TypeArrayInt)
    Parser:Define("tbWeaponId", "weapon_id", nil, Parser.TypeArrayInt)
    Parser:Define("szAnimation", "anim_class_name", "", Parser.TypeString)
    
end

function ThrowStateResDataTable:OnEditorParseLine(Parser, tbContainer, tbNewTemplate)
    if not self.tbContainer[tbNewTemplate.nId] then
        tbContainer[tbNewTemplate.nId] = {}
    end 

    if not self.tbContainer[tbNewTemplate.nId][tbNewTemplate.nEquipId] then
        tbContainer[tbNewTemplate.nId][tbNewTemplate.nEquipId] = {}
    end 

    if not tbContainer[tbNewTemplate.nId][tbNewTemplate.nEquipId][tbNewTemplate.nThrowState] then
        tbContainer[tbNewTemplate.nId][tbNewTemplate.nEquipId][tbNewTemplate.nThrowState] = {}
    end
    table.insert(tbContainer[tbNewTemplate.nId][tbNewTemplate.nEquipId][tbNewTemplate.nThrowState], tbNewTemplate)
    return true
end

-- [EXPORT BEGIN]
function ThrowStateResDataTable:GetAnimRes(nHumanTemplateId, nThrowState, nMovementState, nWeaponTempateId, nEquipId)
    local tbRes = self.tbContainer[nHumanTemplateId][nEquipId][nThrowState]
    if not tbRes then  
        logerror("wrong throw human templateId and throw state :", nHumanTemplateId, nThrowState)
    end

    local tbStates = {}
    for _,v in ipairs(tbRes) do
        for _,v1 in ipairs(v.tbMovementState) do
            if v1 == nMovementState then  
                table.insert(tbStates, v)
            end
        end
    end
    
    for _,v in ipairs(tbStates) do
        for _,v1 in ipairs(v.tbWeaponId) do
            if v1 == nWeaponTempateId then 
                return v.szAnimation
            end
        end
    end
    
    return nil
end
-- [EXPORT END]



return ThrowStateResDataTable
