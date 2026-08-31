-----------------------------------------------------
--File Name    : GuideTrigger.lua
--Description  : 指引触发
-----------------------------------------------------
local luaclass                          = require("luaclass")
local GuideTrigger                      = require("GuideTrigger")
local GuideTriggerEnterPickUpMaterial   = luaclass("GuideTriggerEnterPickUpMaterial", GuideTrigger)

local ClientEventDef            = require("ClientEventDef")
local BattleItemDataTable       = require("BattleItemDataTable")
local BattleItemCategoryDef     = require("BattleItemCategoryDef")
-- local BattlePickTypeDef = require("BattlePickTypeDef")
-----------------------------------------------------

function GuideTriggerEnterPickUpMaterial:OnPickupFinish(nInstanceId, nItemTemplateId, bSuccess)
    if not bSuccess then
        return
    end
    self:DebugLog("OnPickupFinish, nInstanceId = " .. tostring(nInstanceId))
    local tbItemTemplate = BattleItemDataTable:GetTemplate(nItemTemplateId)
    if tbItemTemplate == nil then
        self:LogError(" error! tbItemTemplate is nil")
    end
    self:DebugLog("nItemTemplateId = " .. tostring(nItemTemplateId) .. " Category = " .. tostring(tbItemTemplate.nCategory))
    if tbItemTemplate.nCategory == BattleItemCategoryDef.MATERIAL or tbItemTemplate.nCategory == BattleItemCategoryDef.CONVERTIBLE_ITEM then
        self:Trigger()
    else
        self:Break()
    end
end

--override
function GuideTriggerEnterPickUpMaterial:Begin()
    GuideTriggerEnterPickUpMaterial.super.Begin(self)
end

function GuideTriggerEnterPickUpMaterial:BindEvent(EventHelper)
    EventHelper:RegisterEvent(ClientEventDef.EV_PICK_UP_FINISH, self, self.OnPickupFinish)
end

return GuideTriggerEnterPickUpMaterial
