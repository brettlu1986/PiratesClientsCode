local ReplicationBinder = {}

local GlobalVariableSystem = dynamic_require("GlobalVariableSystem")
local CppDelegate = require("CppDelegate")
local BattleGameModeSystem = dynamic_require("BattleGameModeSystem")
local PropName = require("PropName")

ReplicationBinder.TYPE_PAWN = 1
ReplicationBinder.TYPE_CONTROLLER = 2
ReplicationBinder.TYPE_GAMESTATE  = 3

local function UnbindPreBeginPlayDelegate(tbBindInfo)
    local pDelegate = tbBindInfo.pPreBeginPlayDelegate
    if(pDelegate) then
        pDelegate:Unbind()
        tbBindInfo.pPreBeginPlayDelegate = nil
    end
end

local function UnbindEndPlayDelegate(tbBindInfo)
    local pDelegate = tbBindInfo.pEndPlayDelegate
    if(pDelegate) then
        pDelegate:Unbind()
        tbBindInfo.pEndPlayDelegate = nil
    end
end

local function OnComponentEndPlay(tbBindInfo, pUEActor)
    if(tbBindInfo.pActor == pUEActor) then
        log("ReplicationBinder uninit")
        UnbindPreBeginPlayDelegate(tbBindInfo)
        UnbindEndPlayDelegate(tbBindInfo)
        tbBindInfo.ReplicateHelper:Uninit()
    else
        log("ReplicationBinder uninit failed",
            EngineExtActorShell.GetActorUniqueId(tbBindInfo.pActor),
            EngineExtActorShell.GetActorUniqueId(pUEActor))
    end
end

local function InitRepComponent(tbBindInfo, bServer)
    local pRet = tbBindInfo.pActor.CustomReplication

    assert(isvalidhandle(pRet))
    tbBindInfo.ReplicateHelper:SetRepComponent(pRet)

    local tbIds = PropName.GetRepIdToBeChecked()
    for nRepId, _ in pairs(tbIds) do
        pRet:SetPropertyToBeChecked(nRepId)
    end
    return pRet
end

local function OnPawnPreBeginPlay(tbBindInfo, pActor)
    if(tbBindInfo.pActor == pActor) then
        UnbindPreBeginPlayDelegate(tbBindInfo)

        -- 客户端得在PostNetInit后才能取的到
        local pRepComponent = InitRepComponent(tbBindInfo, false)

        -- 客户端actor销毁时会先让component Endplay并markpendingkill，然后在调用actor的endplay，在actor的endplay时再去取component已经invalid了
        -- 所以这里在component还有效时抛了个口子，让外面解绑各种delegate
        tbBindInfo.pEndPlayDelegate = CppDelegate:BindMethod(pRepComponent.OnEndPlay, tbBindInfo, OnComponentEndPlay)
    end
end

local function OnRecvInvalidData(tbBindInfo, szInfo)
    BattleGameModeSystem:OnRecvInvalidData(tbBindInfo.Component.Owner, szInfo)
end

function ReplicationBinder.Bind(ReplicateHelper, pActor, Component, nType)
    local tbBindInfo = {}
    tbBindInfo.ReplicateHelper = ReplicateHelper
    tbBindInfo.pActor = pActor
    tbBindInfo.Component = Component
    tbBindInfo.nType = nType

    ReplicateHelper:Init(pActor, function(_, szInfo) OnRecvInvalidData(tbBindInfo, szInfo) end)

    if(GlobalVariableSystem:IsDedicatedServer()) then
        InitRepComponent(tbBindInfo, true)
    elseif(GlobalVariableSystem:IsDedicatedClient()) then
        -- -- 客户端的 `OnActorPreCreated` 是听的`OnActorChannelOpen`，此时还没走到 `PostNetInit`，取不到RepComponent
        -- -- PawnPostBeginplay会触发OnActorCreate，这会其他propertycomponent会开始define，
        -- -- 这里因为component创建时序的问题，有可能其他component会先OnActorCreate，然后才会调到此component
        -- -- 所以为了其他component在OnActorCreate时能够直接拿到现成的属性值，这里吧bind时机提前了
        -- local pActorDelegate = CommonShell.GetCommon(GWorld):GetGameDelegateManager().Actor
        -- local Delegate = nType == ReplicationBinder.TYPE_CONTROLLER
        --     and pActorDelegate.OnControllerPreBeginPlay or pActorDelegate.OnPawnPreBeginPlay
        -- tbBindInfo.pPreBeginPlayDelegate = CppDelegate:BindMethod(Delegate, tbBindInfo, OnPawnPreBeginPlay)
        OnPawnPreBeginPlay(tbBindInfo, pActor)
    end

    return tbBindInfo
end

function ReplicationBinder.Unbind(tbBindInfo, pUEActor)
    if(GlobalVariableSystem:IsDedicatedServer()) then
        OnComponentEndPlay(tbBindInfo, pUEActor)
    elseif(isvalidhandle(pUEActor)
        and tbBindInfo.ReplicateHelper ~= nil
        and isvalidhandle(tbBindInfo.ReplicateHelper.pRepComponent)) then
        OnComponentEndPlay(tbBindInfo, pUEActor)
    end
end

return ReplicationBinder