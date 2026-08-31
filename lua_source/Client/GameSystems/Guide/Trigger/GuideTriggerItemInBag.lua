-----------------------------------------------------
--File Name    : GuideTrigger.lua
--Description  : 指引触发
-----------------------------------------------------
local luaclass                  = require("luaclass")
local GuideTrigger              = require("GuideTrigger")
local GuideTriggerItemInBag     = luaclass("GuideTriggerItemInBag", GuideTrigger)
local ClientEventDef            = require("ClientEventDef")

local BattleItemSystemHelper    = require("BattleItemSystemHelper")
local GamePlayerSelfHelper      = require("GamePlayerSelfHelper")

GuideTriggerItemInBag.tbItemIds = nil
GuideTriggerItemInBag.bHadOne = nil
-----------------------------------------------------

local function VerifyItemInBag(self)
    self:DebugLog("ItemInBag")
    if self.tbItemIds == nil then
        self:LogError("ItemInBag not  item")
        return
    end

    local nInstanceId = GamePlayerSelfHelper:Get():GetServerInstanceId()
    local bResult = false
    for i, v in ipairs(self.tbItemIds) do
        local nCount = BattleItemSystemHelper:GetUnequippedItemCount(nInstanceId, v, true)
        self:DebugLog("count", nCount)
        if self.bHadOne then
            if nCount > 0 then
                bResult = true
                break
            end
        else
            if nCount <= 0 then
                break
            end
        end
    end

    if bResult then
        self:DebugLog("Trigger")
        self:Trigger()
    else
        self:Break()
    end
end

local function OnItemAdd(self, tbItem)
    VerifyItemInBag(self)
end

--override
function GuideTriggerItemInBag:Begin()
    GuideTriggerItemInBag.super.Begin(self)
    local tbItemId = self.tbTemplate.tbItemId
    self.tbItemIds = tbItemId
    local tbParam = self.tbTemplate.tbParam
    self.bHadOne = tbParam == nil or tonumber(tbParam[1]) == 1 
    self:DebugLog("Begin", self.bHadOne)
    VerifyItemInBag(self)
end

function GuideTriggerItemInBag:BindEvent(EventHelper)
    self:DebugLog("BindEvent")
    EventHelper:RegisterEvent(ClientEventDef.EV_BATTLE_ITEM_ADD_CLIENT, self, OnItemAdd)
end

return GuideTriggerItemInBag
