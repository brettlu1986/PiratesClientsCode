local luaclass = require("luaclass")
local UPScheduleTabBase = require("UPScheduleTabBase")
local UPScheduleTabFixedAward = luaclass("UPScheduleTabFixedAward", UPScheduleTabBase)
local ClientEventDef = require("ClientEventDef")
local TimedAwardDataTable = require("TimedAwardDataTable")
local AwardDataTable = require("AwardDataTable")
local GlobalVariableSystem_C = require("GlobalVariableSystem_C")
local UISetUtils = require("UISetUtils")
local ScheduleSystem = require("ScheduleSystem")
local Proto = require("ClientProtoNames")
local UIUtils= require("UIUtils")

local MAX_COUNT = 2

UPScheduleTabFixedAward.tbItems = nil


local function JointTime(nTime)
    return nTime < 10 and "0"..nTime or tostring(nTime)
end

local function RefreshIndex(self, pWidgetRef, tbTemplate, nState, nIndex)
    if tbTemplate == nil then
        logerror("ULScheduleFixedAward refresh index ", nIndex)
        return
    end
    local tbAwards = AwardDataTable:GetAwardItem(tbTemplate.nAwardId) 
    if tbAwards == nil or #tbAwards == 0 then
        logerror("ULScheduleFixedAward refresh index award is nil ", nIndex, tbTemplate.nAwardId)
    else
        self.tbItems[nIndex]:SetDisplayItemData(tbAwards[1].nItemId, tbAwards[1].nCount, true)
    end

    local szStartHour = JointTime(tbTemplate.nStartHour)
    local szStartMin  = JointTime(tbTemplate.nStartMin)
    local szStopHour = JointTime(tbTemplate.nStopHour)
    local szStopMin  = JointTime(tbTemplate.nStopMin)
    pWidgetRef["txtFixedTimeDesc"..nIndex]:SetText(tbTemplate.l10nDesc)
    pWidgetRef["txtFixedTime"..nIndex]:SetText(string.format("%s:%s-%s:%s", szStartHour, szStartMin, szStopHour, szStopMin))

    local nCurTime = GlobalVariableSystem_C:GetServerTimeUtc()
    local nCurHour = tonumber(os.date("%H",nCurTime))
    local nCurMin  = tonumber(os.date("%M",nCurTime))
    local nCurSec  = tonumber(os.date("%S",nCurTime))   
    local nCurHMS  = nCurHour * 3600 + nCurMin * 60 + nCurSec
    local nStartHMS= tbTemplate.nStartHour * 3600 + tbTemplate.nStartMin * 60 + tbTemplate.nStartSec  
    local nEndHMS  = tbTemplate.nStopHour * 3600 + tbTemplate.nStopMin * 60 + tbTemplate.nStopSec 

    local szAni = nIndex == 1 and "anim_vbFixedTime_Noon" or "anim_vbFixedTime_Night"
    self.Owner:StopAnimation(szAni)
    local tbAwardState = Proto.s2c_GetTimedAwardInfo_TimedAwardFlag
    if nCurHMS < nStartHMS then
        -- 时间未到
        pWidgetRef["btnGet"..nIndex]:SetVisibility(ESlateVisibility_Hidden)
        pWidgetRef["imgGetEffect"..nIndex]:SetVisibility(ESlateVisibility_Collapsed)
        pWidgetRef["imgGet"..nIndex]:SetVisibility(ESlateVisibility_Collapsed)
        pWidgetRef["imgState"..nIndex]:SetVisibility(ESlateVisibility_Collapsed)
        pWidgetRef["txtFixedTimeState"..nIndex]:SetText(UISetUtils.GetL10NTextByKey("COMMON_AWARD_UNRECH_TIME"))
    elseif nCurHMS >= nStartHMS and nCurHMS <= nEndHMS then
        if nState ~= nil and nState == tbAwardState.TIMED_AWARDED then 
            -- 已领取
            pWidgetRef["btnGet"..nIndex]:SetVisibility(ESlateVisibility_Hidden)
            pWidgetRef["imgGetEffect"..nIndex]:SetVisibility(ESlateVisibility_Collapsed)
            pWidgetRef["imgGet"..nIndex]:SetVisibility(ESlateVisibility_SelfHitTestInvisible)
            pWidgetRef["imgState"..nIndex]:SetVisibility(ESlateVisibility_SelfHitTestInvisible)
            pWidgetRef["txtFixedTimeState"..nIndex]:SetText(UISetUtils.GetL10NTextByKey("COMMON_AWARD_GETED"))
        else
            -- 可领取
            pWidgetRef["btnGet"..nIndex]:SetVisibility(ESlateVisibility_Visible)
            pWidgetRef["imgGetEffect"..nIndex]:SetVisibility(ESlateVisibility_SelfHitTestInvisible)
            pWidgetRef["imgGet"..nIndex]:SetVisibility(ESlateVisibility_Collapsed)
            pWidgetRef["imgState"..nIndex]:SetVisibility(ESlateVisibility_Collapsed)
            pWidgetRef["txtFixedTimeState"..nIndex]:SetText("")
            self.Owner:PlayAnimation(szAni, 0, 0, EUMGSequencePlayMode.Forward)
        end
    else
        pWidgetRef["btnGet"..nIndex]:SetVisibility(ESlateVisibility_Hidden)
        pWidgetRef["imgGetEffect"..nIndex]:SetVisibility(ESlateVisibility_Collapsed)
        if nState ~= nil and nState == tbAwardState.TIMED_AWARDED then
            -- 已领取
            pWidgetRef["imgGet"..nIndex]:SetVisibility(ESlateVisibility_SelfHitTestInvisible)
            pWidgetRef["imgState"..nIndex]:SetVisibility(ESlateVisibility_SelfHitTestInvisible)
            pWidgetRef["txtFixedTimeState"..nIndex]:SetText(UISetUtils.GetL10NTextByKey("COMMON_AWARD_GETED"))
        else
            -- 时间已过
            pWidgetRef["imgGet"..nIndex]:SetVisibility(ESlateVisibility_Collapsed)
            pWidgetRef["imgState"..nIndex]:SetVisibility(ESlateVisibility_SelfHitTestInvisible)
            pWidgetRef["txtFixedTimeState"..nIndex]:SetText(UISetUtils.GetL10NTextByKey("COMMON_AWARD_OVER_TIME"))
        end
    end
end

local function OnRefresh(self)
    UIUtils.HideWaitingPacket()
    local Component = ScheduleSystem:GetComponent()
    local tbAll = TimedAwardDataTable:GetContainer()
    
    local pWidgetRef = self.pWidgetRef
    for i = 1, MAX_COUNT do
        RefreshIndex(self, pWidgetRef, tbAll[i], Component:GetFixedTimeAwardInfo(tbAll[i].nId), i)
    end
end

local function OnClickedGet(self, nIndex)
    local tbAll = TimedAwardDataTable:GetContainer()
    if tbAll[nIndex] ~= nil then
        UIUtils.ShowWaitingPacket()
        ScheduleSystem:RequestTimedAward(tbAll[nIndex].nId)
    end
end


function UPScheduleTabFixedAward:Activate()
    UPScheduleTabFixedAward.super.Activate(self)
    OnRefresh(self)
end

function UPScheduleTabFixedAward:Deactivate()
    UPScheduleTabFixedAward.super.Deactivate(self)
end

function UPScheduleTabFixedAward:OnLoad()
    -- local pWidgetRef = self.pWidgetRef
    -- local PrefabHelper = self.PrefabHelper

    -- self.tbItems = {}
    -- for i = 1, MAX_COUNT do
    --     local pbItem = PrefabHelper:BindPrefab(pWidgetRef["pbFixedTimeLobbyItem"..i], UIDef.UP_LOBBY_DISPLAY_ITEM)
    --     table.insert(self.tbItems, pbItem)
    -- end
end

function UPScheduleTabFixedAward:OnBindEvent(EventHelper)
    for i = 1, MAX_COUNT do
        EventHelper:RegisterCppDelegate(self.pWidgetRef["btnGet"..i].OnClicked,  self, function()
            OnClickedGet(self, i)
        end)
    end
    EventHelper:RegisterEvent(ClientEventDef.EV_SCHEDULE_FIXED_TIME_AWARD_REFRESH, self, OnRefresh)   
end

function UPScheduleTabFixedAward:OnDestroy()
    self.tbItems = nil
end

return UPScheduleTabFixedAward