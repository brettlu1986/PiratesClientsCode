-----------------------------------------------------
--File Name    : UPToastGetItem.lua
--Author       : Chang Nan
--Create Time  : 2017-10-17
--Description  : 获取道具时弹出的toast提示
-----------------------------------------------------
local luaclass = require("luaclass")
local PrefabBase = require("PrefabBase")
local UPToastGetItem = luaclass("UPToastGetItem", PrefabBase)

-- require
local L10N = require("L10N")
local UITextDef = require("UITextDef")
local ItemSystemOld = require("ItemSystemOld")
local LuaDelegate = require("LuaDelegate")
local WidgetAnimationHandle = require("WidgetAnimationHandle")

local DEFAULT_WAIT_TIME = 1.5

-- member variable
UPToastGetItem.tbOnHideFinished = nil
UPToastGetItem.tbOnShowFinished = nil
UPToastGetItem.pbItemIcon = nil

-- public function
function UPToastGetItem:OnLoad()
    self.tbOnHideFinished = LuaDelegate()
    self.tbOnShowFinished = LuaDelegate()
    self.pbItemIcon = self.PrefabHelper:BindPrefab(self.pWidgetRef.pbBackPackItem)
end

function UPToastGetItem:OnBindEvent(EventHelper)
    local OnWaitTimeEndEvent = function()
        self:PlayAnimation("animOut", 0, 1, EUMGSequencePlayMode.Forward, 1)
    end
    local OnComeInFinishedEvent = function()
        self.TimerHelper:NewTimer(OnWaitTimeEndEvent, DEFAULT_WAIT_TIME)
        self.tbOnShowFinished:Fire()
    end
    local OnOutFinishedEvent = function()
        self.tbOnHideFinished:Fire()
    end
    EventHelper:RegisterHandle(WidgetAnimationHandle:BindToAnimationFinished(self.pWidgetRef, self.pWidgetRef.animComeIn, OnComeInFinishedEvent))
    EventHelper:RegisterHandle(WidgetAnimationHandle:BindToAnimationFinished(self.pWidgetRef, self.pWidgetRef.animOut, OnOutFinishedEvent))
end

function UPToastGetItem:ShowToast(tbItemType, nCount)
    local tbTemplate = ItemSystemOld:GetItemTemplate(tbItemType.genre, tbItemType.detail_type, tbItemType.particular)
    if tbTemplate then
        local l10nMessage = L10N:Format(UITextDef.L10N_GAINED_ITEM, tbTemplate.szColorNameInDeepBg, nCount)
        self.pWidgetRef.ktxtToast:SetText(l10nMessage)
        self.pbItemIcon:RefreshItemDisplay(tbTemplate, 0)
    else
        logerror("Show Item Toast failed", tbItemType.genre, tbItemType.detail_type, tbItemType.particular)
    end
    self:PlayAnimation("animComeIn", 0, 1, EUMGSequencePlayMode.Forward, 1)
end

function UPToastGetItem:HideToast()
    self.TimerHelper:ClearAllTimer()
    self:PlayAnimation("animOut", 0, 1, EUMGSequencePlayMode.Forward, 1)
end

return UPToastGetItem
