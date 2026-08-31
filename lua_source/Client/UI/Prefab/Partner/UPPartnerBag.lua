local luaclass = require("luaclass")
local Prefabbase = require("Prefabbase")
local UPPartnerBag = luaclass("UPPartnerBag", Prefabbase)

local UIDef = require("UIDef")
local UIUtils = require("UIUtils")
local UIManager = require("UIManager")
local UISetUtils = require("UISetUtils")
local ClientEventDef = require("ClientEventDef")
local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
local SelfVerticalListHelper = require("SelfVerticalListHelper")
local PartnerGradeDataTable = require("PartnerGradeDataTable")

local MAX_LEVEL_NUM = 6
UPPartnerBag.PartnerComponent = nil
UPPartnerBag.szCurrentDisableKey = nil

--[[
    选中伙伴逻辑Begin
]]
local function SetLevel(self, nLevel)
    for i=1,MAX_LEVEL_NUM do
        self.pWidgetRef.hboxStar:GetChildAt(i - 1):SetVisibility((i <= nLevel) and ESlateVisibility.HitTestInvisible or ESlateVisibility.Collapsed)
    end
end

local function UpdateSelectedPartnerInfo(self)
    local tbPartnerInfo = self.ListHelper:GetSelectedData()
    if tbPartnerInfo then
        local nPartnerId = tbPartnerInfo.nPartnerId
        local tbTemplate = tbPartnerInfo.tbTemplate
        local tbResTemplate = tbPartnerInfo.tbResTemplate
        local pWidgetRef = self.pWidgetRef
        local bButtonEnabled = false
        pWidgetRef.txtName:SetText(tbTemplate.l10nName)

        SetLevel(self, tbPartnerInfo.nLevel)
        if tbPartnerInfo.nLevel < MAX_LEVEL_NUM then
            local nFragmentTotalCount = PartnerGradeDataTable:GetFragmentCountByGradeAndLevel(tbTemplate.nGrade, tbPartnerInfo.nLevel + 1)
            pWidgetRef.txtFragmentCount:SetText(tbPartnerInfo.nFragmentCount .. "/" .. nFragmentTotalCount)
            pWidgetRef.pgbFragment:SetPercent(tbPartnerInfo.nFragmentCount / nFragmentTotalCount)
            bButtonEnabled = tbPartnerInfo.nFragmentCount >= nFragmentTotalCount
            self.szCurrentDisableKey = "PARTNER_LEVEL_UP_FAILED_FRAGMENT"
        else
            pWidgetRef.txtFragmentCount:SetText(tbPartnerInfo.nFragmentCount .. "/MAX")
            pWidgetRef.pgbFragment:SetPercent(1)
            self.szCurrentDisableKey = "PARTNER_LEVEL_UP_FAILED_MAX"
        end
        self.pWidgetRef.btnLevelUp:SetIsEnabled(bButtonEnabled)
        if bButtonEnabled then
            self:PlayAnimation("animContour", 0, 1, EUMGSequencePlayMode.Forward, 1)
        else
            self:PlayAnimation("animContourReset", 0, 1, EUMGSequencePlayMode.Forward, 1)
        end
        UISetUtils.SetImageBrushRes(pWidgetRef.imgFragment, tbResTemplate.szIconPath:load())
        UISetUtils.SetImageBrushRes(self.pWidgetRef.imgGrade, PartnerGradeDataTable:GetIconRes(tbTemplate.nGrade):load(), true)
        self.ulPartnerAvatar:SetModel(tbResTemplate.szModelResPath, tbResTemplate.tbModelLocationOffset, tbResTemplate.tbModelRotationOffset)
        if self.PartnerComponent:IsOwnedPartner(nPartnerId) then
            self.pWidgetRef.txtLevelUp:SetText(UISetUtils.GetL10NTextByKey("PARTNER_LEVEL_UP"))
        else
            self.szCurrentDisableKey = "PARTNER_SUMMON_FAILED_FRAGMENT"
            self.pWidgetRef.txtLevelUp:SetText(UISetUtils.GetL10NTextByKey("PARTNER_SUMMON"))
        end
    end
end
--[[
    选中伙伴逻辑End
]]

local function SelectItemByPartnerId(self, nPartnerId)
    local nIndex = 1
    if nPartnerId then
        for i,tbPartnerInfo in ipairs(self.ListHelper:GetData()) do
            if tbPartnerInfo.nPartnerId == nPartnerId then
                nIndex = i
                break
            end
        end
    end
    self.ListHelper:SetSelectedIndex(nIndex)
end

local function UpdateList(self, bOwned, nSelectedPartnerId)
    local tbData = self.PartnerComponent:GetPartnerList(bOwned)
    self.ListHelper:SetData(tbData)
    if #tbData > 0 then
        self.pWidgetRef.bdrNothing:SetVisibility(ESlateVisibility.Collapsed)
        self.pWidgetRef.listPartner:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
        self.pWidgetRef.cvsRightLayout:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
    else
        self.pWidgetRef.bdrNothing:SetVisibility(ESlateVisibility.HitTestInvisible)
        self.pWidgetRef.listPartner:SetVisibility(ESlateVisibility.Collapsed)
        self.pWidgetRef.cvsRightLayout:SetVisibility(ESlateVisibility.Collapsed)
    end
    SelectItemByPartnerId(self, nSelectedPartnerId)
end

local function OnOwnedCheckStateChanged(self, bIsChecked)
    local tbPartnerInfo = self.ListHelper:GetSelectedData()
    UpdateList(self, bIsChecked, tbPartnerInfo and tbPartnerInfo.nPartnerId)
end

local function OnListSelectedChanged(self)
    UpdateSelectedPartnerInfo(self)
end

local function OnClickedBtnDetail(self)
    UIManager:OpenWnd(UIDef.UI_PARTNER_DETAIL, {nPartnerId = self.ListHelper:GetSelectedData().nPartnerId})
end

local function OnClickedBtnLevelUp(self)
    local nPartnerId = self.ListHelper:GetSelectedData().nPartnerId
    if self.PartnerComponent:IsOwnedPartner(nPartnerId) then
        self.PartnerComponent:RequestUpLevelPartner(nPartnerId)
    else
        self.PartnerComponent:RequestCompoundPartner(nPartnerId)
    end
end

local function OnDisableClickedBtnLevelUp(self)
    UIUtils.ShowToastWithKey(self.szCurrentDisableKey)
end

local function OnPartnerInfoChanged(self, nPartnerId)
    UpdateList(self, self.pWidgetRef.chkOwned:IsChecked(), nPartnerId)
end

local function OnReceiveCompoundPartner(self, nPartnerId)
    OnPartnerInfoChanged(self, nPartnerId)
    self:PlayAnimation("animStar", 0, 1, EUMGSequencePlayMode.Forward, 1)
end

local function OnReceiveUpLevelPartner(self, nPartnerId)
    OnPartnerInfoChanged(self, nPartnerId)
    UIManager:OpenWnd(UIDef.UI_FULLSCREEN_MASK)
    self:PlayAnimation("animStar", 0, 1, EUMGSequencePlayMode.Forward, 1, function()
        UIManager:CloseWnd(UIDef.UI_FULLSCREEN_MASK)
        local tbOpenArgs = {}
        tbOpenArgs.nPartnerId = nPartnerId
        UIManager:OpenWnd(UIDef.UI_PARTNER_LEVEL_UP, tbOpenArgs)
    end)
end

function UPPartnerBag:OnLoad()
    self.PartnerComponent = GamePlayerSelfHelper:Get().PartnerComponent
    self.ListHelper = SelfVerticalListHelper()
    self.ListHelper:Init(self, self.pWidgetRef.listPartner)

    self.ulPartnerAvatar = self.UILogicHelper:CreateUILogic("ULPartnerAvatar")
    self.ulPartnerAvatar:SetModelWidget(self.pWidgetRef.imgModel)
end

function UPPartnerBag:OnUnload()
    self.ListHelper:Uninit()
    self.ListHelper = nil
end

function UPPartnerBag:OnBindEvent(EventHelper)
    EventHelper:RegisterCppDelegate(self.pWidgetRef.chkOwned.OnCheckStateChanged, self, OnOwnedCheckStateChanged)
    EventHelper:RegisterLuaDelegate(self.ListHelper.OnSelectedChangedDelegate, OnListSelectedChanged, self)
    EventHelper:RegisterCppDelegate(self.pWidgetRef.btnDetail.OnClicked, self, OnClickedBtnDetail)
    EventHelper:RegisterCppDelegate(self.pWidgetRef.btnLevelUp.OnClicked, self, OnClickedBtnLevelUp)
    EventHelper:RegisterCppDelegate(self.pWidgetRef.btnLevelUp.OnDisableClicked, self, OnDisableClickedBtnLevelUp)

    EventHelper:RegisterEvent(ClientEventDef.EV_ON_RECEIVE_COMPOUND_PARTNER_RESULT, self, OnReceiveCompoundPartner)
    EventHelper:RegisterEvent(ClientEventDef.EV_ON_RECEIVE_SUMMON_PARTNER_RESULT, self, OnPartnerInfoChanged)
    EventHelper:RegisterEvent(ClientEventDef.EV_ON_RECEIVE_PARTNER_LEVEL_UP_RESULT, self, OnReceiveUpLevelPartner)
end

function UPPartnerBag:Activate()
    UpdateList(self, self.pWidgetRef.chkOwned:IsChecked())
end

function UPPartnerBag:OnHide()
    UIManager:CloseWnd(UIDef.UI_FULLSCREEN_MASK)
end

return UPPartnerBag