local luaclass = require("luaclass")
local UILogicBase = require("UILogicBase")
local ULScheduleCommon = luaclass("ULScheduleCommon", UILogicBase)
local UIManager = require("UIManager")
local UIDef = require("UIDef")
local ScheduleUITable = require("ScheduleUITable")

local SHOW_WIDGETS = {
    -- ["vbGo"] = true
}

local COMMON_IDS = {
    SEVEN_DAY = 2,
    NOOB_LOGIN = 3,
    CONTINUOUS = 5
}

function ULScheduleCommon:Activate(tbAllWidget)
    local pWidgetRef = self.pWidgetRef

    for i, v in ipairs(tbAllWidget) do
        pWidgetRef[v]:SetVisibility(SHOW_WIDGETS[v] and ESlateVisibility_SelfHitTestInvisible or ESlateVisibility_Collapsed)
    end    

    local tbTemp = ScheduleUITable:GetTemplate(self.nId)
    -- pWidgetRef.txtDesc:SetText(tbTemp.l10nDesc)
    if tbTemp.tbGoPos ~= nil then
        pWidgetRef.btnGo:SetVisibility(ESlateVisibility_Visible)
        pWidgetRef.btnGo.Slot:SetPosition(Vector2D{X=tbTemp.tbGoPos[1], Y=tbTemp.tbGoPos[2]})
    else
        pWidgetRef.btnGo:SetVisibility(ESlateVisibility_Collapsed)
    end
end

function ULScheduleCommon:Deactivate()
end

function ULScheduleCommon:OnLoad()
end

function ULScheduleCommon:OnBindEvent(EventHelper)
    -- EventHelper:RegisterCppDelegate(self.pWidgetRef.btnAward.OnClicked,  self, OnClickedAward)
    -- EventHelper:RegisterCppDelegate(self.pWidgetRef.btnChest.OnClicked,  self, OnClickedChest)
    -- EventHelper:RegisterEvent(ClientEventDef.EV_ON_REFRESH_SEASON_RANK, self, OnRefreshSeasonRank)   
    -- EventHelper:RegisterEvent(ClientEventDef.EV_ON_GET_SEASON_DATA, self, OnRecvSeasonData)     
end

function ULScheduleCommon:OnClickedGo()
    if self.nId == COMMON_IDS.NOOB_LOGIN then
        UIManager:OpenWnd(UIDef.UI_SCHEDULE_NOOB_LOGIN, {szFrom = UIDef.UI_SCHEDULE, nId = COMMON_IDS.NOOB_LOGIN})
    elseif self.nId == COMMON_IDS.CONTINUOUS then
        UIManager:OpenWnd(UIDef.UI_SCHEDULE_CONTINUOUS, {szFrom = UIDef.UI_SCHEDULE, nId = COMMON_IDS.CONTINUOUS}) 
    end
    UIManager:CloseWnd(UIDef.UI_SCHEDULE)
end

return ULScheduleCommon