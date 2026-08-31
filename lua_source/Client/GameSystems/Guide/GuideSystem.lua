-----------------------------------------------------
--File Name    : GuideSystem.lua
--Author       : Edward J
--Create Time  : 2019-05-08
--Description  : 新手指引
-----------------------------------------------------
local GuideSystem = {}

local UIManager                 = require("UIManager")
local UIDef                     = require("UIDef")
local GuideModule               = require("GuideModule")
local GuideDebug                = require("GuideDebug")
local GuideDataTable            = require("GuideDataTable")
local GuideBattleDataTable      = require("GuideBattleDataTable")
local GuideModuleDataTable      = require("GuideModuleDataTable")
local dkjson                    = require("dkjson")
local StringUtil                = require("StringUtil")
local ClientEventDef            = require("ClientEventDef")
local SelfEventHelper           = require("SelfEventHelper")
local Proto                     = require("ClientProtoNames")
local NetworkManager            = dynamic_require("NetworkManager")
local GlobalVariableSystem      = dynamic_require("GlobalVariableSystem")
-- local ProtoDR                   = require("DungeonRepProtoNames")
local DelayTimer                = require("DelayTimer")
local GMSystem                  = dynamic_require("GMSystem")
local LuaClassHelper            = require("LuaClassHelper")
local CommonEventDef            = require("CommonEventDef")
local GameObjectTypeDef         = require("GameObjectTypeDef")
local ChannelSDKSystem          = require("ChannelSDKSystem")
local GamePlayerSelfHelper      = require("GamePlayerSelfHelper")
local SettingSystemNew          = require("SettingSystemNew")
local SettingClassType          = require("SettingClassType")
local SettingLayoutFromDef      = require("SettingLayoutFromDef")
local BattleGameModeSystem      = dynamic_require("BattleGameModeSystem")
local TutorialDungeonIni        = require("TutorialDungeonIni")
local GuideSingleDataTable      = require("GuideSingleDataTable")
local CameraGameHelper          = require("CameraGameHelper")
local ResourceManager           = require("ResourceManager")
-----------------------------------------------------
local bClearSaveData        = false
local SINGLEBATTLE          = 0
local LOBBY                 = 1
local BATTLE                = 2
local NOTFINISH             = -1
local FINISH                = 1
local GUIDEMODULELIMIT      = 200
local GUIDEBATTLEMODULELIMIT= 300
local DEFAULT_LAYOUT_SCALE  = Vector2D{X = 1, Y = 1}
local UI_GUIDE_PATH         = "/Game/UI/FFA/Wnd/Guide/UI_Guide.UI_Guide_C"
local TARGET_LOBBY_WND      = {
    ["UI_LobbyCaptain"] = 0,
    ["UI_LobbyShipOverview"] = 0,
    ["UI_LobbySailorMain"] = 0,
    ["UI_Season"] = 0,
}
local TRAINING_DUNGEON_ID = 110001


--member veriable
GuideSystem.bIsOpen                 = true
GuideSystem.bInGuideProgress        = false
GuideSystem.bNewRole                = false
GuideSystem.tbGuideData             = nil  -- 用于记录正在运行的引导 模块、组的标识，用于存储引导记录
GuideSystem.tbBattleGuideData       = nil  -- 用于记录正在运行的引导 模块、组的标识，用于存储引导记录
GuideSystem.tbModules               = nil  -- 记录当前场景的引导模块类，其中都是正在运行的引导事例类
GuideSystem.nSkipGuide              = -1
GuideSystem.EventHelper             = nil
GuideSystem.nEnterBattleCount       = nil
GuideSystem.nSceneId                = SINGLEBATTLE
GuideSystem.DelayTimerHandle        = nil
GuideSystem.tbStripGroupTab         = nil
GuideSystem.tbAllwaystriggerData    = nil
GuideSystem.pUIResource             = nil
GuideSystem.tbTargetLobbyUIOpened   = nil
-----------------------------------------------------

local function ClearDelayTimer(self)
    self:DebugLog("ClearDelayTimer")
    local DelayTimerHandle = self.DelayTimerHandle
    if DelayTimerHandle then
        DelayTimer:ClearTimer(DelayTimerHandle)
    end
    self.DelayTimerHandle = nil
end

local function HoldUIResource(self)
    self:DebugLog("HoldUIResource")
    if not self.pUIResource then
        self.pUIResource = ResourceManager:LoadSync(UI_GUIDE_PATH, true)
    end
end

local function UnHoldUIResource(self)
    self:DebugLog("UnHoldUIResource")
    if self.pUIResource then
        self.pUIResource = ResourceManager:Unhold(self.pUIResource)
        self.pUIResource = nil
    end
end

local function IsTargetUI(self, szWndName)
    self:DebugLog("IsTargetUI szWndName = " .. szWndName)
    local result = TARGET_LOBBY_WND[szWndName]
    return result ~= nil
end

local function OnOpenUI(self, szWndName)
    self:DebugLog("OnOpenUI szWndName = " .. szWndName)
    local result = IsTargetUI(self, szWndName)
    if not result then
        return
    end
    if not self.tbTargetLobbyUIOpened then
        self.tbTargetLobbyUIOpened = {}
    end
    self.tbTargetLobbyUIOpened[szWndName] = 0
end

function GuideSystem:GetOpenedModuleData(tbAllModules)
    self:DebugLog("GetOpenedModuleData")
    local tbTemp = {}
    for nModuleId, v in pairs(tbAllModules) do
        self:DebugLog(" GetOpenedModuleData nModuleId = " .. nModuleId .. " TYPE = " .. type(nModuleId))
        local tbTemplate = GuideModuleDataTable:GetTemplate(nModuleId)
        if tbTemplate then
            if tbTemplate.nOpenOnStart then
                local tbGroup = LuaClassHelper.DeepCopyTable(v)
                tbTemp[nModuleId] = tbGroup
            end
        end
    end
    return tbTemp
end

function GuideSystem:GetAllOpenedModuleData()
    self:DebugLog("GetAllOpenedModuleData")
    local tbAllModules = GuideDataTable:GetAllModules()
    local tbBattleAllModules = GuideBattleDataTable:GetAllModules()
    local tbTemp = {}
    local tbTempBattle = {} --等待局内引导表
    tbTemp = self:GetOpenedModuleData(tbAllModules)
    tbTempBattle = self:GetOpenedModuleData(tbBattleAllModules)
    return tbTemp, tbTempBattle
end

function GuideSystem:GetSingleGuideData()
    -- local tbSingleModules = SingleGuideDataTable:GetAllModules()
    -- return tbSingleModules
end

function GuideSystem:GetModuleData(tbData)
    self:DebugLog("GetModuleData")
    local tbOpenedModule = {}
    local tbBattleOpenedModule = {}
    local tbAllwaystriggerData = {}
    local tbSaveData = self:RecoverGuideProgress(tbData)
    self:DebugLog("tbSaveData is " .. tostring(tbSaveData))
    if tbSaveData then
        local tbGuideData = tbSaveData.tbGuideData
        if tbGuideData then
            local tbModules = GuideDataTable:GetModules(tbGuideData)
            tbOpenedModule = LuaClassHelper.DeepCopyTable(tbModules)
        end
        local tbBattleGuideData = tbSaveData.tbBattleGuideData
        if tbBattleGuideData then
            local tbModules = GuideBattleDataTable:GetModules(tbBattleGuideData)
            tbBattleOpenedModule = LuaClassHelper.DeepCopyTable(tbModules) --局内引导表的相关功能
        end
        tbAllwaystriggerData = tbSaveData.tbAllwaystriggerData
        self.tbTargetLobbyUIOpened = tbSaveData.tbTargetLobbyUIOpened
    else
        tbOpenedModule, tbBattleOpenedModule = self:GetAllOpenedModuleData()
    end
    return tbOpenedModule, tbBattleOpenedModule, tbAllwaystriggerData
end

function GuideSystem:Init()
    --读取guide表
    self:DebugLog("Init System is open : " .. tostring(self.bIsOpen))
    if not self.bIsOpen then
        return
    end
    self.tbModules = {}
    self.tbStripGroupTab = {}
    self.nEnterBattleCount = -1
    self.ServerProxy = NetworkManager:GetHubServerProxy()
    self:BindEvent()
    -- HoldUIResource(self)
    -- self:OpenDebug(GlobalVariableSystem:IsDevMode())
    self:OpenDebug(true)
    if GlobalVariableSystem.bMock then
        GuideSystem:SetStripGroups(300, 2)
    end
end

function GuideSystem:Uninit()
    self:DebugLog("Uninit")
    self:End()
    self:UninitModule()
    self:UnbindEvent()
    ClearDelayTimer(self)
    UnHoldUIResource(self)
    self.tbModules = nil
    self.EventHelper = nil
    self.tbGuideData = nil
    self.tbBattleGuideData = nil
    self.tbStripGroupTab = nil
    self.tbAllwaystriggerData = nil
    self.bNewRole = false
end

function GuideSystem:UninitModule()
    self:DebugLog("UninitModule")
    local nSceneId = self.nSceneId
    if not self.tbModules then
        return
    end
    local tbModules = self.tbModules[nSceneId]
    if not tbModules then
        return
    end
    for nModule, ModuleClass in pairs(tbModules) do
        ModuleClass:Uninit()
    end
    self.tbModules[nSceneId] = {}
end

function GuideSystem:GM_Begin(nModuleId)
    self:DebugLog("GM_Begin")
    if not nModuleId then
        return
    end
    local tbTemp = {}
    self.tbGuideData = {}
    self.tbBattleGuideData = {}
    self.tbModules = {}
    self.nEnterBattleCount = 0
    if nModuleId >= GUIDEMODULELIMIT and nModuleId < GUIDEBATTLEMODULELIMIT then
        tbTemp[nModuleId] = GuideBattleDataTable:GetModuleGroups(nModuleId)
        self.tbBattleGuideData = tbTemp
    elseif nModuleId < GUIDEMODULELIMIT then
        tbTemp[nModuleId] = GuideDataTable:GetModuleGroups(nModuleId)
        self.tbGuideData = tbTemp
    else
        tbTemp[nModuleId] = GuideSingleDataTable:GetModuleGroups(nModuleId)
    end
    if not tbTemp[nModuleId] then
        return
    end
    self:Start(tbTemp)
end

function GuideSystem:GM_Close()
    self:DebugLog("GM_Close")
    self.tbGuideData = {}
    self.tbBattleGuideData = {}
    GMSystem:Exec("gm matchmaking-noob false")
    self:Uninit()
    self.bIsOpen = false
end

function GuideSystem:Start(tbGuideData)
    if not tbGuideData then
        self.bInGuideProgress = false
        return
    end
    self.bInGuideProgress = true
    self:DebugLog("Start")
    if next(tbGuideData) then
        HoldUIResource(self)
    end
    local nSceneId = self.nSceneId
    local tbModules = self.tbModules[nSceneId]
    if not tbModules then
        tbModules = {}
        self.tbModules[nSceneId] = tbModules
    end
    for nModule, tbGroups in pairs(tbGuideData) do
        if tbGroups then
            local CurrentModule = tbModules[nModule]
            if not CurrentModule then
                CurrentModule = GuideModule()
                self:DebugLog("Start nModule = " .. nModule)
                CurrentModule:Init(self, nModule, tbGroups)
                CurrentModule:BindEndCallBack(function(nModuleId) self:OnModuleEnd(nModuleId) end)
                CurrentModule:BindGroupEndCallBack(function(nModuleId, nGroupId) self:OnGroupEnd(nModuleId, nGroupId) end)
                tbModules[nModule] = CurrentModule
                CurrentModule:Begin()
            end
        end
    end
end

function GuideSystem:End()
    self:DebugLog("End")
    local nSceneId = self.nSceneId
    if not self.tbModules then
        return
    end
    local tbModules = self.tbModules[nSceneId]
    if not tbModules then
        return
    end
    for nModule, ModuleClass in pairs(tbModules) do
        ModuleClass:End()
    end
    UIManager:CloseWnd(UIDef.UI_GUIDE)
end

function GuideSystem:OnModuleEnd(nModuleId)
    self:DebugLog("OnModuleEnd ModuleId = " .. nModuleId)
    local nSceneId = self.nSceneId
    local tbData = {}
    if nSceneId == LOBBY then
        tbData = self.tbGuideData 
    elseif nSceneId == BATTLE then
        tbData = self.tbBattleGuideData
    end
    self:EndModule(nModuleId)
    self:HideGuideModal()
    if tbData[nModuleId] then
        self:DebugLog("Delete ModuleId = " .. nModuleId)
        tbData[nModuleId] = nil
    end
    self:SaveGuideProgress()
end

function GuideSystem:OnGroupEnd(nModuleId, nGroupId, bDelaySavePorgress)
    self:DebugLog("OnGroupEnd nModuleId = " .. nModuleId .. " GroupId = " .. nGroupId)
    local nSceneId = self.nSceneId
    local tbData = {}
    if nSceneId == LOBBY then
        tbData = self.tbGuideData
    elseif nSceneId == BATTLE then
        tbData = self.tbBattleGuideData
    end
    if not tbData[nModuleId] then
       return 
    end
    if tbData[nModuleId][nGroupId] then
        local tbModules = self.tbModules[nSceneId]
        if tbModules then
            self:DebugLog("Delete ModuleId = " .. nModuleId .. " GroupId = " .. nGroupId)
            tbData[nModuleId][nGroupId] = nil
        end
    end
    if not bDelaySavePorgress then
        self:SaveGuideProgress()
    end
end

function GuideSystem:RecoverGuideProgress(tbData)
    self:DebugLog("RecoverGuideProgress")
    if StringUtil.IsEmptyString(tbData) then
        return nil
    end
    local tbSaveData = dkjson.decode(tbData)
    if not tbSaveData then
        return nil
    end
    return tbSaveData
end

function GuideSystem:SaveGuideProgress()
    self:DebugLog("SaveGuideProgress")
    if not self.tbGuideData or not self.tbBattleGuideData or self.nSceneId == SINGLEBATTLE then
        return
    end
    local tbGuideData = {}
    local tbBattleGuideData = {}
    for nModuleId, tbGroup in pairs(self.tbGuideData) do
        nModuleId = tostring(nModuleId)
        local tbTemp = {}
        tbGuideData[nModuleId] = tbTemp
        self:DebugLog("SaveGuideProgress nModuleId = " .. tostring(nModuleId))
        for nGroupId, v in pairs(tbGroup) do
            self:DebugLog("SaveGuideProgress nGroupId = " .. tostring(nGroupId))
            table.insert(tbTemp, nGroupId)
        end
    end
    for nModuleId, tbGroup in pairs(self.tbBattleGuideData) do
        nModuleId = tostring(nModuleId)
        local tbTemp = {}
        tbBattleGuideData[nModuleId] = tbTemp
        for nGroupId, v in pairs(tbGroup) do
            table.insert(tbTemp, nGroupId)
        end
    end

    local tbSaveData = {}
    tbSaveData.tbGuideData = tbGuideData
    tbSaveData.nEnterBattleCount = self.nEnterBattleCount
    tbSaveData.tbBattleGuideData = tbBattleGuideData
    tbSaveData.tbAllwaystriggerData = self.tbAllwaystriggerData
    tbSaveData.tbTargetLobbyUIOpened = self.tbTargetLobbyUIOpened
    local szGuideSaveData = dkjson.encode(tbSaveData)
    if bClearSaveData then
        szGuideSaveData = ""
    end
    self:DebugLog("GuideSaveData = ".. szGuideSaveData)
    local tbPacket = {}
    tbPacket.noob_stage = szGuideSaveData
    self.ServerProxy:SendPacket(Proto.c2s_SyncNoobStage, tbPacket)
end

function GuideSystem:SkipGuideProgress()
    self:DebugLog("SkipGuideProgress")
    local tbSaveData = {}
    tbSaveData.tbGuideData = {}
    tbSaveData.nEnterBattleCount = 0
    tbSaveData.tbBattleGuideData = {}
    local szGuideSaveData = dkjson.encode(tbSaveData)
    local tbPacket = {}
    tbPacket.noob_stage = szGuideSaveData
    self.ServerProxy:SendPacket(Proto.c2s_SyncNoobStage, tbPacket)
end

function GuideSystem:BeginModule(nModuleId)
    self:DebugLog("BeginModule ModuleId = " .. nModuleId)
    local nSceneId = self.nSceneId
    local tbModules = self.tbModules[nSceneId]
    if not tbModules then
        self:LogError("tbModules is nil!")
        return
    end
    --已经开启
    if tbModules[nModuleId] then
        self:LogError("module is nil!")
        return
    end
    local tbGroups = GuideDataTable:GetModuleGroups(nModuleId)
    if not tbGroups then
        self:LogError("group is nil!")
        return
    end
    local ModuleClass = GuideModule()
    ModuleClass:Init(self, nModuleId, tbGroups)
    ModuleClass:BindEndCallBack(function(nId) self:OnModuleEnd(nId) end)
    ModuleClass:BindGroupEndCallBack(function(nMId, nGId) self:OnGroupEnd(nMId, nGId) end)
    tbModules[nModuleId] = ModuleClass
    ModuleClass:Begin()
    local tbGuideData = {}
    if nSceneId == LOBBY then
        tbGuideData =self.tbGuideData
    else
        tbGuideData =self.tbBattleGuideData
    end
    local tbTemp = tbGuideData[nModuleId]
    if not tbTemp then
        tbTemp = {}
    end
    tbTemp = LuaClassHelper.DeepCopyTable(tbGroups)
    tbGuideData[nModuleId] = tbTemp
    self:SaveGuideProgress()
end

function GuideSystem:ForceEndModule(tbParam)
    local nModuleId = tonumber(tbParam[2])
    self:DebugLog("ForceEndModule nModuleId = " .. tostring(nModuleId))
    local nSceneId = self.nSceneId
    local tbData = {}
    if nSceneId == LOBBY then
        tbData = self.tbGuideData 
    elseif nSceneId == BATTLE then
        tbData = self.tbBattleGuideData
    end
    self:EndModule(nModuleId, true)
    if tbData[nModuleId] then
        self:DebugLog("Delete ModuleId = " .. nModuleId)
        tbData[nModuleId] = nil
    end
end

function GuideSystem:EndModule(nModuleId, bForce)
    self:DebugLog("EndModule ModuleId = " .. nModuleId)
    local nSceneId = self.nSceneId
    local tbModules = self.tbModules[nSceneId]
    if not tbModules then
        return
    end
    local ModuleClass = tbModules[nModuleId]
    if not ModuleClass then
        return
    end
    if not ModuleClass.bHasAlwaysTriggerGroup or bForce then
        if ModuleClass then
            ModuleClass:End()
            ModuleClass:Uninit()
        end
    end
    self:SaveGuideProgress()
end

function GuideSystem:ForceEndGroup(nModuleId, nGroupId)
    self:DebugLog("ForceEndGroup ModuleId = " .. nModuleId)
    local nSceneId = self.nSceneId
    local tbModules = self.tbModules[nSceneId]
    if not tbModules then
        return
    end
    local ModuleClass = tbModules[nModuleId]
    if ModuleClass then
        ModuleClass:ForceEndGroup(nGroupId)
    end
end

function GuideSystem:ForceEndCurrentStep(nModuleId, nGroupId)
    self:DebugLog("ForceEndCurrentStep ModuleId = " .. nModuleId)
    local nSceneId = self.nSceneId
    local tbModules = self.tbModules[nSceneId]
    if not tbModules then
        return
    end
    local ModuleClass = tbModules[nModuleId]
    if ModuleClass then
        ModuleClass:ForceEndCurrentStep(nGroupId)
    end
end

function GuideSystem:ForceBeginCurrentStep(nModuleId, nGroupId)
    self:DebugLog("ForceBeginCurrentStep ModuleId = " .. nModuleId)
    local nSceneId = self.nSceneId
    local tbModules = self.tbModules[nSceneId]
    if not tbModules then
        return
    end
    local ModuleClass = tbModules[nModuleId]
    if ModuleClass then
        ModuleClass:ForceBeginCurrentStep(nGroupId)
    end
end

function GuideSystem:IsGroupFinish(nModuleId, nGroupId)
    self:DebugLog("IsGroupFinish ModuleId = " .. nModuleId .. " " .. nGroupId)
    local nSceneId = self.nSceneId
    local tbData = {}
    if nSceneId == LOBBY then
        tbData = self.tbGuideData
    elseif nSceneId == BATTLE then
        tbData = self.tbBattleGuideData
    end
    if not tbData then
        self:LogError("GetStepStatus tbModulse is nil")
        return true 
    end
    
    local tbMoudle = tbData[nModuleId]
    
    if not tbMoudle then
        self:LogError("GetStepStatus tbMoudle is nil")
        return true
    end
    local GroupClass = tbMoudle[nGroupId]
    
    if GroupClass then
        return false
    else
        return true
    end
end

function GuideSystem:GetStepStatus(nModuleId, nGroupId, nStepId)
    self:DebugLog("GetStepStatus ModuleId = " .. nModuleId)
    local nSceneId = self.nSceneId
    local tbModules = self.tbModules[nSceneId]
    if not tbModules then
        self:LogError("GetStepStatus tbModulse is nil")
        return FINISH 
    end
    local ModuleClass = tbModules[nModuleId]
    if not ModuleClass then
        self:LogError("GetStepStatus ModuleClass is nil")
        return FINISH
    end
    local GroupClass = ModuleClass:GetGroup(nGroupId)
    if not GroupClass then
        self:LogError("GetStepStatus GroupClass is nil")
        return FINISH
    end
    local StepClass = GroupClass:GetStep(nStepId)
    if not StepClass then
        self:LogError("GetStepStatus StepClass is nil")
        return FINISH
    end
    self:DebugLog("GetStepStatus StepClass.bBegin = " .. tostring(StepClass.bEnd))
    return StepClass.bEnd and FINISH or NOTFINISH
end

function GuideSystem:OnPawnDead(tbDeadActor)
    self:DebugLog("OnPawnDead nSceneId = " .. tostring(self.nSceneId))
    if tbDeadActor and tbDeadActor.ObjectType == GameObjectTypeDef.PlayerSelf and self.nSceneId == BATTLE then
        self:EndBattleGuide()
    end
end

function GuideSystem:EndBattleGuide()
    self:DebugLog("EndBattleGuide")
    self:SaveGuideProgress()
    local nSceneId = BATTLE
    local tbModules = self.tbModules[nSceneId]
    if not tbModules then
        self:LogError("tbModules is nil")
        return
    end
    for nModule, ModuleClass in pairs(tbModules) do
        ModuleClass:Uninit()
    end
    UIManager:CloseWnd(UIDef.UI_GUIDE)
end

function GuideSystem:SetModule(bOpenModule, tbModuleId)
    self:DebugLog("SetModule bOpenModule = " .. tostring(bOpenModule) .. " tbModuleId = " .. tostring(tbModuleId))
    for k, nModuleId in pairs(tbModuleId) do
        if bOpenModule then
            self:BeginModule(nModuleId)
        else
            self:EndModule(nModuleId)
        end
    end
end

function GuideSystem:GetAllwaysTriggerCountWithDefault(szKey, nDefault)
    self:DebugLog("GetAllwaysTriggerData szKey = ".. szKey)
    local tbAllwaystriggerData = self.tbAllwaystriggerData
    if not tbAllwaystriggerData then
        self:DebugLog("GetAllwaysTriggerData is nil")
        return 1
    end
    local nCount = tbAllwaystriggerData[szKey]
    self:DebugLog("nCount = ".. tostring(nCount))
    if not nCount then
        self:SetAllwaysTriggerCount(szKey, nDefault)
        return nDefault
    end
    return nCount
end

function GuideSystem:GetAllwaysTriggerCount(szKey)
    self:DebugLog("GetAllwaysTriggerData szKey = ".. szKey)
    local tbAllwaystriggerData = self.tbAllwaystriggerData
    if not tbAllwaystriggerData then
        self:DebugLog("GetAllwaysTriggerData is nil")
        return 1
    end
    local nCount = tbAllwaystriggerData[szKey]
    self:DebugLog("nCount = ".. nCount)
    return nCount
end

function GuideSystem:ClearAllwaysTriggerCount(szKey)
    self:DebugLog("ClearAllwaysTriggerCount szKey = ".. szKey)
    self:SetAllwaysTriggerCount(szKey, nil)
end

function GuideSystem:SetAllwaysTriggerCount(szKey, nCount)
    self:DebugLog("GetAllwaysTriggerData szKey = ".. szKey .. " nCount = ".. tostring(nCount))
    local tbAllwaystriggerData = self.tbAllwaystriggerData
    if not tbAllwaystriggerData then
        self.tbAllwaystriggerData = {}
        tbAllwaystriggerData = self.tbAllwaystriggerData
    end
    tbAllwaystriggerData[szKey] = nCount
end

function GuideSystem:GetNoobStage(szGuideInfo)
    self:DebugLog("GetNoobStage GuideInfo = ".. szGuideInfo)
    local nSceneId = self.nSceneId
    self.tbGuideData, self.tbBattleGuideData, self.tbAllwaystriggerData = self:GetModuleData(szGuideInfo)
    if nSceneId == LOBBY then
        self:Start(self.tbGuideData)
    elseif nSceneId == BATTLE then
         self:Start(self.tbBattleGuideData)
    end
end

function GuideSystem:OnEnterLobby()
    self:DebugLog("OnEnterLobby")
    self.nSceneId = LOBBY
    local bOpenGuide = GlobalVariableSystem:IsOpenGuide()
    self:DebugLog("OnPlayerSelfRead bNewRole = " .. tostring(self.bNewRole) .. " bSkipGuide = " .. tostring(self.bSkipGuide))
    if self.bNewRole then
        self.bNewRole = false
        -- GMSystem:Exec(string.format("gm matchmaking-noob %s" ,"false"))
        if not bOpenGuide then 
            self:SkipGuideProgress()
            return
        end
    end
end

function GuideSystem:OnPlayerSelfReady()
    self:DebugLog("OnPlayerSelfRead")
    if self.nSceneId == SINGLEBATTLE then
        return
    end
    local tbPlayer = GamePlayerSelfHelper:Get()
    local LobbyPropertyComponent = tbPlayer.LobbyPropertyComponent
    if not LobbyPropertyComponent then
        return
    end
    local nBattleCount = LobbyPropertyComponent.nBattleCount
    local nEnterBattleCount = self.nEnterBattleCount
    if nEnterBattleCount < 0 and nBattleCount then
        self:SetEnterBattleCount(nBattleCount)
    elseif nEnterBattleCount < 0 and not nBattleCount then
        self:SetEnterBattleCount(0)
    end
end

function GuideSystem:OnLobbyReady()
    self:DebugLog("OnLobbyReady")
    -- SDK逻辑相关
    local nEnterBattleCount = self.nEnterBattleCount
    if nEnterBattleCount >= 1 then --评分逻辑是如果评好或差，评分面板不会再弹，如果不评则会三天后再弹,所以不是极端状况的话，二者不会冲突
        ChannelSDKSystem:CheckPopDialog()
    end
    local tbGuideData = self.tbGuideData
    if not tbGuideData then
        self.ServerProxy:SendPacket(Proto.c2s_GetNoobStage)
    else
        self:Start(tbGuideData)
        self:SaveGuideProgress()
    end
end

function GuideSystem:HideGuideModal()
    self:DebugLog("HideGuideModal")
    ClearDelayTimer(self)
    self.DelayTimerHandle = DelayTimer:DelayRun(function() self:JudgeHideGuideModal() end, 2)
end

function GuideSystem:JudgeHideGuideModal()
    self:DebugLog("JudgeHideGuideModal")
    local nSceneId = self.nSceneId
    if not self.tbModules then
        self:ShowSpaceScreen(false)
    end
    local tbCurrent = self.tbModules[nSceneId]
    if not tbCurrent then
        self:ShowSpaceScreen(false)
    end
    local bHandle = true
    for k, ModuleClass in pairs(tbCurrent) do
        if ModuleClass:GetRunningGroup() then
            bHandle = false
            break
        end
    end
    self:DebugLog("JudgeHideGuideModal bHandle = " .. tostring(bHandle))
    if bHandle then
        self:ShowSpaceScreen(false)
    end
end

function GuideSystem:GetRunningGroup()
    local nSceneId = self.nSceneId
    local tbCurrent = self.tbModules[nSceneId]
    if not tbCurrent then
        return false
    end
    for k, ModuleClass in pairs(tbCurrent) do
        if ModuleClass:GetRunningGroup() then
            return true
        end
    end
    return false
end

function GuideSystem:ShowSpaceScreen(isShow)
    local GuideWnd = UIManager:GetWnd(UIDef.UI_GUIDE)
    if GuideWnd then
        self:DebugLog("ShowSpaceScreen isShow = " .. tostring(isShow))
        self.EventHelper(ClientEventDef.EV_GUIDE_SHOW_SPACE_SCREEN, isShow)
    end
end

function GuideSystem:OnLeaveLobby()
    self:DebugLog("OnLeaveLobby")
    self.EventHelper:FireEvent(ClientEventDef.EV_GUIDE_PRE_LEVEL_LOBBY) --通知GuideActionWaitDungonTextGuide，使其先end，从而使整个module end
    self:End()
    self:UninitModule()
end

function GuideSystem:OnEnterBattle()
    self:DebugLog("OnEnterBattle")
    local nDungeonId = BattleGameModeSystem:GetCurrentDungeonId()
    if nDungeonId == TRAINING_DUNGEON_ID then
        return
    end
    if nDungeonId == TutorialDungeonIni.nDungeonId then
        self.nSceneId = SINGLEBATTLE
        return
    end
    self.nSceneId = BATTLE
    local tbBattleGuideData = self.tbBattleGuideData
    if not self.tbBattleGuideData then
        self.ServerProxy:SendPacket(Proto.c2s_GetNoobStage)
    else
        self:Start(tbBattleGuideData)
    end
end

function GuideSystem:OnGameModeStartPlay()
    self:DebugLog("OnGameModeStartPlay")
    if self.nSceneId == SINGLEBATTLE then
        CameraGameHelper.SetGyroEnable(false)
        self.EventHelper:FireEvent(ClientEventDef.EV_SET_GYRO_CHECK_ENABLE, false)
        local tbSingleBattleData = GuideSingleDataTable:GetAllModules()
        self:Start(tbSingleBattleData)
    end
end

function GuideSystem:OnLeaveBattle()
    self:DebugLog("OnLeaveBattle")
    -- local nEnterBattleCount = self.nEnterBattleCount
    -- if nEnterBattleCount > 0 then
    --     self.tbBattleGuideData = {}
    -- end
    self:End()
    self:UninitModule()
end

function GuideSystem:OnSelectRoleBack()
    self:DebugLog("OnSelectRoleBack ModuleCount = " .. tostring(#self.tbModules))
    self:SaveGuideProgress()
end

function GuideSystem:OnBattleEnd()
    self:DebugLog("OnBattleEnd")
    local nEnterBattleCount = self.nEnterBattleCount
    self:SetEnterBattleCount(nEnterBattleCount + 1)
    ChannelSDKSystem:TrackBattle_First(self.nEnterBattleCount)
    self:DebugLog("nEnterBattleCount = " .. self.nEnterBattleCount)
    self:SaveGuideProgress()
end

function GuideSystem:SetEnterBattleCount(nCount)
    self:DebugLog("SetEnterBattleCount nEnterBattleCount = " .. nCount)
    self.nEnterBattleCount = nCount
    if self.EventHelper then
        self.EventHelper:FireEvent(ClientEventDef.EV_ON_SET_ENTER_BATTLE_COUNT, nCount)
    end
end

function GuideSystem:GetEnterBattleCount()
    return self.nEnterBattleCount
end

function GuideSystem:OnRoleSkipGuide(bResult)
    self.bNewRole = true
end

function GuideSystem:OpenDebug(bOpen)
    self:DebugLog("OpenDebug bOpen = " .. tostring(bOpen))
    GuideDebug:OpenDebug(bOpen)
end

function GuideSystem:DebugLog(szMsg)
    szMsg = "[GuideSystem] " .. szMsg
    GuideDebug:DebugLog(szMsg)
end

function GuideSystem:Log(szMsg)
    szMsg = "[GuideSystem] " .. szMsg
    GuideDebug:Log(szMsg)
end

function GuideSystem:LogError(szMsg)
    szMsg = "[GuideSystem] " .. szMsg
    GuideDebug:LogError(szMsg)
end

local function GetWidgetRefBynFrom(nFrom)
    local pWidgetRef = nil
    local pWnd = UIManager:GetWnd(UIDef.UI_FFA_MAIN)
    if not pWnd then
        return pWidgetRef
    end
    if nFrom == SettingLayoutFromDef.COMMON then
        pWidgetRef = pWnd.pWidgetRef
    elseif nFrom == SettingLayoutFromDef.HUMAN then
        pWidgetRef = pWnd.pWidgetRef.pbFFAHuman
    elseif nFrom == SettingLayoutFromDef.SHIP then
        pWidgetRef = pWnd.pWidgetRef.pbFFAShip
    elseif nFrom == SettingLayoutFromDef.VEHICLE then
        pWidgetRef = pWnd.pWidgetRef.pbFFAHuman
    end
    return pWidgetRef
end

function GuideSystem:GetLayoutScale(nFrom, szScaleParent)
    self:DebugLog("GetLayoutScale")
    local pWidgetRef = GetWidgetRefBynFrom(nFrom)
    if not pWidgetRef then
        return DEFAULT_LAYOUT_SCALE
    end
    local SettingLayout = SettingSystemNew:GetInstance(SettingClassType.Setting_Layout)
    local tbAllLayout = SettingLayout:GetCurrentLayoutFrom(nFrom)
    for k, v in pairs(tbAllLayout) do
        if v.nFrom == nFrom then
            local tbTemplate = v.tbTemplate
            if tbTemplate.szMainWidgetName == szScaleParent then
                local pWidget = pWidgetRef[tbTemplate.szMainWidgetName]
                if pWidget then
                    local RenderTransform = pWidget.RenderTransform
                    if RenderTransform then
                        return RenderTransform.Scale
                    end
                end
            end
        end
    end
    return DEFAULT_LAYOUT_SCALE
end

function GuideSystem:SetStripGroups(nModuleId, nGuideType)
    self:DebugLog("SetStripGroups nModuleId = " .. nModuleId .. " nGuideType = " .. nGuideType)
    if self.tbStripGroupTab == nil then
        self.tbStripGroupTab = {}
    end
    local tbTemp = self.tbStripGroupTab[nModuleId]
    if not tbTemp then
        tbTemp = {}
        tbTemp[nGuideType] = 0
        self.tbStripGroupTab[nModuleId] = tbTemp
    else
        tbTemp[nGuideType] = 0
    end
end

function GuideSystem:CheckIsStripGroups(nModuleId, nGroupId)
    self:DebugLog("CheckIsStripGroups nModuleId = " .. nModuleId .. " nGroupId = " .. nGroupId)
    if not self.tbStripGroupTab then
        return false
    end
    local tbTemp = self.tbStripGroupTab[nModuleId]
    if not tbTemp then
        return false
    end
    local nGuideType = -1
    if nModuleId >= GUIDEMODULELIMIT and nModuleId < GUIDEBATTLEMODULELIMIT then
        nGuideType = GuideBattleDataTable:GetGroupType(nModuleId, nGroupId)
    elseif nModuleId < GUIDEMODULELIMIT then
        nGuideType = GuideDataTable:GetGroupType(nModuleId, nGroupId)
    else
        nGuideType = GuideSingleDataTable:GetGroupType(nModuleId, nGroupId)
    end
    if not tbTemp[nGuideType] then
        return false
    end
    self:OnGroupEnd(nModuleId, nGroupId, true)
    return true
end

function GuideSystem:LobbyUIIsOpened(szWndName)
    if not self.tbTargetLobbyUIOpened then
        return false
    end
    local result = self.tbTargetLobbyUIOpened[szWndName]
    if result == nil then
        return false
    end
    return true
end

function GuideSystem:IsGuideInProgress()
    return self.bInGuideProgress
end

function GuideSystem:BindEvent()
    self:DebugLog("BindEvent")
    self.EventHelper = SelfEventHelper()
    local EventHelper = self.EventHelper
    EventHelper:RegisterEvent(ClientEventDef.EV_GUIDE_SET_MODULE, self, self.SetModule)
    EventHelper:RegisterEvent(ClientEventDef.EV_ENTER_PROCEDURE_LOBBY, self, self.OnEnterLobby)
    EventHelper:RegisterEvent(ClientEventDef.EV_LEAVE_PROCEDURE_LOBBY, self, self.OnLeaveLobby)
    EventHelper:RegisterEvent(ClientEventDef.EV_ENTER_PROCEDURE_BATTLE, self, self.OnEnterBattle)
    EventHelper:RegisterEvent(ClientEventDef.EV_LEAVE_PROCEDURE_BATTLE, self, self.OnLeaveBattle)
    EventHelper:RegisterEvent(ClientEventDef.EV_UI_SELECT_ROLE_BACK, self, self.OnSelectRoleBack)
    EventHelper:RegisterEvent(ClientEventDef.EV_PLAYERSELF_READY, self, self.OnPlayerSelfReady)
    EventHelper:RegisterEvent(ClientEventDef.EV_UI_ROLE_SKIP_GUIDE, self, self.OnRoleSkipGuide)
    EventHelper:RegisterEvent(ClientEventDef.EV_LOBBY_READY, self, self.OnLobbyReady)
    EventHelper:RegisterEvent(CommonEventDef.EV_GAME_OBJECT_ON_PAWN_DEAD, self, self.OnPawnDead)
    EventHelper:RegisterEvent(CommonEventDef.EV_GAME_MODE_START_PLAY, self, self.OnGameModeStartPlay)
    EventHelper:RegisterEvent(ClientEventDef.EV_GUIDE_FORCE_END_MODULE, self, self.ForceEndModule)
    EventHelper:RegisterEvent(ClientEventDef.EV_OPEN_UI, self, OnOpenUI)
end

function GuideSystem:UnbindEvent()
    local EventHelper = self.EventHelper
    if not EventHelper then
        return
    end
    EventHelper:UnregisterAll()
end



return GuideSystem