local BattleBlackboard = {}

local CheckParamUtil = require("CheckParamUtil")
local LinkedList = require("LinkedList")

local tbValues = nil
local tbPostListeners = nil

function BattleBlackboard:Init()
    tbValues = {}
    tbPostListeners = {}
end

function BattleBlackboard:Uninit()
    tbValues = nil
    tbPostListeners = nil
end

function BattleBlackboard:AddPostChangeCallback(szKey, fnCallback)
    local Head = tbPostListeners[szKey]
    if(Head == nil) then
        tbPostListeners[szKey] = LinkedList.New(fnCallback)
    else
        tbPostListeners[szKey] = LinkedList.Add(Head, fnCallback)
    end
end

function BattleBlackboard:RemovePostChangeCallback(szKey, fnCallback)
    local Head = tbPostListeners[szKey]
    if(Head ~= nil) then
        tbPostListeners[szKey] = LinkedList.Remove(Head, fnCallback)
    end
end

local function CallPostChangeListener(self, szKey, Value)
    local Next = LinkedList.Next
    local Head = tbPostListeners[szKey]
    while(Head) do        
        Head.Value(szKey, Value)
        Head = Next(Head)
    end
end

function BattleBlackboard:Clear()
    tbValues = {}
    tbPostListeners = {}
end

function BattleBlackboard:DefineNumber(szKey, InitValue)
    if(tbValues[szKey] ~= nil) then
        error("BattleBlackboard define number failed, the key "..szKey.." has defined.")
        return false
    end
    tbValues[szKey] = InitValue
    return true
end

function BattleBlackboard:DefineString(szKey, InitValue)
    if(tbValues[szKey] ~= nil) then
        error("BattleBlackboard define string failed, the key "..szKey.." has defined.")
        return false
    end
    tbValues[szKey] = InitValue
    return true
end

function BattleBlackboard:DefineBool(szKey, InitValue)
    if(tbValues[szKey] ~= nil) then
        error("BattleBlackboard define bool failed, the key "..szKey.." has defined.")
        return false
    end
    tbValues[szKey] = InitValue
    return true
end

function BattleBlackboard:DefineTable(szKey, InitValue)
    if(tbValues[szKey] ~= nil) then
        error("BattleBlackboard define table failed, the key "..szKey.." has defined.")
        return false
    end
    if(InitValue ~= nil) then
        tbValues[szKey] = InitValue
    else
        tbValues[szKey] = false
    end
    return true
end

function BattleBlackboard:Undefine(szKey)
    tbValues[szKey] = nil
end

function BattleBlackboard:SetNumber(szKey, Value)
    if(tbValues[szKey] == nil) then
        error("BattleBlackboard set number failed, the key "..szKey.." has not defined.")
        return false
    end
    CheckParamUtil.number(Value)
    tbValues[szKey] = Value
    CallPostChangeListener(self, szKey, Value)
    return true
end

function BattleBlackboard:GetNumber(szKey)
    local Value = tbValues[szKey]
    if(Value == nil) then
        error("BattleBlackboard get number failed, the key "..szKey.." has not defined.")
        return 0
    end
    CheckParamUtil.number(Value)
    return Value
end

function BattleBlackboard:SetString(szKey ,Value)
    if(tbValues[szKey] == nil) then
        error("BattleBlackboard set string failed, the key "..szKey.." has not defined.")
        return false
    end
    CheckParamUtil.string(Value)
    tbValues[szKey] = Value
    CallPostChangeListener(self, szKey, Value)
    return true
end

function BattleBlackboard:GetString(szKey)
    local Value = tbValues[szKey]
    if(Value == nil) then
        error("BattleBlackboard get string failed, the key "..szKey.." has not defined.")
        return ""
    end
    CheckParamUtil.string(Value)
    return Value
end

function BattleBlackboard:SetBool(szKey ,Value)
    if(tbValues[szKey] == nil) then
        error("BattleBlackboard set bool failed, the key "..szKey.." has not defined.")
        return false
    end
    CheckParamUtil.boolean(Value)
    tbValues[szKey] = Value
    CallPostChangeListener(self, szKey, Value)
    return true
end

function BattleBlackboard:GetBool(szKey)
    local Value = tbValues[szKey]
    if(Value == nil) then
        error("BattleBlackboard get bool failed, the key "..szKey.." has not defined.")
        return false
    end
    CheckParamUtil.boolean(Value)
    return Value
end

function BattleBlackboard:IsDefined(szKey)
    local Value = tbValues[szKey]
    if Value == nil then
        return false
    end
    return true
end

function BattleBlackboard:SetTable(szKey, Value)
    if(tbValues[szKey] == nil) then
        error("BattleBlackboard set table failed, the key "..szKey.." has not defined.")
        return false
    end
    if(Value ~= nil) then
        CheckParamUtil.table(Value)
        tbValues[szKey] = Value
    else
        tbValues[szKey] = false
    end
    CallPostChangeListener(self, szKey, Value)
    return true
end

function BattleBlackboard:GetTable(szKey)
    local Value = tbValues[szKey]
    if(Value == nil) then        
        return nil
    end
    if(type(Value) == 'boolean') then
        return nil    
    end
    CheckParamUtil.table(Value)
    return Value
end

function BattleBlackboard:GetRaw(szKey)
    return tbValues[szKey]
end

return BattleBlackboard