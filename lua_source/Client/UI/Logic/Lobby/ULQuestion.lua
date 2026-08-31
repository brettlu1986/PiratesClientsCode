local luaclass = require("luaclass")
local UILogicBase = require("UILogicBase")
local ULQuestion = luaclass("ULQuestion", UILogicBase)
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

function ULQuestion:Activate(tbAllWidget)
    self.tbInstance = ScheduleSystem:GetInstance(ScheduleTypeDef.QUESTION)
    local pWidgetRef = self.pWidgetRef
    if tbAllWidget ~= nil then 
        for i, v in ipairs(tbAllWidget) do
            pWidgetRef[v]:SetVisibility(ESlateVisibility_Collapsed)
        end
    end

    if pWidgetRef.ovlAsk then
        pWidgetRef.ovlAsk:SetVisibility(ESlateVisibility_SelfHitTestInvisible)
    end
    OnRefresh(self)
end  

function ULQuestion:Deactivate()
    self.tbInstance = nil
end  

function ULQuestion:OnUnload()
    self.tbInstance = nil
end

function ULQuestion:OnBindEvent(EventHelper)
    local pWidgetRef = self.pWidgetRef
    EventHelper:RegisterCppDelegate(pWidgetRef.btnFill.OnClicked, self, OnQuestionClicked)
    EventHelper:RegisterCppDelegate(pWidgetRef.btnGet.OnClicked, self, OnGetRewardClicked)

    if pWidgetRef.btnCloseQuestion then 
        EventHelper:RegisterCppDelegate(pWidgetRef.btnCloseQuestion.OnClicked, self, OnClose)
    end
    EventHelper:RegisterEvent(ClientEventDef.EV_QUESTION_REFRESH, self, OnRefresh)
end


return ULQuestion