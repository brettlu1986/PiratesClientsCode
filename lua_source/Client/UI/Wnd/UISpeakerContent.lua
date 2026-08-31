local luaclass = require("luaclass")
local WndBase = require("WndBase")
local UISpeakerContent = luaclass("UISpeakerContent", WndBase)
local ItemSystem = require("ItemSystem")
local L10N = require("L10N")
local UIUtils = require("UIUtils")
local UITextDef = require("UITextDef")
local UISetUtils = require("UISetUtils")
local ChatSystemHelper = require("ChatSystemHelper")
local LobbyChatSystem = require("LobbyChatSystem")

UISpeakerContent.tbItem = nil 

local DEFAULT_USE_COUNT = 1


local function OnTextChanged(self)
    local szContent = L10N:ToString(self.pWidgetRef.txtContent:GetText())
    local nLength = utf8.len(szContent)
    local nCanInputCount = 0
    if nLength > ChatSystemHelper.MAX_MSG_LENGTH then
        nCanInputCount = 0
        UIUtils.ShowToast(UITextDef.CHAT_LENGTH_LIMITE)
        local tbCharIndex = {}
        local nIndex = 1
        for p, c in utf8.codes(szContent) do
            tbCharIndex[nIndex] = p
            nIndex = nIndex + 1
        end
        szContent = string.sub(szContent, 1, tbCharIndex[LobbyChatSystem.MAX_MSG_LENGTH+1]-1)
        self.pWidgetRef.txtContent:SetText(szContent)
    else  
        nCanInputCount = ChatSystemHelper.MAX_MSG_LENGTH - nLength
    end
    local l10nLeft = L10N:Format(UISetUtils.GetL10NTextByKey("SPEAKER_INPUT_LEFT"), nCanInputCount)
    self.pWidgetRef.txtCanInput:SetText(l10nLeft)

end

local function OnClickSend(self)
    local szContent = L10N:ToString(self.pWidgetRef.txtContent:GetText())
    szContent = string.gsub(szContent, " ", "")
    local eCheckResult = ChatSystemHelper.CheckLengthValid(szContent)
    if eCheckResult == ChatSystemHelper.eCheckResult.TooShort then
        UIUtils.ShowToast(UITextDef.CHAT_NOT_EMPTY)
        return
    elseif eCheckResult == ChatSystemHelper.eCheckResult.TooLong then
        UIUtils.ShowToast(UITextDef.CHAT_LENGTH_LIMITE)
        return
    end
    szContent = ChatSystemHelper.CheckSpecialCharacter(szContent)
    szContent = ChatSystemHelper.CheckMsgSensitiveWords(szContent)
    ItemSystem:RequestUseItem(self.tbItem:GetInstanceId(), DEFAULT_USE_COUNT, LobbyChatSystem:PackTextMsg(szContent))
end

function UISpeakerContent:OnLoad()
    self.pbDialogFrame = self.PrefabHelper:BindPrefab(self.pWidgetRef.pbDialogFrame)
    self.pbDialogFrame:SetDialogClosedCallback(self.CloseSelf, self)
    self.pbDialogFrame:SetCloseButtonVisible(true)
    self.pbDialogFrame:SetPositiveButtonCallback(OnClickSend, self)

    self.tbItem = self.tbOpenArgs.tbItem
    self.pbDialogFrame:SetTitle(self.tbItem:GetName())

    local nCount = ItemSystem:GetItemCount(self.tbItem:GetTemplateId()) 
    local l10nLeft = L10N:Format(UISetUtils.GetL10NTextByKey("SPEAKER_COUNT_LEFT"), nCount)
    self.pWidgetRef.txtLeft:SetText(l10nLeft)
    OnTextChanged(self)
end

function UISpeakerContent:OnShow()
        
end

function UISpeakerContent:OnExit()
end



function UISpeakerContent:OnBindEvent()
    self.EventHelper:RegisterCppDelegate(self.pWidgetRef.txtContent.OnTextChanged, self, OnTextChanged)
end


return UISpeakerContent
