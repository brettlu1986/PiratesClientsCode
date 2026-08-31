-----------------------------------------------------
--File Name    : UIActorMouseOperator.lua
--Description  :
-----------------------------------------------------

local luaclass = require("luaclass")
local UIActorMouseOperator = luaclass("UIActorMouseOperator")

local SelfEventHelper = require("SelfEventHelper")

UIActorMouseOperator.bIsDrag = false
UIActorMouseOperator.tbLastPos = nil
UIActorMouseOperator.tbCurPos = nil
UIActorMouseOperator.pActor = nil
UIActorMouseOperator.bdrWidget = nil
UIActorMouseOperator.EventHelper = nil
UIActorMouseOperator.bActivate = false


local function OnMouseButtonDown(self, pGeometry, pMouseEvent)
    self.bIsDrag = true
    self.tbLastPos = KismetInputLibrary.PointerEvent_GetScreenSpacePosition(pMouseEvent)
    return WidgetBlueprintLibrary.Handled()
end

local function OnMouseMove(self, pGeometry, pMouseEvent)
    if not self.bIsDrag then
        return WidgetBlueprintLibrary.Handled()
    end
    self.tbCurPos = KismetInputLibrary.PointerEvent_GetScreenSpacePosition(pMouseEvent)

    local MoveDelta = Vector2D {
        X = self.tbCurPos.X - self.tbLastPos.X
    }

    local nSpeed = 0.5

    self.tbLastPos = self.tbCurPos
    if self.pActor then
        local tbRotation = self.pActor:K2_GetActorRotation()
        local tbNewRotation = Rotator {
            Pitch = tbRotation.Pitch,
            Roll = tbRotation.Roll,
            Yaw = tbRotation.Yaw - MoveDelta.X * nSpeed
        }

        self.pActor:K2_SetActorRotation(tbNewRotation)
    end
    return WidgetBlueprintLibrary.Handled()
end

local function OnMouseButtonUp(self, pGeometry, pMouseEvent)
    self.bIsDrag = false
    self.tbLastPos = nil
    self.tbCurPos = nil
    return WidgetBlueprintLibrary.Handled()
end

local function OnMouseEnter(self, pGeometry, pMouseEvent)
    return WidgetBlueprintLibrary.Handled()
end

local function OnMouseLeave(self, pMouseEvent)
    if self.bIsDrag then
        self.bIsDrag = false
        self.tbLastPos = nil
        self.tbCurPos = nil
    end
    return WidgetBlueprintLibrary.Handled()
end


function UIActorMouseOperator:Init(bdrWidget, pActor)
    self.bdrWidget = bdrWidget
    self.pActor = pActor
    self.EventHelper = SelfEventHelper()
    self.bActivate = false
end

function UIActorMouseOperator:Uninit()
    if self.bActivate then
        self:Deactivate()
    end
    self.bdrWidget = nil
    self.pActor = nil
    self.EventHelper = nil
end

function UIActorMouseOperator:UpdateActor(pActor)
    self.pActor = pActor
end

function UIActorMouseOperator:Activate()
    if not self.bActivate then
        self.EventHelper:RegisterCppDelegate(self.bdrWidget.OnMouseButtonDownEvent, self, OnMouseButtonDown)
        self.EventHelper:RegisterCppDelegate(self.bdrWidget.OnMouseMoveEvent, self, OnMouseMove)
        self.EventHelper:RegisterCppDelegate(self.bdrWidget.OnMouseButtonUpEvent, self, OnMouseButtonUp)
        self.EventHelper:RegisterCppDelegate(self.bdrWidget.OnMouseEnterEvent, self, OnMouseEnter)
        self.EventHelper:RegisterCppDelegate(self.bdrWidget.OnMouseLeaveEvent, self, OnMouseLeave)
        self.bActivate = true
    end
end

function UIActorMouseOperator:Deactivate()
    if self.bActivate then
        self.EventHelper:UnregisterAll()
        self.bActivate = false
    end
end


return UIActorMouseOperator