local ProcedureTool = {}

local ProcedureManager     = require("ProcedureManager")
local DungeonDataTable     = require("DungeonDataTable")
local SceneResDataTable    = require("SceneResDataTable")
local DelayTimer           = require("DelayTimer")
local UEMapLoader          = require("UEMapLoader")
local ManagerRoot          = require("ManagerRoot")
local ManagerGroupDef      = require("ManagerGroupDef")
local NetworkManager       = dynamic_require("NetworkManager")
local GlobalVariableSystem = dynamic_require("GlobalVariableSystem")
local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
local PrepareLocalDungeonDataHelper = require("PrepareLocalDungeonDataHelper")
local ScreenCaptureHelper = require("ScreenCaptureHelper")
local TutorialDungeonIni    = require("TutorialDungeonIni")

function ProcedureTool:EnterStartGame(tbParam)
    ProcedureManager:ActiveProcedure(ProcedureManager.Procedure_StartGame, tbParam, nil)
end

function ProcedureTool:EnterMock(tbParam, bForce)
	ProcedureManager:ActiveProcedure(ProcedureManager.Procedure_Mock, tbParam, nil, bForce)
end

-- function ProcedureTool:EnterVersionCheck(tbParam, bForce)
--     ProcedureManager:ActiveProcedure(ProcedureManager.Procedure_VersionCheck, tbParam, bForce)
-- end

-- function ProcedureTool:EnterUpdate(tbParam, bForce)
--     ProcedureManager:ActiveProcedure(ProcedureManager.Procedure_Update, tbParam, bForce)
-- end

function ProcedureTool:ReturnToStartGame()
    if self.ReturnToStartGameTimer ~= nil then
        log("ProcedureTool:ReturnToStartGame returning")
        return
    end
    log("ProcedureTool:ReturnToStartGame", debug.traceback(  ))

    -- timer会使clienttravel在下一帧才执行，从而导致会有一帧的闪
    -- self.ReturnToStartGameTimer = DelayTimer:RunNextTick(function()
        --  self.ReturnToStartGameTimer = nil
        -- ProcedureManager:ActiveProcedure(ProcedureManager.Procedure_StartGame)
        -- if not EngineExtShell.IsEditor() and not PatchSettings.IsSkipPatch() then
        if not EngineExtShell.IsEditor() then
            log("ProcedureTool:ReturnToStartGame to launch")
            -- EventManager:OnFireEvent(ClientEventDef.EV_ENTER_LOADING)
            ProcedureManager:ActiveProcedure()
            ProcedureTool:UninitAllGroups()
            ManagerRoot:UninitAll()

            UEMapLoader:LoadMap("/Game/Maps/Map_Launch", true, "")
        else
            self:EnterStartGame()
            log("ProcedureTool:ReturnToStartGame to startGame")
        end
    -- end)
end

function ProcedureTool:ReturnToLogin()
    log("ProcedureTool:ReturnToLogin")
    if self.ReturnToLoginTimer ~= nil then
        return
    end
    self.ReturnToLoginTimer = DelayTimer:RunNextTick(function()
        self.ReturnToLoginTimer = nil
        ProcedureManager:ActiveProcedure(ProcedureManager.Procedure_StartGame)
        -- ProcedureManager:ActiveProcedure()
        -- UEMapLoader:LoadMap("/Game/Maps/Map_Launch", true, "")
    end)
end

local function IsConnectWithLobby()
    if not GlobalVariableSystem:IsWithLobby() then
        return true
    end
    if NetworkManager:GetHubServerProxy():IsConnect() then
        return true
    end

    return false
end

function ProcedureTool:EnterDungeon(tbEnterParam, tbLastProcedureEndParams, bForce)
    if not bForce and not IsConnectWithLobby() then
        log("ProcedureTool:EnterDungeon failed: disconnected", GlobalVariableSystem:IsWithLobby(), GWithEditor, debug.traceback())
        return false
    end

    ProcedureManager:ActiveProcedure(ProcedureManager.Procedure_Battle, tbEnterParam, tbLastProcedureEndParams, bForce)
    return true
end

function ProcedureTool:EnterLobby(tbParam, bForce)
    if not IsConnectWithLobby() then
        log("ProcedureTool:EnterLobby failed: disconnected", debug.traceback( ))
        return false
    end
    if GlobalVariableSystem.bEnterLobby3D then
        ProcedureManager:ActiveProcedure(ProcedureManager.Procedure_Lobby3D, tbParam, nil, bForce)
    else
        ProcedureManager:ActiveProcedure(ProcedureManager.Procedure_Lobby, tbParam, nil, bForce)
    end
    log("ProcedureTool:EnterLobby is 3dlobby ", GlobalVariableSystem.bEnterLobby3D)
    return true
end

function ProcedureTool:EnterHomeland(tbParam, bForce)
    if not IsConnectWithLobby() then
        log("ProcedureTool:EnterHomeland failed: disconnected", debug.traceback( ))
        return false
    end

    ProcedureManager:ActiveProcedure(ProcedureManager.Procedure_Homeland, tbParam, nil, bForce)
    return true
end

function ProcedureTool:EnterSelectRole(tbParam)
    if not IsConnectWithLobby() then
        log("ProcedureTool:EnterSelectRole failed: disconnected", debug.traceback( ))
        return false
    end

    ProcedureManager:ActiveProcedure(ProcedureManager.Procedure_SelectRole, tbParam)
    return true
end

function ProcedureTool:EnterCreateRole(tbParam)
    if not IsConnectWithLobby() then
        log("ProcedureTool:EnterCreateRole failed: disconnected", debug.traceback( ))
        return false
    end
    ProcedureManager:ActiveProcedure(ProcedureManager.Procedure_CreateRole, tbParam)
    return true
end

function ProcedureTool:EnterTutorialDungeon()
    local tbPrepareInfo = PrepareLocalDungeonDataHelper:PrepareTutorialDungeonData()
    local nFakePlayerId = tbPrepareInfo.nPlayerId
    if(GlobalVariableSystem.bQuickBattleLoading) then
        ScreenCaptureHelper.Capture(function(nWidth, nHeight, pShotTexture)
            local tbCustomParam = {}
            tbCustomParam.bQuickBattleLoading = true
            tbCustomParam.tbLoadingInfo = {
                pTexture = pShotTexture,
                nWidth = nWidth,
                nHeight = nHeight
            }
            ProcedureTool:EnterLocalDungeon(TutorialDungeonIni.nDungeonId, nFakePlayerId, tbCustomParam)
        end)
    else
        ProcedureTool:EnterLocalDungeon(TutorialDungeonIni.nDungeonId, nFakePlayerId)
    end
end

function ProcedureTool:EnterLocalDungeon(nDungeonId, nPlayerId, tbCustomParam)
    local tbDungeonData = DungeonDataTable:GetTemplate(nDungeonId)
    if(tbDungeonData == nil) then
        logerror(string.format("ProcedureTool:EnterLocalDungeon failed, cannot find dungeon template data, DungeonId: %d",
            nDungeonId))
        return false
    end

    local nDungeonMode = 0
    local nModeCount = #tbDungeonData.tbModes
    if nModeCount > 0 then
        nDungeonMode = tbDungeonData.tbModes[math.random(1, nModeCount)]
    end
    DungeonDataTable:SetMode(nDungeonId, nDungeonMode)

    local tbResData = SceneResDataTable:GetTemplate(tbDungeonData.nResID)
    if(tbResData == nil) then
        logerror(string.format("ProcedureTool:EnterLocalDungeon failed, cannot find scene res template data, DungeonId: %d, ResId: %d",
             nDungeonId, tbDungeonData.nResID))
        return false
    end

    local tbParam = {}
    tbParam.szTargetIp = tbResData.szPath
    tbParam.nToken = 0
    tbParam.nPlayerId = nPlayerId == nil and GamePlayerSelfHelper:Get().nPlayerId or nPlayerId
    tbParam.nDungeonId = nDungeonId
    tbParam.bStandalone = true
    if(tbCustomParam) then
        for k, v in pairs(tbCustomParam) do
            tbParam[k] = v
        end
    end

    return self:EnterDungeon(tbParam)
end

function ProcedureTool:ExitGame()
    log("ProcedureTool request exit game")
    local pGameInstance = GameplayStatics:GetGameInstance(GWorld)
    pGameInstance:AppExit()
end

function ProcedureTool:UninitAllGroups()
    ManagerRoot:UninitGroup(ManagerGroupDef.nBattleGroupID, true)
    ManagerRoot:UninitGroup(ManagerGroupDef.nHubGroupID, true)
    ManagerRoot:UninitGroup(ManagerGroupDef.nLobbyGroupID, true)
    ManagerRoot:UninitGroup(ManagerGroupDef.nHomelandGroupID, true)
    ManagerRoot:UninitGroup(ManagerGroupDef.nLoginGroupID, true)
    ManagerRoot:UninitGroup(ManagerGroupDef.nDefaultGroupID, true)
    ManagerRoot:UninitGroup(ManagerGroupDef.nImmortalGroupID, true)
end

return ProcedureTool