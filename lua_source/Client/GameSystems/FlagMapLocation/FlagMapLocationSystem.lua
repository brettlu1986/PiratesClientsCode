-----------------------------------------------------
--File Name    : FlagMapLocationSystem.lua
--Author       : Ran Jie
--Create Time  : 2018-9-12
--Description  : 地图标记系统（当前版本只有单人标记，没有队友标记）
-----------------------------------------------------

local SelfEventHelper = require("SelfEventHelper")
local ClientEventDef = require("ClientEventDef")
local DCProto = require("DungeonCommonProtoNames")
local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
local NetworkManager = dynamic_require("NetworkManager")
local TeamWatchClientHelper = require("TeamWatchClientHelper")

local FlagMapLocationSystem = {}
FlagMapLocationSystem.tbFlagPoint = nil
FlagMapLocationSystem.nSelfIndex = nil

local function UpdateFlag(self,nInstanceId, nIndex, SignType, nSignX, nSignY)
    --logdebug("UpdateFlag,SignType=",SignType,nInstanceId,GamePlayerSelfHelper:GetServerInstanceId())
    local tbMemberData = self.tbFlagPoint[nInstanceId]
    if SignType == DCProto.ESignType.SNONE and tbMemberData and tbMemberData.SignType == DCProto.ESignType.SNONE then
        return false
    end
    --local tbMemberData = self.tbFlagPoint[nInstanceId]
    if not tbMemberData then
        tbMemberData = {}
        self.tbFlagPoint[nInstanceId] = tbMemberData
    end
    if SignType ~= tbMemberData.SignType or nSignX ~= tbMemberData.nSignX or nSignY ~= tbMemberData.nSignY then
        log("FlagMapLocationSystem:UpdateFlag=",nInstanceId, nIndex, SignType,GamePlayerSelfHelper:Get():GetName())
        tbMemberData.nIndex = nIndex
        tbMemberData.SignType = SignType
        tbMemberData.nSignX = nSignX
        tbMemberData.nSignY = nSignY
        return true
    end
    return false
end

function FlagMapLocationSystem:SetFlagPos(bSign, WorldPosX, WorldPosY)
    if TeamWatchClientHelper.IsOtherTeamWatch() then
        return
    end
    local SignType = DCProto.ESignType.DELETE
    if bSign then
        SignType = DCProto.ESignType.SIGN
    end
    local nInstanceId = GamePlayerSelfHelper:Get():GetServerInstanceId()
    local nSignX = math.ceil(WorldPosX)
    local nSignY = math.ceil(WorldPosY)
    local c2d_FFAMapSign =
    {
        nInstanceId = nInstanceId,
        SignType = SignType,
        nX = nSignX,
        nY = nSignY,
    }
    --logdebug("FlagMapLocationSystem:SetFlagPos,SignType, X, Y=",SignType, WorldPosY, WorldPosY)
    NetworkManager:GetRPCNetworkProxy():SendToServer(DCProto.c2d_FFAMapSign, c2d_FFAMapSign)
    if self.nSelfIndex then
        UpdateFlag(self, nInstanceId, self.nSelfIndex, SignType, nSignX, nSignY)
        self.EventHelper:FireEvent(ClientEventDef.EV_FFA_FLAG_POINT_UPDATE, self.tbFlagPoint)
    end
end


function FlagMapLocationSystem:GetFlagPos(nInstanceId)
    return self.tbFlagPoint[nInstanceId]
end

function FlagMapLocationSystem:GetAllFlag()
    return self.tbFlagPoint
end

local function OnFFATeamInfoChanged(self)
    local tbTeamInfo = TeamWatchClientHelper.GetCurrentTeamInfo()
    if not tbTeamInfo then
        return
    end
    local bRet = false
    for k, v in ipairs(tbTeamInfo) do
        if v.nInstanceId == GamePlayerSelfHelper:Get():GetServerInstanceId() then
            self.nSelfIndex = v.nIndex
            bRet = UpdateFlag(self,v.nInstanceId, v.nIndex, v.SignType, v.nSignX, v.nSignY) or bRet
        else
            bRet = UpdateFlag(self,v.nInstanceId, v.nIndex, v.SignType, v.nSignX, v.nSignY) or bRet
        end
    end
    if bRet then
        self.EventHelper:FireEvent(ClientEventDef.EV_FFA_FLAG_POINT_UPDATE, self.tbFlagPoint)
    end
end

local function OnRefreshViewForNewMate(self, tbNewMateObj)
    if TeamWatchClientHelper.IsOtherTeamWatch() then
        self.tbFlagPoint = {}
        self.EventHelper:UnregisterAll()
        self.EventHelper:FireEvent(ClientEventDef.EV_CLEAR_ALL_FLAG_POINT)
    end
end

function FlagMapLocationSystem:Init()
    self.tbFlagPoint = {}
    self.nSelfIndex = nil
    self.EventHelper = SelfEventHelper()
    self.EventHelper:RegisterEvent(ClientEventDef.EV_FFA_TEAM_INFO_CHANGED, self, OnFFATeamInfoChanged)
    self.EventHelper:RegisterEvent(ClientEventDef.EV_REFRESH_WATCH_MATE, self, OnRefreshViewForNewMate)
    return true
end

function FlagMapLocationSystem:Uninit()
    self.tbFlagPoint = nil
	self.EventHelper:UnregisterAll()
end

return FlagMapLocationSystem