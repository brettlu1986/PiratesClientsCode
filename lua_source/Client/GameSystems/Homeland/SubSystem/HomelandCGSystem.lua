-----------------------------------------------------
--File Name    : HomelandCGSystem.lua
--Author       : WuJizhou
--Create Time  : 5/20/2019, 1:20:29 PM
--Description  : HomelandCGSystem
-----------------------------------------------------
local HomelandCGSystem = {}

local SelfEventHelper = require("SelfEventHelper")
local ClientEventDef = require("ClientEventDef")
local HomelandIni = require("HomelandIni")
local HomelandSceneSystem = require("HomelandSceneSystem")
local UIStateDef = require("UIStateDef")
local UIManager = require("UIManager")
local MatineeSystem = dynamic_require("MatineeSystem")

local EventHelper = nil


local function GetShipActorName()
    return HomelandIni.tbMatinee.szShipActorName
end

local function GetShipActorMeshName()
    return HomelandIni.tbMatinee.szShipActorMeshName
end

local function OnEnterMatineeFinished()
    UIManager:PopState(UIStateDef.StateName.UI_MATINEE_STATE)
    EventHelper:FireEvent(ClientEventDef.EV_HOMELAND_ENTER_MATINEE_FINISHED)
end

local function OnLeaveMatineeFinished()
    UIManager:PopState(UIStateDef.StateName.UI_MATINEE_STATE)
    EventHelper:FireEvent(ClientEventDef.EV_HOMELAND_LEAVE_MATINEE_FINISHED)
end

local function OnPlay(Matinee)
    local szShipActorName = GetShipActorName()
    local pActor = HomelandSceneSystem:GetRandomShipActor()
    Matinee:BindUEActorFromSkeletalMesh(szShipActorName, GetShipActorMeshName(), pActor.SKM_ShipMaster.SkeletalMesh)
    UIManager:PushState(UIStateDef.StateName.UI_MATINEE_STATE, nil)
end

function HomelandCGSystem:PlayLeaveHomelandMatinee()
    local nId = HomelandIni.tbMatinee.nLeaveHomelandMatinee
    local Matinee = MatineeSystem:PlayMatinee(nId, false, OnLeaveMatineeFinished, OnPlay, false)
    if Matinee then
        return true
    else
        return false
    end
end

function HomelandCGSystem:PlayEnterHomelandMatinee()
    local nId = HomelandIni.tbMatinee.nEnterHomelandMatinee
    local Matinee = MatineeSystem:PlayMatinee(nId, false, OnEnterMatineeFinished, OnPlay, false)
    if Matinee then
        return true
    else
        return false
    end
end

function HomelandCGSystem:PlayTransportTreasureMatinee()
    local nId = HomelandIni.tbMatinee.nTransportTreasureMatinee
    local Matinee = MatineeSystem:PlayMatinee(nId, false, nil, nil, false)
    if not Matinee then
        EventHelper:FireEvent(ClientEventDef.EV_TRANSPORT_TREASURE_ARRIVED)
    end
end

function HomelandCGSystem:Init()
    EventHelper = SelfEventHelper()
end

function HomelandCGSystem:Uninit()
    EventHelper:UnregisterAll()
    EventHelper = nil

end

function HomelandCGSystem:OnEnterHomeland()
end

function HomelandCGSystem:OnLeaveHomeland()
end


return HomelandCGSystem