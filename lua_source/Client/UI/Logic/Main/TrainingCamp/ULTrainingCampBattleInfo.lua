-----------------------------------------------------
--File Name    : ULTrainingCampBattleInfo.lua
--Description  : 训练营倒计时信息等
-----------------------------------------------------
local luaclass = require("luaclass")
local UILogicBase = require("UILogicBase")
local ULTrainingCampBattleInfo = luaclass("ULTrainingCampBattleInfo", UILogicBase)

local GlobalVariableSystem_C = require("GlobalVariableSystem_C")
local ClientEventDef = require("ClientEventDef")
local UIResourceDef = require("UIResourceDef")
local UISetUtils = require("UISetUtils")

local DELAY_TIME = 1
local CLOCK_IMAGE_SIZE = 40
ULTrainingCampBattleInfo.OneSecondTimer = nil
ULTrainingCampBattleInfo.nTime = nil
ULTrainingCampBattleInfo.bTimerStart = false
ULTrainingCampBattleInfo.szCurTimeRes = nil

local function DestroyTimer(self)
    if self.OneSecondTimer then
        self.TimerHelper:ClearTimer(self.OneSecondTimer)
        self.OneSecondTimer = nil
    end
end

local function OnOneSecondPass(self)
    if self.bTimerStart then
        local nTime = math.max(self.nTime, 0)
        local txtCoolTime = self.pWidgetRef.cdtxtPoisonTimer
        local nMinute = math.floor(nTime / 60)
        local nSecond = nTime % 60
        local szTime = string.format("%02.0f:%02.0f", nMinute, nSecond)
        txtCoolTime:SetText(szTime)
    end
end

local function StartTimer(self)
    local pWidgetRef = self.pWidgetRef
    local txtCoolTime = pWidgetRef.cdtxtPoisonTimer
    local imgTimer = pWidgetRef.imgTimer
    self.bTimerStart = true
    txtCoolTime:SetColorAndOpacity(UIResourceDef.COLOR.WHITE.SLATE_COLOR)
    if self.szCurTimeRes ~= UIResourceDef.FFA_REPARE_TIMER then 
        self.szCurTimeRes = UIResourceDef.FFA_REPARE_TIMER
        UISetUtils.SetImageBrushRes(imgTimer, self.szCurTimeRes:load(), false, true, CLOCK_IMAGE_SIZE, CLOCK_IMAGE_SIZE)
    end
    OnOneSecondPass(self)
end

local function OnReleaseTimeStampChanged(self, nEndTimeStamp)
    if nEndTimeStamp and nEndTimeStamp > 0 then
        self.nTime = nEndTimeStamp - GlobalVariableSystem_C:GetServerTimeUtc()
        if not self.bTimerStart then
            StartTimer(self)
        end
    end
end

local function InitInterface(self)
    self.bTimerStart = false

    local pWidgetRef = self.pWidgetRef
    pWidgetRef.txtRemainPlayer:SetText("0")
    pWidgetRef.txtKillPlayer:SetText("0")
    pWidgetRef.txtToastKill:SetVisibility(ESlateVisibility.Collapsed)
    pWidgetRef.hboxRemainPlayer:SetVisibility(ESlateVisibility.Collapsed)
    pWidgetRef.hboxKillPlayer:SetVisibility(ESlateVisibility.Collapsed)
    pWidgetRef.cdtxtPoisonTimer:SetText("--:--")
    self.szCurTimeRes = UIResourceDef.FFA_POISON_CIRCLE_TIMER
    UISetUtils.SetImageBrushRes(pWidgetRef.imgTimer, self.szCurTimeRes:load())
end

function ULTrainingCampBattleInfo:OnCreate()
    self.OneSecondTimer = self.TimerHelper:NewTimerMethod(self, function()
            if self.nTime ~= nil then
                self.nTime = self.nTime - DELAY_TIME

                if self.nTime < 0 then
                    self.nTime = 0
                end
            end
            OnOneSecondPass(self) 
        end,
        DELAY_TIME, true)
end

function ULTrainingCampBattleInfo:OnShow()
    InitInterface(self)
end

function ULTrainingCampBattleInfo:OnBindEvent(EventHelper)
    EventHelper:RegisterEvent(ClientEventDef.EV_GAME_STATE_TRAININGCAMP_RELEASE_TIME_STAMP, self, OnReleaseTimeStampChanged)
end

function ULTrainingCampBattleInfo:OnDestroy()
    DestroyTimer(self)
end

return ULTrainingCampBattleInfo