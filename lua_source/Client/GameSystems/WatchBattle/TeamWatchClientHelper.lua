local GameObjectSystem = dynamic_require("GameObjectSystem")
local Proto = require("DungeonCommonProtoNames")
local PlayerSelfHelper = require("GamePlayerSelfHelper")

local TeamWatchClientHelper = {}

local EState = Proto.TeamInfo_EState
TeamWatchClientHelper.TeamTargetType =
{
    SELF_TEAM = 1,
    OTHER_TEAM = 2,
}

-------------------------用于客户端调用-----------------------
local function GetWatchBattleComponent() 
    local tbPlayer = PlayerSelfHelper:Get()
    if tbPlayer then
        return tbPlayer.WatchBattleComponent
    end   
    return nil
end

local function GetBattleTeamComponent()
    local tbPlayer = PlayerSelfHelper:Get()
    if tbPlayer then
        return tbPlayer.BattleTeamComponent
    end   
    return nil
end

local function GetPlayerInsId()
    local tbPlayer = PlayerSelfHelper:Get()
    return tbPlayer:GetServerInstanceId()
end

--自己原始队伍刚死的时候，第一次切别人，这块需要注意一下
local function GetTeamTargetType()
    local nCurrentTeamId = TeamWatchClientHelper.GetOtherWatchTeamId()
    local TargetType = TeamWatchClientHelper.TeamTargetType
    if nCurrentTeamId == -1 then   
        if TeamWatchClientHelper.IsOriginalTeamDead() then   
            return TargetType.OTHER_TEAM
        else
            return TargetType.SELF_TEAM
        end
    end
    return TargetType.OTHER_TEAM
end

function TeamWatchClientHelper.IsOtherTeamWatch()
    return GetTeamTargetType() == TeamWatchClientHelper.TeamTargetType.OTHER_TEAM
end

function TeamWatchClientHelper.ResetClientWatchTeamRepInfo()
    local WatchBattleComponent = GetWatchBattleComponent()
    if WatchBattleComponent then
        WatchBattleComponent:Reset()
    end
end

--获取原始队伍的队伍信息
function TeamWatchClientHelper.GetOriginalTeamInfo()
    local BattleTeamComponent = GetBattleTeamComponent()
    if BattleTeamComponent then 
        local tbBattleTeamInfo = BattleTeamComponent.tbBattleTeamInfo
        if tbBattleTeamInfo then
            return tbBattleTeamInfo.TeamInfos, tbBattleTeamInfo.nTeamId
        end
    end
    return nil, nil
end

function TeamWatchClientHelper.GetOtherWatchTeamInfo()  
    local WatchBattleComponent = GetWatchBattleComponent()
    if WatchBattleComponent then
        local tbBattleTeamInfo = WatchBattleComponent.tbBattleTeamInfo
        if tbBattleTeamInfo then
            return tbBattleTeamInfo.TeamInfos, tbBattleTeamInfo.nTeamId
        end
    end
    return nil, nil
end

--当前客户端原始队伍 是否存在有效队友，用于队伍内部观战，此时没切其他的队伍
function TeamWatchClientHelper.GetValidOriginalTeammateInfo()
    local tbTeamInfo, _ = TeamWatchClientHelper.GetOriginalTeamInfo()
    local nPlayerInsId = GetPlayerInsId()
    if tbTeamInfo ~= nil and nPlayerInsId ~= nil then
        for k, v in ipairs(tbTeamInfo) do
            if v.nInstanceId ~= nPlayerInsId 
                and v.nState ~= EState.DEAD 
                and v.nState ~= EState.DYING
                and v.nState ~= EState.ADDITIONALSUCCESS then
                return v
            end
        end
    end
    return nil
end

function TeamWatchClientHelper.IsCurrentOtherTeamMember(nOtherInstanceId)
    local tbOtherTeamInfo = TeamWatchClientHelper.GetOtherWatchTeamInfo()
    if tbOtherTeamInfo == nil then  
        return false
    end
    for k, v in ipairs(tbOtherTeamInfo) do
        if nOtherInstanceId == v.nInstanceId then   
            return true
        end
    end
    return false
end

--用于判断 别人和当前自己的 Team是否是同一个队 
function TeamWatchClientHelper.IsInSameTeam(nOtherInstanceId)
    local tbCurrentTeamInfo = TeamWatchClientHelper.GetCurrentTeamInfo() 
    if tbCurrentTeamInfo == nil then   
        return false
    end
    for k, v in ipairs(tbCurrentTeamInfo) do
        if nOtherInstanceId == v.nInstanceId then   
            return true
        end
    end
    return false
end

--这里根据 需要根据类型返回
function TeamWatchClientHelper.GetCurrentTeamInfo() 
    local nTargetType = GetTeamTargetType()
    local TargetType = TeamWatchClientHelper.TeamTargetType
    if nTargetType == TargetType.SELF_TEAM then
        return TeamWatchClientHelper.GetOriginalTeamInfo()
    end
    return TeamWatchClientHelper.GetOtherWatchTeamInfo()
end

--获取队伍的基础信息，包含完整的人名，PlayerId等，即使有人还没有登录进来
function TeamWatchClientHelper.GetCurrentTeamBaseInfo() 
    local nTargetType = GetTeamTargetType()
    local TargetType = TeamWatchClientHelper.TeamTargetType
    if nTargetType == TargetType.SELF_TEAM then
        local tbBattleTeamComp = GetBattleTeamComponent()
        if tbBattleTeamComp then
            return tbBattleTeamComp:GetTeamBaseInfo()
        end
    else
        local tbWatchBattleComp = GetWatchBattleComponent()
        if tbWatchBattleComp then
            return tbWatchBattleComp:GetTeamBaseInfo()
        end
    end

    return nil
end

function TeamWatchClientHelper.SetTeamCount(nCount)
    local WatchBattleComponent = GetWatchBattleComponent() 
    if WatchBattleComponent then
        WatchBattleComponent:SetTeamCount(nCount)
    end
end

function TeamWatchClientHelper.GetTeamCount()
    local WatchBattleComponent = GetWatchBattleComponent() 
    if WatchBattleComponent then
        return WatchBattleComponent:GetTeamCount()
    end  
    return 0
end

function TeamWatchClientHelper.SetCurrentWatchId(nWatchId) 
    local WatchBattleComponent = GetWatchBattleComponent() 
    if WatchBattleComponent then
        WatchBattleComponent.nCurrentWatchId = nWatchId
    end
end

function TeamWatchClientHelper.GetCurrentWatchId() 
    local WatchBattleComponent = GetWatchBattleComponent()
    if WatchBattleComponent then  
        return WatchBattleComponent.nCurrentWatchId
    end
    return -1
end

function TeamWatchClientHelper.GetCurrentWatchPlayer()  
    local nCurrentWatchId = TeamWatchClientHelper.GetCurrentWatchId()
    if nCurrentWatchId > 0 then
        return GameObjectSystem:FindByInstanceId(nCurrentWatchId)
    end  
    return nil
end

function TeamWatchClientHelper.GetOriginalTeamId()
    local BattleTeamComponent = GetBattleTeamComponent() 
    if BattleTeamComponent then
        return BattleTeamComponent.nTeamId
    end  
    return -1
end

function TeamWatchClientHelper.GetOtherWatchTeamId()
    local WatchBattleComponent = GetWatchBattleComponent() 
    if WatchBattleComponent then
        return WatchBattleComponent.nTeamId
    end  
    return -1
end

function TeamWatchClientHelper.IsOriginalTeamDead()
    local WatchBattleComponent = GetWatchBattleComponent() 
    if WatchBattleComponent then
        return WatchBattleComponent:IsOriginalTeamDead()
    end  
    return false
end

function TeamWatchClientHelper.InitOriginalTeamData()
    local WatchBattleComponent = GetWatchBattleComponent() 
    if WatchBattleComponent:IsEmptyOriginalInfo() then 
        local tbOriginalTeamInfo, _ = TeamWatchClientHelper.GetOriginalTeamInfo()  
        WatchBattleComponent:InitOriginalTeamData(tbOriginalTeamInfo)
    end
end

function TeamWatchClientHelper.ProcessOriginalTeamDead(nDeadInsId)
    local WatchBattleComponent = GetWatchBattleComponent() 
    if WatchBattleComponent  then
        TeamWatchClientHelper.InitOriginalTeamData()
        WatchBattleComponent:ProcessOriginalTeamDead(nDeadInsId)
    end
end


return TeamWatchClientHelper