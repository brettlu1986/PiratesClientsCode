-----------------------------------------------------
--File Name    : ItemOld.lua
--Author       : yangyankun
--Create Time  : 2016-06-22
--Description  : ItemOld 物品基类，武器和道具为他们的子类
-----------------------------------------------------

local luaclass = require("luaclass")
local ItemOld = luaclass ("ItemOld")
local Env = require("Env")
local GlobalVariableSystem = require("GlobalVariableSystem_C")
local ItemExpireTypeDef = require("ItemExpireTypeDefine")

ItemOld.nInstanceId = Env.NUMBER_INVALID     -- Instance id 服务器生成的物品内存唯一id
ItemOld.tbTemplate = nil                   -- item 模板 
ItemOld.nStackCount = Env.NUMBER_INVALID        -- 堆叠数量
ItemOld.nCreateTime = Env.NUMBER_INVALID        -- 物品创建时间(秒)，只有创建后计时的会过期物品才会有这个属性
ItemOld.nFirstUseTime = Env.NUMBER_INVALID      -- 物品第一次使用时间(秒)，只有第一次使用后计时的会过期物品才会有这个属性

function ItemOld:SetTemplate(tbNewTemplate)
    self.tbTemplate = tbNewTemplate
end

function ItemOld:GetTemplate()
    return self.tbTemplate
end

function ItemOld:SetInstanceId(nNewInstanceId)
    self.nInstanceId = nNewInstanceId
end

function ItemOld:GetInstanceId()
    return self.nInstanceId
end

function ItemOld:SetStackCount(nNewStackCount)
    self.nStackCount = nNewStackCount
end

function ItemOld:GetStackCount()
    return self.nStackCount
end

function ItemOld:SetCreateTime(nCreateTime)
    self.nCreateTime = nCreateTime
end

function ItemOld:SetFirstUseTime(nFirstUseTime)
    self.nFirstUseTime = nFirstUseTime
end

-- 获得物品还有多少秒过期, -1表示不会过期
function ItemOld:GetRemainExpireSeconds()
    local nExpireType = self.tbTemplate.nExpireType
    if nExpireType == ItemExpireTypeDef.NO_EXPIRE then
        return -1
    end
    local nExpireSeconds = self.tbTemplate.nExpireSeconds
    if nExpireSeconds == nil or nExpireSeconds <= 0 then
        return -1
    end

    if nExpireType == ItemExpireTypeDef.EXPIRE_AFTER_USE and self.nFirstUseTime == 0 then
        return -1
    end

    local nBeginTime = 0
    if nExpireType == ItemExpireTypeDef.EXPIRE_AFTER_CREATE then
        nBeginTime = self.nCreateTime
    elseif nExpireType == ItemExpireTypeDef.EXPIRE_AFTER_USE then
        nBeginTime = self.nFirstUseTime
    end

    local now = GlobalVariableSystem:GetServerTimeUtc()
    local nRemainSeconds = nBeginTime + nExpireSeconds - now
    if nRemainSeconds < 0 then
        return 0
    else
        return nRemainSeconds
    end
end

return ItemOld
