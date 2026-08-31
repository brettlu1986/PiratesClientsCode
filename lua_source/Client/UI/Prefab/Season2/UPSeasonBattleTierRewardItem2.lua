local luaclass = require("luaclass")
local PrefabBase = require("PrefabBase")
local UPSeasonBattleTierRewardItem2 = luaclass("UPSeasonBattleTierRewardItem2", PrefabBase)
local LobbyItemUiHelper = require("LobbyItemUiHelper")
local ClientEventDef = require("ClientEventDef")
local DelayTimer = require("DelayTimer")
local UIDef = require("UIDef")
-- local SeasonSystem = require("SeasonSystem")
local DELAY_TIME = 0.1

UPSeasonBattleTierRewardItem2.pbLobbyItem = nil
UPSeasonBattleTierRewardItem2.tbData = nil
UPSeasonBattleTierRewardItem2.tbDelayTimer = nil

local EFFECT_IMAGES = {
    "imgGreen",
    "imgBlue",
    "imgPuple",
    "imgOrange"
}

local function OnClickedItem(self)
    local tbData = self.tbData
    if tbData ~= nil then 
        self.Owner:OnSelectItem(tbData.nTemplateId, tbData.nIndex, tbData.nTier, tbData.nEffectId, tbData.bAdvance, true)
        -- local tbPass = SeasonSystem:GetComponent():GetBattlePass()
        -- if tbPass.battle_tier_award_status[tbData.nTier] <= 0 then
        --     if self.bAsync then
        --         SeasonSystem:RequestReceiveBattleTierAward(tbData.nTier)
        --     end
        -- end 
    end
    -- return WidgetBlueprintLibrary.Handled()
end

local function OnSelected(self, nTemplateId, nIndex, nTier, nEffectId, bAdvance)
    if isvalidhandle(self.pbLobbyItem.pWidgetRef) then
        local tbData = self.tbData
        if tbData and tbData.nTemplateId == nTemplateId and tbData.nIndex == nIndex and tbData.nTier == nTier 
            and tbData.bAdvance == bAdvance then
            LobbyItemUiHelper.SetSelected(self.pbLobbyItem.pWidgetRef, true)
        else
            LobbyItemUiHelper.SetSelected(self.pbLobbyItem.pWidgetRef, false)
        end
    end
end

local function DestroyTimer(self)
    if self.tbDelayTimer ~= nil then
        DelayTimer:ClearTimer(self.tbDelayTimer)
        self.tbDelayTimer = nil
    end
end

function UPSeasonBattleTierRewardItem2:OnLoad()
    local pWidgetRef = self.pWidgetRef
    self.pbLobbyItem = self.PrefabHelper:BindPrefab(pWidgetRef.pbLobbyItem, UIDef.UP_LOBBY_DISPLAY_ITEM_ASYNC)
end

function UPSeasonBattleTierRewardItem2:OnUnload()
end

function UPSeasonBattleTierRewardItem2:OnDestroy()
    DestroyTimer(self)
    self.pbLobbyItem = nil
end

function UPSeasonBattleTierRewardItem2:OnRefresh(tbData, bAsync)--nItemTemplateId, nCount, bLock)
    local ESelfHitTestInvisible = ESlateVisibility_SelfHitTestInvisible
    local ECollapsed = ESlateVisibility_Collapsed
    local pWidgetRef = self.pWidgetRef
    self.tbData = tbData
    self.bAsync = bAsync
    if tbData then
        pWidgetRef.imgLock:SetVisibility(tbData.bLock and ESelfHitTestInvisible or ECollapsed)
        pWidgetRef.imgNeed:SetVisibility(tbData.bGeted and ESelfHitTestInvisible or ECollapsed)
        -- pWidgetRef.imgBlack:SetVisibility(tbData.bTierRech and ECollapsed or ESelfHitTestInvisible)
        pWidgetRef:SetVisibility(ESelfHitTestInvisible)
        for i, v in ipairs(EFFECT_IMAGES) do
            pWidgetRef[v]:SetVisibility(tbData.nEffectId == i and ESelfHitTestInvisible or ECollapsed)
        end 

        self.pbLobbyItem:SetDisplayItemData(tbData.nTemplateId, tbData.nCount, true, nil, nil, bAsync)
    else
        pWidgetRef:SetVisibility(ECollapsed)
    end

    pWidgetRef.cvsItem:SetVisibility(ECollapsed)
    local fnShowUI = function()
        DestroyTimer(self)
        pWidgetRef.cvsItem:SetVisibility(ESelfHitTestInvisible)
    end
    if bAsync then
        self.tbDelayTimer = DelayTimer:DelayRun(fnShowUI, DELAY_TIME)
    else
        fnShowUI()
    end    
end

function UPSeasonBattleTierRewardItem2:OnBindEvent(EventHelper)
    -- EventHelper:RegisterCppDelegate(self.pbLobbyItem.pWidgetRef.imgItem.OnMouseButtonUpEvent, self, OnClickedItem)
    EventHelper:RegisterCppDelegate(self.pbLobbyItem.pWidgetRef.btnItem.OnClicked, self, OnClickedItem)
    EventHelper:RegisterEvent(ClientEventDef.EV_ON_SELECT_AWARD, self, OnSelected)
end

return UPSeasonBattleTierRewardItem2