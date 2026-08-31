-----------------------------------------------------
--File Name    : BattleItemAutoPickUpHelper.lua
--Author       : WuJizhou
--Create Time  : 6/14/2019, 11:39:25 AM
--Description  : BattleItemAutoPickUpHelper
-----------------------------------------------------
local BattleItemAutoPickUpHelper = {}

local SettingPickUpDataTable = require("SettingPickUpDataTable")

local SettingSystemNew = nil
local SettingClassType = nil

function BattleItemAutoPickUpHelper.GetAutoPickUpSettingValue(bIsClient, nItemTemplateId)
    local nValue
    if bIsClient then
        if not SettingSystemNew then
            SettingSystemNew = require("SettingSystemNew")
        end
        if not SettingClassType then
            SettingClassType = require("SettingClassType")
        end
        local tbSettingPickUp = SettingSystemNew:GetInstance(SettingClassType.Setting_PickUp)
        -- SettingSystemNew:SetUseDefaultSaveId(true)
        if not tbSettingPickUp:IsAutoPick() then
            nValue = 0
        end
        nValue = tbSettingPickUp:GetValueByItemId(nItemTemplateId)
        -- SettingSystemNew:SetUseDefaultSaveId(false)
    else
        local tbPickUpData = SettingPickUpDataTable:GetTemplateByItemId(nItemTemplateId)
        if tbPickUpData then
            nValue = tbPickUpData.nMaxCount
        else
            nValue = -1
        end
    end
    return nValue
end


function BattleItemAutoPickUpHelper.CanAutoPickUp(bIsClient)
    if bIsClient then
        if not SettingSystemNew then
            SettingSystemNew = require("SettingSystemNew")
        end
        if not SettingClassType then
            SettingClassType = require("SettingClassType")
        end
        local tbSettingPickUp = SettingSystemNew:GetInstance(SettingClassType.Setting_PickUp)
        -- SettingSystemNew:SetUseDefaultSaveId(true)
        local bResult = tbSettingPickUp:IsAutoPick()
        -- SettingSystemNew:SetUseDefaultSaveId(false)
        return bResult
    else
        return true
    end
end

return BattleItemAutoPickUpHelper