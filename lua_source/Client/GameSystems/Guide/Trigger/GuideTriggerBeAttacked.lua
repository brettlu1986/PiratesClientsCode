-----------------------------------------------------
--File Name    : GuideTriggerOpenUI.lua
--Description  : 指引触发
-----------------------------------------------------
local luaclass              = require("luaclass")
local GuideTrigger          = require("GuideTrigger")
local GuideTriggerBeAttacked    = luaclass("GuideTriggerBeAttacked",GuideTrigger)

local CommonEventDef        = require("CommonEventDef")
local GamePlayerSelfHelper  =   require("GamePlayerSelfHelper")
-----------------------------------------------------
GuideTriggerBeAttacked.nServerInstanceId = nil
GuideTriggerBeAttacked.szType            = ""
GuideTriggerBeAttacked.pPlayerSelf       = nil
-----------------------------------------------------
local function OnTakeDamage(self, tbTaker, tbCauser, nDamage, nDamageType)
    -- logerror("=================OnTakeDamage================= self.nServerInstanceId = " .. tostring(self.nServerInstanceId) .. " tbTaker.= " .. tostring(tbTaker) .. " tbTaker.nServerInstanceId = ".. tostring(tbTaker.nServerInstanceId) .. " tbCauser = " .. tostring(tbCauser) .. " tbCauser.nServerInstanceId = " .. tostring(tbCauser.nServerInstanceId))
    local bHuman = self.pPlayerSelf:IsHuman()
    local szType = self.szType
    if tbTaker == GamePlayerSelfHelper:Get() then    
        if tbCauser and  tbTaker ~= tbCauser then
            if szType == "ship" and not bHuman or szType == "human" and bHuman then
                self:Trigger()
            else
                self:Break()
            end
        end
    end
end

--override
function GuideTriggerBeAttacked:Begin()
    GuideTriggerBeAttacked.super.Begin(self)
    local pPlayerSelf = GamePlayerSelfHelper:Get()
    if pPlayerSelf then
        self.pPlayerSelf = pPlayerSelf
        self.nServerInstanceId = pPlayerSelf.nServerInstanceId
    end
    local tbParam = self.tbTemplate.tbParam
    if not tbParam or not tbParam[1] then
        return
    end
    self.szType = tbParam[1]
end

function GuideTriggerBeAttacked:BindEvent(EventHelper)
    EventHelper:RegisterEvent(CommonEventDef.EV_ON_TAKE_DAMAGE, self, OnTakeDamage)
end


return GuideTriggerBeAttacked
