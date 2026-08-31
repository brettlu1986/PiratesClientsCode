local luaclass = require("luaclass")
local UPScheduleTabBase = require("UPScheduleTabBase")
local UPScheduleTabQuestion = luaclass("UPScheduleTabQuestion", UPScheduleTabBase)
local SurveyHelper = require("SurveyHelper")
local ClientEventDef = require("ClientEventDef")
local ScheduleSystem = require("ScheduleSystem")
local ScheduleTypeDef = require("ScheduleTypeDef")
local Proto = require("ClientProtoNames")

local function OnRefresh(self)
    local pWidgetRef = self.pWidgetRef
    local nState = self.tbInstance:GetRewardState()
    local bFillQuestion = SurveyHelper.IsFillScheduleQuestion()
    pWidgetRef.btnFill:SetVisibility(bFillQuestion and ESlateVisibility_Collapsed or ESlateVisibility_Visible)
    pWidgetRef.btnGet:SetVisibility(bFillQuestion and ESlateVisibility_Visible or ESlateVisibility_Collapsed)
    if nState == Proto.RewardState.RECEIVE and (not bFillQuestion) then  
        pWidgetRef.btnFill:SetVisibility(ESlateVisibility_Visible)
        pWidgetRef.btnGet:SetVisibility(ESlateVisibility_Collapsed)
    elseif nState == Proto.RewardState.RECEIVE and bFillQuestion then  
        pWidgetRef.btnFill:SetVisibility(ESlateVisibility_Collapsed)
        pWidgetRef.btnGet:SetVisibility(ESlateVisibility_Visible)
    elseif nState == Proto.RewardState.RECEIVED and bFillQuestion then  
        pWidgetRef.btnFill:SetVisibility(ESlateVisibility_Collapsed)
        pWidgetRef.btnGet:SetVisibility(ESlateVisibility_Collapsed)
    else  
        pWidgetRef.btnFill:SetVisibility(ESlateVisibility_Visible)
        pWidgetRef.btnGet:SetVisibility(ESlateVisibility_Collapsed)
    end
end

local function OnQuestionClicked(self)
    SurveyHelper.LaunchQuestionURL()
    SurveyHelper.SaveFillSchedule()

    OnRefresh(self)
end

local function OnGetRewardClicked(self)
    self.tbInstance:RequestGetQuestionReward()
end

local function OnClose(self)
    self.Owner:CloseSelf()
end

function UPScheduleTabQuestion:Activate()
    UPScheduleTabQuestion.super.Activate(self)

    local pWidgetRef = self.pWidgetRef

    if pWidgetRef.ovlAsk then
        pWidgetRef.ovlAsk:SetVisibility(ESlateVisibility_SelfHitTestInvisible)
    end
    OnRefresh(self)    
end

function UPScheduleTabQuestion:Deactivate()
    UPScheduleTabQuestion.super.Deactivate(self)
end

function UPScheduleTabQuestion:OnLoad()
    self.tbInstance = ScheduleSystem:GetInstance(ScheduleTypeDef.QUESTION)
end

function UPScheduleTabQuestion:OnBindEvent(EventHelper)
    local pWidgetRef = self.pWidgetRef
    EventHelper:RegisterCppDelegate(pWidgetRef.btnFill.OnClicked, self, OnQuestionClicked)
    EventHelper:RegisterCppDelegate(pWidgetRef.btnGet.OnClicked, self, OnGetRewardClicked)

    if pWidgetRef.btnCloseQuestion then 
        EventHelper:RegisterCppDelegate(pWidgetRef.btnCloseQuestion.OnClicked, self, OnClose)
    end
    EventHelper:RegisterEvent(ClientEventDef.EV_QUESTION_REFRESH, self, OnRefresh)
end

return UPScheduleTabQuestion