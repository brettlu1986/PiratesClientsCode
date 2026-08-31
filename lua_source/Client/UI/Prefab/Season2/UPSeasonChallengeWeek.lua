local luaclass = require("luaclass")
local ListItemBase = require("ListItemBase")
local UPSeasonChallengeWeek = luaclass("UPSeasonChallengeWeek", ListItemBase)
local UISetUtils = require("UISetUtils")
local L10N = require("L10N")
local UIResourceDef = require("UIResourceDef")
local UIUtils = require("UIUtils")

UPSeasonChallengeWeek.nWeek = nil
UPSeasonChallengeWeek.bSelected = nil
UPSeasonChallengeWeek.nRealCurWeek = nil

local SLATE_WHITE_ALPHA = KMUMGLibrary.GetSlateColor(1.0, 1.0, 1.0, 0.0)

local function RefreshUI(self, nIndex, bSelected, nRealCurWeek, nCompleteCount, nUnCompleteCount)
    local pWidgetRef = self.pWidgetRef
    pWidgetRef.txtWeek:SetText(L10N:Format(UISetUtils.GetL10NTextByKey("LOBBY_SEASON_CHALLENGE_WEEK"), nIndex))
    if bSelected then
        UISetUtils.SetButtonBrushTint(pWidgetRef.btnWeek, UIResourceDef.COLOR.WHITE.SLATE_COLOR)
    else
        UISetUtils.SetButtonBrushTint(pWidgetRef.btnWeek, SLATE_WHITE_ALPHA)
    end
    if nRealCurWeek == nIndex then
        pWidgetRef.txtProgress:SetVisibility(ESlateVisibility_SelfHitTestInvisible)
        pWidgetRef.txtProgress:SetText(string.format("%d/%d", nCompleteCount, nCompleteCount + nUnCompleteCount))
        pWidgetRef.txtProgress:SetColorAndOpacity(UIResourceDef.COLOR.WHITE.SLATE_COLOR)
        pWidgetRef.imgLock:SetVisibility(ESlateVisibility_Collapsed)
    elseif nRealCurWeek > nIndex then
        pWidgetRef.txtProgress:SetVisibility(ESlateVisibility_SelfHitTestInvisible)
        pWidgetRef.txtProgress:SetText(UISetUtils.GetL10NTextByKey("CHALLENGE_OVER"))
        pWidgetRef.txtProgress:SetColorAndOpacity(UIResourceDef.COLOR.GREY.SLATE_COLOR)
        pWidgetRef.imgLock:SetVisibility(ESlateVisibility_Collapsed)
    else
        pWidgetRef.txtProgress:SetVisibility(ESlateVisibility_Collapsed)
        pWidgetRef.imgLock:SetVisibility(ESlateVisibility_SelfHitTestInvisible)
    end
end

local function OnClickedWeek(self)
    if not self.bSelected then 
        if self.nWeek > self.nRealCurWeek then
            UIUtils.ShowToast(UISetUtils.GetL10NTextByKey("LOBBY_SEASON_CHALLENGE_UNREACH_TIME"))
        else
            self.ListHelper.Owner:OnSelectWeek(self.nWeek)
        end
    end
end

function UPSeasonChallengeWeek:OnRefresh(tbData)
    self.nWeek = tbData.nIndex
    self.bSelected = tbData.bSelected
    self.nRealCurWeek = tbData.nRealCurWeek
    RefreshUI(self, tbData.nIndex, tbData.bSelected, tbData.nRealCurWeek, tbData.nCompleteCount, tbData.nUnCompleteCount)
end

function UPSeasonChallengeWeek:OnLoad()

end

function UPSeasonChallengeWeek:OnShow()
end

function UPSeasonChallengeWeek:OnUnload()
end

function UPSeasonChallengeWeek:OnBindEvent(EventHelper)
    EventHelper:RegisterCppDelegate(self.pWidgetRef.btnWeek.OnClicked, self, OnClickedWeek)
end

return UPSeasonChallengeWeek