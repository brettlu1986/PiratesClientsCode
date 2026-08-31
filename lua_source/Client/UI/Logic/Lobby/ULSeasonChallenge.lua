local luaclass = require("luaclass")
local UILogicBase = require("UILogicBase")
local ULSeasonChallenge = luaclass("ULSeasonChallenge", UILogicBase)
local SelfVerticalListHelper = require("SelfVerticalListHelper")
local SeasonDataTable = require("SeasonDataTable")
local Proto = require("ClientProtoNames")
local SeasonSystem = require("SeasonSystem")
local ClientEventDef = require("ClientEventDef")
local UIUtils = require("UIUtils")
local ChallengeSubIndexDataTable = require("ChallengeSubIndexDataTable")
local EventManager = require("EventManager")
-- local LobbySystem = require("LobbySystem")
-- local LobbySubTypeDef = require("LobbySubTypeDef")
local SelfTabBarHelper = require("SelfTabBarHelper")
local SelfListHelperNew = require("SelfListHelperNew")
local UISetUtils = require("UISetUtils")
local L10N = require("L10N")
local GlobalVariableSystem = require("GlobalVariableSystem_C")
local TimeUtil = require("TimeUtil")
local UIResourceDef = require("UIResourceDef")
local ScheduleSystem = require("ScheduleSystem")
local UIDef = require("UIDef")
local AwardDataTable = require("AwardDataTable")
local UITextDef = require("UITextDef")
local Timer = require("Timer")
local GetTextByKey = UISetUtils.GetTextByKey
local GetL10NTextByKey = UISetUtils.GetL10NTextByKey
local CHALLENGETYPEDEF = Proto.ChallengeType
local SINGLE_WEEK_DAY = 7
local MAX_DATE_LEN = 2
local DELAY_TIME = 1
local AWARD_MAX_COUNT = 2
local DATE_STR = {
    GetTextByKey("COMMON_TIME_DAY"),
    GetTextByKey("COMMON_TIME_HOUR"),
    GetTextByKey("COMMON_TIME_MINUTE"),
    GetTextByKey("COMMON_TIME_SECOND")
}

ULSeasonChallenge.tbListHelper = nil
ULSeasonChallenge.tbWeekListHelper = nil
ULSeasonChallenge.nSelectChallengeType = nil
ULSeasonChallenge.nCurWeek = nil
ULSeasonChallenge.tbTabBarHelper = nil
ULSeasonChallenge.pbAwardItems = nil

local function GetChallengeTask(SeasonComponent, nType)
    local tbTypeChallenges = SeasonComponent:GetSeasonChallenge(nType)
    if tbTypeChallenges == nil then
        log("not find season challenge data ", nType)
        SeasonSystem:RequestGetChallenge(nType)
        return 
    end
    local tbData = {}
    local nUnCompleteCount, nCompleteCount = #tbTypeChallenges.challenge_sub, #tbTypeChallenges.completed_sub
    local tbSeasonChallengeSubData
    for i, v in ipairs(tbTypeChallenges.challenge_sub) do
        tbSeasonChallengeSubData = ChallengeSubIndexDataTable:GetTemplate(nType, v.sub_id)
        table.insert(tbData, {nId = v.sub_id, nProgress = v.progress, bLock = v.is_lock, nType = nType, nMaxProgress = tbSeasonChallengeSubData.nObjectiveEnd or 0})
    end
    for i, v in ipairs(tbTypeChallenges.completed_sub) do
        if ChallengeSubIndexDataTable:GetTemplate(nType, v) then
            table.insert(tbData, {nId = v, bComplete = true, nType = nType})
        end
    end

    local fnSort = function(a, b)
        if a.bLock and not b.bLock then
            return false
        elseif not a.bLock and b.bLock then
            return true
        elseif a.nProgress and b.nProgress then
            if a.nProgress >= a.nMaxProgress and b.nProgress < b.nMaxProgress then
                return true
            elseif b.nProgress >= b.nMaxProgress and a.nProgress < a.nMaxProgress then
                return false
            else
                return a.nId < b.nId
            end 
        elseif a.bComplete and not b.bComplete then
            return false
        elseif not a.bComplete and b.bComplete then
            return true
        else
            return a.nId < b.nId
        end
    end
    table.sort(tbData, fnSort)

    return tbData, nCompleteCount, nUnCompleteCount
end

local function SetSelectWeek(self, nWeek)
    local SeasonComponent = SeasonSystem:GetComponent()
    local nRealCurWeek = SeasonComponent:GetCurWeek()
    
    self.nCurWeek = nWeek

    local nType = CHALLENGETYPEDEF.WEEKLY
    -- if nWeek == nRealCurWeek then
    local tbData, nCompleteCount, nUnCompleteCount = GetChallengeTask(SeasonComponent, nType)
    if nWeek ~= nRealCurWeek then
        tbData = {}
        local tbChallenges = ChallengeSubIndexDataTable:GetTypeTemplate(nType)
        if nWeek < nRealCurWeek then
            -- 已结束
            for i, v in pairs(tbChallenges) do
                if type(v) == "table" and v.tbOwner ~= nil and v.tbOwner[nWeek] ~= nil then
                    -- nCompleteCount = nCompleteCount + 1
                    table.insert(tbData, {nId = v.nSubId, bOver = true, nType = nType})
                end
            end
        else
            -- 未开启
            for i, v in pairs(tbChallenges) do
                if type(v) == "table" and v.tbOwner ~= nil and v.tbOwner[nWeek] ~= nil then
                    -- nUnCompleteCount = nUnCompleteCount + 1
                    table.insert(tbData, {nId = v.nSubId, nProgress = 0, bLock = true, nType = nType})
                end
            end            
        end
    end

    local kmWeekList = self.pWidgetRef.kmWeekList
    if tbData == nil then
        UIUtils.ShowLoadingDialog()
        self.tbListHelper:SetData({})
        kmWeekList:SetVisibility(ESlateVisibility_Collapsed)
    else
        self.tbListHelper:SetData(tbData)
        self.tbListHelper:ScrollToTop(false)
        if self.nCurWeek == nil or self.nCurWeek == 0 then
            kmWeekList:SetVisibility(ESlateVisibility_Collapsed)
        else
            kmWeekList:SetVisibility(ESlateVisibility.SelfHitTestInvisible)

            local tbWeek = {}
            for i = 1, self.nMaxWeek do
                table.insert(tbWeek, {nIndex = i, bSelected = i == self.nCurWeek, nRealCurWeek = nRealCurWeek, nCompleteCount = nCompleteCount, nUnCompleteCount= nUnCompleteCount})
            end  
            self.tbWeekListHelper:SetData(tbWeek)
        end 
    end

    return tbData, nCompleteCount, nUnCompleteCount
end

local function TimeToDHMSStr(nTime)
    local nDay, nHour, nMin = TimeUtil.TimeToDHMS(nTime)
    local tbDate = {nDay, nHour, nMin}

    local nCount = 0
    local szRet = ""
    for i, value in ipairs(tbDate) do
        if value > 0 then
            szRet = szRet..(value..DATE_STR[i])
            nCount = nCount + 1
            if nCount >= MAX_DATE_LEN then
                break
            end 
        end
    end 

    -- 只有时间小于1小时时，才显示秒数
    local bStartTimer = nDay == 0 and nHour == 0

    return szRet, bStartTimer
end

local function SetTextTime(self, txtTimer, nRemainTime)
    local szRemainTime, bStartTimer = TimeToDHMSStr(nRemainTime)
    if bStartTimer then
        txtTimer:StartTimer(nRemainTime, DELAY_TIME, DATE_STR, EMinTimeUnit.Second)
    else
        txtTimer:SetText(szRemainTime)
    end
end

local function RefreshWeekAward(self, bComplete)
    local nCount = 0
    local Collapsed, Visible = ESlateVisibility_Collapsed, ESlateVisibility_Visible
    local tbItems = self.pbAwardItems
    local nItemId, nMultiple = ScheduleSystem:GetAwardMultiple()

    local nAwardId = ChallengeSubIndexDataTable:GetOwnerAward(CHALLENGETYPEDEF.WEEKLY, self.nCurWeek)
    local tbAwards = AwardDataTable:GetAwardItem(nAwardId)
    nCount = math.min(tbAwards and #tbAwards or 0, AWARD_MAX_COUNT)

    for i = 1, nCount do
        local pWidgetRef = tbItems[i].pWidgetRef
        pWidgetRef:SetVisibility(Visible)
        local nTemp = nItemId and nItemId == tbAwards[i].nItemId and nMultiple 
        tbItems[i]:SetDisplayItemData(tbAwards[i].nItemId, tbAwards[i].nCount, true, false, nTemp)
        -- if bComplete then
        --     tbItems[i]:PlayAnimation("animGetGlow", 0, 0, EUMGSequencePlayMode.Forward, 1)
        -- else
        --     pWidgetRef:StopAllAnimations()
        --     tbItems[i]:PlayAnimation("animEffectClose", 0, 1, EUMGSequencePlayMode.Forward, 1)
        -- end
    end

    for i = nCount + 1, AWARD_MAX_COUNT do
        tbItems[i].pWidgetRef:SetVisibility(Collapsed)
    end

    local pWidgetRef = self.pWidgetRef
    pWidgetRef.btnGet:SetVisibility(bComplete and Visible or Collapsed)
    if bComplete then
        local SeasonComponent = SeasonSystem:GetComponent()
        local bGet = SeasonComponent:IsGetChallengeWeekAward(CHALLENGETYPEDEF.WEEKLY)
        pWidgetRef.txtPositive:SetText(bGet and UITextDef.COMMON_AWARD_GETED or UITextDef.COMMON_AWARD_GET)
        UISetUtils.SetButtonBrushTint(pWidgetRef.btnGet, bGet and UIResourceDef.COLOR.GREY.SLATE_COLOR or UIResourceDef.COLOR.WHITE.SLATE_COLOR)
        pWidgetRef.txtPositive:SetColorAndOpacity(bGet and UIResourceDef.COLOR.GREY.SLATE_COLOR or UIResourceDef.COLOR.WHITE.SLATE_COLOR)
    end
end

local function RefreshProgressImg(self, nCount, imgName)
    local tbData = {0, 0, 0}
    tbData[3] = math.floor(nCount / 100)
    local temp = nCount - tbData[3]
    tbData[2] = math.floor(nCount / 10)
    tbData[1] = temp - tbData[2] * 10
    
    local fnVisible = function(nIndex)
        if tbData[nIndex] > 0 then
            return true
        end
        local tempIndex = nIndex + 1 
        while tempIndex <= 3 do
            if tbData[tempIndex] > 0 then
                return true
            end
            tempIndex = tempIndex + 1
        end 
        if nIndex == 1 then
            return true
        end   
        return false 
    end
    
    local pWidgetRef = self.pWidgetRef
    for i, v in ipairs(tbData) do
        local bVisible = fnVisible(i)
        pWidgetRef[imgName..i]:SetVisibility(bVisible and ESlateVisibility_SelfHitTestInvisible or ESlateVisibility_Collapsed)
        if bVisible then
            UISetUtils.SetImageBrushRes(pWidgetRef[imgName..i], UIResourceDef.NUM_IMAGE[v]:load())
        end
    end
end

local function RefreshChallengeProgress(self, nType, tbData, nCompleteCount, nUnCompleteCount)
    if tbData == nil then
        return
    end
    local pWidgetRef = self.pWidgetRef
    local SeasonComponent = SeasonSystem:GetComponent()
    local nAllCount = nCompleteCount + nUnCompleteCount
    local Collapsed, SelfHitTestInvisible = ESlateVisibility_Collapsed, ESlateVisibility_SelfHitTestInvisible

    if nType == CHALLENGETYPEDEF.DAILY then
        pWidgetRef.pnlWeek:SetVisibility(Collapsed)
        pWidgetRef.hbProgress:SetVisibility(SelfHitTestInvisible)
        RefreshProgressImg(self, nCompleteCount, "imgComplete")
        RefreshProgressImg(self, nAllCount, "imgMax")
        pWidgetRef.proWeek:SetPercent(nCompleteCount / nAllCount)
        pWidgetRef.txtProgress:SetText(GetL10NTextByKey("LOBBY_SEASON_CHALLENGE_DAY_PROGRESS"))
    elseif nType == CHALLENGETYPEDEF.WEEKLY then
        local nRealCurWeek = SeasonComponent:GetCurWeek()
        if self.nCurWeek == nRealCurWeek then
            pWidgetRef.pnlWeek:SetVisibility(SelfHitTestInvisible)
            pWidgetRef.hbProgress:SetVisibility(SelfHitTestInvisible)
            RefreshProgressImg(self, nCompleteCount, "imgComplete")
            RefreshProgressImg(self, nAllCount, "imgMax")
            pWidgetRef.proWeek:SetPercent(nCompleteCount / nAllCount)
    
            local nCurTimeStamp = GlobalVariableSystem:GetServerTimeUtc()
            local nRemainTime = TimeUtil.GetWeekRemainTime(nCurTimeStamp)
            SetTextTime(self, pWidgetRef.txtWeekTime, nRemainTime)
            pWidgetRef.txtProgress:SetText(L10N:Format(GetL10NTextByKey("LOBBY_SEASON_CHALLENGE_WEEK_PROGRESS"), self.nCurWeek))
        
            RefreshWeekAward(self, nAllCount == nCompleteCount)
        elseif self.nCurWeek < nRealCurWeek then
            pWidgetRef.pnlWeek:SetVisibility(Collapsed)
            pWidgetRef.proWeek:SetPercent(0)
            pWidgetRef.hbProgress:SetVisibility(Collapsed)
            pWidgetRef.txtProgress:SetText(L10N:Format(GetL10NTextByKey("LOBBY_SEASON_CHALLENGE_WEEK_OVER"), self.nCurWeek))
        end
    else
        pWidgetRef.pnlWeek:SetVisibility(Collapsed)
        pWidgetRef.hbProgress:SetVisibility(SelfHitTestInvisible)
        RefreshProgressImg(self, nCompleteCount, "imgComplete")
        RefreshProgressImg(self, nAllCount, "imgMax")
        pWidgetRef.proWeek:SetPercent(nCompleteCount / nAllCount)
        pWidgetRef.txtProgress:SetText(GetL10NTextByKey("LOBBY_SEASON_CHALLENGE_PROGRESS"))
    end
end

local function RefreshChallengeList(self, nType)
    local SeasonComponent = SeasonSystem:GetComponent()

    if nType == CHALLENGETYPEDEF.WEEKLY then
        local nRealCurWeek = SeasonComponent:GetCurWeek()
        return SetSelectWeek(self, nRealCurWeek)
    else
        local tbData, nCompleteCount, nUnCompleteCount = GetChallengeTask(SeasonComponent, nType)
        if tbData == nil then
            UIUtils.ShowLoadingDialog()
            self.tbListHelper:SetData({})
        else
            self.tbListHelper:SetData(tbData)
            self.tbListHelper:ScrollToTop(false)
        end
        self.pWidgetRef.kmWeekList:SetVisibility(ESlateVisibility_Collapsed)
        return tbData, nCompleteCount, nUnCompleteCount
    end
end

local function OnSelectChallengeType(self, nSelectIndex)
    self.nSelectChallengeType = nSelectIndex - 1
    local tbData, nCompleteCount, nUnCompleteCount = RefreshChallengeList(self, self.nSelectChallengeType)
    RefreshChallengeProgress(self, self.nSelectChallengeType, tbData, nCompleteCount, nUnCompleteCount)

    if self.nSelectChallengeType == CHALLENGETYPEDEF.WEEKLY then
        local SeasonComponent = SeasonSystem:GetComponent()
        local nRealCurWeek = SeasonComponent:GetCurWeek()
        self.tbWeekListHelper:ScrollToIndexTopLeft(nRealCurWeek or 1, false)
    end
end

local function OnRefreshSeasonChallenge(self)
    if self.nSelectChallengeType == nil then
        log("recv data after season challenge ui opened")
        return
    end
    UIUtils.HideLoadingDialog()    
    OnSelectChallengeType(self, self.nSelectChallengeType + 1)
    EventManager:OnFireEvent(ClientEventDef.EV_SEASON_CHALLENGE_REFRESH_FINISH)
end

local function RefreshChallengeAwardStatus(self)
    local SeasonComponent = SeasonSystem:GetComponent()
    --local pWidgetRef = self.pWidgetRef
    for i = 1, 3 do
        local bHasAward = SeasonComponent:GetChallengeAwardStatus(i - 1)
        --pWidgetRef["cbType"..i]:HideTipIcon(not bHasAward)
        self.tbTabBarHelper:SetTipIconVisible(i, bHasAward)
    end
end

local function DestroyTimer(self)
    if self.tbTimer ~= nil then
        self.tbTimer:Clear()
        self.tbTimer = nil
    end
end

local function RefreshChallengeTime(self)
    local SeasonComponent = SeasonSystem:GetComponent()
    local nSeasonStartTime = SeasonComponent:GetStartTime()
    local tbSeasonData = SeasonDataTable:GetTemplate(SeasonComponent:GetSeasonId())
    local nCurTime = GlobalVariableSystem:GetServerTimeUtc()
    
    local nStatus = SeasonComponent:GetNewSeasonStatus()
    if nStatus == Proto.PlayerSeasonStatus.RUNNING then
        local nDurationTime = tbSeasonData.nDurationDay *24 * 60 * 60
        local nSeasonEndTime = nDurationTime + nSeasonStartTime
        local nRemainTime = nSeasonEndTime - nCurTime
        if nRemainTime > 0 then
            SetTextTime(self, self.pWidgetRef.txtSeasonTime, nRemainTime)
            self.pWidgetRef.txtSeasonTimeTitle:SetText(L10N:Format(UISetUtils.GetL10NTextByKey("SEASON_TIME_TO_CLOSING"), tbSeasonData.l10nName))
        else
            self.pWidgetRef.txtSeasonTime:SetText(UISetUtils.GetL10NTextByKey("SEASON_NEW_OPENING"))
            self.pWidgetRef.txtSeasonTimeTitle:SetText(UISetUtils.GetL10NTextByKey("SEASON_TIME_TO_OPENING"))
        end
    else
        local nRemainTime = nSeasonStartTime - nCurTime
        SetTextTime(self, self.pWidgetRef.txtSeasonTime, nRemainTime)
        self.pWidgetRef.txtSeasonTimeTitle:SetText(UISetUtils.GetL10NTextByKey("SEASON_TIME_TO_OPENING"))
    end
end

local function OnRefreshWeeklyAward(self)
    RefreshWeekAward(self, true)
end

local function OnClickedGetWeekAward(self)
    SeasonSystem:RequestChallengeWeeklyAward()
end

function ULSeasonChallenge:OnSelectWeek(nWeek)
    local tbData, nCompleteCount, nUnCompleteCount = SetSelectWeek(self, nWeek)
    RefreshChallengeProgress(self, self.nSelectChallengeType, tbData, nCompleteCount, nUnCompleteCount)
end

function ULSeasonChallenge:OnShow()
end

function ULSeasonChallenge:OnDestroy()
end

function ULSeasonChallenge:OnLoad()
    local SeasonComponent = SeasonSystem:GetComponent()
    local pWidgetRef = self.pWidgetRef
    local PrefabHelper = self.PrefabHelper

    self.tbListHelper = SelfVerticalListHelper()
    self.tbListHelper:Init(self, pWidgetRef.listChallenge)

    self.tbWeekListHelper = SelfListHelperNew()
    self.tbWeekListHelper:Init(self, pWidgetRef.kmWeekList)
    local nId = SeasonComponent:GetSeasonId()
    local tbSeasonData = SeasonDataTable:GetTemplate(nId)
    self.nMaxWeek = math.ceil(tbSeasonData.nDurationDay / SINGLE_WEEK_DAY)  

    self.pbAwardItems = {}
    for i = 1, AWARD_MAX_COUNT do
        local pbRewardItem = PrefabHelper:BindPrefab(pWidgetRef["UP_WeekAward" .. i], UIDef.UP_LOBBY_DISPLAY_ITEM)
        table.insert(self.pbAwardItems , pbRewardItem)
        pbRewardItem:SetOwner(self)
    end

    self.tbTabBarHelper = SelfTabBarHelper()
    self.tbTabBarHelper:Init(self, self.pWidgetRef.vboxTab, -1)

    local nStatus = SeasonComponent:GetNewSeasonStatus()
    pWidgetRef:SetVisibility(nStatus == Proto.PlayerSeasonStatus.RUNNING and ESlateVisibility_Visible or ESlateVisibility_Collapsed)
end

function ULSeasonChallenge:OnBindEvent(EventHelper)
    --local pWidgetRef = self.pWidgetRef
    EventHelper:RegisterEvent(ClientEventDef.EV_ON_REFRESH_SEASON_CHALLENGE, self, OnRefreshSeasonChallenge) 
    EventHelper:RegisterEvent(ClientEventDef.EV_ON_REFRESH_SEASON_CHALLENGE_AWARD_STATUS, self, RefreshChallengeAwardStatus)
    EventHelper:RegisterEvent(ClientEventDef.EV_ON_REFRESH_SEASON_CHALLENGE_WEEKLY_AWARD, self, OnRefreshWeeklyAward)
    EventHelper:RegisterCppDelegate(self.pWidgetRef.btnGet.OnClicked, self, OnClickedGetWeekAward)
    
    self.tbTabBarHelper.OnSelectedChangedDelegate:Bind(OnSelectChallengeType, self)
end

function ULSeasonChallenge:OnUnload()
    self.tbListHelper:Uninit()
    self.tbListHelper = nil
    self.tbWeekListHelper:Uninit()
    self.tbWeekListHelper = nil
    if self.tbTabBarHelper then
        self.tbTabBarHelper:Uninit()
        self.tbTabBarHelper = nil
    end
    self.pbAwardItems = nil
end

function ULSeasonChallenge:Activate()
    if self.tbTimer == nil then
        self.tbTimer = Timer.NewTimerMethod(self, RefreshChallengeTime, 60, true)
    end  

    self.tbTabBarHelper:SelectByIndex(1, true)
    RefreshChallengeAwardStatus(self)
    RefreshChallengeTime(self)
    -- LobbySystem:GetSub(LobbySubTypeDef.SEASON):SetViewTarget(nil)    
end

function ULSeasonChallenge:Deactivate()
    DestroyTimer(self)
end

return ULSeasonChallenge