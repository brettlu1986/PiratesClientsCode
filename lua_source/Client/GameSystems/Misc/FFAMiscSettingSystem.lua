local FFAMiscSettingSystem = {}

local EventManager      = require("EventManager")
local ClientEventDef    = require("ClientEventDef")
local ProtoDR           = require("DungeonRepProtoNames")

local DungeonIni        = require("DungeonIni")
local SoundManager      = require("SoundManager")

local WAITING_STAGE_DRAW_DISTANCE = 7500
local GAMING_STAGE_DRAW_DISTANCE = 30000
local CMD_DRAW_DISTANCE = "pir.CharacterDrawDis %d"

local function SetDrawDistance(nValue)
    RenderExtendBlueprintFunctions.ExecuteCommand(string.format(CMD_DRAW_DISTANCE, nValue))
    ExtendBlueprintFunctions.ResetCharacterSkeletalDrawDistance(GWorld)
end

local function EnableFFABGM(bEnable)
    if bEnable then
        local nBGMId = DungeonIni.tbFFA.nBGMId
        SoundManager:PlayBackgroundMusic(nBGMId)
    else
        SoundManager:StopBackgroundMusic()
    end
end

local function OnBattleWaitStageStateChanged(self, tbPacket)
    local bWaitStage = tbPacket.bWaitStage
    local nValue
    if bWaitStage then
        nValue = WAITING_STAGE_DRAW_DISTANCE
    else
        nValue = GAMING_STAGE_DRAW_DISTANCE
    end
    SetDrawDistance(nValue)

    EnableFFABGM(bWaitStage)
end

local function OnFFAProcessStateChanged(self, nState, bBattle, nTime)
    if nState == ProtoDR.rFFAProcessState_EState.PARACHUTING then
        SetDrawDistance(GAMING_STAGE_DRAW_DISTANCE)
    end
end


function FFAMiscSettingSystem:Init()
    EventManager:BindEventMethod(ClientEventDef.EV_BATTLE_WAIT_STAGE_STATE_CHANGED, self, OnBattleWaitStageStateChanged)
    EventManager:BindEventMethod(ClientEventDef.EV_FFA_PROCESS_STATE_CHANGED, self, OnFFAProcessStateChanged)

    return true
end

function FFAMiscSettingSystem:Uninit()
    EventManager:UnBindEventMethod(ClientEventDef.EV_BATTLE_WAIT_STAGE_STATE_CHANGED, self, OnBattleWaitStageStateChanged)
    EventManager:UnBindEventMethod(ClientEventDef.EV_FFA_PROCESS_STATE_CHANGED, self, OnFFAProcessStateChanged)
end
return FFAMiscSettingSystem