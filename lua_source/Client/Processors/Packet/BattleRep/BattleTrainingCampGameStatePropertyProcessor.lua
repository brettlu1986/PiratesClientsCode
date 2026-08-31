local luaclass = require("luaclass")
local BattleGameStatePropertyProcessorClass = require("BattleGameStatePropertyProcessor")
local BattleTrainingCampGameStatePropertyProcessor = luaclass("BattleTrainingCampGameStatePropertyProcessor", BattleGameStatePropertyProcessorClass)

local PropNameGameState = require("PropNameGameState")
local ClientEventDef = require("ClientEventDef")
local EventManager = require("EventManager")

local function LOG(...)
    log("[BattleTrainingCampGameStatePropertyProcessor] ", ...)
end

local function OnReleaseTimeStamp(self, nTimeStamp)
    LOG("OnGameStateTrainingCampReleaseTimeStamp: ", nTimeStamp)
    EventManager:OnFireEvent(ClientEventDef.EV_GAME_STATE_TRAININGCAMP_RELEASE_TIME_STAMP, nTimeStamp)
end

-- 注册处理包
function BattleTrainingCampGameStatePropertyProcessor:RegisterPackets()
    self:Bind(PropNameGameState.nTrainingCampReleaseTimeStamp, self, OnReleaseTimeStamp, true)
end

return BattleTrainingCampGameStatePropertyProcessor
