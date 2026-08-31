-----------------------------------------------------
--File Name    : GuideActionLeavePoisonCircle.lua
--Description  : 指引动作
-----------------------------------------------------
local luaclass                      = require("luaclass")
local GuideActionBase               = require("GuideActionBase")
local GuideActionLeavePoisonCircle  = luaclass("GuideActionLeavePoisonCircle", GuideActionBase)

local GamePlayerSelfHelper = require("GamePlayerSelfHelper")

local tbBuffList = {30001,30002,30003,30004,30005,30006,30007,30008,30009}

local function CheckPoisionCircleBuff(self)
    local BuffComponentClient = GamePlayerSelfHelper:Get().BuffComponentClient
    for i, buffId in ipairs(tbBuffList) do
        local bInPoison = BuffComponentClient:IsExistBuffById(buffId)
        if bInPoison then
            return true
        end
    end
    return false
end

local function OnBuffRemoved(self, nInstanceId, nTemplateId)
    self:DebugLog("OnBuffRemoved ")
    if not CheckPoisionCircleBuff(self) then
        self:DebugLog("EndAction")
        self:EndAction()
    end
end

function GuideActionLeavePoisonCircle:DoAction(tbTemplate)
    GuideActionLeavePoisonCircle.super.DoAction(self, tbTemplate)
    local EventHelper = self.EventHelper
    EventHelper:UnregisterAll()
    self:DebugLog("Register BuffRemoveDelegate")
    local BuffComponentClient = GamePlayerSelfHelper:Get().BuffComponentClient
    EventHelper:RegisterLuaDelegate(BuffComponentClient.OnBuffRemoveDelegate, OnBuffRemoved, self)
end

function GuideActionLeavePoisonCircle:EndAction()
    self:DebugLog("EndAction")
    self:ForceEndCurrentStep()
end

return GuideActionLeavePoisonCircle
