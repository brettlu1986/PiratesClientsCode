local luaclass = require ("luaclass")
local UPFFABase = require("PrefabBase")
local UPFFABotWatchHuman = luaclass("UPFFABotWatchHuman", UPFFABase)
local UISetUtils = require("UISetUtils")
local UIResourceDef = require("UIResourceDef")
local BattleItemDataTable = require("BattleItemDataTable")

function UPFFABotWatchHuman:OnCreate()
end

function UPFFABotWatchHuman:OnDestroy()
end

function UPFFABotWatchHuman:OnLoad()
end

function UPFFABotWatchHuman:OnBindEvent( EventHelper )
end


local function SetAttackBtnImage(self, szRes, szPressedRes)
    local pRes = szRes:load()
    UISetUtils.SetButtonBrushRes(self.pWidgetRef.btnFight1, pRes)
    UISetUtils.SetButtonBrushRes(self.pWidgetRef.btnFight2, pRes)
    local pPressRes = szPressedRes:load()
    UISetUtils.SetButtonPressedBrushRes(self.pWidgetRef.btnFight1, pPressRes)
    UISetUtils.SetButtonPressedBrushRes(self.pWidgetRef.btnFight2, pPressRes)
end

local function RefreshAttackBtnImage(self, nTemplateId)
    local szRes
    local szPressedRes
    if nTemplateId == 0 then
        szRes = UIResourceDef.FFA_HUMAN_WEAPON_ATTACK_IMAGE_EMPTY_HAND
        szPressedRes = UIResourceDef.FFA_HUMAN_WEAPON_ATTACK_IMAGE_EMPTY_HAND_PRESSED
    else
        local tbTemplate = BattleItemDataTable:GetTemplate(nTemplateId)
        if tbTemplate then
            szRes = tbTemplate.nNormalRes
            szPressedRes = tbTemplate.nPressRes
        end
    end
    
    if szRes and szPressedRes then
        SetAttackBtnImage(self, szRes, szPressedRes)
    end
end

function UPFFABotWatchHuman:RefreshHumanState(tbBotState)
    local nActiveWeaponSlot = tbBotState.active_weapon_slot
    local tbHumanState = tbBotState.state.human_ext
    if nActiveWeaponSlot > 0 then   
        local nWeaponTemplateId = tbHumanState.weapons[nActiveWeaponSlot]
        RefreshAttackBtnImage(self, nWeaponTemplateId)
    else   
        RefreshAttackBtnImage(self, 0)
    end
end

return UPFFABotWatchHuman
