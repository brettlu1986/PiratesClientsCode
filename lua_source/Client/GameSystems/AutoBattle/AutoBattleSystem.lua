-----------------------------------------------------
--File Name    : AutoBattleSystem.lua
--Author       : WuJizhou
--Create Time  : 8/13/2019, 6:26:06 PM
--Description  : AutoBattleSystem
-----------------------------------------------------
local AutoBattleSystem = {}

local tbIAutoBattleCheckers = nil

function AutoBattleSystem:Register(tbIAutoBattleChecker)
    if tbIAutoBattleChecker.CheckAutoBattle then
        table.insert(tbIAutoBattleCheckers, tbIAutoBattleChecker)
    else
        logwarning("AutoBattleSystem, the checker registered should have func named CheckAutoBattle ")
    end
end

function AutoBattleSystem:Unregister(tbIAutoBattleChecker)
    local nIdx = 1
    local bMatch = false
    if not tbIAutoBattleCheckers then
        return
    end
    for _, v in ipairs(tbIAutoBattleCheckers) do
        if tbIAutoBattleChecker == v then
            bMatch = true
            break
        end
        nIdx = nIdx + 1
    end
    if bMatch then
        table.remove(tbIAutoBattleChecker, nIdx)
    end
end

function AutoBattleSystem:InAutoBattle()
    local bRet = false
    for _, v in ipairs(tbIAutoBattleCheckers) do
        local bResult = v:CheckAutoBattle()
        if bResult then
            bRet = true
            break
        end
    end
    return bRet
end

function AutoBattleSystem:Init()
    tbIAutoBattleCheckers = {}

end

function AutoBattleSystem:Uninit()
    tbIAutoBattleCheckers = nil
end

return AutoBattleSystem