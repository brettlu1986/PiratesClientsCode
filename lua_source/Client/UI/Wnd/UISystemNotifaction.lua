-----------------------------------------------------
--File Name    : UISystemNotifaction.lua
--Author       : Edward J
--Create Time  : 2019-04-24
--Description  : UISystemNotifaction
-----------------------------------------------------
local luaclass                          = require("luaclass")
local WndBase                           = require("WndBase")
local UISystemNotifaction               = luaclass("UISystemNotifaction", WndBase)

local LobbyChatSystem                   = require("LobbyChatSystem")
local StringUtil                        = require("StringUtil")
local dkjson                            = require("dkjson")
local NotifactionMiscIni                = require("NotifactionMiscIni")
local ClientEventDef                    = require("ClientEventDef")
local LobbySubTypeDef                   = require("LobbySubTypeDef")
local BattleGameModeSystem              = dynamic_require("BattleGameModeSystem")
local TutorialDungeonIni                = require("TutorialDungeonIni")
local GlobalVariableSystem              = dynamic_require("GlobalVariableSystem")
-----------------------------------------------------
local Visible                   = ESlateVisibility.SelfHitTestInvisible
local Collapsed                 = ESlateVisibility.Collapsed
local MAX_MSG_COUNT             = 50

UISystemNotifaction.tbMsg           = nil
UISystemNotifaction.tbCurrentMsg    = nil
UISystemNotifaction.bInInterval     = false
UISystemNotifaction.bInShow         = false
-----------------------------------------------------
local function OnMoveFinish(self)
    self:ShowMsg()
end

local function SortFunc(a, b)
    return a.nPriority > b.nPriority
end

function UISystemNotifaction:ParseSystemContent(szContent)
    if not szContent then
      return nil  
    end
    --读表 解析出类型
    local tbData = dkjson.decode(szContent)
    if type(tbData) ~= "table" then
        logerror("UISystemNotifaction:ParseSystemContent not table")
        return nil
    end
    if tbData.nLoopCount == 0 then
        log("UISystemNotifaction:ParseSystemContent bShowNotify is 0")
        return nil
    end
    local nLoopCount = tonumber(tbData.nLoopCount)
    local nInterval = tonumber(tbData.nInterval)
    local nPriority = tonumber(tbData.nPriority)
    local nType = tonumber(tbData.nType)
    local tbTemp ={}
    tbTemp.nType = nType
    tbTemp.nLoopCount = nLoopCount
    if nInterval == 0 then
        nInterval = 0.1
    end
    tbTemp.nInterval = nInterval 
    tbTemp.nPriority = nPriority
    local szMsg = LobbyChatSystem:GetSystemContentText(szContent)
    tbTemp.szMsg = szMsg
    tbTemp.bNotPlayed = true
    return tbTemp
end

function UISystemNotifaction:GetMsg()
    local tbMsg = self.tbMsg
    local tbTemp = tbMsg[1]
    local bNotPlayed = false
    if tbTemp then
        local nLoopCount = tbTemp.nLoopCount
        nLoopCount = nLoopCount - 1
        tbTemp.nLoopCount = nLoopCount
        if tbTemp.bNotPlayed then
            tbTemp.bNotPlayed = false
            bNotPlayed = true
        end
        if nLoopCount <= 0 then
            table.remove(tbMsg, 1)
        end
    end
    return tbTemp, bNotPlayed
end

function UISystemNotifaction:AddMsg(szContent)
    local nDungeonId = BattleGameModeSystem:GetCurrentDungeonId()
    if nDungeonId == TutorialDungeonIni.nDungeonId or GlobalVariableSystem:IsInDungeon() then
        return
    end
    if type(szContent) == "string" and StringUtil.IsEmptyString(szContent) then
        self:Deactivate()
        return 
    end
    local tbMsg = self.tbMsg
    local nMsgCount = #tbMsg
    if nMsgCount >= MAX_MSG_COUNT then
        return
    end
    local tbTemp =  self:ParseSystemContent(szContent)
    if tbTemp then
        table.insert(tbMsg, tbTemp)
        table.sort(tbMsg, SortFunc)
        self:ShowMsg()
    end        
end

function UISystemNotifaction:GetSpeed()
    local nSpeed = NotifactionMiscIni.tbNotifaction.nSystemNotifySpeed
    return nSpeed
end

local function StartMove(self)
    self.pWidgetRef.ktxtMsg:SetVisibility(Visible)
    local nSpeed = self:GetSpeed()
    self.pWidgetRef:SetMoveSpeed(nSpeed)
    self.pWidgetRef:StartMove()
    self.bInInterval = false
end

local function SetNotice(self, tbMsg)
    self.bInShow = true
    self:Activate()
    self.pWidgetRef.ktxtMsg:SetVisibility(Collapsed)
    self.pWidgetRef:SetNotice(tbMsg.szMsg)
    self.pWidgetRef.ktxtMsg:SetVisibility(Visible)
    self.TimerHelper:RunNextTick(function () StartMove(self) end)
    self:NotifyToStart(tbMsg)
end

function UISystemNotifaction:NotifyToStart(tbMsg)
    
end

function UISystemNotifaction:NotifyToEnd()
    
end

function UISystemNotifaction:ShowMsg()
    if self.pWidgetRef.bStartMove or self.bInInterval then
        return
    end
    local tbMsg, bNotPlayed = self:GetMsg()
    self.tbCurrentMsg = tbMsg
    if not tbMsg then
        self.bInShow = false
        self:Deactivate()
    else
        local nInterval = tbMsg.nInterval
        self.bInInterval = true
        if bNotPlayed then
            SetNotice(self, tbMsg)
        else
            self.tbTimerHandler = self.TimerHelper:NewTimerMethod(self, function() SetNotice(self, tbMsg) end, nInterval, false)
        end
    end
end

function UISystemNotifaction:GetCurrentMsg()
    return self.tbCurrentMsg
end

function UISystemNotifaction:Activate()
    self.pWidgetRef:SetVisibility(Visible)
    self.pWidgetRef.cvsBox:SetVisibility(Visible)
end

function UISystemNotifaction:Deactivate()
    self.pWidgetRef:SetVisibility(Collapsed)
    self.pWidgetRef.cvsBox:SetVisibility(Collapsed)
    self:NotifyToEnd()
end

function UISystemNotifaction:OnLobbySubSystemActivate(nType)
    if nType == LobbySubTypeDef.MAIN then
        if self.bInShow then
            self:RecoverUI()
        end
    else
        self:HideUI()
    end
end

function UISystemNotifaction:OnLoad()
    self.tbMsg = {}
    self.tbCurrentMsg = nil
end

function UISystemNotifaction:OnShow()
    self:Deactivate()
end

function UISystemNotifaction:HideUI()

end

function UISystemNotifaction:OnBindEvent(EventHelper)
    EventHelper:RegisterCppDelegate(self.pWidgetRef.OnMoveFinish, self, OnMoveFinish)
    EventHelper:RegisterEvent(ClientEventDef.EV_LOBBY_SUB_SYSTEM_ACTIVATE, self, self.OnLobbySubSystemActivate)
end

return UISystemNotifaction