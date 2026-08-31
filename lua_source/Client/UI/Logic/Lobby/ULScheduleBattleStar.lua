local luaclass = require("luaclass")
local UILogicBase = require("UILogicBase")
local ULScheduleBattleStar = luaclass("ULScheduleBattleStar", UILogicBase)
local UIDef = require("UIDef")
local LobbySystem = require("LobbySystem")
local LobbySubTypeDef = require("LobbySubTypeDef")
local GlobalVariableSystem_C = require("GlobalVariableSystem_C")
local ScheduleSystem = require("ScheduleSystem")
local ScheduleUITable = require("ScheduleUITable")
local ClientEventDef = require("ClientEventDef")
-- local UIManager = require("UIManager")
local TimeUtil = require("TimeUtil")
local UISetUtils = require("UISetUtils")
local Timer = require("Timer")

local SHOW_WIDGETS = {
    -- ["vbGo"] = true,
    ["hboxBattleStarTime"] = true,
    ["btnGo2"] = true
}

local BATTLE_STAR_ID = 4 

local NUMBER_IMG = {
    "PaperSprite'/Game/UI/Textures/LobbyActivity/Frames/Spr_ActivityNumber0.Spr_ActivityNumber0'",
    "PaperSprite'/Game/UI/Textures/LobbyActivity/Frames/Spr_ActivityNumber1.Spr_ActivityNumber1'",
    "PaperSprite'/Game/UI/Textures/LobbyActivity/Frames/Spr_ActivityNumber2.Spr_ActivityNumber2'",
    "PaperSprite'/Game/UI/Textures/LobbyActivity/Frames/Spr_ActivityNumber3.Spr_ActivityNumber3'",
    "PaperSprite'/Game/UI/Textures/LobbyActivity/Frames/Spr_ActivityNumber4.Spr_ActivityNumber4'",
    "PaperSprite'/Game/UI/Textures/LobbyActivity/Frames/Spr_ActivityNumber5.Spr_ActivityNumber5'",
    "PaperSprite'/Game/UI/Textures/LobbyActivity/Frames/Spr_ActivityNumber6.Spr_ActivityNumber6'",
    "PaperSprite'/Game/UI/Textures/LobbyActivity/Frames/Spr_ActivityNumber7.Spr_ActivityNumber7'",
    "PaperSprite'/Game/UI/Textures/LobbyActivity/Frames/Spr_ActivityNumber8.Spr_ActivityNumber8'",
    "PaperSprite'/Game/UI/Textures/LobbyActivity/Frames/Spr_ActivityNumber9.Spr_ActivityNumber9'",
}

local TIME_COUNT = 3
local INTERVAL = 60

ULScheduleBattleStar.tbTimer = nil

local function OnCompleteTimer(self)
    self.pWidgetRef.hboxBattleStarTime:SetVisibility(ESlateVisibility_Collapsed)
end

local function SetTimeImage(pWidgetRef, szWidgetName, nTime)
    if nTime <= 0 then
        for i = 0, TIME_COUNT - 1 do
            pWidgetRef[szWidgetName..i]:SetVisibility(ESlateVisibility_Collapsed)
        end
        return
    end
    local nTime1 = math.floor(nTime / 10)
    local nTime2 = nTime - nTime1 * 10
    if nTime1 > 0 then
        pWidgetRef[szWidgetName..1]:SetVisibility(ESlateVisibility_SelfHitTestInvisible)
        UISetUtils.SetImageBrushRes(pWidgetRef[szWidgetName..1], NUMBER_IMG[nTime1 + 1]:load())
    else
        pWidgetRef[szWidgetName..1]:SetVisibility(ESlateVisibility_Collapsed)
    end
    pWidgetRef[szWidgetName..2]:SetVisibility(ESlateVisibility_SelfHitTestInvisible)
    UISetUtils.SetImageBrushRes(pWidgetRef[szWidgetName..2], NUMBER_IMG[nTime2 + 1]:load())
end

local function DestroyTimer(self)
    if self.tbTimer then
        self.tbTimer:Clear()
        self.tbTimer = nil
    end
end

local function RefreshUI(self)
    local Component = ScheduleSystem:GetComponent()
    local nTime = Component:GetBattleStarCloseTime()
    local nCurTime = GlobalVariableSystem_C:GetServerTimeUtc()
    local nRemainTime = nTime and nTime - nCurTime
    log("ULScheduleBattleStar refresh ", nCurTime)

    if nRemainTime then
        local pWidgetRef = self.pWidgetRef
        local nDay, nHour, nMin = TimeUtil.TimeToDHMS(nRemainTime)
        SetTimeImage(pWidgetRef, "imgTimeDay", nDay)
        SetTimeImage(pWidgetRef, "imgTimeHour", nHour)
        SetTimeImage(pWidgetRef, "imgTimeMiu", nMin)
        if self.tbTimer == nil then
            self.tbTimer = Timer.NewTimerMethod(self, RefreshUI, INTERVAL, true)
        end
    else
        DestroyTimer(self)
        OnCompleteTimer(self)
    end
end

local function OnClickedGo(self)
    -- UIManager:CloseWnd(UIDef.UI_SCHEDULE)
    -- UIManager:OpenWnd(UIDef.UI_SEASON_CHALLENGE, {szFrom = UIDef.UI_SCHEDULE, nId = BATTLE_STAR_ID})
    self.EventHelper:FireEvent(ClientEventDef.EV_ON_PAUSE_POP)
    if self.Owner.tbOpenArgs.szFrom == UIDef.UI_SCHEDULE_CHEST_POP then
        local tbUINames = {UIDef.UI_SCHEDULE_CHEST_POP, UIDef.UI_SCHEDULE}
        LobbySystem:Activate(LobbySubTypeDef.SEASON, {szUIName = UIDef.UI_SEASON_CHALLENGE, tbOpenArgs = {szFrom = UIDef.UI_SCHEDULE, nId = BATTLE_STAR_ID, tbUINames = tbUINames}})
    else
        LobbySystem:Activate(LobbySubTypeDef.SEASON, {szUIName = UIDef.UI_SEASON_CHALLENGE, tbOpenArgs = {szFrom = UIDef.UI_SCHEDULE, nId = BATTLE_STAR_ID}})
    end
end

function ULScheduleBattleStar:Activate(tbAllWidget)
    self.EventHelper:FireEvent(ClientEventDef.EV_ON_RESUME_POP)
    local pWidgetRef = self.pWidgetRef

    for i, v in ipairs(tbAllWidget) do
        pWidgetRef[v]:SetVisibility(SHOW_WIDGETS[v] and ESlateVisibility_SelfHitTestInvisible or ESlateVisibility_Collapsed)
    end

    local tbTemp = ScheduleUITable:GetTemplate(self.nId)
    -- pWidgetRef.txtDesc:SetText(tbTemp.l10nDesc)
    if tbTemp.tbGoPos ~= nil then
        pWidgetRef.btnGo2:SetVisibility(ESlateVisibility_Visible)
        pWidgetRef.btnGo2.Slot:SetPosition(Vector2D{X=tbTemp.tbGoPos[1], Y=tbTemp.tbGoPos[2]})
    else
        pWidgetRef.btnGo2:SetVisibility(ESlateVisibility_Collapsed)
    end
    RefreshUI(self)
end

function ULScheduleBattleStar:Deactivate()
    DestroyTimer(self)
end

function ULScheduleBattleStar:OnLoad()
end

function ULScheduleBattleStar:OnBindEvent(EventHelper)
    EventHelper:RegisterCppDelegate(self.pWidgetRef.btnGo2.OnClicked,  self, OnClickedGo)
    -- EventHelper:RegisterCppDelegate(self.pWidgetRef.btnChest.OnClicked,  self, OnClickedChest)
    -- EventHelper:RegisterEvent(ClientEventDef.EV_ON_REFRESH_SEASON_RANK, self, OnRefreshSeasonRank)   
    -- EventHelper:RegisterEvent(ClientEventDef.EV_ON_GET_SEASON_DATA, self, OnRecvSeasonData)     
end

function ULScheduleBattleStar:OnDestroy()
    DestroyTimer(self)
end

return ULScheduleBattleStar