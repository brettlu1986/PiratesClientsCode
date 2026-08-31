local luaclass = require("luaclass")
local SyncDataBase = require("SyncDataBase")
local SyncDataPlayerBaseState = luaclass("SyncDataPlayerBaseState", SyncDataBase)
local SyncDataUtils = require("SyncDataUtils")
local ShipItemHelper = require("ShipItemHelper")
local BotAISystem = dynamic_require("BotAISystem")

SyncDataPlayerBaseState.tbPlayerState = nil

-- luacheck: push ignore
local function LOG(...)
    log("CJ->SyncDataPlayerBaseState:", ...)
end
-- luacheck: pop


function SyncDataPlayerBaseState:OnSync(tbPack)
    local tbOwner = self.tbOwner
    local nServerInstanceId = tbOwner.nServerInstanceId
    local bRealPlayer = not BotAISystem:IsBot(tbOwner)
    SyncDataUtils:FillPlayerState(tbOwner, self.tbPlayerState, nServerInstanceId, bRealPlayer)
    tbPack.state = self.tbPlayerState
    tbPack.is_real_player = bRealPlayer
    if tbOwner:IsHuman() and not bRealPlayer then
        tbPack.ship_stat_cache = tbPack.ship_stat_cache or {}
        tbPack.ship_stat_cache.ship_template_id = ShipItemHelper.GetCurrentShipItemTemplateId(nServerInstanceId, false)
    end
end


function SyncDataPlayerBaseState:OnStart()
    self.tbPlayerState = {}

end


function SyncDataPlayerBaseState:OnStop()

end



return SyncDataPlayerBaseState