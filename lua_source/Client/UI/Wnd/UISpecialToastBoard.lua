-----------------------------------------------------
--File Name    : UISpecialToastBoard.lua
--Author       : Song Fuhao
--Create Time  : 2016-06-18
--Description  : Toast面板
-----------------------------------------------------

local luaclass = require("luaclass")
local WndBase = require("WndBase")
local UISpecialToastBoard = luaclass("UISpecialToastBoard", WndBase)

local WidgetAnimationHandle = require("WidgetAnimationHandle")

local DEFAULT_WAIT_TIME = 2

UISpecialToastBoard.nWaitTime = DEFAULT_WAIT_TIME
UISpecialToastBoard.bShowing = false
UISpecialToastBoard.nCurrentToastId = nil
UISpecialToastBoard.tbSpecialWaitMessageList = nil

local function SetText(self, l10nMessage)
    self.pWidgetRef.ktxtToast:SetText(l10nMessage and l10nMessage or "")
end

local function OnWaitTimeEndEvent(self)
    self:PlayAnimation("animFadeOut", 0, 1, EUMGSequencePlayMode.Forward, 1)
end

local function OnFadeInFinished(self)
    self.TimerHelper:NewTimerMethod(self, OnWaitTimeEndEvent, self.nWaitTime)
end

local function OnFadeOutFinished(self)
    self.bShowing = false
    self.nCurrentToastId = nil
    local tbMessageInfo = self.tbSpecialWaitMessageList[1]
    if tbMessageInfo then
        table.remove(self.tbSpecialWaitMessageList, 1)
        self:ShowToast(tbMessageInfo[1], tbMessageInfo[2], tbMessageInfo[3], tbMessageInfo[4])
    else
        self:CloseSelf()
    end
end

function UISpecialToastBoard:OnEnter()
    self.bShowing = false
    self.nCurrentToastId = nil
    self.tbSpecialWaitMessageList = {}
end

function UISpecialToastBoard:OnBindEvent(EventHelper)
    local pWidgetRef = self.pWidgetRef
    EventHelper:RegisterHandle(WidgetAnimationHandle:BindToAnimationFinished(pWidgetRef, pWidgetRef.animFadeIn, OnFadeInFinished, self))
    EventHelper:RegisterHandle(WidgetAnimationHandle:BindToAnimationFinished(pWidgetRef, pWidgetRef.animFadeOut, OnFadeOutFinished, self))
end

function UISpecialToastBoard:ShowToast(nToastId, l10nMessage, nWaitTime, bJudgeRepeat)
    if nToastId == self.nCurrentToastId and bJudgeRepeat then -- bJudgeRepeat 是否判断重复 如果重复就更新 这个和进入副本提示冲突 因为是同一个nId 所及加了判断
        SetText(self, l10nMessage)
        return
    end

    if self.bShowing then -- 没有剩余时，加入等待队列
        table.insert(self.tbSpecialWaitMessageList, {nToastId, l10nMessage, nWaitTime, bJudgeRepeat})
        return
    end

    self.bShowing = true
    self.nWaitTime = nWaitTime > 0 and nWaitTime or DEFAULT_WAIT_TIME
    self.nCurrentToastId = nToastId
    self:PlayAnimation("animFadeIn", 0, 1, EUMGSequencePlayMode.Forward, 1)
    SetText(self, l10nMessage)
end

return UISpecialToastBoard
