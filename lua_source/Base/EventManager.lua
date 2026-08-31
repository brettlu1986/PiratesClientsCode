-----------------------------------------------------
--File Name    : EventManager.lua
--Author       : yangyankun
--Create Time  : 2016-06-22
--Description  : 实现一套事件系统
-----------------------------------------------------
local EventManager = {}

-- DispatcherBase基类，外部需重载fire
local luaclass = require("luaclass")
local DispatcherBase = luaclass("EventManager.DispatcherBase")
EventManager.DispatcherBase = DispatcherBase

function DispatcherBase:Fire(nEvent, ...)
end

-----------------------------------------------------
local tbDispatchers = nil

local DefaultDispatcher = {}
local bEnableDebugLog = false
local tbEventList = {}
local bInFiring = false
local tbDispatcherToBeDeleted = nil

local NewEventHandle = function(Next, _nEvent, fnCallBack, tbClass)
    local tbHandle = {}
    tbHandle.Next = Next
    --tbHandle.nEvent = nEvent
    tbHandle.fnCallBack = fnCallBack
    tbHandle.tbClass = tbClass
    return tbHandle
end

local Call = function(tbHandle, ...)
    if tbHandle.tbClass then
        tbHandle.fnCallBack(tbHandle.tbClass, ...)
    else
        tbHandle.fnCallBack(...)
    end
end

local AddToList = function(tbHeader, nEvent, tbClass, fnCallBack)
    if(tbHeader ~= nil) then
        local tbTempNode = tbHeader
        while(tbTempNode) do
            if(tbTempNode.tbClass == tbClass) and (tbTempNode.fnCallBack == fnCallBack) then
                return nil
            end
            tbTempNode = tbTempNode.Next
        end
    end
    return NewEventHandle(tbHeader, nEvent, fnCallBack, tbClass)
end

local RemoveFromList = function(tbHeader, tbClass, fnCallBack)
    local tbRetHeader = tbHeader
    local tbLastNode = tbHeader
    local tbTempNode = tbHeader
    while(tbTempNode) do
        if(tbTempNode.tbClass == tbClass) and (tbTempNode.fnCallBack == fnCallBack) then
            if(tbTempNode == tbHeader) then
                tbRetHeader = tbRetHeader.Next
            else
                tbLastNode.Next = tbTempNode.Next
            end
            tbTempNode.bDestroyed = true
            break
        end
        tbLastNode = tbTempNode
        tbTempNode = tbTempNode.Next
    end
    return tbRetHeader
end

local BindEventImpl = function(nEvent, tbClass, fnCallBack)
    -- init the event list
    if(fnCallBack == nil) then
        error('BindEvent failed, fnCallBack is nil')
        return nil
    end

    local tbHeader = tbEventList[nEvent]
    tbHeader = AddToList(tbHeader, nEvent, tbClass, fnCallBack)
    if(tbHeader == nil) then
        error('BindEvent failed, already bind the fnCallBack')
        return nil
    end

    if bEnableDebugLog then
       tbHeader.szTrack = debug.traceback()
    end
    tbEventList[nEvent] = tbHeader
end

local UnBindEventImpl = function(nEvent, tbClass, fnCallBack)
    -- check valid of nEvent
    if(fnCallBack == nil) then
        error('UnBindEvent failed, fnCallBack is nil')
        return
    end

    local tbHeader = tbEventList[nEvent]
    if not tbHeader then
        return
    end
    tbEventList[nEvent] = RemoveFromList(tbHeader, tbClass, fnCallBack)
end

function DefaultDispatcher:BindEvent(nEvent, fnCallBack)
    BindEventImpl(nEvent, nil, fnCallBack)
end

function DefaultDispatcher:BindEventMethod(nEvent, tbClass, fnCallBack)
    BindEventImpl(nEvent, tbClass, fnCallBack)
end

function DefaultDispatcher:UnBindEvent(nEvent, fnCallBack)
    UnBindEventImpl(nEvent, nil, fnCallBack)
end

function DefaultDispatcher:UnBindEventMethod(nEvent, tbClass, fnCallBack)
    UnBindEventImpl(nEvent, tbClass, fnCallBack)
end

function DefaultDispatcher:Fire(nEvent, ...)
    local tbHeader = tbEventList[nEvent]
    local tbHandle
    while(tbHeader) do
        tbHandle = tbHeader
        tbHeader = tbHeader.Next
        if(tbHandle and not tbHandle.bDestroyed) then
            Call(tbHandle, ...)
        end
    end
end

function DefaultDispatcher:CheckEventList()
    if GWithEditor then
        for _,v in pairs(tbEventList) do
            logerror("!!!!!!!!!!!!! Please check event unbind, debug track:", v.szTrack)
        end
    end
end

-----------------------------------------------------
function EventManager:Init()
    tbDispatchers = {}
    self:RegisterDispatcher("Default", DefaultDispatcher)
    return true
end

function EventManager:Uninit()
    DefaultDispatcher:CheckEventList()
end

-----------------------------------------------------
function EventManager:RegisterDispatcher(szName, tbDispatcher)
    self[szName] = tbDispatcher

    -- 为了遍历时能稍微快一点，这里当成了数组，如果有需求记name，那再改成map把
    table.insert(tbDispatchers, tbDispatcher)
    return tbDispatcher
end

function EventManager:UnregisterDispatcher(szName, tbDispatcher)
    self[szName] = nil
    if(bInFiring) then
        if(tbDispatcherToBeDeleted == nil) then
            tbDispatcherToBeDeleted = {}
        end
        tbDispatcherToBeDeleted[tbDispatcher] = szName
    else
        for k, v in ipairs(tbDispatchers) do
            if(v == tbDispatcher) then
                table.remove(tbDispatchers, k)
                break
            end
        end
    end
end

function EventManager:BindEvent(nEvent, fnCallBack)
    DefaultDispatcher:BindEvent(nEvent, fnCallBack)
end

function EventManager:BindEventMethod(nEvent, tbClass, fnCallBack)
    if type(tbClass) ~= "table" then
        error('BindEventMethod warning, tbClass is not a luaclass')
    end

    DefaultDispatcher:BindEventMethod(nEvent, tbClass, fnCallBack)
end

function EventManager:UnBindEvent(nEvent, fnCallBack)
    DefaultDispatcher:UnBindEvent(nEvent, fnCallBack)
end

function EventManager:UnBindEventMethod(nEvent, tbClass, fnCallBack)
    if type(tbClass) ~= "table" then
        error('UnBindEventMethod warning, tbClass is not a luaclass')
    end
    DefaultDispatcher:UnBindEventMethod(nEvent, tbClass, fnCallBack)
end

function EventManager:OnFireEvent(nEvent, ...)
    bInFiring = true
    for _, v in ipairs(tbDispatchers) do
        if(tbDispatcherToBeDeleted == nil or tbDispatcherToBeDeleted[v] == nil) then
            v:Fire(nEvent, ...)
        end
    end
    bInFiring = false

    if(tbDispatcherToBeDeleted) then
        for tbDispatcher, szName in pairs(tbDispatcherToBeDeleted) do
            self:UnregisterDispatcher(tbDispatcher, szName)
        end
        tbDispatcherToBeDeleted = nil
    end
end

function EventManager.EnableDebugLog(bEnable)
    bEnableDebugLog = bEnable
end

-- function EventManager:UnBindEventByHandle(tbHandle)
--     -- check valid of nEvent
--     if(tbHandle == nil) then
--         return
--     end

--     local nEvent = tbHandle.nEvent
--     local tbHeader = tbEventList[nEvent]
--     if not tbHeader then
--         return
--     end
--     tbEventList[nEvent] = RemoveFromList(tbHeader, tbHandle.tbClass, tbHandle.fnCallBack)
-- end

function EventManager:DumpInfo()
    local nTotalCount = 0
    local nEventCount = 0
    for nEvent, tbHeader in pairs(tbEventList) do
        local nCount = 0
        nEventCount = nEventCount + 1
        while(tbHeader) do
            nCount = nCount + 1
            tbHeader = tbHeader.Next
        end
        nTotalCount = nTotalCount + nCount
        log(string.format("Event: %d, Count: %d", nEvent, nCount))
    end
    log(string.format("Event count: %d, listener count: %d", nEventCount, nTotalCount))
end

return EventManager
