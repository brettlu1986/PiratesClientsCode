local luaclass = require("luaclass")
local ListItemBase = require("ListItemBase")
local UPSeasonChallengeTaskItem2 = luaclass("UPSeasonChallengeTaskItem2", ListItemBase)
local UIDef = require("UIDef")
local ChallengeSubIndexDataTable = require("ChallengeSubIndexDataTable")
local UISetUtils = require("UISetUtils")
local SeasonSystem = require("SeasonSystem")
local L10N = require("L10N")
local AwardDataTable = require("AwardDataTable")
local ScheduleSystem = require("ScheduleSystem")

local nMaxRewardItems = 2
UPSeasonChallengeTaskItem2.tbData = nil
UPSeasonChallengeTaskItem2.tbChallengeData = nil
UPSeasonChallengeTaskItem2.tbRewardItems = nil

local function RefreshAward(self)
    local nItemId, nMultiple = ScheduleSystem:GetAwardMultiple()

    local Collapsed, Visible = ESlateVisibility.Collapsed, ESlateVisibility.Visible
    local nAwardId = self.tbChallengeData.nAwardId
    local tbAward = AwardDataTable:GetAwardItem(nAwardId)
    local nCount = math.min(tbAward and #tbAward or 0, nMaxRewardItems)
    for i = 1, nCount do
        self.tbRewardItems[i].pWidgetRef:SetVisibility(Visible)
        local nTemp = nItemId and nItemId == tbAward[i].nItemId and nMultiple
        self.tbRewardItems[i]:SetDisplayItemData(tbAward[i].nItemId, tbAward[i].nCount, true, false, nTemp)    
    end
    for i = nCount + 1, nMaxRewardItems do
        self.tbRewardItems[i].pWidgetRef:SetVisibility(Collapsed)
    end
end

local function RefreshTask(self)
    local pWidgetRef = self.pWidgetRef
    local Collapsed, Hidden, SelfHitTestInvisible, Visible = ESlateVisibility_Collapsed, ESlateVisibility_Hidden,
        ESlateVisibility_SelfHitTestInvisible, ESlateVisibility_Visible
    local nCurProgress, nMaxProgress = self.tbData.nProgress, self.tbChallengeData.nObjectiveEnd

    local tbData = self.tbData
    if tbData.bOver ~= nil then
        pWidgetRef.txtPercent:SetVisibility(Collapsed)
        pWidgetRef.imgOver:SetVisibility(Collapsed)
        pWidgetRef.btnGet:SetVisibility(Hidden)
        pWidgetRef.txtOver:SetVisibility(SelfHitTestInvisible)
        pWidgetRef.txtOver:SetText(UISetUtils.GetL10NTextByKey("CHALLENGE_OVER"))
    elseif tbData.bComplete then
        pWidgetRef.txtPercent:SetVisibility(Collapsed)
        pWidgetRef.imgOver:SetVisibility(SelfHitTestInvisible)
        pWidgetRef.btnGet:SetVisibility(Hidden)
        pWidgetRef.txtOver:SetVisibility(Collapsed)

        -- pWidgetRef.txtPercent:SetText(string.format("%d/%d", nMaxProgress, nMaxProgress))
    else
        pWidgetRef.txtPercent:SetVisibility(SelfHitTestInvisible)
        pWidgetRef.imgOver:SetVisibility(Collapsed)
        pWidgetRef.txtOver:SetVisibility(Collapsed)
        if nCurProgress >= nMaxProgress then
            pWidgetRef.btnGet:SetVisibility(Visible)
            pWidgetRef.txtPercent:SetText("")
        else
            pWidgetRef.btnGet:SetVisibility(Hidden)
            pWidgetRef.txtPercent:SetText(string.format("<text color=\"#D27D00FF\">%d</>/<text color=\"#FFFFFFFF\">%d</>", nCurProgress, nMaxProgress))
        end
    end
    pWidgetRef.txtName:SetText(L10N:Format(self.tbChallengeData.l10nDesc, nMaxProgress))
    RefreshAward(self)
end

local function OnClickGetAward(self)
    local tbData = self.tbData
    if tbData.nType ~= nil and tbData.nProgress >= self.tbChallengeData.nObjectiveEnd then
        SeasonSystem:RequestChallengeSubAward(tbData.nType, tbData.nId)
    end
end

function UPSeasonChallengeTaskItem2:OnRefresh(tbData)
    self.tbData = tbData
    self.tbChallengeData = ChallengeSubIndexDataTable:GetTemplate(tbData.nType, tbData.nId)
    RefreshTask(self)
end

function UPSeasonChallengeTaskItem2:OnShow()
    self.pWidgetRef.txtGet:SetVisibility(ESlateVisibility_Collapsed)
end

function UPSeasonChallengeTaskItem2:OnLoad()
    local pWidgetRef = self.pWidgetRef
    self.tbRewardItems  = { }
    for i=1,nMaxRewardItems do
        local pbRewardItem = self.PrefabHelper:BindPrefab(pWidgetRef["pbReward0" .. i], UIDef.UP_LOBBY_DISPLAY_ITEM)
        table.insert(self.tbRewardItems , pbRewardItem)
    end
end

function UPSeasonChallengeTaskItem2:OnBindEvent(EventHelper)
    EventHelper:RegisterCppDelegate(self.pWidgetRef.btnGet.OnClicked, self, OnClickGetAward)
end

return UPSeasonChallengeTaskItem2