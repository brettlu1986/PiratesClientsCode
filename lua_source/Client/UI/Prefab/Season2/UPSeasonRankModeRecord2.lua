local luaclass = require("luaclass")
local PrefabBase = require("PrefabBase")
local UPSeasonRankModeRecord2 = luaclass("UPSeasonRankModeRecord2", PrefabBase)
local UITextDef = require("UITextDef")

UPSeasonRankModeRecord2.tbData = nil
UPSeasonRankModeRecord2.pbRank = nil

local INFOS = {
    {Field = "matches",         Title = UITextDef.STATISTIC_BASE_GAME_COUNT},
    {Field = "wins",            Title = UITextDef.STATISTIC_BASE_WIN_COUNT},
    {Field = "top_ten",         Title = UITextDef.STATISTIC_BASE_RANKTOP10_COUNT},
    {Field = "kill_death_rate", Title = UITextDef.STATISTIC_BASE_KILLDEAD_COUNT},
}

local function RefreshUI(self)
    local tbData = self.tbData
    self.pbRank:OnRefresh({
        mode = tbData.mode,
        rank_point = tbData.rank_point,
        rank = tbData.rank,
        hide_rank = true
    })

    local pWidgetRef = self.pWidgetRef
    for i, v in ipairs(INFOS) do
        pWidgetRef["txtKey"..i]:SetText(v.Title)
        pWidgetRef["txtValue"..i]:SetText(tbData[v.Field])
    end
end

function UPSeasonRankModeRecord2:OnLoad()
    local pWidgetRef = self.pWidgetRef
    self.pbRank = self.PrefabHelper:BindPrefab(pWidgetRef.pbRank)
end

function UPSeasonRankModeRecord2:OnBindEvent(EventHelper)
end

function UPSeasonRankModeRecord2:OnRefresh(tbData)
    self.tbData = tbData
    RefreshUI(self)
end

function UPSeasonRankModeRecord2:OnDestroy()
    self.tbData = nil
end

return UPSeasonRankModeRecord2