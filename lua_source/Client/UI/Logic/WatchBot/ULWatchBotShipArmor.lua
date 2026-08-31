
local luaclass = require("luaclass")
local UILogicBase = require("UILogicBase")
local ULWatchBotShipArmor = luaclass("ULWatchBotShipArmor", UILogicBase)
local ShipPartTypeDef = require("ShipPartTypeDef")
local BattleItemCategoryDef = require("BattleItemCategoryDef")
local BattleItemDataTable = require("BattleItemDataTable")
local UIDef = require("UIDef")

ULWatchBotShipArmor.tbSlots = { }

function ULWatchBotShipArmor:RefreshArmorSlots(tbBotState)
    local tbEquipStates = tbBotState.equipments
    if tbEquipStates ~= nil then  
        local nSlotCount = ShipPartTypeDef.Max

        local tbValidArmInfo = {}
        for k , v in pairs(tbEquipStates) do  
            if v and v.templateid ~= 0 then  
                local tbTemplate = BattleItemDataTable:GetTemplate(v.templateid)
                if tbTemplate.nCategory == BattleItemCategoryDef.SHIP_PART then 
                    table.insert(tbValidArmInfo, v)
                end
            end
        end

        for nSlotIdx = 1, nSlotCount do
            if tbValidArmInfo[nSlotIdx] then
                self.tbSlots[nSlotIdx]:ShowArmor(tbValidArmInfo[nSlotIdx].templateid, tbValidArmInfo[nSlotIdx].durability_percent)
            else  
                self.tbSlots[nSlotIdx]:ShowArmor(0, 0)
            end
        end
    end
end


function ULWatchBotShipArmor:OnLoad()
    self.tbSlots = {}
    local pShipWatchRef = self.pWidgetRef.pBotWatchShip
    for i=1, ShipPartTypeDef.Max do
        self.tbSlots[i] = self.PrefabHelper:BindPrefab(pShipWatchRef["pbShipPartSlot0"..i], UIDef.UP_BOT_SHIP_ARMOR_SLOT_IN_MAIN)
        self.tbSlots[i]:Init(i)
    end
end

return ULWatchBotShipArmor