local PropNameGameState = {}

PropNameGameState.PropType = 
{
    TYPE_COMMON       = 0, --通用
    TYPE_FFA          = 1, --吃鸡本
    TYPE_TRAININGCAMP = 2, --训练营
}

local GameStatePropTypeDef = PropNameGameState.PropType
local CurrentType = nil
local tbTypeToIds = nil
local PropDefine = nil
local RepType = nil


local function CustomDefine(Name, T)
    local Id = PropDefine(Name, T, RepType)
    tbTypeToIds[CurrentType] = tbTypeToIds[CurrentType] or {}
    table.insert(tbTypeToIds[CurrentType], Id)
end

local function IncludeCommonRepIds()
    local tbIds = tbTypeToIds[GameStatePropTypeDef.TYPE_COMMON]
    tbTypeToIds[CurrentType] = tbTypeToIds[CurrentType] or {}
    local tbSelfRepIds = tbTypeToIds[CurrentType]
    for _, v in ipairs(tbIds) do
        table.insert(tbSelfRepIds, v)
    end
end

---------------------------------------------------------------------------------

local function DefineCommon(T)
    CurrentType = GameStatePropTypeDef.TYPE_COMMON
    
    CustomDefine("nGameStatePropType",            T.Int)     --GameStatePropType
    CustomDefine("bGameStateSkyEnabled",          T.Bool) --是否启用
    CustomDefine("nGameStateCurrentSkyTime",      T.Int)   --当前几点几分
    CustomDefine("fGameStateSkySpeed",            T.Float)   --运行速率
end

local function DefineFFA(T)
    CurrentType = GameStatePropTypeDef.TYPE_FFA
    IncludeCommonRepIds()

    CustomDefine("nFFACountDownEndTime",          T.Int)
    CustomDefine("nFFAAlivePlayerCount",          T.Int)
    CustomDefine("nFFATeamModeId",                T.Int)
    CustomDefine("nFFAProcessState",              T.Int)
    CustomDefine("bFFAWaitStage",                 T.Bool)
    CustomDefine("rFFANewTransportInfos",         T.Proto)
    CustomDefine("rFFAPoisonCircleInfo",          T.Proto)
end

local function DefineTrainingCamp(T)
    CurrentType = GameStatePropTypeDef.TYPE_TRAININGCAMP
    IncludeCommonRepIds()

    CustomDefine("nTrainingCampReleaseTimeStamp", T.Int)   --训练营结束的UTC时间
    CustomDefine("rTrainingCampPlayerInfos",      T.Proto)  --训练营所有玩家信息，加好友使用
end

local function DefineProperties(T)
    DefineFFA(T)
    DefineTrainingCamp(T)
end

-----------------------------------------------------------------------------------
function PropNameGameState.Init(Define, T, R)
    tbTypeToIds = {}
    PropDefine = Define
    RepType = R.All

    DefineCommon(T)
    DefineProperties(T)
end

function PropNameGameState.GetIdsByType(Type)
    return tbTypeToIds[Type]
end

return PropNameGameState