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
local DestructibleObjectNewDataTable = {}

DestructibleObjectNewDataTable.szFileName = "common/ffa/destructibleobject/destructibleobjectnew.tab"

local function ParseKey(self, Parser)
    if self.tbKeys == nil then
        local tbCurrentKeys = Parser:GetCurrentKeys()
        local tbKeys = {}
        for szKeyName, nIndex in pairs(tbCurrentKeys) do
            tbKeys[nIndex] = szKeyName
        end
        self.tbKeys = tbKeys
    end
end

function DestructibleObjectNewDataTable:OnEditorDefine(Parser)
    Parser:SetKey("nId")
    Parser:Define("nId",            "id",           -1,     Parser.TypeInt)
    Parser:Define("szRes",          "res",          nil,     Parser.TypeString)
    Parser:Define("szMesh",         "mesh",         nil,     Parser.TypeString)
    Parser:Define("szBreakEffect",  "break_effect", nil,     Parser.TypeString)
    Parser:Define("tbCollisionLocation", "collision_location", nil, Parser.TypeArrayInt)
    Parser:Define("tbCollisionScale",    "collision_scale", nil, Parser.TypeArrayInt)
    Parser:Define("tbInPos",        "in_pos",       nil,    Parser.TypeArrayInt)
    Parser:Define("tbOutPos",       "out_pos",      nil,    Parser.TypeArrayInt)
    Parser:Define("nType",          "type",         0,      Parser.TypeInt)
    Parser:Define("bHit",           "be_hit",       true,   Parser.TypeBool)
    Parser:Define("nMaxHp",         "max_hp",       0,      Parser.TypeInt)   
    -- Parser:Define("nCannonDamage",  "cannon_damage",0,      Parser.TypeInt)
    -- Parser:Define("nBombDamage",    "bomb_damage",  0,      Parser.TypeInt)
    -- Parser:Define("nBulletDamage",  "bullet_damage",0,      Parser.TypeInt)
    -- Parser:Define("nMeleeDamage",   "melee_damage", 0,      Parser.TypeInt)
    -- Parser:Define("nFireDamage",    "fire_damage",  0,      Parser.TypeInt)
    Parser:Define("nBreakSoundId",      "break_sound_id",     0,      Parser.TypeInt)
    Parser:Define("nOpenSoundId",       "open_sound_id",      0,      Parser.TypeInt)
    Parser:Define("nCloseSoundId",      "close_sound_id",     0,      Parser.TypeInt)
end

function DestructibleObjectNewDataTable:OnEditorParseLine(Parser, tbContainer, tbNewTemplate)
    ParseKey(self, Parser)
    local tbLineData = Parser:GetCurrentLineData()
    if #tbLineData ~= #self.tbKeys then
        logerror("DestructibleObjectNewDataTable parse count num is not equal", tbNewTemplate.nId)
        return false
    end

    if tbNewTemplate.tbDamageRate == nil then
        tbNewTemplate.tbDamageRate = {}
    end    
    for i, v in ipairs(self.tbKeys) do
        local nPos = string.find(v, "damage_rate_")
        if nPos then
            local szDamageType = string.sub(v, 13, string.len(v) - nPos + 1)
            local nDamageType = tonumber(szDamageType) 
            if nDamageType == nil then
                logerror("DestructibleObjectNewDataTable damage type is invalid ", v)
                return false
            end

            local nValue = tonumber(tbLineData[i])
            tbNewTemplate.tbDamageRate[nDamageType] = nValue or 0
        end
    end

    return true
end
-- [EXPORT BEGIN]
function DestructibleObjectNewDataTable:GetTemplate(nTemplateId)
    return self.tbContainer[nTemplateId]
end
-- [EXPORT END]

return DestructibleObjectNewDataTable
