-----------------------------------------------------
--File Name    : UILobbyShowShipWeapon.lua
--Author       : chenyixin
--Description  : 商城船武器展示界面
-----------------------------------------------------
local luaclass = require("luaclass")
local WndBase = require("WndBase")
local UILobbyShowShipWeapon = luaclass("UILobbyShowShipWeapon", WndBase)

local UIDef = require("UIDef")
local ItemDataTable = require("ItemDataTable")
local LobbySystem = require("LobbySystem")
local LobbySubTypeDef = require("LobbySubTypeDef")

UILobbyShowShipWeapon.OwnerSub = nil
UILobbyShowShipWeapon.nWeaponTemplateId = nil

UILobbyShowShipWeapon.tbWeaponDetail = nil

UILobbyShowShipWeapon.pbWindowFrame = nil
UILobbyShowShipWeapon.ulLobbyShipBdrRotate = nil

local WEAPON_PLATFORM_TAG = "taizi"
local SHIP_WND_NAME = UIDef.UI_LOBBY_SHIP_WEAPON
local SHIP_WND_KEY = "Weapon"

--[[
    GetWeaponDetailData: 生成UPLobbyShipWeaponDetail所需信息
    tbWeaponDetailData = {
        tbTemplate,     -- 当前武器的tbItemTemplate
        nActiveIndex,   -- tbWeaponSlot选中武器类型的所有武器中，当前武器的Index
        nWeaponCount,   -- tbWeaponSlot选中武器类型的所有武器个数
        bUnlocked,      -- 当前武器是否已解锁
    }
]]
local function GetWeaponDetailData(tbTemplate, nActiveIndex, nWeaponCount, bUnlocked)
    return {
        tbTemplate = tbTemplate,
        nActiveIndex = nActiveIndex,
        nWeaponCount = nWeaponCount,
        bUnlocked = bUnlocked,
    }
end

local function OnBackClicked(self)
    LobbySystem:ReturnToPrevSub()
end

---------------------------------------
-- Widget设置
---------------------------------------
local function UpdateWeaponDisplay(self, tbWeaponDetail)
    local tbWeapon = ItemDataTable:GetTemplate(self.nWeaponTemplateId)
    local tbWeaponDetailData = GetWeaponDetailData(tbWeapon, -1, -1, true)
    self.tbWeaponDetail:SetData(tbWeaponDetailData)
    self.OwnerSub:CreateWeaponActorById(tbWeapon.nId)
end

---------------------------------------
-- 初始化
---------------------------------------
local function InitWeaponDetail(self)
    local tbWeaponDetail = self.PrefabHelper:BindPrefab(self.pWidgetRef.pbLobbyShipWeaponDetail)
    -- tbWeaponDetail:SetSwitchBtnVisible(false)
    self.tbWeaponDetail = tbWeaponDetail
end

---------------------------------------
-- life cycle
---------------------------------------
function UILobbyShowShipWeapon:OnLoad()
    local tbOpenArgs = self.tbOpenArgs
    self.OwnerSub = tbOpenArgs.OwnerSub
    self.OwnerSub.szCurOpenWndKey = SHIP_WND_KEY
    self.nWeaponTemplateId = tbOpenArgs.nItemTemplateId
    self.pbWindowFrame = self.PrefabHelper:BindPrefab(self.pWidgetRef.pbWindowFrame)
    self.pbWindowFrame:SetBackDelegate(OnBackClicked, self)
    self.ulLobbyShipBdrRotate = self.UILogicHelper:CreateUILogic("ULLobbyShipBdrRotate")
    InitWeaponDetail(self)
end

function UILobbyShowShipWeapon:OnUnload()
    self.OwnerSub.szCurOpenWndKey = nil
end

function UILobbyShowShipWeapon:OnShow()
    self.OwnerSub.SubLevelLoadHelper:SetCamera(LobbySubTypeDef.SHOW, self:GetWndName(), 1)

    local pWeaponActor = self.OwnerSub:GetSubLevelActorByTag(SHIP_WND_NAME, WEAPON_PLATFORM_TAG)
    self.ulLobbyShipBdrRotate:SetRotateActor(pWeaponActor)
    
    UpdateWeaponDisplay(self)
    self:PlayAnimation("anim_LobbyShipWeaponIn", 0, 1, EUMGSequencePlayMode.Forward, 1)
end

function UILobbyShowShipWeapon:OnHide()
    self.ulLobbyShipBdrRotate:ResetActorRotation()
    self.OwnerSub:DestroyAllShipActors()
    self.nCurrentSelectedSlot = nil
end

function UILobbyShowShipWeapon:OnBindEvent(EventHelper)
end

return UILobbyShowShipWeapon