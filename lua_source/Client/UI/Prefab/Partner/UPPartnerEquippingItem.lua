local luaclass = require("luaclass")
local Prefabbase = require("Prefabbase")
local UPPartnerEquippingItem = luaclass("UPPartnerEquippingItem", Prefabbase)

local UIDef = require("UIDef")
local UIUtils = require("UIUtils")
local UIManager = require("UIManager")
local UISetUtils = require("UISetUtils")
local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
local PartnerGradeDataTable = require("PartnerGradeDataTable")

local MAX_LEVEL_NUM = 6
UPPartnerEquippingItem.tbRelationIds = nil
UPPartnerEquippingItem.fnEquipPartnerCallback = nil
UPPartnerEquippingItem.fnUnequipPartnerCallback = nil

local function GetShipPreparationComponent()
    return GamePlayerSelfHelper:Get().PartnerComponent
end

local function UpdatePartnerInfo(self, nPartnerId)
    local tbData = GetShipPreparationComponent():GetPartnerInfo(nPartnerId)
    local tbTemplate = tbData.tbTemplate
    local tbResTemplate = tbData.tbResTemplate
    local pWidgetRef = self.pWidgetRef
    pWidgetRef.txtName:SetText(tbTemplate.l10nName)

    self:SetLevel(tbData.nLevel)
    UISetUtils.SetImageBrushRes(pWidgetRef.imgGrade, PartnerGradeDataTable:GetIconRes(tbTemplate.nGrade):load(), true)
    self.ulPartnerAvatar:SetModel(tbResTemplate.szModelResPath, tbResTemplate.tbModelLocationOffset, tbResTemplate.tbModelRotationOffset)
    self:UpdateRelation()
end

local function OnClickedBtnEquip(self)
    if self.fnEquipPartnerCallback then
        self.fnEquipPartnerCallback()
    end
end

local function OnClickedBtnUnequip(self)
    if self.fnUnequipPartnerCallback then
        self.fnUnequipPartnerCallback()
    end
end

local function OnClickedBtnReplace(self)
    if self.fnEquipPartnerCallback then
        self.fnEquipPartnerCallback()
    end
end

local function OnClickedBtnDetail(self)
    UIManager:OpenWnd(UIDef.UI_PARTNER_DETAIL, {nPartnerId = self.nPartnerId})
end

local function OnClickedBtnRelation(self)
    local tbTips = UIUtils.ShowTips(UIDef.UP_PARTNER_RELATION_TIPS, self.pWidgetRef.btnRelation)
    tbTips:SetRelationIds(self.tbRelationIds)
end

function UPPartnerEquippingItem:OnLoad()
    self.ulPartnerAvatar = self.UILogicHelper:CreateUILogic("ULPartnerAvatar")
    self.ulPartnerAvatar:SetModelWidget(self.pWidgetRef.imgModel)
end

function UPPartnerEquippingItem:OnHide()
    UIUtils.HideTips()
end

function UPPartnerEquippingItem:OnBindEvent(EventHelper)
    EventHelper:RegisterCppDelegate(self.pWidgetRef.btnEquip.OnClicked, self, OnClickedBtnEquip)
    EventHelper:RegisterCppDelegate(self.pWidgetRef.btnUnequip.OnClicked, self, OnClickedBtnUnequip)
    EventHelper:RegisterCppDelegate(self.pWidgetRef.btnReplace.OnClicked, self, OnClickedBtnReplace)
    EventHelper:RegisterCppDelegate(self.pWidgetRef.btnDetail.OnClicked, self, OnClickedBtnDetail)
    EventHelper:RegisterCppDelegate(self.pWidgetRef.btnRelation.OnClicked, self, OnClickedBtnRelation)
end

function UPPartnerEquippingItem:SetEquipPartnerCallback(fnEquipPartnerCallback)
    self.fnEquipPartnerCallback = fnEquipPartnerCallback
end

function UPPartnerEquippingItem:SetUnequipPartnerCallback(fnUnequipPartnerCallback)
    self.fnUnequipPartnerCallback = fnUnequipPartnerCallback
end

function UPPartnerEquippingItem:SetPartnerId(nPartnerId)
    local nLastPartnerId = self.nPartnerId
    self.nPartnerId = nPartnerId
    if nPartnerId then
        UpdatePartnerInfo(self, nPartnerId)
        if nLastPartnerId then
            self:PlayAnimation("animReplaceDetail", 0, 1, EUMGSequencePlayMode.Forward, 1)
        else
            self:PlayAnimation("animToDetail", 0, 1, EUMGSequencePlayMode.Forward, 1, function()
                --引导需要
            end)
        end
    else
        self:PlayAnimation("animToEmpty", 0, 1, EUMGSequencePlayMode.Forward, 1, function()
            self.ulPartnerAvatar:ClearAvatar()
        end)
    end
end

function UPPartnerEquippingItem:GetPartnerId()
    return self.nPartnerId
end

function UPPartnerEquippingItem:SetLevel(nLevel)
    for i=1,MAX_LEVEL_NUM do
        self.pWidgetRef.hboxStar:GetChildAt(i - 1):SetVisibility((i <= nLevel) and ESlateVisibility.HitTestInvisible or ESlateVisibility.Collapsed)
    end
end

function UPPartnerEquippingItem:UpdateRelation()
    if self.nPartnerId then
        self.tbRelationIds = GetShipPreparationComponent():GetActiveRelationIds(self.nPartnerId)
        if #self.tbRelationIds > 0 then
            self.pWidgetRef.btnRelation:SetVisibility(ESlateVisibility.Visible)
        else
            self.pWidgetRef.btnRelation:SetVisibility(ESlateVisibility.Collapsed)
        end
    end
end

return UPPartnerEquippingItem