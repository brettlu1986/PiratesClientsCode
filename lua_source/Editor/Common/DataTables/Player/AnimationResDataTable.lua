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
local AnimationResDataTable = {}

AnimationResDataTable.szFileName = "common/res/animation_res.tab"

function AnimationResDataTable:OnEditorDefine(Parser)
    Parser:Define("nId", "id", -1, Parser.TypeInt)
    Parser:Define("szKey", "anim_key", nil, Parser.TypeString)
    Parser:Define("nStateId", "state_id", 1, Parser.TypeInt)    
    Parser:Define("tbWeaponIds", "weapon_id", nil, Parser.TypeArrayInt)
    Parser:Define("tbWeaponCategorys", "weapon_category", nil, Parser.TypeArrayInt)
    Parser:Define("szNodeKey", "node_key", nil, Parser.TypeString)
    Parser:Define("bMontage", "is_montage", true, Parser.TypeBool)
    Parser:Define("szAnimation", "anim_class_name", "", Parser.TypeString)
    Parser:Define("nLooping", "anim_loop", 0, Parser.TypeInt)
end

function AnimationResDataTable:OnEditorParseLine(Parser, tbContainer, tbNewTemplate)
    -- tbNewTemplate.nAnimationId    = Parser:Get("anim_id",         -1, Parser.TypeInt, true)
    if not tbNewTemplate.szKey   then 
        logerror("error anim key")
        return true
    end 
    if not self.tbContainer[tbNewTemplate.nId] then
        tbContainer[tbNewTemplate.nId] = {}
    end 
    if not tbContainer[tbNewTemplate.nId][tbNewTemplate.szKey] then
        tbContainer[tbNewTemplate.nId][tbNewTemplate.szKey] = {}
    end
    if not tbContainer[tbNewTemplate.nId][tbNewTemplate.szKey][tbNewTemplate.nStateId] then
        tbContainer[tbNewTemplate.nId][tbNewTemplate.szKey][tbNewTemplate.nStateId] = {}
    end
    table.insert(tbContainer[tbNewTemplate.nId][tbNewTemplate.szKey][tbNewTemplate.nStateId], tbNewTemplate)
    -- tbContainer[tbNewTemplate.nId][tbNewTemplate.szKey][tbNewTemplate.nStateId] = tbNewTemplate
    -- if not tbContainer[tbNewTemplate.nId][tbNewTemplate.szKey][tbNewTemplate.nStateId][tbNewTemplate.nWeaponCategory] then
    --     tbContainer[tbNewTemplate.nId][tbNewTemplate.szKey][tbNewTemplate.nStateId][tbNewTemplate.nWeaponCategory] = {}
    -- end
    -- if not tbContainer[tbNewTemplate.nId][tbNewTemplate.szKey][tbNewTemplate.nStateId][tbNewTemplate.nWeaponCategory][tbNewTemplate.nWeaponId] then
    --     tbContainer[tbNewTemplate.nId][tbNewTemplate.szKey][tbNewTemplate.nStateId][tbNewTemplate.nWeaponCategory][tbNewTemplate.nWeaponId] = {}
    -- end

    -- tbContainer[tbNewTemplate.nId][tbNewTemplate.szKey][tbNewTemplate.nStateId][tbNewTemplate.nWeaponCategory][tbNewTemplate.nWeaponId] = tbNewTemplate
    -- if tbNewTemplate.szNodeKey then 
    --     if not self.tbContainer[tbNewTemplate.nId][tbNewTemplate.szNodeKey] then
    --         tbContainer[tbNewTemplate.nId][tbNewTemplate.szNodeKey] = {}
    --     end 
    --     tbContainer[tbNewTemplate.nId][tbNewTemplate.szNodeKey][tbNewTemplate.szKey] = tbNewTemplate
    -- else 
    --     tbContainer[tbNewTemplate.nId][tbNewTemplate.szKey] = tbNewTemplate
    -- end

    -- if tbNewTemplate.nStateId then
    --     if not tbContainer[tbNewTemplate.nId][tbNewTemplate.szKey] then
    --         tbContainer[tbNewTemplate.nId][tbNewTemplate.szKey] = {}
    --     end
    --     if tbNewTemplate.nWeaponId then
    --         if not tbContainer[tbNewTemplate.nId][tbNewTemplate.szKey][tbNewTemplate.nStateId] then
    --             tbContainer[tbNewTemplate.nId][tbNewTemplate.szKey][tbNewTemplate.nStateId] = {}
    --         end 
    --         tbContainer[tbNewTemplate.nId][tbNewTemplate.szKey][tbNewTemplate.nStateId][tbNewTemplate.nWeaponId] = tbNewTemplate
    --     else
    --         tbContainer[tbNewTemplate.nId][tbNewTemplate.szKey][tbNewTemplate.nStateId] = tbNewTemplate
    --     end

    -- else
    --     if tbNewTemplate.nWeaponId then
    --         if not tbContainer[tbNewTemplate.nId][tbNewTemplate.szKey] then
    --             tbContainer[tbNewTemplate.nId][tbNewTemplate.szKey] = {}
    --         end
    --         tbContainer[tbNewTemplate.nId][tbNewTemplate.szKey][tbNewTemplate.nWeaponId] = tbNewTemplate
    --     else
    --         tbContainer[tbNewTemplate.nId][tbNewTemplate.szKey] = tbNewTemplate
    --     end 
    -- end
    
    return true;
end

-- [EXPORT BEGIN]
function AnimationResDataTable:GetTemplate(nId, szKey)
    local tbAnims = self.tbContainer[nId]
    if not tbAnims then
        logerror("AnimationResDataTable:GetTemplate not find anim table ", nId)
        return 
    end

    return tbAnims[szKey]
end
-- [EXPORT END]

-- [EXPORT BEGIN]
function AnimationResDataTable:GetTemplateRes(nId, szKey)
    local tbTemplate = self:GetTemplate(nId, szKey)
    if tbTemplate then
        return tbTemplate.szAnimation
    end
end
-- [EXPORT END]

-- [EXPORT BEGIN]
function AnimationResDataTable:TryGetNodeRes(nID, szKey, szNodeKey)
    local tbAnims = self.tbContainer[nID]
    if not tbAnims then
        logerror("AnimationResDataTable:GetTemplate not find anim table ", nID)
        return 
    end
    local tbNode = tbAnims[szNodeKey]
    if not tbNode then
        logerror("AnimationResDataTable:GetTemplate not find anim table ", szNodeKey)
        return 
    end    
    return tbNode[szKey]
end 
-- [EXPORT END]

return AnimationResDataTable
