-----------------------------------------------------
--File Name    : UPBattleMemberResult.lua
--Author       : Ran Jie
--Create Time  : 2019-01-22
-----------------------------------------------------
local luaclass = require ("luaclass")
local UPWidgetBase = require("UPWidgetBase")
local UPBattleMemberResult = luaclass("UPBattleMemberResult", UPWidgetBase)

local AvatarDataTable = require("AvatarDataTable")
local HeadIconResDataTable = require("HeadIconResDataTable")
local UISetUtils = require("UISetUtils")
local UIResourceDef = require("UIResourceDef")
local GenderTypeDefine = require("GenderTypeDefine")
local L10N = require("L10N")

local DEFALUT_NAME = UISetUtils.GetL10NTextByKey("BATTLE_RESULT_PLAYER_DEFAULT_NAME")

function UPBattleMemberResult:SetData(tbData, bHideKillCount)
    local pWidgetRef = self.pWidgetRef
    pWidgetRef:SetVisibility(ESlateVisibility.HitTestInvisible)
    --头像
    local HumanTemplate = AvatarDataTable:GetTemplate(tbData.nAvatarId)
    if not HumanTemplate then
        logerror("UIFFABattleResult:SetTeamMemberInfo,HumanTemplate is nil,templateid=", tbData.nAvatarId)
        return
    end
    local szHeadIconPath = HeadIconResDataTable:GetResPath(HumanTemplate.nHeadIconId)
    if szHeadIconPath then
        local pIconObj = szHeadIconPath:load()
        if pIconObj then
            UISetUtils.SetImageBrushRes(pWidgetRef.imgPlayerHead, pIconObj)
        end
    end
    --性别
    local szGenderIcon = UIResourceDef.GENDER_FEMALE
    if tbData.nGenderType == GenderTypeDefine.MALE then
        szGenderIcon = UIResourceDef.GENDER_MALE
    end
    UISetUtils.SetImageBrushRes(pWidgetRef.imgSex, szGenderIcon:load(), true)
    --名字
    local szName = tbData.name
    if not szName or szName == "" then
        szName = DEFALUT_NAME
    end
    pWidgetRef.txtPlayName:SetText(szName)
    --击杀数量
    if bHideKillCount then
        pWidgetRef.txtKillCount:SetVisibility(ESlateVisibility_Collapsed)
    else
        pWidgetRef.txtKillCount:SetVisibility(ESlateVisibility_SelfHitTestInvisible)
        local l10nKill = UISetUtils.GetL10NTextByKey("FFA_TEAM_MEMBER_KILL_COUNT")
        l10nKill = L10N:Format(l10nKill, tbData.nKillCount)
        pWidgetRef.txtKillCount:SetText(l10nKill)
    end
end


return UPBattleMemberResult