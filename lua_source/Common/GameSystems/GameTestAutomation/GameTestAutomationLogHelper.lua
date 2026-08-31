-----------------------------------------------------
--File Name    : GameTestAutomationLogHelper.lua
--Author       : WuJizhou
--Create Time  : 6/10/2019, 6:26:41 PM
--Description  : GameTestAutomationLogHelper
-----------------------------------------------------
local GameTestAutomationLogHelper = {}

local bEnableLog = false

function GameTestAutomationLogHelper.Log(...)
    log("GameTestAutomation", ...)
end


function GameTestAutomationLogHelper.LogDebug(...)
    if bEnableLog then
        -- luacheck: push ignore 113
        logdebug("GameTestAutomation", ...)
        -- luacheck: pop
    end
end

function GameTestAutomationLogHelper.LogPathInfo(tbPathData)
    if bEnableLog then
        for k, v in pairs(tbPathData) do
            GameTestAutomationLogHelper.LogDebug(k, "path info begin")
            for a, b in ipairs(v) do
                GameTestAutomationLogHelper.LogDebug(k, a, b.X, b.Y, b.Z)
            end
            GameTestAutomationLogHelper.LogDebug(k, "path info end")
        end
    end
end

function GameTestAutomationLogHelper.EnableLog(bEnable)
    bEnableLog = bEnable
end

return GameTestAutomationLogHelper