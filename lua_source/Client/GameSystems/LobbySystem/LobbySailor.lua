
local luaclass = require("luaclass")
local LobbySubBase = require("LobbySubBase")
local LobbySailor = luaclass("LobbySailor", LobbySubBase)

local UIManager = require("UIManager")
local UIDef = require("UIDef")
local ClientEventDef = require("ClientEventDef")

LobbySailor.tbSailorUIStack = nil

local function SwitchToNext(self, szWndName)
    local nLen = #self.tbSailorUIStack
    if nLen > 0 then  
        local szCurrentWnd = self.tbSailorUIStack[nLen]
        UIManager:CloseWnd(szCurrentWnd)
    end
    UIManager:OpenWnd(szWndName)
    table.insert(self.tbSailorUIStack, szWndName)
end

local function SwitchToPre(self)
    local nLen = #self.tbSailorUIStack
    if nLen > 1 then  
        local szCurrentWnd = self.tbSailorUIStack[nLen]
        UIManager:CloseWnd(szCurrentWnd)
        local szPreWnd = self.tbSailorUIStack[nLen - 1]
        UIManager:OpenWnd(szPreWnd)
        table.remove(self.tbSailorUIStack, nLen)
        --TODO: 加载切换视角
    end
end

local function CloseAll(self)
    for i , v in ipairs(self.tbSailorUIStack) do  
        if UIManager:IsWndOpen(v) then  
            UIManager:CloseWnd(v)
        end
    end
    self.tbSailorUIStack = {}
end

local function BindEvent(self)
    local EventHelper = self.EventHelper
    EventHelper:RegisterEvent(ClientEventDef.EV_LOBBYSAILOR_TO_PRE, self, SwitchToPre)
    EventHelper:RegisterEvent(ClientEventDef.EV_LOBBYSAILOR_TO_NEXT, self, SwitchToNext)
end

--------------override-----------------------
function LobbySailor:Init(Owner, nSubType)
    LobbySailor.super.Init(self, Owner, nSubType)
    self.tbSailorUIStack = {}
    return true
end

function LobbySailor:Uninit()
    LobbySailor.super.Uninit(self)
    self.tbSailorUIStack = nil
end

function LobbySailor:Activate(tbParam)
    LobbySailor.super.Activate(self, tbParam)
    self.tbSailorUIStack = {}
    BindEvent(self)
    SwitchToNext(self, UIDef.UI_LOBBY_SAILOR_MAIN)
    --TODO 加载level
end

function LobbySailor:Deactivate()
    LobbySailor.super.Deactivate(self)
    CloseAll(self)
end

return LobbySailor