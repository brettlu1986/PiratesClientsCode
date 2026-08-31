-----------------------------------------------------
--File Name    : PerformanceEventDef.lua
--Author       : Edward J
--Create Time  : 2020-09-25
--Description  : 性能event key名称
-----------------------------------------------------

local PerformanceEventDef = {}

PerformanceEventDef.IMAGE_QUALITY = "image_quality"
PerformanceEventDef.CHEAPS        = "cheaps"
PerformanceEventDef.FRAMES_MEMORY = "frames_memory"

PerformanceEventDef.EVENT_ID = {}
local tbEventId = {
    [PerformanceEventDef.IMAGE_QUALITY] = "image_quality",
    [PerformanceEventDef.CHEAPS]        = "cheaps",
    [PerformanceEventDef.FRAMES_MEMORY] = "frames_memory"
}
PerformanceEventDef.EVENT_ID = tbEventId

PerformanceEventDef.EVENT_DESC = {}
local tbEventDesc = {
    [PerformanceEventDef.IMAGE_QUALITY] = "画质等级",
    [PerformanceEventDef.CHEAPS]        = "安卓用户芯片型号",
    [PerformanceEventDef.FRAMES_MEMORY] = "帧率与内存占用"
}
PerformanceEventDef.EVENT_DESC = tbEventDesc

return PerformanceEventDef