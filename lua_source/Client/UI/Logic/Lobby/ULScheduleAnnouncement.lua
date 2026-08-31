local luaclass = require("luaclass")
local UILogicBase = require("UILogicBase")
local ULScheduleAnnouncement = luaclass("ULScheduleAnnouncement", UILogicBase)
local SaveGameDef = require("SaveGameDef")

local SHOW_WIDGETS = {
    ["brAnnouncement"] = true
}

local function SetUseDefaultSaveId(bValue)
    local pSaveGameMgr = ClientShell.GetClient(GWorld):GetSaveGameManager()
    pSaveGameMgr:SetUseDefaultUserId(bValue)
end

function ULScheduleAnnouncement:Activate(tbAllWidget)
    local pWidgetRef = self.pWidgetRef

    for i, v in ipairs(tbAllWidget) do
        pWidgetRef[v]:SetVisibility(SHOW_WIDGETS[v] and ESlateVisibility_SelfHitTestInvisible or ESlateVisibility_Collapsed)
    end

    SetUseDefaultSaveId(true)
    local pSaveGameMgr = ClientShell.GetClient(GWorld):GetSaveGameManager()
    local szContent = pSaveGameMgr:GetStringData(SaveGameDef.LOGIN_ANNOUNCEMENT)
    SetUseDefaultSaveId(false)
    self.pWidgetRef.txtMessage:SetText(szContent)
end

function ULScheduleAnnouncement:Deactivate()
end

function ULScheduleAnnouncement:OnLoad()
end

function ULScheduleAnnouncement:OnBindEvent(EventHelper)
    -- EventHelper:RegisterCppDelegate(self.pWidgetRef.btnAward.OnClicked,  self, OnClickedAward)
    -- EventHelper:RegisterCppDelegate(self.pWidgetRef.btnChest.OnClicked,  self, OnClickedChest)
    -- EventHelper:RegisterEvent(ClientEventDef.EV_ON_REFRESH_SEASON_RANK, self, OnRefreshSeasonRank)   
    -- EventHelper:RegisterEvent(ClientEventDef.EV_ON_GET_SEASON_DATA, self, OnRecvSeasonData)     
end

return ULScheduleAnnouncement