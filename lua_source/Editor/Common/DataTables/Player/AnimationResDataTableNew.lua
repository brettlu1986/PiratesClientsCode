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

local DataTableExporter = require("DataTableExporter")
local AnimDef = require("AnimDef")

local AnimationResDataTableNew = {}

AnimationResDataTableNew.szFileName = "common/ffa/animation/index.tab"
AnimationResDataTableNew.tbSubTable = {}
AnimationResDataTableNew.bLoadingSubFile = false
-- [EXPORT BEGIN]
local DEFAULT_STATE_ID = 1
local DEFAULT_EQUIP_ID = 1
AnimationResDataTableNew.tbWeaponTable = {}
AnimationResDataTableNew.tbWeaopnCategoryTable = {}
-- [EXPORT END]

function AnimationResDataTableNew:OnEditorSubTableDefine(Parser)
    Parser:Define("nId", "id", -1, Parser.TypeInt)
    Parser:Define("nEquipId", "equip_id", DEFAULT_EQUIP_ID, Parser.TypeInt, false)
    Parser:Define("szKey", "anim_key", nil, Parser.TypeString)
    Parser:Define("nStateId", "state_id", DEFAULT_STATE_ID, Parser.TypeInt)    
    Parser:Define("tbWeaponIds", "weapon_id", nil, Parser.TypeArrayInt)
    Parser:Define("tbWeaponCategorys", "weapon_category", nil, Parser.TypeArrayInt)
    Parser:Define("szNodeKey", "node_key", nil, Parser.TypeString)
    Parser:Define("szAnimation", "anim_class_name", "", Parser.TypeString)
    Parser:Define("szRootMotion", "root_motion_path", nil, Parser.TypeString)
end

local function OnEditorParseSubTableLine(self, Parser, tbContainer, tbNewTemplate)
    if not tbNewTemplate.szKey   then 
        return true
    end 

    -- local szKey = "Anim" .. tbNewTemplate.nId .. tbNewTemplate.szKey .. tbNewTemplate.nStateId
    local szKey = tbNewTemplate.szKey .. tbNewTemplate.nId .. tbNewTemplate.nEquipId
    -- local szKey = tbNewTemplate.szKey .. tbNewTemplate.nId 
    if not self.tbContainer[szKey] then
        tbContainer[szKey] = {}
    end     

    if tbNewTemplate.szRootMotion then 
        local pMontage = tbNewTemplate.szAnimation:load()
        local nEndRootMotionSectionTime = ExtendBlueprintFunctions.GetMontageSectionStartEndTime(pMontage, AnimDef.SectionName.END_ROOTMOTION_TIME)

        local tbOutPosition = ExtendBlueprintFunctions.ExportRootMotion(tbNewTemplate.szRootMotion:load(), nEndRootMotionSectionTime)
        tbNewTemplate.tbRootMotion = {}
        for i,v in ipairs(tbOutPosition) do
            table.insert(tbNewTemplate.tbRootMotion, {X=v.X-v.X%0.01, Y=v.Y-v.Y%0.01, Z=v.Z-v.Z%0.01 })
        end

        tbNewTemplate.fEndRootMotionTime = nEndRootMotionSectionTime
        tbNewTemplate.fRootMotionStartCorrectTime = 0.0
        local szStartCorrectSection = AnimDef.SectionName.ROOTMOTION_STARTPOS_CORRECTION

        local _, nStartSectionEndTime = ExtendBlueprintFunctions.GetMontageSectionStartEndTime(pMontage, szStartCorrectSection)
        if nStartSectionEndTime and nStartSectionEndTime > 0 then
            tbNewTemplate.fRootMotionStartCorrectTime = nStartSectionEndTime
        end

        tbNewTemplate.tbRootMotionCorrectSectionTimeRange = {}
        local szCurCorrectSection = AnimDef.SectionName.ROOTMOTION_FINALPOS_CORRECTION

        local nSectionStartTime, nSectionEndTime = ExtendBlueprintFunctions.GetMontageSectionStartEndTime(pMontage, szCurCorrectSection)

        if nSectionStartTime and nSectionEndTime and nSectionStartTime >= 0 and nSectionEndTime > 0 then
            table.insert(tbNewTemplate.tbRootMotionCorrectSectionTimeRange, nSectionStartTime)
            table.insert(tbNewTemplate.tbRootMotionCorrectSectionTimeRange, nSectionEndTime)
        end

        --todo 攀爬动画目前有些歪，先通过这里修正下数据，新动画上后，这里注释掉
        if tbNewTemplate.fRootMotionStartCorrectTime > 0.0 then
            local FirstZ = tbNewTemplate.tbRootMotion[1].Z
            for _, tbCurPos in pairs(tbNewTemplate.tbRootMotion) do
                tbCurPos.Y = 0

                if tbCurPos.Z < FirstZ then
                    tbCurPos.Z = FirstZ
                end
            end
        end

        tbNewTemplate.szRootMotion = nil 
    end

    table.insert(tbContainer[szKey], tbNewTemplate)
    

    -- 预加载动作用
    if tbNewTemplate.tbWeaponIds  then
        local nId = tbNewTemplate.nId
        if not self.tbWeaponTable[nId] then
            self.tbWeaponTable[nId] = {}
        end
        local tbWeaponTable = self.tbWeaponTable[nId]
        for i, v in ipairs(tbNewTemplate.tbWeaponIds) do
            if not tbWeaponTable[v] then
                tbWeaponTable[v] = {}
            end 
            table.insert(tbWeaponTable[v], tbNewTemplate.szAnimation)
        end
    end

    if tbNewTemplate.tbWeaponCategorys then
        local nId = tbNewTemplate.nId
        if not self.tbWeaopnCategoryTable[nId] then
            self.tbWeaopnCategoryTable[nId] = {}
        end
        local tbWeaopnCategoryTable = self.tbWeaopnCategoryTable[nId]
        for i, v in ipairs(tbNewTemplate.tbWeaponCategorys) do
            if not tbWeaopnCategoryTable[v] then
                tbWeaopnCategoryTable[v] = {}
            end
            table.insert(tbWeaopnCategoryTable[v], tbNewTemplate.szAnimation)
        end
    end

    return true;
end


function AnimationResDataTableNew:OnEditorDefine(Parser)
    Parser:Define("szPath", "path", nil, Parser.TypeString)
end

function AnimationResDataTableNew:OnEditorParseLine(Parser, tbContainer, tbNewTemplate)
    if(self.bLoadingSubFile) then
        return OnEditorParseSubTableLine(self, Parser, tbContainer, tbNewTemplate)
    end

    table.insert(self.tbSubTable, tbNewTemplate)
    return true;
end

function AnimationResDataTableNew:OnEditorParseFinished()
    if(self.bLoadingSubFile) then
        return
    end

    local szOldPath = self.szFileName
    self.bLoadingSubFile = true
    local fnOldDefine = self.OnEditorDefine

    local tbData
    local tbDatas = self.tbSubTable
    local nCount = #tbDatas
    for i=1, nCount do
        tbData = tbDatas[i]
        self.szFileName = tbData.szPath

        self.OnEditorDefine = self.OnEditorSubTableDefine
        if(not DataTableExporter:Load(self)) then
            logerror("NPCDataTable load sub table failed", self.szFileName)
            assert(false)
            return
        end
    end

    self.bLoadingSubFile = false
    self.szFileName = szOldPath
    self.tbSubTable = {}

    self.OnEditorDefine = fnOldDefine
end

-- [EXPORT BEGIN]

local function ToVector(tbIn)
    return Vector{X = tbIn.X, Y = tbIn.Y, Z = tbIn.Z}
end

local function TransformTemplate(tbTemplate)
    if not tbTemplate then  
        return nil
    end 

    if tbTemplate.tbRootMotion then 
        tbTemplate.tbRootMotionVectors = {}
        for i,v in ipairs(tbTemplate.tbRootMotion) do
            table.insert(tbTemplate.tbRootMotionVectors, ToVector(v))
        end
        tbTemplate.tbRootMotion = nil 
    end

    return tbTemplate
end 

function AnimationResDataTableNew:GetTemplate(tbParams)
    local nTemplateId = tbParams.nTemplateId
    local szKey = tbParams.szAnimKey
    local nStateId = tbParams.nStateId
    local nArmorTemplatedId = tbParams.nArmorId
    local nWeaponCategory = tbParams.nWeaponCategory
    local nWeaponId = tbParams.nWeaponId
    local nDefaultTemplateId = tbParams.nDefaultTemplateId
    local bUsedDefaultArmorId = false
    if (not nArmorTemplatedId or nArmorTemplatedId <= 0) and nArmorTemplatedId ~= DEFAULT_EQUIP_ID then 
        nArmorTemplatedId = DEFAULT_EQUIP_ID
        bUsedDefaultArmorId = true
    end 
    local szAnimKey = szKey .. nTemplateId ..  nArmorTemplatedId
    local tbTemplates = self.tbContainer[szAnimKey]

    if not bUsedDefaultArmorId and not tbTemplates and nArmorTemplatedId ~= DEFAULT_EQUIP_ID then  
        szAnimKey = szKey .. nTemplateId ..  DEFAULT_EQUIP_ID
        tbTemplates = self.tbContainer[szAnimKey]
    end

    if not tbTemplates then 
        if nDefaultTemplateId ~= nil and nDefaultTemplateId ~= tbParams.nTemplateId then 
            tbParams.nTemplateId = nDefaultTemplateId
            tbParams.nDefaultTemplateId = nil 
            return self:GetTemplate(tbParams)
        else 
            return nil
        end
    end 

    local tbStateRes = {}
    for i,v in ipairs(tbTemplates) do
        if v.nStateId == nStateId  then 
            table.insert(tbStateRes, 1, v)
        elseif v.nStateId == DEFAULT_STATE_ID then 
            table.insert(tbStateRes, v)
        end
    end

    local tbRes = {}
    -- 找到匹配武器类型的动作
    for _,v in ipairs(tbStateRes) do
        if not v.tbWeaponCategorys then  
            table.insert(tbRes, v)
        else   
            for _, nWeaponCategoryTemp in ipairs(v.tbWeaponCategorys) do
                if not nWeaponCategoryTemp or nWeaponCategoryTemp == 0 or nWeaponCategoryTemp == nWeaponCategory then  
                    table.insert(tbRes, 1, v)
                end 
            end
        end
    end

    local tbTemplate = nil 
    -- 找到匹配武器id的动作
    for _,v in ipairs(tbRes) do
        if not v.tbWeaponIds then  
            if not tbTemplate then 
                tbTemplate = v  
            end
        else  
            for _, nWeaponIdTemp in ipairs(v.tbWeaponIds) do
                if not nWeaponIdTemp or nWeaponIdTemp == 0 or nWeaponIdTemp == nWeaponId then  
                    return TransformTemplate(v)
                end 
            end
        end 
    end    

    if not tbTemplate then 
        if nDefaultTemplateId ~= nil and nDefaultTemplateId ~= tbParams.nTemplateId then 
            tbParams.nTemplateId = nDefaultTemplateId
            tbParams.nDefaultTemplateId = nil 
            return self:GetTemplate(tbParams)
        elseif tbParams.nArmorId ~= DEFAULT_EQUIP_ID then 
            tbParams.nArmorId = DEFAULT_EQUIP_ID
            return self:GetTemplate(tbParams)            
        else 
            return nil
        end
    end 

    return TransformTemplate(tbTemplate)

end
-- [EXPORT END]

-- [EXPORT BEGIN]
function AnimationResDataTableNew:GetWeaponRes(nId, nWeaponId)
    local tbTemplate = self.tbWeaponTable[nId]
    if not tbTemplate then
        log("AnimationResDataTable:GetWeaponRes not find anim table ", nId)
        return
    end
    return tbTemplate[nWeaponId]
end
-- [EXPORT END]

-- [EXPORT BEGIN]
function AnimationResDataTableNew:GetWeaponCategoryRes(nId, nCategory)
    local tbTemplate = self.tbWeaopnCategoryTable[nId]
    if not tbTemplate then
        log("AnimationResDataTable:GetWeaponCategoryRes not find anim table ", nId)
        return
    end
    return tbTemplate[nCategory]
end
-- [EXPORT END]

return AnimationResDataTableNew