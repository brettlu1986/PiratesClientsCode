-----------------------------------------------------
--File Name    : GuideTriggerCanBuild.lua
--Description  : 指引触发
-----------------------------------------------------
local luaclass              = require("luaclass")
local GuideTrigger          = require("GuideTrigger")
local GuideTriggerCanBuild  = luaclass("GuideTriggerCanBuild", GuideTrigger)

local CheckCanBuildItemHelper   = require("CheckCanBuildItemHelper")
local GamePlayerSelfHelper      = require("GamePlayerSelfHelper")
local ClientEventDef            = require("ClientEventDef")
local BattleItemDataTable       = require("BattleItemDataTable")
-----------------------------------------------------
GuideTriggerCanBuild.szCanBuildType = nil
GuideTriggerCanBuild.tbParam        = nil
-----------------------------------------------------

local function CheckCanBuild(self, _, _, bSuccess)
    if not bSuccess then
        return
    end
    self:DebugLog("CheckCanBuild szCanBuildType = " .. self.szCanBuildType)
    local bCanBuild = false
    local szCanBuildType = self.szCanBuildType
    local tbParam = self.tbParam
    local nCharacterInstanceId = GamePlayerSelfHelper:GetServerInstanceId()
    if szCanBuildType == "ship" then
        local szShipGrade = tbParam[2]
        if szShipGrade then
            local nShipGrade = tonumber(szShipGrade)
            local tbCanBuildTemplateIds = CheckCanBuildItemHelper.GetCanBuildShipItemTemplateIds(nCharacterInstanceId, true)
            for i,v in ipairs(tbCanBuildTemplateIds) do
                local tbItemTemplate = BattleItemDataTable:GetTemplate(v)
                if tbItemTemplate.nGrade == nShipGrade then
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
        self:Trigger()
    else
        self:Break()
    end
end

--override
function GuideTriggerCanBuild:Begin()
    GuideTriggerCanBuild.super.Begin(self)
    local tbParam = self.tbTemplate.tbParam 
    if tbParam and tbParam[1] then
        self.tbParam = tbParam
        self.szCanBuildType = tbParam[1]
        return
    end
    CheckCanBuild(self)
end

function GuideTriggerCanBuild:BindEvent(EventHelper)
    EventHelper:RegisterEvent(ClientEventDef.EV_PICK_UP_FINISH, self, CheckCanBuild)
end

return GuideTriggerCanBuild
