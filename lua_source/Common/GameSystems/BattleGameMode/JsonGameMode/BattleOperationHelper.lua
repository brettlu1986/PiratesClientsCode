local BattleOperationHelper = {}

local BattleOperationDef = dynamic_require("BattleOperationDef")

function BattleOperationHelper:GetClass(szOperation)
    if(szOperation == nil) then
        error("BattleOperationHelper GetClass failed, the input operation name is nil")
        return nil
    end
    local Class, bDynamicRequire = BattleOperationDef:FindOperation(szOperation)
    if(Class == nil) then
        error("BattleOperationHelper GetClass failed: " .. szOperation)
        return nil
    end

    if(bDynamicRequire == true) then
        return dynamic_require(Class)
    end

    return require(Class)
end

function BattleOperationHelper:Create(ParentOperation, tbJsonData, ...)
    local Class = self:GetClass(tbJsonData.OperationName)
    if(Class == nil) then
        return nil
    end
    local Operation = Class()
    if(Operation.Init) then
        Operation:Init(...)
    end
    Operation.szOperationName = tbJsonData.OperationName
    Operation.szOperationDesc = tbJsonData.Description
    Operation.ParentOperation = ParentOperation
    if(ParentOperation == nil or ParentOperation.nStack == nil) then
        Operation.nStack = 1
    else
        Operation.nStack = ParentOperation.nStack + 1
    end
    if(not Operation:Parse(tbJsonData)) then
        self:PrintError(Operation, "Parse failed")
        return nil
    end
    return Operation
end

local function GetStackString(nStack)
    local szRet = ""
    for i=1, nStack do
        szRet = szRet .. "-"
    end
    return szRet..">"
end

function BattleOperationHelper:PrintError(Operation, szError)
    if(Operation == nil) then
        error(szError)
        return
    end

    if(Operation.szOperationName == nil) then
        if(Operation.szName ~= nil) then
            error(Operation.szName..": "..szError)
        else
            error(szError)
        end
        return
    end

    error("Op"..GetStackString(Operation.nStack)..
        "[" .. Operation.szOperationName ..
        "][" .. ((Operation.szOperationDesc ~= nil) and Operation.szOperationDesc or "None") ..
        "]: Error: " .. szError)
end

function BattleOperationHelper:PrintTable(szTitle, tbTable)
    local dkjson = require("dkjson")
    log(szTitle..": "..dkjson.encode(tbTable))
end

function BattleOperationHelper:PrintLog(Operation, szTempLog)
    local szLog = (szTempLog ~= nil and szTempLog or "" )
    if(Operation == nil) then
        log(szLog)
        return
    end

    if(Operation.szOperationName == nil) then
        if(Operation.szName ~= nil) then
            log(Operation.szName..": "..szLog)
        else
            log(szLog)
        end
        return
    end

    log("Op"..GetStackString(Operation.nStack)..
        "[" .. Operation.szOperationName ..
        "][" .. ((Operation.szOperationDesc ~= nil) and Operation.szOperationDesc or "None") ..
        "]: " ..szLog)
end

function BattleOperationHelper:CallOperator(szOperator, A, B)
    local fnFunc = BattleOperationDef:FindOperator(szOperator)
    if(fnFunc == nil) then
        return nil
    end
    return fnFunc(A, B)
end

return BattleOperationHelper