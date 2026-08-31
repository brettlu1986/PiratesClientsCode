local luaclass = require("luaclass")
local UILogicBase = require("UILogicBase")
local ULWatchBotWeapon = luaclass("ULWatchBotWeapon", UILogicBase)

local HumanWeaponSlotDef = require("HumanWeaponSlotDef")
local ShipWeaponSlotDef = require("ShipWeaponSlotDef")
local BattleItemDataTable = require("BattleItemDataTable")
local UIDef = require("UIDef")

ULWatchBotWeapon.tbHumanWeaponSlots = nil
ULWatchBotWeapon.bCurrentMastVisible = nil

local CURRENT_MAX_SHIP_SLOT = 4

local function RefreshPlayerWeaponGroupVisible(self)
    local tbCurrentWatchObj = self.Owner.tbCurrrentWatchObj
    local bHuman = tbCurrentWatchObj:IsHuman()

    local pWidgetRef = self.pWidgetRef
    pWidgetRef.hboxHumanWeapon:SetVisibility(bHuman and ESlateVisibility.HitTestInvisible or ESlateVisibility.Collapsed)
    pWidgetRef.hboxShipWeapon:SetVisibility(bHuman and ESlateVisibility.Collapsed or ESlateVisibility.HitTestInvisible)
end

function ULWatchBotWeapon:RefreshCurrentMateWeapon(tbBotState)
    local tbCurrentWatchObj = self.Owner.tbCurrrentWatchObj
    local bHuman = tbCurrentWatchObj:IsHuman()
    local bMessageBHuman = not tbBotState.state.is_ship

    if bHuman ~= bMessageBHuman then  
        log("[BotWatch] : the msg bot state is not same with current , bHuman and bMessageBHuman: ", bHuman, bMessageBHuman)
        return
    end

    local nActiveWeaponSlot = tbBotState.active_weapon_slot
    if nActiveWeaponSlot >= CURRENT_MAX_SHIP_SLOT then  
        return 
    end
    
    local bMastVisible = true
    if bHuman then 
        local tbHumanState = tbBotState.state.human_ext
        local tbHumanBulletInfo =  tbBotState.weapons
        for nSlot, v in ipairs(self.tbHumanWeaponSlots) do  
            -- logdebug("enter here ::", tbHumanState.weapons[nSlot], nActiveWeaponSlot, tbHumanBulletInfo, tbHumanBulletInfo[nSlot] )
            v:RefreshWeaponIcon(tbHumanState.weapons[nSlot], nActiveWeaponSlot)
            local nBullet = 0
            for _, value in pairs(tbHumanBulletInfo) do 
                if value.slotid and value.slotid == nSlot then
                    nBullet = value.bullet
                    break
                end
            end

            if nBullet ~= 0 then  
                v:RefreshWeaponBullet(tbHumanState.weapons[nSlot], nBullet)
            else  
                v:RefreshWeaponBullet(0, 0)
            end
        end
    else  
        local tbShipState = tbBotState.state.ship_ext
        local tbShipBulletInfo =  tbBotState.weapons
        for nSlot, v in ipairs(self.tbShipWeaponSlot) do  
            -- logdebug("enter here ::", tbShipState.weapons[nSlot], nActiveWeaponSlot, tbShipBulletInfo, tbShipBulletInfo[nSlot] )
            v:RefreshWeaponIcon(tbShipState.weapons[nSlot], nActiveWeaponSlot)

            local nBullet = 0
            for _, value in pairs(tbShipBulletInfo) do 
                if value.slotid and value.slotid == nSlot then
                    nBullet = value.bullet
                    break
                end
            end
            if nBullet ~= 0 then
                v:RefreshWeaponBullet(tbShipState.weapons[nSlot], nBullet)
            else   
                v:RefreshWeaponBullet(0, 0)
            end
        end

        if nActiveWeaponSlot and nActiveWeaponSlot > 0 and tbShipState.weapons[nActiveWeaponSlot] > 0 then 
            local tbResTemplate = BattleItemDataTable:GetResTemplate(tbShipState.weapons[nActiveWeaponSlot])
            if tbResTemplate and tbResTemplate.szSilhouettePath then
                bMastVisible = false
            end
        else 
            bMastVisible = true
        end

        if self.bCurrentMastVisible == nil or self.bCurrentMastVisible ~= bMastVisible then
            self.bCurrentMastVisible = bMastVisible
            tbCurrentWatchObj.pUEActor:SetMastVisible(self.bCurrentMastVisible)
        end
        
    end
    RefreshPlayerWeaponGroupVisible(self)
end


local function InitHumanWeaponSlot(self)
    self.tbHumanWeaponSlots = {}
    local pWidgetRef = self.pWidgetRef
    local PrefabHelper = self.PrefabHelper
    local nSlotCount = HumanWeaponSlotDef:SlotCount()
    for i=1, nSlotCount do
        local tbWeaponSlot = PrefabHelper:BindPrefab(pWidgetRef["pbFFAHumanSub" .. i],  UIDef.UP_BOT_HUMAN_WEAPON_SLOT_IN_MAIN)
        if tbWeaponSlot then
            tbWeaponSlot:SetSlotIndex(i)
            self.tbHumanWeaponSlots[i] = tbWeaponSlot
            --init clear human wealon slot
            tbWeaponSlot:RefreshWeaponIcon(0, 0)
            tbWeaponSlot:RefreshWeaponBullet(0, 0)
        end
    end
end

local function InitShipWeaponSlot(self)
    self.tbShipWeaponSlot = {}
    for i=ShipWeaponSlotDef.COMMON_START, ShipWeaponSlotDef.COMMON_END do
        self.tbShipWeaponSlot[i] = self.PrefabHelper:BindPrefab(self.pWidgetRef["pbShipWeaponSlot"..i], UIDef.UP_BOT_SHIP_WEAPON_SLOT)
        self.tbShipWeaponSlot[i]:Init(i)
        --TODO:init clear ship weapon slot
        self.tbShipWeaponSlot[i]:SetActive(false)
        self.tbShipWeaponSlot[i]:RefreshWeaponIcon(0, 0)
        self.tbShipWeaponSlot[i]:RefreshWeaponBullet(0, 0)
    end
end

function ULWatchBotWeapon:OnLoad()
    RefreshPlayerWeaponGroupVisible(self)
    InitHumanWeaponSlot(self)
    InitShipWeaponSlot(self)
end

function ULWatchBotWeapon:OnEnter()
    --Owner is UIWatchBattle
end

function ULWatchBotWeapon:OnBindEvent(EventHelper)
end

function ULWatchBotWeapon:OnUnload()
    --unload res
end

return ULWatchBotWeapon