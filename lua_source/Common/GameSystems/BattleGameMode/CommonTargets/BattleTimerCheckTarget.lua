-- 检查Timer的Target

local luaclass = require("luaclass")
local BattleTargetBaseClass = require("BattleTargetBase")
local BattleTimerCheckTarget = luaclass("BattleTimerCheckTarget", BattleTargetBaseClass)

local BattleTimerHelper = require("BattleTimerHelper")

BattleTimerCheckTarget.fnTimerEnd = nil

function BattleTimerCheckTarget:Init()
    BattleTimerCheckTarget.super.Init(self)
    self.szName = "BattleTimerCheckTarget"
end

function BattleTimerCheckTarget:SetTimeName(szName)
    self.szTimerName = szName
end

function BattleTimerCheckTarget:Parse(tbJsonData)
    self.szTimerName = tbJsonData.TimerName
    return self.szTimerName ~= nil and string.len(self.szTimerName) > 0
end

function BattleTimerCheckTarget:Start()
    BattleTimerCheckTarget.super.Start(self)

    -- 有Timer的话就听事件，没timer直接complete
    if(BattleTimerHelper:HasTimer(self.szTimerName)) then
        self.fnTimerEnd = function()
            self:Complete()
        end
        BattleTimerHelper:AddListener(self.szTimerName, self.fnTimerEnd)
    else
        logwarning("BattleTimerCheckTarget start failed, the timer "..self.szTimerName.." is not exsisted.")
        self:Complete()
    end
end

function BattleTimerCheckTarget:UnregisterEvent()
    if(self.fnTimerEnd) then
        BattleTimerHelper:RemoveListener(self.szTimerName, self.fnTimerEnd)
        self.fnTimerEnd = nil
    end
end

return BattleTimerCheckTarget