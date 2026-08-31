-----------------------------------------------------
--File Name    : CheaterCheckSystemNew.lua
--Author       : liujifang
--Create Time  : 2020-04-27
--Description  : 用于检测外挂
-----------------------------------------------------

local CheaterCheckSystemNew = {}

local SelfEventHelper = require("SelfEventHelper")
local CommonEventDef = require("CommonEventDef")
local DungeonIni = require("DungeonIni")
local TimeCheaterCheck = require("TimeCheaterCheck")
--local CheatingTypeDef = require("CheatingTypeDef")
local GameObjectSystem = dynamic_require("GameObjectSystem")
--local BattleGameModeSystem = dynamic_require("BattleGameModeSystem")

local CHECK_COUNT_LIMIT = DungeonIni.tbCheaterCheck.nCheckCountLimit

CheaterCheckSystemNew.tbPlayerCheckDataMap = nil

local function LOG(...)
    log('[CheaterCheckSystem]', ...)
end

local function LOG_WARNING(...)
    logwarning('[CheaterCheckSystem]', ...)
end

local function LOG_ERROR(...)
    logerror('[CheaterCheckSystem]', ...)
end

-- Server
-- 获得一个玩家的CheckData
local function GetPkayerCheckData(self, tbPlayer, bCreateIfNotFind)
    local tbPlayerCheckData = self.tbPlayerCheckDataMap[tbPlayer]
    if (not tbPlayerCheckData) and bCreateIfNotFind then
        tbPlayerCheckData = {}
        self.tbPlayerCheckDataMap[tbPlayer] = tbPlayerCheckData
    end
    return tbPlayerCheckData
end

local function OnRecordCheaterCheck(self, tbPlayer, nCheatingType)
    if not self.tbPlayerCheckDataMap then
        LOG_ERROR("RecordCheating, tbPlayerCheckDataMap is nil")
        return
    end

    --TODO:这里也需要有运营方案的介入，怎么来处理并记录各类作弊行为
    local tbPlayerCheckData = GetPkayerCheckData(self, tbPlayer, true)
    if tbPlayerCheckData.nCheatingCount then
        tbPlayerCheckData.nCheatingCount = tbPlayerCheckData.nCheatingCount + 1
    else
        tbPlayerCheckData.nCheatingCount = 1
    end

    LOG(tbPlayer.szName, ", record a cheating operation, nCheatingCount, nCheatingType =", tbPlayerCheckData.nCheatingCount, nCheatingType)
    --TODO:目前还没有运营方案，所以这里直接进行踢人
    if tbPlayerCheckData.nCheatingCount >= CHECK_COUNT_LIMIT then
        LOG_WARNING(tbPlayer.szName, ", kick.")
        --BattleGameModeSystem:KickPlayer(tbPlayer)
    end
end

local function OnMovementIllegal(self, pActor)
    local tbPlayer = GameObjectSystem:FindByUEActor(pActor)
    LOG(tbPlayer.szName, ",OnMovementIllegal")
    --OnRecordCheaterCheck(self, tbPlayer, CheatingTypeDef.MOVEMENT_CHECK)        
end

function CheaterCheckSystemNew:Init()
    local EventHelper = SelfEventHelper()
    EventHelper:RegisterEvent(CommonEventDef.EV_CHEATER_CHECK, self, OnRecordCheaterCheck)

    local DelegateMgr = CommonShell.GetCommon(GWorld):GetGameDelegateManager().Movement
    EventHelper:RegisterCppDelegate(DelegateMgr.OnMovementIllegalDetection, self, OnMovementIllegal)

    self.tbPlayerCheckDataMap = {}
    self.EventHelper = EventHelper
    self.tbGameObjects = {}

    TimeCheaterCheck:Init()
end

function CheaterCheckSystemNew:Uninit()
    TimeCheaterCheck:Uninit()
    if self.EventHelper ~= nil then
    	self.EventHelper:UnregisterAll()
    end
    self.tbGameObjects = nil
end

return CheaterCheckSystemNew