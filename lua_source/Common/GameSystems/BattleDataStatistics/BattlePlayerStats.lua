-----------------------------------------------------
--File Name    : BattlePlayerStats.lua
--Author       : Song Fuhao
--Create Time  : 2017-08-29
--Description  : 战斗内玩家数据统计
-----------------------------------------------------
local luaclass = require("luaclass")
local BattleCharacterStats = require("BattleCharacterStats")
local BattlePlayerStats = luaclass("BattlePlayerStats", BattleCharacterStats)
local BattleDataStatisticsPropertyDef = require("BattleDataStatisticsPropertyDef")
local BattleDataStatisticsEnum = require("BattleDataStatisticsEnum")
local PropertyDef = require("BattleDataStatisticsPropertyFieldDef")
local BattleStatsHelper = require("BattleStatsHelper")

BattlePlayerStats.tbOtherPlayerDamageMap = nil
BattlePlayerStats.tbConsumeItemMap = nil
BattlePlayerStats.tbBuildItemMap = nil
BattlePlayerStats.tbKillDamageTypeMap = nil
BattlePlayerStats.tbKillRegionTypeMap = nil
BattlePlayerStats.tbKillMoveStateTypeMap = nil
BattlePlayerStats.tbDamagedArray = nil
BattlePlayerStats.tbItems = nil

function BattlePlayerStats:Create(tbCharacter)
    self.tbCharacter = tbCharacter
    self.tbOtherPlayerDamageMap = {}
    self.tbConsumeItemMap = {}
    self.tbBuildItemMap = {}
    self.tbKillDamageTypeMap = {}
    self.tbKillRegionTypeMap = {}
    self.tbKillMoveStateTypeMap = {}
    self.tbDamagedArray = {}
    
    BattlePlayerStats.super.Create(self, tbCharacter)
end

function BattlePlayerStats:Destroy()
    self.tbOtherPlayerDamageMap = nil
    self.tbOtherPlayerDamageMap = nil
    self.tbConsumeItemMap = nil
    self.tbBuildItemMap = nil
    self.tbKillDamageTypeMap = nil
    self.tbKillRegionTypeMap = nil
    self.tbKillMoveStateTypeMap = nil
    self.tbDamagedArray = nil
    self.tbItems = nil
    BattlePlayerStats.super.Destroy(self)
end

function BattlePlayerStats:RegisterDefaultProperty()
    BattlePlayerStats.super.RegisterDefaultProperty(self)

    local tbCharacter = self.tbCharacter
    self:RegisterProperty(PropertyDef.PLAYERID, tbCharacter.nPlayerId)
    self:RegisterProperty(PropertyDef.GRADE, tbCharacter.tbPrepareInfo and tbCharacter.tbPrepareInfo.nGrade or 0)
    self:RegisterProperty(PropertyDef.TEAMID,   tbCharacter.BattleTeamComponent.nTeamId)
    self:RegisterProperty(PropertyDef.LOGINOUT, 0)
    for _, v in ipairs(BattleDataStatisticsPropertyDef.tbPlayerPropertyDef) do
        if v.PropertySource == BattleDataStatisticsEnum.LuaScript then
            self:RegisterProperty(v.Name, v.DefaultValue)
        end
    end
end

function BattlePlayerStats:GetProperty(szKey)
    local varProperty = self.tbProperty[szKey]
    if varProperty then
        return varProperty
    else
        logwarning("[BattlePlayerStats] get property failed, this key is not register :", szKey)
        return 0
    end
end

function BattlePlayerStats:Reset()
    self:SetProperty(PropertyDef.LOGINOUT, 0)
    for _, v in ipairs(BattleDataStatisticsPropertyDef.tbPlayerPropertyDef) do
        if v.PropertySource == BattleDataStatisticsEnum.LuaScript then
            self:SetProperty(v.Name, v.DefaultValue)
        end
    end
    self.tbOtherPlayerDamageMap = {}
    self.tbConsumeItemMap = {}
    self.tbBuildItemMap = {}
    self.tbKillDamageTypeMap = {}
    self.tbKillRegionTypeMap = {}
    self.tbKillMoveStateTypeMap = {}
    self.tbDamagedArray = {}
end

function BattlePlayerStats:ClearDamaged()
    self.tbDamagedArray = {}
end

-- self是挨打者 统计
function BattlePlayerStats:ProcessDamaged(tbDamageData)
    table.insert(self.tbDamagedArray, tbDamageData)
    self.tbDamagedArray = BattleStatsHelper.ArrangeDamagedArray(self.tbDamagedArray)
    log("[stats] --- process damaged ", self:GetProperty(PropertyDef.PLAYERID), tbDamageData.nDamage, 
        tbDamageData.nDamageType, tbDamageData.nCauserId, tbDamageData.nWeaponTemplateId, #self.tbDamagedArray)
end

function BattlePlayerStats:HitDown(bHitDown)
    log("[stats] --- process hitdown ", bHitDown)
    if bHitDown then
        local tbDamageData = self.tbDamagedArray[#self.tbDamagedArray]
        if tbDamageData ~= nil then
            tbDamageData.bHitDown = true
        end
    else
        for i, v in ipairs(self.tbDamagedArray) do
            if v.bHitDown then
                v.bHitDown = nil
            end
        end
    end
end

-- self是打人者 统计
function BattlePlayerStats:ProcessDamage(nPlayerId, szProperty, tbDamageData)
    local tbOtherPlayer = self.tbOtherPlayerDamageMap[nPlayerId]
    if tbOtherPlayer == nil then
        tbOtherPlayer = 
            {
                nShipDamage = 0, nHumanDamage = 0, bKill = false
            }
        self.tbOtherPlayerDamageMap[nPlayerId] = tbOtherPlayer
    end

    local nDamage = tbDamageData.nDamage

    if szProperty == PropertyDef.APPLYDAMAGETOSHIP then
        tbOtherPlayer.nShipDamage = tbOtherPlayer.nShipDamage + nDamage
    elseif szProperty == PropertyDef.APPLYDAMAGETOHUMAN then
        tbOtherPlayer.nHumanDamage = tbOtherPlayer.nHumanDamage + nDamage
    elseif szProperty == PropertyDef.KILL then
        tbOtherPlayer.bKill = true

        local nDamageType = tbDamageData.nDamageType
        local nRegionType = tbDamageData.nRegionType
        local nMovementState  = tbDamageData.nMovementState
        local nTemplateType = tbDamageData.nTemplateType 

        if nTemplateType ~= nil then
            if self.tbKillDamageTypeMap[nDamageType] == nil then
                self.tbKillDamageTypeMap[nDamageType] = {}
            end 
            if self.tbKillDamageTypeMap[nDamageType][nTemplateType] == nil then
                self.tbKillDamageTypeMap[nDamageType][nTemplateType] = 1
            else
                self.tbKillDamageTypeMap[nDamageType][nTemplateType] = self.tbKillDamageTypeMap[nDamageType][nTemplateType] + 1
            end 
        end
        
        if nRegionType ~= nil then
            if self.tbKillRegionTypeMap[nRegionType] == nil then
                self.tbKillRegionTypeMap[nRegionType] = 1
            else
                self.tbKillRegionTypeMap[nRegionType] = self.tbKillRegionTypeMap[nRegionType] + 1
            end
        end

        if nMovementState > 0 then
            if self.tbKillMoveStateTypeMap[nMovementState] == nil then
                self.tbKillMoveStateTypeMap[nMovementState] = 1
            else
                self.tbKillMoveStateTypeMap[nMovementState] = self.tbKillMoveStateTypeMap[nMovementState] + 1
            end 
        end
    end
end

function BattlePlayerStats:ConsumeItem(nItemTemplateId, nCount)
    if self.tbConsumeItemMap[nItemTemplateId] then
        self.tbConsumeItemMap[nItemTemplateId] = self.tbConsumeItemMap[nItemTemplateId] + nCount
    else
        self.tbConsumeItemMap[nItemTemplateId] = nCount
    end
end

function BattlePlayerStats:BuildItem(nItemTemplateId, nCount)
    if self.tbBuildItemMap[nItemTemplateId] then
        self.tbBuildItemMap[nItemTemplateId] = self.tbBuildItemMap[nItemTemplateId] + nCount
    else
        self.tbBuildItemMap[nItemTemplateId] = nCount
    end
end

function BattlePlayerStats:RecordItems(tbItems)
    self.tbItems = tbItems
end

function BattlePlayerStats:GetOtherPlayerStats()
    return self.tbOtherPlayerDamageMap
end

function BattlePlayerStats:GetConsumeItem()
    return self.tbConsumeItemMap
end

function BattlePlayerStats:GetBuildItem()
    return self.tbBuildItemMap
end

function BattlePlayerStats:GetDamagedStats()
    return self.tbDamagedArray
end

function BattlePlayerStats:GetKillStats()
    return self.tbKillDamageTypeMap
end

function BattlePlayerStats:GetRegionStats()
    return self.tbKillRegionTypeMap
end

function BattlePlayerStats:GetMovementStats()
    return self.tbKillMoveStateTypeMap
end

function BattlePlayerStats:GetItems()
    return self.tbItems
end

return BattlePlayerStats
