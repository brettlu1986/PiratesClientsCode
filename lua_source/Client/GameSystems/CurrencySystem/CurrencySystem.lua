local luaclass = require("luaclass")
local CurrencySystem = luaclass("CurrencySystem")

local L10N = require("L10N")
local LobbyItemIni = require("LobbyItemIni")
local ItemDataTable = require("ItemDataTable")
local GamePlayerSelfHelper = require("GamePlayerSelfHelper")

local function GetComponent()
    local PlayerSelf = GamePlayerSelfHelper:Get()
    local CurrencyComponent = PlayerSelf.CurrencyComponent
    return CurrencyComponent
end

function CurrencySystem:Init()
end

function CurrencySystem:Uninit()
end

function CurrencySystem:UpdateCurrency(nTemplateId, nCount)
    local Component = GetComponent()
    if Component then
        Component:UpdateCurrency(nTemplateId, nCount)
    end
end

function CurrencySystem:GetCurrencyCount(nTemplateId)
    local Component = GetComponent()
    if Component then
        return Component:GetCurrencyCount(nTemplateId)
    end
    return 0
end

function CurrencySystem:ReachCurrencyMax(nTemplateId)
    local Component = GetComponent()
    if Component then
        local tbRecord = Component:GetCurrencyCeilingsRecords(nTemplateId)
        if tbRecord then
            return tbRecord.nPeriodicCount >= tbRecord.nCeiling
        else
            return false
        end
    end
    return false
end

function CurrencySystem:GetCurrencyCeilingsRecords(nTemplateId)
    local Component = GetComponent()
    if Component then
        return Component:GetCurrencyCeilingsRecords(nTemplateId)
    end
    return nil
end

function CurrencySystem:UpdateCurrencyCeilingsRecords(tbCeilings)
    local Component = GetComponent()
    if Component then
        Component:UpdateCurrencyCeilingsRecords(tbCeilings)
    end
end

function CurrencySystem:UpdateCurrencyCeilingsRefreshTime(nRemainSeconds)
    local Component = GetComponent()
    if Component then
        Component:UpdateCurrencyCeilingsRefreshTime(nRemainSeconds)
    end
end

function CurrencySystem:GetCurrencySmallIcon(nTemplateId)
    local tbItemResTemplate = ItemDataTable:GetResTemplate(nTemplateId)
    if tbItemResTemplate then
        return tbItemResTemplate.szSmallIconPath
    end
    logwarning("CurrencySystem:GetCurrencySmallIcon tbItemResTemplate is nil,nTemplateId=",nTemplateId)
    return ""
end

function CurrencySystem:GetCurrencyName(nTemplateId)
    local tbItemTemplate = ItemDataTable:GetTemplate(nTemplateId)
    if tbItemTemplate then
        return tbItemTemplate.l10nName
    end
    logwarning("CurrencySystem:GetCurrencyName tbItemTemplate is nil,nTemplateId=",nTemplateId)
    return L10N.NullString
end

-- 默认显示在顶栏的货币id列表
function CurrencySystem:GetDefaultDisplayCurrencyIds()
    return LobbyItemIni.tbCurrency.tbDefaultDisplayCurrencyIds
end

-- 默认显示在顶栏的货币id列表
function CurrencySystem:IsDefaultDisplayCurrencyIds(nCurrencyId)
    local tbDefaultDisplayCurrencyIds = self:GetDefaultDisplayCurrencyIds()
    for _, v in ipairs(tbDefaultDisplayCurrencyIds) do
        if v == nCurrencyId then
            return true
        end
    end
    return false
end

return CurrencySystem()