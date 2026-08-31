-----------------------------------------------------
--File Name    : UPBattleMemberDetail.lua
--Author       : Ran Jie
--Create Time  : 2019-01-22
-----------------------------------------------------
local luaclass = require ("luaclass")
local PrefabBase = require("PrefabBase")
local UPBattleMemberDetail = luaclass("UPBattleMemberDetail", PrefabBase)

local UIResourceDef = require("UIResourceDef")
local UISetUtils = require("UISetUtils")
local GenderTypeDefine = require("GenderTypeDefine")
local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
local HumanDataTable = require("HumanDataTable")

local DEFALUT_NAME = UISetUtils.GetL10NTextByKey("BATTLE_RESULT_PLAYER_DEFAULT_NAME")

function UPBattleMemberDetail:SetData(tbData, bTeamDead, bMVP)
    local pWidgetRef = self.pWidgetRef
    pWidgetRef:SetVisibility(ESlateVisibility.HitTestInvisible)
    local nSelfPlayerId = GamePlayerSelfHelper:Get().nPlayerId
    --性别
    local tbHumanTemplate = HumanDataTable:GetTemplate(tbData.nAvatarId)
    if tbHumanTemplate then
        local nGenderType = tbHumanTemplate.nGender
        local szGenderIcon = UIResourceDef.GENDER_FEMALE
        if nGenderType == GenderTypeDefine.MALE then
            szGenderIcon = UIResourceDef.GENDER_MALE
        end
        UISetUtils.SetImageBrushRes(pWidgetRef.imgSex, szGenderIcon:load(), true)
    end
    --名字
    local szName = tbData.name
    if not szName or szName == "" then
        szName = DEFALUT_NAME
    end
    pWidgetRef.txtPlayName:SetText(szName)
    if bTeamDead or tbData.nPlayerId == nSelfPlayerId then
        --舰船伤害
        pWidgetRef.txtScore:SetText(string.format("%.1f", tbData.nBattleScore))
        if bMVP then
            pWidgetRef.imgMVP:SetVisibility(ESlateVisibility.HitTestInvisible)
        end
    else
        pWidgetRef.txtScore:SetText(0)
    end
end


return UPBattleMemberDetail