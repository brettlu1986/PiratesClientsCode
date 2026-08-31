-----------------------------------------------------
--File Name    : GuideTrigger.lua
--Description  : 指引触发
-----------------------------------------------------
local luaclass              = require("luaclass")
local GuideTrigger          = require("GuideTrigger")
local GuideTriggerQuickBuild  = luaclass("GuideTriggerQuickBuild", GuideTrigger)

local ClientEventDef        = require("ClientEventDef")
local BattleItemDataTable   = require("BattleItemDataTable")
local BattleItemCategoryDef = require("BattleItemCategoryDef")
-----------------------------------------------------
GuideTriggerQuickBuild.szQuickBuildType = ""

-----------------------------------------------------

function GuideTriggerQuickBuild:OnReciveEvent(tbTemplateIds)
    self:DebugLog("OnReciveEvent," .. " self.szQuickBuildType = " .. self.szQuickBuildType)
    local bHumanPart = false
    local bShipPart = false
    local szQuickBuildType = self.szQuickBuildType
    for _, nItemTemplateId in ipairs(tbTemplateIds) do
        local tbTemplate = BattleItemDataTable:GetTemplate(nItemTemplateId)
        local nCategory = tbTemplate.nCategory
        if nCategory == BattleItemCategoryDef.SHIP
            or nCategory == BattleItemCategoryDef.SHIP_WEAPON
            or nCategory == BattleItemCategoryDef.SHIP_PART then
                bShipPart = true
        elseif nCategory == BattleItemCategoryDef.HUMAN_WEAPON
            or nCategory == BattleItemCategoryDef.HUMAN_ARMOR then
                bHumanPart = true
        end
    end
    self:DebugLog("OnReciveEvent " .. "  bHumanPart = " .. tostring(bHumanPart) .. " bShipPart = " .. tostring(bShipPart))
    if szQuickBuildType == "human" and bHumanPart or szQuickBuildType == "ship" and bShipPart then
        self:Trigger()
    end
end

--override
function GuideTriggerQuickBuild:Begin()
    GuideTriggerQuickBuild.super.Begin(self)
    local tbTemplate = self.tbTemplate
    local tbParam = tbTemplate.tbParam
    if not tbParam then
        self:LogError("tbParam is nil!")
        return
    end
    self.szQuickBuildType = tbParam[1]
end

function GuideTriggerQuickBuild:BindEvent(EventHelper)
    EventHelper:RegisterEvent(ClientEventDef.EV_FFA_QUICK_BUILD, self, self.OnReciveEvent)
end

return GuideTriggerQuickBuild
