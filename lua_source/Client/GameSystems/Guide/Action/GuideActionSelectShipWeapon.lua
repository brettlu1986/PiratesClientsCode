-----------------------------------------------------
--File Name    : GuideActionSelectShipWeapon.lua
--Description  : 出航引导选择武器
-----------------------------------------------------
local luaclass                      = require("luaclass")
local GuideActionSelectWidget       = require("GuideActionSelectWidget")
local GuideActionSelectShipWeapon   = luaclass("GuideActionSelectShipWeapon", GuideActionSelectWidget)

local GamePlayerSelfHelper          = require("GamePlayerSelfHelper")
local BattleItemCategoryDef         = require("BattleItemCategoryDef")
local UIManager                     = require("UIManager")
local UIDef                         = require("UIDef")
local GuideSystem                   = require("GuideSystem")

local ShipItemHelper                = require("ShipItemHelper")
local BattleItemDataTable           = require("BattleItemDataTable")
local ShipWeaponCategoryDataTable   = require("ShipWeaponCategoryDataTable")
local ShipWeaponSlotDef             = require("ShipWeaponSlotDef")
local BattleItemSystemClient        = require("BattleItemSystemClient")
-----------------------------------------------------
GuideActionSelectShipWeapon.szCurrentSlotName = ""

--当前船没有推荐武器，按照这个顺序查找
local tbSearchOrder = {ShipWeaponSlotDef.SIDE, ShipWeaponSlotDef.HEAD, ShipWeaponSlotDef.DECK }
-----------------------------------------------------

local function GetRecommendSlot(nShipTemplateId)
    local tbItemShipTemplate = ShipItemHelper.GetItemTemplateByShipTemplateId(nShipTemplateId)
    local tbRecommendedWeapons = tbItemShipTemplate.tbRecommendedWeapons
    if #tbRecommendedWeapons > 0 then   
        local nRId = tbRecommendedWeapons[1]
        local tbRecommandWeaponTemplate = BattleItemDataTable:GetTemplate(nRId)
        return ShipWeaponCategoryDataTable:GetWeaponSlot(tbRecommandWeaponTemplate.nSubCategory)
    end
    return ShipWeaponSlotDef.UNKNOWN
end

local function GetShipSlotEquipState()
    local PlayerSelf = GamePlayerSelfHelper:Get()
    local bEquipHead = BattleItemSystemClient:GetEquippedItem(BattleItemCategoryDef.SHIP_WEAPON, PlayerSelf.nServerInstanceId, ShipWeaponSlotDef.HEAD) ~= nil
    local bEquipSide = BattleItemSystemClient:GetEquippedItem(BattleItemCategoryDef.SHIP_WEAPON, PlayerSelf.nServerInstanceId, ShipWeaponSlotDef.SIDE) ~= nil
    local bEquipDeck = BattleItemSystemClient:GetEquippedItem(BattleItemCategoryDef.SHIP_WEAPON, PlayerSelf.nServerInstanceId, ShipWeaponSlotDef.DECK) ~= nil
    return {
        [ShipWeaponSlotDef.HEAD] = bEquipHead,
        [ShipWeaponSlotDef.SIDE] = bEquipSide,
        [ShipWeaponSlotDef.DECK] = bEquipDeck,
    }
end

function GuideActionSelectShipWeapon:GetSelectWidgets()
    local Widget = nil
    local tbTemp = {}
    local Wnd = UIManager:GetWnd(UIDef.UI_FFA_MAIN)
    if not Wnd then
        self:LogError(" GuideActionSelectShipWeapon 1")
        return tbTemp
    end
   
    local PlayerSelf = GamePlayerSelfHelper:Get()
    if PlayerSelf:IsShip() then  
        self:DebugLog("GuideActionSelectShipWeapon begin 0000")
        local nTargetRecommendSlot = ShipWeaponSlotDef.UNKNOWN

        local nShipTemplateId = PlayerSelf:GetShipTemplateId()
        local nRecommendSlot = GetRecommendSlot(nShipTemplateId)
        local tbCurrentShipEquipState = GetShipSlotEquipState()
        if nRecommendSlot == ShipWeaponSlotDef.UNKNOWN or tbCurrentShipEquipState[nRecommendSlot] == false then   
            for i,v in ipairs(tbSearchOrder) do  
                if tbCurrentShipEquipState[v] then  
                    nTargetRecommendSlot = v
                    break
                end
            end
        else  
            nTargetRecommendSlot = nRecommendSlot
        end
        self:DebugLog("GuideActionSelectShipWeapon select ship weapon 111", nTargetRecommendSlot)
        if nTargetRecommendSlot ~= ShipWeaponSlotDef.UNKNOWN then 
            if Wnd.pWidgetRef and Wnd.pWidgetRef.pbFFAShip["pbShipWeaponSlot" .. nTargetRecommendSlot] then
                Widget = Wnd.pWidgetRef.pbFFAShip["pbShipWeaponSlot" .. nTargetRecommendSlot].chkSlot
                self.szCurrentSlotName = "pbShipWeaponSlot" .. nTargetRecommendSlot
            end
            self:DebugLog("GuideActionSelectShipWeapon select ship weapon 22")
            table.insert(tbTemp, Widget)
        end
           
    else  
        self:DebugLog("GuideActionSelectShipWeapon error")
        self:LogError(" GuideActionSelectShipWeapon this is a ship weapon select guide, player should not be a human")
    end
   
    return tbTemp
end

function GuideActionSelectShipWeapon:GetParentScale(tbTemplate)
    local tbScaleParent = tbTemplate.tbScaleParent
    local eLayoutType = 0
    local szScaleParentName = ""
    if tbScaleParent then
        eLayoutType = tonumber(tbScaleParent[1])
        szScaleParentName = self.szCurrentSlotName
    end
    local Scale = GuideSystem:GetLayoutScale(eLayoutType, szScaleParentName) --RenderTransform.Scale
    return Scale
end

return GuideActionSelectShipWeapon
