local luaclass = require("luaclass")
local BattlePrepareMockSystemClass = require("BattlePrepareMockSystem")
local BattlePrepareMockSystem_C = luaclass("BattlePrepareMockSystem_C", BattlePrepareMockSystemClass)

-- local ClientEventDef = require("ClientEventDef")
-- local GameObjectTypeDef = require("GameObjectTypeDef")
-- local GameObjectSystem = require("GameObjectSystem_C")
--local GamePlayerSelfHelper = require("GamePlayerSelfHelper")


-- local function TryMockClientPlayerData(tbInitProtoData)
--     local PlayerSelf = GamePlayerSelfHelper:Get()
--     if(PlayerSelf ~= nil and PlayerSelf.nPlayerId == 0) then
--         log("TryMockClientPlayerData", tbInitProtoData.player_id)

--         PlayerSelf.nTemplateId = tbInitProtoData.template_id
--         PlayerSelf.nPlayerId = tbInitProtoData.player_id
--         PlayerSelf.bCreateUEActor = false
--     end
-- end

function BattlePrepareMockSystem_C:Init()
    BattlePrepareMockSystem_C.super.Init(self)
    --self.SelfEventHelper:RegisterEventFunc(ClientEventDef.EV_TRY_MOCK_CLIENT_PLAYER_DATA, TryMockClientPlayerData)
    return true
end

function BattlePrepareMockSystem_C:Uninit()
    BattlePrepareMockSystem_C.super.Uninit(self)
end


return BattlePrepareMockSystem_C()
