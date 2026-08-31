-- 黑板值比较

local luaclass = require("luaclass")
local BattleTargetBaseClass = require("BattleTargetBase")
local BattleBlackboardTargetBase = luaclass("BattleBlackboardTargetBase", BattleTargetBaseClass)

local BattleOperationHelper = require("BattleOperationHelper")
local BattleBlackboard = require("BattleBlackboard")

BattleBlackboardTargetBase.fnCallback = nil
BattleBlackboardTargetBase.szOperator = nil
BattleBlackboardTargetBase.szKey1 = nil
BattleBlackboardTargetBase.szKey2 = nil
BattleBlackboardTargetBase.Value2 = nil

function BattleBlackboardTargetBase:Check()
    -- 必须重载！
    return nil
end

function BattleBlackboardTargetBase:Init()
    BattleBlackboardTargetBase.super.Init(self)
    self.szName = "BattleBlackboardTargetBase"    
end

function BattleBlackboardTargetBase:Parse(tbJsonData)
    self.szOperator = tbJsonData.Operator
    self.szKey1 = tbJsonData.Key1
    self.szKey2 = tbJsonData.Key2
    self.Value2 = tbJsonData.Value2
    return string.len(self.szKey1) > 0
end

local function OnValuePostChanged(self)
    local Ret = self:Check()
    if(Ret == nil) then
        BattleOperationHelper:PrintError(self, "Do failed, Operator: "..self.szOperator..
            ", Key1: "..self.szKey1)
        return
    end

    if(Ret == true) then
        self:Complete()
    end
end

function BattleBlackboardTargetBase:RegisterEvent()
    self.fnCallback = function(szKey, Value)
        OnValuePostChanged(self)
    end
    BattleBlackboard:AddPostChangeCallback(self.szKey1, self.fnCallback)

    local szKey2 = self.szKey2
    if(szKey2 ~= nil and string.len(szKey2) > 0) then
        BattleBlackboard:AddPostChangeCallback(szKey2, self.fnCallback)
    end
end

function BattleBlackboardTargetBase:UnregisterEvent()
    local fnCallback = self.fnCallback
    if(fnCallback) then
        self.fnCallback = nil
        BattleBlackboard:RemovePostChangeCallback(self.szKey1, fnCallback)

        local szKey2 = self.szKey2
        if(szKey2 ~= nil and string.len(szKey2) > 0) then
            BattleBlackboard:RemovePostChangeCallback(szKey2, fnCallback)
        end
    end
end

function BattleBlackboardTargetBase:Start()
    BattleBlackboardTargetBase.super.Start(self)

    OnValuePostChanged(self)
end

return BattleBlackboardTargetBase
