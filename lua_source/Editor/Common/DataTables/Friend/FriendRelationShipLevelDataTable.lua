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
local FriendRelationShipLevelDataTable = {}

-- [EXPORT BEGIN]
local MIN_RELATION_TYPE = 1
local MAX_RELATION_TYPE = 4
local UP_TOMAX_LEVEL = -1
-- [EXPORT END]

local L10N = require("L10N")

FriendRelationShipLevelDataTable.szFileName = "common/friend2/friend_relationship_level.tab"

function FriendRelationShipLevelDataTable:OnEditorDefine(Parser)
    Parser:SetKey("nId")
    Parser:Define("nId", "id", -1, Parser.TypeInt)
    Parser:Define("nRelationType", "relationship", -1, Parser.TypeInt)
    Parser:Define("nLevel", "level", -1, Parser.TypeInt)
    Parser:Define("l10nName", "desc", L10N.NullString, Parser.TypeL10N)
    Parser:Define("nIntimacyLimit", "intimacy_points_limit", -1, Parser.TypeInt)
    Parser:Define("nAwardId", "award_id", -1, Parser.TypeInt)
    Parser:Define("nUpgradeId", "upgrade_id", -1, Parser.TypeInt)
end

-- [EXPORT BEGIN]
local function GetId(nType, nLevel)
    return nType * 100 + nLevel
end 

function FriendRelationShipLevelDataTable:GetDataTemplate(nType, nLevel)
    return self.tbContainer[GetId(nType, nLevel)]
end

function FriendRelationShipLevelDataTable:GetNextLevelIntimacy(nType, nLevel)
    local tbTemplate = self:GetDataTemplate(nType, nLevel)
    local nNextLevelId = tbTemplate.nUpgradeId
    if nNextLevelId == UP_TOMAX_LEVEL then  
        return tbTemplate.nIntimacyLimit
    end
    local tbNextTemplate = self.tbContainer[nNextLevelId]
    return tbNextTemplate.nIntimacyLimit
end

function FriendRelationShipLevelDataTable:CanHaveRelation(nRefIntimacy)
    local tbMinLimits = {}
    for i = MIN_RELATION_TYPE, MAX_RELATION_TYPE do   
        local nMin = 0
        for idx, v in pairs(self.tbContainer) do 
            if i == v.nRelationType then  
                if nMin == 0 then  
                    nMin = v.nIntimacyLimit
                end
                if v.nIntimacyLimit < nMin then  
                    nMin = v.nIntimacyLimit
                end
            end
        end
        if nMin ~= 0 then
            table.insert(tbMinLimits, nMin)
        end
    end

    local bHas = false
    for _, v in ipairs(tbMinLimits) do  
        if nRefIntimacy >= v then  
            bHas = true
            break
        end
    end
    return bHas
end
-- [EXPORT END]


return FriendRelationShipLevelDataTable
