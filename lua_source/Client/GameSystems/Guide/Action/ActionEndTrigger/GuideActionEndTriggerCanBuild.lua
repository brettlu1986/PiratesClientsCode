-----------------------------------------------------
--File Name    : GuideActionEndTriggerCanBuild.lua
--Description  : 指引动作
-----------------------------------------------------
local luaclass                              = require("luaclass")
local GuideActionEndTriggerBase             = require("GuideActionEndTriggerBase")
local GuideActionEndTriggerCanBuild         = luaclass("GuideActionEndTriggerCanBuild", GuideActionEndTriggerBase)

local ClientEventDef            = require("ClientEventDef")
local GamePlayerSelfHelper      = require("GamePlayerSelfHelper")
local CheckCanBuildItemHelper   = require("CheckCanBuildItemHelper")
-----------------------------------------------------

local function CheckCanBuild(self, _, _, bSuccess)
    if not bSuccess then
        return
    end
    self:DebugLog("CheckCanBuild")
    local bCanBuild = false
    local tbParam = self.tbParam
    local szCanBuildType = tbParam[1]
    local nCharacterInstanceId = GamePlayerSelfHelper:GetServerInstanceId()
    if szCanBuildType == "ship" then
        local szShipId = tbParam[2]
        if szShipId then
            local nShipId = tonumber(szShipId)
            local tbCanBuildTemplateIds = CheckCanBuildItemHelper.GetCanBuildShipItemTemplateIds(nCharacterInstanceId, true)
            for i,v in ipairs(tbCanBuildTemplateIds) do
                if v == nShipId then
                    bCanBuild = true
                    break
                end
            end
        else
            bCanBuild = CheckCanBuildItemHelper.CanBuildShip(nCharacterInstanceId, true)
        end
    elseif szCanBuildType == "shippart" then
        bCanBuild = CheckCanBuildItemHelper.CanBuildShipPart(nCharacterInstanceId, true)
    elseif szCanBuildType == "shipweapon" then
        bCanBuild = CheckCanBuildItemHelper.CanBuildShipWeapon(nCharacterInstanceId, true)
    end
    self:DebugLog("CheckCanBuild bCanBuild = " .. tostring(bCanBuild))
    if bCanBuild then
        self:Triggered()
    end
end

function GuideActionEndTriggerCanBuild:BindEvent(tbParam)
    GuideActionEndTriggerCanBuild.super.BindEvent(self, tbParam)
    self.EventHelper:RegisterEvent(ClientEventDef.EV_PICK_UP_FINISH, self, CheckCanBuild)
end

return GuideActionEndTriggerCanBuild
