local luaclass = require("luaclass")
local BattleTeamComponent = require("BattleTeamComponent")
local BattleTeamComponent_C = luaclass("BattleTeamComponent_C", BattleTeamComponent)

local BitHelper = require("BitHelper")
local EventManager = require("EventManager")
local ClientEventDef = require("ClientEventDef")
local GameObjectTypeDef = require("GameObjectTypeDef")
local BattleTeammateSystem  = require("BattleTeammateSystem")


BattleTeamComponent_C.tbBattleTeamInfo = nil

BattleTeamComponent_C.tbBaseInfo        = nil
BattleTeamComponent_C.tbHealthInfo      = nil
BattleTeamComponent_C.tbStateInfo       = nil
BattleTeamComponent_C.tbPosInfo         = nil
BattleTeamComponent_C.tbSignInfo        = nil
BattleTeamComponent_C.tbTeamPlayersInfo = nil

BattleTeamComponent_C.tbAllSortedPlayerIds = nil

BattleTeamComponent_C.nBaseInfoNum      = 0
BattleTeamComponent_C.nHealthInfoNum    = 0
BattleTeamComponent_C.nStateInfoNum     = 0
BattleTeamComponent_C.nPosInfoNum       = 0
BattleTeamComponent_C.nSignInfoNum      = 0
BattleTeamComponent_C.nIDInfoNum        = 0


function BattleTeamComponent_C:OnCreate(Owner, tbParams)
    BattleTeamComponent_C.super.OnCreate(self, Owner, tbParams)
    return true
end

function BattleTeamComponent_C:OnActorCreated(pUEActor)
    BattleTeamComponent_C.super.OnActorCreated(self, pUEActor)

    local bPlayerSelf = (self.Owner.ObjectType == GameObjectTypeDef.PlayerSelf)

    if bPlayerSelf then
        log("BattleTeamComponent_C:OnActorCreated")
        self:Reset()

        if self.rBattleTeamBaseInfo then
           self:OnBattleTeamBaseInfoChanged(self.rBattleTeamBaseInfo, self.rBattleTeamBaseInfo:Get())
        end

        if self.rBattleTeamHealthInfo then
            self:OnBattleTeamHealthInfoChanged(self.rBattleTeamHealthInfo, self.rBattleTeamHealthInfo:Get())
        end

        if self.rBattleTeamStateInfo then
           self:OnBattleTeamStateInfoChanged(self.rBattleTeamStateInfo, self.rBattleTeamStateInfo:Get())
        end

        if self.rBattleTeamPosInfo then
           self:OnBattleTeamPosInfoChanged(self.rBattleTeamPosInfo, self.rBattleTeamPosInfo:Get())
        end

        if self.rBattleTeamSignInfo then
           self:OnBattleTeamSignInfoChanged(self.rBattleTeamSignInfo, self.rBattleTeamSignInfo:Get())
        end

        if self.rTeamPlayersInfo then
            self:OnTeamPlayersInfoChanged(self.rTeamPlayersInfo, self.rTeamPlayersInfo:Get())
        end
    end
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

            tbPlayerInfo.nInstanceId = nCurInstanceId
            local nPlayerId = self.tbTeamPlayersInfo.tbPlayerIds[Index]
            local bFound = SaveBattleBaseInfoToPlayerInfo(self.tbBaseInfo, nPlayerId, tbPlayerInfo)

            if bFound then
                table.insert( tbTeamInfos, tbPlayerInfo )
            end
        end

        self.tbBattleTeamInfo = {}
        self.tbBattleTeamInfo.TeamInfos    = tbTeamInfos
        self.tbBattleTeamInfo.nTeamId      = self.tbTeamPlayersInfo.nTeamId
        self.tbBattleTeamInfo.nPlayerCount = #self.tbBaseInfo

        if not bPosChanged then
            log("BattleTeamComponent_C EV_FFA_TEAM_INFO_CHANGED Info:", require("dkjson").encode(self.tbBattleTeamInfo))
        end

        EventManager:OnFireEvent(ClientEventDef.EV_FFA_TEAM_INFO_CHANGED, self.tbBattleTeamInfo)
    end
end

local function OnBattleTeamInfoChanged(self, tbInfo, szTbInfoKey, szInfoKey, szNumKey, bPosChanged, bBaseChanged)
    if tbInfo and tbInfo[szTbInfoKey] then
        self[szInfoKey] = tbInfo[szTbInfoKey]
        self[szNumKey]  = #self[szInfoKey]

        CheckAllDataReceived(self, bPosChanged, bBaseChanged)
    end
end

function BattleTeamComponent_C:OnBattleTeamBaseInfoChanged(_Property, tbBattleTeamBaseInfo)
    log("BattleTeamComponent_C OnBattleTeamBaseInfoChanged")
    OnBattleTeamInfoChanged(self, tbBattleTeamBaseInfo, "BaseInfos", "tbBaseInfo", "nBaseInfoNum", false, true)
end

function BattleTeamComponent_C:OnBattleTeamHealthInfoChanged(_Property, tbBattleTeamHealthInfo)
    log("BattleTeamComponent_C OnBattleTeamHealthInfoChanged")
    OnBattleTeamInfoChanged(self, tbBattleTeamHealthInfo, "HealthInfos", "tbHealthInfo", "nHealthInfoNum")
end

function BattleTeamComponent_C:OnBattleTeamStateInfoChanged(_Property, tbBattleTeamStateInfo)
    log("BattleTeamComponent_C OnBattleTeamStateInfoChanged")
    OnBattleTeamInfoChanged(self, tbBattleTeamStateInfo, "StateInfos", "tbStateInfo", "nStateInfoNum")
end

function BattleTeamComponent_C:OnBattleTeamPosInfoChanged(_Property, tbBattleTeamPosInfo)
    OnBattleTeamInfoChanged(self, tbBattleTeamPosInfo, "PosInfos", "tbPosInfo", "nPosInfoNum", true)
end

function BattleTeamComponent_C:OnBattleTeamSignInfoChanged(_Property, tbBattleTeamSignInfo)
    log("BattleTeamComponent_C OnBattleTeamSignInfoChanged")
    OnBattleTeamInfoChanged(self, tbBattleTeamSignInfo, "SignInfos", "tbSignInfo", "nSignInfoNum")
end

function BattleTeamComponent_C:OnTeamPlayersInfoChanged(_Property, tbTeamPlayersInfo)
    log("BattleTeamComponent_C OnTeamPlayersInfoChanged")

    if tbTeamPlayersInfo and tbTeamPlayersInfo.nTeamId then
       local nServerInstanceId = self.Owner.nServerInstanceId
       local bFound = false

       for _, curId in pairs(tbTeamPlayersInfo.tbInstanceIds) do
           if curId == nServerInstanceId then
               bFound = true
               break
           end
       end

       self.tbTeamPlayersInfo = tbTeamPlayersInfo
       self.nIDInfoNum        = #self.tbTeamPlayersInfo.tbInstanceIds

       log("OnTeamPlayersInfoChanged:", tbTeamPlayersInfo.nTeamId, #(tbTeamPlayersInfo.tbInstanceIds))

       BattleTeammateSystem:SetPacket(tbTeamPlayersInfo)
       BattleTeammateSystem:SyncBPTeamSystemOnClient(tbTeamPlayersInfo)

       if bFound then
           if self.nTeamId ~= tbTeamPlayersInfo.nTeamId then
               self:RemoveFromTeam()
               self:AddToTeam(tbTeamPlayersInfo.nTeamId)
           end
       else
           self:RemoveFromTeam()
       end

       EventManager:OnFireEvent(ClientEventDef.EV_GAME_STATE_ON_RECV_TEAM_INFOS)
       CheckAllDataReceived(self, false)
    end
end

function BattleTeamComponent_C:GetTeamInfos()
    return self.tbBattleTeamInfo and self.tbBattleTeamInfo.TeamInfos
end

function BattleTeamComponent_C:GetMemberInfo(nInstanceId)
    if self.tbBattleTeamInfo == nil then
        return
    end
    for k, v in ipairs(self.tbBattleTeamInfo.TeamInfos) do
        if v.nInstanceId == nInstanceId then
            return v
        end
    end
end

function BattleTeamComponent_C:GetInstanceIdByPlayerId(nPlayerId)
    if self.tbTeamPlayersInfo == nil or self.tbTeamPlayersInfo.tbPlayerIds == nil
        or self.tbBattleTeamInfo == nil  or self.tbBattleTeamInfo.TeamInfos == nil then 
        return nil
    end
    local nIdx = nil  
    for k, v in ipairs(self.tbTeamPlayersInfo.tbPlayerIds) do 
        if nPlayerId == v then  
            nIdx = k
            break;
        end
    end

    if nIdx ~= nil and self.tbBattleTeamInfo.TeamInfos[nIdx] ~= nil then 
        return self.tbBattleTeamInfo.TeamInfos[nIdx].nInstanceId
    end
    return nil
end

function BattleTeamComponent_C:Reset()
    self.nBaseInfoNum   = 0
    self.nHealthInfoNum = 0
    self.nStateInfoNum  = 0
    self.nPosInfoNum    = 0
    self.nSignInfoNum   = 0
    self.nIDInfoNum     = 0
end

function BattleTeamComponent_C:GetTeamBaseInfo()
    return self.tbBaseInfo
end

function BattleTeamComponent_C:GetAllSortedPlayerIds()
    return self.tbAllSortedPlayerIds
end

return BattleTeamComponent_C