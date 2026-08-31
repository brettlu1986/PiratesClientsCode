-----------------------------------------------------
--File Name    : UIPartnerDetail.lua
--Author       : Song Fuhao
--Create Time  : 2019-03-05
--Description  : 伙伴详情
-----------------------------------------------------
local luaclass = require("luaclass")
local WndBase = require("WndBase")
local UIPartnerDetail = luaclass("UIPartnerDetail", WndBase)

local L10N = require("L10N")
local UIDef = require("UIDef")
local UIUtils = require("UIUtils")
local UISetUtils = require("UISetUtils")
local SkillDataTable = require("SkillDataTable")
local SelfTabBarHelper = require("SelfTabBarHelper")
local BattleItemDataTable = require("BattleItemDataTable")
local SelfGalleryHelper = require("SelfGalleryHelper")
local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
local PartnerGradeDataTable = require("PartnerGradeDataTable")
local SelfVerticalListHelper = require("SelfVerticalListHelper")
local PartnerRelationDataTable = require("PartnerRelationDataTable")

local MAX_WEAPON_COUNT = 3
local MAX_SKILL_COUNT = 6
local MAX_LEVEL_NUM = 6
local TAB_INDEX_RELATION = 2
local PERSONALITY_NAME = {
    UISetUtils.GetL10NTextByKey("PARTNER_PERSONALITY_NAME_1"),
    UISetUtils.GetL10NTextByKey("PARTNER_PERSONALITY_NAME_2"),
    UISetUtils.GetL10NTextByKey("PARTNER_PERSONALITY_NAME_3"),
    UISetUtils.GetL10NTextByKey("PARTNER_PERSONALITY_NAME_4")
}
local SPECIALITY_NAME = {
    UISetUtils.GetL10NTextByKey("PARTNER_SPECIALITY_NAME_1"),
    UISetUtils.GetL10NTextByKey("PARTNER_SPECIALITY_NAME_2"),
    UISetUtils.GetL10NTextByKey("PARTNER_SPECIALITY_NAME_3"),
    UISetUtils.GetL10NTextByKey("PARTNER_SPECIALITY_NAME_4"),
    UISetUtils.GetL10NTextByKey("PARTNER_SPECIALITY_NAME_5")
}
local PERSONALITY_COLOR = {
    KMUMGLibrary.GetLinearColorFromHex("FF0000FF"), -- 好战
    KMUMGLibrary.GetLinearColorFromHex("FFFFFFFF"), -- 平衡
    KMUMGLibrary.GetLinearColorFromHex("0059FFFF"), -- 谨慎
    KMUMGLibrary.GetLinearColorFromHex("C182FFFF"), -- 和平
}
local SPECIALITY_COLOR = {
    KMUMGLibrary.GetLinearColorFromHex("FF00C1FF"), -- 近战
    KMUMGLibrary.GetLinearColorFromHex("6300FFFF"), -- 远程
    KMUMGLibrary.GetLinearColorFromHex("FF5B00FF"), -- 投掷
    KMUMGLibrary.GetLinearColorFromHex("F8FF6DFF"), -- 收集
    KMUMGLibrary.GetLinearColorFromHex("00FF00FF"), -- 医疗
}
UIPartnerDetail.nPartnerId = -1
UIPartnerDetail.tbSkillList = {}
UIPartnerDetail.tbWeaponList = {}

local function OnTabBarIndexChanged(self, nIndex)
    nIndex = nIndex - 1
    local pWidgetRef = self.pWidgetRef
    pWidgetRef.wsRightPanel:SetActiveWidgetIndex(nIndex)
    if nIndex == TAB_INDEX_RELATION then
        if #self.RelationListHelper:GetData() > 0 then
            pWidgetRef.listRelation:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
        else
            pWidgetRef.vboxRelationEmpty:SetVisibility(ESlateVisibility.HitTestInvisible)
        end
    end
end

local function OnClickedSkillButton(self, nIndex)
    local tbTips = UIUtils.ShowTips(UIDef.UP_PARTNER_SKILL_TIPS, self.pWidgetRef["btnSkill"..nIndex])
    tbTips:SetSkillId(self.tbSkillList[nIndex])
end

local function OnClickedWeaponButton(self, nIndex)
    local tbTips = UIUtils.ShowTips(UIDef.UP_PARTNER_WEAPON_TIPS, self.pWidgetRef["btnWeapon"..nIndex])
    tbTips:SetWeaponId(self.tbWeaponList[nIndex])
end

local function SetLevel(self, nLevel)
    for i=1,MAX_LEVEL_NUM do
        self.pWidgetRef.hboxStar:GetChildAt(i - 1):SetVisibility((i <= nLevel) and ESlateVisibility.HitTestInvisible or ESlateVisibility.Collapsed)
    end
end

local function UpdatePartnerInfo(self)
    self.nPartnerId = self.tbOpenArgs.nPartnerId

    local tbPartnerInfo = GamePlayerSelfHelper:Get().PartnerComponent:GetPartnerInfo(self.nPartnerId)
    local tbTemplate = tbPartnerInfo.tbTemplate
    local tbResTemplate = tbPartnerInfo.tbResTemplate
    local pWidgetRef = self.pWidgetRef
    local nLevel = math.max(tbPartnerInfo.nLevel, 1)
    -- 设置星级
    SetLevel(self, nLevel)
    -- 设置伙伴名称
    pWidgetRef.txtName:SetText(tbTemplate.l10nName)
    -- 设置质量图标
    UISetUtils.SetImageBrushRes(pWidgetRef.imgGrade, PartnerGradeDataTable:GetIconRes(tbTemplate.nGrade):load(), true)
    -- 设置3D模型
    self.ulPartnerAvatar:SetModel(tbResTemplate.szModelResPath, tbResTemplate.tbModelLocationOffset, tbResTemplate.tbModelRotationOffset)
    -- 设置性格/特长
    pWidgetRef.bdrPersonality:SetBrushColor(PERSONALITY_COLOR[tbTemplate.nPersonality])
    pWidgetRef.bdrSpeciality:SetBrushColor(SPECIALITY_COLOR[tbTemplate.nSpeciality])
    pWidgetRef.txtPersonality:SetText(L10N:Format(UISetUtils.GetL10NTextByKey("PARTNER_PERSONALITY_FORMAT"), PERSONALITY_NAME[tbTemplate.nPersonality]))
    pWidgetRef.txtSpeciality:SetText(L10N:Format(UISetUtils.GetL10NTextByKey("PARTNER_SPECIALITY_FORMAT"), SPECIALITY_NAME[tbTemplate.nSpeciality]))
    -- 设置生命
    pWidgetRef.txtHp:SetText(L10N:Format(UISetUtils.GetL10NTextByKey("PARTNER_HP_FORMAT"), tbTemplate.tbHpList[nLevel]))
    -- 设置武器
    for i = 1, MAX_WEAPON_COUNT do
        local tbWeaponList = tbTemplate["tbWeaponList"..i]
        if tbWeaponList then
            pWidgetRef["ovlWeapon"..i]:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
            self.tbWeaponList[i] = tbWeaponList[nLevel]
            local tbBattleResTemplate = BattleItemDataTable:GetResTemplate(self.tbWeaponList[i])
            UISetUtils.SetImageBrushRes(pWidgetRef["imgWeapon"..i], tbBattleResTemplate.szEquipmentDisplayPath:load())
        end
    end

    -- 设置技能相关UI
    self.tbSkillList = tbTemplate.tbSkillList
    for i,nSkillId in ipairs(self.tbSkillList) do
        if nSkillId ~= -1 then
            -- 显示技能该技能图层
            pWidgetRef["ovlSkill"..i]:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
            -- 设置技能图标
            local tbSkillResTemplate = SkillDataTable:GetResTemplate(nSkillId)
            UISetUtils.SetButtonBrushRes(pWidgetRef["btnSkill"..i], tbSkillResTemplate.szIconRes:load(), true)
            -- 设置技能图标背景
            UISetUtils.SetImageBrushRes(pWidgetRef["imgSkillBg"..i], tbSkillResTemplate.szDisplayBgRes:load())
            -- 技能解锁等级大于当前等级时，显示Lock信息
            if i > nLevel  then
                pWidgetRef["btnSkill"..i]:SetIsEnabled(false)
                pWidgetRef["imgSkillLock"..i]:SetVisibility(ESlateVisibility.HitTestInvisible)
                pWidgetRef["txtSkillLock"..i]:SetVisibility(ESlateVisibility.HitTestInvisible)
            end
        end
    end

    local tbRelations = PartnerRelationDataTable:GetRelationsByPartnerId(self.nPartnerId)
    self.RelationListHelper:SetData(tbRelations)

    self.GalleryHelper:SetData({
        {
            szSkinPosterRes = tbTemplate.szDefaultSkinPosterRes
        }
    })
end

function UIPartnerDetail:OnLoad()
    self.pbWindowFrame = self.PrefabHelper:BindPrefab(self.pWidgetRef.pbWindowFrame)

    self.TabBarHelper = SelfTabBarHelper()
    self.TabBarHelper:Init(self, self.pWidgetRef.hboxTabBar)
    self.TabBarHelper.OnSelectedChangedDelegate:Bind(OnTabBarIndexChanged, self)

    -- 初始化皮肤列表
    self.GalleryHelper = SelfGalleryHelper()
    self.GalleryHelper:Init(self, self.pWidgetRef.glrySkin)

    -- 初始化羁绊列表
    self.RelationListHelper = SelfVerticalListHelper()
    self.RelationListHelper:Init(self, self.pWidgetRef.listRelation)

    -- 初始化3D模型显示
    self.ulPartnerAvatar = self.UILogicHelper:CreateUILogic("ULPartnerAvatar")
    self.ulPartnerAvatar:SetModelWidget(self.pWidgetRef.imgModel)

    self.tbSkillList = {}
end

function UIPartnerDetail:OnUnload()
    self.GalleryHelper:Uninit()
    self.GalleryHelper = nil
    self.RelationListHelper:Uninit()
    self.RelationListHelper = nil
    self.TabBarHelper:Uninit()
    self.TabBarHelper = nil
end

function UIPartnerDetail:OnEnter()
    UpdatePartnerInfo(self)
end

function UIPartnerDetail:OnHide()
    UIUtils.HideTips()
end

function UIPartnerDetail:OnBindEvent(EventHelper)
    for i=1,MAX_SKILL_COUNT do
        EventHelper:RegisterCppDelegate(self.pWidgetRef["btnSkill"..i].OnClicked, self, function()
            OnClickedSkillButton(self, i)
        end)
        EventHelper:RegisterCppDelegate(self.pWidgetRef["btnSkill"..i].OnDisableClicked, self, function()
            OnClickedSkillButton(self, i)
        end)
    end
    for i=1,MAX_WEAPON_COUNT do
        EventHelper:RegisterCppDelegate(self.pWidgetRef["btnWeapon"..i].OnClicked, self, function()
            OnClickedWeaponButton(self, i)
        end)
    end
end

return UIPartnerDetail