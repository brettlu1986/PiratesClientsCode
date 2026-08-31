-----------------------------------------------------
--File Name    : BattleHistoryComponent.lua
--Author       : Chen Jing
--Create Time  : 2018-02-22
--Description  : 玩家个人历程的数据储存
-----------------------------------------------------

local luaclass = require("luaclass")
local GameComponentBase = require("GameComponentBase")
local BattleHistoryComponent = luaclass("BattleHistoryComponent", GameComponentBase)
local SaveGameDef = require("SaveGameDef")

BattleHistoryComponent.tbPvPStats = nil
BattleHistoryComponent.tbPvEStats = nil
BattleHistoryComponent.tbBattleRecords = nil                --缓存服务器发过来的历史战斗概况
BattleHistoryComponent.nLastBattleRecordId = 0              --服务器上一次发过来历史战斗概况的Id
BattleHistoryComponent.tbDetailedBattleRecords = nil        --本地战斗记录列表
BattleHistoryComponent.nCacheRecordId = 0                   --缓存服务器发过来的战斗记录Id

local nMaxSavedDetailedBattleRecord = 30

function BattleHistoryComponent:SetPvPStats(tbPvPStats)
    self.tbPvPStats = tbPvPStats
end

function BattleHistoryComponent:SetPvEStats(tbPvEStats)
    self.tbPvEStats = tbPvEStats
end

function BattleHistoryComponent:SetBattleRecords(tbBattleRecords)
    self.tbBattleRecords = tbBattleRecords
end

function BattleHistoryComponent:GetLastBattleRecordId()
    return self.nLastBattleRecordId
end

local function fnSort(a, b)
    return a.nRecordId > b.nRecordId
end

function BattleHistoryComponent:LoadDetailedBattleRecord()
    if not self.tbDetailedBattleRecords then
        self.tbDetailedBattleRecords = { }
        local pSaveGameMgr = ClientShell.GetClient(GWorld):GetSaveGameManager()
        local nNumDetailedBattleRecord = pSaveGameMgr:GetIntData(SaveGameDef.NUM_DETAILED_BATTLE_RECORD)
        if not nNumDetailedBattleRecord or nNumDetailedBattleRecord <= 0 then
            return
        end
        for i = 1, nNumDetailedBattleRecord do
            local szDetaildedRecord = pSaveGameMgr:GetStringData(SaveGameDef.DETAILED_BATTLE_RECORD_DATA .. "_" .. i)
            if szDetaildedRecord then
                local tbDetaildedRecord = { }
                for k, v in string.gmatch(szDetaildedRecord, "(%w+)=(%d+)") do
                    tbDetaildedRecord[k] = v
                end
                table.insert(self.tbDetailedBattleRecords, tbDetaildedRecord)
            end
        end
        if #self.tbDetailedBattleRecords > 0 then
            table.sort(self.tbDetailedBattleRecords, fnSort)
        end
    end
end

function BattleHistoryComponent:SaveDetailedBattleRecord()
    
    if self.tbDetailedBattleRecords and #self.tbDetailedBattleRecords > 0 then
        local numDetailedBattleRecord = #self.tbDetailedBattleRecords
        if numDetailedBattleRecord > nMaxSavedDetailedBattleRecord then
            numDetailedBattleRecord = nMaxSavedDetailedBattleRecord
        end
        local pSaveGameMgr = ClientShell.GetClient(GWorld):GetSaveGameManager()
        pSaveGameMgr:AddIntData(SaveGameDef.NUM_DETAILED_BATTLE_RECORD, numDetailedBattleRecord)
 
        for i = 1, numDetailedBattleRecord do
            local tbDetaildedRecord = self.tbDetailedBattleRecords[i]
            local szDetaildedRecord = ""
            for k,v in pairs(tbDetaildedRecord) do
                szDetaildedRecord = szDetaildedRecord .. k .. "=" .. v .. ","
            end
          
            pSaveGameMgr:AddStringData(SaveGameDef.DETAILED_BATTLE_RECORD_DATA .. "_" .. i, szDetaildedRecord)
        end
        pSaveGameMgr:Save()
    end
end

function BattleHistoryComponent:SaveLastDetailedBattleRecord(nRecordId)
    self.nCacheRecordId = nRecordId
    self.nLastBattleRecordId = nRecordId
    
end

function BattleHistoryComponent:SetLastDetailedBattleRecord(tbLastDetailedBattleRecord)
    if tbLastDetailedBattleRecord and self.nCacheRecordId > 0 then
        tbLastDetailedBattleRecord.nRecordId = self.nCacheRecordId
        self.tbDetailedBattleRecords = self.tbDetailedBattleRecords or { }
        table.insert(self.tbDetailedBattleRecords, tbLastDetailedBattleRecord)
        table.sort(self.tbDetailedBattleRecords, fnSort)
        for _ = #self.tbDetailedBattleRecords, nMaxSavedDetailedBattleRecord + 1, -1 do
            table.remove(self.tbDetailedBattleRecords)
        end
        self:SaveDetailedBattleRecord()
        self.nCacheRecordId = 0
    end
end

function BattleHistoryComponent:GetDetailedBattleRecord(nRecordId)
    for _,v in ipairs(self.tbDetailedBattleRecords) do
        if v.nRecordId == nRecordId then
            return v
        end
    end
end

function BattleHistoryComponent:OnCreate(Owner, tbParams)
    local bRet = BattleHistoryComponent.super.OnCreate(self, Owner, tbParams)
    if not bRet then
        return
    end
    return true
end

function BattleHistoryComponent:OnDestroy()
    BattleHistoryComponent.super.OnDestroy(self)
end

return BattleHistoryComponent
