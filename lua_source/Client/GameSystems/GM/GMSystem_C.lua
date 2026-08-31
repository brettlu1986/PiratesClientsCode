local luaclass = require("luaclass")
local GMSystem = require("GMSystem")
local GMSystem_C = luaclass("GMSystem_C", GMSystem)

local tbAllLocalVars = {}

-- local tbLocationHandle = nil

-- local PrintGameObjectInfo = function(szParam)
-- 	local GameObjectSystem = dynamic_require("GameObjectSystem")
-- 	GameObjectSystem:PrintDebugInfo()
-- end

local SendGMCommandToHubServer = function(szParam)
	local Proto = require("ClientProtoNames")
	local NetworkManager = dynamic_require("NetworkManager")
	local tbPacket =
	{
		cmd = szParam
	}
	NetworkManager:GetHubServerProxy():SendPacket(Proto.c2s_GmCmd, tbPacket);
end

local SendGMCommandToDungeonServer = function(szParam)
	local pPlayerController = GameplayStatics.GetPlayerController(GWorld, 0)
	if pPlayerController.ServerExecGMCommand ~= nil then
		pPlayerController:ServerExecGMCommand(szParam)
	end
end

-- local SwitchNetLog = function(szParam)
-- 	local NetworkManager = dynamic_require("NetworkManager")
-- 	local bSwitch =(szParam == "1")
-- 	NetworkManager:GetHubServerProxy():SwitchNetLog(bSwitch)
-- end

local PrintItemInfo = function(szParam)
	local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
	local ItemComponentOld = GamePlayerSelfHelper:Get().ItemComponentOld
	local BackpackRoom = ItemComponentOld:GetBackpack()
	for RoomType, ItemRoom in pairs(BackpackRoom) do
		log("------------------")
		log("RoomType : ", RoomType)
		local ItemList = ItemRoom:GetItemList()
		for index, Item in ipairs(ItemList) do
			log("Item InstanceId : ", Item:GetInstanceId(), " StackCount : ", Item:GetStackCount())
		end
	end
end

local function FakeCrash(szParam)
    local DelayTimer = require("DelayTimer")
    local bIsOtherThread = szParam ~= nil and szParam == "1"
	DelayTimer:DelayRun(function()
		log("----InDelayRun")
		EngineExtShell.TriggerCrash(bIsOtherThread)
	end, 3)
end

local function LogCat(szParam)
	local tbParams = {}
	for sz in string.gmatch(szParam, "%S+") do
		table.insert(tbParams, sz)
	end
	local SubCommand = tbParams[1]
	if SubCommand == "e" then
		LogCatcher.SetEnable(tbParams[2] == "1")
	elseif SubCommand == "s" then
		LogCatcher.PrintLogsOnScreen(tbParams[2] == "1")
	elseif SubCommand == "d" then
		LogCatcher.SetPrintDuration(tonumber(tbParams[2]))
	elseif SubCommand == "p" then
		local LogCount = tbParams[2] or "20"
		local ErrorCount = tbParams[3] or "5"
		printScreen(LogCatcher.GetLogs(tonumber(LogCount), tonumber(ErrorCount),""))
	end
end

local function Mock(szParam)
	local ProcedureTool = require("ProcedureTool")
	local nMockId = tonumber(szParam)
	if nMockId ~= nil then
		ProcedureTool:EnterMock({nMockId = nMockId, bFromCmd = true}, true)
	else
		logerror("Param of command 'mock' must be number.")
	end
end

local function EnterLocalDungeon(szParam)
	local ProcedureTool = require("ProcedureTool")
	local nDungeonId = tonumber(szParam)
	ProcedureTool:EnterLocalDungeon(nDungeonId)
end

local bTest = true

local function CollectNpcData(szParam)
	local dkjson = require("dkjson")
	local NPCSystem = require("NPCSystem")
	local StringUtil = require("StringUtil")
	local NPCUsageDef = require("NPCUsageDef")

	if(bTest) then
		bTest = false
		NPCSystem:AddServerNPCInfo(1, 2, 3, {x = - 1, y = - 888, z = - 999}, 0)
	end

	local tbParams = StringUtil.Split(szParam, ' ')
	local tbRet = NPCSystem:FindDataByUsage(tonumber(tbParams[1]), NPCUsageDef.Gather)
	for i, tbData in ipairs(tbRet) do
		log("CollectNpcData", dkjson.encode(tbData))
	end
end

local function TestSocietyExplorer(szParam)
	local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
	local SocietyExplorerSystem = require("SocietyExplorerSystem")
	local PlayerSelf = GamePlayerSelfHelper:Get()
	if(szParam == '0') then
		local pLocation = PlayerSelf:GetLocation()
		SocietyExplorerSystem:SetInfo(1, pLocation.X, pLocation.Y)
	else
		SocietyExplorerSystem:UpdateArrow()
	end
end

local function Interaction(szParam)
	local StringUtil = require("StringUtil")
	local InteractionHelper = require("InteractionHelper")
	local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
	local tbParams = StringUtil.Split(szParam, ' ')
	local szSubCommand = tbParams[1]
	if szSubCommand == "matinee" then
		InteractionHelper:CreateMatinee(tonumber(tbParams[2]))
	elseif szSubCommand == "explore" then
		InteractionHelper:CreateExplore(tonumber(tbParams[2]))
	elseif szSubCommand == "head_dialog" then
    	local target = GamePlayerSelfHelper:Get()
		local ActorSelectorComponent = target.ActorSelectorComponent
		local selecteNpc = ActorSelectorComponent:GetSelectedNpc(false)
		if selecteNpc then
			target = selecteNpc
		end
    	InteractionHelper:CreatePortraitHeadDialog(tonumber(tbParams[2]), nil, nil)
		-- InteractionHelper:CreateHeadDialog(tonumber(tbParams[2]))
	elseif szSubCommand == "portrait" then
		InteractionHelper:CreatePortrait(tonumber(tbParams[2]), false)
	elseif szSubCommand == "camera" then
		InteractionHelper:CreateCameraDialog(tonumber(tbParams[2]))
	end
end

local function FlushShipRes(szParam)
	local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
    local PlayerSelf = GamePlayerSelfHelper:Get()
    PlayerSelf.ShipAvatarComponent:FlushPlayerSelfRes()
end

local function UpdateHumanAvatar(szParam)
	local StringUtil = require("StringUtil")
	local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
	local tbParams = StringUtil.Split(szParam, ' ')
	local PlayerSelf = GamePlayerSelfHelper:Get()
	local tbResData =
	{
		head = tonumber(tbParams[1]),
		body = tonumber(tbParams[2]),
		hair = tonumber(tbParams[3])
	}
	PlayerSelf.HumanAvatarComponent:UpdateResData(tbResData)
end

local function TestAccessory(szParam)
	local UIDef = require("UIDef")
	local UIManager = require("UIManager")
	local StringUtil = require("StringUtil")
	local tbParams = StringUtil.Split(szParam, ' ')
	local UI = UIManager:GetWnd(UIDef.UI_SHIP_ACCESSORY_BUILD)
	UI:TestParam(tonumber(tbParams[1]), tonumber(tbParams[2]), tonumber(tbParams[3]), tonumber(tbParams[4]), tonumber(tbParams[5]))
end

local function QuitDungeon()
	local BattleGameModeSystem = dynamic_require("BattleGameModeSystem")
    BattleGameModeSystem:RequestQuitDungeon(BattleGameModeSystem.QUIT_REASON.QUIT_BUTTON)
end

local function LeaveDungeon()
	local ProtoDC = require("DungeonCommonProtoNames")
	local NetworkManager = dynamic_require("NetworkManager")
    NetworkManager:GetRPCNetworkProxy():SendToServer(ProtoDC.c2d_LeaveDungeon)
end
local function RestartGame(szParam)
	local ManagerRoot = require("ManagerRoot")
	local ManagerGroupDef = require("ManagerGroupDef")
    ManagerRoot:UninitGroup(ManagerGroupDef.nBattleGroupID, true)
    ManagerRoot:UninitGroup(ManagerGroupDef.nHubGroupID, true)
    ManagerRoot:UninitGroup(ManagerGroupDef.nDefaultGroupID, true)
    ManagerRoot:UninitGroup(ManagerGroupDef.nImmortalGroupID, true)
    ManagerRoot:UninitAll()

	local GameInstance = GameplayStatics.GetGameInstance(GWorld)
	GameInstance:RestartGameOnNextFrame()
end

local function PlayAnimMontage(szParam)
	local NPCSystem = require("NPCSystem")
	local StringUtil = require("StringUtil")
	local MontageDataTable = require("MontageDataTable")
	local tbParams = StringUtil.Split(szParam, ' ')
	local actor_id = tonumber(tbParams[1])
	local montage_id = tonumber(tbParams[2])

	local pNpc = NPCSystem:GetNpcByID(actor_id)
    if pNpc then
        local szRes = MontageDataTable:GetTemplate(montage_id).szRes
        pNpc.pUEActor:PlayAnimMontage(szRes:load(), 1, "Default")
    end
end

local function PrintLuaMemory()
	local ResourceManager = require("ResourceManager")
	local nSize = ResourceManager:GetUsedMemorySize()
    log("Lua memory used", nSize/1024/1024, "M")
    printPluginMemory()
end

local function GC()
	local ResourceManager = require("ResourceManager")
	ResourceManager:GC()
	KismetSystemLibrary.CollectGarbage()
end

local function PrintLuaReferenced()
	printrefobjects()
end

local function SendPacket(szProto, tbPacket)
	local NetworkManager = dynamic_require("NetworkManager")
    local Socket = NetworkManager:GetHubServerProxy()
    return Socket:SendPacket(szProto, tbPacket)
end

local function SetCinematicMode(szParam)
	local UIStateDef = require("UIStateDef")
	local UIManager = require("UIManager")
	if szParam ~= "0" then
		UIManager:PushState(UIStateDef.StateName.UI_INTERACTION_STATE)
		CommonShell.GetCommon(GWorld):GetInputManager():OpenGestureSelfTouchListen()
	else
		UIManager:PopState(UIStateDef.StateName.UI_INTERACTION_STATE)
		CommonShell.GetCommon(GWorld):GetInputManager():CloseGestureSelfTouchListen()
	end
end

local ShowPlayerCountTimer = nil
local function ShowPlayerCount(szParam)
	local Timer = require("Timer")
	local StringUtil = require("StringUtil")
	local Proto = require("ClientProtoNames")
	local NetworkManager = dynamic_require("NetworkManager")
	local tbParams = StringUtil.Split(szParam, ' ')
	local HubProxy = NetworkManager:GetHubServerProxy()
	if(tbParams[1] == '1') then
		if(ShowPlayerCountTimer) then
			return
		end
		HubProxy:BindFunc(Proto.s2c_GetPlayerCount, function(tbPacket)
			printScreen(tbPacket.online.." online, "..tbPacket.disconnected.." disconnected, "..tbPacket.total.." total")
		end)
		HubProxy:SendPacket(Proto.c2s_GetPlayerCount, {})
		ShowPlayerCountTimer = Timer.NewTimer(function()
			HubProxy:SendPacket(Proto.c2s_GetPlayerCount, {})
		end, 10, true)
	elseif(ShowPlayerCountTimer) then
		HubProxy:UnbindMethod(Proto.c2s_GetPlayerCount, nil, nil)
		ShowPlayerCountTimer:Clear()
		ShowPlayerCountTimer = nil
	end
end

local function ShowDebugWidget()
	local UIDef = require("UIDef")
	local UIManager = require("UIManager")
	UIManager:OpenWnd(UIDef.UI_DEBUG_WIDGET)
end

local function ArtOpen( szParam )
	local UIManager = require("UIManager")
	UIManager:CloseAllWnd()
	local szCommand = "open " .. szParam
	KismetSystemLibrary.ExecuteConsoleCommand(GWorld, szCommand, nil)
    CommonShell.GetCommon(GWorld):GetInputManager():OpenGestureSelfTouchListen()
end

local function RetryGame(szParam)
	local Proto = require("ClientProtoNames")
	local NetworkManager = dynamic_require("NetworkManager")
	NetworkManager:GetRPCNetworkProxy():SendToServer(Proto.c2d_RetryGame)
end

local function EnableDebugLog(szParam)
	setenabledebuglog(szParam == "true")
end

local function ToggleFPS(szParam)
	KismetSystemLibrary.ExecuteConsoleCommand(GWorld, "stat fps", nil)
end

local function SensitiveWordsSystemTest(szParam)
	local SensitiveWordsSystem = require("SensitiveWordsSystem")
	log("SensitiveWordsSystem start")
	local bRet = SensitiveWordsSystem:Check(szParam)
	log("SensitiveWordsSystem end", tostring(bRet))
	-- SensitiveWordsSystem:Init()
end

local function SetHubServerIp(szParam)
    szParam = string.gsub(szParam, "\"", "")
	local GlobalVariableSystem = dynamic_require("GlobalVariableSystem")
	GlobalVariableSystem.tbServerList[1].lobby_backup = szParam
end

local function ShowMessageBox()
	local UIDef = require("UIDef")
	local UIManager = require("UIManager")
	local Proto = require("ClientProtoNames")
	local tbParams = {}
	tbParams.nButtonType = Proto.s2c_ShowMessageBox_Buttons.OK
	tbParams.nCountDownType = Proto.s2c_ShowMessageBox_Countdown.NO_COUNTDOWN
	tbParams.nCountDown = 0
	tbParams.szTitle = "ceshi"
	tbParams.szText = "ceshi"
	UIManager:OpenWnd(UIDef.UI_SERVER_COMMON_DIALOG,tbParams)
end

local function DumpRenderTexture()
	CommonShell.GetCommon(GWorld):DumpRenderTexture()
end

local function PlayAnimation(szParam)
	local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
	local ActorSelectorComponent = GamePlayerSelfHelper:Get().ActorSelectorComponent
	local selecteNpc = ActorSelectorComponent:GetSelectedNpc(false)
	if not selecteNpc then
		return
	end
	local SelfAnimationHelper = require("SelfAnimationHelper")
	SelfAnimationHelper:PlayNPCAnimation(selecteNpc, szParam)
end

local function CrashRenderThread()
	ClientShell.GetClient(GWorld):CrashRenderThread()
end

local function OpenAssociationUI()
	local AssociationSystemUtils = require("AssociationSystemUtils")
	AssociationSystemUtils:OpenAssociationWnd()
end

local OnBattlegroundMatchmakingStatTimer = nil
local function BattlegroundMatchmakingStat(szParam)
	local Proto = require("ClientProtoNames")
	local NetworkManager = dynamic_require("NetworkManager")
	local HubProxy = NetworkManager:GetHubServerProxy()

	local fnSendMsg = function()
		HubProxy:BindFunc(Proto.s2c_GetBattlegroundStatistics, function(tbPacket)
			printScreen("Battleground matchmaking statistics(", tbPacket.count, "most recent data): Max [ ", tbPacket.max, "]; Min [", tbPacket.min, "]; Avg [", tbPacket.avg, "]")
			HubProxy:UnbindMethod(Proto.s2c_GetBattlegroundStatistics)
		end)
		HubProxy:SendPacket(Proto.c2s_GetBattlegroundStatistics)
	end

	local interval = tonumber(szParam)
	if OnBattlegroundMatchmakingStatTimer ~= nil then
		printScreen("Close outputing matchmaking stat.")
		OnBattlegroundMatchmakingStatTimer:Clear()
		OnBattlegroundMatchmakingStatTimer = nil
	elseif interval == nil then
		fnSendMsg()
	else
		printScreen("Start outputing matchmaking stat at", interval, "interval.")
		local Timer = require("Timer")
		OnBattlegroundMatchmakingStatTimer = Timer.NewTimer(fnSendMsg, interval, true)
	end
end

-- local function TestGetPvEStats()
-- 	local PlayerSelf = GamePlayerSelfHelper:Get()
-- 	local nPlayerid = PlayerSelf.nPlayerId
-- 	local c2s_PvEStats =
--     {
--         player_id = nPlayerid
--     }
--     SendPacket(Proto.c2s_PvEStats, c2s_PvEStats)
-- end

-- local function TestGetPvPStats()
-- 	local PlayerSelf = GamePlayerSelfHelper:Get()
-- 	local nPlayerid = PlayerSelf.nPlayerId
-- 	local c2s_PvPStats =
--     {
--         player_id = nPlayerid
--     }
--     SendPacket(Proto.c2s_PvPStats, c2s_PvPStats)
-- end

local function TestGetRecentBattleRecords()
	local Proto = require("ClientProtoNames")
	local c2s_RecentBattleRecords =
	{
		last_record_id = 0
	}
	SendPacket(Proto.c2s_RecentBattleRecords, c2s_RecentBattleRecords)
end

local function TestSendLocalBattleStats()
	local DataProto = require("DataProtoNames")
	local Proto = require("ClientProtoNames")
	local c2s_BattleStats =
	{
		dungeon_id = 80101,
		stats =
		{
            player_id = 0,
            ship_id = 1031,
            cannon_damage = 1,
            cannon_fired_count = 2,
            cannon_hit_count = 3,
            cannon_core_count = 4,
            caused_fire_count = 5,
            caused_fire_damage = 6,
            torpedo_damage = 7,
            torpedo_fired_count = 8,
            torpedo_hit_count = 9,
            caused_leak_count = 10,
            caused_leak_damage = 11,
            cure_amount = 12,
            be_cured_amount = 13,
            kill_count = 14,
            dead_count = 15,
            sail_distance = 16,
            total_damage = 17,
            assist_count = 18,
            mvp = true,
            result = DataProto.GameResult.GAME_WIN,
        }
	}
	SendPacket(Proto.c2s_BattleStats, c2s_BattleStats)
end

local function skiptutorial(self)
	local ClientEventDef = require("ClientEventDef")
	local EventManager = require("EventManager")
	-- EventManager:OnFireEvent(ClientEventDef.EV_GUIDE_SKIP_DUNGEON)
	EventManager:OnFireEvent(ClientEventDef.EV_UI_GUIDE_END_STEP, 300, 30008, 1)
end

local function questtownportal(szParam)
	local Proto = require("ClientProtoNames")
	local StringUtil = require("StringUtil")
	local tbParams = StringUtil.Split(szParam, ' ')
	local nSceneId = tonumber(tbParams[1])
	local nPlayerStartId = tonumber(tbParams[2])

	local c2s_QuestTownPortal =
	{
		scene_id = nSceneId,
		player_start_id = nPlayerStartId,
	}
	SendPacket(Proto.c2s_QuestTownPortal, c2s_QuestTownPortal)
end

-- 临时测试
-- local function EnableNewLua(szParam)
-- 	local bEnable = szParam ~= nil and szParam == "on"
-- 	local pSaver = ClientShell.GetClient(GWorld):GetSaveGameManager()
-- 	pSaver:AddBoolData("EnableNewLua", bEnable)
-- 	pSaver:Save()
-- end

local function LuaDebug(szParam)
	local StringUtil = require("StringUtil")
	local tbParams = szParam and StringUtil.Split(szParam, ' ') or nil
	if(tbParams == nil or #tbParams == 0) then
        printLuaDebuginfo(0)
    else
        printLuaDebuginfo(tonumber(tbParams[1]))
	end
end

local function Pirates()
	-- 所有关键道具
	KismetSystemLibrary.ExecuteConsoleCommand(GWorld, "gm multi-add-item 1760005 1 1760008 1 1760009 1 1760010 1 1760011 1 1760012 1 1760013 1 1760014 1 1760015 1 1760017 1 1760018 1 1760019 1 1610001 1 1610002 1 1610004 1 1610005 1 1610006 1 1620001 1 1620002 1 1630001 1 1630002 1 1404000 999 1404001 999 1404002 999 1404003 999 1404004 999 1404005 999 1404200 999 1404201 999 1404400 999 1404401 999 1404402 999 1100000 1 1120000 1 1130000 1 1140000 1 1150000 1 1200000 1 1200001 1 1200002 1 2060020 1 2060021 1 2060022 1 2060023 1 2060024 1 2060025 1 2060026 1 2060027 1 2060028 1 2060029 1", nil)
	-- 所有钱
	KismetSystemLibrary.ExecuteConsoleCommand(GWorld, "gm add-currency 1400000 100000", nil)
	KismetSystemLibrary.ExecuteConsoleCommand(GWorld, "gm add-currency 1400001 100000", nil)
	KismetSystemLibrary.ExecuteConsoleCommand(GWorld, "gm add-currency 1400002 100000", nil)
	KismetSystemLibrary.ExecuteConsoleCommand(GWorld, "gm add-currency 1400003 100000", nil)
end

-- local function DefaultPickUpCollision(szParam)
-- 	local StringUtil = require("StringUtil")
-- 	local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
-- 	local tbParams = szParam and StringUtil.Split(szParam, ' ') or nil
-- 	local nDefault = tbParams and tonumber(tbParams[1]) or 1
-- 	local PickComponent = GamePlayerSelfHelper:Get().pUEActor.PickComponent
-- 	log("DefaultPickUpCollision ", nDefault)
-- 	if nDefault > 0 then
-- 		PickComponent:SetUseDefaultCollision(true)
-- 	else
-- 		PickComponent:SetUseDefaultCollision(false)
-- 	end
-- end

-- local function PrintSceneItem(szParam)
-- 	local L10N = require("L10N")
-- 	local StringUtil = require("StringUtil")
-- 	local GameTriggerType = require("GameTriggerType")
-- 	local GameObjectTypeDef = require("GameObjectTypeDef")
-- 	local BattleItemDataTable = require("BattleItemDataTable")
-- 	local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
-- 	local GameObjectSystem = dynamic_require("GameObjectSystem")
-- 	local GlobalVariableSystem_C = require("GlobalVariableSystem_C")

-- 	local tbParams = StringUtil.Split(szParam, ' ')
-- 	GlobalVariableSystem_C.bPrintSceneItem = tonumber(tbParams[1]) == 1 and true or false
-- 	local nDistance = tonumber(tbParams[2])
-- 	local tbPlayer = GamePlayerSelfHelper:Get()
-- 	local pLocation = tbPlayer:GetLocation()
-- 	tbPlayer.pUEActor:PrintPickUpCollision()

-- 	local tbObjects = GameObjectSystem:GetAllGameObjects()
-- 	for _, v in pairs(tbObjects) do
-- 		if v.ObjectType == GameObjectTypeDef.Trigger and v.nType == GameTriggerType.SceneItem and  v.pUEActor ~= nil then
-- 			local pItemLocation = v:GetLocation()
-- 			if math.sqrt((pLocation.X - pItemLocation.X)^2 + (pLocation.Y - pItemLocation.Y)^2) <= nDistance then
-- 				local tbItemResInfo = v.tbCustomProtoData.scene_item_info

-- 				local tbItemData = BattleItemDataTable:GetTemplate(tbItemResInfo.template_id)
-- 				local szMsg = string.format("ActorTriggerGroupHelper scene item: %s, uniqueId = %d, serverId = %d", L10N:ToString(tbItemData.l10nName), v:GetUEActorUniqueId(), v.nServerInstanceId)
-- 				printScreen(szMsg)
-- 				log(szMsg)
-- 				v.pUEActor:PrintCollision()
-- 			end
-- 		end
-- 	end
-- end


-- 存盘key值
local KeyEnableXSJEngineFeature = "EnableXSJEngineFeature"

local function SetXSJEngineFeatureSettings(bEnabled)
	-- if(not GWithEditor) then
		-- AsyncLoading: s.EnableAsyncLoadingReturnImmediately 1开/0关
		--KismetSystemLibrary.ExecuteConsoleCommand(GWorld,
		--"s.EnableAsyncLoadingReturnImmediately " .. (bEnabled and "1" or "0"),
		--nil)
		-- 海洋贴图加载： ocean.usesyncload 1 同步加载 0 异步加载
		--KismetSystemLibrary.ExecuteConsoleCommand(GWorld,
		--"ocean.usesyncload " .. (bEnabled and "0" or "1"),
		--nil)
		-- 角色合并：r.MergeSkeletalMesh 1开/0关
		--KismetSystemLibrary.ExecuteConsoleCommand(GWorld,
		--"r.MergeSkeletalMesh " .. (bEnabled and "1" or "0"),
		--nil)
		-- 船只合并：r.UseShipMerge 1开/0关
		--KismetSystemLibrary.ExecuteConsoleCommand(GWorld,
		--"r.UseShipMerge " .. (bEnabled and "1" or "0"),
		--nil)
		-- 粒子合并：r.EnableParticleMerge 1开/0关
		--KismetSystemLibrary.ExecuteConsoleCommand(GWorld,
		--"r.EnableParticleMerge " .. (bEnabled and "1" or "0"),
		--nil)
		-- 平面反射实例化优化：r.EnableReflectionInstancedOptimization 1开/0关
		--KismetSystemLibrary.ExecuteConsoleCommand(GWorld,
		--"r.EnableReflectionInstancedOptimization " .. (bEnabled and "1" or "0"),
		--nil)
		-- 名字片：XSJME.WidgetBatchRendering 1开/0关
		--KismetSystemLibrary.ExecuteConsoleCommand(GWorld,
		--"pir.3DWidgetBatching " .. (bEnabled and "1" or "0"),
		--nil)
		-- 新管线： r.SPRenderer 1开/0关
		--KismetSystemLibrary.ExecuteConsoleCommand(GWorld,
		--"r.SPRenderer " .. (bEnabled and "1" or "0"),
		--nil)
	-- end
end

local function SetXSJEngineFeatureEnabled(szParam)
    local bEnabled = szParam == "1"
    local pSaveGameMgr = ClientShell.GetClient(GWorld):GetSaveGameManager()

    -- 执行命令，以及存储的key值
	SetXSJEngineFeatureSettings(bEnabled)

    -- 在save前加命令以及存盘
    pSaveGameMgr:AddBoolData(KeyEnableXSJEngineFeature, bEnabled)

    pSaveGameMgr:Save()
end

local function TestSaveGame(szParam)
	local pSaveGameMgr = ClientShell.GetClient(GWorld):GetSaveGameManager()

	while(true)
	do
		pSaveGameMgr:Save()
	end
end

local function TryLoadXSJEngineFeatureSwitch()
    local pSaveGameMgr = ClientShell.GetClient(GWorld):GetSaveGameManager()

    -- 读取逻辑
    local bEnabled = pSaveGameMgr:GetBoolDataWithDefault(KeyEnableXSJEngineFeature, true)
	SetXSJEngineFeatureSettings(bEnabled)

    -- 往下加
end

local function PrintSelfLocation(szParam)
	local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
	local tbLocation = GamePlayerSelfHelper:Get():GetLocation()
	local szLocation = string.format( "Location: X = %.1f, Y = %.1f, Z = %.1f",
		tbLocation.X, tbLocation.Y, tbLocation.Z )
	-- printScreen(szLocation)
	log(szLocation)

	local UIDef = require("UIDef")
	local UIManager = require("UIManager")
	local tbOpenArgs = { nDisplayTime = tonumber(szParam) }
	UIManager:OpenWnd(UIDef.UI_REAL_TIME_DEBUG_INFO_LAYER, tbOpenArgs)
end

local function ShowReliableMulticast()
	EditorExtendFunctions.ShowMulticastFunction()
end

local function HeadlessTravel(szParam)
	local StringUtil = require("StringUtil")
	local szServerAddr = nil
	local nDungeonId = nil
	local tbParams = StringUtil.Split(szParam, ' ')
	if #tbParams >= 1 then
		szServerAddr = tbParams[1]
	end
	if #tbParams >= 2 then
		nDungeonId = tonumber(tbParams[2])
	end

	local ProcedureTool = require("ProcedureTool")
	ProcedureTool:EnterMock({szServerAddr = szServerAddr, nDungeonId = nDungeonId}, true)
end

local function DumpShipConfig()
	EditorExtendFunctions.ExportShipConfig(true)
	log("dump ship finished...")
end

local function LoadingScreen(szParam)
	local StringUtil = require("StringUtil")
	local GlobalVariableSystem = dynamic_require("GlobalVariableSystem")
	local tbParams = StringUtil.Split(szParam, ' ')
	local bUse = StringUtil.ToBool(tbParams[1])
	GlobalVariableSystem:UseLoadingScreen(bUse)
end

local function BuildItem(nTemplateId)
	local BattleItemSystemClient  = require("BattleItemSystemClient")
	BattleItemSystemClient:RequestBuildItem(tonumber(nTemplateId))
end

local function EnequipBattleItem(nInstanceId)
	local BattleItemSystemClient  = require("BattleItemSystemClient")
	BattleItemSystemClient:RequestUnEquipItem(tonumber(nInstanceId))
end

local function EquipBattleItem(szParam)
	local StringUtil = require("StringUtil")
	local tbParams = StringUtil.Split(szParam, ' ')
	local nOwnerInstanceId = tbParams[1]
	local nItemInstanceId = tbParams[2]
	local nSlotIndex = tbParams[3]
	local BattleItemSystemClient  = require("BattleItemSystemClient")
	BattleItemSystemClient:RequestEquipItem(tonumber(nOwnerInstanceId), tonumber(nItemInstanceId), tonumber(nSlotIndex))
end

local function EquipStackableBattleItem(szParam)
	local StringUtil = require("StringUtil")
	local tbParams = StringUtil.Split(szParam, ' ')
	local nOwnerInstanceId = tbParams[1]
	local nItemTemplateId = tbParams[2]
	local nCount = tbParams[3]
	local BattleItemSystemClient  = require("BattleItemSystemClient")
	BattleItemSystemClient:RequestEquipStackableItem(tonumber(nOwnerInstanceId), tonumber(nItemTemplateId), tonumber(nCount))
end

local function ExchangeStorageLocation(szParam)
	local StringUtil = require("StringUtil")
	local tbParams = StringUtil.Split(szParam, ' ')
	local nItemInstanceId1 = tbParams[1]
	local nItemInstanceId2 = tbParams[2]
	local BattleItemSystemClient  = require("BattleItemSystemClient")
	BattleItemSystemClient:RequestExchangeStorageLocation(tonumber(nItemInstanceId1), tonumber(nItemInstanceId2))
end

local function PickItem(nInstanceId)
	local BattleItemSystemClient = require("BattleItemSystemClient")
	BattleItemSystemClient:RequestPickUpSceneItem(tonumber(nInstanceId))
end

local function ThrowItem(nInstanceId)
	local BattleItemSystemClient = require("BattleItemSystemClient")
	BattleItemSystemClient:RequestThrowAwayItem(tonumber(nInstanceId))
end

local function ThrowAndPickupItem(szParam)
	local StringUtil = require("StringUtil")
	local tbParams = StringUtil.Split(szParam, ' ')
	local nItemInstanceId = tonumber(tbParams[1])
	local tbThrowItems = {}
	local nSize = #tbParams
	for i=2, nSize do
		if i + 1 <= nSize then
			local tbThrowItem = {}
			tbThrowItem.instance_id = tonumber(tbParams[i])
			i = i + 1
			tbThrowItem.count = tonumber(tbParams[i])
			table.insert(tbThrowItems, tbThrowItem)
		end
	end
	local BattleItemSystemClient  = require("BattleItemSystemClient")
	BattleItemSystemClient:RequestThrowAwayAndPickupItem(tbThrowItems, nItemInstanceId)
end

local function BeginViewItem(szParam)
	local StringUtil = require("StringUtil")
	local tbParams = StringUtil.Split(szParam, ' ')
	local nItemInstanceIds = {}
	for _, v in pairs(tbParams) do
		table.insert(nItemInstanceIds, tonumber(v))
	end
	local BattleItemSystemClient = require("BattleItemSystemClient")
	BattleItemSystemClient:RequestBeginViewSceneItems(nItemInstanceIds)
end

local function EndViewItem()
	local BattleItemSystemClient  = require("BattleItemSystemClient")
	BattleItemSystemClient:RequestEndViewSceneItems()
end

local function FFAJumpFromTransporter()
	local ProtoDC = require("DungeonCommonProtoNames")
	local NetworkManager = dynamic_require("NetworkManager")
	NetworkManager:GetRPCNetworkProxy():SendToServer(ProtoDC.c2d_JumpFromTransporter, {})
end

-- local function SetSceneItemViewDistance(szParam)
-- 	local StringUtil = require("StringUtil")
-- 	local GameTriggerType = require("GameTriggerType")
-- 	local GameObjectTypeDef = require("GameObjectTypeDef")
-- 	local GameObjectSystem = dynamic_require("GameObjectSystem")
-- 	local tbParams = StringUtil.Split(szParam, ' ')
-- 	local nDistance = tonumber(tbParams[1])
-- 	local tbObjects = GameObjectSystem:GetAllGameObjects()
-- 	for _, v in pairs(tbObjects) do
-- 		if v.ObjectType == GameObjectTypeDef.Trigger and v.nType == GameTriggerType.SceneItem and  v.pUEActor ~= nil then
-- 			v.pUEActor:SetViewDistance(nDistance)
-- 		end
-- 	end
-- end

-- local function SetFogVisible(szParam)
-- 	local StringUtil = require("StringUtil")
-- 	local GameTriggerType = require("GameTriggerType")
-- 	local GameObjectTypeDef = require("GameObjectTypeDef")
-- 	local GameObjectSystem = dynamic_require("GameObjectSystem")
-- 	local tbParams = StringUtil.Split(szParam, ' ')
-- 	local bVisible = tonumber(tbParams[1]) == 1 and true or false
-- 	local tbObjects = GameObjectSystem:GetAllGameObjects()
-- 	for _, v in pairs(tbObjects) do
-- 		if v.ObjectType == GameObjectTypeDef.Trigger and v.nType == GameTriggerType.Fog and  v.pUEActor ~= nil then
-- 			v.pUEActor:SetMeshVisible(bVisible)
-- 		end
-- 	end
-- end

local function ToggleBotAim(szParam)
	local bShow = szParam == "1"
	local GameCoreWatchSystem = require("GameCoreWatchSystem_C")
	local tbCurrentWatchBot = GameCoreWatchSystem.tbCurrentWatchBot
	if tbCurrentWatchBot and tbCurrentWatchBot.pUEActor then
		tbCurrentWatchBot.pUEActor.ShowEyeAim = bShow
	end
end

local function ToggleBotByIndex(szParam)
	local ProtoDC = require("DungeonCommonProtoNames")
	local NetworkManager = dynamic_require("NetworkManager")
	local StringUtil = require("StringUtil")

	local tbParams = StringUtil.Split(szParam, ' ')
	local nIndex = tonumber(tbParams[1])
	NetworkManager:GetRPCNetworkProxy():SendToServer(ProtoDC.c2d_ToggleBotByIndex, {nBotIndex = nIndex} )
end

local function ToggleBotById(szParam)
	local ProtoDC = require("DungeonCommonProtoNames")
	local NetworkManager = dynamic_require("NetworkManager")
	local StringUtil = require("StringUtil")

	local tbParams = StringUtil.Split(szParam, ' ')
	local nInstanceId = tonumber(tbParams[1])
	NetworkManager:GetRPCNetworkProxy():SendToServer(ProtoDC.c2d_ToggleBotById, {nBotInstanceId = nInstanceId})
end

local function EnableReplicatedLog(szParam)
	local bEnable = szParam == "1"
	local GlobalVariableSystem = dynamic_require("GlobalVariableSystem")
	GlobalVariableSystem.bEnableReplicatedLog = bEnable
end

local function MemSnapshotDump(szParam)
	local StringUtil = require("StringUtil")
	local tbParams = StringUtil.Split(szParam, ' ')
	local nCompareTime = tonumber(tbParams[1])
	local nInterval = tonumber(tbParams[2]) 
	log(string.format("memSnapshotDump compare time = %d, interval = %d", nCompareTime, nInterval))

	KismetSystemLibrary.ExecuteConsoleCommand(GWorld, string.format("dm memSnapshotDump %d %d", nCompareTime, nInterval), nil)
end

local function PrintMem()
	KismetSystemLibrary.ExecuteConsoleCommand(GWorld, string.format("dm printMem"), nil)
end

local function ToggleBack(szParam)
	local EventManager = require("EventManager")
	local ClientEventDef = require("ClientEventDef")
	local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
	local PlayerSelf = GamePlayerSelfHelper:Get()
	ToggleBotAim('0')
	if PlayerSelf:IsShip() then
		EventManager:OnFireEvent(ClientEventDef.EV_SET_BOT_CAMERA_BACK, false, PlayerSelf.pUEActor)
	else
		EventManager:OnFireEvent(ClientEventDef.EV_SET_BOT_CAMERA_BACK, true, PlayerSelf.pUEActor)
	end
	if PlayerSelf:IsShip() then
		KismetSystemLibrary.ExecuteConsoleCommand(GWorld, "xsj.usepawnlocforwc 1", nil)
	else
		KismetSystemLibrary.ExecuteConsoleCommand(GWorld, "xsj.usepawnlocforwc 0", nil)
	end
	EventManager:OnFireEvent(ClientEventDef.EV_WATCH_BOT_OVER)
	KismetSystemLibrary.ExecuteConsoleCommand(GWorld, "dm toggleBack", nil)
end

local function TestUpdate(szParam)
	require("TestUpdate")
end

local function IgnoreTcpError(szParam)
	local NetworkManager = dynamic_require("NetworkManager")
    local bIgnore = szParam == '1'
    NetworkManager:GetHubServerProxy().pNetworkManager:SetIgnoreSpecificError(bIgnore)
end

local function SetHumanWeaponProperty(szParam)
	local StringUtil = require("StringUtil")
	local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
	local HumanWeaponItemPropertyHelper = require("HumanWeaponItemPropertyHelper")
	local tbPlayer = GamePlayerSelfHelper:Get()
	local tbParams = StringUtil.Split(szParam, ' ')
	HumanWeaponItemPropertyHelper.GMSetBaseWeaponProperty(tbPlayer, tbParams, true)
	SendGMCommandToDungeonServer("sethumanweaponproperty "..szParam)
end

local function TestSound(szParam)
--	local Timer = require("Timer")
	local StringUtil = require("StringUtil")
	local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
	local tbPlayer = GamePlayerSelfHelper:Get()
	local tbParams = StringUtil.Split(szParam, ' ')
	local nCount = tonumber(tbParams[1]) or 10
	local szSoundResPath = "SoundCue'/Game/SoundCues/Effect/SC_BoltGun_01.SC_BoltGun_01'"
	local pSound = szSoundResPath:load()
	local pLocation = tbPlayer:GetLocation()
	for i=1,nCount do
		ExtendBlueprintFunctions.PlaySoundInClient(GWorld, pSound, 1, pLocation,
		tbPlayer.pUEActor)
	end
end

local function GTAEnableLog(szParam)
	local StringUtil = require("StringUtil")
	local GameTestAutomationLogHelper = require("GameTestAutomationLogHelper")
	local tbParams = StringUtil.Split(szParam, ' ')
	local nParam = tonumber(tbParams[1])
	if nParam == 1 then
		GameTestAutomationLogHelper.EnableLog(true)
	else
		GameTestAutomationLogHelper.EnableLog(false)
	end
end

local function EnableBattleTestAutomation(szParam)
	local StringUtil = require("StringUtil")
	local GameTestAutomationVariables = require("GameTestAutomationVariables")
	local tbParams = StringUtil.Split(szParam, ' ')
	local nParam = tonumber(tbParams[1])
	log("EnableBattleTestAutomation", nParam)
	if nParam == 1 then
		GameTestAutomationVariables.bBattleTestEnable = true
	else
		GameTestAutomationVariables.bBattleTestEnable = false
	end
end

local function StartMatchmaking(szParam)
	local StringUtil = require("StringUtil")
	local MatchmakingSystem = require("MatchmakingSystem")
	local tbParams = StringUtil.Split(szParam, ' ')
	local nDungeonId = tonumber(tbParams[1]) or 100011
	local nTeamMode = tonumber(tbParams[2]) or 1
	local bAutoTeamFormation = StringUtil.ToBool(tbParams[3])
	local szRoom = tbParams[4] or ""
	MatchmakingSystem:SetAutoMatchmaking(bAutoTeamFormation)
	MatchmakingSystem:SetSelectDungeon(nDungeonId)
	MatchmakingSystem:SetMatchmakingMode(nTeamMode)
	MatchmakingSystem:SetMatchmakingRoom(szRoom)
	MatchmakingSystem:StartMatchmaking()
end

local function ShowAimSphere(szParam)
	local GameObjectTypeDef = require("GameObjectTypeDef")
	local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
	local GameObjectSystem = dynamic_require("GameObjectSystem")
	local nShowTag = tonumber(szParam)
	local tbAllGameObjectMap = GameObjectSystem:GetAllGameObjects()


	local PlayerSelf = GamePlayerSelfHelper:Get()
	if PlayerSelf and PlayerSelf:IsHuman() and PlayerSelf.pUEActor then
		PlayerSelf.pUEActor.AdsorptionDebugType = nShowTag == 1 and EDrawDebugTrace.Persistent or EDrawDebugTrace.None
	end
    for nInstanceId, GameObject in pairs(tbAllGameObjectMap) do
		if GameObject.ObjectType == GameObjectTypeDef.PlayerOther then
			local pUEActor = GameObject.pUEActor
			if pUEActor and pUEActor.AimSphereCollision then
				pUEActor:ShowDebugAdsorptionSphere(nShowTag)
			end
        end
    end
end

--测试人的相机 attach detach
local CameraAttachParent = nil
local function DetachCamera(szParam)
	local GCMgr = GameplayStatics.GetPlayerCameraManager(GWorld, 0)
	local CameraActor = GCMgr:GetPlayerCameraActor()
	CameraAttachParent = CameraActor:GetAttachParentActor()
	GCMgr:UnInitCameraForDead()
end

local function AttachCamera(szParam)
	local GCMgr = GameplayStatics.GetPlayerCameraManager(GWorld, 0)
	local CameraActor = GCMgr:GetPlayerCameraActor()
	CameraActor:K2_SetActorLocationAndRotation(Vector{X = 0, Y = 0, Z = 0}, Rotator{Pitch = 0, Yaw = 0, Roll = 0});
	local AttachRule = EAttachmentRule.KeepRelative
	CameraActor:K2_AttachToActor(CameraAttachParent, "", AttachRule, AttachRule, AttachRule, false)
	--CameraActor:K2_AttachToComponent(CameraAttachParent.Mesh, "", AttachRule, AttachRule, AttachRule, false)
end

local function PrintTemplateActorInfo()
    CommonShell.Get(GWorld):GetTemplateActorDataManager():PrintDebugInfo()
end

-- local function OnPlayerSelfReady(self)
--  local GlobalVariableSystem = dynamic_require("GlobalVariableSystem")
-- 	if not GlobalVariableSystem:IsInDungeon() then
-- 		return
-- 	end
-- 	local tbPlayer = GamePlayerSelfHelper:Get()
-- end

local function SendMsgToFriend(szParam)
	local StringUtil = require("StringUtil")
	local tbParams = StringUtil.Split(szParam, ' ')
	local szMsg = tbParams[1]
	local nFriendId = tonumber(tbParams[2])
    local BattleChatSystem = require("BattleChatSystem_C")
	BattleChatSystem:SendMsgToFriend(szMsg, nFriendId)
end

local function ShowNotifaction(szParam)
	local StringUtil = require("StringUtil")
	local tbParams = StringUtil.Split(szParam, ' ')
	--参数1 通知模板类型
	--参数2 是否发往全服
	local szBSendSystem = tbParams[2]
	local szSendSystemPrefix = (szBSendSystem == "0" or not szBSendSystem) and "" or "gm system-chat "
	local szID = tbParams[1]
	local tbGM = {}
	--模板1 恭喜您获得%s 不在跑马灯中显示，如果是全服广播则只在系统频道显示
	tbGM[1] = "{\"message_id\":1,\"system_channel_item\":{\"1400000\":10,\"1400001\":20},\"loop_count\":2,\"interval\":4,\"priority\":1000}"
	--模板2 恭喜%s气运无双，获得%s，海盗之路正在向巅峰迈进！ 在跑马灯中显示，如果是全服广播则在系统频道、跑马灯中显示
	tbGM[2] = "{\"message_id\":2,\"player_name\":\"JNN2\",\"system_channel_item\":{\"1400000\":10,\"1400001\":20},\"loop_count\":2,\"interval\":4,\"priority\":1000}"
	--模板3 XX活动已开启，内容表中配置。 在跑马灯中显示，如果是全服广播则在系统频道、跑马灯中显示
	tbGM[3] = "{\"message_id\":3,\"loop_count\":2,\"interval\":4,\"priority\":1000}"
	--模板4 您失去%s 不在跑马灯中显示，如果是全服广播则只在系统频道显示
	tbGM[4] = "{\"message_id\":4,\"system_channel_item\":{\"1400000\":10,\"1400001\":20},\"loop_count\":2,\"interval\":4,\"priority\":1000}"
	--模板5 自定义内容 不在跑马灯中显示，如果是全服广播则只在系统频道显示
	tbGM[5] = "{\"message_id\":5,\"notify_text\":\"123456\",\"loop_count\":2,\"interval\":4,\"priority\":1000}"
	--模板6 自定义内容 在跑马灯中显示，如果是全服广播则在系统频道、跑马灯中显示
	tbGM[6] = "{\"message_id\":6,\"notify_text\":\"123456\",\"loop_count\":2,\"interval\":4,\"priority\":1000}"
	local UIUtils = require("UIUtils")
	local szGM = szSendSystemPrefix .. tbGM[tonumber(szID)]
	UIUtils.ShowSystemNotifaction(szGM)
end

local function EnterHomeland()
	local HomelandSystem = require("HomelandSystem")
	HomelandSystem:EnterHomeland()
end


local function HomelandSwitchScene(szParam)
	local StringUtil = require("StringUtil")
	local tbParams = StringUtil.Split(szParam, " ")
	local nSceneId = tonumber(tbParams[1])
	local bRecover = tbParams[1] == "1" and true or false
	local HomelandSystem = require("HomelandSystem")
	HomelandSystem:RequestSetCurrentSceneId(nSceneId, bRecover)
end

local function PlaceBuilding(szParam)
	local StringUtil = require("StringUtil")
	local tbParams = StringUtil.Split(szParam, " ")
	local nBlockId = tonumber(tbParams[1])
	local nItemInstanceId = tonumber(tbParams[2])
	local nRotationId = tonumber(tbParams[3])
	local HomelandSystem = require("HomelandSystem")
	HomelandSystem:RequestPlaceItemBuilding(nBlockId, nItemInstanceId, nRotationId)
end

local function RemoveBuilding(szParam)
	local StringUtil = require("StringUtil")
	local tbParams = StringUtil.Split(szParam, " ")
	local nBlockId = tonumber(tbParams[1])
	local HomelandSystem = require("HomelandSystem")
	HomelandSystem:RequestRemoveItemBuilding(nBlockId)
end

local function DebugTemplateActor(szParam)
    local BattleTemplateActorSystem = require("BattleTemplateActorSystem_C")
    BattleTemplateActorSystem:SetDebug(szParam == "1")
end

local function LandmarkUpgrade(szParam)
	local StringUtil = require("StringUtil")
	local tbParams = StringUtil.Split(szParam, " ")
	local nLandmarkType = tonumber(tbParams[1])
	local HomelandSystem = require("HomelandSystem")
	HomelandSystem:RequestLandmarkUpgrade(nLandmarkType)
end

local function HomelandRemoveBuilding(szParam)
	local StringUtil = require("StringUtil")
	local tbParams = StringUtil.Split(szParam, " ")
	local HomelandSceneSystem = require("HomelandSceneSystem")
	HomelandSceneSystem:RemoveBuilding(tonumber(tbParams[1]))
end

local function HomelandCreateBuilding(szParam)
	local StringUtil = require("StringUtil")
	local tbParams = StringUtil.Split(szParam, " ")
	local nBlockId = tonumber(tbParams[1])
	local nBuildingId = tonumber(tbParams[2])
	local bPreview = tbParams[3] == "1" or tbParams[1] == "true" or false
	local HomelandSceneSystem = require("HomelandSceneSystem")
	HomelandSceneSystem:CreateBuilding(nBlockId, nBuildingId, bPreview)
end

local function SwitchHomeScene(szParam)
	local StringUtil = require("StringUtil")
	local tbParams = StringUtil.Split(szParam, " ")
	local nSceneId = tonumber(tbParams[1])
	local bRecover = tbParams[2] == "1" and true or false
	local HomelandSystem = require("HomelandSystem")
	HomelandSystem:RequestSetCurrentSceneId(nSceneId, bRecover)
end

local function HomelandEnableBlock(szParam)
	local StringUtil = require("StringUtil")
	local tbParams = StringUtil.Split(szParam, " ")
	local nBlockId = tonumber(tbParams[1])
	local bEnable = tbParams[2] == "1" or tbParams[2] == "true" or false
	local HomelandSceneSystem = require("HomelandSceneSystem")
	HomelandSceneSystem:SetBlockEnable(nBlockId, bEnable)
end

local function TestLua(szParam)
	--local StringUtil = require("StringUtil")
    --local tbParams = StringUtil.Split(szParam, " ")
    local nFunctionInputParamCount = 5
    local nFunctionOutputParamCount = 0
    --local bUseUELuaField = tbParams[1] == "1"

    --setuseueluafield(bUseUELuaField)
    local szClass = "Class'/Game/Game/CharacterEx/BP_NewPlayer.BP_NewPlayer_C'"
    local pActor = EngineExtActorShell.SpawnActorForScript(GWorld, szClass:load(), Transform(), nil)

    local nTestPropertyCount = 10000
    local nTestFunctionCount = 10000
    local pTestObject = CommonShell.CreateNewTestObject(nTestPropertyCount, nTestFunctionCount,
        nFunctionInputParamCount, nFunctionOutputParamCount)

    local szP1Log = string.format("%d properties set firstly", nTestPropertyCount)
    rts()
    for i=1, nTestPropertyCount do
        pTestObject["Property_"..tostring(i-1)] = i-1
        --pTestObject["Property_0"] = i-1
    end
    rte(szP1Log)

    local pFunction
    local tbFunctions = {}
    local szF1Log = string.format("%d functions call firstly", nTestFunctionCount)

    rts()
    for i=1, nTestFunctionCount do
        pFunction = pTestObject["Function_"..tostring(i-1)]
        table.insert(tbFunctions, pFunction)
        pFunction(pTestObject, 1, 2, 3, 4, 5)
    end
    rte(szF1Log)

    local szSameFLog = string.format("%d same functions call", nTestFunctionCount)
    rts()
    for i=1, nTestFunctionCount do
        pTestObject["Function_0"](pTestObject, 1, 2, 3, 4, 5)
    end
    rte(szSameFLog)

    local tbGetControllor = {}
    local szGetControllerLog = string.format("%d getcontroller firstly", nTestFunctionCount)
    rts()
    for i=1, nTestFunctionCount do
        pFunction = pActor.GetController
        table.insert(tbGetControllor, pFunction)
        pFunction(pActor)
    end
    rte(szGetControllerLog)

    local szTestRawCFunction = string.format("%d raw c function", nTestFunctionCount)
    rts()
    for i=1, nTestFunctionCount do
        testemptyfunction()
    end
    rte(szTestRawCFunction)

    -- recall
    local szP2Log = string.format("%d properties set secondarily", nTestPropertyCount)
    rts()
    for i=1, nTestPropertyCount do
        pTestObject["Property_"..tostring(i-1)] = i-1
    end
    rte(szP2Log)

    local szF2Log = string.format("%d functions call secondarily", nTestFunctionCount)
    rts()
    for i=1, nTestFunctionCount do
        tbFunctions[i](pTestObject, 1, 2, 3, 4, 5)
    end
    rte(szF2Log)

    local szGetControllerLog2 = string.format("%d getcontroller secondarily", nTestFunctionCount)
    rts()
    for i=1, nTestFunctionCount do
        tbGetControllor[i](pActor)
    end
    rte(szGetControllerLog2)

    log("------------------------------------------------------------------------------")
end

local function PrintRepInfo()
	local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
    local PlayerSelf = GamePlayerSelfHelper:Get()
    if(PlayerSelf) then
        PlayerSelf.CustomReplicationComponent.Helper.pRepComponent:PrintAllPropertySize()
    end
end

local function BeginGuide(szParam)
	local UIDef = require("UIDef")
	local UIManager = require("UIManager")
	local StringUtil = require("StringUtil")
	local GuideSystem = require("GuideSystem")
	local tbParams = StringUtil.Split(szParam, " ")
	local nModuleId = tonumber(tbParams[1])
	GuideSystem.bIsOpen = true
	GuideSystem:GM_Begin(nModuleId)
	UIManager:CloseWnd(UIDef.UI_DEBUG_WIDGET)
end

local function CloseGuide()
	local UIDef = require("UIDef")
	local UIManager = require("UIManager")
	local GuideSystem = require("GuideSystem")
	GuideSystem:GM_Close()
	UIManager:CloseWnd(UIDef.UI_DEBUG_WIDGET)
end

local function EndCurrentStep(szParam)
	local GuideSystem = require("GuideSystem")
	local StringUtil = require("StringUtil")
	local tbParams = StringUtil.Split(szParam, " ")
	local nModuleId = tonumber(tbParams[1])
	local nGroupId = tonumber(tbParams[2])
	GuideSystem:ForceEndCurrentStep(nModuleId, nGroupId)
end

local function BeginCurrentStep(szParam)
	local GuideSystem = require("GuideSystem")
	local StringUtil = require("StringUtil")
	local tbParams = StringUtil.Split(szParam, " ")
	local nModuleId = tonumber(tbParams[1])
	local nGroupId = tonumber(tbParams[2])
	GuideSystem:ForceBeginCurrentStep(nModuleId, nGroupId)
end

local function DebugAudio(szParam)
	KismetSystemLibrary.ExecuteConsoleCommand(GWorld, "Log LogAudio All", nil)
end

local function ReloadLua(szParam)
	-- luacheck: push ignore
	package.loaded[szParam] = nil
	-- luacheck: pop
	require(szParam)
end

local function SetMapPinch(szParam)
	local StringUtil = require("StringUtil")
	local tbParams = StringUtil.Split(szParam, " ")
	local nSize = tonumber(tbParams[1])
	local WorldMapUtil = require("WorldMapUtil")
	WorldMapUtil.PinchSize = nSize
end

local function QuitGame(szParam)
	local UIDef = require("UIDef")
	local UIManager = require("UIManager")
	-- UIUtils.ShowChoiceDialog("提示", "您确定要退出游戏重新登录吗？", function()
    --     EventManager:OnFireEvent(ClientEventDef.EV_UI_SELECT_ROLE_BACK)
	-- end)
	UIManager:OpenWnd(UIDef.UI_EXIT_GAME_DIALOG)
end

-- local function ChangeGuideZOrder(szParam)
-- 	local UIDef = require("UIDef")
-- 	local UIManager = require("UIManager")
-- 	local StringUtil = require("StringUtil")
-- 	local tbParams = StringUtil.Split(szParam, " ")
-- 	local nOrder = tonumber(tbParams[1])
-- 	local Wnd = UIManager:GetWnd(UIDef.UI_GUIDE)
-- 	Wnd:SetZOrder(nOrder)
-- end

local function EnableMic(szParam)
	local bEnable = szParam ~= "0"
	local GVoiceSDKSystem = require("GVoiceSDKSystem")
	-- local bAllRoom = szParam ~= "0"
	-- if bAllRoom then
	-- 	GVoiceSDKSystem:EnableCurrentAllRoomMicrophone(true)
	-- 	GVoiceSDKSystem:EnableCurrentTeamRoomMicrophone(false)
	-- else
	-- 	GVoiceSDKSystem:EnableCurrentAllRoomMicrophone(false)
	-- 	GVoiceSDKSystem:EnableCurrentTeamRoomMicrophone(true)
	-- end
	GVoiceSDKSystem:EnableMic(bEnable)
end

local function calldatasdk(szParam)
	local DataSDKHelper = require("DataSDKHelper")
	local ClientDefaultLogEventOp = require("ClientDefaultLogEventOp")
	log("calldatasdk param = " .. szParam)
	if szParam == "1" then
		log("111")
		DataSDKHelper.OnAccountLogin("JNN1")
	elseif szParam == "2" then
		log("222")
		DataSDKHelper.OnEvent("1", "test test")
	elseif szParam == "3" then
		log("333")
		DataSDKHelper.Ping("127.0.0.1")
	elseif szParam == "4" then
		log("444")
		
		ClientDefaultLogEventOp:OnCustomEvent("1", "ACustomEvent", 0, {["eventTargetId"] = "01", ["eventTargetName"] = "guide01"})
	end
end

-- local function AddGuideWithZOrder(szParam)
-- 	local UIDef = require("UIDef")
-- 	local UIManager = require("UIManager")
-- 	local StringUtil = require("StringUtil")
-- 	local tbParams = StringUtil.Split(szParam, " ")
-- 	local nOrder = tonumber(tbParams[1])
-- 	local Wnd = UIManager:GetWnd(UIDef.UI_GUIDE)
-- 	Wnd:AddToViewportWithZOrder(nOrder)
-- end

local function ShowWndList()
	local UIManager = require("UIManager")
	local tbWndList = UIManager:GetWndList()
	for k, v in pairs(tbWndList) do
		log("[WndList] WndName: " .. k)
	end
end

-- local function ShowGuideWnd(szParam)
-- 	local UIDef = require("UIDef")
-- 	local UIManager = require("UIManager")
-- 	local StringUtil = require("StringUtil")
-- 	local tbParams = StringUtil.Split(szParam, " ")
-- 	local bShow = tbParams[1]
-- 	local GuideWnd = UIManager:GetWnd(UIDef.UI_GUIDE)
--     if bShow == "false" then
--         GuideWnd.pWidgetRef:SetVisibility(ESlateVisibility.Collapsed)
--      else
--         GuideWnd.pWidgetRef:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
--     end
-- end

local function DumpSounds(szParam)
	-- luacheck: push ignore
	KismetSystemLibrary.ExecuteConsoleCommand(GWorld, "Log LogAudio All", nil)
	log("=============================================================")
	ExtendBlueprintFunctions.DumpActiveSounds(GWorld)
	log("=============================================================")
	-- luacheck: pop
end

local function ShowSelectPoint()
	local UIDef = require("UIDef")
	local UIManager = require("UIManager")
	UIManager:OpenWnd(UIDef.UI_FFA_SELECT_BORNPOINT)
end

local function ToggleVolume(szParam)
	local StringUtil = require("StringUtil")
	local tbParams = StringUtil.Split(szParam, " ")
	local nType = tonumber(tbParams[1])
	local nVolume = tonumber(tbParams[2])
	local AudioUtilityHelper = require("AudioUtilityHelper")
	if nType == 1 then
		AudioUtilityHelper.ToggleUISoundVolume (nVolume, GWorld)
	else
		AudioUtilityHelper.ToggleSFXSoundVolume(nVolume, GWorld)
	end
end

local function FlushLog()
    EngineExtShell.FlushLog()
end

local function SetLanguage(szParam)
	KismetInternationalizationLibrary.SetCurrentLanguage(szParam, true)

	local UIDef = require("UIDef")
	local UIManager = require("UIManager")
	UIManager:CloseWnd(UIDef.UI_DEBUG_WIDGET)
end

local function PrintPlayerVisible()
	local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
	local tbPlayerSelf = GamePlayerSelfHelper:Get()
	local pUEActor = tbPlayerSelf and tbPlayerSelf.pUEActor
	if pUEActor and tbPlayerSelf:IsHuman() then
		local szActorVisible = pUEActor.bHidden and "actor hidden" or "actor show"
		log(szActorVisible)
		printScreen(szActorVisible)
	end
end

local function PayTest(szParam)
	local ChannelSDKSystem = require("ChannelSDKSystem")
	local bResult = ChannelSDKSystem:EGSDKPay("com.seasungames.potc.gold1", "10金币", "买买买！", "2", "www.baidu.com", "100", "USD")
	log("===========pay bResult = " .. tostring(bResult))
	local UIDef = require("UIDef")
	local UIManager = require("UIManager")
	UIManager:CloseWnd(UIDef.UI_DEBUG_WIDGET)
end

local function UnlockSailorSlotOneKey()
	-- 一键解锁前要先确保钻石足够
	KismetSystemLibrary.ExecuteConsoleCommand(GWorld, "gm add-currency 1400001 100000", nil)

	local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
	local SailorComponent = GamePlayerSelfHelper:Get().SailorComponent
	if SailorComponent then
		SailorComponent:RequestUnlockSailorSlotOneKey()
	end
end

local function EquipSailorOneKey()
	local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
	local SailorComponent = GamePlayerSelfHelper:Get().SailorComponent
	if SailorComponent then
		SailorComponent:RequestSailorEquipOneKey()
	end
end

local function GetNetworkState()
	local eNetworkState = GamePlatformMiscLibrary.CheckNetState()
	local UIUtils = require("UIUtils")
	local szStateKey = ""
	if EGameNetState.DisconnectionState == eNetworkState then
		szStateKey = "Disconnection"
	elseif EGameNetState.WifiState == eNetworkState then
		szStateKey = "WIFI"
	else
		szStateKey = "Mobile"
	end
	UIUtils.ShowToast("===========Network State is=============== " .. szStateKey)
end

local function GetChannelID()
	local GlobalVariableSystem = dynamic_require("GlobalVariableSystem")
	local UIUtils = require("UIUtils")
	local pSdkManager = GlobalVariableSystem:GetChannelSdkManager()
	local szChannelID = pSdkManager:GetChannel()
	UIUtils.ShowToast("===========Channel ID is=============== " .. szChannelID)
end

local function SendTestDataToServer(szParam)
	local NetworkManager = dynamic_require("NetworkManager")
    local nDataSize = tonumber(szParam)

    if(GMSystem_C.SendTestDataTimer ~= nil) then
        GMSystem_C.SendTestDataTimer:Clear()
        GMSystem_C.SendTestDataTimer = nil
        GMSystem_C.fnSendTestDataFunc = nil
    end

    if(nDataSize <= 0) then
        return
    end

    GMSystem.fnSendTestDataFunc = function()
        local pRPC = NetworkManager:GetRPCNetworkProxy().pNetworkManager:GetClientRPCComponent()
        if(pRPC ~= nil) then
            pRPC:SendToServerTestData(nDataSize)
        end
    end

    GMSystem.SendTestDataTimer = require("Timer").NewTimer(GMSystem.fnSendTestDataFunc, 0.05, true)
end

local function cutout()
	printScreen("IsCutoutScreen " .. tostring(GamePlatformMiscLibrary.IsCutoutScreen()))
end

local function SetQuickLoading(szParam)
    local GlobalVariableSystem = dynamic_require("GlobalVariableSystem")
    GlobalVariableSystem.bQuickBattleLoading = szParam == "1"
end

local function StopSelectPointCondition(szParam)
	KismetSystemLibrary.ExecuteConsoleCommand(GWorld, "dm deletetimer MaxCDWaitTime", nil)
	KismetSystemLibrary.ExecuteConsoleCommand(GWorld, "dm setboolvalue INTER_GM_StopSelectPointCondition true", nil)
end

local function UseVehicleAcceleration(szParam)
	local bUse = szParam == '1'
	local UPFFAHuman = require("UPFFAHuman")
	UPFFAHuman.UseAcceleration(bUse)
end

local function EnableLogReport(szParam)
	local LogReportSystem = dynamic_require("LogReportSystem")
	LogReportSystem:SetEnabled(tonumber(szParam) == 1)
end

local function ShowChannelInfo(szParam)
	local ChannelSDKSystem = require("ChannelSDKSystem")
	local UIUtils = require("UIUtils")
	local eChannelID = ChannelSDKSystem:GetProtoChannelIDEnum()
	local ePlatform = ChannelSDKSystem:GetProtoPlatformEnum()
	UIUtils.ShowToast("===========EChannel is : " .. eChannelID .. "EPlatform is : " .. ePlatform .. "===========")
end

local function EnableNewAimAdsorption(szParam)
	local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
	local PlayerSelf = GamePlayerSelfHelper:Get()
	if PlayerSelf:IsHuman() then
		PlayerSelf.pUEActor.EnableNewAim = szParam == '1'
	end
end

local function AddToWndQueue(szParam)
	local StringUtil = require("StringUtil")
	local tbParams = StringUtil.Split(szParam, ' ')
	if #tbParams > 0 then
		local UIWndQueueHelper = require("UIWndQueueHelper")
		UIWndQueueHelper.AddWnd(tbParams[1])
	end
end

local function GameSpeed(szParam)
	local nSpeed = tonumber(szParam) or 1
	GameplayStatics.SetGlobalTimeDilation(GWorld, nSpeed)
	log("set speed " .. nSpeed .. " in client")
	KismetSystemLibrary.ExecuteConsoleCommand(GWorld, "dm gamespeed " .. nSpeed, nil)
end

local function LockJoyStick(szParam)
	local tbParams = {}
	for param in string.gmatch(szParam, "%d") do
		if param == "0" then
			table.insert(tbParams, false)
		else
			table.insert(tbParams, true)
		end
	end
	log(t2s(tbParams))
	local UPHumanVirtualJoystick = require("UPHumanVirtualJoystick")
	UPHumanVirtualJoystick.LockDirections(tbParams[1], tbParams[2], tbParams[3], tbParams[4])
end

local function SetMapPathDebug(szParam)
	local bDebug = szParam == '1'
	local GlobalVariableSystem = dynamic_require("GlobalVariableSystem")
	GlobalVariableSystem.bDebugMapPath = bDebug
end

local function FindPlayerInRange(szParam)
	local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
	local pUEActor = GamePlayerSelfHelper:Get()
	local GameObjectSystem = dynamic_require("GameObjectSystem")
	local pStart = pUEActor:GetLocation()
	local pRot = pUEActor:GetRotation()
	pRot = KismetMathLibrary.Conv_RotatorToVector(pRot)
	pRot = KismetMathLibrary.Normal(pRot, GDefaultTolerance)
	local x = pStart.X + pRot.X * 15000
	local y = pStart.Y + pRot.Y * 15000
	local z = pStart.Z + pRot.Z * 15000
	local pEnd = KismetMathLibrary.MakeVector(x,y,z)
	if pUEActor.pUEActor and pUEActor.pUEActor.MultiTraceObjects then
		local bReturnValue, tbOutHit = pUEActor.pUEActor:MultiTraceObjects(pStart, pEnd)
		if bReturnValue then
			for _, pOutHit in ipairs(tbOutHit) do
				local pPawn = GameObjectSystem:FindByUEActor(pOutHit.Actor)
				if pPawn then
					log(pPawn.szName)
				end
			end
		else
			log("not hit")
		end
	end
end

local function LogFilter(szParam)
	local szCommand = "Log global " .. szParam
	KismetSystemLibrary.ExecuteConsoleCommand(GWorld, szCommand, nil)
	SendGMCommandToDungeonServer("cmd " .. szCommand)
end

local function TestLineTrace(szParam)
	local StringUtil = require("StringUtil")
	local tbParams = StringUtil.Split(szParam, ' ')
	local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
	local pUEActor = GamePlayerSelfHelper:Get().pUEActor
	local nDistance = tonumber(tbParams[1])
	local nRadius = tonumber(tbParams[2])
	local pStart = pUEActor:GetEyePosition()
	local pCameraManager = GameplayStatics.GetPlayerCameraManager(GWorld, 0)
	local pRotation = pCameraManager:GetCameraRotation()
	local pEnd = KismetMathLibrary.Add_VectorVector(pStart, KismetMathLibrary.Multiply_VectorFloat(KismetMathLibrary.GetForwardVector(pRotation), nDistance))
	local nTraceDistance = ExtendBlueprintFunctions.GetCollisionDistance(pUEActor, nRadius, pStart, pEnd)
	log("client line trace distance ", nTraceDistance)
	local szCommand = tostring(nRadius) ..
	" " .. tostring(pStart.X) ..
	" " .. tostring(pStart.Y) ..
	" " .. tostring(pStart.Z) ..
	" " .. tostring(pEnd.X) ..
	" " .. tostring(pEnd.Y) ..
	" " .. tostring(pEnd.Z)
	log("testlinetrace " .. szCommand)
	SendGMCommandToDungeonServer("testlinetrace " .. szCommand)
end

local function SetU4LuaEnabled(szParam)
    ClientShell.GetClient(GWorld):SetUseU4LuaEnabled(type(szParam) == "string" and szParam == "1")
end

local function RotToTarget(szParam)
	local nInsId = tonumber(szParam)
	local CameraGameHelper = require("CameraGameHelper")
	local GameObjectSystem = dynamic_require("GameObjectSystem")
	local object = GameObjectSystem:FindByInstanceId(nInsId)
	CameraGameHelper.RotateToTarget(object.pUEActor:K2_GetActorLocation(), 0.5)
end

local function EnableGPerf(szParam)
	local GPerfSystem = require("GPerfSystem")
	local nFlag = tonumber(szParam)
	if nFlag == 1 then
		GPerfSystem:EnableByIntValue(1)
	else
		GPerfSystem:EnableByIntValue(0)
	end
end

local function StartGPerf(_szParam)
	local GPerfSystem = require("GPerfSystem")
	GPerfSystem:Start(true)
end

-- local function StartBattleGPerf(_szParam)
-- 	local GPerfSystem = require("GPerfSystem")
-- 	GPerfSystem:StartWithFinishedBySelfDead(true)
-- end

local function StopAndUploadGPerf(_szParam)
	local GPerfSystem = require("GPerfSystem")
	GPerfSystem:Stop()
	GPerfSystem:Upload()
end

local function SetGPerfLogUploadingMode(szParam)
	local GPerfSystem = require("GPerfSystem")
	GPerfSystem:SetLogUploadingMode(tonumber(szParam))
end

local function EnableGPerfPSO(_szParam)
	local GPerfPSOSystem = require("GPerfPSOSystem")
	GPerfPSOSystem:Enable()
end

local function ShowPlayerName(szParam)
	local bShow = szParam == '1'
	local GlobalVariableSystem = dynamic_require("GlobalVariableSystem")
	GlobalVariableSystem.bShowPlayerName = bShow
	local ClientEventDef = require("ClientEventDef")
	local EventManager = require("EventManager")
	EventManager:OnFireEvent(ClientEventDef.EV_SHOW_PLAYER_NAME_HEAD, bShow)
end

local function ShowPort(szParam)
	local StringUtil = require("StringUtil")
	local tbParams = StringUtil.Split(szParam, ' ')
	local bShow = tbParams[1] == '1'
	local nShowTime = tonumber(tbParams[2])
	local GlobalVariableSystem = dynamic_require("GlobalVariableSystem")
	GlobalVariableSystem.bDebugMapPath = bShow
	local MiniMapSystem = require("MiniMapSystem")
	MiniMapSystem:ShowPort(nShowTime)
end

local function ToogleMountainCheckDebug()
	local GlobalVariableSystem = dynamic_require("GlobalVariableSystem")
	GlobalVariableSystem.bPrintActorInfoWhenCheckMountain = not GlobalVariableSystem.bPrintActorInfoWhenCheckMountain
end

local function EnableNewJump(szParam)
	local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
	local PlayerSelf = GamePlayerSelfHelper:Get()
	if PlayerSelf:IsHuman() and PlayerSelf.pUEActor then
		PlayerSelf.pUEActor.CharacterMovement.bUseNewJump = not (szParam == "0")
	end
end

local function HideSelfActor()
	local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
	local pUEActor = GamePlayerSelfHelper:GetUEActor()
	if pUEActor then
		pUEActor:SetActorHiddenInGame(true)
	end
end

local function EnableGVoiceAllRoom(szParam)
	local bEnable = szParam ~= "0"
	local GVoiceSDKSystem = require("GVoiceSDKSystem")
	local GlobalVariableSystem = dynamic_require("GlobalVariableSystem")
	GlobalVariableSystem:EnableGVoiceAllRoom(bEnable)
	GVoiceSDKSystem:EnableMultiRoom(bEnable)
end

local function DisplayItems(szParam)
	local AwardSystem = require("AwardSystem")
    local tbItems = {}
    for param in string.gmatch(szParam, "%d*") do
        table.insert(tbItems, {template_id = tonumber(param), count = 1})
    end

	local tbPacket = {}
	tbPacket.award_addition = tbItems
	
	AwardSystem:OnRecvAwardNotification(tbPacket)
end

local function CloseCameraCollision(szParam)
	local bClose = szParam == '1'
	local GCMgr = GameplayStatics.GetPlayerCameraManager(GWorld, 0)
    local CameraActor = GCMgr:GetPlayerCameraActor()
	local pArm =  CameraActor:GetSpringArm()
	pArm.bDoCollisionTest = not bClose
end

local function EnableNewWatch(szParam)
	local bShow = szParam == '1'
	local GlobalVariableSystem = dynamic_require("GlobalVariableSystem")
	GlobalVariableSystem.bNewBattleWatch = bShow
end

local function ToogleCrosshairsDebug()
	local UIDef = require("UIDef")
	local UIManager = require("UIManager")
	UIManager:ToggleWnd(UIDef.UI_CROSSHAIRS_DEBUG)
end

local function MockLogin(szParam)
	-- local StringUtil = require("StringUtil")
	-- local tbParams = StringUtil.Split(szParam, ' ')
	-- local szToken = tbParams[1]
	-- local Proto = require("ClientProtoNames")
	-- local c2s_Login =
    -- {
    --     token = szToken,
	-- }
	-- SendPacket(Proto.c2s_Login, c2s_Login)
	-- local GlobalVariableSystem = dynamic_require("GlobalVariableSystem")
	-- local UIUtils = require("UIUtils")
	-- local pChannelSdkManager = GlobalVariableSystem:GetChannelSdkManager()
    -- if pChannelSdkManager then
	-- 	local szChannelID = pChannelSdkManager:GetChannel()
	-- 	UIUtils.ShowToast("===========channel id is =============== " .. szChannelID)
	-- end
	-- local StringUtil = require("StringUtil")
	-- local tbParams = StringUtil.Split(szParam, ' ')
	-- local szRate = tbParams[1]
	-- local GVoiceSDKSystem = require("GVoiceSDKSystem")
	-- GVoiceSDKSystem:SetBitRate(tonumber(szRate))
	-- ClientShell.GetClient(GWorld):TaskThreadTest(false)
	local EventManager = require("EventManager")
	local ClientEventDef = require("ClientEventDef")
	-- EventManager:OnFireEvent(ClientEventDef.EV_GUIDE_ALLINONE_TRIGGER)
	EventManager:OnFireEvent(ClientEventDef.EV_RELEASE_FIGHT_BTN)
end

local function ShowSpeed(szParam)
	local bShow = szParam ~= "0"
	local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
	local tbPlayer = GamePlayerSelfHelper:Get()
	local pUEActor = tbPlayer.pUEActor
	if tbPlayer and pUEActor and tbPlayer.HumanMovementStateComponent then
		if tbPlayer.HumanMovementStateComponent:IsInVehicle() then
			pUEActor = pUEActor.CurrentVehicle
		end
		if pUEActor and pUEActor.bShowSpeed ~= nil then
			pUEActor.bShowSpeed = bShow
		end
	end
end

local function RemoteLua(szParam)
    local szTemp = szParam == 'off' and "" or szParam
    CommonShell.SetRemoteLuaRepository(string.gsub(szTemp, '\"', ''))
end

local function PrintRequireCheckResult(szParam)
    printRequireCheckResult(szParam ~= nil and tonumber(szParam) or 0)
    PrintLuaMemory()
    printMemoryUsage(false)
end

local function SetShipVisibleDebugEnabled(szParam)
	local bEnabled = szParam == "1"
	local pGameInstance = GameplayStatics.GetGameInstance(GWorld)
    if pGameInstance and pGameInstance.GlobalSettings then
        pGameInstance.GlobalSettings.ShipVisibleDebugEnabled = bEnabled
    end
end


-- local function Retravel()
-- 	local GlobalVariableSystem  = require("GlobalVariableSystem_C")
-- 	local BattleGameModeSystem  = dynamic_require("BattleGameModeSystem")
-- 	local ProcedureTool = require("ProcedureTool")
-- 	local UIDef = require("UIDef")

--     ClientShell.GetClient(GWorld):GetDungeonShell():DisconnectFromDungeonServer(false)

-- 	local tbParam = {}
-- 	tbParam.nDungeonId = BattleGameModeSystem.nDungeonId
-- 	tbParam.szDungeonSessionId = BattleGameModeSystem:GetDungeonSessionId()
-- 	tbParam.bQuickBattleLoading = true
-- 	tbParam.bStandalone = false
-- 	tbParam.bRetraveling = true
-- 	tbParam.szLoadingWnd = UIDef.UI_WAIT_CONNECT_DIALOG

-- 	local tbEndParams = {}
-- 	tbEndParams.bRetraveling = true
-- 	ProcedureTool:EnterDungeon(tbParam, tbEndParams, true)

-- 	local szParam = GlobalVariableSystem.szLastTravelParam
-- 	BattleGameModeSystem.bRetraveling = true
-- 	log("RetravelToDS", szParam)
-- 	ClientShell.GetClient(GWorld):ClientTravel(szParam, false)
-- end

local function SetDisconnectRetravel(szParam)
	local bRetravel = szParam == "1"
	local GlobalVariableSystem  = require("GlobalVariableSystem_C")
	GlobalVariableSystem:SetDisconnectRetravel(bRetravel)
end

local function SetNetLogEnabled(szParam)
    local bEnabled = szParam ~= nil and szParam == "1"
    CommonShell.SetNetLogEnabled(bEnabled)
    SendGMCommandToDungeonServer("setnetlogenabled "..(bEnabled and "1" or "0"))
end

local function CheckShipShotCount(self)
	local ShipUtilityExHelper = require("ShipUtilityExHelper")
	ShipUtilityExHelper.CheckShipShotCount(GWorld)
end

local function CopyLogToSdcard(self)
	local UIUtils = require("UIUtils")
	UIUtils.ShowToast("Log copy result : " .. tostring(GamePlatformMiscLibrary.CopyLogToSdcard()))

end

local function SwitchToPCControlMode(szParam)
	local UIManager = require("UIManager")
	local UIDef = require("UIDef")
	local UI = UIManager:GetWnd(UIDef.UI_FFA_MAIN)
	UI:SwitchToPCControlMode(szParam == "1")
end

local function ShowDecoration(szParam)
	local UIDef = require("UIDef")
	local UIManager = require("UIManager")
	UIManager:OpenWnd(UIDef.UI_LOBBY_CAPTAIN_DECORATION)
end

local function AIDebugParam(szParam)
	local EventManager = require("EventManager")
	local ClientEventDef = require("ClientEventDef")
	EventManager:OnFireEvent(ClientEventDef.EV_AIDBUEG_PARAM, szParam)
end

local function EnableActorAsyncCreating(szParam)
    local GlobalVariableSystem_C = require("GlobalVariableSystem_C")
    local NetworkManager_C = require("NetworkManager_C")
    local bEnabled = szParam ~= nil and szParam == "1"
    GlobalVariableSystem_C.bEnableActorAsyncCreating = bEnabled
    NetworkManager_C:GetRPCNetworkProxy():SetActorAsyncCreatingEnabled(bEnabled)
end

local function ShowNewLobbyShip()
	local LobbyShip = require("LobbyShip")
	LobbyShip:Start()
end

local function AddAmmo(szParam)
	local nAmmoAmount = tonumber(szParam)

	local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
	local HumanWeaponMisc = require("HumanWeaponMisc")

	local PlayerSelf = GamePlayerSelfHelper:Get()
	local WeaponComponent = PlayerSelf.HumanWeaponComponent
	local tbWeapon = WeaponComponent:GetCurrentWeapon()
	local nType = tbWeapon:GetType()
	if nType == HumanWeaponMisc.Type.PROJECTILE or nType == HumanWeaponMisc.Type.INSTANT then
		tbWeapon:SetAmmoInfo(nAmmoAmount, nAmmoAmount)
	elseif nType == HumanWeaponMisc.Type.THROW then
		local BattleItemComponent = PlayerSelf.BattleItemComponentClient
		local nThrowItemId = tbWeapon:GetTemplateId()
		local Item = BattleItemComponent:GetUnequippedItems(nThrowItemId)
		if Item == nil then
			return
		end
		Item[1].nStackCount = nAmmoAmount
	end
	log("[WeaponCheat] set ammo amount", nAmmoAmount, "weapon type", nType)
end

local function SetAttackCD(szParam)
	local nCD = tonumber(szParam)
	local GlobalVariableSystem = dynamic_require("GlobalVariableSystem")
	GlobalVariableSystem.nAttackCDTime = nCD
	log("[WeaponCheat] set attack cd", nCD)
end

local function SetReloadCD(szParam)
	local nCD = tonumber(szParam)
	local GlobalVariableSystem = dynamic_require("GlobalVariableSystem")
	GlobalVariableSystem.nReloadCDTime = nCD
	log("[WeaponCheat] set reload cd", nCD)
end

local function SetHumanCheatSpeed(szParam)
	local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
	local PlayerSelf = GamePlayerSelfHelper:Get()
	local CheatSpeed = tonumber(szParam)
	if PlayerSelf.pUEActor and PlayerSelf:IsHuman() then
		log("CheatSpeed human ", CheatSpeed)
		PlayerSelf.pUEActor.CharacterMovement.DebugIllegalSpeed = CheatSpeed
	end
end

local function SetShipCheatSpeed(szParam)
	local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
	local PlayerSelf = GamePlayerSelfHelper:Get()
	local CheatSpeed = tonumber(szParam)
	if PlayerSelf.pUEActor and PlayerSelf:IsShip() then
		log("CheatSpeed ship ", CheatSpeed)
		PlayerSelf.pUEActor.ShipMovementComponent.DebugIllegalSpeed = CheatSpeed
	end
end

local function SetShipWeaponParamForCheat(szParam)
	local StringUtil = require("StringUtil")
	local tbParams = StringUtil.Split(szParam, " ")
	local GlobalVariableSystem = dynamic_require("GlobalVariableSystem")
	GlobalVariableSystem.bFixedShipWeaponParamEnabled = StringUtil.ToBool(tbParams[1])
	GlobalVariableSystem.nFixedShipWeaponFiringInterval = StringUtil.ToNumber(tbParams[2], 0)
	GlobalVariableSystem.nFixedShipWeaponLoadingInterval = StringUtil.ToNumber(tbParams[3], 0)
	log("GlobalVariableSystem.bFixedShipWeaponParamEnabled =", GlobalVariableSystem.bFixedShipWeaponParamEnabled)
	log("GlobalVariableSystem.nFixedShipWeaponFiringInterval =", GlobalVariableSystem.nFixedShipWeaponFiringInterval)
	log("GlobalVariableSystem.nFixedShipWeaponLoadingInterval =", GlobalVariableSystem.nFixedShipWeaponLoadingInterval)
end

local function LoadAllLobbySublevels(szParam)
	local bLoadAll = szParam ~= nil and szParam == "1"
	local GlobalVariableSystem = dynamic_require("GlobalVariableSystem")
	GlobalVariableSystem.bLoadAllLobbySublevel = bLoadAll
end

local function SetShipSoundEnabled(szParam)
	local GlobalVariableSystem = dynamic_require("GlobalVariableSystem")
	GlobalVariableSystem.bShipSoundEnabled = szParam == "1"
end

local function SetBlackScreenSpeed(szParam)
	local StringUtil = require("StringUtil")
	local BlackScreenHelper = require("BlackScreenHelper")
	local tbParams = StringUtil.Split(szParam, " ")
	local nInSpeed = StringUtil.ToNumber(tbParams[1])
	local nOutSpeed = StringUtil.ToNumber(tbParams[2])
	BlackScreenHelper.nBlackScreenInSpeed = nInSpeed
	BlackScreenHelper.nBlackScreenOutSpeed = nOutSpeed
end

local function ShowVehicleDebugLog(szParam)
    local bShow = szParam ~= "0"
    local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
    local tbPlayer = GamePlayerSelfHelper:Get()
    local pUEActor = tbPlayer.pUEActor
    if tbPlayer and pUEActor and tbPlayer.HumanMovementStateComponent then
        if tbPlayer.HumanMovementStateComponent:IsInVehicle() then
            pUEActor = pUEActor.CurrentVehicle
            if pUEActor and pUEActor.bShowDebugLog ~= nil then
                pUEActor.bShowDebugLog = bShow
            end
        end
    end
end

local function SetDOVisible(szParam)
	local bShow = szParam ~= "0"
	local GlobalVariableSystem = dynamic_require("GlobalVariableSystem")
	local GameObjectTypeDef = require("GameObjectTypeDef")
	local GameObjectSystem = dynamic_require("GameObjectSystem")
	GlobalVariableSystem.bDestructibleObjectVisible = bShow
	local tbAllObjs = GameObjectSystem:GetAllByObjectType(GameObjectTypeDef.DestructibleObject)
	for v, _ in pairs(tbAllObjs) do
		v.pUEActor:SetActorHiddenInGame(not bShow)
	end
end

local function TestHotPatch(szParam)
	local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
	local tbPlayer = GamePlayerSelfHelper:Get()
	if tbPlayer:IsHuman() then
		local pUEActor = tbPlayer.pUEActor
		pUEActor.AnimationSoundComponent:TestUpdate()
	end
	--log("test hot patch ok!")
	--ExtendBlueprintFunctions.TestShaderCoreReload()
end

local function AttachToVehicle(szParam)
	local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
	local HumanVehicleHelper = require("HumanVehicleHelper")
	local HumanVehicleStateDef = require("HumanVehicleStateDef")
	local tbPlayer = GamePlayerSelfHelper:Get()
	if szParam then
		HumanVehicleHelper.RequestVehicleState(HumanVehicleStateDef.AttachToVehicle, tonumber(szParam))
	else
		HumanVehicleHelper.RequestVehicleState(HumanVehicleStateDef.None, tbPlayer.GameVehicleComponent:GetVehicleInstanceId())
	end
end

local function SetBdrRotateVisible(szParam)
	local bVisible = szParam ~= "0"
	local UIManager = require("UIManager")
	local szTopWnd = UIManager:GetWndStackTop()
	if szTopWnd then
		local Wnd = UIManager:GetWnd(szTopWnd)
		if Wnd and Wnd.pWidgetRef and Wnd.pWidgetRef.bdrRotate then
			local pVisibility = bVisible and ESlateVisibility.Visible or ESlateVisibility.Collapsed
			Wnd.pWidgetRef.bdrRotate:SetVisibility(pVisibility)
		end
	end
end

local function ListLoadedPackages(szParam)
	KismetSystemLibrary.ExecuteConsoleCommand(GWorld, "ListLoadedPackages", nil)
end

local function SetShipFiringDebugEnabled(szParam)
	szParam = (szParam == "1") and szParam or "0"
	log("SetShipFiringDebugEnabled " .. szParam)
	KismetSystemLibrary.ExecuteConsoleCommand(GWorld, "dm setshipfiringdebugenabled "..szParam, nil)
	KismetSystemLibrary.ExecuteConsoleCommand(GWorld, "ShipMovement.DrawServerLocation "..szParam, nil)
end

local function NewMeleeCamera(szParam)
	local GlobalVariableSystem_C = require("GlobalVariableSystem_C")
	GlobalVariableSystem_C.bNewMeleeCamera = szParam == "1"
end

-- local function PlayMedia(szParam)
-- 	local MediaSystem = require("MediaSystem")
-- 	local UIDef = require("UIDef")
-- 	local StringUtil = require("StringUtil")
-- 	local UIManager = require("UIManager")
-- 	local tbParams = StringUtil.Split(szParam, " ")
-- 	local szId = tbParams[1]
-- 	szId = szId == nil and "1" or szId
-- 	local nId = tonumber(szId)
-- 	local szWndNameId = tbParams[2]
-- 	local szWndName
-- 	if szWndNameId == "1" then
-- 		szWndName = UIDef.UI_MEDIAPLAYER
-- 		MediaSystem:PlayMedia(nId, szWndName)
-- 	elseif szWndNameId == "2" then
-- 		szWndName = UIDef.UI_GUIDE
-- 		MediaSystem:PlayMedia(nId, szWndName)
-- 		local tbGuideWnd = UIManager:GetWnd(szWndName)
-- 		tbGuideWnd:ShowMediaPlayer("", false)
-- 	end
	

	
-- end

local function TestLog(szParam)
	local StringUtil = require("StringUtil")
	local tbParams = StringUtil.Split(szParam, " ")
	local nLines = StringUtil.ToNumber(tbParams[1])
	local nLogCatcherEnable = StringUtil.ToNumber(tbParams[2])

	LogCatcher.SetEnable(nLogCatcherEnable == 1)

	for i = 1, nLines do
		log("Test Data", i, "--------Test Info---------", i+1)
	end
end

local function RefreshOwningTorpedoColor()
	local ShipUtilityExHelper = require("ShipUtilityExHelper")
	ShipUtilityExHelper.RefreshOwningTorpedoColor(GWorld)
end

local function PrintTorpedoParam()
	local UIUtils = require("UIUtils")
	local UIResourceDef = require("UIResourceDef")
	local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
	local UIDef = require("UIDef")
	local UIManager = require("UIManager")

	local szShotActorClass = '/Game/Game/ShipEx/Shot/ShotActor/BP_TorpedoShotBase.BP_TorpedoShotBase_C'
	local pUEActor = GamePlayerSelfHelper:GetUEActor()
    local tbShotActors = GameplayStatics.GetAllActorsOfClass(GWorld, szShotActorClass:load())
	for _,v in ipairs(tbShotActors) do
		local pParticle = v.PS_Ball
		local nTranslucencySortPriority = pParticle.TranslucencySortPriority
		local nDistance = v:GetDistanceTo(pUEActor) / 100
		local bTeammate = v:IsInstigatorTeammate(pUEActor)
		local bActive = pParticle:IsActive()
		local bVisible = pParticle:IsVisible()
		local bHiddenInGame = pParticle.bHiddenInGame
		local szMessage = string.format("[Torpedo] nTranslucencySortPriority:%d, nDistance:%fm, bTeammate:%s, bActive:%s, bVisible:%s, bHiddenInGame:%s", nTranslucencySortPriority, nDistance, bTeammate, bActive, bVisible, bHiddenInGame)
		printScreen(szMessage)
		log(szMessage)
		UIUtils.PrintScreen(szMessage, 20, UIResourceDef.COLOR.YELLOW.SLATE_COLOR)
	end
	
	UIManager:ToggleWnd(UIDef.UI_CROSSHAIRS_DEBUG)
end

-- local function ShowDoorInfo(self)
-- 	local GameObjectSystem = dynamic_require("GameObjectSystem")
-- 	local GameObjectTypeDef = require("GameObjectTypeDef")
-- 	local DestructibleObjectNewDataTable = require("DestructibleObjectNewDataTable")
-- 	local GameDestructibleObjectType = require("GameDestructibleObjectType")
-- 	local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
-- 	local pSelfVector = GamePlayerSelfHelper:Get():GetLocation()
--     local tbAllObjs = GameObjectSystem:GetAllByObjectType(GameObjectTypeDef.DestructibleObject)
-- 	for v, _ in pairs(tbAllObjs) do
-- 		local tbDestructibleData = DestructibleObjectNewDataTable:GetTemplate(v.nTemplateId)
-- 		if tbDestructibleData ~= nil and tbDestructibleData.nType == GameDestructibleObjectType.Door then
-- 			local pVector = v:GetLocation()
-- 			local nDistance  = ExtendBlueprintFunctions.GetVectorToVectorDistance(pSelfVector, pVector)
-- 			if nDistance <= 1000 then
-- 				local s = v:GetScale3D()
-- 				log("[door] ", pVector.X, pVector.Y, pVector.Z, s.X, s.Y, s.Z)
-- 			end
-- 		end
-- 	end
-- end


local function LobbyAwardWatering(szParam)
	local LobbySystem = require("LobbySystem")
	local LobbySubTypeDef = require("LobbySubTypeDef")
	local tbSub = LobbySystem:GetActiveSub()
	if tbSub and tbSub.nSubType == LobbySubTypeDef.AWARD then
		if szParam == "0" then
			tbSub:StopWateringPostProcessEffect()
		elseif szParam == "1" then
			tbSub:PlayWateringPostProcessEffect()
		else
			local StringUtil = require("StringUtil")
			local tbParams = StringUtil.Split(szParam, ' ')
			local pWateringEffect = tbSub:GetWateringEffectObj()
			if tbParams[1] == "AlwaysStartFromZero" then
				pWateringEffect.bAlwaysStartFromZero = tbParams[2] ~= "0"
			elseif tbParams[1] == "EaseOut" then
				pWateringEffect.bEaseOut = tbParams[2] ~= "0"
			end
		end
	end
end

local GameCameraShakeHelper 
local function PlayGameShake(szParam)
	local nId = tonumber(szParam)
	if not GameCameraShakeHelper then
		GameCameraShakeHelper = require("GameCameraShakeHelper")
	end
	GameCameraShakeHelper.GameShake(nId)
end

local function PlayExperienceSound(szParam)
	local StringUtil = require("StringUtil")
	local SoundExperienceHelper = require("SoundExperienceHelper")
	local tbParams = StringUtil.Split(szParam, ' ')
	for _, szId in ipairs(tbParams) do
		SoundExperienceHelper:PlaySound(tonumber(szId))
	end
end
-- luacheck: push ignore
local function PlayAbilityPostProcess(szParam)
	local BattleAbilitySystem = require("BattleAbilitySystem")
	local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
	local nHandle = BattleAbilitySystem:PlayPostProcessEffect(GamePlayerSelfHelper:Get(), tonumber(szParam))
	logdebug("PlayAbilityPostProcess", nHandle)
end

local function StopAbilityPostProcess(szParam)
	local BattleAbilitySystem = require("BattleAbilitySystem")
	local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
	local nHandle = tonumber(szParam)
	BattleAbilitySystem:StopPostProcessEffect(GamePlayerSelfHelper:Get(), nHandle)
	logdebug("StopAbilityPostProcess", nHandle)
end
-- luacheck: pop

local function CDFire(szParam)
	local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
	local Timer = require("Timer")

	local nCDTime = tonumber(szParam)

	local firefunction = nil
	local PlayerSelf = GamePlayerSelfHelper:Get()
	if PlayerSelf:IsShip() then
		firefunction = function(...)
		    local BattleShipWeaponSystem = dynamic_require("BattleShipWeaponSystem")
		    local ShipFiringOperationDef = require("ShipFiringOperationDef")
    
		    BattleShipWeaponSystem:RequestFire(ShipFiringOperationDef.START)
		end
	else
		firefunction = function(...)
			PlayerSelf.HumanWeaponComponent:StartAttack()
		end
	end

	if tbAllLocalVars.tbCDFireTimer ~= nil then
		tbAllLocalVars.tbCDFireTimer:Clear()
		tbAllLocalVars.tbCDFireTimer = nil
	end

	if nCDTime > 0 then
		tbAllLocalVars.tbCDFireTimer = Timer.NewTimer(firefunction, nCDTime, true)
	end
end

local function StartDownloadTest(szParam)
	local DownloadTest = require("DownloadTest")
	local StringUtil = require("StringUtil")
	local tbParams = StringUtil.Split(szParam, ' ')
	if tbParams[1] == "1" then
		DownloadTest.Start(tbParams[2], tonumber(tbParams[3]), tbParams[4])
	else
		DownloadTest.Cancel()
	end
end

-- Put function in tbAllLocalVars to avoid error: too many local variables (limit is 200) in main function near '('. 
tbAllLocalVars.EnableDLC = function(szParam)
	local StringUtil = require("StringUtil")
	local SaveGameDef = require("SaveGameDef")
	local bEnabled = StringUtil.ToBool(szParam)
	local pSaveGameMgr = ClientShell.GetClient(GWorld):GetSaveGameManager()
	pSaveGameMgr:AddBoolData(SaveGameDef.ENABLE_DLC, bEnabled)
	pSaveGameMgr:Save()
	log("Enable DLC : ", bEnabled)
	printScreen("Enable DLC : ", bEnabled)
end

tbAllLocalVars.DlcInstallChunk = function(szParam)
	local DLCSystem = require("DLCSystem")
	local nChunkID = tonumber(szParam)
	DLCSystem:InstallChunk(nChunkID)
end

tbAllLocalVars.DlcUnistallChunk = function(szParam)
	local DLCSystem = require("DLCSystem")
	local nChunkID = tonumber(szParam)
	DLCSystem:UninstallChunk(nChunkID)
end

tbAllLocalVars.DlcCancelInstall = function(szParam)
	local DLCSystem = require("DLCSystem")
	local nChunkID = tonumber(szParam)
	if nChunkID then
		DLCSystem:CancelInstallChunk(nChunkID)
	else
		DLCSystem:CancelAllInstall()
	end
end

tbAllLocalVars.DlcIsChunkInstalled = function(szParam)
	local DLCSystem = require("DLCSystem")
	local nChunkID = tonumber(szParam)
	local bInstalled = DLCSystem:IsChunkInstalled(nChunkID)
	log("DLC Chunk ", nChunkID, " is installed: ", bInstalled)
    printScreen("DLC Chunk ", nChunkID, " is installed: ", bInstalled)
end

tbAllLocalVars.EnableSoundTest = function (szParam)
	local ClientEventDef = require("ClientEventDef")
	local EventManager = require("EventManager")
	local GamePlayerSelfHelper = require("GamePlayerSelfHelper")

	local func = function(...) 
	     local tbPlayer = GamePlayerSelfHelper:Get()
	     local szSoundResPath = "SoundCue'/Game/SoundCues/Effect/SC_AssaultGun_End.SC_AssaultGun_End'"
	     local pSound = szSoundResPath:load()
	     local pLocation = tbPlayer:GetLocation()
	     ExtendBlueprintFunctions.PlaySoundInClient(GWorld, pSound, 1, pLocation,
	         tbPlayer.pUEActor)
	end

	EventManager:BindEvent(ClientEventDef.EV_APP_WILL_DEACTIVE, func)
	EventManager:BindEvent(ClientEventDef.EV_APP_WILL_ENTER_BACKGROUND, func)
	EventManager:BindEvent(ClientEventDef.EV_APP_HAS_ENTERED_FOREGROUND, func)
end

function GMSystem_C:RegisterCommands()
	GMSystem_C.super.RegisterCommands(self)
	-- self:Register("PrintGameObjectInfo", PrintGameObjectInfo)
	-- self:Register("SwitchNetLog", SwitchNetLog)
	self:Register("gm", SendGMCommandToHubServer)
	self:Register("PrintItemInfo", PrintItemInfo)
	self:Register("dm", SendGMCommandToDungeonServer)
	self:Register("fakecrash", FakeCrash)
	self:Register("logcat", LogCat)
	self:Register("mock", Mock)
	self:Register("enterlocaldungeon", EnterLocalDungeon)
	self:Register("collectnpcdata", CollectNpcData)
	self:Register("testexplorer", TestSocietyExplorer)
	self:Register("interaction", Interaction)
    self:Register("flushshipres", FlushShipRes)
	self:Register("updatehumanavatar", UpdateHumanAvatar)
	self:Register("testaccessory", TestAccessory)
	self:Register("quitdungeon", QuitDungeon)
	self:Register("leavedungeon", LeaveDungeon)
	self:Register("restartgame", RestartGame)
	self:Register("PlayAnimMontage", PlayAnimMontage)
	self:Register("luamem", PrintLuaMemory)
	self:Register("luagc", GC)
	self:Register("printluaref", PrintLuaReferenced)
	self:Register("setcinematicmode", SetCinematicMode)
	self:Register("showplayercount", ShowPlayerCount)
	self:Register("debugwnd", ShowDebugWidget)
	self:Register("artopen", ArtOpen)
	self:Register("retrygame", RetryGame)
	self:Register("enabledebuglog", EnableDebugLog)
	self:Register("togglefps", ToggleFPS)
	self:Register("SensitiveWordsSystem", SensitiveWordsSystemTest)
	self:Register("hubserverip", SetHubServerIp)
	self:Register("ShowMessageBox", ShowMessageBox)
	self:Register("DumpRenderTexture", DumpRenderTexture)
	self:Register("PlayAnimation", PlayAnimation)
	self:Register("CrashRenderThread", CrashRenderThread)
	self:Register("OpenAssociationUI", OpenAssociationUI)
	self:Register("battlegroundmatchmakingstat", BattlegroundMatchmakingStat)
	-- self:Register("testgetpvestats", TestGetPvEStats)
	-- self:Register("testgetpvpstats", TestGetPvPStats)
	self:Register("testgetrecentbattlerecords", TestGetRecentBattleRecords)
	self:Register("testsendlocalbattlestats", TestSendLocalBattleStats)
	self:Register("skiptutorial", skiptutorial)
	self:Register("questtownportal", questtownportal)
	--self:Register("newlua", EnableNewLua)
	self:Register("luadebug", LuaDebug)
	self:Register("xsj", SetXSJEngineFeatureEnabled)
	self:Register("location", PrintSelfLocation)
	self:Register("showMulticast", ShowReliableMulticast)
	self:Register("headlesstravel", HeadlessTravel)
	self:Register("dumpShipConfig", DumpShipConfig)
	self:Register("loadingscreen", LoadingScreen)
	self:Register("ffajump", FFAJumpFromTransporter)
	self:Register("builditem", BuildItem)
	self:Register("unequipitem", EnequipBattleItem)
	self:Register("equipitem", EquipBattleItem)
	self:Register("equipstackableitem", EquipStackableBattleItem)
	self:Register("exchangestoragelocation", ExchangeStorageLocation)
	self:Register("pickitem", PickItem)
	self:Register("throwitem", ThrowItem)
	self:Register("throwandpickupitem", ThrowAndPickupItem)
	self:Register("beginviewitem", BeginViewItem)
	self:Register("endviewitem", EndViewItem)
	-- self:Register("setsceneitemviewdistance", SetSceneItemViewDistance)
	-- self:Register("setfogvisible", SetFogVisible)
	self:Register("toggleBack", ToggleBack)
	self:Register("testUpdate", TestUpdate)
	self:Register("ignoretcperror", IgnoreTcpError)
	self:Register("sethumanweaponproperty", SetHumanWeaponProperty)
	self:Register("testSound", TestSound)
	self:Register("gtaenablelog", GTAEnableLog)
	self:Register("enablebattleautotest", EnableBattleTestAutomation)
	self:Register("startmatchmaking", StartMatchmaking)
	self:Register("showaimsphere", ShowAimSphere)
	self:Register("detachcamera", DetachCamera)
	self:Register("reattachcamera", AttachCamera)
    self:Register("printtemplateactorinfo", PrintTemplateActorInfo)
	self:Register("sendmsgtofriend", SendMsgToFriend)
	self:Register("enterhome", EnterHomeland)
	self:Register("homelandswitchscene", HomelandSwitchScene)
	self:Register("homelandplacebuilding", PlaceBuilding)
	self:Register("homelandremovebuilding", RemoveBuilding)
	self:Register("homelandenableblock", HomelandEnableBlock)
    self:Register("debugtemplateactor", DebugTemplateActor)
	self:Register("landmarkupgrade", LandmarkUpgrade)
	self:Register("homelandcreatebuilding", HomelandCreateBuilding)
	self:Register("homelandremovebuilding", HomelandRemoveBuilding)
	self:Register("switchhomescene", SwitchHomeScene)
    self:Register("shownotifaction", ShowNotifaction)
    self:Register("testlua", TestLua)
	self:Register("printrepinfo", PrintRepInfo)
	self:Register("beginguide", BeginGuide)
	self:Register("debugaudio", DebugAudio)
	self:Register("reloadlua", ReloadLua)
	self:Register("setmappinch", SetMapPinch)
	self:Register("closeguide", CloseGuide)
	self:Register("quitgame", QuitGame)
	self:Register("enablemic", EnableMic)
	self:Register("showwndlist", ShowWndList)
	self:Register("calldatasdk", calldatasdk)
	-- self:Register("showguidewnd", ShowGuideWnd)
	self:Register("activesounds", DumpSounds)
	self:Register("showselectpoint", ShowSelectPoint)
    self:Register("togglevolume", ToggleVolume)
    self:Register("flushgamelog", FlushLog)
    self:Register("pirates", Pirates)
    -- self:Register("defaultpickup", DefaultPickUpCollision)
    -- self:Register("printsceneitem", PrintSceneItem)
    self:Register("sendtestdatatoserver", SendTestDataToServer)
	self:Register("setlanguage", SetLanguage)
	self:Register("cutout", cutout)
	self:Register("printplayervisible", PrintPlayerVisible)
	self:Register("paytest", PayTest)
	self:Register("unlock_sailor_slot_one_key", UnlockSailorSlotOneKey)
	self:Register("equip_sailor_one_key", EquipSailorOneKey)
    self:Register("getnetworkstate", GetNetworkState)
	self:Register("quickloading", SetQuickLoading)
	self:Register("getchannelid", GetChannelID)
	self:Register("stopselectpointcondition", StopSelectPointCondition)
	self:Register("showchannelinfo", ShowChannelInfo)
	self:Register("logreport", EnableLogReport)
	self:Register("usevehicleaccleration", UseVehicleAcceleration)
	self:Register("enablenewaim", EnableNewAimAdsorption)
	self:Register("addtowndqueue", AddToWndQueue)
	self:Register("gamespeed", GameSpeed)
	self:Register("lockjoystick", LockJoyStick)
	self:Register("endcurrentstep", EndCurrentStep)
	self:Register("begincurrentstep", BeginCurrentStep)
	self:Register("mappathdebug", SetMapPathDebug)
	self:Register("findplayerinrange", FindPlayerInRange)
	self:Register("logfilter", LogFilter)
    self:Register("testlinetrace", TestLineTrace)
    self:Register("setu4luaenabled", SetU4LuaEnabled)
	self:Register("rottotarget", RotToTarget)
	self:Register("toggleBotAim", ToggleBotAim)
	self:Register("enablegperf", EnableGPerf)
	self:Register("startgperf", StartGPerf)
	-- self:Register("startbattlegperf", StartBattleGPerf)
	self:Register("stopanduploadgperf", StopAndUploadGPerf)
	self:Register("setgperfloguploadingmode", SetGPerfLogUploadingMode)
	self:Register("enablegperfpso", EnableGPerfPSO)
	self:Register("showplayername", ShowPlayerName)
	self:Register("showport", ShowPort)
	self:Register("tooglemountaincheckdebug", ToogleMountainCheckDebug)
	self:Register("enablenewjump", EnableNewJump)
	self:Register("hideselfactor", HideSelfActor)
	self:Register("displayitems", DisplayItems)
	self:Register("enablegvoiceallroom", EnableGVoiceAllRoom)

	self:Register("closecameracollision", CloseCameraCollision)

	self:Register("toggleBotByIndex", ToggleBotByIndex)
	self:Register("toggleBotById", ToggleBotById)
	self:Register("enableReplicatedLog", EnableReplicatedLog)
	self:Register("memSnapshotDump", MemSnapshotDump)
	self:Register("printMem", PrintMem)

	self:Register("enablewatch", EnableNewWatch)
	self:Register("togglecrosshairsdebug", ToogleCrosshairsDebug)

	self:Register("mocklogin", MockLogin)

	self:Register("showspeed", ShowSpeed)
    self:Register("remotelua", RemoteLua)
    self:Register("printRequireCheckResult", PrintRequireCheckResult)
    self:Register("setshipvisibledebugenabled", SetShipVisibleDebugEnabled)
	-- self:Register("retravel", Retravel)
    self:Register("disconnectretravel", SetDisconnectRetravel)
    self:Register("setnetlogenabled", SetNetLogEnabled)
    self:Register("checkshipshotcount", CheckShipShotCount)
	self:Register("copylogtosdcard", CopyLogToSdcard)
    self:Register("testsavegame", TestSaveGame)
    self:Register("switchtopc", SwitchToPCControlMode)
    self:Register("aidebugparam", AIDebugParam)
	self:Register("enableactorasynccreating", EnableActorAsyncCreating)
	self:Register("shownewlobbyship", ShowNewLobbyShip)
	self:Register("addammo", AddAmmo)
	self:Register("setattackcd", SetAttackCD)
	self:Register("showdecoration", ShowDecoration)
	self:Register("sethumancheatspeed", SetHumanCheatSpeed)
	self:Register("setshipcheatspeed", SetShipCheatSpeed)
	self:Register("setshipweaponparamforcheat", SetShipWeaponParamForCheat)
	self:Register("setreloadcd", SetReloadCD)
	self:Register("loadalllobbysublevels", LoadAllLobbySublevels)
	self:Register("setshipsoundenabled", SetShipSoundEnabled)
    self:Register("setblacksreenspeed", SetBlackScreenSpeed)
	self:Register("vehicledebug", ShowVehicleDebugLog)
	self:Register("testhotpatch", TestHotPatch)
	self:Register("setdovisible", SetDOVisible)
	self:Register("setbdrrotatevisible", SetBdrRotateVisible)
	self:Register("attachtovehicle", AttachToVehicle)
	self:Register("listloadedpackages", ListLoadedPackages)
	self:Register("setshipfiringdebugenabled", SetShipFiringDebugEnabled)
	self:Register("newmeleecamera", NewMeleeCamera)
	-- self:Register("playmedia", PlayMedia)
	self:Register("testlog", TestLog)
	self:Register("refreshowningtorpedocolor", RefreshOwningTorpedoColor)
	self:Register("printtorpedoparam", PrintTorpedoParam)
	-- self:Register("showdoorinfo", ShowDoorInfo)
	self:Register("lobbyawardwatering", LobbyAwardWatering)
	self:Register("playgameshake", PlayGameShake)
	self:Register("playexperiencesound", PlayExperienceSound)
	self:Register("playabilitypostprocess", PlayAbilityPostProcess)
	self:Register("stopabilitypostprocess", StopAbilityPostProcess)
	self:Register("cdfire", CDFire)
	self:Register("startdownloadtest", StartDownloadTest)
	self:Register("dlcenable", tbAllLocalVars.EnableDLC)
	self:Register("dlcinstallchunk", tbAllLocalVars.DlcInstallChunk)
	self:Register("dlcuninstallchunk", tbAllLocalVars.DlcUnistallChunk)
	self:Register("dlccancelinstall", tbAllLocalVars.DlcCancelInstall)
	self:Register("dlcischunkinstalled", tbAllLocalVars.DlcIsChunkInstalled)
	self:Register("enablesoundtest", tbAllLocalVars.EnableSoundTest)
end

function GMSystem_C:Init()
	GMSystem_C.super.Init(self)
	TryLoadXSJEngineFeatureSwitch()
    return true
end

function GMSystem_C:Uninit()
	-- if tbLocationHandle ~= nil then
	-- 	tbLocationHandle:Clear()
	-- 	tbLocationHandle = nil
	-- end
	GMSystem_C.super.Uninit(self)
end

-- @Override
function GMSystem:IsEnabled()
	local GlobalVariableSystem = dynamic_require("GlobalVariableSystem")
    return GlobalVariableSystem:IsDevMode()
end

return GMSystem_C()
