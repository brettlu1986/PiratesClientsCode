-----------------------------------------------------
--File Name    : GuideTriggerCloseUI.lua
--Author       : Edward J
--Create Time  : 2019-05-14
--Description  : 指引触发
-----------------------------------------------------
local luaclass                              = require("luaclass")
local GuideTriggerSailorSlotEmpty           = require("GuideTriggerSailorSlotEmpty")
local GuideTriggerFirstSailorSlotEmpty      = luaclass("GuideTriggerFirstSailorSlotEmpty",GuideTriggerSailorSlotEmpty)

-----------------------------------------------------
--override

function GuideTriggerFirstSailorSlotEmpty:GetSlotIndex()
    return 1, 1
end

function GuideTriggerFirstSailorSlotEmpty:Begin()
    GuideTriggerFirstSailorSlotEmpty.super.Begin(self)
end

return GuideTriggerFirstSailorSlotEmpty
