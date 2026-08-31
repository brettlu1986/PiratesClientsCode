-----------------------------------------------------
--File Name    : HumanAvatarData.lua
--Author       : WuJizhou
--Create Time  : 4/26/2020, 5:47:45 PM
--Description  : HumanAvatarData
-----------------------------------------------------
local luaclass = require("luaclass")


-- 该data只负责PartType--PartValue层面的数据，产生当前最终的PartType--PartValue数据
local HumanAvatarData = luaclass("HumanAvatarData")

local HumanAvatarDef = require("HumanAvatarDef")
local PartType = HumanAvatarDef.PartType
local PartTypeToProtoFieldName = HumanAvatarDef.PartTypeToProtoFieldName
--{key:HumanAvatarDef.PartType, value: part id/ color id }
HumanAvatarData.tbAppearanceData = nil

--{key:HumanAvatarDef.PartType, value: part id/ color id }
HumanAvatarData.tbBasicFashionData = nil

--{
--  key : HumanArmorDef.ArmorType,
--  value : {
--              key : nArmorLevel,
--              value : {
--                          key:HumanAvatarDef.PartType,
--                          value: part id/ color id
--                      }
--          }
--}
HumanAvatarData.tbArmorFashionData = nil

HumanAvatarData.nCurrentArmorLevel = nil
HumanAvatarData.nCurrentArmorType = nil

HumanAvatarData.tbArmorFashionFlag = nil

local function GetArmorFashionFlag(self)
    local tb = self.tbArmorFashionFlag
    if not tb then
        tb = {}
        self.tbArmorFashionFlag = tb
    end
    return tb
end

local function GetArmorFashionData(self)
    local tbCurData = self.tbArmorFashionData
    if not tbCurData then
        tbCurData = {}
        self.tbArmorFashionData = tbCurData
    end
    return tbCurData
end

local function GetAppearanceData(self)
    local tbCurData = self.tbAppearanceData
    if not tbCurData then
        tbCurData = {}
        self.tbAppearanceData = tbCurData
    end
    return tbCurData
end

local function GetBasicFashionData(self)
    local tbCurData = self.tbBasicFashionData
    if not tbCurData then
        tbCurData = {}
        self.tbBasicFashionData = tbCurData
    end
    return tbCurData
end

local function GetArmorFashionDataByLevelAndType(self, nArmorType, nArmorLevel)
    if not nArmorType or not nArmorLevel then
        return {}
    end
    local tbArmorData = GetArmorFashionData(self)
    local tbSpecificTypeData = tbArmorData[nArmorType]
    if not tbSpecificTypeData then
        return {}
    end
    local tbLevelData = tbSpecificTypeData[nArmorLevel]
    if not tbLevelData then
        return {}
    end
    return tbLevelData
end

local function IsArmorFashionOverrideByBasicFashion(self, nArmorType)
    local tb = GetArmorFashionFlag(self)
    return tb[nArmorType]
end

local function MergePartData(self, fnCheckData, ...)
    local tbResult = {}
    local tbAllCandidateDatas = {...}
    for _, nPartType in pairs(PartType) do
        for _, tbPartData in ipairs(tbAllCandidateDatas) do
            local nPartData = tbPartData[nPartType]
            if fnCheckData(nPartData) then
                tbResult[nPartType] = nPartData
                break
            end
        end
    end
    return tbResult
end

local fnCheckDataExceptAppearance = function (nPartValue)
    if nPartValue and nPartValue >= 0 then
        return true
    else
        return false
    end
end

local fnCheckDataWithAppearance = function (nPartValue)
    if nPartValue and nPartValue > 0 then
        return true
    else
        return false
    end
end

-----------------------public method-----------------------

function HumanAvatarData:SetAppearanceData(tbNewData)
    self.tbAppearanceData = tbNewData
end

function HumanAvatarData:SetBasicFashionData(tbNewData)
    self.tbBasicFashionData = tbNewData
end

function HumanAvatarData:SetArmorFashionData(tbNewData)
    self.tbArmorFashionData = tbNewData
end

function HumanAvatarData:SetArmorType(nArmorType)
    self.nCurrentArmorType = nArmorType
end

function HumanAvatarData:SetArmorLevel(nArmorLevel)
    self.nCurrentArmorLevel = nArmorLevel
end

function HumanAvatarData:SetArmorTypeAndLevel(nArmorType, nArmorLevel)
    self:SetArmorType(nArmorType)
    self:SetArmorLevel(nArmorLevel)
end

function HumanAvatarData:SetArmorFashionFlag(nArmorType, bOverlay)
    local tb = GetArmorFashionFlag(self)
    tb[nArmorType] = bOverlay
end

function HumanAvatarData:SetArmorFashionFlagTable(tbData)
    self.tbArmorFashionFlag = tbData
end


function HumanAvatarData:GetPartDatas()
    local bOverride = IsArmorFashionOverrideByBasicFashion(self, self.nCurrentArmorType)
    -- 根据当前防具的类型和等级，获取防具层的PartData
    local tbArmorPartData
    if bOverride then
        tbArmorPartData = {}
    else
        tbArmorPartData = GetArmorFashionDataByLevelAndType(self, self.nCurrentArmorType, self.nCurrentArmorLevel)
    end
    -- 合并防具层、基础时装层的PartData
    local tbBasicPartData = GetBasicFashionData(self)
    local tbMergedData = MergePartData(self, fnCheckDataExceptAppearance, tbArmorPartData, tbBasicPartData)
    -- 合并初新装层(Appearance)的PartData
    local tbApearancePartData = GetAppearanceData(self)
    tbMergedData = MergePartData(self, fnCheckDataWithAppearance, tbMergedData, tbApearancePartData)
    local tbResult = {}
    for nPartType, nPartValue in pairs(tbMergedData) do
        if nPartValue ~= HumanAvatarDef.PLACE_HOLDER_PART_VALUE_INCLUDE_APPEARANCE then
            tbResult[PartTypeToProtoFieldName[nPartType]] = nPartValue
        end
    end
    return tbResult
end


function HumanAvatarData:ModifyBasicFashionData(tbDeltaData)
    local tbCurData = GetBasicFashionData(self)
    for nPartType, nPartValue in pairs(tbDeltaData) do
        tbCurData[nPartType] = nPartValue
    end
end

function HumanAvatarData:ModifyArmorFashionData(tbDeltaData)
    local tbCurArmorData = GetArmorFashionData(self)
    for nArmorType, tbLevelData in pairs(tbDeltaData) do
        local tbCurLevelData = tbCurArmorData[nArmorType]
        if not tbCurLevelData then
            tbCurLevelData = {}
            tbCurArmorData[nArmorType] = tbCurLevelData
        end
        for nArmorLevel, tbPartData in pairs(tbLevelData) do
            local tbCurPartData = tbCurLevelData[nArmorLevel]
            if not tbCurPartData then
                tbCurPartData = {}
                tbCurLevelData[nArmorLevel] = tbCurPartData
            end
            for nPartType, nPartValue in pairs(tbPartData) do
                tbCurPartData[nPartType] = nPartValue
            end
        end
    end
end


return HumanAvatarData