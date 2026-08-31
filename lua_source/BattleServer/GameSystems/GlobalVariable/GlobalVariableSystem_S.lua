local luaclass = require("luaclass")
local GlobalVariableSystemClass = require("GlobalVariableSystem")
local GlobalVariableSystem_S = luaclass("GlobalVariableSystem_S", GlobalVariableSystemClass)

GlobalVariableSystem_S.szDungeonId = nil
GlobalVariableSystem_S.nStartTime = nil
GlobalVariableSystem_S.tbVersionInfo = nil

function GlobalVariableSystem_S:Init()
    local bRet = GlobalVariableSystem_S.super.Init(self)
    return bRet
end

function GlobalVariableSystem_S:Uninit()

    GlobalVariableSystem_S.super.Uninit(self)
end

function GlobalVariableSystem_S:SetStartTime(nStartTime)
    self.nStartTime = nStartTime
end

function GlobalVariableSystem_S:GetStartTime()
    return self.nStartTime
end

function GlobalVariableSystem_S:SetVersionInfo(tbInfo)
    self.tbVersionInfo = tbInfo
end

function GlobalVariableSystem_S:GetVersionInfo()
    return self.tbVersionInfo
end

return GlobalVariableSystem_S()
