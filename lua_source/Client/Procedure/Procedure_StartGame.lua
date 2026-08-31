local luaclass = require("luaclass")
local ProcedureBase = require("ProcedureBase")
local Procedure_StartGame = luaclass("Procedure_StartGame", ProcedureBase)

local ManagerRoot = require("ManagerRoot")
local ManagerGroupDef = require("ManagerGroupDef")
local ProcedureManager = require("ProcedureManager")
-- local HandlerManagerHelper = require("HandlerManagerHelper")
local StringUtil = require("StringUtil")

--local bForceUpdate = true

-- 播放启动logo等动画
-- local function PlayIntroMovie(self)
--     -- TODO..

--     -- 播完后进游戏
--     self:Complete(ProcedureManager.Procedure_VersionCheck)
-- end

-- 正常启动
local function NormalStart(self)
    -- log("Procedure_StartGame version test 1.0.104")

    -- if not PatchSettings.IsSkipPatch() then
    --     HandlerManagerHelper:Uninit()
    -- end

    --if(not bForceUpdate) then
        -- Debug模式
        log("Procedure_StartGame no update mode")
        self:Complete(ProcedureManager.Procedure_PreLogin)
    -- elseif(GameplayStatics.GetGameInstance(GWorld):IsGameRestarting()) then
    --     -- 更新完后直接进入serverlist
    --     log("Procedure_StartGame restarted, enter server list")
    --     self:Complete(ProcedureManager.Procedure_ServerList)
    -- elseif(not ClientShell.HasAppStarted()) then
    --     -- 第一次启动，播启动动画
    --     log("Procedure_StartGame PlayIntroMovie")
    --     PlayIntroMovie(self)
    -- else
    --     -- 非第一次启动，有可能是退出游戏等原因导致的重启，这里直接进入versioncheck
    --     log("Procedure_StartGame enter version check")
    --     self:Complete(ProcedureManager.Procedure_VersionCheck)
    --end
end

function Procedure_StartGame:Begin()
    Procedure_StartGame.super.Begin(self)
    -- 只有nImmortalGroupID组不uninit
    ManagerRoot:UninitGroup(ManagerGroupDef.nBattleGroupID, true)
    ManagerRoot:UninitGroup(ManagerGroupDef.nHubGroupID, true)
    ManagerRoot:UninitGroup(ManagerGroupDef.nLobbyGroupID, true)
    ManagerRoot:UninitGroup(ManagerGroupDef.nDefaultGroupID, true)
    ManagerRoot:UninitGroup(ManagerGroupDef.nLoginGroupID, true)

    local szCmdLineStr = KismetSystemLibrary.GetCommandLine()
    local tbCmdArgs = StringUtil.Split(szCmdLineStr, ' ')
    for i=1,#tbCmdArgs do
        if tbCmdArgs[i] == "-autoconnect" then
            log("Enter auto connect mode...")
            self:Complete(ProcedureManager.Procedure_Mock, { bAutoConnect = true })
            return
        end
    end

    local pGameMode = GameplayStatics.GetGameMode(GWorld)
    if GWithEditor and pGameMode then
        if(pGameMode.ParseInitOptions == nil) then
            -- 非BP_GameMode
            local szGameModeName = KismetSystemLibrary.GetDisplayName(GameplayStatics.GetObjectClass(pGameMode))
            if ((szGameModeName == "LoginGameMode_C") or (szGameModeName == "GameMode")) then
                log("Start with editor. Not mock mode.")
                NormalStart(self)
            end
            return
        end

        local szMockOption = pGameMode:ParseInitOptions("AutoMock")
        local nMockId = tonumber(szMockOption)
        if nMockId and (nMockId > 0) then
            self:Complete(ProcedureManager.Procedure_Mock, { nMockId = nMockId })
        else
            NormalStart(self)
        end
    else
        NormalStart(self)
    end
end

function Procedure_StartGame:End()
    --ClientShell.MarkAppStarted()
    Procedure_StartGame.super.End(self)
end

return Procedure_StartGame
