-----------------------------------------------------
--File Name    : UILobbyShipOverview.lua
--Author       : chenyixin
--Description  : 舰船总览
-----------------------------------------------------
local luaclass = require("luaclass")
local WndBase = require("WndBase")
local UILobbyShipOverview = luaclass("UILobbyShipOverview", WndBase)

local LobbyShipDef = require("LobbyShipDef")
local SelfTabBarHelper = require("SelfTabBarHelper")
local UIUtils = require("UIUtils")

local LobbyShipWndDef = LobbyShipDef.WndDef

UILobbyShipOverview.OwnerSub = nil
UILobbyShipOverview.pbWindowFrame = nil

local function OnTabClicked(self, nSelectIndex)
    local szKey = LobbyShipWndDef.tbKeys[nSelectIndex]
    if not self.OwnerSub or not szKey then
        return
    end
    self.OwnerSub:OpenShipWnd(szKey, self:GetWndName())
end

local function OnBack()
    UIUtils.BottomMenuSelect(1, true)
end

function UILobbyShipOverview:OnLoad()
    local tbOpenArgs = self.tbOpenArgs
    self.OwnerSub = tbOpenArgs.OwnerSub
    self.pbWindowFrame = self.PrefabHelper:BindPrefab(self.pWidgetRef.pbWindowFrame)
    self.pbWindowFrame:SetBackDelegate(OnBack, self)
    self.tbTabBarHelper = SelfTabBarHelper()
    self.tbTabBarHelper:Init(self, self.pWidgetRef.vboxTab, -1)
    self.tbTabBarHelper.OnSelectedChangedDelegate:Bind(OnTabClicked, self)
end

function UILobbyShipOverview:OnShow()
    self.tbTabBarHelper:UnselectAll()
    local tbEquippedShipIds = self.OwnerSub:GetEquippedShipIds()
    if tbEquippedShipIds and #tbEquippedShipIds > 0 then
        local nShipId = 0
        for _, v in pairs(tbEquippedShipIds) do
            if v and v > 0 then
                nShipId = v
                break
            end
        end
        if nShipId and nShipId > 0 then
            nShipId = self.OwnerSub:GetShipPreparationComponent():GetEquippedShipSkinId(nShipId)
            local tbHullModify = self.OwnerSub:GetShipModelModifyByKey("Hull", nShipId)
            local tbModify = self.OwnerSub:MakeModify(0,0,0,0,0,0,1)
            if tbHullModify then
                tbModify.tbLocation = tbHullModify.tbLocation
                tbModify.nScale = tbHullModify.nScale
            end
            self.OwnerSub:CreateShipActorById(nShipId, 1, tbModify)
        end
    end

    for i = 1, self.tbTabBarHelper:GetButtonCount() do
        local szKey = LobbyShipWndDef.tbKeys[i]
        self.tbTabBarHelper:SetTipIconVisible(i, self.OwnerSub:CheckLobbyShipTabShowTipIcon(szKey))
    end
    
    self.OwnerSub:ShowShipDisplayScene(true)
    self:PlayAnimation("anim_LobbyShipIn", 0, 1, EUMGSequencePlayMode.Forward, 1, function() 
    end)
end

function UILobbyShipOverview:OnBindEvent(EventHelper)
    
end

function UILobbyShipOverview:OnUnload()
    if self.tbTabBarHelper then
        self.tbTabBarHelper:Uninit()
        self.tbTabBarHelper = nil
    end
end

return UILobbyShipOverview