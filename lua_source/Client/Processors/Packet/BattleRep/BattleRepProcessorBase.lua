local luaclass = require("luaclass")
local NetMessageProcessorBase = require("NetMessageProcessorBase")
local BattleRepProcessorBase = luaclass("BattleRepProcessorBase", NetMessageProcessorBase)

local NetworkManager = dynamic_require("NetworkManager")
local BattleGameModeSystem = dynamic_require("BattleGameModeSystem")
local GlobalVariableSystem = require("GlobalVariableSystem_C")

BattleRepProcessorBase.bServer = false

function BattleRepProcessorBase:BindRep(szProtoName, fnFunc, bSaveToGameState)    
    local fnCallback = fnFunc
    if(not self.bServer and (bSaveToGameState == nil or bSaveToGameState == true)) then
        fnCallback = function(_self, tbPacket)
            if(not _self.bServer) then
                local tbGameState = BattleGameModeSystem:GetGameState()
                tbGameState[szProtoName] = tbPacket
            end
            if(fnFunc) then
                fnFunc(_self, tbPacket)
            end
        end
    end

    self:BindMethod(szProtoName, self, fnCallback)
end

-- 注册处理包
function BattleRepProcessorBase:RegisterPackets()
end

-- 初始化
function BattleRepProcessorBase:Init()
    BattleRepProcessorBase.super.Init(self)

    self.bServer = GlobalVariableSystem:IsStandaloneServer()
    self:SetBinder(NetworkManager:GetRPCNetworkProxy())
    self:RegisterPackets()
    return true
end

return BattleRepProcessorBase
