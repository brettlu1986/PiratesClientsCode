-- Npc的Group组死亡数量

local luaclass = require("luaclass")
local BattleTargetBaseClass = require("BattleTargetBase")
local BattleNpcGroupDeadTarget = luaclass("BattleNpcGroupDeadTarget", BattleTargetBaseClass)

local CommonEventDef = require("CommonEventDef")
local EventManager = require("EventManager")
local GameObjectTypeDef = require("GameObjectTypeDef")

BattleNpcGroupDeadTarget.nMaxDeadCount = 0
BattleNpcGroupDeadTarget.nCurrentDeadCount = 0

-- key : nGroupIndex
-- value : info data
-- {
--      CampType    = xx,
--      nMaxDeadCount = xx,
--      nCurrentDeadCount = xx,
-- }
BattleNpcGroupDeadTarget.tbGroupInfoMap = nil

local function IsAllGroupDead(self)
    for nGroupIndex, tbGroupInfo in pairs(self.tbGroupInfoMap) do
        if tbGroupInfo.nCurrentDeadCount < tbGroupInfo.nMaxDeadCount then
          --  log('BattleNpcGroupDeadTarget IsAllGroupDead() group index : ', nGroupIndex, tbGroupInfo.nCurrentDeadCount, tbGroupInfo.nMaxDeadCount)
            return false
        end
    end
    return true
end

function BattleNpcGroupDeadTarget:PrintInfo()
    local BaseUtil = require("BaseUtil")
    BaseUtil:PrintTable(self.tbGroupInfoMap)
end

function BattleNpcGroupDeadTarget:Init()
    BattleNpcGroupDeadTarget.super.Init(self)
    self.szName = "BattleNpcGroupDeadTarget"
    self.tbGroupInfoMap = {}
end

function BattleNpcGroupDeadTarget:AddGroupInfo(nGroupIndex, CampType, nMaxDeadCount)
    if self.tbGroupInfoMap[nGroupIndex] == nil then
        self.tbGroupInfoMap[nGroupIndex] = {}
    end

    local tbGroupInfo = self.tbGroupInfoMap[nGroupIndex]
    tbGroupInfo.CampType            = CampType
    tbGroupInfo.nMaxDeadCount       = nMaxDeadCount
    tbGroupInfo.nCurrentDeadCount   = 0
end

function BattleNpcGroupDeadTarget:OnPawnDead(DeadGameNpc)
    if(DeadGameNpc.ObjectType ~= GameObjectTypeDef.Npc) then
        log('BattleNpcGroupDeadTarget:OnPawnDead(), dead game object type not fit : ', DeadGameNpc.ObjectType)
        return
    end

    local nDeadNpcGroupIndex = DeadGameNpc:GetGroupIndex()
    local tbGroupNpcInfo = self.tbGroupInfoMap[nDeadNpcGroupIndex]
    if tbGroupNpcInfo == nil then
        logerror('BattleNpcGroupDeadTarget:OnPawnDead() dead npc group index not find in target : ', nDeadNpcGroupIndex)
        return
    end

    -- 死亡Npc的CampType不是目标CampType
    if DeadGameNpc.BattleCampComponent:GetCampType() ~= tbGroupNpcInfo.CampType then
        log('BattleNpcGroupDeadTarget:OnPawnDead() not target camp : ', DeadGameNpc.CampType)
        return
    end

    tbGroupNpcInfo.nCurrentDeadCount = tbGroupNpcInfo.nCurrentDeadCount + 1
    if IsAllGroupDead(self) == true then
        self:Complete()
    end
end

function BattleNpcGroupDeadTarget:OnLogout(tbGamePlayer)
    if(not tbGamePlayer:IsDead()) then
        self:OnPawnDead(tbGamePlayer)
    end
end

function BattleNpcGroupDeadTarget:RegisterEvent()
    EventManager:BindEventMethod(CommonEventDef.EV_GAME_OBJECT_ON_PAWN_DEAD, self, self.OnPawnDead)
    EventManager:BindEventMethod(CommonEventDef.EV_BATTLE_PLAYER_LOGOUT, self, self.OnLogout)
end

function BattleNpcGroupDeadTarget:UnregisterEvent()
    EventManager:UnBindEventMethod(CommonEventDef.EV_GAME_OBJECT_ON_PAWN_DEAD, self, self.OnPawnDead)   
    EventManager:UnBindEventMethod(CommonEventDef.EV_BATTLE_PLAYER_LOGOUT, self, self.OnLogout)
end


return BattleNpcGroupDeadTarget
