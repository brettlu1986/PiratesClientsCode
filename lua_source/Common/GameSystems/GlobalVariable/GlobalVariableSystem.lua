local luaclass = require("luaclass")
local GlobalVariableSystem = luaclass("GlobalVariableSystem")


GlobalVariableSystem.bEnableCaptureLag = false
GlobalVariableSystem.fCaptureLagTime = 0.01

GlobalVariableSystem.bIsClient = false
GlobalVariableSystem.bIsInDungeon = false
GlobalVariableSystem.bIsStandalone = false  -- 是否单机模式
--GlobalVariableSystem.bEnableComponentDataSerializer = not GWithEditor
GlobalVariableSystem.bEnableComponentDataSerializer = false
GlobalVariableSystem.bDyingEnabled = true
GlobalVariableSystem.bWithLobby = true
GlobalVariableSystem.bDungeonDamageEnbled = true -- 副本内伤害开关
GlobalVariableSystem.bNotifyDamageWhenIgnoreDamage  = false --忽略伤害时是否发送真实伤害值给客户端，用于伤害测试员

GlobalVariableSystem.bEnableNewLobbyServer = true    -- 新服务器模式
GlobalVariableSystem.bEnableTemplateActor = false
GlobalVariableSystem.bEnablePartner = false
GlobalVariableSystem.bEnableNPCAlert = true     -- 开启NPC警戒系统
GlobalVariableSystem.bNavigationWalkForBot = false

GlobalVariableSystem.bEnableAIGameCore = false          --是否是深度学习AI模式
GlobalVariableSystem.bAIGameCoreTrainingMode = false    --是否处于AI训练模式，只在给超参数的版本里面为true
GlobalVariableSystem.bEnableBotSupply = true
GlobalVariableSystem.EnableDLAgent = true                  --是否允添加深度学习机器人
GlobalVariableSystem.bShowDLAgentName = false               --是否显示深度学习机器人名字
GlobalVariableSystem.bEnableTeamWithBot = true             --是否开启跟机器人组队
GlobalVariableSystem.bEnableSyncRealPlayer = true          --是否开启在与机器人组队的时候向AI服务器同步真人数据


GlobalVariableSystem.bUseNewBattleItem = true
GlobalVariableSystem.bUseNewSpeel = true

function GlobalVariableSystem:Init()
     self.bIsClient = false
     self.bIsInDungeon = true
     self.bIsStandalone = false
     math.randomseed(self:GetLocalTime())
     return true
end

function GlobalVariableSystem:Uninit()
end

function GlobalVariableSystem:SetIsClient(bClient)
    self.bIsClient = bClient
end

function GlobalVariableSystem:IsClient()
    return self.bIsClient
end

function GlobalVariableSystem:SetInDungeon(bInDungeon)
    self.bIsInDungeon = bInDungeon
    local pGameInstance = GameplayStatics.GetGameInstance(GWorld)
    if pGameInstance and pGameInstance.GlobalSettings then
        pGameInstance.GlobalSettings.IsInDungeon = bInDungeon
    end
end

function GlobalVariableSystem:IsServerLogic()
    if not self.bIsInDungeon then
        return false
    end
    if not self.bIsClient then
        return true
    end
    return self.bIsStandalone
end

function GlobalVariableSystem:IsDedicatedServer()
    return not self.bIsClient
end

function GlobalVariableSystem:IsDedicatedClient()
    if not self.bIsInDungeon then
        return false
    end
    if not self.bIsClient then
        return false
    end
    return not self.bIsStandalone
end

-- 单机服务器
function GlobalVariableSystem:IsStandaloneServer()
    if not self.bIsInDungeon then
        return false
    end
    if not self.bIsClient then
        return false
    end
    return self.bIsStandalone
end

function GlobalVariableSystem:IsInDungeon()
    return self.bIsInDungeon
end

function GlobalVariableSystem:IsInLobby()
    return not self.bIsInDungeon
end

function GlobalVariableSystem:SetStandalone(bIsStandalone)
    self.bIsStandalone = bIsStandalone
end

function GlobalVariableSystem:IsStandalone()
    return self.bIsStandalone
end

function GlobalVariableSystem:SetEnableDebugLog(bTimerLog, bEventLog, bCppLog)
    local Timer = require("Timer")
    local EventManager = require("EventManager")
    Timer.EnableDebugLog(bTimerLog)
    EventManager.EnableDebugLog(bEventLog)

    if(not GEnableNewLua) then
        setenabledebuglog(bCppLog)
    end
end

function GlobalVariableSystem:GetLocalTime()
    return os.time()
end

function GlobalVariableSystem:GetDSTimeSeconds()
    local pGameState = GameplayStatics.GetGameState(GWorld)
    if pGameState then
        return pGameState:GetServerWorldTimeSeconds()
    end
    return 0
end

function GlobalVariableSystem:GetPlatformName(bLower)
    local szPlatformName = GameplayStatics.GetPlatformName()
    if bLower then
        szPlatformName = string.lower(szPlatformName)
    end
    return szPlatformName
end

function GlobalVariableSystem:EnableTemplateActor(bEnable)
    self.bEnableTemplateActor = bEnable
end

function GlobalVariableSystem:SetDungeonDamageEnabled(bEnable)
    self.bDungeonDamageEnbled = bEnable
end

function GlobalVariableSystem:GetDungeonDamageEnabled()
    return self.bDungeonDamageEnbled
    -- return true
end

function GlobalVariableSystem:SetNotifyDamageWhenIgnoreDamage(bEnable)
    self.bNotifyDamageWhenIgnoreDamage = bEnable
end

function GlobalVariableSystem:IsNotifyDamageWhenIgnoreDamage()
    return self.bNotifyDamageWhenIgnoreDamage
end

function GlobalVariableSystem:SetWithLobby(bWith)
    self.bWithLobby = bWith
end

function GlobalVariableSystem:IsWithLobby()
    return self.bWithLobby
end


function GlobalVariableSystem:EnableSyncRealPlayerDataToAI()
    return self.bEnableSyncRealPlayer and self.bEnableAIGameCore and self.bEnableTeamWithBot
end

function GlobalVariableSystem:SetVersionInfo(tbInfo)
end

function GlobalVariableSystem:GetVersionInfo()
end

return GlobalVariableSystem()
