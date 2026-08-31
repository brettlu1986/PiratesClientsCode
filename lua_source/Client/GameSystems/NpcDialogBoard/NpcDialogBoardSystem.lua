-----------------------------------------------------
--File Name    : NpcDialogBoardSystem.lua
--Author       : Chang Nan
--Create Time  : 2017-12-27
--Description  : NPC喊话系统
-----------------------------------------------------
local UIManager = require("UIManager")
local UIDef = require("UIDef")


local SelfEventHelper = require("SelfEventHelper")
local ClientEventDef = require("ClientEventDef")
local CommonEventDef = require("CommonEventDef")
--local DialogDataTable = require("DialogDataTable")
local GameObjectTypeDef = require("GameObjectTypeDef")
local BattleGameModeSystem = dynamic_require("BattleGameModeSystem")
local DungeonDataTable = require("DungeonDataTable")
local NpcDialogBoardDataTable = require("NpcDialogBoardDataTable")
local IntervalTimeDef = require("IntervalTimeDef")
local GlobalVariableSystem = require("GlobalVariableSystem_C")
local InteractionHelper = require("InteractionHelper")

local NpcDialogBoardSystem = {}

NpcDialogBoardSystem.nDialogID = 0
NpcDialogBoardSystem.nStepID = 0
NpcDialogBoardSystem.nDungeonId = 0
NpcDialogBoardSystem.pLastDialogBoard = nil
NpcDialogBoardSystem.EventHelper = nil
-- NpcDialogBoardSystem.TimerHelper = nil
-- NpcDialogBoardSystem.OnComplete = nil
NpcDialogBoardSystem.tbPlayerDialogBoardDataTable = nil
NpcDialogBoardSystem.tbIntervalTimes = {}
NpcDialogBoardSystem.bLoadScene = nil

NpcDialogBoardSystem.tbSavedRequests = {}

-- local SUBID_DEFAULT = 1
local DISPLAY_MODE_POP = 2
local tbEventToTimeKey = {}
local tbEventToIds = {}

local function DefineEventToTemplateKey()
    local Set = function(nIndex, szIntervalTime, szIds)
        tbEventToTimeKey[nIndex] = szIntervalTime
        tbEventToIds[nIndex] = szIds
    end
    Set(IntervalTimeDef.LAST_BORN_ENEMY_INDEX, "nBornIntervalTime", "tbBorn")
    Set(IntervalTimeDef.LAST_DISCOVER_ENEMY_INDEX, "nDiscoverEnemyIntervalTime", "tbDiscoverEnemy")
    Set(IntervalTimeDef.LAST_KILL_ENEMY_INDEX, "nKillEnemyIntervalTime", "tbKillEnemy")
    Set(IntervalTimeDef.LAST_BURN_ENEMY_INDEX, "nBurnEnemyIntervalTime", "tbBurnEnemy")
    Set(IntervalTimeDef.LAST_HIT_ENEMY_INDEX, "nHitEnemyIntervalTime", "tbHitEnemy")
    Set(IntervalTimeDef.LAST_DEAD_SELF_INDEX, "nDeadSelfIntervalTime", "tbDeadSelf")
    Set(IntervalTimeDef.LAST_HIT_TORPEDO_SELF_INDEX, "nHitTorpedoSelfIntervalTime", "tbHitTorpedoSelf")
    Set(IntervalTimeDef.LAST_HIT_CORE_INDEX, "nHitCoreSelfIntervalTime", "tbHitCoreSelf")
    Set(IntervalTimeDef.LAST_BURN_SELF_INDEX, "nBurnSelfIntervalTime", "tbBurnSelf")
    Set(IntervalTimeDef.LAST_WATER_LEAK_SELF_INDEX, "nWaterLeakSelfIntervalTime", "tbWaterLeakSelf")
    Set(IntervalTimeDef.LAST_HIT_SELF_INDEX, "nHitSelfIntervalTime", "tbHitSelf")
end
DefineEventToTemplateKey()

-- 获取随机的喊话ID
local function GetRandomDialogBoardId(self, tbIdArray)
    local nArraylens = #tbIdArray
    if nArraylens <= 0 then
        return -1
    end
    local nRandomIndex = math.random( 1, nArraylens)
    return tbIdArray[nRandomIndex]
end

local function GetObjectDialogBoardData(self, GameObject)
    if(GameObject == nil or GameObject.nServerInstanceId < 0) then
        return nil
    end

    if(GameObject.ObjectType == GameObjectTypeDef.Npc) then
        if GameObject.DialogBoardComponent == nil or GameObject.DialogBoardComponent:GetDialogBoardId() == 0 then
            return
        end

        return NpcDialogBoardDataTable:GetTemplate(GameObject.DialogBoardComponent:GetDialogBoardId())
    elseif(GameObject.ObjectType == GameObjectTypeDef.PlayerSelf) then
        return self.tbPlayerDialogBoardDataTable
    end

    return nil
end

local function OpenWithTemplate(self, tbTemplate, nEventIndex, GameObject)
    assert(tbTemplate ~= nil)
    local bIsPassedIntervalTime = self:CheckIntervalTimePased(nEventIndex, tbTemplate[tbEventToTimeKey[nEventIndex]])
    if bIsPassedIntervalTime == false then
        return false
    end
    local nDialogId = GetRandomDialogBoardId(self, tbTemplate[tbEventToIds[nEventIndex]])

    if nDialogId < 0 then
        error("NpcDialogBoardSystem:OpenWithTemplate error: "..tostring(nEventIndex)..","..tostring(tbTemplate.nID))
    end

    self:OpenDialogBoard(nDialogId, GameObject)
    return true
end

function NpcDialogBoardSystem:TryOpenWithTemplate(GameObject, nEventIndex)
    local tbTemplate = GetObjectDialogBoardData(self, GameObject)
    if(tbTemplate == nil) then
        return false
    end

    if(self.bLoadScene) then
        table.insert(self.tbSavedRequests, {tbTemplate, nEventIndex, GameObject})
        return false
    end
    OpenWithTemplate(self, tbTemplate, nEventIndex, GameObject)
    return true
end

local function FlushRequests(self)
    for _, v in ipairs(self.tbSavedRequests) do
        OpenWithTemplate(self, v[1], v[2], v[3])
    end
    self.tbSavedRequests = {}
end



local function ClearAll(self)
    self.pLastDialogBoard = nil
    self.tbPlayerDialogBoardDataTable = nil
    --self.nDungeonId = 0
    self.bLoadScene = false
end


local function OnEnterLoading(self)
    self.bLoadScene = true
    if(GlobalVariableSystem:IsInDungeon()) then
        ClearAll(self)
        local nDungeonId = BattleGameModeSystem.nDungeonId
        if nDungeonId ~= nil then
            self.nDungeonId = nDungeonId
            local tbDungeonDataTemplate = DungeonDataTable:GetTemplate(nDungeonId)
            if tbDungeonDataTemplate.nNpcDialogBoardID ~= nil and tbDungeonDataTemplate.nNpcDialogBoardID > 0 then
                self.tbPlayerDialogBoardDataTable = NpcDialogBoardDataTable:GetTemplate(tbDungeonDataTemplate.nNpcDialogBoardID)
            end
        end
    end
end


local function OnExitLoading(self)
    self.bLoadScene = false
    --获取当前副本的id
    if not GlobalVariableSystem:IsInDungeon() and self.nDungeonId > 0 then
        self.nDungeonId = 0
        self.nDialogID = 0
        self.nStepID = 0
        return
    end
    if self.nStepID > 0 and self.nDialogID > 0 then
        self.pLastDialogBoard = UIManager:OpenWnd(UIDef.UI_NPC_DIALOG_BOARD,{nDialogID = self.nDialogID, nStep = self.nStepID})
        self.nDialogID = 0
        self.nStepID = 0
        -- self:ShowNextDialog()
        -- self.pLastDialogBoard:ShowNextDialog()
        return
    end

    FlushRequests(self)
end


local function OnInteractionStart(self)
    if self.pLastDialogBoard ~= nil then
        self.pLastDialogBoard:CloseSelf()

        self.pLastDialogBoard = nil
    end
end

-- 验证喊话冷却时间是否结束
function NpcDialogBoardSystem:CheckIntervalTimePased(nEventIndex, nIntervalTime)
    if self.tbIntervalTimes[nEventIndex] == nil or self.tbIntervalTimes[nEventIndex] == 0 then
        self.tbIntervalTimes[nEventIndex] = GlobalVariableSystem:GetLocalTime()
    elseif self.tbIntervalTimes[nEventIndex] > 0 then
        local nCurrentTime = GlobalVariableSystem:GetLocalTime()
        local nPassTime = nCurrentTime - self.tbIntervalTimes[nEventIndex]
        if nPassTime < nIntervalTime then
            return false
        else
            self.tbIntervalTimes[nEventIndex] = GlobalVariableSystem:GetLocalTime()
        end
    end
    return true
end

--出生
local function OnCreateObject(self, GameObject)
    self:TryOpenWithTemplate(GameObject, IntervalTimeDef.LAST_BORN_ENEMY_INDEX)
end

--击沉事件
local function OnAnyShipDead(self, GameObject)
    self:TryOpenWithTemplate(GameObject, IntervalTimeDef.LAST_DEAD_SELF_INDEX)
    -- if GameObject.BattleStatusComponent then
    --     local KillerObject = GameObject.BattleStatusComponent:GetLastDamageCauser()
    --     self:TryOpenWithTemplate(KillerObject, IntervalTimeDef.LAST_KILL_ENEMY_INDEX)
    -- end
end

--监听各种状态事件
local function RegisteDialogBoardEvents(self)
    -- 注册NPC创建事件
    self.EventHelper:RegisterEvent(CommonEventDef.EV_GAME_OBJECT_POST_ACTOR_CREATE, self, OnCreateObject)
    -- 击杀事件
    self.EventHelper:RegisterEvent(CommonEventDef.EV_GAME_OBJECT_ON_PAWN_DEAD, self, OnAnyShipDead)
end


function NpcDialogBoardSystem:Init()
    self.bLoadScene = false
    self.tbSavedRequests = {}

	self.EventHelper = SelfEventHelper()
    self.EventHelper:RegisterEvent(ClientEventDef.EV_EXIT_LOADING, self, OnExitLoading)
    self.EventHelper:RegisterEvent(ClientEventDef.EV_ENTER_LOADING, self, OnEnterLoading)
    self.EventHelper:RegisterEvent(ClientEventDef.EV_INTERACTION_START, self, OnInteractionStart)
    RegisteDialogBoardEvents(self)
    ClearAll(self)
end

function NpcDialogBoardSystem:Uninit()
    self.nDialogID = 0
    self.nStepID = 0
    ClearAll(self)
    self.tbSavedRequests = nil
	self.EventHelper:UnregisterAll()
	self.EventHelper = nil
end


-- 打开喊话面板
function NpcDialogBoardSystem:OpenDialogBoard(nDialogID, GameObject, fnComplete, Parent)
    if nDialogID <= 0 then
        return
    end

    --气泡喊话
    -- self.tbDialog = DialogDataTable:GetTemplate(nDialogID, IntervalTimeDef.DEFAULT_DIALOG_SUBID, SUBID_DEFAULT)
    -- if not self.tbDialog then
    --     return
    -- end

    if self.tbDialog.nDisplayMode == DISPLAY_MODE_POP then

        InteractionHelper:CreateHeadDialog(nDialogID, nil, GameObject)
        return
    end

    self.nDialogID = nDialogID
    -- self.nStepID = 0
    local tbParams = {nDialogID = self.nDialogID, fnComplete = fnComplete, Parent = Parent}

    if self.pLastDialogBoard == nil then
        if not UIManager:GetWnd(UIDef.UI_INTERACTION) then
            self.pLastDialogBoard = UIManager:OpenWnd(UIDef.UI_NPC_DIALOG_BOARD,tbParams)
        end
    else
        self.pLastDialogBoard:RefreshDialog(tbParams)
    end

end

-- 气泡喊话

return NpcDialogBoardSystem
