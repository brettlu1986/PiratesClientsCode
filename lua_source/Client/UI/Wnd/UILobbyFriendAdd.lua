local luaclass              = require("luaclass")
local WndBase               = require("WndBase")
local UILobbyFriendAdd      = luaclass("UILobbyFriendAdd", WndBase)
local UTF8NameValidatorHelper = require("UTF8NameValidatorHelper")
local FriendIni             = require("FriendIni")
local UIUtils               = require("UIUtils")
local UISetUtils            = require("UISetUtils")
local FriendSystem          = require("FriendSystem")
local StringUtil            = require("StringUtil")
local L10N                  = require("L10N")

UILobbyFriendAdd.pbDialogFrame = nil

local function OnMessageChange(self)
    local editMessage = self.pWidgetRef.editMessage
    local szMessage = L10N:ToString(editMessage:GetText())
    -- szMessage = trim(szMessage)
    local nRet, nIndex = self.tbNameValidator:GetLegalNameLength(szMessage, FriendIni.tbApplyFriend.nMaxApplyFriendMessage)
    if nRet == self.tbNameValidator.Result.InvalidCodePoint then
        UIUtils.ShowToast(UISetUtils.GetL10NTextByKey("MESSGE_INVALID"))
    end
    szMessage = string.sub(szMessage, 1, nIndex)
    editMessage:SetText(szMessage)        

    local _, nDisplayWidth = self.tbNameValidator:DisplayWidth(szMessage)
    self.pWidgetRef.txtCount:SetText(nDisplayWidth.."/"..FriendIni.tbApplyFriend.nMaxApplyFriendMessage)
end

local function OnClickOk(self)
    local editMessage = self.pWidgetRef.editMessage
    local szMessage = L10N:ToString(editMessage:GetText())
    if szMessage == "" then
        szMessage = self.tbOpenArgs.szMsg
    end
    local _, nDisplayWidth = self.tbNameValidator:DisplayWidth(szMessage)
    if nDisplayWidth > FriendIni.tbApplyFriend.nMaxApplyFriendMessage then
        UIUtils.ShowToast(UISetUtils.GetL10NTextByKey("FRIEND_APPLY_MESSAGE_TOOLONG"))
        return
    end    
    local nId = self.tbOpenArgs.id or self.tbOpenArgs.nId
    FriendSystem:RequestApplyFriend(nId, StringUtil.Trim(szMessage))
end

local function OnClickClose(self)
    self:CloseSelf()
end

function UILobbyFriendAdd:OnLoad()
    self.pbDialogFrame = self.PrefabHelper:BindPrefab(self.pWidgetRef.pbDialogFrame)
    self.pbDialogFrame:SetPositiveButtonCallback(OnClickOk, self)
    self.pbDialogFrame:SetDialogClosedCallback(OnClickClose, self)
end

function UILobbyFriendAdd:OnCreate()
    self.tbNameValidator = UTF8NameValidatorHelper:ApplyFriendMessageValidator()
end

function UILobbyFriendAdd:OnShow()
    local pWidgetRef = self.pWidgetRef
    pWidgetRef.txtCount:SetText("0/"..FriendIni.tbApplyFriend.nMaxApplyFriendMessage)
    pWidgetRef.editMessage:SetHintText(self.tbOpenArgs.szMsg)
    self.pbDialogFrame:ShowDialog()
end

function UILobbyFriendAdd:OnDestroy()
    self.pbDialogFrame = nil
    self.tbNameValidator = nil 
end

function UILobbyFriendAdd:OnBindEvent(EventHelper)
    EventHelper:RegisterCppDelegate(self.pWidgetRef.editMessage.OnTextChanged, self, OnMessageChange)   
end

return UILobbyFriendAdd
