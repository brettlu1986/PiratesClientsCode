local luaclass = require("luaclass")
local SettingBase = require("SettingBase")
local SettingPickUp = luaclass("SettingPickUp", SettingBase)
local SettingKeyDef = require("SettingKeyDef")
local SettingPickUpDataTable = require("SettingPickUpDataTable")

local LocalKeys = SettingKeyDef.LocalKeys
local START_KEY = LocalKeys.PICK_UP_START

function SettingPickUp:LoadLocalSetting()
    local tbOwner = self.Owner
    local tbAll = SettingPickUpDataTable:GetAll()
    for k, v in pairs(tbAll) do
        tbOwner:Get(k + START_KEY, -1)
    end
    for i = LocalKeys.PICK_UP_AUTO, LocalKeys.PICK_UP_LIST_AUTO do
        tbOwner:Get(i)
    end
end

function SettingPickUp:GetValue(nId)
    local nValue = self.Owner:Get(nId + START_KEY, -1)
    if nValue < 0 then
        local tbData = SettingPickUpDataTable:GetTemplate(nId)
        nValue = tbData.nDefaultCount
    end
    return nValue
end

function SettingPickUp:GetValueByItemId(nItemId)
    local tbPickUpData = SettingPickUpDataTable:GetTemplateByItemId(nItemId)
    if tbPickUpData then
        if tbPickUpData.nSettingType > 0 then
            return self:GetValue(tbPickUpData.nId)
        else
            return tbPickUpData.nMaxCount
        end
    end
    return -1
end

function SettingPickUp:IsAutoPick()
    local nValue = self:Get(LocalKeys.PICK_UP_AUTO)
    return nValue > 0
end

function SettingPickUp:IsAutoChangeSail()
    local nValue = self:Get(LocalKeys.PICK_UP_AUTO_CHANGE_SAIL)
    return nValue > 0
end

function SettingPickUp:IsListAutoPick()
    local nValue = self:Get(LocalKeys.PICK_UP_LIST_AUTO)
    return nValue > 0
end

function SettingPickUp:SetValue(nId, nValue)
    nId = START_KEY + nId
    self:Set(nId, nValue)
end

function SettingPickUp:SetValueByItemId(nItemId, nValue)
    local tbPickUpData = SettingPickUpDataTable:GetTemplateByItemId(nItemId)
    if tbPickUpData then
        self:SetValue(tbPickUpData.nId, nValue)
    end
end

return SettingPickUp