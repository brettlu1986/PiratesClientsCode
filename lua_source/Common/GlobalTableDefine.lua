-- luacheck: globals _G

-- 所有global表中的变量以及函数定义在这里，只在游戏启动前可以修改
local BaseUtil = require("BaseUtil")

-- 变量
_G.GDefaultTolerance = 1.0e-4

-- 函数
-- 获取函数所在的文件以及行号
_G.getdebuginfo_f = function(fnCallback)
    if(fnCallback == nil and type(fnCallback) ~= 'function') then
        return nil
    end

    local tbInfo = debug.getinfo(fnCallback, "S")
    if(tbInfo == nil) then
        return nil
    end
    return string.format("source: %s, line: %d", tbInfo.source, tostring(tbInfo.linedefined))
end

-- 获取调用当前函数的函数的文件以及行号
_G.getdebuginfo_l = function()
    local tbInfo = debug.getinfo(3, "S")
    if(tbInfo == nil) then
        return nil
    end
    return string.format("source: %s, line: %d", tbInfo.source, tostring(tbInfo.linedefined))
end

-- table to string
_G.t2s = function(tbTable)
    return BaseUtil:ConvertTableToJsonString(tbTable)
end

local function GenerateGlobalNativeVariableImp(tbNative, bGenerateFunction, tbGeneratedVariables)
    local tbPropertyNames, tbFunctionNames, tbTemp, pClass, pValue, szKeyName, tbGTable
    local Collect = bGenerateFunction and
        ExtendBlueprintFunctions.GetClassFunctionAndPropertyNames or
        ExtendBlueprintFunctions.GetEnumPropertyNames

    for _, szName in ipairs(tbNative) do
        tbGTable = {}
        pClass = _G[szName]     -- 从C++取出来
        _G[szName] = tbGTable   -- 存到_G里，下次用就不用走c++了
        assert(pClass)
        tbPropertyNames, tbFunctionNames = Collect(szName, nil, nil)
        tbTemp = bGenerateFunction and tbFunctionNames or tbPropertyNames

        for _, szSubName in ipairs(tbTemp) do
            szKeyName = string.format("%s_%s", szName, szSubName)
            assert(tbGeneratedVariables[szKeyName] == nil)
            pValue = pClass[szSubName]
            tbGTable[szSubName] = pValue
            _G[szKeyName] = pValue
            tbGeneratedVariables[szKeyName] = pValue
            --logdebug(szKeyName)
        end
    end
end

local function GenerateGlobalNativeVariable()
    -- 定义后会把类中的函数都cache下来，并且会自动生成带有前缀的全局函数
    -- 比如定义了EngineExtShell,那么可直接调用EngineExtShell_GetCurrentMapName(pShell)
    -- PS: 这里尽量只放native常用的

    -- 生成函数
    -- local tbCommonFunctions =
    -- {
    --     -- native class
    --     "EngineExtShell",
    --     "EngineExtActorShell",
    --     "CommonShell",
    --     "CommonActorShell",
    --     "KismetSystemLibrary",
    --     "KismetMathLibrary",
    --     "GameplayStatics",
    -- }

    -- local tbClientFunctions =
    -- {
    --     "ClientShell",
    --     "GameActorShell",
    --     "GameSoundShell",
    --     "GameCameraShotShell",
    --     "GameDungeonShell",
    -- }

    -- local tbServerFunctions =
    -- {
    --     "ServerShell",
    --     "DungeonShell",
    -- }

    -- 生成enum
    local tbEnums =
    {
        -- native enum
        "ESlateVisibility",
    }

    local tbGeneratedVariables = {}
    -- GenerateGlobalNativeVariableImp(tbCommonFunctions, true, tbGeneratedVariables)
    -- if(GIsDedicatedServer) then
    --     GenerateGlobalNativeVariableImp(tbServerFunctions, true, tbGeneratedVariables)
    -- else
    --     GenerateGlobalNativeVariableImp(tbClientFunctions, true, tbGeneratedVariables)
    -- end
    GenerateGlobalNativeVariableImp(tbEnums, false, tbGeneratedVariables)
end

GenerateGlobalNativeVariable()

