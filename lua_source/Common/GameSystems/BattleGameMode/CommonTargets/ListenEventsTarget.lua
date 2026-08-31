-- 监听某一个事件的Target

local luaclass = require("luaclass")
local BattleTargetBaseClass = require("BattleTargetBase")
local ListenEventsTarget = luaclass("ListenEventsTarget", BattleTargetBaseClass)
local EventManager = require("EventManager")

--[[
    {
        nEvent = xx,
        fnOnEventCallback = xx,
    }
]]
ListenEventsTarget.tbEventList = nil

function ListenEventsTarget:Init()
    ListenEventsTarget.super.Init(self)
    self.szName = "ListenEventsTarget"
    self.tbEventList = {}
end

function ListenEventsTarget:Uninit()
    self.tbEventList = {}
    ListenEventsTarget.super.Uninit(self)
end

function ListenEventsTarget:CallBack(nCallbackEvent)
    local nFindIndex = -1
    local tbEventList = self.tbEventList
    for nIndex, tbEventInfo in pairs(tbEventList) do
        if tbEventInfo.nEvent == nCallbackEvent then
            nFindIndex = nIndex
            break
        end
    end

    if nFindIndex == -1 then
        return
    end

    table.remove(tbEventList, nFindIndex)

    local nCount = #tbEventList
    if nCount == 0 then
        self:Complete()
    end
end

function ListenEventsTarget:RegisterEvent()
    ListenEventsTarget.super.RegisterEvent()
    for k, tbEventInfo in pairs(self.tbEventList) do
        local fnOnEventCallback = nil
        fnOnEventCallback = function()
            EventManager:UnBindEvent(tbEventInfo.nEvent, fnOnEventCallback)
            self:CallBack(tbEventInfo.nEvent)
        end
        tbEventInfo.fnOnEventCallback = fnOnEventCallback
        EventManager:BindEvent(tbEventInfo.nEvent, tbEventInfo.fnOnEventCallback)
    end
end

function ListenEventsTarget:UnregisterEvent()
    if self.tbEventList == nil then
        return
    end

    local tbEventList = self.tbEventList
    for nIndex, tbEventInfo in pairs(tbEventList) do
        if tbEventInfo.fnOnEventCallback ~= nil then
            EventManager:UnBindEvent(tbEventInfo.nEvent, tbEventInfo.fnOnEventCallback)
        end
    end
end

function ListenEventsTarget:ListenEvent(nNewEvent)
    local tbEventInfo = {}
    tbEventInfo.nEvent = nNewEvent
    table.insert(self.tbEventList, tbEventInfo)
end

function ListenEventsTarget:Start()
    ListenEventsTarget.super.Start(self)
end

return ListenEventsTarget
