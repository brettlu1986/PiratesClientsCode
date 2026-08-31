local luaclass     = require ("luaclass")
local UPTipBase    = require("UPTipBase")
local UPSeasonTips = luaclass("UPSeasonTips", UPTipBase)
local L10N = require("L10N")
local UIResourceDef = require("UIResourceDef")
local UISetUtils = require("UISetUtils")

local function SetData(self, tbTipData)
    -- local tbTipData = {
    --     nTier = tbBattlePass.battle_tier,
    --     bActive = bPassActive
    -- }
    local pWidgetRef = self.pWidgetRef
    local pbLobbyItem = pWidgetRef.pbLobbyItem
    if tbTipData.bActive then
        pWidgetRef.txtName:SetText(L10N:Format(UISetUtils.GetL10NTextByKey("SEASON_BATTLE_PASS_TIER"), UISetUtils.GetL10NTextByKey("SEASON_BATTLE_HERO"), tbTipData.nTier))    
        UISetUtils.SetButtonBrushRes(pbLobbyItem.btnItem, UIResourceDef.SEASON_PASS_ACITVE_IMAGE:load())   
    else
        pWidgetRef.txtName:SetText(L10N:Format(UISetUtils.GetL10NTextByKey("SEASON_BATTLE_PASS_TIER"), UISetUtils.GetL10NTextByKey("SEASON_BATTLE_NORMAL"), tbTipData.nTier))    
        UISetUtils.SetButtonBrushRes(pbLobbyItem.btnItem, UIResourceDef.SEASON_PASS_UNACITVE_IMAGE:load())   
    end
    pWidgetRef.kmtxtDesc:SetText("")
    pbLobbyItem.txtCount:SetText("")    
end

local function Init(self)
    local tbTipData = self.tbTipData
    if (tbTipData == nil) then
        return
    end
    SetData(self, tbTipData)
end

function UPSeasonTips:OnLoad()
end

function UPSeasonTips:OnShow()
    Init(self)
end

return UPSeasonTips
