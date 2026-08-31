-----------------------------------------------------
--File Name    : UPMiniMap.lua
--Author       : Zou Chunyi
--Create Time  : 2016-08-22
--Description  : Prefab MiniMap
-----------------------------------------------------

local luaclass = require ("luaclass")
local PrefabBase = require("PrefabBase")
local UPHeadInfo = luaclass("UPHeadInfo", PrefabBase)

local UISetUtils = require("UISetUtils")
local QuestDef = require("QuestDef")
local UIResourceDef = require("UIResourceDef")
local LuaDelegate = require("LuaDelegate")

local DIALOG_DURATION_TIME = 5
UPHeadInfo.nQuestType = 0
UPHeadInfo.OnTipsHide = nil 
function UPHeadInfo:OnLoad()
    self.pWidgetRef.ovlHead:SetVisibility(ESlateVisibility.Collapsed)
    self.pWidgetRef.vboxText:SetVisibility(ESlateVisibility.Collapsed)
    self.OnTipsHide = LuaDelegate()
end

function UPHeadInfo:OnShow()
    self:SetQuestInfo(self.nQuestType)
end 

function UPHeadInfo:SetTipText( szText , szPortraitPath)
    self.pWidgetRef.txtTips:SetVisibility(ESlateVisibility.Visible)
    self.pWidgetRef.ovlHead:SetVisibility(ESlateVisibility.Collapsed)
    self.TimerHelper:ClearAllTimer()
    self.TimerHelper:NewTimerMethod(self, self.OnTipsTimeEnd, DIALOG_DURATION_TIME, false)
    if string.len( szText ) > 0 then 
        self.pWidgetRef.vboxText:SetVisibility(ESlateVisibility.Visible)
        self.pWidgetRef.txtTips:SetText( szText )
    else
        self.pWidgetRef.vboxText:SetVisibility(ESlateVisibility.Collapsed)
    end
    if szPortraitPath then 
        if string.len( szPortraitPath ) > 0 then 
            UISetUtils.SetImageBrushRes(self.pWidgetRef.imgPlayerHead, szPortraitPath:load())
        end
        self.pWidgetRef.imgPlayerHead:SetVisibility(ESlateVisibility.Visible)
    else
        self.pWidgetRef.imgPlayerHead:SetVisibility(ESlateVisibility.Collapsed)
    end 
end

function UPHeadInfo:OnTipsTimeEnd()
    self.pWidgetRef.vboxText:SetVisibility(ESlateVisibility.Collapsed)
    self:SetHeadInfo(self.nQuestType)
    self.OnTipsHide:Fire()
end

function UPHeadInfo:SetHeadInfo(nQuestType)
    -- if self.nQuestType == QuestDef.QuestAcceptType.QUEST_CAN_COMPLETE and nQuestType == QuestDef.QuestAcceptType.QUEST_CAN_ACCEPT then 
    --     return 
    -- end 
    
    self.nQuestType = nQuestType
    self.pWidgetRef.txtTips:SetVisibility(ESlateVisibility.Collapsed)
    self.pWidgetRef.ovlHead:SetVisibility(ESlateVisibility.Visible)
    if nQuestType == QuestDef.QuestAcceptType.QUEST_CAN_ACCEPT then         --可接
        UISetUtils.SetImageBrushRes(self.pWidgetRef.imgIcon, UIResourceDef.QUEST_ACCEPT_HEAD:load())
    elseif nQuestType == QuestDef.QuestAcceptType.QUEST_CAN_COMPLETE then     -- 可完成
        UISetUtils.SetImageBrushRes(self.pWidgetRef.imgIcon, UIResourceDef.QUEST_COMPLETE_HEAD:load())
    else 
        self.pWidgetRef.ovlHead:SetVisibility(ESlateVisibility.Collapsed)
    end 
end

return UPHeadInfo