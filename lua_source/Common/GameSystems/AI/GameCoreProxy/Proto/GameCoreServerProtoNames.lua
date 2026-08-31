local Proto = {}

---------------------------------------------
-- export from src\server.proto begin

-- Message definitions for network packets for the game
-- Note: Follow the style guide when writing message definitions:
-- https://developers.google.com/protocol-buffers/docs/style





Proto.s2c_hello = "s2c_hello"

Proto.s2c_addBot = "s2c_addBot"

Proto.s2c_addBTBot = "s2c_addBTBot"

Proto.s2c_fire = "s2c_fire"

Proto.s2c_move = "s2c_move"

Proto.s2c_focus = "s2c_focus"

Proto.s2c_pick = "s2c_pick"

Proto.s2c_crouch = "s2c_crouch"

Proto.s2c_jump = "s2c_jump"

Proto.s2c_crawl = "s2c_crawl"

Proto.s2c_stand = "s2c_stand"

Proto.Item = "Item"

Proto.s2c_addItem = "s2c_addItem"

Proto.s2c_switchWeapon = "s2c_switchWeapon"

Proto.s2c_spawnItem = "s2c_spawnItem"

Proto.s2c_setSyncInterval = "s2c_setSyncInterval"

Proto.s2c_run = "s2c_run"

Proto.s2c_consumeItem = "s2c_consumeItem"

Proto.s2c_dropItem = "s2c_dropItem"

Proto.s2c_setPoisonCircle = "s2c_setPoisonCircle"

Proto.s2c_resetDungeon = "s2c_resetDungeon"


Proto.s2c_gameSpeed = "s2c_gameSpeed"

Proto.s2c_reload = "s2c_reload"

Proto.s2c_directMove = "s2c_directMove"

Proto.s2c_linetrace = "s2c_linetrace"

Proto.s2c_jumpWall = "s2c_jumpWall"

Proto.s2c_buildItem = "s2c_buildItem"

Proto.s2c_rescue = "s2c_rescue"

Proto.s2c_joyStickInput = "s2c_joyStickInput"

Proto.s2c_teleport = "s2c_teleport"

Proto.s2c_changeDisplay = "s2c_changeDisplay"

Proto.s2c_stopMeleeAttack = "s2c_stopMeleeAttack"

Proto.s2c_switchCarronadeEffect = "s2c_switchCarronadeEffect"

Proto.SwitchDoorAction = {
    None = 0,
    Open = 1,
    Close = 2,
}

Proto.s2c_switchDoor = "s2c_switchDoor"

Proto.s2c_ping = "s2c_ping"

Proto.s2c_holdThrownWeapon = "s2c_holdThrownWeapon"

Proto.s2c_unholdThrownWeapon = "s2c_unholdThrownWeapon"

Proto.s2c_throwAttack = "s2c_throwAttack"

Proto.s2c_setShipPosture = "s2c_setShipPosture"

Proto.s2c_configSight = "s2c_configSight"

Proto.s2c_changeVehicleState = "s2c_changeVehicleState"

Proto.s2c_setAim = "s2c_setAim"

Proto.s2c_execCmd = "s2c_execCmd"

Proto.s2c_equipItem = "s2c_equipItem"

Proto.s2c_unequipItem = "s2c_unequipItem"

-- export from src\server.proto end
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