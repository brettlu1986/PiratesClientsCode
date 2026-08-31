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
local BattleTierRewardDataTable = {}
-- [EXPORT]
BattleTierRewardDataTable.tbAll = {}

BattleTierRewardDataTable.szFileName = "common/season2/battle_pass/battle_tier_reward.tab"

function BattleTierRewardDataTable:OnEditorDefine(Parser)
    Parser:SetKey("nTier")
    Parser:Define("nTier",  "tier", -1, Parser.TypeInt)
    Parser:Define("nWarriorAwardId", "warrior_award_id", -1, Parser.TypeInt)
    Parser:Define("nHeroAwardId", "hero_award_id", -1, Parser.TypeInt)
    Parser:Define("bDefaultSelected", "default_selected", false, Parser.TypeBool)
end

function BattleTierRewardDataTable:OnEditorParseLine(Parser, tbContainer, tbNewTemplate)
    table.insert(self.tbAll, tbNewTemplate)

    return true
end
-- [EXPORT BEGIN]
function BattleTierRewardDataTable:GetTemplate(nTier)
    return self.tbContainer[nTier]
end
-- [EXPORT END]

-- [EXPORT BEGIN]
function BattleTierRewardDataTable:GetContainer()
    return self.tbAll
end
-- [EXPORT END]

-- [EXPORT BEGIN]
function BattleTierRewardDataTable:GetNextSelectedTier(nTier)
    local nMaxDefaultTier = 1
    for i, v in ipairs(self.tbAll) do
        if v.bDefaultSelected then 
            if v.nTier >= nTier then
                return v.nTier
            end
            if v.nTier > nMaxDefaultTier then
                nMaxDefaultTier = v.nTier
            end
        end
    end
    return nMaxDefaultTier
end
-- [EXPORT END]

return BattleTierRewardDataTable
