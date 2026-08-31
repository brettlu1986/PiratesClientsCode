-- LoginPacketProcessor和TutorialPacketProcessor的基类
local luaclass = require("luaclass")
local NetMessageProcessorBase = require("NetMessageProcessorBase")
local CreatePlayerPacketProcessor = luaclass("CreatePlayerPacketProcessor", NetMessageProcessorBase)

local ClientEventDef = require("ClientEventDef")
local EventManager = require("EventManager")
-- local ProcedureManager = require("ProcedureManager")
local ProcedureTool = require("ProcedureTool")
local NetworkManager = dynamic_require("NetworkManager")
local Proto = require("ClientProtoNames")
-- local UIUtils = require("UIUtils")
local GlobalVariableSystem = require("GlobalVariableSystem_C")
local GameObjectSystem = require("GameObjectSystem_C")
-- local UITextDef = require("UITextDef")
local GamePlayerSelfHelper = require("GamePlayerSelfHelper")

CreatePlayerPacketProcessor.tbPlayerDataPacket = nil


function CreatePlayerPacketProcessor:Init()
    log("CreatePlayerPacketProcessor:Init")
    CreatePlayerPacketProcessor.super.Init(self)
    return true
end

function CreatePlayerPacketProcessor:Uninit()
    log("CreatePlayerPacketProcessor:Uninit")
    self.tbPlayerDataPacket = nil
    CreatePlayerPacketProcessor.super.Uninit(self)
end

function CreatePlayerPacketProcessor:RegisterPackets()
    self:BindMethod(Proto.s2c_PlayerData, self, self.OnRecvPlayerData)
    -- self:BindMethod(Proto.s2c_EnterWorld, self, self.OnRecvEnterWorld)
    self:BindMethod(Proto.s2c_WaitingDungeon, self, self.OnWaitingDungeon)
    -- self:BindMethod(Proto.s2c_EnterLocalDungeon, self, self.OnEnterLocalDungeon)
    -- self:BindMethod(Proto.s2c_EnterGameError, self, self.OnEnterGameError)

end

local function SendDeviceInfo()
    local nDeviceLevel = RenderExtendBlueprintFunctions.GetDevicePerformanceLevel()
    local szDeviceMake = RenderExtendBlueprintFunctions.GetDeviceMake()
    local szDeviceModel = RenderExtendBlueprintFunctions.GetDeviceModel()
    local szOsVersion   = RenderExtendBlueprintFunctions.GetOSVersion()
    local szClientAppVersion = GlobalVariableSystem:GetAppVersion()
    local szClientResVersion = GlobalVariableSystem:GetResVersion()
    log("DeviceInfo: nDeviceLevel " .. nDeviceLevel .. " szDeviceMake " .. szDeviceMake.. " szDeviceModel " .. szDeviceModel .. " OSVersion " .. szOsVersion .. " ClientAppVersion " .. szClientAppVersion .. " ClientResVersion " .. szClientResVersion)
    local tbParams = {}
    tbParams.brand = szDeviceMake
    tbParams.model = szDeviceModel
    tbParams.performance_level = nDeviceLevel
    tbParams.os_version = szOsVersion
    tbParams.client_app_version = szClientAppVersion
    tbParams.client_res_version = szClientResVersion
    NetworkManager:GetHubServerProxy():SendPacket(Proto.c2s_DeviceInfo, tbParams)
end

function CreatePlayerPacketProcessor:OnRecvPlayerData(tbPacket)
    GlobalVariableSystem:SetWithLobby(true)
    GamePlayerSelfHelper:SetEnableSaveComponents(false)
    GameObjectSystem:DestroyAll()
    GamePlayerSelfHelper:SetEnableSaveComponents(true)

    local nPlayerId = tbPacket.player_id or 0
    local szAddress = EngineExtActorShell.GetLocalHostAddress() or ""
    local szName = tbPacket.name or "blankname"
    log(string.format("CreatePlayerPacketProcessor:OnRecvPlayerData, name = %s, player_id = %d, ip = %s", szName, nPlayerId, szAddress))
    tbPacket.nPlayerId = nPlayerId
    self.tbPlayerDataPacket = tbPacket
    GlobalVariableSystem.nSelfLobbyPlayerId = nPlayerId
    --local tbSceneData = tbPacket.data.scene

    -- local tbCurrentServerData = GlobalVariableSystem.tbCurrentServerData
    -- local pChannelSdkManager = GlobalVariableSystem:GetChannelSdkManager()
	-- pChannelSdkManager:SetRoleIdAndName(tostring(nPlayerId), tbPacket.name)
    --世游版本暂时不统计
    --pChannelSdkManager:SetRoleLevel(tostring(tbPacket.data.basic.level))
    -- pChannelSdkManager:SetServerIDAndName(tbCurrentServerData.id, tbCurrentServerData.name)
    -- pChannelSdkManager:OnEnterGame()
    BuglyCrashReportBPLibrary.SetUserIdentifier(tbPacket.name)

    SendDeviceInfo()
    -- 在这里并不创建Actor，等切到wildprocedure才创建actor，这里只是创出个壳
    -- 因为未来在这里可能直接进入战斗，也可能进入野外，如何创建actor取决于具体的业务流程，所以这里只创建个壳

    local bDungeon = GlobalVariableSystem:IsInDungeon()
    GlobalVariableSystem:SetInDungeon(false)
    GameObjectSystem:CreatePlayerSelfWithHubLoginData(tbPacket)
    GlobalVariableSystem:SetInDungeon(bDungeon)

    EventManager:OnFireEvent(ClientEventDef.EV_PLAYERDATA_SYNC, tbPacket)

    -- 切Procedure
    -- if(not tbPacket.is_client_enter_dungeon) then
    --     ProcedureTool:EnterWildWorld(tbSceneData.scene_id, "OnRecvPlayerData",
    --         tbPacket.actor_id, tbSceneData.transform, true, tbPacket)
    -- end
end

-- function CreatePlayerPacketProcessor:OnRecvEnterWorld(tbPacket)
--     -- ProcedureTool:EnterWildWorld(tbPacket.scene_id, "OnRecvEnterWildWorld",
--     --     tbPacket.actor_id, tbPacket.transform, true, nil)

--     ProcedureManager:ActiveProcedure(ProcedureManager.Procedure_Lobby, self.tbPlayerDataPacket)
-- end

-- function CreatePlayerPacketProcessor:OnEnterLocalDungeon(tbPacket)
--     -- local WndCreateRole = UIManager:GetWnd(UIDef.UI_CREATE_ROLE)
--     -- if WndCreateRole then
--     --     ProcedureManager:ActiveProcedure(ProcedureManager.Procedure_NewPlayer,tbPacket)
--     -- else
--     ProcedureTool:EnterLocalDungeon(0, GlobalVariableSystem.nSelfLobbyPlayerId, tbPacket.dungeon_id)
--     -- end
-- end
-- function CreatePlayerPacketProcessor:OnEnterGameError(tbPacket)
--     local nRetCode = tbPacket.return_code
--     if nRetCode == Proto.ReturnCode.INVALID_REQUEST then
--         UIUtils.ShowToast(UITextDef.INVALID_REQUEST)
--     elseif nRetCode == Proto.ReturnCode.SERVER_ERROR then
--         UIUtils.ShowToast(UITextDef.SERVER_ERROR)
--     end

--     EventManager:OnFireEvent(ClientEventDef.EV_ON_ENTER_GAME_ERROR)
-- end

-- 登录后有可能直接进副本，这里单独写了一套副本进入流程
function CreatePlayerPacketProcessor:OnWaitingDungeon(tbPacket)
    local tbParam = {}
    tbParam.nDungeonId = tbPacket.dungeon_template_id
    tbParam.bStandalone = false
    if ProcedureTool:EnterDungeon(tbParam) then
        EventManager:OnFireEvent(ClientEventDef.EV_ON_WAITING_DUNGEON)
    else
        log("CreatePlayerPacketProcessor:OnWaitingDungeon failed disconnect")
    end
end

return CreatePlayerPacketProcessor
