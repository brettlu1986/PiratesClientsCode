-----------------------------------------------------
--File Name    : AbilityEvent_AcquireBuff.lua
--Author       : Song Fuhao
--Create Time  : 2018-03-19
--Description  : 获得Buff事件
-----------------------------------------------------
local luaclass = require("luaclass")
local AbilityEventBaseClass = require("AbilityEventBase")
local AbilityEvent_AcquireBuff = luaclass("AbilityEvent_AcquireBuff", AbilityEventBaseClass)

AbilityEvent_AcquireBuff.bDone = false

local function OnBuffAdd(self, nBuffId, nTime, nOverlapCount, nLevel, nBuffInstanceId)
    -- 不重复触发
    if self.bDone then
        return
    end
    -- 指定BuffId才能触发
    if self.tbParams.BuffId and (tonumber(self.tbParams.BuffId) ~= nBuffId) then
        return
    end
    -- 达到指定层数才能触发
    if self.tbParams.Count and (nOverlapCount < tonumber(self.tbParams.Count)) then
        return
    end
    self:TriggerDo()
    self.bDone = true
end

local function OnBuffRemove(self, nBuffId, nBuffInstanceId)
    if self.bDone then
        self:TriggerUndo()
        self.bDone = false
    end
end

function AbilityEvent_AcquireBuff:OnActivate()
    local BuffComponentServer = self.OwnerPawn.BuffComponentServer
    if BuffComponentServer then
        BuffComponentServer.OnBuffAddDelegate:Bind(OnBuffAdd, self)
        BuffComponentServer.OnBuffRefreshDelegate:Bind(OnBuffAdd, self)
        BuffComponentServer.OnBuffRemoveDelegate:Bind(OnBuffRemove, self)
    end
end

function AbilityEvent_AcquireBuff:OnDeactivate()
    local BuffComponentServer = self.OwnerPawn.BuffComponentServer
    if BuffComponentServer then
        BuffComponentServer.OnBuffAddDelegate:Unbind(OnBuffAdd, self)
        BuffComponentServer.OnBuffRefreshDelegate:Unbind(OnBuffAdd, self)
        BuffComponentServer.OnBuffRemoveDelegate:Unbind(OnBuffRemove, self)
    end
end

return AbilityEvent_AcquireBuff
