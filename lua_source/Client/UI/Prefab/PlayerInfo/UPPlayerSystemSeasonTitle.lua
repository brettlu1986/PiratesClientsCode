local luaclass = require("luaclass")
local ListItemBase = require("ListItemBase")
local UPPlayerSystemSeasonTitle = luaclass("UPPlayerSystemSeasonTitle", ListItemBase)
local SeasonSystem = require("SeasonSystem")
local UISetUtils = require("UISetUtils")

UPPlayerSystemSeasonTitle.tbSeasonTemplate = nil

local function OnClickSeason(self)
    self.ListHelper.Owner:SetCurSeason(self.tbSeasonTemplate.nSeasonId)
end

function UPPlayerSystemSeasonTitle:OnCreate()
    self.nPlayerId = self.Owner.nPlayerId
end

function UPPlayerSystemSeasonTitle:OnLoad()
end

function UPPlayerSystemSeasonTitle:OnBindEvent( EventHelper )
    EventHelper:RegisterCppDelegate(self.pWidgetRef.btnSeason.OnClicked, self, OnClickSeason)
end

function UPPlayerSystemSeasonTitle:OnDestroy()

end

function UPPlayerSystemSeasonTitle:OnUnload()
end

function UPPlayerSystemSeasonTitle:OnRefresh(tbData)
    self.tbSeasonTemplate = tbData

    local pWidgetRef = self.pWidgetRef 
    local Component = SeasonSystem:GetComponent()
    if tbData.nSeasonId == Component:GetSeasonId() then
        pWidgetRef.txtSeasonName:SetText(UISetUtils.GetL10NTextByKey("UI_SEASON_CURRENT"))
    else
        pWidgetRef.txtSeasonName:SetText(tbData.l10nName)
    end
    pWidgetRef.imgBg:SetVisibility(tbData.bSelect and ESlateVisibility.SelfHitTestInvisible or ESlateVisibility.Collapsed)
end

return UPPlayerSystemSeasonTitle