local luaclass = require("luaclass")
local SettingBase = require("SettingBase")
local SettingBasic = luaclass("SettingBasic", SettingBase)
local SettingKeyDef = require("SettingKeyDef")
local EventManager = require("EventManager")
local ClientEventDef = require("ClientEventDef")
local SettingDataTable = require("SettingDataTable")

local LocalKeys = SettingKeyDef.LocalKeys
local RemoteKeys= SettingKeyDef.RemoteKeys

local BASICS = {
    -- [LocalKeys.FIRE_BY_LEFT_HAND] = {

    -- },
    [RemoteKeys.ALLOW_WATCH_HISTORY_STATS] = {
        fnGetDefault = function()
            local tbData = SettingDataTable:GetTemplate(RemoteKeys.ALLOW_WATCH_HISTORY_STATS)
            if tbData then
                return tbData.nDefaultValue
            else
                return 0
            end
        end
    },
    [RemoteKeys.ALLOW_WATCH_SEASON_STATS] = {
        fnGetDefault = function()
            local tbData = SettingDataTable:GetTemplate(RemoteKeys.ALLOW_WATCH_SEASON_STATS)
            if tbData then
                return tbData.nDefaultValue
            else
                return 0
            end
        end
    }, 
    [RemoteKeys.ALLOW_WATCH_OTHER_RELATION] = {
        fnGetDefault = function()
            local tbData = SettingDataTable:GetTemplate(RemoteKeys.ALLOW_WATCH_OTHER_RELATION)
            if tbData then
                return tbData.nDefaultValue
            else
                return 0
            end
        end
    },
    [RemoteKeys.ALOOW_WATCH_TEAM_RELATION] = {
        fnGetDefault = function()
            local tbData = SettingDataTable:GetTemplate(RemoteKeys.ALOOW_WATCH_TEAM_RELATION)
            if tbData then
                return tbData.nDefaultValue
            else
                return 0
            end
        end
    }
}

function SettingBasic:Get(nKey, nDefaultValue)
    local nValue = SettingBasic.super.Get(self, nKey)
    if nValue >= 0 then
        return nValue
    end
    if nDefaultValue then
        return nDefaultValue
    end
    return BASICS[nKey].fnGetDefault()
end

function SettingBasic:Set(nKey, nValue)
    SettingBasic.super.Set(self, nKey, nValue)
    if nKey == LocalKeys.FIRE_BY_LEFT_HAND then
        EventManager:OnFireEvent(ClientEventDef.EV_SETTING_LEFT_HAND_FIRE)
    end
end

return SettingBasic