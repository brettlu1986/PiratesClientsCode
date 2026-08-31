-----------------------------------------------------
--File Name    : PropertyWrapperPool.lua
--Author       : Song Fuhao
--Create Time  : 2020-10-21
--Description  :
-----------------------------------------------------
local PropertyWrapperPool = {}

local PropertyWrapper = require("PropertyWrapperNew")

local tbContainer = {}

local function LOG(...)
    -- logdebug("[PropertyWrapperPool]", ...)
end

function PropertyWrapperPool.Accquire(nPropId, nValueType, varOriginValue)
    local Property = nil
    local nLastIndex = #tbContainer
    if nLastIndex > 0 then
        Property = tbContainer[nLastIndex]
        tbContainer[nLastIndex] = nil
        LOG("Accquire property, use cache, Pool num :", #tbContainer)
    else
        Property = PropertyWrapper()
        LOG("Accquire property, create new.")
    end
    Property:Init(nPropId, nValueType, varOriginValue)
    return Property
end

function PropertyWrapperPool.Release(Property)
    if not Property then
        return
    end
    Property:ReturnToPool()
    table.insert(tbContainer, Property)
    LOG("Release property, Pool num :", #tbContainer)
end

return PropertyWrapperPool