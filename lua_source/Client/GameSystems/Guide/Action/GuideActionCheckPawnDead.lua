-----------------------------------------------------
--File Name    : GuideActionCheckPawnDead.lua
--此action是为了解决引导中的特殊问题，单机副本的最后一步
--是船死为触发条件，进入光圈是倒数第二步（因为执行action
--时会有一帧的延迟，这时候还没有注册号监听事件），但当倒
--数第二部先触发，最后一步后触发时，会造成死锁现象
--Description  : 指引动作
-----------------------------------------------------
local luaclass                      = require("luaclass")
local GuideActionBase               = require("GuideActionBase")
local GuideActionCheckPawnDead      = luaclass("GuideActionCheckPawnDead", GuideActionBase)
----------------------------------------------------------
local GameObjectSystem  = dynamic_require("GameObjectSystem")
local GameObjectTypeDef = require("GameObjectTypeDef")

local TIME_TICK = 1 
GuideActionCheckPawnDead.nObjTemplateId = 0
----------------------------------------------------------
function GuideActionCheckPawnDead:Begin()
    GuideActionCheckPawnDead.super.Begin(self)
    self.bUIControl = false
    self.nObjTemplateId = self.tbTemplate.tbParam[1]
end

function GuideActionCheckPawnDead:DoAction(tbTemplate)
    GuideActionCheckPawnDead.super.DoAction(self, tbTemplate)
    self.TimerHelper:NewTimerMethod(self, self.CheckPawnDead, TIME_TICK, true)
end

function GuideActionCheckPawnDead:End()
    GuideActionCheckPawnDead.super.End(self)
    self.TimerHelper:ClearAllTimer()
end

function GuideActionCheckPawnDead:CheckPawnDead()
    local tbGameObjectList = GameObjectSystem:GetAllGameObjects()
    self:DebugLog("CheckPawnDead ")
    local isDead = true
    for _, GameObject in pairs(tbGameObjectList) do
        self:DebugLog("GameObjectType =  " .. tostring(GameObjectTypeDef.Npc))
        if GameObject:GetObjectType() == GameObjectTypeDef.Npc then
            self:DebugLog("GuideActionCheckPawnDead: nTemplateId =  " .. GameObject.nTemplateId)
            if GameObject.nTemplateId == self.nObjTemplateId then -- 是
                self:DebugLog("GuideActionCheckPawnDead: nTemplateId =  " .. GameObject.nTemplateId)
                isDead = false
                break
            end
        end
    end
    if isDead then
        self:ForceEndCurrentGroup()
    end
end

return GuideActionCheckPawnDead