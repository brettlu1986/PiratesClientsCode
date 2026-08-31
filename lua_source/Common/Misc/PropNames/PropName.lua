local PropName = {}

-- luacheck: push ignore
PropName.PropertyType = {
    Bool    = 1,
    Int     = 2,
    Float   = 3,
    String  = 4,
    Proto   = 5,
    Table   = 6,
}

-- rep类型c++只支持了下面几种，有需求在扩
local RepType = {
    NoRep                  = nil,
    All                    = ELifetimeCondition.COND_None,
    InitialOnly            = ELifetimeCondition.COND_InitialOnly,
    OwnerOnly              = ELifetimeCondition.COND_OwnerOnly,
    SkipOwner              = ELifetimeCondition.COND_SkipOwner,
    -- SimulatedOnly          = ELifetimeCondition.COND_SimulatedOnly,
    -- AutonomousOnly         = ELifetimeCondition.COND_AutonomousOnly,
    -- SimulatedOrPhysics     = ELifetimeCondition.COND_SimulatedOrPhysics,
    -- InitialOrOwner         = ELifetimeCondition.COND_InitialOrOwner,
}

-- luacheck: pop

local nTempPropertyId = 1
local tbPropertyIdToName = {}
local tbPropertyType = {}
local tbRepType = {}
local tbRepPropFiles = {}

local tbRepIdToBeChecked = {}
local tbCurrentRepIds = nil

function PropName.FindName(nPropertyId)
    return tbPropertyIdToName[nPropertyId]
end

-- 动态生成nameindex，小心生成时序
function PropName.VerifyNameIndex(szName)
    local nRet = PropName[szName]
    if(nRet == nil) then
        error("Can not generate property name in runtime: "..szName)
    end
    return nRet
end

function PropName.GetAllIdInfo()
    return tbPropertyIdToName, tbPropertyType, tbRepType
end

function PropName.GetRepIds(szFileName)
    return require(szFileName).GetRepIds()
end

function PropName.GetRepIdToBeChecked()
    return tbRepIdToBeChecked
end

function PropName.FindType(nPropertyId)
    return tbPropertyType[nPropertyId]
end

function PropName.FindRepType(nPropertyId)
    return tbRepType[nPropertyId]
end

function PropName.GetAllRepPropFiles()
    return tbRepPropFiles
end

function PropName.IsReplicatedToOwner(nPropertyId)
    local nRepType = tbRepType[nPropertyId]
    assert(nRepType)
    return nRepType == RepType.All
        or nRepType == RepType.InitialOnly
        or nRepType == RepType.OwnerOnly
        -- or nRepType == RepType.AutonomousOnly
        -- or nRepType == RepType.InitialOrOwner
end

function PropName.IsRepAll(nPropertyId)
    return tbRepType[nPropertyId] == RepType.All
end

local function Define(szName, nPropertyType, nRepType)
    local nId = PropName[szName]
    if(nId == nil) then
        nId = nTempPropertyId
        nTempPropertyId = nTempPropertyId + 1

        PropName[szName] = nId
        tbPropertyIdToName[nId] = szName
        tbPropertyType[nId] = nPropertyType
    end

    if(nRepType ~= nil and nPropertyType ~= RepType.Table) then
        assert(tbRepType[nId] == nil)
        tbRepType[nId] = nRepType
        for _, nTempId in ipairs(tbCurrentRepIds) do
            assert(nTempId ~= nId)
        end
        table.insert(tbCurrentRepIds, nId)
    end
    return nId
end

local function DeclarePropertyToBeChecked()
    local tbNames = {
        --"ProgressBar",
    }

    for _, v in ipairs(tbNames) do
        tbRepIdToBeChecked[PropName[v]] = true
    end
end

local tbMetaTable = {
    __index = function(t, szKey)
        local v = PropName[szKey]
        if(v) then
            return v
        else
            return rawget(t, szKey)
        end
    end,
    __newindex = nil
}

local function Register(szFileName)
    local tbCurrentNames = require(szFileName)
    if(tbCurrentNames.bReplicate == nil or tbCurrentNames.bReplicate == true) then
        table.insert(tbRepPropFiles, szFileName)
    end
    local tbRepIds = {}
    tbCurrentRepIds = tbRepIds
    tbCurrentNames.GetRepIds = function()
        return tbRepIds
    end

    tbCurrentNames.Init(Define, PropName.PropertyType, RepType)
    setmetatable(tbCurrentNames, tbMetaTable)
end

local function Init()
    local PropNameRegister = require("PropNameRegister")
    PropNameRegister.RegisterNames(Register)
    DeclarePropertyToBeChecked()
end

Init()

return PropName