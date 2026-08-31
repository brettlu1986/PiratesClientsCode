local luaclass = require("luaclass")
local ProcedureBase = require("ProcedureBase")
local Procedure_Mock = luaclass("Procedure_Mock", ProcedureBase)


local MockClientDataTable = require("MockClientDataTable")
local SelfEventHelperClass = require("SelfEventHelper")
local ShipDataTable = require("ShipDataTable")
local UIManager = require("UIManager")
local UIDef = require("UIDef")
local UEMapLoader = require("UEMapLoader")
local ManagerGroupDef = require("ManagerGroupDef")
local ProcedureTool = require("ProcedureTool")
local UEActorHelper = require("UEActorHelper")
local HumanDataTable = require("HumanDataTable")
local AvatarDataTable = require("AvatarDataTable")
--local PrepareLocalDungeonDataHelper = require("PrepareLocalDungeonDataHelper")
local BattlePrepareSystem = require("BattlePrepareSystem")
local BattlePlayerPrepareInfoMockData = require("BattlePlayerPrepareInfoMockData")

-- local HandlerManagerHelper = require("HandlerManagerHelper")
local GlobalVariableSystem = require("GlobalVariableSystem_C")
local EventManager = require("EventManager")
local ClientEventDef = require("ClientEventDef")
local StringUtil = require("StringUtil")
local TemplateTypeDef = require("TemplateTypeDef")
local DungeonDataTable = require("DungeonDataTable")

Procedure_Mock.tbEventHelper = nil

-- local szHandleManagerPath = "Blueprint'/Game/Game/Handler/BP_HandlerManager.BP_HandlerManager_C'"
local szGlobalSettingsPath = "Blueprint'/Game/Framework/Base/BP_GlobalSettings.BP_GlobalSettings_C'"

local function InitBPGameInstance( self )
    -- HandlerManagerHelper:Init(szHandleManagerPath:load())

    local pGameInstance = GameplayStatics.GetGameInstance(GWorld)
    if not pGameInstance.GlobalSettings then
        local pGlobalSettings = ExtendBlueprintFunctions.CreateObject(szGlobalSettingsPath:load(), pGameInstance)
        pGameInstance:InitGlobalSettings(pGlobalSettings)
        log("[GlobalSettings] GlobalSettings initialize in MockSystem.")
    else
        log("[GlobalSettings] GlobalSettings had initialized. Ignore it.")
    end
end

local function SpawnPawn(self, tbMockData, pLocaiton, pRotation)
    local pController = GameplayStatics.GetPlayerController(GWorld, 0)
    local szPawnClass, pPawn, nUniqueId
    if tbMockData.bIsShip then
        szPawnClass = ShipDataTable:GetResTemplate(tbMockData.nTemplateId).szPawnClassName
    else
        local humanId = AvatarDataTable:GetHumanId(tbMockData.nTemplateId)
        szPawnClass = HumanDataTable:GetResData(humanId).szPawnClassName
    end
    if szPawnClass ~= nil then
        nUniqueId, pPawn = UEActorHelper:CreateActor(szPawnClass, pLocaiton, pRotation)
        pController:Possess(pPawn)
    end

    if tbMockData.bIsShip then
        ClientShell.GetClient(GWorld):GetActorShell():InitMovement(pPawn, false, EGameActorMoveMode.E_HubShip, ShipMovementConfig())
        -- HandlerManagerHelper:SwitchMode(Enum_HandlerMode.ShipWildMode)
        UIManager:OpenWnd(UIDef.UI_MAIN, { nMapID = -1 })
        log("SpawnPawn..............................", nUniqueId)
    -- else
        -- HandlerManagerHelper:SwitchMode(Enum_HandlerMode.Player)
    end
end

local function SpawnPawnAtPlayerStart(self, tbMockData)
    local pGameMode = GameplayStatics.GetGameMode(GWorld)
    local pController = GameplayStatics.GetPlayerController(GWorld, 0)
    local pStartPoint = pGameMode:FindPlayerStart(pController, "")
    local pLocation = EngineExtActorShell.GetActorLocation(pStartPoint)
    local pRotation = EngineExtActorShell.GetActorRotation(pStartPoint)
    SpawnPawn(self, tbMockData, pLocation, pRotation)
end

local function SpawnPawnWhenPlayFromHere(self, tbMockData)
    local pLocation, pRotation = CommonShell.GetCommon(GWorld):GetPlayFromHereTransform()
    local pNewRot = Rotator()
    pNewRot.Yaw = pRotation.Yaw

    SpawnPawn(self, tbMockData, pLocation, pNewRot)
end

local function LoadMap(self, tbMockData)
    UEMapLoader:LoadMap(tbMockData.szUrl, true, "")
    local DelegateMgr = ClientShell.GetClient(GWorld):GetGameDelegateManager()
    self.tbEventHelper:RegisterCppDelegateFunc(DelegateMgr.Level.OnPostLoadMap, function()
        SpawnPawnAtPlayerStart(self, tbMockData)
    end)
end

local InitGameData = function(self)
    local ManagerRoot = require("ManagerRoot")
    InitBPGameInstance()
    ManagerRoot:InitGroup(ManagerGroupDef.nDefaultGroupID)
end

local function CreateMockPlayerSelf(bStandalone, nDungeonId)
    GlobalVariableSystem:SetInDungeon(true)
    GlobalVariableSystem:SetStandalone(bStandalone)

    local GameObjectSystem = require("GameObjectSystem_C")
    local GameObjectTypeDef = require("GameObjectTypeDef")
    -- local GOCreateDataHelper = dynamic_require("GOCreateDataHelper")
    -- local GOCustomDataHelper = dynamic_require("GOCustomDataHelper")

    local tbCreateData = nil
    local tbCustomData = nil

    local nPlayerId = GameDungeonShell.GenerateMockPlayerId()
    local nServerInstanceId = 9999999 --todo 应该使用GameObjectSystem:GenerateDungeonInstanceId函数
    if bStandalone then
        --todo 现在LoadTemplateInfo调用了两次，将来不用BattlePlayerPrepareInfoMockData来伪造PrepareData而是使用PrepareLocalDungeonDataHelper
        BattlePlayerPrepareInfoMockData:LoadTemplateInfo()
        local tbPrepareInfo = BattlePlayerPrepareInfoMockData:GetInstanceInfo(nPlayerId)
        local tbDungeonData = DungeonDataTable:GetTemplate(nDungeonId)
        tbPrepareInfo:SetInitItemsByGroupId(tbDungeonData.nInitItem)

        BattlePrepareSystem:AddPlayerPrepareInfo(tbPrepareInfo)
        return nil, nPlayerId

        -- local tbSpawnInfo = {}
        -- tbSpawnInfo.bCreateUEActor = false
        -- tbCreateData = GOCreateDataHelper:ParsePlayerSelfGameModeData(tbPrepareInfo, nServerInstanceId, tbSpawnInfo)
        -- tbCustomData = GOCustomDataHelper:ParsePlayerSelfGameModeData(tbPrepareInfo, tbSpawnInfo, tbCreateData.tbInitProtoData)
    else
        nServerInstanceId = 0
        tbCreateData = {}
        tbCreateData.bCreateComponents = true
        tbCreateData.bCreateUEActor = false
        tbCreateData.nTemplateId = -1
        tbCreateData.nServerInstanceId = nServerInstanceId
        tbCreateData.nPlayerId = nPlayerId
        log("CreateMockPlayerSelf", tbCreateData.nPlayerId)
        tbCreateData.nToken = 123456
        tbCreateData.nTemplateType = TemplateTypeDef.SHIP
    end

    local PlayerSelf = GameObjectSystem:Create(GameObjectTypeDef.PlayerSelf, tbCreateData, tbCustomData)
    PlayerSelf.nHubServerId = 999

    GlobalVariableSystem:SetInDungeon(false)
    GlobalVariableSystem:SetStandalone(bStandalone)
    return PlayerSelf, nPlayerId
end

local function TryToSetParamsFromCommandLine(self)
    local szCmdLineStr = KismetSystemLibrary.GetCommandLine()
	local tbCmdArgs = StringUtil.Split(szCmdLineStr, ' ')
	local szServerAddr = self.Param.szServerAddr
    local nDungeonId = self.Param.nDungeonId
    if szServerAddr == nil then
        for i=1,#tbCmdArgs do
            local szServerAddrKey = "serveraddr="
            if StringUtil.StartsWith(tbCmdArgs[i], szServerAddrKey) then
                szServerAddr = string.sub(tbCmdArgs[i], #szServerAddrKey + 1, #tbCmdArgs[i])
                self.Param.szServerAddr = szServerAddr
                break
            end
        end
    end
    if nDungeonId == nil then
        for i=1,#tbCmdArgs do
            local szDungeonIdKey = "dungeonid="
            if StringUtil.StartsWith(tbCmdArgs[i], szDungeonIdKey) then
                nDungeonId = tonumber(string.sub(tbCmdArgs[i], #szDungeonIdKey + 1, #tbCmdArgs[i]))
                self.Param.nDungeonId = nDungeonId
                break
            end
        end
    end
    log("Command line szTargetIp:", szServerAddr, "; DungeonId:", nDungeonId)
    printScreen("Command line szTargetIp:", szServerAddr, "; DungeonId:", nDungeonId)
end

local function CloseUpdateUI()
    -- 关闭update ui
    local GameInstance = GameplayStatics.GetGameInstance(GWorld)
    if(GameInstance) then
        local UpdateUI = GameInstance.UpdateUI
        if(UpdateUI) then
            log("Close UpdateUI...")
            UpdateUI:RemoveFromParent()
            GameInstance.UpdateUI = nil
        end
    end
end

function Procedure_Mock:Begin()
    Procedure_Mock.super.Begin(self)
    self.tbEventHelper = SelfEventHelperClass()
    GlobalVariableSystem:SetMockDeltaTime()
    InitGameData(self)
    KMInstancedSceneItemActor.SetMockMode()
    GlobalVariableSystem:SetDevMode(true)
    CloseUpdateUI()
    -- self.Param has higher priority than nMockId to set szTargetIp and nDungeonId
    TryToSetParamsFromCommandLine(self)
    local nDungeonId = self.Param.nDungeonId
    if nDungeonId == nil then
        local pGameMode = GameplayStatics.GetGameMode(GWorld)
        local szDungeonId = pGameMode:ParseInitOptions("DungeonId")
        nDungeonId = tonumber(szDungeonId)
    end
    local szServerAddr = self.Param.szServerAddr

    local tbMockData = MockClientDataTable:GetTemplate(self.Param.nMockId)
    if (tbMockData ~= nil or szServerAddr ~= nil) and nDungeonId ~= nil and nDungeonId > 0 then

        GlobalVariableSystem:SetWithLobby(false)

        local bPlayHere = ClientShell.GetClient(GWorld):IsPlayFromHereInEditor()
        if(bPlayHere and tbMockData ~= nil) then
            SpawnPawnWhenPlayFromHere(self, tbMockData)
            return
        end

        if nDungeonId ~= -1 then
            -- 直接进副本
            -- 这里得造个playerself，要不然后面流程会访问不到
            local bStandalone = self.Param.nMockId == 8
            local PlayerSelf, nPlayerId = CreateMockPlayerSelf(bStandalone, nDungeonId)
            local szTargetIp = szServerAddr
            if szTargetIp == nil and tbMockData ~= nil then
                szTargetIp = tbMockData.szUrl
            end
            if not bStandalone and szTargetIp ~= nil and string.len(szTargetIp) > 0 then
                local szPlayerName = self.Param.szPlayerName
                local tbParam = {}
                tbParam.szTargetIp = szTargetIp
                tbParam.nToken = PlayerSelf.nToken
                tbParam.nPlayerId = nPlayerId
                tbParam.nDungeonId = nDungeonId
                tbParam.szPlayerName = szPlayerName
                ProcedureTool:EnterDungeon(tbParam)
                EventManager:OnFireEvent(ClientEventDef.EV_ENTER_DUNGEON, szTargetIp, PlayerSelf.nToken, PlayerSelf.nPlayerId, nDungeonId, szPlayerName)
            else
                -- 重定义PrepareLocalDungeonData方法防止LocalDungeon重新计算进入副本的船只属性，会在Mock阶段BattlePlayerPrepareInfoMockData中做
                --[[
                PrepareLocalDungeonDataHelper.PrepareLocalDungeonData = function()
                    return {nPlayerId = -1000}  -- 必须是个非法值
                end
                ]]
                ProcedureTool:EnterLocalDungeon(nDungeonId, nPlayerId)
            end
        elseif tbMockData ~= nil then
            if (self.Param.bFromCmd) then
                LoadMap(self, tbMockData)
            else
                SpawnPawnAtPlayerStart(self, tbMockData)
            end
        end
    end
end

function Procedure_Mock:End()
    self.tbEventHelper:UnregisterAll()
    Procedure_Mock.super.End(self)
end

return Procedure_Mock
