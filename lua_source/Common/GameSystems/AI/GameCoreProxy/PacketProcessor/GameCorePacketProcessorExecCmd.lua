local luaclass = require("luaclass")
local GameCorePacketProcessorBase = require("GameCorePacketProcessorBase")
local GameCorePacketProcessorExecCmd = luaclass("GameCorePacketProcessorExecCmd", GameCorePacketProcessorBase)

-- luacheck: push ignore
local function LOG(...)
    log("CJ->GameCorePacketProcessorExecCmd:", ...)
end
-- luacheck: pop

local CommandFuncs = {}

local function RegisterCmd(szCmd, func)
    CommandFuncs[szCmd] = func
end

local function ToggleAIShipVisibilityEnable(tbParams)
    local bEnabled = tonumber(tbParams[2] or 0) > 0
	local pGameInstance = GameplayStatics.GetGameInstance(GWorld)
    if pGameInstance and pGameInstance.GlobalSettings then
        LOG("old ai ship visibility:", pGameInstance.GlobalSettings.AIUseShipVisibility)
        pGameInstance.GlobalSettings.AIUseShipVisibility = bEnabled
        LOG("toggle ai ship visibility:", bEnabled)
    end
end

function GameCorePacketProcessorExecCmd:Init()
    GameCorePacketProcessorExecCmd.super.Init(self)
    RegisterCmd("toggle_ai_ship_visibility_enable", ToggleAIShipVisibilityEnable)
end

function GameCorePacketProcessorExecCmd:Process(tbPacket)
    local szCmd = tbPacket.cmd
    local StringUtil = require("StringUtil")
    local tbParams = StringUtil.Split(szCmd, " ")
    if tbParams then
        local CommandFunc = CommandFuncs[tbParams[1]]
        if CommandFunc then
            CommandFunc(tbParams)
        else
            LOG("use command not found:", tbParams[1])
        end
    end
end


return GameCorePacketProcessorExecCmd