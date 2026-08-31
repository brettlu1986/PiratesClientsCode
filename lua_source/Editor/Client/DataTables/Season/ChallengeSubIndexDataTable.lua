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
local L10N = require("L10N")
local DataTableExporter = require("DataTableExporter")
local ChallengeSubIndexDataTable = {}

local bLoadingSubFile = false
local nCurType = nil

ChallengeSubIndexDataTable.szFileName = "common/season2/challenge/challenge_sub_index.tab"

-- [EXPORT]
ChallengeSubIndexDataTable.tbOwnerContainer = nil

-- [EXPORT BEGIN]
local CHALLENGE_DAILY = 0
local CHALLENGE_WEELY = 1
local CHALLENGE_SEASONAL = 2

local CHALLENGE_TYPE = {
    ["DAILY"] = CHALLENGE_DAILY,
    ["WEEKLY"] = CHALLENGE_WEELY,
    ["SEASONAL"] = CHALLENGE_SEASONAL
}
-- [EXPORT END]

function ChallengeSubIndexDataTable:OnEditorDefine(Parser)
    Parser:Define("szType", "type", "", Parser.TypeString)
    Parser:Define("szPath", "path", "", Parser.TypeString)
    Parser:Define("szAwardPath", "award_path", nil, Parser.TypeString)
    Parser:Define("szOwnerPath", "owner_path", nil, Parser.TypeString)    
end

function ChallengeSubIndexDataTable:OnEditorParseLine(Parser, tbContainer, tbNewTemplate)
    local nType = CHALLENGE_TYPE[tbNewTemplate.szType] 
    tbNewTemplate.nType = nType
    self.tbContainer[nType] = tbNewTemplate
    return true
end

function ChallengeSubIndexDataTable:OnEditorSubTableDefine(Parser)
    Parser:Define("nSubId", "id", -1, Parser.TypeInt)
    Parser:Define("nObjectiveEnd", "objective_end", -1, Parser.TypeInt)
    Parser:Define("l10nDesc", "desc",    L10N.NullString, Parser.TypeL10N)
    Parser:Define("nAwardId", "award_id", -1, Parser.TypeInt)
end

function ChallengeSubIndexDataTable:OnEditorParseSubLine(Parser, tbContainer, tbNewTemplate)
    self.tbContainer[nCurType][tbNewTemplate.nSubId] = tbNewTemplate 
    return true
end

function ChallengeSubIndexDataTable:OnEditorOwnerTableDefine(Parser)
    Parser:Define("nId", "id", -1, Parser.TypeInt)
    Parser:Define("nWeeklyId", "weekly_id", -1, Parser.TypeInt)
    Parser:Define("nSubId", "sub_id", -1, Parser.TypeInt)
end

function ChallengeSubIndexDataTable:OnEditorParseOwnerLine(Parser, tbContainer, tbNewTemplate)    
    if self.tbContainer[nCurType][tbNewTemplate.nSubId].tbOwner == nil then 
        self.tbContainer[nCurType][tbNewTemplate.nSubId].tbOwner = {}  
    end

    local nOwnerId = tbNewTemplate.nWeeklyId
    self.tbContainer[nCurType][tbNewTemplate.nSubId].tbOwner[nOwnerId] = true

    if self.tbOwnerContainer == nil then
        self.tbOwnerContainer = {}
    end
    if self.tbOwnerContainer[nCurType] == nil then
        self.tbOwnerContainer[nCurType] = {}
    end
    if self.tbOwnerContainer[nCurType][nOwnerId] == nil then
        self.tbOwnerContainer[nCurType][nOwnerId] = {}
        self.tbOwnerContainer[nCurType][nOwnerId].tbContainer = {}
    end
    table.insert(self.tbOwnerContainer[nCurType][nOwnerId].tbContainer, tbNewTemplate)
    return true
end

function ChallengeSubIndexDataTable:OnEditorOwnerAwardTableDefine(Parser)
    Parser:Define("nOwnerId", "id", -1, Parser.TypeInt)
    Parser:Define("l10nDesc", "desc",    L10N.NullString, Parser.TypeL10N)
    Parser:Define("nAwardId", "award_id", -1, Parser.TypeInt)
end

function ChallengeSubIndexDataTable:OnEditorParseOwnerAwardLine(Parser, tbContainer, tbNewTemplate)
    self.tbOwnerContainer[nCurType][tbNewTemplate.nOwnerId].nAwardId = tbNewTemplate.nAwardId
    self.tbOwnerContainer[nCurType][tbNewTemplate.nOwnerId].l10nDesc = tbNewTemplate.l10nDesc

    return true
end

function ChallengeSubIndexDataTable:OnEditorParseFinished()
    if bLoadingSubFile then
        return
    end
    local szOldPath = self.szFileName
    bLoadingSubFile = true
    local fnOldDefine = self.OnEditorDefine
    local fnOldParseLine = self.OnEditorParseLine

    for k, v in pairs(self.tbContainer) do
        self.szFileName = v.szPath
        self.OnEditorDefine = self.OnEditorSubTableDefine
        self.OnEditorParseLine = self.OnEditorParseSubLine
        nCurType = v.nType
        if not DataTableExporter:Load(self) then
            error("ChallengeSubIndexDataTable load sub table failed".. self.szFileName)
        end
        if v.szOwnerPath ~= nil then
            self.szFileName = v.szOwnerPath
            self.OnEditorDefine = self.OnEditorOwnerTableDefine
            self.OnEditorParseLine = self.OnEditorParseOwnerLine
            if not DataTableExporter:Load(self) then
                error("ChallengeSubIndexDataTable load owner table failed".. self.szFileName)
            end
        end
        if v.szAwardPath ~= nil then
            self.szFileName = v.szAwardPath
            self.OnEditorDefine = self.OnEditorOwnerAwardTableDefine
            self.OnEditorParseLine = self.OnEditorParseOwnerAwardLine
            if not DataTableExporter:Load(self) then
                error("ChallengeSubIndexDataTable load owner award table failed".. self.szFileName)
            end
        end
    end  

    bLoadingSubFile = false
    self.OnEditorDefine = fnOldDefine
    self.OnEditorParseLine = fnOldParseLine
    self.szFileName = szOldPath
end

-- [EXPORT BEGIN]
function ChallengeSubIndexDataTable:GetTemplate(nType, nId)
    if self.tbContainer[nType] then
        return self.tbContainer[nType][nId]
    end
end
-- [EXPORT END]

-- [EXPORT BEGIN]
function ChallengeSubIndexDataTable:GetTypeTemplate(nType)
    return self.tbContainer[nType]
end
-- [EXPORT END]

-- [EXPORT BEGIN]
function ChallengeSubIndexDataTable:GetOwnerAward(nType, nOwnerId)
    if self.tbOwnerContainer and self.tbOwnerContainer[nType] and self.tbOwnerContainer[nType][nOwnerId] then
        return self.tbOwnerContainer[nType][nOwnerId].nAwardId
    end
end
-- [EXPORT END]

-- [EXPORT BEGIN]
function ChallengeSubIndexDataTable:GetOwnerTemplate(nType, nOwnerId)
    if self.tbOwnerContainer and self.tbOwnerContainer[nType] then
        return self.tbOwnerContainer[nType][nOwnerId]
    end
end
-- [EXPORT END]

return ChallengeSubIndexDataTable
