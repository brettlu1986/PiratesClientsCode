-----------------------------------------------------
--File Name    : UPBattleDeadPlaybackWeapon.lua
--Author       : ranjie
--Create Time  : 2019-09-17
--Description  : 死亡回放造成伤害的武器
-----------------------------------------------------
local luaclass = require("luaclass")
local PrefabBase = require("PrefabBase")
local UPBattleDeadPlaybackWeapon = luaclass("UPBattleDeadPlaybackWeapon", PrefabBase)

local UISetUtils = require("UISetUtils")
local BattleItemDataTable = require("BattleItemDataTable")
local L10N = require("L10N")
local DamageCauserType = require("DamageCauserType")
local UIResourceDef = require("UIResourceDef")
local UITextDef = require("UITextDef")
local FFAToastDataTable = require("FFAToastDataTable")

local L10N_WEAPON_NAME = UISetUtils.GetL10NTextByKey("BATTLE_DEAD_PLAYBACK_WEAPON_NAME")
local L10N_WEAPON_DAMAGE = UISetUtils.GetL10NTextByKey("BATTLE_DEAD_PLAYBACK_WEAPON_DAMAGE")

function UPBattleDeadPlaybackWeapon:SetData(tbData, nCauserType)
    local pWidgetRef = self.pWidgetRef
    if not tbData then
        pWidgetRef:SetVisibility(ESlateVisibility_Collapsed)
        return 
    end 
    --武器图标
    local szHeadIconPath = nil
    local l10nNameText = nil
    if nCauserType == DamageCauserType.PLAYER or nCauserType == DamageCauserType.BOT or nCauserType == DamageCauserType.NPC then
        local tbItemResTemplate = BattleItemDataTable:GetResTemplate(tbData.nWeaponTemplateId)
        if tbItemResTemplate then
            szHeadIconPath = tbItemResTemplate.szIconPath
        else
            local tbKillTemplate = FFAToastDataTable:GetTemplate(tbData.nDamageType)
            if tbKillTemplate then
                szHeadIconPath = tbKillTemplate.szIcon
            else
                logerror("UPBattleDeadPlaybackWeapon:tbKillTemplate is nil, nDamageType=",tbData.nDamageType)
            end
        end
        --武器名称和攻击次数
        local tbItemTemplate = BattleItemDataTable:GetTemplate(tbData.nWeaponTemplateId)
        if tbItemTemplate then
            l10nNameText = L10N:Format(L10N_WEAPON_NAME, tbItemTemplate.l10nName, tbData.nAttackCount)
        else
            local l10nDamageName = UITextDef.DEAD_DAMAGE_NAME[tbData.nDamageType]
            if l10nDamageName then
                l10nNameText = L10N:Format(L10N_WEAPON_NAME, l10nDamageName, tbData.nAttackCount)
            else
                logerror("UPBattleDeadPlaybackWeapon:l10nDamageName is nil, nDamageType=",tbData.nDamageType)
            end
        end
    else
        szHeadIconPath = UIResourceDef.DEAD_CAUSER_TYPE_ICON[nCauserType]
        l10nNameText = L10N:Format(L10N_WEAPON_NAME, UITextDef.DEAD_CAUSER_NAME[nCauserType], tbData.nAttackCount)
    end
    if szHeadIconPath and szHeadIconPath ~= "" then
        local pIconObj = szHeadIconPath:load()
        if pIconObj then
            UISetUtils.SetImageBrushRes(pWidgetRef.imgHeadIcon, pIconObj)
        end
    else
        logerror("UPBattleDeadPlaybackWeapon:SetData,szHeadIconPath is nil, nCauserType,nWeaponTemplateId =", nCauserType,tbData.nWeaponTemplateId)
    end
    if l10nNameText then
        pWidgetRef.txtWeaponName:SetText(l10nNameText)
    else
        pWidgetRef.txtWeaponName:SetText("Unknown")
        logerror("UPBattleDeadPlaybackWeapon:SetData,l10nNameText is nil, nCauserType,nWeaponTemplateId =", nCauserType,tbData.nWeaponTemplateId)
    end
    --伤害和百分比
    local szDamageRate = string.format("%.1f", tbData.nDamageRate * 100)
    local l10nDamageText = L10N:Format(L10N_WEAPON_DAMAGE, tbData.nDamage, szDamageRate)
    pWidgetRef.txtDamage:SetText(l10nDamageText)
end

return UPBattleDeadPlaybackWeapon
