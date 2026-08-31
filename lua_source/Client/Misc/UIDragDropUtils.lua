local EventManager = require("EventManager")
local ClientEventDef = require("ClientEventDef")

local UIDragDropUtils = { }

local function OnEmitterDragStart (nDragSourceCategory, nDragSourceId)
    EventManager:OnFireEvent(ClientEventDef.EV_UI_DRAG_START, nDragSourceCategory, nDragSourceId)
end

local function OnEmitterDragCancel(nDragSourceCategory, nDragSourceId)
    EventManager:OnFireEvent(ClientEventDef.EV_UI_DRAG_END,   nDragSourceCategory, nDragSourceId)
end

function UIDragDropUtils.EnableDragStartAndEndEvent(EventHelper, pDragWidget)
    if EventHelper and pDragWidget then
       EventHelper:RegisterCppDelegateFunc(pDragWidget.OnDragStart, OnEmitterDragStart)
       EventHelper:RegisterCppDelegateFunc(pDragWidget.OnDragCancel,OnEmitterDragCancel)
       EventHelper:RegisterCppDelegateFunc(pDragWidget.OnAcceptDrop,OnEmitterDragCancel)
    end
end

function UIDragDropUtils.FireEventWhenItemDropped(EventHelper, pDragWidget)
    if EventHelper and pDragWidget then
       EventHelper:RegisterCppDelegateFunc(pDragWidget.OnAcceptDrop,OnEmitterDragCancel)
    end
end

function UIDragDropUtils.FireEventWhenItemDragged(EventHelper, pDragWidget)
    if EventHelper and pDragWidget then
        EventHelper:RegisterCppDelegateFunc(pDragWidget.OnDragStart, OnEmitterDragStart)
        EventHelper:RegisterCppDelegateFunc(pDragWidget.OnDragCancel,OnEmitterDragCancel)
    end
end

return UIDragDropUtils