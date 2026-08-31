local luaclass = require("luaclass")
local GOCustomDataHelperClass = require("GOCustomDataHelper")
local GOCustomDataHelper_C = luaclass("GOCustomDataHelper_C", GOCustomDataHelperClass)

local GameComponentDataParser = require("GameComponentDataParser_C")

-- 公海进入时
function GOCustomDataHelper_C:ParsePlayerSelfHubData(nTemplateType, tbProtoData)
    local tbData = {}
    tbData.tbComponentData = GameComponentDataParser:ParsePlayerSelfHubData(nTemplateType, tbProtoData)
    return tbData
end

-- 客户端联网副本进入时
function GOCustomDataHelper_C:ParsePlayerReplicatedData(pUEActor, tbInitProtoData)
    local tbData = {}
    tbData.tbComponentData = GameComponentDataParser:ParsePlayerReplicatedData(pUEActor, tbInitProtoData)
    return tbData
end

----------------------------------------------------------------------------------
-- Npc
-- 公海进入时
function GOCustomDataHelper_C:ParseNpcHubData(tbProtoData)
    local tbData = {}
    tbData.tbComponentData = GameComponentDataParser:ParseNpcHubData(tbProtoData)
    return tbData
end

-- 客户端联网副本进入时
function GOCustomDataHelper_C:ParseNpcReplicatedData(pUEActor, tbInitProtoData)
    local tbData = {}
    tbData.tbComponentData = GameComponentDataParser:ParseNpcReplicatedData(pUEActor, tbInitProtoData)
    return tbData
end


----------------------------------------------------------------------------------
-- PlayerOther
-- 公海
function GOCustomDataHelper_C:ParsePlayerOtherHubData(tbProtoData)
    local tbData = {}
    tbData.tbComponentData = GameComponentDataParser:ParsePlayerOtherHubData(tbProtoData)
    return tbData
end

----------------------------------------------------------------------------------
-- Trigger
function GOCustomDataHelper_C:ParseTriggerHubData(tbProtoData)   
    return nil
end

function GOCustomDataHelper_C:ParseTriggerReplicatedData(pUEActor, tbInitProtoData)
    local tbData = {}
    tbData.tbComponentData = GameComponentDataParser:ParseTriggerReplicatedData(tbInitProtoData)
    return tbData
end

-----------------------------------------------------------------------------------
-- Dummy
function GOCustomDataHelper_C:ParseDummyHubData(tbProtoData)   
    return nil
end

function GOCustomDataHelper_C:ParseDummyReplicatedData(pUEActor, tbInitProtoData)
    return nil
end

-----------------------------------------------------------------------------------
-- Destructible object
function GOCustomDataHelper_C:ParseDestructibleObjectReplicatedData(pUEActor, tbInitProtoData)
    local tbData = {}
    tbData.tbComponentData = GameComponentDataParser:ParseDestructibleObjectReplicatedData(tbInitProtoData)
    return tbData
end

return GOCustomDataHelper_C
