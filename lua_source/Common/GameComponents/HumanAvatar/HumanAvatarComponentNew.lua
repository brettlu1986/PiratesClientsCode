-----------------------------------------------------
--File Name    : HumanAvatarComponentNew.lua
--Author       : WuJizhou
--Create Time  : 4/13/2020, 7:50:39 PM
--Description  : HumanAvatarComponentNew
-----------------------------------------------------
local luaclass                      = require("luaclass")
local GameComponentBaseClass        = require("GameComponentBase")
local HumanAvatarComponentNew          = luaclass("HumanAvatarComponentNew", GameComponentBaseClass)


local PropName                      = require("PropName")
local HumanDataTable                = require("HumanDataTable")
local GenderTypeDefine              = require("GenderTypeDefine")
local HumanAvatarData               = require("HumanAvatarData")
local HumanAvatarHelper             = require("HumanAvatarHelper")

local GlobalVariableSystem          = dynamic_require("GlobalVariableSystem")


HumanAvatarComponentNew.rHumanAvatarData = nil

HumanAvatarComponentNew.tbComponentData = nil



local function InitComponentData(self, tbAppearancePartData, tbBasicFashionPartData, tbArmorFashionPartData, tbFashionFlagData)
    local tbComponentData = HumanAvatarData()
    tbComponentData:SetAppearanceData(tbAppearancePartData)
    tbComponentData:SetBasicFashionData(tbBasicFashionPartData)
    tbComponentData:SetArmorFashionData(tbArmorFashionPartData)
    tbComponentData:SetArmorFashionFlagTable(tbFashionFlagData)
    self.tbComponentData = tbComponentData
end

local function InitComponentFromParameter(self, tbParams)
    local tbAppearancePartData
    if tbParams.tbAppearancePartData then
        tbAppearancePartData = tbParams.tbAppearancePartData
    -- elseif tbParams.tbAppearanceIds then
    --     local tbAppearanceIds = tbParams.tbAppearanceIds
    --     tbAppearancePartData = HumanAvatarHelper.ParseToPartDataFromAppearance(tbAppearanceIds)
    else
        logerror("HumanAvatarComponentNew error, appearance is nil")
    end
    local tbFashionItemTemplateIds = tbParams.tbFashionItemTemplateIds
    local tbBasicFashionPartData, tbArmorFashionPartData = HumanAvatarHelper.ParseToPartDataFromFashionItemTemplate(tbFashionItemTemplateIds)

    local nHumanFashionFlag = tbParams.nHumanFashionFlag
    local tbFashionFlagData = HumanAvatarHelper.GetArmorFlagTable(nHumanFashionFlag)
    InitComponentData(self, tbAppearancePartData, tbBasicFashionPartData, tbArmorFashionPartData, tbFashionFlagData)
end

local function UpdateReplicateData(self)
    local tbComponentData = self.tbComponentData
    if GlobalVariableSystem:IsServerLogic() then
        self.rHumanAvatarData:Set(tbComponentData:GetPartDatas())
    else
        if GlobalVariableSystem:IsInLobby() then
            self:OnAvatarResDataChanged(nil, tbComponentData:GetPartDatas())
        end
    end
end


-- tbNewData: { key:HumanAvatarDef.PartProtoDef, value: part id / color id}
function HumanAvatarComponentNew:OnAvatarResDataChanged(rProperty, tbNewData)
end


-----------------------Public Method-----------------------

function HumanAvatarComponentNew:ApplyArmorTypeAndLevel(nArmorType, nArmorLevel)
    self.tbComponentData:SetArmorTypeAndLevel(nArmorType, nArmorLevel)
    UpdateReplicateData(self)
end

function HumanAvatarComponentNew:ApplyBasicFashionItem(tbTemplateIds)
    local tbPartData = HumanAvatarHelper.ParseToPartDataFromBasicFashionItemTemplate(tbTemplateIds)
    self.tbComponentData:SetBasicFashionData(tbPartData)
    UpdateReplicateData(self)
end

function HumanAvatarComponentNew:ApplyArmorFashionItem(tbTemplateIds)
    local tbPartData = HumanAvatarHelper.ParseToPartDataFromArmorFashionItemTemplate(tbTemplateIds)
    self.tbComponentData:SetArmorFashionData(tbPartData)
    UpdateReplicateData(self)
end


-------base api from GameComponentBaseClass--------

function HumanAvatarComponentNew:OnCreate(Owner, tbParams)
    HumanAvatarComponentNew.super.OnCreate(self, Owner, tbParams)
    if GlobalVariableSystem:IsServerLogic() or GlobalVariableSystem:IsInLobby() then
        InitComponentFromParameter(self, tbParams)
    end
    return true
end

function HumanAvatarComponentNew:OnDestroy()
    HumanAvatarComponentNew.super.OnDestroy(self)
end

function HumanAvatarComponentNew:OnActorPreCreated(pUEActor)
    HumanAvatarComponentNew.super.OnActorPreCreated(self, pUEActor)
    if self.Owner:IsHuman() then
        local tbTemplate = HumanDataTable:GetTemplate(self.Owner:GetTemplateId())
        local nHumanGender = tbTemplate.nGender
        if nHumanGender == GenderTypeDefine.MALE then
            pUEActor:SetGender(ENUM_HumanGender.Male)
        else
            pUEActor:SetGender(ENUM_HumanGender.Female)
        end
    end
end

function HumanAvatarComponentNew:OnActorCreated(pUEActor)
    HumanAvatarComponentNew.super.OnActorCreated(self, pUEActor)
    if GlobalVariableSystem:IsInDungeon() then
        local tbCharacter = self.Owner
        local rComponent = tbCharacter.CustomReplicationComponent
        self.rHumanAvatarData = rComponent:BindMethod(PropName.rHumanAvatarData, nil, self, self.OnAvatarResDataChanged, false)
        if GlobalVariableSystem:IsServerLogic() then
            UpdateReplicateData(self)
        end
    end
end

function HumanAvatarComponentNew:OnActorDestroyed(...)
    HumanAvatarComponentNew.super.OnActorDestroyed(self, ...)
end


return HumanAvatarComponentNew