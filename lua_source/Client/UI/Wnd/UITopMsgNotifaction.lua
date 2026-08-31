-----------------------------------------------------
--File Name    : UITopMsgNotifaction.lua
--Author       : Edward J
--Create Time  : 2019-12-23
--Description  : UITopMsgNotifaction
-----------------------------------------------------
local luaclass                          = require("luaclass")
local UISystemNotifaction               = require("UISystemNotifaction")
local UITopMsgNotifaction               = luaclass("UITopMsgNotifaction", UISystemNotifaction)

local ChatIni                           = require("ChatIni")
local LobbyChatSystem                   = require("LobbyChatSystem")
local NotifactionMiscIni                = require("NotifactionMiscIni")
local EventManager                      = require("EventManager")
local ClientEventDef                    = require("ClientEventDef")
-----------------------------------------------------
local SHOW_INTERVAL                     = ChatIni.tbHorn.nInterval
local PRIORITY                          = 1000

UITopMsgNotifaction.OriginPos     = nil
UITopMsgNotifaction.HidePos       = nil
-----------------------------------------------------
function UITopMsgNotifaction:OnLoad()
  UITopMsgNotifaction.super.OnLoad(self)
  self.OriginPos = self.pWidgetRef.cvsBox.Slot:GetPosition()
  self.HidePos = Vector2D{X = self.OriginPos.X, Y = self.OriginPos.Y - 1000}
end

function UITopMsgNotifaction:GetSpeed()
  local nSpeed = NotifactionMiscIni.tbNotifaction.nTopMsgSpeed
  return nSpeed
end

function UITopMsgNotifaction:ParseSystemContent(tbData)
  if not tbData then
    return nil  
  end
  local szName = tbData.szName
  local szContent = tbData.szContent
  local tbContentData = LobbyChatSystem:UnpackContent(szContent)
  szContent = tbContentData[2]
  local szMsg = szName .. " : " .. szContent
  local nLoopCount = 1
  local nInterval = SHOW_INTERVAL
  local nPriority = PRIORITY
  local tbTemp ={}
  tbTemp.szName = szName
  tbTemp.nSenderId = tbData.nSenderId
  tbTemp.nLoopCount = nLoopCount
  tbTemp.nInterval = nInterval 
  tbTemp.nPriority = nPriority
  tbTemp.szMsg = szMsg
  tbTemp.szContent = szContent
  tbTemp.bNotPlayed = true
  return tbTemp
end

function UITopMsgNotifaction:NotifyToStart(tbMsg)
  EventManager:OnFireEvent(ClientEventDef.EV_SHOW_TOP_MSG, tbMsg)
end

function UITopMsgNotifaction:NotifyToEnd()
  EventManager:OnFireEvent(ClientEventDef.EV_DEACTIVE_TOP_MSG)
end

function UITopMsgNotifaction:HideUI()
  local pWidgetRef = self.pWidgetRef
  pWidgetRef.cvsContent.Slot:SetPosition(self.HidePos)
end

function UITopMsgNotifaction:RecoverUI()
  local pWidgetRef = self.pWidgetRef
  pWidgetRef.cvsContent.Slot:SetPosition(self.OriginPos)
end

function UITopMsgNotifaction:Deactivate()
  UITopMsgNotifaction.super.Deactivate(self)
  self:RecoverUI()
end

return UITopMsgNotifaction