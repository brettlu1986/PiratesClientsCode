-----------------------------------------------------
--File Name    : HomelandExchangeSystem.lua
--Author       : zhiyuan
--Create Time  : 2019-05-09
--Description  : 家园兑换system
-----------------------------------------------------

local HomelandExchangeSystem = {}

local Proto = require("ClientProtoNames")
local NetworkManager = dynamic_require("NetworkManager")

-----------------------------------------logic local function---------------------------------------------


-----------------------------------------System Init UnInit---------------------------------------------

-- function HomelandExchangeSystem:Init()
-- end

-- function HomelandExchangeSystem:Uninit()
-- end

-- function HomelandExchangeSystem:OnEnterHomeland()
-- end

-- function HomelandExchangeSystem:OnLeaveHomeland()
-- end

-----------------------------------------给外部模块的调用接口---------------------------------------------

-- 请求建筑兑换
-- @param nExchangeId 兑换id
function HomelandExchangeSystem:RequestBuildingExchange(nExchangeId)
    local c2s_ExchangeBuilding =
    {
        exchange_id = nExchangeId
    }
    NetworkManager:GetHubServerProxy():SendPacket(Proto.c2s_ExchangeBuilding, c2s_ExchangeBuilding)
end

return HomelandExchangeSystem