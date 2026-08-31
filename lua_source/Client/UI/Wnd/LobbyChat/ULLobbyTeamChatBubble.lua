-----------------------------------------------------
--File Name    : ULLobbyTeamChatBubble.lua
--Author       : Edward J
--Create Time  : 2020-08-12
--Description  : ULLobbyTeamChatBubble
-----------------------------------------------------
local luaclass                  = require("luaclass")
local UILogicBase               = require("UILogicBase")
local ULLobbyTeamChatBubble     = luaclass("ULLobbyTeamChatBubble", UILogicBase)

local ClientEventDef            = require("ClientEventDef")
-----------------------------------------------------
local BUBBLE_COUNT  = 4
local BUBBLE_PREFIX = "pbChatBubble0"

ULLobbyTeamChatBubble.tbBubblePreb  = nil
ULLobbyTeamChatBubble.tbBubbleQueue = nil
-----------------------------------------------------
local function GetUnuseBubble(self)
    if not self.tbBubblePreb then
        return nil
    end
    for i,v in ipairs(self.tbBubblePreb) do
        if v and not v:IsInUse() then
            return v
        end
    end
    return nil
end

function ULLobbyTeamChatBubble:OnLoad()
    self.tbBubblePreb = {}
    self.tbBubbleQueue = {}

    for i = 1,BUBBLE_COUNT do
        local pScript = self.PrefabHelper:BindPrefab(self.pWidgetRef[BUBBLE_PREFIX..i])
        if pScript then
            pScript:Deactivate()
            table.insert(self.tbBubblePreb, pScript)
        end
    end
end

function ULLobbyTeamChatBubble:OnUnload()
    for i,v in ipairs(self.tbBubblePreb) do
        self.PrefabHelper:UnbindPrefab(v)
    end
end

function ULLobbyTeamChatBubble:ShowBubble(nPlayerId, pWorldPos, szText)
    local pBubbleScript = self.tbBubbleQueue[nPlayerId]
    if not pBubbleScript then
        pBubbleScript = GetUnuseBubble(self)
        if not pBubbleScript then
            return
        end
        self.tbBubbleQueue[nPlayerId] = pBubbleScript
    end
    self.pWidgetRef:GetLocalPosWithWorldPos(pBubbleScript.pWidgetRef, pWorldPos)
    pBubbleScript:SetText(szText)
end

function ULLobbyTeamChatBubble:OnBindEvent(EventHelper)
    EventHelper:RegisterEvent(ClientEventDef.EV_LOBBY_CHAT_BUBBLE, self, self.ShowBubble)
end

return ULLobbyTeamChatBubble