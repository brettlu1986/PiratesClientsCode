-----------------------------------------------------
--File Name    : WidgetComponentBase.lua
--Author       : Song Fuhao
--Create Time  : 2017-03-02
--Description  : 船只头顶信息UI
--
--WidgetComponent类中必须有的成员变量与函数
--szWidgetName      : Widget在UIDef中对应的枚举
--szUEComponentName : UEActor身上组件名字
-----------------------------------------------------

local luaclass = require("luaclass")
local GameComponentBase = require("GameComponentBase")
local WidgetComponentBase = luaclass("WidgetComponentBase", GameComponentBase)

local WidgetConfig = require("WidgetDataTable")
local UIManager = require("UIManager")
local EventManager = require("EventManager")
local ClientEventDef = require("ClientEventDef")
local GamePlayerSelfHelper = require("GamePlayerSelfHelper")

WidgetComponentBase.szWidgetName = nil
WidgetComponentBase.szUEComponentName = nil
WidgetComponentBase.pDrawSize = nil
WidgetComponentBase.Widget = nil
WidgetComponentBase.pWidgetComponent = nil

function WidgetComponentBase:OnActorCreated(pUEActor)
    WidgetComponentBase.super.OnActorCreated(self, pUEActor)
    if pUEActor[self.szUEComponentName] then
        if GamePlayerSelfHelper:Get().bReady then
            self:CreateWidget()
        else
            EventManager:BindEventMethod(ClientEventDef.EV_PLAYERSELF_READY, self, self.CreateWidget)
        end
    --else
        --error('WidgetComponentBase OnActorCreated failed, WidgetComponent is nil. ObjectName ' .. KismetSystemLibrary.GetObjectName(pUEActor))
    end
end

function WidgetComponentBase:OnActorDestroyed(pUEActor)
    EventManager:UnBindEventMethod(ClientEventDef.EV_PLAYERSELF_READY, self, self.CreateWidget)
    WidgetComponentBase.super.OnActorDestroyed(self, pUEActor)
    self:DestoryWidget()
end

function WidgetComponentBase:CreateWidget()
    EventManager:UnBindEventMethod(ClientEventDef.EV_PLAYERSELF_READY, self, self.CreateWidget)
    if not self.szWidgetName then
        error('WidgetComponentBase CreateWidget failed, szWidgetName is nil.')
    end
    local tbTemplate = WidgetConfig:GetTemplate(self.szWidgetName)
    local pWidgetRef = UIManager:CreateUMG(tbTemplate.szUIPath)

    local pUEActor = self:GetOwner().pUEActor
    local pWidgetComponent = pUEActor[self.szUEComponentName]
    if not pWidgetComponent then
        error('WidgetComponentBase OnActorCreated failed, WidgetComponent is nil. ObjectName ' .. KismetSystemLibrary.GetObjectName(pUEActor))
    end
    self.pWidgetComponent = pWidgetComponent
    pWidgetComponent:SetWidget(pWidgetRef)
    if self.pDrawSize then
        pWidgetComponent:SetDrawSize(self.pDrawSize)
    end

    self.pWidgetRef = pWidgetRef
    self:OnWidgetCreated(pWidgetRef)
end

function WidgetComponentBase:OnWidgetCreated(pWidgetRef)
end

function WidgetComponentBase:DestoryWidget()
    if(self.pWidgetRef) then
        UIManager:DestroyUMG(self.pWidgetRef)
        self.pWidgetRef = nil
    end
end

function WidgetComponentBase:SetRelativeLoaction(RelativeVector)
    local pUEActor = self:GetOwner().pUEActor
    local pWidgetComponent = pUEActor[self.szUEComponentName]
    pWidgetComponent:K2_SetRelativeLocation(RelativeVector);
end

return WidgetComponentBase
