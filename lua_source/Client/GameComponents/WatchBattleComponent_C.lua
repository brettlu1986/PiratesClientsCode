local luaclass = require("luaclass")
local WatchBattleComponent = require("WatchBattleComponent")
local WatchBattleComponent_C = luaclass("WatchBattleComponent_C", WatchBattleComponent)
local BattleTeammateSystem = require("BattleTeammateSystem")
local Proto = require("DungeonCommonProtoNames")
local ClientEventDef = require("ClientEventDef")
local EventManager = require("EventManager")
local BitHelper = require("BitHelper")

local EState = Proto.TeamInfo_EState

--用于记录原始队伍人员都是谁，还有人员伤亡状态
WatchBattleComponent_C.tbOriginalTeamInfo = nil
WatchBattleComponent_C.nTeamCount = 0

WatchBattleComponent_C.nCurrentWatchId = -1

WatchBattleComponent_C.tbBattleTeamInfo = nil

WatchBattleComponent_C.tbBaseInfo        = nil
WatchBattleComponent_C.tbHealthInfo      = nil
WatchBattleComponent_C.tbStateInfo       = nil
WatchBattleComponent_C.tbPosInfo         = nil
WatchBattleComponent_C.tbSignInfo        = nil
WatchBattleComponent_C.tbTeamPlayersInfo = nil

WatchBattleComponent_C.tbAllSortedPlayerIds = nil

WatchBattleComponent_C.nBaseInfoNum      = 0
WatchBattleComponent_C.nHealthInfoNum    = 0
WatchBattleComponent_C.nStateInfoNum     = 0
WatchBattleComponent_C.nPosInfoNum       = 0
WatchBattleComponent_C.nSignInfoNum      = 0
WatchBattleComponent_C.nIDInfoNum        = 0
WatchBattleComponent_C.nTeamId           = -1

function WatchBattleComponent_C:OnActorCreated(pUEActor)
    WatchBattleComponent_C.super.OnActorCreated(self, pUEActor)
end

local function SaveBattleTeamInfo(tbCurInfo, tbAllPlayerInfo)
    for Index, tbInfo in pairs(tbCurInfo) do
        local tbPlayerInfo = tbAllPlayerInfo[Index]

        if tbPlayerInfo == nil then
            tbPlayerInfo = {}
            tbAllPlayerInfo[Index] = tbPlayerInfo
        end

        for Key, Value in pairs(tbInfo) do
            tbPlayerInfo[Key] = Value
        end
    end
end

local function SaveBattlePosInfo(tbPosInfo, tbAllPlayerInfo)
    for Index, tbInfo in pairs(tbPosInfo) do
        local tbPlayerInfo = tbAllPlayerInfo[Index]

        if tbPlayerInfo == nil then
            tbPlayerInfo = {}
            tbAllPlayerInfo[Index] = tbPlayerInfo
        end

        local COORDINATE_PROPORTION = 100

        tbPlayerInfo.nPlayerX, tbPlayerInfo.nPlayerY   = BitHelper:PosToXY(tbInfo.nPosXY)
        tbPlayerInfo.nPlayerX = tbPlayerInfo.nPlayerX * COORDINATE_PROPORTION
        tbPlayerInfo.nPlayerY = tbPlayerInfo.nPlayerY * COORDINATE_PROPORTION

        tbPlayerInfo.nPlayerZ, tbPlayerInfo.nPlayerYaw = BitHelper:PosToXY(tbInfo.nPosZYaw)
    end
end

local function SaveBaseInfo(self)
    local tbAllSortedPlayerIds = {}
    for nIndex, tbCurInfo in pairs(self.tbBaseInfo) do
        tbCurInfo.nIndex = nIndex
        table.insert(tbAllSortedPlayerIds, tbCurInfo.nPlayerId)
    end

    self.tbAllSortedPlayerIds = tbAllSortedPlayerIds
end

local function SaveBattleBaseInfoToPlayerInfo(tbBaseInfo, nPlayerId, tbPlayerInfo)
    for _, tbCurInfo in pairs(tbBaseInfo) do
        if tbCurInfo.nPlayerId == nPlayerId then
            for Key, Value in pairs(tbCurInfo) do
                tbPlayerInfo[Key] = Value
            end
            
            return true
        end
    end

    return false
end

local function CheckAllDataReceived(self, bPosChanged, bBaseChanged)
    if bBaseChanged then
        SaveBaseInfo(self)
    end

    -- logdebug("[client watch] 1 nIDInfoNum, nBaseInfoNum nHealthInfoNum nStateInfoNum nPosInfoNum nSignInfoNum", 
        -- self.nIDInfoNum,self.nBaseInfoNum,self.nHealthInfoNum, self.nStateInfoNum,self.nPosInfoNum, self.nSignInfoNum )
    if self.nIDInfoNum     > 0                    and 
       self.nIDInfoNum     == self.nHealthInfoNum and
       self.nHealthInfoNum == self.nStateInfoNum  and
       self.nStateInfoNum  == self.nPosInfoNum    and
       self.nPosInfoNum    == self.nSignInfoNum   and 
       self.nBaseInfoNum   >= self.nIDInfoNum     then

        local tbAllPlayerInfo = {}
        SaveBattleTeamInfo(self.tbHealthInfo, tbAllPlayerInfo)
        SaveBattleTeamInfo(self.tbStateInfo,  tbAllPlayerInfo)
        SaveBattlePosInfo (self.tbPosInfo,    tbAllPlayerInfo)
        SaveBattleTeamInfo(self.tbSignInfo,   tbAllPlayerInfo)

        local tbTeamInfos = {}
        --按照tbTeamPlayersInfo存储的顺序组数据
        local tbInstanceIds = self.tbTeamPlayersInfo.tbInstanceIds
        for Index, nCurInstanceId in pairs(tbInstanceIds) do
            local tbPlayerInfo = tbAllPlayerInfo[Index]
            if not tbPlayerInfo then
                return
            end
            -- logdebug("[client watch] 1", require("dkjson").encode(self.tbBaseInfo))
            -- logdebug("[client watch] 2", require("dkjson").encode(self.tbHealthInfo))
            -- logdebug("[client watch] 3", require("dkjson").encode(self.tbStateInfo))
            tbPlayerInfo.nInstanceId = nCurInstanceId
            local nPlayerId = self.tbTeamPlayersInfo.tbPlayerIds[Index]
            local bFound = SaveBattleBaseInfoToPlayerInfo(self.tbBaseInfo, nPlayerId, tbPlayerInfo)
            
            if bFound then
                table.insert( tbTeamInfos, tbPlayerInfo )
            end
        end

        self.tbBattleTeamInfo = {}
        local nVarTeamId = self.tbTeamPlayersInfo.nTeamId
        self.nTeamId = nVarTeamId
        self.tbBattleTeamInfo.nTeamId      = nVarTeamId
        self.tbBattleTeamInfo.nPlayerCount = #self.tbBaseInfo
        self.tbBattleTeamInfo.TeamInfos    = tbTeamInfos
        
        if not bPosChanged then
            log("[ClientWatch] WatchBattleComponent_C EV_FFA_TEAM_INFO_CHANGED Info:", require("dkjson").encode(self.tbBattleTeamInfo))
        end

        EventManager:OnFireEvent(ClientEventDef.EV_FFA_TEAM_INFO_CHANGED, self.tbBattleTeamInfo)
    end
end

local function OnBattleTeamInfoChanged(self, tbInfo, szTbInfoKey, szInfoKey, szNumKey, bPosChanged, bBaseChanged)
    -- logerror("~~~---", require("dkjson").encode(tbInfo))
    if tbInfo and tbInfo[szTbInfoKey] then
        self[szInfoKey] = tbInfo[szTbInfoKey]
        self[szNumKey]  = #self[szInfoKey]

        CheckAllDataReceived(self, bPosChanged, bBaseChanged)
    end
end

function WatchBattleComponent_C:OnBattleTeamBaseInfoChanged(_Property, tbBattleTeamBaseInfo)
    log("[ClientWatch] WatchBattleComponent_C:OnBattleTeamBaseInfoChanged")
    -- logdebug("[client watch] tbBattleTeamBaseInfo", require("dkjson").encode(tbBattleTeamBaseInfo))
    OnBattleTeamInfoChanged(self, tbBattleTeamBaseInfo, "BaseInfos", "tbBaseInfo", "nBaseInfoNum", false, true)
end

function WatchBattleComponent_C:OnBattleTeamHealthInfoChanged(_Property, tbBattleTeamHealthInfo)
    log("[ClientWatch] WatchBattleComponent_C:OnBattleTeamHealthInfoChanged")
    -- logdebug("[client watch] tbBattleTeamHealthInfo", require("dkjson").encode(tbBattleTeamHealthInfo))
    OnBattleTeamInfoChanged(self, tbBattleTeamHealthInfo, "HealthInfos", "tbHealthInfo", "nHealthInfoNum")
end

function WatchBattleComponent_C:OnBattleTeamStateInfoChanged(_Property, tbBattleTeamStateInfo)
    log("[ClientWatch] WatchBattleComponent_C:OnBattleTeamStateInfoChanged")
    -- logdebug("[client watch] tbBattleTeamStateInfo", require("dkjson").encode(tbBattleTeamStateInfo))
    OnBattleTeamInfoChanged(self, tbBattleTeamStateInfo, "StateInfos", "tbStateInfo", "nStateInfoNum")
end

function WatchBattleComponent_C:OnBattleTeamPosInfoChanged(_Property, tbBattleTeamPosInfo)
    -- logdebug("[client watch] tbBattleTeamPosInfo", require("dkjson").encode(tbBattleTeamPosInfo))
    OnBattleTeamInfoChanged(self, tbBattleTeamPosInfo, "PosInfos", "tbPosInfo", "nPosInfoNum", true)
end

function WatchBattleComponent_C:OnBattleTeamSignInfoChanged(_Property, tbBattleTeamSignInfo)
    log("[ClientWatch] WatchBattleComponent_C:OnBattleTeamSignInfoChanged")
    -- logdebug("[client watch] tbBattleTeamSignInfo", require("dkjson").encode(tbBattleTeamSignInfo))
    OnBattleTeamInfoChanged(self, tbBattleTeamSignInfo, "SignInfos", "tbSignInfo", "nSignInfoNum")
end

function WatchBattleComponent_C:OnTeamPlayersInfoChanged(_Property, tbTeamPlayersInfo)
    log("[ClientWatch] WatchBattleComponent_C:OnTeamPlayersInfoChanged")
    -- logerror("~~~--- 111111", require("dkjson").encode(tbTeamPlayersInfo))
    -- logdebug("[client watch] tbTeamPlayersInfo", require("dkjson").encode(tbTeamPlayersInfo))
    if tbTeamPlayersInfo and tbTeamPlayersInfo.nTeamId then

        self.tbTeamPlayersInfo = tbTeamPlayersInfo
        self.nIDInfoNum        = #self.tbTeamPlayersInfo.tbInstanceIds
        BattleTeammateSystem:SyncBPTeamSystemOnClient(tbTeamPlayersInfo)
        CheckAllDataReceived(self, false)
    end
end

function WatchBattleComponent_C:SetTeamCount(nCount)
    self.nTeamCount = nCount
end

function WatchBattleComponent_C:GetTeamCount()
    return self.nTeamCount
end

function WatchBattleComponent_C:InitOriginalTeamData(tbTeamInfo)
    if tbTeamInfo == nil then  
        return
    end
    for k, v in ipairs(tbTeamInfo) do
        local tbInfo = {}
        tbInfo.nInstanceId = v.nInstanceId
        tbInfo.bDead = v.nState == EState.DEAD
        table.insert(self.tbOriginalTeamInfo, tbInfo)
    end
end

function WatchBattleComponent_C:IsEmptyOriginalInfo()
    return self.tbOriginalTeamInfo and #self.tbOriginalTeamInfo == 0
end

local function GetRepOriginalTeamMemberDeadState(self, nInsId)
    local BattleTeamComponent = self.Owner.BattleTeamComponent
    local tbBattleTeamInfo = BattleTeamComponent.tbBattleTeamInfo
    if tbBattleTeamInfo and tbBattleTeamInfo.TeamInfos then
        local tbTeamInfos = tbBattleTeamInfo.TeamInfos
        for k, v in ipairs(tbTeamInfos) do
            if v.nInstanceId == nInsId then   
                return v.nState
            end
        end
    end
    return nil
end
--单人模式也有Team的概念，只不过是一个人
function WatchBattleComponent_C:IsOriginalTeamDead()
    local bTeamDead = true
    if self:IsEmptyOriginalInfo() then   
        bTeamDead = false 
    else 
        
        for _, v in pairs(self.tbOriginalTeamInfo) do  
            local nTeamDeadState = GetRepOriginalTeamMemberDeadState(self, v.nInstanceId)
            if nTeamDeadState ~= nil and nTeamDeadState == EState.DEAD and v.bDead == false then   
                v.bDead = true
            end

            if v.bDead == false then   
                bTeamDead = false  
                break
            end
        end
    end
    return bTeamDead
end

function WatchBattleComponent_C:ProcessOriginalTeamDead(nDeaderInsId)
    for _, v in pairs(self.tbOriginalTeamInfo) do   
        if v.nInstanceId == nDeaderInsId then  
            v.bDead = true
        end
    end 
end

function WatchBattleComponent_C:OnCreate(Owner, tbParams)
    WatchBattleComponent_C.super.OnCreate(self, Owner, tbParams)
    self.nTeamCount = 0
    self.tbOriginalTeamInfo = {}
    self.nTeamId = -1
    self.nCurrentWatchId = -1
    return true
end

function WatchBattleComponent_C:OnDestroy()
    WatchBattleComponent_C.super.OnDestroy(self)
end

function WatchBattleComponent_C:Reset()
    self.nBaseInfoNum      = 0
    self.nHealthInfoNum    = 0
    self.nStateInfoNum     = 0
    self.nPosInfoNum       = 0
    self.nSignInfoNum      = 0
    self.nIDInfoNum        = 0
end

function WatchBattleComponent_C:GetTeamBaseInfo()
    return self.tbBaseInfo
end

return WatchBattleComponent_C 