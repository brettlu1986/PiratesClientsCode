local luaclass = require("luaclass")
local PrefabBase = require("PrefabBase")
local UPSeasonBattlePassAward = luaclass("UPSeasonBattlePassAward", PrefabBase)
local UISetUtils = require("UISetUtils")

UPSeasonBattlePassAward.pbItem = nil

function UPSeasonBattlePassAward:OnRefresh(szIcon, l10nDesc)
    local pWidgetRef = self.pWidgetRef
    UISetUtils.SetButtonBrushRes(pWidgetRef.pbItem.btnItem, szIcon:load())
    pWidgetRef.pbItem.imgSelected:SetVisibility(ESlateVisibility_Collapsed)
    self.pWidgetRef.txtContent:SetText(l10nDesc)
    pWidgetRef.pbItem.txtCount:SetText("")
end

function UPSeasonBattlePassAward:OnLoad()
end

function UPSeasonBattlePassAward:OnDestroy()
end

return UPSeasonBattlePassAward