local luaclass = require("luaclass")
local GameComponentBaseClass = require("GameComponentBase")
local PropertyComboComponent = luaclass("PropertyComboComponent", GameComponentBaseClass)

local PropertyWrapperType = require("PropertyWrapperType")
local ItemDataTable = require("ItemDataTable")
local PropertyComboSystem = require("PropertyComboSystem")
-- local PartnerRelationDataTable = require("PartnerRelationDataTable")
local PropertyComboOperationTypeDef = require("PropertyComboOperationTypeDef")
local LandmarkBuildingUpgradeDataTable = require("LandmarkBuildingUpgradeDataTable")

local PROP_OVERLAP_TYPE = {
    [PropertyComboOperationTypeDef.PLUS] = PropertyWrapperType.TYPE_ADD,
    [PropertyComboOperationTypeDef.MULTIPLY] = PropertyWrapperType.TYPE_MULTIPLY
}

PropertyComboComponent.nPropComboOverlapIdTop = 1
PropertyComboComponent.tbPropComboOverlapMap = nil

local function GetComponent(self, nComponentType)
    local P = PropertyComboSystem.PROP_COMPONENT_TYPE
    if nComponentType == P.HUMAN then
        return self.Owner.HumanBattlePropertyComponent
    elseif nComponentType == P.SHIP then
        return self.Owner.ShipBattlePropertyComponent
    end
end

local function AddPropComboToComponent(self, tPropertyComboMap)
    log("[AddPropComboToComponent] tPropertyComboMap", t2s(tPropertyComboMap))
    local tbOverlapInfo = {}
    local tbPropertyComboProperties = PropertyComboSystem:GetMultiPropertyComboProperties(tPropertyComboMap)
    log("[AddPropComboToComponent] tbPropertyComboProperties", t2s(tbPropertyComboProperties))
    for szKey, tbProperties in pairs(tbPropertyComboProperties) do
        local tbProperty = PropertyComboSystem:GetPropRegisterInfo(szKey)
        if tbProperty then
            for nOperation, nValue in pairs(tbProperties) do
                local tbRegisterInfo = tbProperty[nOperation]
                if tbRegisterInfo then
                    local nPropId = tbRegisterInfo.nPropId
                    local nComponentType = tbRegisterInfo.nComponentType
                    local PropertyComponent = GetComponent(self, nComponentType)
                    --logdebug("before Add", tbRegisterInfo.szPropKey, PropertyComponent:GetPropAddValue(tbRegisterInfo.nPropId))
                    --logdebug("before Multiply", tbRegisterInfo.szPropKey, PropertyComponent:GetPropMultiplyValue(tbRegisterInfo.nPropId))
                    local nOverlapId = PropertyComponent:PropOverlap(PROP_OVERLAP_TYPE[nOperation], nPropId, nValue)
                    tbOverlapInfo[nComponentType] = tbOverlapInfo[nComponentType] or {}
                    tbOverlapInfo[nComponentType][nPropId] = nOverlapId
                    --logdebug("after Add", tbRegisterInfo.szPropKey, PropertyComponent:GetPropAddValue(tbRegisterInfo.nPropId))
                    --logdebug("after Multiply", tbRegisterInfo.szPropKey, PropertyComponent:GetPropMultiplyValue(tbRegisterInfo.nPropId))
                else
                    logerror("[PropertyComboComponent] Parse property failed, can not find the operation : ", nOperation)
                end
            end
        else
            logerror("[PropertyComboComponent] Parse property failed, can not find the key : ", szKey)
        end
    end
    return tbOverlapInfo
end

local function RemovePropComboFromComponent(self, tbOverlapInfo)
    for nComponentType, tbOverlapIds in pairs(tbOverlapInfo) do
        local PropertyComponent = GetComponent(self, nComponentType)
        for nPropId, nOverlapId in pairs(tbOverlapIds) do
            PropertyComponent:RemovePropOverlap(nPropId, nOverlapId)
        end
    end
end

local function AddPropertyComboRecord(tPropertyComboMap, nComboId, nCount)
    if nComboId and (nComboId ~= -1) then
        local nCurrentCount = tPropertyComboMap[nComboId] or 0
        tPropertyComboMap[nComboId] = nCurrentCount + (nCount or 1)
    end
end

local function CollectFromItemTemplateIds(tPropertyComboMap, nTemplateIds)
    if nTemplateIds then
        for _,nTemplateId in ipairs(nTemplateIds) do
            local tbTemplate = ItemDataTable:GetTemplate(nTemplateId)
            if tbTemplate then
                AddPropertyComboRecord(tPropertyComboMap, tbTemplate.nPropertyComboId)
            end
        end
    end
end

-- local function CollectPartnerComboIds(tPropertyComboMap, tbPartners)
--     local GetPartnerLevel = function(nPartnerId)
--         for _, v in ipairs(tbPartners) do
--             if v.partner_id == nPartnerId then
--                 return v.level
--             end
--         end
--         return -1
--     end
--     local tbPartnerRelationMap = {}
--     for i, v in ipairs(tbPartners) do
--         local nPartnerId = v.partner_id
--         local tbRelations = PartnerRelationDataTable:GetRelationsByPartnerId(nPartnerId)
--         for _, tbGroupData in ipairs(tbRelations) do
--             local nMinLevel = 6
--             for _, nId in ipairs(tbGroupData[1].tbPartnerIds) do
--                 nMinLevel = math.min(nMinLevel, GetPartnerLevel(nId))
--             end
--             for _, tbTemplate in ipairs(tbGroupData) do
--                 if nMinLevel >= tbTemplate.nLevel then
--                     tbPartnerRelationMap[tbTemplate.nId] = tbTemplate
--                 end
--             end
--         end
--     end
--     for nId, tbTemplate in pairs(tbPartnerRelationMap) do
--         AddPropertyComboRecord(tPropertyComboMap, tbTemplate.nPropertyComboId)
--     end
-- end

local function CollectHomelandComboIds(tPropertyComboMap, tbLandmarkDatas)
    for _, v in ipairs(tbLandmarkDatas) do
        local tbLandmarkTemplate = LandmarkBuildingUpgradeDataTable:GetTemplate(v.id, v.grade)
        local nPropertyComboId = tbLandmarkTemplate.nPropertyComboId
        if nPropertyComboId ~= nil and nPropertyComboId > 0 then
            AddPropertyComboRecord(tPropertyComboMap, nPropertyComboId)
        end
    end
end

local function ParsePrepareInfo(tPropertyComboMap, tbPrepareInfo)
    -- 饰品属性加成现在都走 battle_buff.tab 表，decoration表里面不再直接填 property_combo_id 了：
    -- CollectFromItemTemplateIds(tPropertyComboMap, tbPrepareInfo.tbHumanDecorationIds)
    CollectFromItemTemplateIds(tPropertyComboMap, tbPrepareInfo.tbSailorIds)
    -- CollectPartnerComboIds(tPropertyComboMap, tbPrepareInfo.tbPartners)
    CollectHomelandComboIds(tPropertyComboMap, tbPrepareInfo.tbLandmarkDatas)
end

function PropertyComboComponent:OnCreate(Owner, tbPrepareInfo)
    PropertyComboComponent.super.OnCreate(self, Owner, tbPrepareInfo)
    self.tbPropComboOverlapMap = {}

    local tPropertyComboMap = {}
    ParsePrepareInfo(tPropertyComboMap, tbPrepareInfo)
    AddPropComboToComponent(self, tPropertyComboMap)
end

-- 在副本内实时的Overlap一个属性集数值
function PropertyComboComponent:ApplyPropertyComboOverlap(nComboId)
    local tPropertyComboMap = {}
    AddPropertyComboRecord(tPropertyComboMap, nComboId)
    local nPropComboOverlapId = self.nPropComboOverlapIdTop
    self.tbPropComboOverlapMap[nPropComboOverlapId] = AddPropComboToComponent(self, tPropertyComboMap)
    self.nPropComboOverlapIdTop = nPropComboOverlapId + 1
    return nPropComboOverlapId
end

-- 在副本内移除一组实时的属性集数值叠加
function PropertyComboComponent:RemovePropertyComboOverlap(nPropComboOverlapId)
    local tbOverlapInfo = self.tbPropComboOverlapMap[nPropComboOverlapId]
    if tbOverlapInfo then
        RemovePropComboFromComponent(self, tbOverlapInfo)
    end
end

return PropertyComboComponent
