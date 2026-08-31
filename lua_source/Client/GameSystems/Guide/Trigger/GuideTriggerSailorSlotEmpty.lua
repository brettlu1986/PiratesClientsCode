-----------------------------------------------------
--File Name    : GuideTriggerCloseUI.lua
--Author       : Edward J
--Create Time  : 2019-05-14
--Description  : 指引触发
-----------------------------------------------------
local luaclass                      = require("luaclass")
local GuideTrigger                  = require("GuideTrigger")
local GuideTriggerSailorSlotEmpty   = luaclass("GuideTriggerSailorSlotEmpty",GuideTrigger)

local GamePlayerSelfHelper          = require("GamePlayerSelfHelper")
-----------------------------------------------------
--override

function GuideTriggerSailorSlotEmpty:CheckSlotIsEmpty(nSailorType, nSlotIndex)
    local bEmpty = true
    local PlayerSelf = GamePlayerSelfHelper:Get()
    if not PlayerSelf then
        return false
    end
    local SailorComponent = PlayerSelf.SailorComponent
    if not SailorComponent then
        return false
    end
    local tbSlotInfos = SailorComponent:GetSailorSlotInfo()
    for k, v in pairs(tbSlotInfos) do
        if k == nSailorType then
            for i,tbEquippedData in ipairs(v) do
                if i == nSlotIndex then
                    if tbEquippedData and tbEquippedData.bUnlocked and tbEquippedData.nSailorId then
                        self:DebugLog("CheckSlotIsEmpty() Not Empty!")
                        bEmpty = false
                        break;
                    end
                end
            end
        end
    end
    if not self.tbTemplate.bIsEnable then
        bEmpty = not bEmpty
    end
    return bEmpty
end

function GuideTriggerSailorSlotEmpty:GetSlotIndex()
    local nSailorType = self.tbTemplate.tbSailorSlot[1]
    local nSailorSlotIndex = self.tbTemplate.tbSailorSlot[2]
    return nSailorType, nSailorSlotIndex
end

function GuideTriggerSailorSlotEmpty:Begin()
    GuideTriggerSailorSlotEmpty.super.Begin(self)
    local nSailorType, nSailorSlotIndex = self:GetSlotIndex()
    local bResult = self:CheckSlotIsEmpty(nSailorType, nSailorSlotIndex)
    self:DebugLog("CheckSlotIsEmpty() = " .. tostring(bResult) .. type(bResult))
    if bResult then
        self:Trigger()
    else
        self:ForceEndCurrentGroup()
    end
end


return GuideTriggerSailorSlotEmpty
