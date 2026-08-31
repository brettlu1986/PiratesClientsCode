local ProgressBarTableNew = require("ProgressBarTableNew")
local BattleBuffDataTable = require("BattleBuffDataTable")
local BattleAbilityDefine = require("BattleAbilityDefine")

local ConsumableItemDataTableHelper = {}

function ConsumableItemDataTableHelper.ParseExtraAttriLine(Parser, NewTemplate)
    NewTemplate.tbShipBuffs              = Parser:Get("ship_buffs"                    , {}    , Parser.TypeArrayInt)
    NewTemplate.tbHumanBuffs             = Parser:Get("human_buffs"                   , {}    , Parser.TypeArrayInt)
    NewTemplate.nHpLimit                 = Parser:Get("hp_limit"                      , nil   , Parser.TypeInt)
    NewTemplate.nShipProgressBar         = Parser:Get("ship_progress_bar"             , nil   , Parser.TypeInt)
    NewTemplate.nHumanProgressBar        = Parser:Get("human_progress_bar"            , nil   , Parser.TypeInt)
    NewTemplate.nValidTargetType         = Parser:Get("valid_target_type"             , 0     , Parser.TypeInt)
    NewTemplate.nConsumableBarSortWeight = Parser:Get("consumable_bar_sort_weight"    , 0     , Parser.TypeInt)
    NewTemplate.nRecoveringType     = Parser:Get("recovering_type"      , 0     , Parser.TypeInt)
    NewTemplate.nRecoveringValueType= Parser:Get("recovering_value_type", 0     , Parser.TypeInt)
    NewTemplate.nRecoveringValue    = Parser:Get("recovering_value"     , 0     , Parser.TypeFloat)
end

function ConsumableItemDataTableHelper.ValidateAttriLine(NewTemplate)
    local nShipProgressBar = NewTemplate.nShipProgressBar
    local tbShipProgressBar = ProgressBarTableNew:GetTemplate(nShipProgressBar)
    if not tbShipProgressBar then
        error("ConsumableItemDataTableHelper.ValidateAttriLine failed. Ship progress bar invalid. Item template id: "..NewTemplate.nId..". nShipProgressBar: "..nShipProgressBar)
        return
    end

    local nHumanProgressBar = NewTemplate.nHumanProgressBar
    local tbHumanProgressBar = ProgressBarTableNew:GetTemplate(nHumanProgressBar)
    if not tbHumanProgressBar then
        error("ConsumableItemDataTableHelper.ValidateAttriLine failed. Human progress bar invalid. Item template id: "..NewTemplate.nId..". nHumanProgressBar: "..nHumanProgressBar)
        return
    end

    for _, nBuffId in ipairs(NewTemplate.tbShipBuffs) do
        local tbBuffTemplate = BattleBuffDataTable:GetTemplate(nBuffId)
        if not tbBuffTemplate then
            error("ConsumableItemDataTableHelper.ValidateAttriLine failed. Buff doesn't exist. Item template id: "..NewTemplate.nId..". nBuffId: "..nBuffId)
            return
        end
        local BuffAddableTargetType = BattleAbilityDefine.BUFF_ADDABLE_TARGET_TYPE

        if tbBuffTemplate.nAddableTargetType ~= BuffAddableTargetType.SHIP
            and tbBuffTemplate.nAddableTargetType ~= BuffAddableTargetType.SHIP_AND_HUMAN then
                error("ConsumableItemDataTableHelper.ValidateAttriLine failed. Ship buff Invalid! Item template id: "..NewTemplate.nId..". nBuffId: "..nBuffId)
            return
        end
    end

    for _, nBuffId in ipairs(NewTemplate.tbHumanBuffs) do
        local tbBuffTemplate = BattleBuffDataTable:GetTemplate(nBuffId)
        if not tbBuffTemplate then
            error("ConsumableItemDataTableHelper.ValidateAttriLine failed. Buff doesn't exist. Item template id: "..NewTemplate.nId..". nBuffId: "..nBuffId)
            return
        end
        local BuffAddableTargetType = BattleAbilityDefine.BUFF_ADDABLE_TARGET_TYPE

        if tbBuffTemplate.nAddableTargetType ~= BuffAddableTargetType.HUMAN
            and tbBuffTemplate.nAddableTargetType ~= BuffAddableTargetType.SHIP_AND_HUMAN then
                error("ConsumableItemDataTableHelper.ValidateAttriLine failed. Human buff Invalid! Item template id: "..NewTemplate.nId..". nBuffId: "..nBuffId)
            return
        end
    end
end

return ConsumableItemDataTableHelper
