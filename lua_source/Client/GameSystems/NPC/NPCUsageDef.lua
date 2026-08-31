--[[
    用法：
    直接使用NPCUsageDef.ShipBuild 
    类似enum
]]

local NPCUsageDef = {}

-- local Proto = require("ClientProtoNames")

NPCUsageDef.ProcessType = {}
NPCUsageDef.ProcessType.UI = 1
NPCUsageDef.ProcessType.Server = 2

-- local nMaxIndex = 0

-- local Define = function(szType, nProcessType)
--     local tbInfo = {}
--     local nNewIndex = 1<<nMaxIndex
--     NPCUsageDef[szType] = nNewIndex
--     NPCUsageDef.ProcessType[nNewIndex] = tbInfo
--     tbInfo.nProcessType = nProcessType
--     nMaxIndex = nMaxIndex + 1
--     assert(nMaxIndex < 32)
--     return tbInfo
-- end

-- local DefineUIUsage = function(szKey, nUITypeId)
--     local tbInfo = Define(szKey, NPCUsageDef.ProcessType.UI)
--     tbInfo.nUIId = nUITypeId
-- end

-- local DefineServerUsage = function(szKey, nServerUsage)
--     local tbInfo = Define(szKey, NPCUsageDef.ProcessType.Server)
--     tbInfo.nUsage = nServerUsage
-- end

-- local DefineAllUsages = function()
--     -- npc_ui
--     DefineUIUsage("ShipBuild", 1)
--     DefineUIUsage("ShipEnhance", 2)
--     DefineUIUsage("MaterialShop", 3)
--     DefineUIUsage("LeavePort", 4)
--     DefineUIUsage("Trade", 5)
--     DefineUIUsage("RedeemShip", 6)
--     DefineUIUsage("WorkShop", 7)
--     -- DefineUIUsage("PricingList", 8)
--     DefineUIUsage("ShipAccessoryBuild", 9)

--     -- server
--     DefineServerUsage("Gather", Proto.s2c_AddNpcInfo_NpcUsageType.GATHER)
-- end

-- DefineAllUsages()

return NPCUsageDef