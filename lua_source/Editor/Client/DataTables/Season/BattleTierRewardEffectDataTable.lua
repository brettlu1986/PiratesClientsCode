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
local BattleTierRewardEffectDataTable = {}

BattleTierRewardEffectDataTable.szFileName = "client/season2/battle_pass/battle_tier_reward_effect.tab"

-- [EXPORT BEGIN]
local WARRIOR_REWARD = 1
local HERO_REWARD = 2

local REWARD_TYPE = {
    ["WARRIOR"] = WARRIOR_REWARD,
    ["HERO"] = HERO_REWARD
}
-- [EXPORT END]

function BattleTierRewardEffectDataTable:OnEditorDefine(Parser)
    Parser:Define("nTier",  "tier", -1, Parser.TypeInt)
    Parser:Define("nIndex", "index", -1, Parser.TypeInt)
    Parser:Define("szType", "type", "", Parser.TypeString)
    Parser:Define("nEffect","effect", 0, Parser.TypeInt)
end

function BattleTierRewardEffectDataTable:OnEditorParseLine(Parser, tbContainer, tbNewTemplate)
    local nType = REWARD_TYPE[tbNewTemplate.szType] 
    if nType == nil then
        error("BattleTierRewardEffectDataTable reward type is invalid ", tbNewTemplate.nTier, tbNewTemplate.szType)
        return
    end
    tbNewTemplate.nType = nType
    
    local tbAwardEffect = self.tbContainer[tbNewTemplate.nTier]
    if tbAwardEffect == nil then
        tbAwardEffect = {[WARRIOR_REWARD] = {}, [HERO_REWARD] = {}}
        self.tbContainer[tbNewTemplate.nTier] = tbAwardEffect 
    end

    table.insert(tbAwardEffect[tbNewTemplate.nType], tbNewTemplate)

    return true
end

-- [EXPORT BEGIN]
function BattleTierRewardEffectDataTable:GetWarriorAwardEffectTemplate(nTier)
    if self.tbContainer[nTier] then
        return self.tbContainer[nTier][WARRIOR_REWARD]
    end
end
-- [EXPORT END]

-- [EXPORT BEGIN]
function BattleTierRewardEffectDataTable:GetHeroAwardEffectTemplate(nTier)
    if self.tbContainer[nTier] then
        return self.tbContainer[nTier][HERO_REWARD]
    end
end
-- [EXPORT END]

return BattleTierRewardEffectDataTable
