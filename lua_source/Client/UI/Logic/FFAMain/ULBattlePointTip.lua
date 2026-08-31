-----------------------------------------------------
--File Name    : ULBattlePointTip.lua
--Author       : Edward J
--Create Time  : 2020-06-28
--Description  : logic of BattlePointTip
-----------------------------------------------------
local luaclass              = require("luaclass")
local UILogicBase           = require("UILogicBase")
local ULBattlePointTip      = luaclass("ULBattlePointTip", UILogicBase)

local ClientEventDef        = require("ClientEventDef")
local GlobalVariableSystem  = dynamic_require("GlobalVariableSystem")
local SelfTimerHelperClass  = require("SelfTimerHelper")
local UIDef                 = require("UIDef")
local GamePlayerSelfHelper  = require("GamePlayerSelfHelper")
local PointTipsHelper       = require("PointTipsHelper")
local UIUtils               = require("UIUtils")
local L10N                  = require("L10N")
local UISetUtils            = require("UISetUtils")
local BattleChatSystem      = dynamic_require("BattleChatSystem")
local GameplayUtilityHelper = require("GameplayUtilityHelper")
-----------------------------------------------------
local TIME_TICK             =  0.03
local EndPos                = Vector()
local WorldPos              = Vector()

ULBattlePointTip.nCurrentQueueIndex     = nil
ULBattlePointTip.tbPointLocationTips    = nil
ULBattlePointTip.tbLoopTimer            = nil
ULBattlePointTip.TimerHelper            = nil
ULBattlePointTip.tbPrefabs              = nil
-----------------------------------------------------
local function ReadyToShow(self, nTipsType)
    local nTime = GlobalVariableSystem:GetServerTimeUtc()
    local bAllFinished = true
    for k,tbTips in pairs(self.tbPointLocationTips) do
        local nMaxShowTime = PointTipsHelper.GetTipMaxShowTime(k)
        for i,v in ipairs(tbTips) do
            if nTime - v.nTime < nMaxShowTime then
                bAllFinished = false
            end
        end
    end
    return bAllFinished
end

local function ClearLoopTimer(self)
    if self.tbLoopTimer then
        self.TimerHelper:ClearTimer(self.tbLoopTimer)
    end
    self.tbLoopTimer = nil
end

local function RefreshLocationTips(self)
    local nTime = GlobalVariableSystem:GetServerTimeUtc()
    local bAllFinished = true
    for k, tbTips in pairs(self.tbPointLocationTips) do
        local nMaxShowTime = PointTipsHelper.GetTipMaxShowTime(k)
        for i,v in ipairs(tbTips) do
            if nTime - v.nTime < nMaxShowTime then
                v.pWidget:Activate()
                v.pWidget:RefreshScreenPos()
                bAllFinished = false
            else
                v.pWidget:Deactivate()
            end
        end
    end
    if bAllFinished then
        ClearLoopTimer(self)
    end
end

local function ShowLocationTips(self, nTipsType)
    if ReadyToShow(self, nTipsType) or not self.tbLoopTimer then
        ClearLoopTimer(self)
        self.tbLoopTimer = self.TimerHelper:NewTimerMethod(self, RefreshLocationTips, TIME_TICK, true)
    end
end

local function GetAlmostLocationTip(self, nTipsType)
    local nTime = GlobalVariableSystem:GetServerTimeUtc()
    local nMinKeyIndex = 1
    local tbTips = self.tbPointLocationTips[nTipsType]
    if not tbTips then
        return nil
    end
    for i,v in ipairs(tbTips) do
        if v.nTime < nTime then
            nTime = v.nTime
            nMinKeyIndex = i
        end
    end
    return tbTips[nMinKeyIndex]
end

local function ClearPrefabs(self)
    if not self.tbPrefabs then
        return
    end
    for i, prefab in ipairs(self.tbPrefabs) do
        self.PrefabHelper:UnbindPrefab(prefab)
    end
end

local function CreatePrefab(self)
    local tbPrefab = self.PrefabHelper:CreatePrefab(UIDef.UP_POINT_TIP)
    if tbPrefab then
        self.pWidgetRef.cvsBase:AddChildToCanvas(tbPrefab.pWidgetRef)
        table.insert(self.tbPrefabs, tbPrefab)
    end
    return tbPrefab
end

local function CreatePointLocationTipTab(self, nPos)
    local temp = {}
    temp.nTime = GlobalVariableSystem:GetServerTimeUtc()
    local pWidget = CreatePrefab(self)
    if pWidget then
        pWidget:SetWorldPosition(nPos)
    end
    temp.pWidget = pWidget
    return temp
end

local function GetTipCountInQueue(self, nTipsType)
    local tbTips = self.tbPointLocationTips[nTipsType]
    if not tbTips then
        return 0
    end
    return #tbTips
end

local function AddToPointLocationQueue(self, nTipsType, pPos)
    local nMaxQueue = PointTipsHelper.GetTipMaxCount(nTipsType)
    local nCurrentQueueCount = GetTipCountInQueue(self, nTipsType)
    if nCurrentQueueCount >= nMaxQueue then
        local tbAlmostLocationTip = GetAlmostLocationTip(self, nTipsType)
        tbAlmostLocationTip.nTime = GlobalVariableSystem:GetServerTimeUtc()
        tbAlmostLocationTip.pWidget:SetWorldPosition(pPos)
    else
        local tbOneTip = CreatePointLocationTipTab(self, pPos)
        local tbTips = self.tbPointLocationTips[nTipsType]
        if not tbTips then
            tbTips = {}
           self.tbPointLocationTips[nTipsType] = tbTips
        end
        table.insert(tbTips, tbOneTip)
    end
    ShowLocationTips(self, nTipsType)
end

local function OnPointLocationTip(self, nTipsType, pPos)
    BattleChatSystem:SendPointLocationToTeam(pPos, PointTipsHelper.Proto_PointType[nTipsType])
    AddToPointLocationQueue(self, nTipsType, pPos)
end

local function ShowDiantanceTooFarError(nMaxDistance)
    UIUtils.ShowToast(L10N:Format(UISetUtils.GetL10NTextByKey("POINT_DISTANCE_TOO_FAR"), nMaxDistance))
end

function ULBattlePointTip:PointLocation()
    local PlayerSelf = GamePlayerSelfHelper:Get()
    local bShip = PlayerSelf:IsShip()
    local tbConfig = PointTipsHelper.GetConfig(bShip, PointTipsHelper.PointLocationConfig)
    local tbActorsToIgnore = {PlayerSelf.pUEActor}
    local ViewPortVector = PointTipsHelper.GetCrosshairPos(self.Owner, PlayerSelf, bShip)
    if not ViewPortVector then
        return false
    end
    local __, pStartPos, pWorldDirection = GameplayStatics.DeprojectScreenToWorld(PlayerSelf.pUEController, ViewPortVector)
    local nInteractionDistance = tbConfig.distance
    local nEndPosX, nEndPosY, nEndPosZ = pStartPos.X + pWorldDirection.X*nInteractionDistance, pStartPos.Y + pWorldDirection.Y*nInteractionDistance, pStartPos.Z + pWorldDirection.Z*nInteractionDistance
    EndPos.X = nEndPosX
    EndPos.Y = nEndPosY
    EndPos.Z = nEndPosZ
    local bRet, pHitResult = GameplayUtilityHelper.TraceActor(GWorld, pStartPos, EndPos, tbActorsToIgnore, PointTipsHelper.DEBUG_MODE, false, true, false, true, false, GWorld)
    if bRet then
        local Location = pHitResult.Location
        WorldPos.X = Location.X
        WorldPos.Y = Location.Y
        WorldPos.Z = Location.Z
        if Location.Z < 0 then
            local pCorrectPos = PointTipsHelper.LinePlaneIntersectPoint(pStartPos, pWorldDirection)
            WorldPos.X = pCorrectPos.X
            WorldPos.Y = pCorrectPos.Y
            WorldPos.Z = pCorrectPos.Z
        end
        OnPointLocationTip(self, PointTipsHelper.PointTips ,WorldPos)
    else
        local pWorldPos, bOpposite = PointTipsHelper.LinePlaneIntersectPoint(pStartPos, pWorldDirection)
        local nDistance = PointTipsHelper.GetDistance(pWorldPos, pStartPos)
        if nDistance and nDistance <= nInteractionDistance and not bOpposite then
            OnPointLocationTip(self, PointTipsHelper.PointTips ,pWorldPos)
        else
            ShowDiantanceTooFarError(math.ceil(nInteractionDistance/100))
            return false
        end
    end
    return true
end

function ULBattlePointTip:OnLoad()
    self.TimerHelper = SelfTimerHelperClass()
    self.tbPrefabs = {}
    self.tbPointLocationTips = {}
end

function ULBattlePointTip:OnUnload()
    ClearLoopTimer(self)
    ClearPrefabs(self)
end

function ULBattlePointTip:OnBindEvent(EventHelper)
    EventHelper:RegisterEvent(ClientEventDef.EV_POINT_LOCATE, self, self.PointLocation)
    EventHelper:RegisterEvent(ClientEventDef.EV_TEAM_MEMBER_POINT_LOCATE, self, AddToPointLocationQueue)
    EventHelper:RegisterEvent(ClientEventDef.EV_POINT_DROP_ITEM_LOCATE, self, OnPointLocationTip)
end

return ULBattlePointTip