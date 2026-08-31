-----------------------------------------------------
--File Name    : NPCSpawner.lua
--Author       : Zuo Kun
--Create Time  : 2017-04-13
--Description  : NPCSpawner
-----------------------------------------------------
local luaclass = require("luaclass")
local NPCSpawnerBaseClass = require("NPCSpawnerBase")
local NPCSpawner = luaclass("NPCSpawner", NPCSpawnerBaseClass)

local GameObjectSystem = dynamic_require("GameObjectSystem")
local GOCreateDataHelper = dynamic_require("GOCreateDataHelper")
local GameNpc = dynamic_require("GameNpc")
local SpawnerDef = require("SpawnerDef")
local DungeonDifficultyDataTable = require("DungeonDifficultyDataTable")
local BattleGameModeSystem = dynamic_require("BattleGameModeSystem")

NPCSpawner.nObjectUniqueId = nil

function NPCSpawner:OnCreate(tbParams)
    -- 先将DifficultyId解析成对应的TemplateId 
    if tbParams.DifficultyId and tbParams.DifficultyId > 0 then
        local nLevel = BattleGameModeSystem:GetGameInitData().difficulty
        if nLevel ~= nil then
            local newTemplateId = DungeonDifficultyDataTable:GetNpc(tbParams.DifficultyId, nLevel)
            tbParams.TemplateId = newTemplateId
        end
    end
    NPCSpawner.super.OnCreate(self, tbParams)

    self.nType = SpawnerDef.SpawnerType.NPC
    if(self.nTemplateId < 0) then
        logerror("NPCSpawner:OnCreate failed, the nTemplateId is invalid", self.nSpawnerId)
        return false
    end
    return true
end 

function NPCSpawner:Spawn()
    log("NPCSpawner:Spawn", self.nSpawnerId, self.nTemplateId,
        self.nX, self.nY, self.nZ, self.nYaw,
        self.nGroupIndex, self.nDifficultyId)
    
    -- local tbRet = GameObjectSystem:CreateNpcInGameMode(self.nTemplateId, 
    --     self.nX, self.nY, self.nZ, self.nYaw,
    --     self.nGroupIndex, self.szTag, self.tbCreateParams)
    self.tbJsonData = self.tbCreateParams
    local tbRet = GameObjectSystem:CreateNpcInGameMode(self)    -- self拥有spawninfo用到的所有参数
    if(tbRet) then
        self.nObjectUniqueId = tbRet:GetUEActorUniqueId()
    end
    return tbRet
end

function NPCSpawner:CollectResource(tbInOutResources)
    self.tbJsonData = self.tbCreateParams
    -- local tbCreateData = GOCreateDataHelper:ParseNpcGameModeData(-1, self.nTemplateId, 
    --     self.nX, self.nY, self.nZ, self.nYaw,
    --     self.nGroupIndex, self.szTag, self.tbCreateParams)
    local tbCreateData = GOCreateDataHelper:ParseNpcGameModeData(-1, self)    
    local szRes = GameNpc.StaticCollectResources(tbCreateData, nil)
    if(szRes) then
        table.insert(tbInOutResources, szRes)
    end
end


return NPCSpawner
