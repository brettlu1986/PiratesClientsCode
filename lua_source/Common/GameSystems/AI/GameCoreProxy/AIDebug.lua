local AIDebug = { }
local Util = require("BaseUtil")

function AIDebug:IsTableEqual(tbOrignal, tbNewest)
    return Util:CheckEqual(tbOrignal, tbNewest)
end

local function ReloadLuaFile(tbPlayer, tbParams)
    local szFileName = tbParams[3]
    local szOldFile = package.loaded[szFileName]

	-- luacheck: push ignore
	package.loaded[szFileName] = nil
    -- luacheck: pop

    require(szFileName)
    local szNewFile = package.loaded[szFileName]

    for k,v in pairs(szNewFile) do
        if type(v) == "function" then
            rawset(szOldFile, k, v)
        end
    end

    -- luacheck: push ignore
    package.loaded[szFileName] = szOldFile
    -- luacheck: pop

    log("reload lua file:", szFileName)
end









--------------------------------------------------------------------------------------
local tbCommandProcessor = {
    reload = ReloadLuaFile,
}

function AIDebug:ProcessCmd(tbPlayer, tbParams)
    local szCommand = (tbParams[2])
    if tbCommandProcessor[szCommand] then
        tbCommandProcessor[szCommand](tbPlayer, tbParams)
        log("process ai cmd:", szCommand)
    end
end

return AIDebug