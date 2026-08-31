local luaclass = require("luaclass")
local NetMessageProcessorBase = require("NetMessageProcessorBase")
local SailorPacketProcessor = luaclass("SailorPacketProcessor", NetMessageProcessorBase)

local UIUtils = require("UIUtils")
local Proto = require("ClientProtoNames")
local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
local NetworkManager = dynamic_require("NetworkManager")
local EventManager = require("EventManager")
local ClientEventDef = require("ClientEventDef")
local CostCurrencyHelper = require("CostCurrencyHelper")

local ErrorReturnCodeText = {
    [Proto.ReturnCode.MONEY_IS_NOT_ENOUGH]              = "RETURN_CODE_MONEY_IS_NOT_ENOUGH_SAILOR_SLOT",
    [Proto.ReturnCode.SAILOR_NOT_FOUND]                 = "RETURN_CODE_SAILOR_NOT_FOUND",
    [Proto.ReturnCode.SAILOR_SLOT_LOCKED]               = "RETURN_CODE_SAILOR_SLOT_LOCKED",
    [Proto.ReturnCode.SAILOR_ADD_FAILED]                = "RETURN_CODE_SAILOR_ADD_FAILED",
    [Proto.ReturnCode.SAILOR_SUMMON_ID_NOT_FOUND]       = "RETURN_CODE_SAILOR_SUMMON_ID_NOT_FOUND",
    [Proto.ReturnCode.SAILOR_CATEGORY_NOT_MATCH]        = "RETURN_CODE_SAILOR_CATEGORY_NOT_MATCH",
    [Proto.ReturnCode.SAILOR_UPGRADE_COUNT_LIMIT]       = "RETURN_CODE_SAILOR_UPGRADE_COUNT_LIMIT",
    [Proto.ReturnCode.SAILOR_UPGRADE_GRADE_LIMIT]       = "RETURN_CODE_SAILOR_UPGRADE_GRADE_LIMIT",
    [Proto.ReturnCode.SAILOR_DEGRADE_COUNT_LIMIT]       = "RETURN_CODE_SAILOR_DEGRADE_COUNT_LIMIT",
    [Proto.ReturnCode.SAILOR_DEGRADE_GRADE_LIMIT]       = "RETURN_CODE_SAILOR_DEGRADE_GRADE_LIMIT",
    [Proto.ReturnCode.SAILOR_EQUIPPED_ALL_TOP_GRADE]    = "RETURN_CODE_SAILOR_EQUIPPED_ALL_TOP_GRADE",
    [Proto.ReturnCode.SAILOR_EQUIPPED_GRADE_LIMIT]      = "RETURN_CODE_SAILOR_EQUIPPED_GRADE_LIMIT",
    [Proto.ReturnCode.SAILOR_EQUIPPED_EMPTY_SLOT]       = "RETURN_CODE_SAILOR_EQUIPPED_EMPTY_SLOT",
    [Proto.ReturnCode.SAILOR_EQUIPPED_COUNT_LIMIT]      = "RETURN_CODE_SAILOR_EQUIPPED_COUNT_LIMIT",
    [Proto.ReturnCode.SAILOR_SLOT_UNLOCKED]             = "RETURN_CODE_SAILOR_SLOT_UNLOCKED",
    [Proto.ReturnCode.SAILOR_SLOT_INVALID]              = "RETURN_CODE_SAILOR_SLOT_INVALID",
    [Proto.ReturnCode.SAILOR_SLOT_WRONG_ORDER]          = "RETURN_CODE_SAILOR_SLOT_WRONG_ORDER",
    [Proto.ReturnCode.SAILOR_NO_FREE_SUMMON_ID]         = "RETURN_CODE_SAILOR_NO_FREE_SUMMON_ID",
    [Proto.ReturnCode.SAILOR_COOLDOWN_LIMITED]          = "RETURN_CODE_SAILOR_COOLDOWN_LIMITED",
    [Proto.ReturnCode.SAILOR_CURRENCY_ID_INVALID]       = "RETURN_CODE_SAILOR_CURRENCY_ID_INVALID"
}

local function CheckReturnCode(nReturnCode)
    if nReturnCode ~= Proto.ReturnCode.OK then
        local szKey = ErrorReturnCodeText[nReturnCode]
        if szKey then
            UIUtils.ShowToastWithKey(szKey)
        else
            logerror("SailorPacketProcessor Unknown error code : " .. nReturnCode)
        end
        return false
    end
    return true
end

local function GetSailorComponent()
    return GamePlayerSelfHelper:Get().SailorComponent
end


local function OnReceiveSailorSummonResult(tbPacket)
    CostCurrencyHelper:FinishRequest()
    local bSummonSucceeded = true
    -- 因为货币不足时有其他转换逻辑，所以不在这里提示
    if tbPacket.return_code == Proto.ReturnCode.MONEY_IS_NOT_ENOUGH then
        bSummonSucceeded = false
    else
        bSummonSucceeded = CheckReturnCode(tbPacket.return_code)
    end

    GetSailorComponent():ReceiveSailorSummonResult(bSummonSucceeded,
                                                   tbPacket.result,
                                                   tbPacket.free_result,
                                                   tbPacket.summon_group_count,
                                                   tbPacket.return_code,
                                                   tbPacket.currency_auto_exchange)
end

local function OnReceiveSailorEquipResult(tbPacket)
    if CheckReturnCode(tbPacket.return_code) then
        GetSailorComponent():ReceiveSailorEquipResult(tbPacket.sailor_slot.sub_category,
                                                      tbPacket.sailor_slot.slot_index,
                                                      tbPacket.equipped_sailor,
                                                      tbPacket.unequipped_sailor)
    end
end

local function OnReceiveSailorUpgradeResult(tbPacket)
    if CheckReturnCode(tbPacket.return_code) then
        GetSailorComponent():ReceiveSailorUpgradeResult(tbPacket.sailor_template_id,
                                                        tbPacket.count,
                                                        tbPacket.upgraded_sailor_template_id,
                                                        tbPacket.upgraded_sailor)
    end
end

local function OnReceiveSailorDegradeResult(tbPacket)
    if CheckReturnCode(tbPacket.return_code) then
        GetSailorComponent():ReceiveSailorDegradeResult(tbPacket.sailor_template_id,
                                                        tbPacket.count,
                                                        tbPacket.degraded_sailor_template_id,
                                                        tbPacket.degraded_sailor)
    end
end

local function OnReceiveUpgradeEquippedSailorResult(tbPacket)
    if CheckReturnCode(tbPacket.return_code) then
        GetSailorComponent():ReceiveUpgradeEquippedSailorResult(tbPacket.sailor,
                                                                tbPacket.one_key_upgrade)
    end
end

local function OnReceiveSailorUnequipAllResult(tbPacket)
    if CheckReturnCode(tbPacket.return_code) then
        GetSailorComponent():ReceiveSailorUnequipAllResult()
    end
end

local function OnReceiveSailorUnequipCategoryResult(tbPacket)
    if CheckReturnCode(tbPacket.return_code) then
        GetSailorComponent():ReceiveSailorUnequipCategoryResult(tbPacket.sub_category)
    end
end

local function OnReceiveUnlockSailorSlotResult(tbPacket)
    CostCurrencyHelper:FinishRequest()
    local bSummonSucceeded = true
    -- 因为货币不足时有其他转换逻辑，所以不在这里提示
    if tbPacket.return_code == Proto.ReturnCode.MONEY_IS_NOT_ENOUGH then
        bSummonSucceeded = false
        EventManager:OnFireEvent(ClientEventDef.EV_ON_RECEIVE_UNLOCK_SAILOR_SLOT_NOT_ENOUGH_MONEY, tbPacket.currency_auto_exchange)
    else
        bSummonSucceeded = CheckReturnCode(tbPacket.return_code)
    end

    if bSummonSucceeded then
        GetSailorComponent():ReceiveUnlockSailorSlotResult(tbPacket.sailor_slot)
    end
end

function SailorPacketProcessor:RegisterPackets()
    self:BindFunc(Proto.s2c_SailorSummon, OnReceiveSailorSummonResult)
    self:BindFunc(Proto.s2c_SailorEquip, OnReceiveSailorEquipResult)
    self:BindFunc(Proto.s2c_SailorUpgrade, OnReceiveSailorUpgradeResult)
    self:BindFunc(Proto.s2c_SailorDegrade, OnReceiveSailorDegradeResult)
    self:BindFunc(Proto.s2c_UpgradeEquippedSailor, OnReceiveUpgradeEquippedSailorResult)
    self:BindFunc(Proto.s2c_SailorUnequipAll, OnReceiveSailorUnequipAllResult)
    self:BindFunc(Proto.s2c_UnlockSailorSlot, OnReceiveUnlockSailorSlotResult)
    self:BindFunc(Proto.s2c_TheSameSailorUnequip, OnReceiveSailorUnequipCategoryResult)
end

function SailorPacketProcessor:Init()
    SailorPacketProcessor.super.Init(self)
    self:SetBinder(NetworkManager:GetHubServerProxy())
    self:RegisterPackets()
    return true
end

return SailorPacketProcessor
