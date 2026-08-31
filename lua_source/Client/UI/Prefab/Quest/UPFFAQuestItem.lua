-----------------------------------------------------
--File Name    : UPFFAQuestItem.lua
--Author       : LiHui
--Create Time  : 
--Description  : UPFFAQuestItem
-----------------------------------------------------
local luaclass          = require("luaclass")
local ListItemBase      = require("ListItemBase")
local UPFFAQuestItem = luaclass("UPFFAQuestItem", ListItemBase)

local BattleQuestSystem = dynamic_require("BattleQuestSystem")
local UISetUtils = require("UISetUtils")
local L10N = require("L10N")

function UPFFAQuestItem:OnRefresh(szMsg)
    local nASQuestId = BattleQuestSystem:GetAdditionalSuccessQuestId()
    local nASRemainCount = BattleQuestSystem:GetAdditionalSuccessCount()
    local bASFighting = BattleQuestSystem:IsAdditionalSuccessFighting()
    

    local szQuestName = szMsg.szQuestNameDesc
    local szQuestAwardsDesc = L10N:Format(UISetUtils.GetL10NTextByKey("FFA_QUEST_AWARDS_DESC"),szMsg.szQuestAwardsDesc)
    if nASQuestId and nASQuestId == szMsg.nQuestId then 
        local szText = UISetUtils.GetL10NTextByKey("FFA_ADDITIONAL_SUCCESS_REMAIN_COUNT")
        szQuestName = L10N:Format(szText,nASRemainCount)
        szQuestAwardsDesc = L10N:Format(UISetUtils.GetL10NTextByKey("FFA_ADDITIONAL_SUCCESS_AWARDS_DESC"),szMsg.szQuestAwardsDesc)

        if bASFighting == nil then
            self.pWidgetRef.KMRichTextBlock_0:SetText(szMsg.szQuestInfoDesc)
            self.pWidgetRef.KMRichTextBlock_1:SetText(szMsg.szQuestProcessDesc)
            self.pWidgetRef.KMRichTextBlock_2:SetText(szQuestAwardsDesc)
        else
            if bASFighting then
                self.pWidgetRef.KMRichTextBlock_0:SetText(UISetUtils.GetL10NTextByKey("FFA_ADDITIONAL_SUCCESS_FIGHTING"))
            else
                self.pWidgetRef.KMRichTextBlock_0:SetText(UISetUtils.GetL10NTextByKey("FFA_ADDITIONAL_SUCCESS_EXIT_BATTLE"))
            end
    
            self.pWidgetRef.KMRichTextBlock_1:SetText("")
            self.pWidgetRef.KMRichTextBlock_2:SetText("")
        end
    else
        self.pWidgetRef.KMRichTextBlock_0:SetText(szMsg.szQuestInfoDesc)
        self.pWidgetRef.KMRichTextBlock_1:SetText(szMsg.szQuestProcessDesc)
        self.pWidgetRef.KMRichTextBlock_2:SetText(szQuestAwardsDesc)
    end

    self.pWidgetRef.KMTextBlock_0:SetText(szQuestName)

    
end

function UPFFAQuestItem:OnBindEvent(EventHelper)
end

function UPFFAQuestItem:OnUnbindEvent(EventHelper)
    EventHelper:UnregisterAll()
end

return UPFFAQuestItem