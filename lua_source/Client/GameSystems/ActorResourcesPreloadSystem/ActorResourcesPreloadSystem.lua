local ActorResourcesPreloadSystem = {}

local ActorResourcesPreloadData = require("ActorResourcesPreloadData")
local CommonEventDef = require("CommonEventDef")
local EventManager = require("EventManager")
local CppDelegate = require("CppDelegate")

local tbDatas = nil
local pDelegate = nil

-- 注意，此时的actor以及repComponent都没有beginplay，并且针对此actor的所有包都属于pending状态(不处理)
local function OnRecvActorInfoBeforeNetInit(pActorChannel,
    pActor, nServerInstanceId, pInitProtoData, nActorNetGuid, bLoadAsync)

    assert(tbDatas[nActorNetGuid] == nil)
    local tbData = ActorResourcesPreloadData()
    tbData:OnCreate(pActorChannel,
        pActor,
        nServerInstanceId,
        msgtoluatable(pInitProtoData),
        nActorNetGuid,
        bLoadAsync)
    if(not tbData.bAllFinished) then
        tbDatas[nActorNetGuid] = tbData
    end
end

local function OnActorCreated(tbGameObject)
    local nNetGuid = EngineExtActorShell.GetActorNetGuid(tbGameObject.pUEActor)
    local tbData = tbDatas[nNetGuid]
    if(tbData) then
        tbData:OnDestroy()
        tbDatas[nNetGuid] = nil
    end
end

function ActorResourcesPreloadSystem:Init()
    tbDatas = {}
    pDelegate = CppDelegate:Bind(
        CommonShell.GetCommon(GWorld):GetGameDelegateManager().GameNet.OnRecvActorInfoBeforeNetInit,
        OnRecvActorInfoBeforeNetInit,
        "ActorResourcesPreloadSystem")
    EventManager:BindEvent(CommonEventDef.EV_GAME_OBJECT_POST_ACTOR_CREATE, OnActorCreated)
    return true
end

function ActorResourcesPreloadSystem:Uninit()
    tbDatas = nil
    if(pDelegate) then
        pDelegate:Unbind()
    end
    pDelegate = nil
    EventManager:UnBindEvent(CommonEventDef.EV_GAME_OBJECT_POST_ACTOR_CREATE, OnActorCreated)
end

function ActorResourcesPreloadSystem:GetData(pUEActor)
    local nNetGuid = EngineExtActorShell.GetActorNetGuid(pUEActor)
    return tbDatas[nNetGuid]
end

return ActorResourcesPreloadSystem