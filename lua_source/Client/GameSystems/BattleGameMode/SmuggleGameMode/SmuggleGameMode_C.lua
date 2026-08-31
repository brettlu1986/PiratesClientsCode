local luaclass = require("luaclass")

local SmuggleGameModeClass = require("SmuggleGameMode")
local SmuggleGameMode_C = luaclass("SmuggleGameMode_C", SmuggleGameModeClass)

local Proto = require("ClientProtoNames")
local EventManager = require("EventManager")
local ClientEventDef = require("ClientEventDef")
local UIDef = require("UIDef")
-- local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
local NetworkManager = dynamic_require("NetworkManager")

local function SendPacket(szProto, tbPacket)
    local Socket = NetworkManager:GetHubServerProxy()
    return Socket:SendPacket(szProto, tbPacket)
end

local function OnUIOpen( szWndName )
    if szWndName == UIDef.UI_BATTLE_MAIN then
        EventManager:OnFireEvent(ClientEventDef.EV_UI_ATTACK_VISIBLE, false)
        -- local tbPlayerSelf = GamePlayerSelfHelper:Get()

        -- local CameraControlManager = GameplayStatics.GetPlayerCameraManager(GWorld, 0)
        -- CameraControlManager.CurrentActiveModeComponent:SwitchMode(Enum_CameraType.BattleSmuggle, false)
        -- tbPlayerSelf.BattleStatusComponent.PropertyWrapperHelper:Overlap_Override("bWeaponEnabled", false)
    end
end

function SmuggleGameMode_C:Init(nSubDungonId, pGameMode, tbGameState, tbJsonTableFile)
    SmuggleGameMode_C.super.Init(self, nSubDungonId, pGameMode, tbGameState, tbJsonTableFile)
    EventManager:BindEvent(ClientEventDef.EV_OPEN_UI, OnUIOpen)
    return true
end

function SmuggleGameMode_C:Uninit()
    EventManager:UnBindEvent(ClientEventDef.EV_OPEN_UI, OnUIOpen)
    SmuggleGameMode_C.super.Uninit(self)
end

function SmuggleGameMode_C:OnAllStepFinished()
    log("SmuggleGameMode_C:OnAllStepFinished")

    SendPacket(Proto.c2s_LeaveLocalDungeon)

    SmuggleGameMode_C.super.OnAllStepFinished()
end

return SmuggleGameMode_C
