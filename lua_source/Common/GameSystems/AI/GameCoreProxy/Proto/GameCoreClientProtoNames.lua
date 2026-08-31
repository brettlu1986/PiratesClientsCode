local Proto = {}

---------------------------------------------
-- export from src\client.proto begin

-- Message definitions for network packets for the game
-- Note: Follow the style guide when writing message definitions:
-- https://developers.google.com/protocol-buffers/docs/style





-- Workaround for linking FileDescriptor static initializer
Proto._LinkerWorkaround_ = "_LinkerWorkaround_"


Proto.AttachmentState = "AttachmentState"

Proto.WeaponParams = "WeaponParams"

Proto.WeaponState = "WeaponState"

Proto.EquipmentState = "EquipmentState"


Proto.Vector = "Vector"

Proto.HumanKeyPosition = "HumanKeyPosition"


Proto.HumanExtentState = "HumanExtentState"

Proto.ShipKeyPosition = "ShipKeyPosition"

Proto.ShipExtentState = "ShipExtentState"

Proto.PlayerState = "PlayerState"

Proto.VisibleItemState = "VisibleItemState"

Proto.VisiblePlayerState = "VisiblePlayerState"

Proto.VisibleVehicleState = "VisibleVehicleState"

Proto.VehicleState = "VehicleState"

Proto.CameraState = "CameraState"

Proto.PoisonCircleState = "PoisonCircleState"

Proto.BackpackItem = "BackpackItem"


Proto.Backpack = "Backpack"

Proto.HeardSound = "HeardSound"

Proto.CanBuildItemsList = "CanBuildItemsList"

Proto.BuildList = "BuildList"

Proto.EquipmentItem = "EquipmentItem"

Proto.HumanStatCache = "HumanStatCache"

Proto.ShipStatCache = "ShipStatCache"

Proto.PackageItem = "PackageItem"

Proto.ThrownWeaponState = "ThrownWeaponState"

Proto.ShipMovementState = "ShipMovementState"

Proto.TookDamage = "TookDamage"

Proto.TorpedoState = "TorpedoState"

Proto.SmokeState = "SmokeState"

Proto.DamageRegion = "DamageRegion"

Proto.MakeDamage = "MakeDamage"

Proto.BotState = "BotState"


Proto.c2s_syncBot = "c2s_syncBot"


Proto.ActionType = {
    None = 0,
    Fire = 1,
    Crouch = 2,
    Jump = 3,
    Crawl = 4,
    Pick = 5,
    Focus = 6,
    Move = 7,
    Stand = 8,
    SwitchWeapon = 9,
    Run = 10,
    ConsumeItem = 11,
    DropItem = 12,
    Reload = 13,
    DirectMove = 14,
    JumpWall = 15,
    BuildItem = 16,
    Rescue = 17,
    JoyStick = 18,
    ChangeDisplay = 19,
    StopAttack = 20,
    SwitchCarronadeEffect = 21,
    Teleport = 22,
    SwitchDoor = 23,
    EquipItem = 24,
    UnequipItem = 25,
}
Proto.c2s_actionValid = "c2s_actionValid"

Proto.c2s_gameFinish = "c2s_gameFinish"

Proto.c2s_linetrace = "c2s_linetrace"

Proto.c2s_welcome = "c2s_welcome"

Proto.c2s_notifyBotDead = "c2s_notifyBotDead"

Proto.c2s_ping = "c2s_ping"


Proto.c2s_fps = "c2s_fps"

Proto.FFAPlayerResult = "FFAPlayerResult"

Proto.c2s_notifyStatisticsData = "c2s_notifyStatisticsData"

-- export from src\client.proto end
---------------------------------------------



---------------------------------------------
-- export from src\ccs_sdk\ccs_agent_api.proto begin




Proto.OperationResultCode = {
    E_RESULT_OK = 0,
    E_RESULT_TIMEOUT = 1, -- timeout.
    E_RESULT_DUPLICATED_REQUEST = 2, -- duplicated request.
    E_RESULT_NO_SUCH_GAME = 3, -- on such game.
    E_RESULT_GAME_STOPPED = 4, -- game is stopped.
    E_RESULT_PARSE_STATE_ERROR = 5, -- parse state info error.
    E_RESULT_OVERLOAD = 6, -- ai server overload.

    -- TODO: add other error here.
    E_RESULT_ERROR = 99, -- common error.
}

Proto.AgentStyle = {
    E_STYLE_NONE = 0, -- none style, use random choice.
    E_STYLE_BALANCED = 1, -- balanced style.
    E_STYLE_CONSERVATIVE = 2, -- conservative style.
    E_STYLE_AGGRESSIVE = 3, -- aggressive style.
}

-- base data sturcture.
Proto.OperationResult = "OperationResult"

Proto.AgentConfig = "AgentConfig"

-- request and response structure for each operation.
Proto.GameStartRequest = "GameStartRequest"


Proto.GameStartResponse = "GameStartResponse"

Proto.GameStopRequest = "GameStopRequest"

Proto.GameStopResponse = "GameStopResponse"

Proto.AgentCreateRequest = "AgentCreateRequest"

Proto.AgentCreateResponse = "AgentCreateResponse"

Proto.AgentDestroyRequest = "AgentDestroyRequest"

Proto.AgentDestroyResponse = "AgentDestroyResponse"


-- export from src\ccs_sdk\ccs_agent_api.proto end
---------------------------------------------

return Proto