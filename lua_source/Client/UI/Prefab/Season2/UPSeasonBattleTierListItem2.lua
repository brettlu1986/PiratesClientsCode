local luaclass = require("luaclass")
local ListItemBase = require("ListItemBase")
local UPSeasonBattleTierListItem2 = luaclass("UPSeasonBattleTierListItem2", ListItemBase)
local SeasonSystem = require("SeasonSystem")
local UIDef = require("UIDef")
local L10N = require("L10N")
local UITextDef = require("UITextDef")
local ClientEventDef = require("ClientEventDef")
local BattleTierRewardEffectDataTable = require("BattleTierRewardEffectDataTable")
local AwardDataTable = require("AwardDataTable")

UPSeasonBattleTierListItem2.SeasonComponent = nil
UPSeasonBattleTierListItem2.tbData         = nil
UPSeasonBattleTierListItem2.bIsNextMileStoneReward = nil
UPSeasonBattleTierListItem2.tbNormalItems  = nil
UPSeasonBattleTierListItem2.tbAdvanceItems = nil

local nMaxNormalItems  = 1
local nMaxAdvanceItems = 2

local function GetRewards(tbData)
    local tbNormalItems = AwardDataTable:GetAwardItem(tbData.nWarriorAwardId) or {}
    local tbAdvanceItems = AwardDataTable:GetAwardItem(tbData.nHeroAwardId) or {}
    local tbNormalItemEffects = BattleTierRewardEffectDataTable:GetWarriorAwardEffectTemplate(tbData.nTier)
    local tbAdvanceItemEffects = BattleTierRewardEffectDataTable:GetHeroAwardEffectTemplate(tbData.nTier)

    return tbNormalItems, tbAdvanceItems, tbNormalItemEffects, tbAdvanceItemEffects
end

local function GetEffectId(tbItemEffects, nIndex)
    local nEffectId = 0
    if tbItemEffects == nil then
        return nEffectId
    end
    for i, v in ipairs(tbItemEffects) do
        if nIndex == i then
            nEffectId = v.nEffect
            break
        end
    end
    return nEffectId
end

local function OnRecvSeasonBattleTierAward(self, nTier)
    if nTier and self.tbData and nTier == self.tbData.nTier then
        self:OnRefresh(self.tbData, self.bIsNextMileStoneReward)
    end
end

local function OnClickedGet(self)
    local tbPass = SeasonSystem:GetComponent():GetBattlePass()
    if tbPass and tbPass.battle_tier_award_status[self.tbData.nTier] <= 0 then
        SeasonSystem:RequestReceiveBattleTierAward(self.tbData.nTier)
    end 
end

function UPSeasonBattleTierListItem2:HideBackImage()
    local pWidgetRef = self.pWidgetRef
    pWidgetRef.imgUp:SetVisibility(ESlateVisibility_Hidden)  
    pWidgetRef.imgDown:SetVisibility(ESlateVisibility_Hidden)  
end

function UPSeasonBattleTierListItem2:OnRefresh(tbData, bIsNextMileStoneReward)
    self.tbData = tbData
    self.bIsNextMileStoneReward = bIsNextMileStoneReward

    local pWidgetRef = self.pWidgetRef
    local SeasonComponent = self.SeasonComponent
    local tbBattlePass = SeasonComponent:GetBattlePass()

    local nItemBattleTierLevel = tbData.nTier
    local nCurrentBattleTier = tbBattlePass.battle_tier
    local Hidden, Collapsed, SelfHitTestInvisible, Visible = ESlateVisibility_Hidden, ESlateVisibility_Collapsed, 
        ESlateVisibility_SelfHitTestInvisible, ESlateVisibility_Visible
    -- 战阶
    pWidgetRef.txtLevel:SetText(L10N:Format(UITextDef.COMMON_PLAYER_LEVEL, nItemBattleTierLevel))

    local bTierRech = nItemBattleTierLevel <= nCurrentBattleTier or bIsNextMileStoneReward
    pWidgetRef.ImageLockNormal:SetVisibility(bTierRech and Collapsed or SelfHitTestInvisible)
    pWidgetRef.imgLockAdvance:SetVisibility(bTierRech and Collapsed or SelfHitTestInvisible)

    local tbNormalItems, tbAdvanceItems, tbNormalItemEffects, tbAdvanceItemEffects = GetRewards(tbData)
    local bNormalGeted = tbBattlePass.battle_tier_award_status[nItemBattleTierLevel] > 0

    local bCanGet = false
    for i, v in ipairs(self.tbNormalItems) do
        local tbItemData = tbNormalItems[i]
        local bLock = not bTierRech
        local nEffectId = GetEffectId(tbNormalItemEffects, i)
        if not bCanGet then
            bCanGet = tbItemData ~= nil and (not bNormalGeted and not bLock) 
        end
        if tbItemData then
            local tbItem = {nIndex = i, nTemplateId= tbItemData.nItemId, nCount = tbItemData.nCount, 
                bLock = bLock, bGeted = bNormalGeted, nTier = nItemBattleTierLevel, nEffectId = nEffectId, bAdvance = false, bTierRech = bTierRech}
            v:OnRefresh(tbItem, not bIsNextMileStoneReward)
        else
            if i == 1 then
                v.pWidgetRef:SetVisibility(Hidden)
            else
                v:OnRefresh(nil)
            end
        end
    end
    local bActive = SeasonComponent:IsPassActive()
    local bAdvanceGeted = bActive and tbBattlePass.battle_tier_award_status[nItemBattleTierLevel] > 0
    for i, v in ipairs(self.tbAdvanceItems) do
        local tbItemData = tbAdvanceItems[i]
        local bLock = ((not bTierRech) or (not bActive)) and (not bIsNextMileStoneReward)
        local nEffectId = GetEffectId(tbAdvanceItemEffects, i)
        if not bCanGet then
            bCanGet = tbItemData ~= nil and (bActive and not bAdvanceGeted and not bLock) 
        end
        if tbItemData then
            local tbItem = {nIndex = i, nTemplateId= tbItemData.nItemId, 
                nCount = tbItemData.nCount, bLock = bLock, bGeted = bAdvanceGeted, nTier = nItemBattleTierLevel, 
                nEffectId = nEffectId, bAdvance = true, bTierRech = bTierRech}
            v:OnRefresh(tbItem, not bIsNextMileStoneReward)
        else
            if i == 2 then
                v.pWidgetRef:SetVisibility(Hidden)
            else 
                v:OnRefresh(nil)
            end
        end
    end

    if bCanGet and nItemBattleTierLevel <= nCurrentBattleTier then
        pWidgetRef.btnGet:SetVisibility(Visible)
        pWidgetRef.txtLevel:SetVisibility(Hidden)
        pWidgetRef.imgLine:SetVisibility(Hidden)
    else
        pWidgetRef.btnGet:SetVisibility(Collapsed)
        pWidgetRef.txtLevel:SetVisibility(SelfHitTestInvisible)
        pWidgetRef.imgLine:SetVisibility(SelfHitTestInvisible)
    end
end

function UPSeasonBattleTierListItem2:OnSelectItem(nTemplateId, nSelectIndex, nTier, nEffectId, bAdvance, bForce)
    self.EventHelper:FireEvent(ClientEventDef.EV_ON_SELECT_AWARD, nTemplateId, nSelectIndex, nTier, nEffectId, bAdvance, bForce)
end

function UPSeasonBattleTierListItem2:OnLoad()
    local pWidgetRef = self.pWidgetRef
    self.SeasonComponent = SeasonSystem:GetComponent()
    self.tbNormalItems  = { }
    self.tbAdvanceItems = { }
    for i = 1, nMaxNormalItems do
        local pbRewardItem = self.PrefabHelper:BindPrefab(pWidgetRef["pbNormalReward0" .. i], UIDef.UP_SEASON_BATTLETIER_REWARDITEM)
        table.insert(self.tbNormalItems , pbRewardItem)
        pbRewardItem:SetOwner(self)
    end
    for i = 1, nMaxAdvanceItems do
        local pbRewardItem = self.PrefabHelper:BindPrefab(pWidgetRef["pbAdvanceReward0" .. i], UIDef.UP_SEASON_BATTLETIER_REWARDITEM)
        table.insert(self.tbAdvanceItems , pbRewardItem)
        pbRewardItem:SetOwner(self)
    end
end

function UPSeasonBattleTierListItem2:OnBindEvent(EventHelper)
    EventHelper:RegisterEvent(ClientEventDef.EV_SEASON_BATTLE_TIER_AWARD, self, OnRecvSeasonBattleTierAward)
    EventHelper:RegisterCppDelegate(self.pWidgetRef.btnGet.OnClicked, self, OnClickedGet)
end

function UPSeasonBattleTierListItem2:OnShow()
end

function UPSeasonBattleTierListItem2:OnHide()
end

return UPSeasonBattleTierListItem2