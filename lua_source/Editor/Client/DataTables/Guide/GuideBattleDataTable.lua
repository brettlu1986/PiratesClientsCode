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

local GuideBattleDataTable = {}

GuideBattleDataTable.szFileName = "client/guide/guide_battle.tab"
GuideBattleDataTable.bEnableIterateKey = true
-- [EXPORT]
GuideBattleDataTable.tbModuleContainer = {}

function GuideBattleDataTable:OnEditorDefine(Parser)
    Parser:Define("nStep", "step", -1, Parser.TypeInt)
    Parser:Define("nGroup", "group", -1, Parser.TypeInt)
    Parser:Define("nModuleId", "module_id", -1, Parser.TypeInt)
    Parser:Define("tbOpenModuleId", "module_open", nil, Parser.TypeArrayInt)
    Parser:Define("tbEndModuleId", "module_end", nil, Parser.TypeArrayInt)
    Parser:Define("bIsModal", "is_modal", true, Parser.TypeBool, false)
    Parser:Define("nDelayResponseTime", "delay_response_time", nil, Parser.TypeInt, false)
    Parser:Define("tbTriggerKey", "trigger_key", "", Parser.TypeArrayString)
    Parser:Define("tbActionKey", "action_key", "", Parser.TypeArrayString)
    Parser:Define("nAlwaysTrigger", "always_trigger", 1, Parser.TypeInt, false)
    Parser:Define("bDefensive", "defensive", true, Parser.TypeBool, false)
    Parser:Define("nGuideType", "guide_type", 1, Parser.TypeInt, false)
    Parser:Define("bInQueue", "in_queue", false, Parser.TypeBool, false)
    Parser:Define("bInterrupt", "interrupt", false, Parser.TypeBool, false)
    Parser:Define("szDesc", "desc", "", Parser.TypeString, false)
end

function GuideBattleDataTable:OnEditorParseLine(Parser, tbContainer, tbNewTemplate)
    local nModuleId = tbNewTemplate.nModuleId
    local tbModuleContainer = self.tbModuleContainer
    local tbModule = tbModuleContainer[nModuleId]
    if not tbModule then
        tbModule = {}
        tbModuleContainer[nModuleId] = tbModule
    end
    local nGroup = tbNewTemplate.nGroup
    local tbGroup = tbModule[nGroup]
    if(not tbGroup)then
        tbGroup = {}
        tbModule[nGroup] = tbGroup
    end
    tbGroup[tbNewTemplate.nStep] = tbNewTemplate
    return true
end

function GuideBattleDataTable:OnEditorParseFinished()
    
end

-- [EXPORT BEGIN]
function GuideBattleDataTable:GetModuleGroups(nModuleId)
    if(self.tbModuleContainer[nModuleId] == nil)then
        return nil
    end
    return self.tbModuleContainer[nModuleId]
end
-- [EXPORT END]

-- [EXPORT BEGIN]
function GuideBattleDataTable:GetGroupType(nModuleId, nGroupId)
    local tbModule = self.tbModuleContainer[nModuleId]
    if(tbModule == nil)then
        return -1
    end
    local tbGroup = tbModule[nGroupId]
    if not tbGroup then
        return -1
    end
    return tbGroup[1].nGuideType
end
-- [EXPORT END]

-- [EXPORT BEGIN]
function GuideBattleDataTable:GetGroupIsInQueue(nModuleId, nGroupId)
    local tbModule = self.tbModuleContainer[nModuleId]
    if(tbModule == nil)then
        return false
    end
    local tbGroup = tbModule[nGroupId]
    if not tbGroup then
        return false
    end
    return tbGroup[1].bInQueue
end
-- [EXPORT END]

-- [EXPORT BEGIN]
function GuideBattleDataTable:GetModules(tbModuleAndGroup)
    local tbModuleContainer = self.tbModuleContainer
    if not tbModuleContainer then
        return nil
    end
    local tbModuleData = {}
    for nModuleId, tbGroups in pairs(tbModuleAndGroup) do
        nModuleId = tonumber(nModuleId)
        for nIndex, nGroupId in pairs(tbGroups) do
            nGroupId = tonumber(nGroupId)
            if tbModuleContainer[nModuleId] and tbModuleContainer[nModuleId][nGroupId] then
                if not tbModuleData[nModuleId] then
                    tbModuleData[nModuleId] = {}
                end
                tbModuleData[nModuleId][nGroupId] = tbModuleContainer[nModuleId][nGroupId]
            end
        end 
    end
    return tbModuleData
end
-- [EXPORT END]

-- [EXPORT BEGIN]
function GuideBattleDataTable:GetAllModules()
    local tbModuleContainer = self.tbModuleContainer
    if not tbModuleContainer then
        return nil
    end
    return tbModuleContainer
end
-- [EXPORT END]

-- [EXPORT BEGIN]
function GuideBattleDataTable:GetAllSteps()
    return self.tbContainer
end
-- [EXPORT END]

return GuideBattleDataTable