-----------------------------------------------------
--File Name    : Item.lua
--Author       : zhiyuan
--Create Time  : 2019-02-22
--Description  : 大厅里道具class
-----------------------------------------------------

local luaclass = require("luaclass")
local Item = luaclass ("Item")

local ItemExpireDef = require("ItemExpireDef")
local GlobalVariableSystem = require("GlobalVariableSystem_C")

Item.nInstanceId = -1        -- 道具唯一id
Item.tbTemplate = nil        -- item 配置
Item.nStackCount = -1        -- 堆叠数量
Item.nCreateSeconds = -1     -- 物品创建时间(秒)
Item.nExpireAtSeconds = -1   -- 物品过期时间(秒)

-----------------------------------------local function---------------------------------------------
local function GetNormalRemainCanUseSeconds(self)
    local tbTemplate = self.tbTemplate
    local nBeginTime = self:GetCreateSeconds()
    local now = GlobalVariableSystem:GetServerTimeUtc()
    local nExpireSeconds = tbTemplate.nExpirationSeconds
    local nRemainSeconds = nBeginTime + nExpireSeconds - now
    if nRemainSeconds < 0 then
        return 0
    else
        return nRemainSeconds
    end
end

local function GetStackTimeRemainCanUseSeconds(self)
    local nExpireAtSeconds = self.nExpireAtSeconds
    if nExpireAtSeconds == 0 then
        error("Item is Non-expired!")
    end
    local now = GlobalVariableSystem:GetServerTimeUtc()
    local nRemainSeconds = nExpireAtSeconds - now
    if nRemainSeconds < 0 then
        return 0
    else
        return nRemainSeconds
    end
end

-----------------------------------------初始化和属性改变时调用的set方法---------------------------------------------
function Item:SetInstanceId(nNewInstanceId)
    self.nInstanceId = nNewInstanceId
end

function Item:SetTemplate(tbNewTemplate)
    self.tbTemplate = tbNewTemplate
end

function Item:SetStackCount(nNewStackCount)
    self.nStackCount = nNewStackCount
end

function Item:SetCreateSeconds(nCreateSeconds)
    self.nCreateSeconds = nCreateSeconds
end

function Item:SetExpireAtSeconds(nExpireAtSeconds)
    self.nExpireAtSeconds = nExpireAtSeconds
end

-----------------------------------------查询时调用的Get方法--------------------------------------------
function Item:GetInstanceId()
    return self.nInstanceId
end

function Item:GetTemplate()
    return self.tbTemplate
end

function Item:GetTemplateId()
    return self.tbTemplate.nId
end

function Item:GetStackCount()
    return self.nStackCount
end

function Item:GetCreateSeconds()
    return self.nCreateSeconds
end

function Item:GetCategory()
    return self.tbTemplate.nCategory
end

function Item:GetSubCategory()
    return self.tbTemplate.nSubCategory
end

function Item:GetGrade()
    return self.tbTemplate.nGrade
end

function Item:GetName()
    return self.tbTemplate.l10nName
end

function Item:HasExpiration()
    local tbTemplate = self.tbTemplate
    local nExpireType = tbTemplate.nExpireType
    if nExpireType == ItemExpireDef.NORMAL then
        return self.tbTemplate.bHasExpiration
    elseif nExpireType == ItemExpireDef.STACK_TIME then
        return self.nExpireAtSeconds ~= 0
    end
end

function Item:CanSell()
    return self.tbTemplate.bCanSell
end

function Item:GetCurrencyId()
    return self.tbTemplate.nCurrencyId
end

function Item:GetSellPrice()
    return self.tbTemplate.nSellPrice
end

function Item:HasHoldLimit()
    return self.tbTemplate.bHasHoldLimit
end

function Item:GetHoldLimit()
    return self.tbTemplate.nHoldLimit
end

function Item:GetRemainCanUseSeconds()
    if not self:HasExpiration() then
        error("Cannot GetRemainCanUseTime! Item do not has expiration!"..Item:GetTemplateId())
    end

    local tbTemplate = self.tbTemplate
    local nExpireType = tbTemplate.nExpireType
    if nExpireType == ItemExpireDef.NORMAL then
        return GetNormalRemainCanUseSeconds(self)
    elseif nExpireType == ItemExpireDef.STACK_TIME then
        return GetStackTimeRemainCanUseSeconds(self)
    end

    error("Cannot GetRemainCanUseTime! expire type error!"..nExpireType)
end

return Item
