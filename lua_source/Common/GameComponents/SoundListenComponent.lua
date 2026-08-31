-----------------------------------------------------
--File Name    : SoundListenComponent.lua
--Author       : Chen Jing
--Create Time  : 2018-09-13
--Description  : 监听Actor上的声音事件并转化为UI需要的信息
-----------------------------------------------------

local luaclass = require("luaclass")
local GameComponentBase = require("GameComponentBase")
local SoundListenComponent = luaclass("SoundListenComponent", GameComponentBase)
local SelfEventHelperClass = require("SelfEventHelper")
local ClientEventDef = require("ClientEventDef")
local EventManager = require("EventManager")
local GameObjectSystem = dynamic_require("GameObjectSystem")
local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
local RadarmapSoundListenIni = require("RadarmapSoundListenIni")
local RadarMapSoundDataTable = require("RadarMapSoundDataTable")
--local GameObjectTypeDef = require("GameObjectTypeDef")
local HumanMovementStateType = require("HumanMovementStateType")
local ShipDataTable = require("ShipDataTable")
local GameCoreWatchSystem = dynamic_require("GameCoreWatchSystem")
local TeamWatchClientHelper = require("TeamWatchClientHelper")
local PropName = require("PropName")


SoundListenComponent.EventHelper = nil
SoundListenComponent.tbSoundTarget = nil
SoundListenComponent.bWatchBot = false

local fnAtan2 = KismetMathLibrary.Atan2
local fnSubtractVector = KismetMathLibrary.Subtract_VectorVector
local fnVectorSize = KismetMathLibrary.VSize
local tbSoundTypeEnumToLua = nil
local rad2ang = (180) / math.pi
local tbSoundLevelPercents = {
    66, 33, 0
}

local function LOG(...)
    log("CJ->SoundListenComponent:", ...)
end

local function InitEnum()
    if not tbSoundTypeEnumToLua then
        tbSoundTypeEnumToLua = {
            SHIP_FIRE               = enumtoint(Enum_SoundType.ShipFire),
            HUMAN_FIRE              = enumtoint(Enum_SoundType.HumanFire),
            CARRIER_NOISE           = enumtoint(Enum_SoundType.CarrierNoise),
            FOOTSTEP                = enumtoint(Enum_SoundType.Footstep),
        }
        LOG("initial tbSoundTypeEnumToLua")
    end
end

local function GetListenRange(tbPlayer)
    local nListenRange = 0
    if tbPlayer:IsShip() then
        nListenRange = tbPlayer.ShipBattlePropertyComponent:GetProp(PropName.nShipListenRange)
    else
        nListenRange = tbPlayer.HumanBattlePropertyComponent:GetProp(PropName.nHumanListenRange)
    end
    return nListenRange
end

local function GetHumanStateId(tbSoundMaker)
    local nStateQueryId = 0
    if tbSoundMaker.pUEActor then
        local bJump = tbSoundMaker.pUEActor.AnimationSoundComponent.bJumping
        if bJump then
            return 4
        end
    end
    local nHumanMovementState = tbSoundMaker.HumanMovementStateComponent:GetCurrentState()
    if nHumanMovementState == HumanMovementStateType.UpRight_State then
        if tbSoundMaker.HumanMovementStateComponent:GetRun() then
            nStateQueryId = 4
        else
            nStateQueryId = 1
        end
    elseif nHumanMovementState == HumanMovementStateType.Crouch_State then
        if tbSoundMaker.HumanMovementStateComponent:GetRun() then
            nStateQueryId = 5
        else
            nStateQueryId = 2
        end
    elseif nHumanMovementState == HumanMovementStateType.Crawl_State then
        nStateQueryId = 3
    end
    return nStateQueryId
end

local function GetHumanBuffs(tbSoundMaker)
    local tbRet = {}
    local BuffComponentClient = tbSoundMaker.BuffComponentClient
    local tbBuffs = BuffComponentClient:GetAllBuffs()
    for _, tbBuff in pairs(tbBuffs) do
        table.insert( tbRet, tbBuff.nTemplateId )
    end

    return tbRet
end

local function GetHumanStateRadiusByBuffs(nStateId, tbBuffs)
    local nFootStepSpreadRange = RadarMapSoundDataTable:GetHumanStateRadius(nStateId)

    for _, nTemplateId in pairs(tbBuffs) do
        local nCurRange = RadarMapSoundDataTable:GetHumanStateRadius(nStateId, nTemplateId)
        if nCurRange then
            if nFootStepSpreadRange then
                nFootStepSpreadRange = math.min(nFootStepSpreadRange, nCurRange)
            else
                nFootStepSpreadRange = nCurRange
            end
        end
    end

    return nFootStepSpreadRange
end

local function GetWeaponRadiusByBuffs(nHumanWeaponTemplateId, tbBuffs)
    local nSpreadRange = RadarMapSoundDataTable:GetWeaponRadius(nHumanWeaponTemplateId)

    for _, nTemplateId in pairs(tbBuffs) do
        local nCurRange = RadarMapSoundDataTable:GetWeaponRadius(nHumanWeaponTemplateId, nTemplateId)
        if nCurRange then
            if nSpreadRange then
                nSpreadRange = math.min(nSpreadRange, nCurRange)
            else
                nSpreadRange = nCurRange
            end
        end
    end

    return nSpreadRange
end

local function GetSoundSpreadDistance(nSoundType, tbSoundMaker)
    if tbSoundMaker:IsHuman() then
        if nSoundType == tbSoundTypeEnumToLua.FOOTSTEP then
            local nStateId = GetHumanStateId(tbSoundMaker)
            local tbBuffs  = GetHumanBuffs(tbSoundMaker)

            return GetHumanStateRadiusByBuffs(nStateId, tbBuffs) or RadarmapSoundListenIni.nFootStepSpreadRange
        elseif nSoundType == tbSoundTypeEnumToLua.HUMAN_FIRE then
            local nHumanWeaponTemplateId = tbSoundMaker.HumanWeaponComponent:GetCurrentWeaponTemplateId()
            local tbBuffs  = GetHumanBuffs(tbSoundMaker)

            return GetWeaponRadiusByBuffs(nHumanWeaponTemplateId, tbBuffs) or RadarmapSoundListenIni.nHumanFireSpreadRange
        elseif nSoundType == tbSoundTypeEnumToLua.CARRIER_NOISE then
            local nVehicleInstanceId = tbSoundMaker.HumanMovementStateComponent:GetVehicleInstanceId()
            local tbVehicle = GameObjectSystem:FindByInstanceId(nVehicleInstanceId)
            if tbVehicle and tbVehicle.pUEActor then
                local nVehicleId = tbVehicle:GetTemplateId()
                local bSprint = tbVehicle.pUEActor.AnimationSoundComponent.bSprint
                return RadarMapSoundDataTable:GetVehicleStateRadius(nVehicleId, bSprint and 1 or 2) or RadarmapSoundListenIni.nCarrierSpreadRange
            end
        end
   elseif tbSoundMaker:IsShip() then
        if nSoundType == tbSoundTypeEnumToLua.SHIP_FIRE then
            local nShipWeaponTemplateId = tbSoundMaker.ShipBattlePropertyComponent:GetProp(PropName.nActiveWeaponTemplateId)
            if nShipWeaponTemplateId and nShipWeaponTemplateId > 0 then
                return RadarMapSoundDataTable:GetWeaponRadius(nShipWeaponTemplateId) or RadarmapSoundListenIni.nShipFireSpreadRange
            end
        end
    end
    return 0
end

local function GetRealListenRange(self)
    if self.bWatchBot then
        local bHuman = self.tbSoundTarget:IsHuman()
        if bHuman then
            return RadarmapSoundListenIni.nHumanListenRange
        else
            local nTempId = self.tbSoundTarget.ShipBattlePropertyComponent:GetProp(PropName.nShipTemplateId)
            local tbTemplate = ShipDataTable:GetTemplate(nTempId)
            return tbTemplate and tbTemplate["nListenRange"] or 0
        end
    else
        return GetListenRange(self.tbSoundTarget)
    end
end

local function OnSetBotSoundTarget(self, bWatchBot, tbTargetObj)
    self.bWatchBot = bWatchBot
    if bWatchBot then
        self.tbSoundTarget = tbTargetObj
    else
        self.tbSoundTarget = self.Owner
    end
end

local function IsTeammate(tbOwner, tbSoundMaker)
    local bTeammate = false
    if GameCoreWatchSystem.bEnabled then
        bTeammate = GameCoreWatchSystem.tbCurrentWatchBot == tbOwner and GameCoreWatchSystem:IsTeammate(tbSoundMaker)
    else
        local nServerInstanceId = tbSoundMaker.nServerInstanceId
        bTeammate = TeamWatchClientHelper.IsInSameTeam(nServerInstanceId)
    end
    return bTeammate
end

local function OnListenSound(self, nSoundType, pLocation, nSoundSourceUniqueID)
    local tbOwner = self.tbSoundTarget
    local tbSoundMaker = GameObjectSystem:FindByUniqueId(nSoundSourceUniqueID)
    if not tbSoundMaker then
        log(" sound maker not found ", nSoundType, nSoundSourceUniqueID)
        return
    end

    local bOwner = tbOwner and tbOwner.pUEActor and tbOwner.nUniqueId ~= nSoundSourceUniqueID
    local bSoundMaker = tbSoundMaker and tbSoundMaker.nServerInstanceId ~= tbOwner.nServerInstanceId

    if bOwner and bSoundMaker then
        if IsTeammate(tbOwner, tbSoundMaker) then
            return
        end
        local pActorPostion = tbOwner.pUEActor:K2_GetActorLocation()
        local pSoundDirection = fnSubtractVector(pLocation, pActorPostion)
        local nDistance = fnVectorSize(pSoundDirection)
        local nSpreadDistance = GetSoundSpreadDistance(nSoundType, tbSoundMaker)
        -- make sure sound distance is less than listen range and sound spread range
        local nListenRange = GetRealListenRange(self)
        nListenRange = math.min(nSpreadDistance, nListenRange)
        if nDistance > nListenRange then
            return
        end
        -- if sound is fire with muffler, make sure distance percent is less than limit
        local nPercent = nDistance * 100 // nListenRange
        local nSoundSoundReduction = nil
        if nSoundType == tbSoundTypeEnumToLua.SHIP_FIRE then
            local tbFireShip = tbSoundMaker
            if tbFireShip and tbFireShip:IsShip() then
                local nFireSoundReduction = tbFireShip.ShipBattlePropertyComponent:GetProp(PropName.nFireSoundReduction)
                if nFireSoundReduction > 0 then
                    nSoundSoundReduction = nFireSoundReduction * 100
                end
            end
        end
        if nSoundSoundReduction and nPercent > nSoundSoundReduction then
            return
        end
        -- fire event
        local nSoundLevel = 0
        for i,v in ipairs(tbSoundLevelPercents) do
            if nPercent >= v then
                nSoundLevel = i
                break
            end
        end
        local nAngle = fnAtan2(pSoundDirection.Y, pSoundDirection.X) * rad2ang
        if nAngle < 0 then
            nAngle = nAngle + 360
        end
        --LOG("listen sound ",tbOwner.szName, nSoundType, math.floor(nAngle), nSoundLevel, nSpreadDistance)
        EventManager:OnFireEvent(ClientEventDef.EV_FFA_RADARMAP_SOUND, nSoundType, nAngle, nSoundLevel, nSoundSourceUniqueID)
    end
end

function SoundListenComponent:OnActorCreated(pUEActor)
    SoundListenComponent.super.OnActorCreated(self, pUEActor)
    InitEnum()
    if self.Owner == GamePlayerSelfHelper:Get() then
        self.tbSoundTarget = self.Owner
        local DelegateMgr  = CommonShell.GetCommon(GWorld):GetGameDelegateManager().GameMisc
        local nListenRange = GetListenRange(self.Owner)
        self.EventHelper = SelfEventHelperClass()
        self.EventHelper:RegisterCppDelegate(DelegateMgr.OnPlaySound, self, OnListenSound)
        self.EventHelper:RegisterEvent(ClientEventDef.EV_SET_WATCH_BOT_SOUND_TARGET, self, OnSetBotSoundTarget)
        if self.Owner:IsShip() then
            pUEActor.ListenRange = nListenRange
            LOG("set ship listen range ", nListenRange)
        elseif self.Owner:IsHuman() then
            pUEActor.ListenRange = nListenRange
            LOG("set human listen range ", nListenRange)
        end
    end
end

function SoundListenComponent:OnActorDestroyed(pUEActor)
    SoundListenComponent.super.OnActorDestroyed(self, pUEActor)
    if self.EventHelper then
        self.EventHelper:UnregisterAll()
        self.EventHelper = nil
    end
end


return SoundListenComponent