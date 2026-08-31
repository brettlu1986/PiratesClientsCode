local luaclass = require("luaclass")
local UILogicBase = require("UILogicBase")

local ULWatchBotHumanArmor = luaclass("ULWatchBotHumanArmor", UILogicBase)
local BattleItemCategoryDef = require("BattleItemCategoryDef")
local BattleItemDataTable = require("BattleItemDataTable")
local HumanArmorSlotDef = require("HumanArmorSlotDef")
local UIDef = require("UIDef")

function ULWatchBotHumanArmor:RefreshArmorSlots(tbBotState)
    local tbEquipStates = tbBotState.equipments
    if tbEquipStates ~= nil then  
        local nSlotCount = HumanArmorSlotDef:SlotCount()

        local tbValidArmInfo = {}
        for k , v in pairs(tbEquipStates) do  
            if v and v.templateid ~= 0 then  
                local tbTemplate = BattleItemDataTable:GetTemplate(v.templateid)
                if tbTemplate.nCategory == BattleItemCategoryDef.HUMAN_ARMOR then 
                    table.insert(tbValidArmInfo, v)
                end
            end
        end

        for nSlotIdx = 1, nSlotCount do
            if tbValidArmInfo[nSlotIdx] then
                self.tbArmorSlots[nSlotIdx]:ShowArmor(tbValidArmInfo[nSlotIdx].templateid, tbValidArmInfo[nSlotIdx].durability_percent)
            else  
                self.tbArmorSlots[nSlotIdx]:ShowArmor(0, 0)
            end
        end
    end
end

----------life cycle----------
function ULWatchBotHumanArmor:OnCreate()
    self.tbArmorSlots = {}
end

function ULWatchBotHumanArmor:OnLoad()
    local pWidgetRef = self.pWidgetRef
    local pHumanWatchRef = pWidgetRef.pBotWatchHuman
    local nSlotCount = HumanArmorSlotDef:SlotCount()
    for i = 1, nSlotCount do
        local tbArmorSlot = self.PrefabHelper:BindPrefab(pHumanWatchRef["pbEmquieTip0" .. i],  UIDef.UP_BOT_HUMAN_ARMOR_SLOT_IN_MAIN)
        if tbArmorSlot then
            tbArmorSlot:SetSlotIndex(i)
            tbArmorSlot.pWidgetRef:SetVisibility(ESlateVisibility.Hidden)
            self.tbArmorSlots[i] = tbArmorSlot
        end
    end
end

function ULWatchBotHumanArmor:OnBindEvent( EventHelper )
end

return ULWatchBotHumanArmor