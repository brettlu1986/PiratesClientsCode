-----------------------------------------------------
--File Name    : UPWidgetDialog.lua
--Author       : Zuo Kun
--Create Time  : 2017-05-10
-----------------------------------------------------
local luaclass = require ("luaclass")
local UPWidgetBase = require("UPWidgetBase")
local UPQuestWidget = luaclass("UPQuestWidget", UPWidgetBase)
local UIResourceDef = require("UIResourceDef")
local QuestDef = require("QuestDef")
local UISetUtils = require("UISetUtils")
local UIDef = require("UIDef")

function UPQuestWidget:OnWidgetCreated()
    self.pWidgetRef.ovlHead:SetVisibility(ESlateVisibility.Collapsed)
end 

function UPQuestWidget:RefreshWidget(tbParams)
    local nQuestType = tbParams
    self.nQuestType = nQuestType
    -- self.pWidgetRef.txtTips:SetVisibility(ESlateVisibility.Collapsed)
    self.pWidgetRef.ovlHead:SetVisibility(ESlateVisibility.Visible)
    self.Owner:SetWidgetVisibility(UIDef.UP_NPC_HEAD_ICON_WIDGET, false)
    if nQuestType == QuestDef.QuestAcceptType.QUEST_CAN_ACCEPT then         --可接
        UISetUtils.SetImageBrushRes(self.pWidgetRef.imgIcon, UIResourceDef.QUEST_ACCEPT_HEAD:load())
    elseif nQuestType == QuestDef.QuestAcceptType.QUEST_CAN_COMPLETE then     -- 可完成
        UISetUtils.SetImageBrushRes(self.pWidgetRef.imgIcon, UIResourceDef.QUEST_COMPLETE_HEAD:load())
    else 
        self.Owner:SetWidgetVisibility(UIDef.UP_NPC_HEAD_ICON_WIDGET, true)
        self.pWidgetRef.ovlHead:SetVisibility(ESlateVisibility.Collapsed)
    end 
end 

return UPQuestWidget