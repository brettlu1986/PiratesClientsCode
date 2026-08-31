-----------------------------------------------------
--File Name    : GuideTriggerLoadMap.lua
--Description  : 指引触发
-----------------------------------------------------
local luaclass = require("luaclass")
local GuideTrigger = require("GuideTrigger")
local GuideTriggerLoadMap = luaclass("GuideTriggerLoadMap",GuideTrigger)


local ClientEventDef = require("ClientEventDef")
local GameWorldSystem = require("GameWorldSystem")
local GlobalVariableSystem_C = require("GlobalVariableSystem_C")

local function CheckSceneId(self)
    local bIsInDungeon = GlobalVariableSystem_C:IsInDungeon()
    if not bIsInDungeon then
        return self.tbTemplate.nSceneId == GameWorldSystem:GetWorld().nSceneId
    end
    return false
end

--override
function GuideTriggerLoadMap:Begin()
    GuideTriggerLoadMap.super.Begin(self)
    if CheckSceneId(self) then
        self:Trigger()
    end
end

function GuideTriggerLoadMap:BindEvent(EventHelper)
    EventHelper:RegisterEvent(ClientEventDef.EV_POST_LOAD_MAP, self, self.OnLoadMap)
end

function GuideTriggerLoadMap:OnLoadMap()
    self:DebugLog("OnLoadMap")
    if(CheckSceneId(self))then
        self:Trigger()
    end
end

function GuideTriggerLoadMap:IsTrigger()
    self.bIsTrigger = CheckSceneId(self)
    return self.bIsTrigger
end

return GuideTriggerLoadMap
