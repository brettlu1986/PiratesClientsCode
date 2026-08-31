-----------------------------------------------------
--File Name    : UPBattleDeadPlaybackItem.lua
--Author       : ranjie
--Create Time  : 2019-09-17
--Description  : 死亡回放详情单元
-----------------------------------------------------
local luaclass = require("luaclass")
local PrefabBase = require("PrefabBase")
local UPBattleDeadPlaybackItem = luaclass("UPBattleDeadPlaybackItem", PrefabBase)

local UISetUtils = require("UISetUtils")
local TemplateTypeDef = require("TemplateTypeDef")
local AvatarDataTable = require("AvatarDataTable")
local HeadIconResDataTable = require("HeadIconResDataTable")
local ShipItemHelper = require("ShipItemHelper")
local BattleItemResDataTable = require("BattleItemResDataTable")
local DamageCauserType = require("DamageCauserType")
local UIResourceDef = require("UIResourceDef")
local UITextDef = require("UITextDef")
local NPCDataTable = require("NPCDataTable")

local CAUSE_TEXT =
{
    [1] = UISetUtils.GetL10NTextByKey("BATTLE_DEAD_PLAYBACK_KILL"),
    [2] = UISetUtils.GetL10NTextByKey("BATTLE_DEAD_PLAYBACK_ASSIST"),
    [3] = UISetUtils.GetL10NTextByKey("BATTLE_DEAD_PLAYBACK_ASSIST"),
}

local KILL_BG_COLOR = KMUMGLibrary.GetSlateColorFromHex("59060286")
local KILL_TITLE_COLOR = KMUMGLibrary.GetSlateColorFromHex("FF0D0DFF")

local MAX_COUNT = 3

UPBattleDeadPlaybackItem.tbDamageWeaponScript = nil

local function SortFunc(tbData1, tbData2)
    if tbData1.nDamageRate == tbData2.nDamageRate then
        return tbData1.nIndex < tbData2.nIndex
    else
        return tbData1.nDamageRate > tbData2.nDamageRate
    end
end

function UPBattleDeadPlaybackItem:OnLoad()
    self.tbDamageWeaponScript = {}
    local PrefabHelper = self.PrefabHelper
    local pWidgetRef = self.pWidgetRef
    for i = 1, MAX_COUNT do
        local pbDamageWeapon = PrefabHelper:BindPrefab(pWidgetRef["pbDamageWeapon_"..i])
        table.insert(self.tbDamageWeaponScript, pbDamageWeapon) 
    end
end

function UPBattleDeadPlaybackItem:SetData(tbData, nIndex)
    local pWidgetRef = self.pWidgetRef
    if not tbData then
        pWidgetRef:SetVisibility(ESlateVisibility_Collapsed)
        return 
    end 
    pWidgetRef:SetVisibility(ESlateVisibility_SelfHitTestInvisible)
    if nIndex == 1 then
        --击倒背景颜色
        UISetUtils.SetImageBrushTint(pWidgetRef.imgBg02, KILL_BG_COLOR)
        UISetUtils.SetImageBrushTint(pWidgetRef.imgBg03, KILL_TITLE_COLOR)
    end
    
    for k, v in ipairs(tbData.DeathPlaybackWeapons) do
        v.nIndex = k
    end
    table.sort(tbData.DeathPlaybackWeapons, SortFunc)
    --回放伤害来源分类：
    pWidgetRef.txtPlaybackCause:SetText(CAUSE_TEXT[nIndex])
    
    
    local szHeadIconPath = nil
    local l10nNameText = nil
    if tbData.nCauserType == DamageCauserType.PLAYER or tbData.nCauserType == DamageCauserType.BOT or tbData.nCauserType == DamageCauserType.NPC then
        local nTemplateId = tbData.nTemplateId
        l10nNameText = tbData.szName
        if tbData.nCauserType == DamageCauserType.NPC then
            local tbNpcTemplate = NPCDataTable:GetTemplate(tbData.nTemplateId)
            if tbNpcTemplate then
                l10nNameText = tbNpcTemplate.l10nName
                nTemplateId = tbNpcTemplate.nTypeID
            end
        end
        if tbData.nTemplateType == TemplateTypeDef.HUMAN then
            --人
            local HumanTemplate = AvatarDataTable:GetTemplate(nTemplateId)
            if HumanTemplate then
                szHeadIconPath = HeadIconResDataTable:GetResPath(HumanTemplate.nHeadIconId)
            else
                logerror("UPBattleDeadPlaybackItem:SetData,HumanTemplate is nil,templateid=", nTemplateId)
            end
            pWidgetRef.txtShipName:SetVisibility(ESlateVisibility_Collapsed)
        elseif tbData.nTemplateType == TemplateTypeDef.SHIP then
            --船
            local tbShipItemTemplate = ShipItemHelper.GetItemTemplateByShipTemplateId(nTemplateId)
            if tbShipItemTemplate then
                local tbResTemplate = BattleItemResDataTable:GetTemplate(tbShipItemTemplate.nResId)
                if tbResTemplate then
                    szHeadIconPath = tbResTemplate.szIconPath
                end
                pWidgetRef.txtShipName:SetVisibility(ESlateVisibility_SelfHitTestInvisible)
                pWidgetRef.txtShipName:SetText(tbShipItemTemplate.l10nName)
            else
                logerror("UPBattleDeadPlaybackItem:SetData,HumanTemplate is nil,templateid=", nTemplateId)
            end
        end
    else
        pWidgetRef.txtShipName:SetVisibility(ESlateVisibility_Collapsed)
        szHeadIconPath = UIResourceDef.DEAD_CAUSER_TYPE_ICON[tbData.nCauserType]
        l10nNameText = UITextDef.DEAD_CAUSER_NAME[tbData.nCauserType]
    end
    --头像图标
    if szHeadIconPath and szHeadIconPath ~= "" then
        local pIconObj = szHeadIconPath:load()
        if pIconObj then
            UISetUtils.SetImageBrushRes(pWidgetRef.imgHeadIcon, pIconObj)
        end
    else
        logerror("UPBattleDeadPlaybackItem:SetData, szHeadIconPath is nil", tbData.nCauserType)
    end
    --player name 
    if l10nNameText then
        pWidgetRef.txtPlayerName:SetText(l10nNameText)
    else
        pWidgetRef.txtPlayerName:SetText("Unknown")
        logerror("UPBattleDeadPlaybackItem:SetData,l10nNameText is nil, nCauserType =", tbData.nCauserType)
    end
    
    --
    for i = 1, MAX_COUNT do 
        self.tbDamageWeaponScript[i]:SetData(tbData.DeathPlaybackWeapons[i], tbData.nCauserType)
    end
end

function UPBattleDeadPlaybackItem:HideData()
    self.pWidgetRef:SetVisibility(ESlateVisibility_Collapsed)
end

return UPBattleDeadPlaybackItem
