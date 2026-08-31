-----------------------------------------------------
--File Name    : UPToastItem.lua
--Author       : Song Fuhao
--Create Time  : 2016-06-18
--Description  : Prefab Toast Item
-----------------------------------------------------
local luaclass = require("luaclass")
local PrefabBase = require("PrefabBase")
local UPToastItem = luaclass("UPToastItem", PrefabBase)

-- require
local LuaDelegate = require("LuaDelegate")
local ClientEventDef = require("ClientEventDef")
local WidgetAnimationHandle = require("WidgetAnimationHandle")

local DEFAULT_WAIT_TIME = 3
local DEFAULT_MESSAGE = ""

-- member variable
UPToastItem.tbOnHideFinished = nil
UPToastItem.tbOnShowFinished = nil

local function OnEnterProcedureBattle(self)
    if self.TimerHelper then
        self.TimerHelper:ClearAllTimer()
    end
end

local function OnLeaveProcedureBattle(self)
    if self.TimerHelper then
        self.TimerHelper:ClearAllTimer()
    end
end

-- public function
function UPToastItem:OnLoad()
    self.tbOnHideFinished = LuaDelegate()
    self.tbOnShowFinished = LuaDelegate()
end

function UPToastItem:OnBindEvent(EventHelper)
    local OnWaitTimeEndEvent = function()
        self:PlayAnimation("FadeOutAnim", 0, 1, EUMGSequencePlayMode.Forward, 1)
    end
    local OnFadeInFinishedEvent = function()
        self.TimerHelper:NewTimer(OnWaitTimeEndEvent, DEFAULT_WAIT_TIME)
        self.tbOnShowFinished:Fire()
    end
    local OnFadeOutFinishedEvent = function()
        self.tbOnHideFinished:Fire()
    end
    EventHelper:RegisterHandle(WidgetAnimationHandle:BindToAnimationFinished(self.pWidgetRef, self.pWidgetRef.FadeInAnim, OnFadeInFinishedEvent))
    EventHelper:RegisterHandle(WidgetAnimationHandle:BindToAnimationFinished(self.pWidgetRef, self.pWidgetRef.FadeOutAnim, OnFadeOutFinishedEvent))
    EventHelper:RegisterEvent(ClientEventDef.EV_ENTER_PROCEDURE_BATTLE, self, OnEnterProcedureBattle)
    EventHelper:RegisterEvent(ClientEventDef.EV_LEAVE_PROCEDURE_BATTLE, self, OnLeaveProcedureBattle)
end

function UPToastItem:ShowToast(l10nMessage)
    self.pWidgetRef.ktxtToast:SetText(l10nMessage and l10nMessage or DEFAULT_MESSAGE)
    self:PlayAnimation("FadeInAnim", 0, 1, EUMGSequencePlayMode.Forward, 1)
end

function UPToastItem:HideToast()
    self.TimerHelper:ClearAllTimer()
    self:PlayAnimation("FadeOutAnim", 0, 1, EUMGSequencePlayMode.Forward, 1)
end

return UPToastItem
