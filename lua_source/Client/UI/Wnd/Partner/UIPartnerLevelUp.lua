-----------------------------------------------------
--File Name    : UIPartnerLevelUp.lua
--Author       : Song Fuhao
--Create Time  : 2019-03-05
--Description  : 伙伴升星提示
-----------------------------------------------------
local luaclass = require("luaclass")
local WndBase = require("WndBase")
local UIPartnerLevelUp = luaclass("UIPartnerLevelUp", WndBase)

local UIDef = require("UIDef")
local UIUtils = require("UIUtils")
local UISetUtils = require("UISetUtils")
local SkillDataTable = require("SkillDataTable")
local GamePlayerSelfHelper = require("GamePlayerSelfHelper")

local MAX_WEAPON_COUNT = 3

local function OnClickedBtnClose(self)
    self:PlayAnimation("animHide", 0, 1, EUMGSequencePlayMode.Forward, 1, function()
        self:CloseSelf()
    end)
end

local function OnClickedBtnSkill(self)
    local tbTips = UIUtils.ShowTips(UIDef.UP_PARTNER_SKILL_TIPS, self.pWidgetRef.btnSkill)
    tbTips:SetSkillId(self.nSkillId)
end

local function HasAnyWeaponUpLevel(tbTemplate, nLastLevel, nLevel)
    for i = 1, MAX_WEAPON_COUNT do
        local tbWeaponList = tbTemplate["tbWeaponList"..i]
        if tbWeaponList then
            local nLastWeaponId = tbWeaponList[nLastLevel]
            local nWeaponId = tbWeaponList[nLevel]
            if nLastWeaponId ~= nWeaponId then
                return true
            end
        end
    end
    return false
end

local function UpdatePartnerInfo(self)
    local tbPartnerInfo = GamePlayerSelfHelper:Get().PartnerComponent:GetPartnerInfo(self.nPartnerId)
    local tbTemplate = tbPartnerInfo.tbTemplate
    local pWidgetRef = self.pWidgetRef

    local nLevel = tbPartnerInfo.nLevel
    local nLastLevel = tbPartnerInfo.nLevel - 1

    self.pbPartnerMiniItem:SetPartnerInfo(tbPartnerInfo, nLevel)

    pWidgetRef.txtOldHp:SetText(tbTemplate.tbHpList[nLastLevel])
    pWidgetRef.txtNewHp:SetText(tbTemplate.tbHpList[nLevel])

    if HasAnyWeaponUpLevel(tbTemplate, nLastLevel, nLevel) then
        pWidgetRef.txtWeaponUpLevel:SetVisibility(ESlateVisibility.HitTestInvisible)
    end

    self.nSkillId = tbTemplate.tbSkillList[nLevel]
    if self.nSkillId ~= -1 then
        local tbSkillResTemplate = SkillDataTable:GetResTemplate(self.nSkillId)
        UISetUtils.SetButtonBrushRes(pWidgetRef.btnSkill, tbSkillResTemplate.szIconRes:load(), true)
        UISetUtils.SetImageBrushRes(pWidgetRef.imgSkillBg, tbSkillResTemplate.szDisplayBgRes:load())
        pWidgetRef.ovlSkill:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
        pWidgetRef.txtSkillTitle:SetVisibility(ESlateVisibility.HitTestInvisible)
    end
end

function UIPartnerLevelUp:OnLoad()
    self.pbPartnerMiniItem = self.PrefabHelper:BindPrefab(self.pWidgetRef.pbPartnerMiniItem, UIDef.UP_PARTNER_LEVEL_UP_ITEM)
end

function UIPartnerLevelUp:OnBindEvent(EventHelper)
    EventHelper:RegisterCppDelegate(self.pWidgetRef.btnClose.OnClicked, self, OnClickedBtnClose)
    EventHelper:RegisterCppDelegate(self.pWidgetRef.btnSkill.OnClicked, self, OnClickedBtnSkill)
end

function UIPartnerLevelUp:OnEnter()
    self.nPartnerId = self.tbOpenArgs.nPartnerId
    UpdatePartnerInfo(self)
    self:PlayAnimation("animShow", 0, 1, EUMGSequencePlayMode.Forward, 1)
end

return UIPartnerLevelUp