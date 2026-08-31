local ScheduleTable = {}
local DataTableExporter = require("DataTableExporter")
-- local TimeUtil = require("TimeUtil")
local L10N = require("L10N")

local szCurrentExceptionalParseHelper = nil
local bLoadingSubFile = nil
local szTaskConditionFileName = "common/schedule2/event/condition.tab" 

ScheduleTable.szFileName = "common/schedule2/activity.tab"
ScheduleTable.tbTaskCondition = nil

function ScheduleTable:OnEditorDefine(Parser)
    Parser:SetKey("nId")
    Parser:Define("nId", "id", -1, Parser.TypeInt)
    Parser:Define("szType", "type", nil, Parser.TypeString)
    Parser:Define("szScheduleDataPath", "mission_path", nil, Parser.TypeString)
    Parser:Define("nScheduleDataId", "mission_id", -1, Parser.TypeInt)
    Parser:Define("szTimePath", "time_path", nil, Parser.TypeString)
    Parser:Define("nTimeId", "time_id", -1, Parser.TypeInt)
    Parser:Define("bEnable", "enable", true, Parser.TypeBool)
    Parser:Define("nLevel", "level", 1, Parser.TypeInt)
    Parser:Define("bReset", "reset", false, Parser.TypeBool)
    Parser:Define("szParseFile", "parse_file", nil, Parser.TypeString)
    Parser:Define("szLuaFile", "lua_file", nil, Parser.TypeString)
end

function ScheduleTable:OnEditorParseLine(Parser, tbContainer, tbNewTemplate)
    if tbNewTemplate.szScheduleDataPath == nil or tbNewTemplate.nScheduleDataId < 0 then
        error("Schedule invalid schedule data "..tbNewTemplate.nId)
    end
    if tbNewTemplate.szTimePath == nil or tbNewTemplate.nTimeId < 0 then
        error("Schedule invalid time "..tbNewTemplate.nId)
    end

    return true
end

function ScheduleTable:OnEditorScheduleDefine(Parser)
    Parser:Define("nId", "id", -1, Parser.TypeInt)
end

local function OnEditorParsScheduleLineExceptionalData(self, Parser, tbNewTemplate)
    if szCurrentExceptionalParseHelper ~= nil and szCurrentExceptionalParseHelper ~= "" then
        require(szCurrentExceptionalParseHelper).ParseExceptionalScheduleLine(Parser, tbNewTemplate)
    end    
end

function ScheduleTable:OnEditorParseScheduleLine(Parser, tbContainer, tbNewTemplate)
    OnEditorParsScheduleLineExceptionalData(self, Parser, tbNewTemplate)
    for k, v in pairs(tbContainer) do
        if v.nScheduleDataId == tbNewTemplate.nId and v.szScheduleDataPath == self.szFileName then
            v.tbScheduleData = tbNewTemplate
            break
        end
    end
    
    return true
end

function ScheduleTable:OnEditorTimeDefine(Parser)
    Parser:Define("nId", "id", -1, Parser.TypeInt)
    -- Parser:Define("szStartTime", "start_time", "", Parser.TypeString)
    -- Parser:Define("szStopTime", "stop_time", "", Parser.TypeString)
end

local function OnEditorParseTimeLineExceptionalData(self, Parser, tbNewTemplate)
    if szCurrentExceptionalParseHelper ~= nil and szCurrentExceptionalParseHelper ~= "" then
        require(szCurrentExceptionalParseHelper).ParseExceptionalTimeLine(Parser, tbNewTemplate)
    end    
end

function ScheduleTable:OnEditorParseTimeLine(Parser, tbContainer, tbNewTemplate)
    -- local nStartTime, szError = TimeUtil.GetTimeByString(tbNewTemplate.szStartTime)
    -- if nStartTime == nil then
    --     error("get schedule start time failed! time id:"..tbNewTemplate.nId..", error:"..szError)
    -- end
    -- tbNewTemplate.nStartTime = nStartTime

    -- local nStopTime, szError1 = TimeUtil.GetTimeByString(tbNewTemplate.szStopTime)

    -- if nStopTime == nil then
    --     error("get schedule stop time failed! time id:"..tbNewTemplate.nId..", error:"..szError1)
    -- end
    -- tbNewTemplate.nStopTime = nStopTime

    OnEditorParseTimeLineExceptionalData(self, Parser, tbNewTemplate)
    
    for k, v in pairs(tbContainer) do
        if v.nTimeId == tbNewTemplate.nId and v.szTimePath == self.szFileName then
            v.tbTime = tbNewTemplate
        end
    end

    return true
end

function ScheduleTable:OnEditorTaskDefine(Parser)
    Parser:Define("nId", "id", -1, Parser.TypeInt)
    Parser:Define("nType", "type", -1, Parser.TypeInt)
    Parser:Define("l10nDesc", "desc",    L10N.NullString, Parser.TypeL10N)
    Parser:Define("tbRewards", "reward", {}, Parser.TypeArrayInt)
    Parser:Define("nCondition", "condition", -1, Parser.TypeInt)
end

local function OnEditorParseTaskExceptionalData(self, Parser, tbScheduleTemplate, tbTaskTemplate)
    szCurrentExceptionalParseHelper = tbScheduleTemplate.szParseFile
    if szCurrentExceptionalParseHelper ~= nil and szCurrentExceptionalParseHelper ~= "" then
        require(szCurrentExceptionalParseHelper).ParseExceptionalTaskLine(Parser, tbScheduleTemplate, tbTaskTemplate)
    end    
end

function ScheduleTable:OnEditorParseTaskLine(Parser, tbContainer, tbNewTemplate)
    for k, v in pairs(tbContainer) do
        if v.tbScheduleData ~= nil and v.tbScheduleData.tbTaskIds ~= nil then
            for i, nTaskId in ipairs(v.tbScheduleData.tbTaskIds) do
                if nTaskId == tbNewTemplate.nId and v.tbScheduleData.szTaskPath == self.szFileName then
                    if v.tbTask == nil then
                        v.tbTask = {}
                    end
                    OnEditorParseTaskExceptionalData(self, Parser, v, tbNewTemplate)
                    
                    table.insert(v.tbTask, tbNewTemplate)
                end
            end
        end
    end

    return true
end

function ScheduleTable:OnEditorTaskConditionDefine(Parser)
    Parser:Define("nId", "id", -1, Parser.TypeInt)
    Parser:Define("nFactor1", "factor_1", 0, Parser.TypeInt)
    Parser:Define("nFactor2", "factor_2", 0, Parser.TypeInt)
    Parser:Define("nFactor3", "factor_3", 0, Parser.TypeInt)
end

function ScheduleTable:OnEditorParseTaskConditionLine(Parser, tbContainer, tbNewTemplate)
    local fnGetTaskTemps = function(tbScheduleTemp, nId)
        local tbTask = tbScheduleTemp.tbTask
        if tbTask == nil then
            return
        end
        local tbResults = {}
        for i, v in ipairs(tbTask) do
            if v.nCondition == tbNewTemplate.nId then
                table.insert(tbResults, v)
            end           
        end
        return tbResults
    end

    for k, v in pairs(tbContainer) do
        if v.tbScheduleData ~= nil and v.tbScheduleData.tbClientTaskIds ~= nil then
            for i, tbTaskIds in ipairs(v.tbScheduleData.tbClientTaskIds) do
                local tbTaskTemps = fnGetTaskTemps(v, tbNewTemplate.nId)
                if tbTaskTemps ~= nil then
                    for nIndex, tbTaskTemp in ipairs(tbTaskTemps) do
                        tbTaskTemp.tbCondition = tbNewTemplate
                    end
                end
            end
        end
    end

    return true    
end

function ScheduleTable:OnEditorParseFinished()
    if bLoadingSubFile then
        return
    end
    
    local szOldPath = self.szFileName
    bLoadingSubFile = true
    local fnOldDefine = self.OnEditorDefine

    for k, v in pairs(self.tbContainer) do
        -- 
        self.szFileName = v.szScheduleDataPath                                       
        self.OnEditorDefine = self.OnEditorScheduleDefine
        self.OnEditorParseLine = self.OnEditorParseScheduleLine
        szCurrentExceptionalParseHelper = v.szParseFile
        if not DataTableExporter:Load(self) then
            logerror("ScheduleTable load sub table failed", self.szFileName)
            assert(false)
        end
        
        -- 
        self.szFileName = v.szTimePath
        self.OnEditorDefine = self.OnEditorTimeDefine
        self.OnEditorParseLine = self.OnEditorParseTimeLine
        if not DataTableExporter:Load(self) then
            logerror("ScheduleTable load time table failed", self.szFileName)
            assert(false)
        end
    end

    local tbTaskPaths = {}
    for k, v in pairs(self.tbContainer) do
        if v.tbScheduleData ~= nil and v.tbScheduleData.szTaskPath ~= nil and v.tbScheduleData.tbTaskIds ~= nil then
            table.insert(tbTaskPaths, v.tbScheduleData.szTaskPath)
        end
    end
    for i, v in ipairs(tbTaskPaths) do
        self.szFileName = v
        self.OnEditorDefine = self.OnEditorTaskDefine
        self.OnEditorParseLine = self.OnEditorParseTaskLine
        if not DataTableExporter:Load(self) then
            logerror("ScheduleTable load task table failed", self.szFileName)
            assert(false)
        end
    end

    for k, v in pairs(self.tbContainer) do
        if v.tbScheduleData ~= nil and v.tbScheduleData.tbTaskIds ~= nil then
            if v.tbTask == nil or #v.tbScheduleData.tbTaskIds ~= #v.tbTask then
                logerror("schedule task data is invalid ", v.tbScheduleData.szTaskPath, v.nId, #v.tbScheduleData.tbTaskIds, v.tbTask and #v.tbTask)
                assert(false)
            end
        end
    end

    -- tast condition
    self.szFileName = szTaskConditionFileName
    self.OnEditorDefine = self.OnEditorTaskConditionDefine
    self.OnEditorParseLine = self.OnEditorParseTaskConditionLine
    self.tbTaskCondition = {}
    if not DataTableExporter:Load(self) then
        logerror("ScheduleTable load task condition table failed", self.szFileName)
        assert(false)
    end

    bLoadingSubFile = false
    self.OnEditorDefine = fnOldDefine
    self.szFileName = szOldPath
end

-- [EXPORT BEGIN]
function ScheduleTable:GetTemplate(nId)
    return self.tbContainer[nId]
end
-- [EXPORT END]

-- [EXPORT BEGIN]
function ScheduleTable:GetTemplateByType(szType)
    for k, v in pairs(self.tbContainer) do
        if v.szType == szType then
            return v
        end
    end
end
-- [EXPORT END]

return ScheduleTable