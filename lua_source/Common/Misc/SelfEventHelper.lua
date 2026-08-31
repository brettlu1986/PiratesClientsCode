local luaclass = require("luaclass")
local SelfEventHelper = luaclass("SelfEventHelper")

local EventManager = require("EventManager")
local CppDelegate = require("CppDelegate")


local COMPOSITE_AND = 1
local COMPOSITE_OR = 2
local INIT_COMPOSITE_INDEX = -1000

SelfEventHelper.tbEvents = {}
SelfEventHelper.tbEventObjects = {}
SelfEventHelper.tbCppDelegates = {}
SelfEventHelper.tbLuaDelegates = {}
SelfEventHelper.tbHandles = {}

SelfEventHelper.tbComposite = {}
SelfEventHelper.nCompositeIndex = INIT_COMPOSITE_INDEX



local tbTempCurrentComposite = nil

local function CreateCompositeKey(self)
    local nCompositeIndex = self.nCompositeIndex
    nCompositeIndex = nCompositeIndex + 1
    self.nCompositeIndex = nCompositeIndex
    return nCompositeIndex
end

local function CreateComposite(self, nRelation, EndFunc, VerifyFunc)
    local tbComposite = {}
    local nNewKey = CreateCompositeKey(self);
    tbComposite.Type = nRelation
    tbComposite.Func = EndFunc
    tbComposite.VerifyFunc = VerifyFunc
    if nRelation == COMPOSITE_AND then
        tbComposite.tbHitEvent = {}
        tbComposite.nMaxCondition = 0
        tbComposite.nHitCount = 0
        tbComposite.nHitIndex = 0
    end
    if not tbTempCurrentComposite then
        self.tbComposite[nNewKey] = tbComposite
    else
        if tbTempCurrentComposite.Type == COMPOSITE_AND then
            tbTempCurrentComposite.nMaxCondition = tbTempCurrentComposite.nMaxCondition + 1
        end
        tbComposite.tbParent = tbTempCurrentComposite
    end
    tbTempCurrentComposite = tbComposite
    return nNewKey
end

local function EndComposite(self)
    assert(tbTempCurrentComposite)
    local tbParent = tbTempCurrentComposite.tbParent
    if tbParent then
        tbTempCurrentComposite = tbParent
    else
        tbTempCurrentComposite = nil
    end
end

local function CompositeDoneFunc(self, tbComposite, ResultKey)
    local bFulfill = false
    if tbComposite.Type == COMPOSITE_OR then
        bFulfill = true
    else
        assert(ResultKey)
        local nHitIndex = tbComposite.nHitIndex
        local tbHitEvent = tbComposite.tbHitEvent
        if tbHitEvent[ResultKey] ~= nHitIndex then
            tbHitEvent[ResultKey] = nHitIndex
            local nHitCount = tbComposite.nHitCount
            nHitCount = nHitCount + 1
            tbComposite.nHitCount = nHitCount

            log("tbComposite.nHitCount,tbComposite.nMaxCondition=", tbComposite.nHitCount, tbComposite.nMaxCondition)
            if nHitCount == tbComposite.nMaxCondition then
                bFulfill = true
                tbComposite.nHitCount = 0
                tbComposite.nHitIndex = nHitIndex + 1
            end
        end
    end

    if bFulfill then
        if tbComposite.Func then
            tbComposite.Func()
        end
        local tbParent = tbComposite.tbParent
        if tbParent then
            CompositeDoneFunc(self, tbParent, tbComposite)
        end
    end
end

local function ReplaceCompositeEvent(self, Class, Handle, Func)
    assert(tbTempCurrentComposite)
    local tbComposite = tbTempCurrentComposite
    if tbComposite.Type == COMPOSITE_AND then
        tbComposite.nMaxCondition = tbComposite.nMaxCondition + 1
    end
    local FuncTemp = function(...)
        if(Func) then
            if Class then
                Func(Class, ...)
            else
                Func(...)
            end
        end
        local VerifyFunc = tbComposite.VerifyFunc
        local bRet = not VerifyFunc
        if VerifyFunc then
            if Class then
                bRet = VerifyFunc(Class, Handle, ...)
            else
                bRet = VerifyFunc(Handle, ...)
            end
        end
        if bRet then
            CompositeDoneFunc(self, tbComposite, Handle)
        end
    end
    return FuncTemp
end


--[[
    Multi Event
]]

function SelfEventHelper:BeginCompositeAndEvent(Class, EndFunc, VerifyFunc)
    local EndFuncTemp = nil
    if EndFunc then
        EndFuncTemp = function()
            EndFunc(Class)
        end
    end
    return CreateComposite(self, COMPOSITE_AND, EndFuncTemp, VerifyFunc)
end

function SelfEventHelper:BeginCompositeAndEventFunc(EndFunc, VerifyFunc)
    return CreateComposite(self, COMPOSITE_AND, EndFunc, VerifyFunc)
end

function SelfEventHelper:BeginCompositeOrEvent(Class, EndFunc, VerifyFunc)
    local EndFuncTemp = nil
    if EndFunc then
        EndFuncTemp = function()
            EndFunc(Class)
        end
    end
    return CreateComposite(self, COMPOSITE_OR, EndFuncTemp, VerifyFunc)
end

function SelfEventHelper:BeginCompositeOrEventFunc(EndFunc, VerifyFunc)
    return CreateComposite(self, COMPOSITE_OR, EndFunc, VerifyFunc)
end

function SelfEventHelper:EndCompositeEvent()
    EndComposite(self)
end

function SelfEventHelper:EndCompositeEventFunc()
    EndComposite(self)
end

--[[暂只能解绑Composite，Composite里面的event需要单独解绑或通过UnregisterAll来解绑。（因为SelfEventHelper里提供了三种类型事件的绑定与解绑接口，单独解绑composite需要
缓存更多数据来区分不同类型的事件解绑方式，比较费）
例如：
绑定
local Handle = EventHelper:BeginCompositeOrEvent(self, XXXEndFunc, XXXVerifyFunc)
    EventHelper:RegisterEvent(ClientEventDef.EV_XXX, class, XXXFunc)
    EventHelper:RegisterEvent(ClientEventDef.EV_YYY, class, YYYFunc)
    EventHelper:EndCompositeEvent()
解绑
    EventHelper:UnregisterEvent(ClientEventDef.EV_XXX)
    EventHelper:UnregisterEvent(ClientEventDef.EV_YYY)
    EventHelper:UnRegisterComposite(Handle)
]]
function SelfEventHelper:UnRegisterComposite(CompositeHandle)
    self.tbComposite[CompositeHandle] = nil
end

--[[
    All
]]
function SelfEventHelper:UnregisterAll()
    local tbEvents = self.tbEvents
    local tbEventObjects = self.tbEventObjects
    local tbObject
    for k, v in pairs(tbEvents) do
        tbObject = tbEventObjects[k]
        if(tbObject) then
            EventManager.Object:UnBindEvent(k, tbObject, v)
        else
            EventManager:UnBindEvent(k, v)
        end
    end
    self.tbEvents = {}
    self.tbEventObjects = {}

    local tbCppDelegates = self.tbCppDelegates
    for _, v in pairs(tbCppDelegates) do
        v:Unbind()
    end
    self.tbCppDelegates = {}

    local tbLuaDelegates = self.tbLuaDelegates
    for k, v in pairs(tbLuaDelegates) do
        k:Unbind(v[1], v[2])
    end
    self.tbLuaDelegates = {}

    local tbHandles = self.tbHandles
    for _,v in pairs(tbHandles) do
        if v.Unbind then
            v:Unbind()
        end
    end
    self.tbHandles = {}
    self.tbComposite = {}
end

--[[
    Event
]]
function SelfEventHelper:RegisterEventFunc(Event, Func)
    if(self.tbEvents[Event]) then
        error("SelfEventHelper register duplicated.")
    end
    local FuncTemp
    if tbTempCurrentComposite then
        FuncTemp = ReplaceCompositeEvent(self, nil, Event, Func)
    else
        if Func == nil or type(Func) ~= 'function' then
            error("SelfEventHelper:RegisterEvent failed. Func is nil")
        end
        FuncTemp = Func
    end

    EventManager:BindEvent(Event, FuncTemp)
    self.tbEvents[Event] = FuncTemp
    return Event
end

function SelfEventHelper:RegisterEvent(Event, Class, Func)
    if(self.tbEvents[Event]) then
        error("SelfEventHelper register duplicated.")
    end
    local FuncTemp
    if tbTempCurrentComposite then
        FuncTemp = ReplaceCompositeEvent(self, Class, Event, Func)
    else
        if Func == nil or type(Func) ~= 'function' then
            error("SelfEventHelper:RegisterEvent failed. Func is nil")
        end
        FuncTemp = function(...)
            Func(Class, ...)
        end
    end
    EventManager:BindEvent(Event, FuncTemp)
    self.tbEvents[Event] = FuncTemp
    return Event
end

function SelfEventHelper:RegisterObjectEventFunc(Event, tbGameObject, Func)
    if(self.tbEvents[Event]) then
        error("SelfEventHelper register duplicated.")
    end
    local FuncTemp
    if tbTempCurrentComposite then
        FuncTemp = ReplaceCompositeEvent(self, nil, Event, Func)
    else
        if Func == nil or type(Func) ~= 'function' then
            error("SelfEventHelper:RegisterObjectEventFunc failed. Func is nil")
        end
        FuncTemp = Func
    end

    EventManager.Object:BindEvent(Event, tbGameObject, FuncTemp)
    self.tbEvents[Event] = FuncTemp
    self.tbEventObjects[Event] = tbGameObject
    return Event
end

function SelfEventHelper:RegisterObjectEvent(Event, tbGameObject, Class, Func)
    if(self.tbEvents[Event]) then
        error("SelfEventHelper register duplicated.")
    end
    local FuncTemp
    if tbTempCurrentComposite then
        FuncTemp = ReplaceCompositeEvent(self, Class, Event, Func)
    else
        if Func == nil or type(Func) ~= 'function' then
            error("SelfEventHelper:RegisterEvent failed. Func is nil")
        end
        FuncTemp = function(...)
            Func(Class, ...)
        end
    end
    EventManager.Object:BindEvent(Event, tbGameObject, FuncTemp)
    self.tbEvents[Event] = FuncTemp
    self.tbEventObjects[Event] = tbGameObject
    return Event
end

function SelfEventHelper:UnregisterEvent(Event)
    local Func = self.tbEvents[Event]
    if(Func) then
        local tbObject = self.tbEventObjects[Event]
        if(tbObject) then
            EventManager.Object:UnBindEvent(Event, tbObject, Func)
            self.tbEventObjects[Event] = nil
        else
            EventManager:UnBindEvent(Event, Func)
        end
        self.tbEvents[Event] = nil
    end
end

function SelfEventHelper:FireEvent(Key, ...)
    EventManager:OnFireEvent(Key, ...)
end

--[[
    CppDelegate
]]
function SelfEventHelper:RegisterCppDelegate(Event, Class, Func, szInfo)
    szInfo = szInfo or getdebuginfo_f(Func)
    if tbTempCurrentComposite then
        local FuncTemp = ReplaceCompositeEvent(self, Class, Event, Func)
        local Delegate = CppDelegate:Bind(Event, FuncTemp, szInfo)
        self.tbCppDelegates[Delegate] = Delegate
        return Delegate
    else
        if Func == nil or type(Func) ~= 'function' then
            error("SelfEventHelper:RegisterEvent failed. Func is nil")
        end
        local Delegate = CppDelegate:BindMethod(Event, Class, Func, szInfo)
        self.tbCppDelegates[Delegate] = Delegate
        return Delegate
    end
end

function SelfEventHelper:RegisterCppDelegateFunc(Event, Func, szInfo)
    szInfo = szInfo or getdebuginfo_f(Func)
    local FuncTemp
    if tbTempCurrentComposite then
        FuncTemp = ReplaceCompositeEvent(self, nil, Event, Func)
    else
        if Func == nil or type(Func) ~= 'function' then
            error("SelfEventHelper:RegisterCppDelegateFunc failed. Func is nil")
        end
        FuncTemp = Func
    end

    local Delegate = CppDelegate:Bind(Event, FuncTemp, szInfo)
    self.tbCppDelegates[Delegate] = Delegate
    return Delegate
end

function SelfEventHelper:UnregisterCppDelegate(Delegate)
    if(Delegate) then
        Delegate:Unbind()
        self.tbCppDelegates[Delegate] = nil
    end
end

--[[
    LuaDelegate
]]
function SelfEventHelper:RegisterLuaDelegate(Delegate, Func, Class)
    if Delegate then
        if tbTempCurrentComposite then
            local FuncTemp = ReplaceCompositeEvent(self, Class, Delegate, Func)
            Delegate:Bind(FuncTemp)
            self.tbLuaDelegates[Delegate] = {FuncTemp}
        else
            if Func == nil or type(Func) ~= 'function' then
                error("SelfEventHelper:RegisterLuaDelegate failed. Func is nil")
            end
            Delegate:Bind(Func, Class)
            self.tbLuaDelegates[Delegate] = {Func, Class}
        end
    end
    return Delegate
end

function SelfEventHelper:UnregisterLuaDelegate(Delegate, Func, Class)
    if Delegate then
        Delegate:Unbind(Func, Class)
        self.tbLuaDelegates[Delegate] = nil
    end
end

--[[
    Common
]]
function SelfEventHelper:RegisterHandle(CommonHandle)
    if tbTempCurrentComposite then
        error("RegisterHandle is not be supported in composite!")
    end
    self.tbHandles[CommonHandle] = CommonHandle
    return CommonHandle
end

function SelfEventHelper:UnRegisterHandle(CommonHandle)
    if(CommonHandle) then
        if CommonHandle.Unbind then
            CommonHandle:Unbind()
        end
        self.tbHandles[CommonHandle] = nil
    end
end






return SelfEventHelper
