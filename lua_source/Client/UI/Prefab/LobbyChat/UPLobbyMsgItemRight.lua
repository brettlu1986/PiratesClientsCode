-----------------------------------------------------
--File Name    : UPLobbyMsgItemRight.lua
--Author       : Edward J
--Create Time  : 2018-04-16
--Description  : UPLobbyMsgItemRight
-----------------------------------------------------
local luaclass              = require("luaclass")
local UPLobbyMsgItemBase    = require("UPLobbyMsgItemBase")
local UPLobbyMsgItemRight   = luaclass("UPLobbyMsgItemRight", UPLobbyMsgItemBase)

local UIUtils           = require("UIUtils")
local UISetUtils        = require("UISetUtils")
local LobbyChatSystem   = require("LobbyChatSystem")
-- local TeamSystem        = require("TeamSystem")
-----------------------------------------------------
-----------------------------------------------------
function UPLobbyMsgItemRight:OnTeamingBtnClicked()
    local tbData = self.tbData
    local nSenderId = tbData.nSenderId
    local nTime = tbData.nTime
    if LobbyChatSystem:IsLatest(nSenderId, nTime) then
        UIUtils.ShowToast(UISetUtils.GetL10NTextByKey("LOBBYCHAT_ALREADY_IN_TEAM"))
        --TeamSystem:ReplyRecruitTeammate(nSenderId)
    else
        UIUtils.ShowToast(UISetUtils.GetL10NTextByKey("LOBBYCHAT_TEAM_INVITE_INVALILD"))
    end
end

function UPLobbyMsgItemRight:BindHeadBtn()
    self.pPlayHeadScript:EnableClickHeadDefaultAction(false)
end

function UPLobbyMsgItemRight:SetData(tbData)
    self.super.SetData(self, tbData)
end
return UPLobbyMsgItemRight