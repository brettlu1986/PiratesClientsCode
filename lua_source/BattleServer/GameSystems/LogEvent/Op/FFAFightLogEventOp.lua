local luaclass = require("luaclass")
local LogEventOpBase = dynamic_require("LogEventOpBase")
local FFAFightLogEventOp = luaclass("FFAFightLogEventOp", LogEventOpBase)

local Analytics             = require("DungeonAnalyticsProtoNames")
local EventManager          = require("EventManager")
local CommonEventDef        = require("CommonEventDef")
local GameObjectTypeDef     = require("GameObjectTypeDef")
local BotAISystem           = dynamic_require("BotAISystem")
local GlobalVariableSystem  = dynamic_require("GlobalVariableSystem")
local GameObjectSystem      = dynamic_require("GameObjectSystem")

-- 每次持续战斗之间的时间间隔
local PERSISTENT_FIGHT_INTERVAL = 30

-- 所有玩家之间持续战斗数据集合
FFAFightLogEventOp.tbTotalPersistentFightMap = nil

-- 所有玩家持续战斗总次数集合
FFAFightLogEventOp.tbTotalPersistentFightCountMap = nil

-- 最所有玩家后一次持续战斗开始的时间集合
FFAFightLogEventOp.tbLastPersistentFightTimeMap = nil

local function LOG(...)
    log("[FFAFightLogEventOp]", ...)
end

local function GetLocationString(tbPlayer)
    local pLocation = tbPlayer:GetLocation()
    return string.format("%d,%d,%d", math.floor(pLocation.X), math.floor(pLocation.Y), math.floor(pLocation.Z))
end

-- 是否处于持续状态中
local function IsFightState(self, tbCharacter)
    local nCurrentTime = GlobalVariableSystem:GetDSTimeSeconds()
    local nLastPersistentFightTime = self.tbLastPersistentFightTimeMap[tbCharacter]
    return nLastPersistentFightTime and ((nCurrentTime - nLastPersistentFightTime) <= PERSISTENT_FIGHT_INTERVAL)
end

-- 上传持续战斗总次数
local function LogTotalPersistentFight(self, nPlayerId, nCount)
    local tbPacket = {}
    tbPacket.count = nCount
    self:SavePlayerCommonPropertysToPacket(nPlayerId, tbPacket)
    LOG("logevent Analytics.TotalPersistentFight", t2s(tbPacket))
    self:LogEvent(Analytics.TotalPersistentFight, tbPacket)
end

-- 上传单次战斗信息
local function LogOnceFight(self, tbPlayer, nWeaponTemplateId, nDamage)
    local tbPacket = {}
    tbPacket.location = GetLocationString(tbPlayer)                                 -- 战斗发生区域
	tbPacket.elapsed_time = self:GetBattleElapsedTime()                             -- 游戏开始至战斗时的时间
	tbPacket.template_id = nWeaponTemplateId                                        -- 武器ID
	tbPacket.damege = nDamage                                                       -- 此次攻击造成的总伤害，为0时则未未命中
    self:SavePlayerCommonPropertysToPacket(tbPlayer.nPlayerId, tbPacket)
    LOG("logevent Analytics.OnceFight", t2s(tbPacket))
    self:LogEvent(Analytics.OnceFight, tbPacket)
end

-- 处理持续战斗逻辑判断
local function HandlePersistentFight(self, tbCauser, tbTaker)
    local nTotalPersistentFightCount = self.tbTotalPersistentFightCountMap[tbCauser] or 0
    local tbPersistentFightTimeMap = self.tbTotalPersistentFightMap[tbCauser] or {}
    self.tbTotalPersistentFightMap[tbCauser] = tbPersistentFightTimeMap

    local nCurrentTime = GlobalVariableSystem:GetDSTimeSeconds()                    -- 当前时间
    local nLastTime = tbPersistentFightTimeMap[tbTaker]                             -- 上次发生持续战斗的时间
    if (not nLastTime)                                                              -- nLastTime为nil，说明没和这个人发生过持续战斗，直接上传
    or (nCurrentTime - nLastTime >= PERSISTENT_FIGHT_INTERVAL) then                 -- 或者是距离上次上传持续战斗数据已经超过了时间阈值PERSISTENT_FIGHT_INTERVAL
        tbPersistentFightTimeMap[tbTaker] = nCurrentTime
        self.tbTotalPersistentFightCountMap[tbCauser] = nTotalPersistentFightCount + 1
        self.tbLastPersistentFightTimeMap[tbCauser] = nCurrentTime
        LOG("Record a persistent fight, causer :", tbCauser.nPlayerId, ", taker :", tbTaker.nPlayerId, ", total count :", self.tbTotalPersistentFightCountMap[tbCauser])
    end
end

-- 处理所有玩家持续战斗数据
local function HandleAllPlayerPersistentFight(self)
    for tbPlayer, nCount in pairs(self.tbTotalPersistentFightCountMap) do
        LogTotalPersistentFight(self, tbPlayer.nPlayerId, nCount)
    end
end

-- 角色收到伤害的事件回调
local function OnTakeDamage(self, tbTaker, tbCauser, nDamage, nDamageType, nHp, nItemTemplateId, tbDamageExtraData)
    if (not self:IsBattleBegin())                                                   -- 需要先战斗开始
    or (not tbTaker)                                                                -- Taker不能为空
    or (not tbCauser)                                                               -- Causer不能为空
    or (tbTaker == tbCauser)                                                        -- 自己对自己造成的伤害不算（重伤、自杀等）
    or (tbCauser.ObjectType ~= GameObjectTypeDef.PlayerSelf)                        -- Causer的ObjectType必须为PlayerSelf
    or BotAISystem:IsBot(tbCauser)                                                  -- Causer不能为Bot
    or (not GameObjectSystem:IsCharacter(tbTaker))  then                            -- 打可破坏物时不上传
        return
    end
    HandlePersistentFight(self, tbCauser, tbTaker)
end

-- 角色收到伤害的事件回调
local function OnCharacterAttacked(self, tbCharacter, nWeaponTemplateId, nDamage)
    if (not self:IsBattleBegin())                                                   -- 需要先战斗开始
    or (not tbCharacter)                                                            -- Character不能为空
    or (tbCharacter.ObjectType ~= GameObjectTypeDef.PlayerSelf)                     -- Character的ObjectType必须为PlayerSelf
    or BotAISystem:IsBot(tbCharacter)                                               -- Character不能为Bot
    or ((not IsFightState(self, tbCharacter)) and (nDamage <= 0)) then              -- 不处于战斗状态且伤害值小于0时不上传
        return
    end
    LogOnceFight(self, tbCharacter, nWeaponTemplateId, nDamage)
end

function FFAFightLogEventOp:Init()
    FFAFightLogEventOp.super.Init(self)
    LOG("Init")
    self.tbTotalPersistentFightMap = {}
    self.tbTotalPersistentFightCountMap = {}
    self.tbLastPersistentFightTimeMap = {}
    EventManager:BindEventMethod(CommonEventDef.EV_ON_TAKE_DAMAGE, self, OnTakeDamage)
    EventManager:BindEventMethod(CommonEventDef.EV_ON_CHARACTER_ATTACKED, self, OnCharacterAttacked)
end

function FFAFightLogEventOp:Uninit()
    EventManager:UnBindEventMethod(CommonEventDef.EV_ON_CHARACTER_ATTACKED, self, OnCharacterAttacked)
    EventManager:UnBindEventMethod(CommonEventDef.EV_ON_TAKE_DAMAGE, self, OnTakeDamage)
    self.tbLastPersistentFightTimeMap = nil
    self.tbTotalPersistentFightCountMap = nil
    self.tbTotalPersistentFightMap = nil
    LOG("Uninit")
    FFAFightLogEventOp.super.Uninit(self)
end

--游戏结束时(有队伍吃鸡或者副本回收)触发
function FFAFightLogEventOp:OnBattleEnd()
    LOG("OnBattleEnd")
    HandleAllPlayerPersistentFight(self)
    FFAFightLogEventOp.super.OnBattleEnd(self)
end

return FFAFightLogEventOp