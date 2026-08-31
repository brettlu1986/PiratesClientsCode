-----------------------------------------------------
--File Name    : ULLobbyButton.lua
--Author       : Ranjie
--Create Time  : 2020-4-20
--Description  : ULLobbyButton
-----------------------------------------------------
local luaclass = require("luaclass")
local UILogicBase = require("UILogicBase")
local ULLobbyButton = luaclass("ULLobbyButton", UILogicBase)


local MailSystem = require("MailSystem")
local ClientEventDef = require("ClientEventDef")
local UIManager = require("UIManager")
local UIDef = require("UIDef")
local ShopSystem = require("ShopSystem")
local FriendSystem = require("FriendSystem")
local Proto = require("ClientProtoNames")
--local IAPSystem = require("IAPSystem")
local UIToolTipHelper = require("UIToolTipHelper")
local ItemBuffHelper = require("ItemBuffHelper")


--Mail
local function SetRedDotVisible(self, bVisible)
    self.pWidgetRef.btnMail:HideTipIcon(not bVisible)
    -- if bVisible then
    --     if not self.Owner:IsAnimationPlaying("animNewMail") then
    --         self.Owner:PlayAnimation("animNewMail", 0, 0, EUMGSequencePlayMode.Forward, 1)
    --     end
    -- else
    --     self.Owner:StopAnimation("animNewMail")
    -- end
end

local function OnNewMailNotified(self)
    SetRedDotVisible(self, MailSystem:HasUnreadMail())
end


local function OnMailSynced(self)
    SetRedDotVisible(self, MailSystem:HasUnreadMail())
end

local function OnMailRead(self)
    SetRedDotVisible(self, MailSystem:HasUnreadMail())
end

local function OnMailAttachmentGet(self)
    SetRedDotVisible(self, MailSystem:HasUnreadMail())
end

local function SyncMails()
    if not MailSystem:HasSynced() then
        MailSystem:RequestToSyncMails()
    end
end

local function OnClickMail()
    UIManager:OpenWnd(UIDef.UI_MAIL)
end

--Friend
local function OnRefreshFriendApplyCount(self)
    local Component = FriendSystem:GetComponent()
    local bShowTipIcon = false
    if Component ~= nil then
        bShowTipIcon = Component:HadApplies() or Component:HasRedDotRelation() == true
        self.pWidgetRef.btnFriend:HideTipIcon(not bShowTipIcon)
    else
        self.pWidgetRef.btnFriend:HideTipIcon(true)
    end
    -- if bShowTipIcon then
    --     if not self.Owner:IsAnimationPlaying("animNewFriend") then
    --         self.Owner:PlayAnimation("animNewFriend", 0, 0, EUMGSequencePlayMode.Forward, 1)
    --     end
    -- else
    --     self.Owner:StopAnimation("animNewFriend")
    -- end
end

local function RefreshFriendsOnline(self)
    local FriendComponent = FriendSystem:GetComponent()
    local tbFriendSummaries = FriendComponent:GetFriendSummaries()
    local nOnlineCount = 0
    for k, v in ipairs(tbFriendSummaries) do
        if v.status ~= Proto.PlayerStatus.OFFLINE then
            nOnlineCount = nOnlineCount + 1
        end
    end
    self.pWidgetRef.txtInviteFriend:SetText(nOnlineCount)
end

local function OnClickFriend(self)
    UIManager:OpenWnd(UIDef.UI_LOBBY_FRIEND)
end

--Team
local function OnInvitedClicked(self)
    UIManager:OpenWnd(UIDef.UI_LOBBY_TEAM_LIST)
end

local function SetSomeVisible(self, bVisible)
    --local pVisiblity = bVisible and ESlateVisibility_SelfHitTestInvisible or ESlateVisibility_Collapsed
    --local pWidgetRef = self.pWidgetRef
    -- pWidgetRef.blurMatchmaking:SetVisibility(pVisiblity)
    -- pWidgetRef.hbxFirstBattleBg:SetVisibility(pVisiblity)
    -- pWidgetRef.btnFirstBattle:SetVisibility(pVisiblity)
    --pWidgetRef.ovlStartEffect:SetVisibility(pVisiblity)
end

local function OnPreOpenUI(self, szWndName)
    if szWndName == UIDef.UI_LOBBY_TEAM_LIST then
        SetSomeVisible(self, false)
    end
end

local function OnPreCloseUI(self, szWndName)
    if szWndName == UIDef.UI_LOBBY_TEAM_LIST then
        SetSomeVisible(self, true)
    end
end
--Shop
local function OnClickShopButton(self)
    ShopSystem:OpenShop()
end

--Setting
local function OnClickSet(self)
    UIManager:OpenWnd(UIDef.UI_SETTING)
end

--First Prize
-- local function OnRefreshFirstPrize(self)
--     local btnFirstPrize = self.pWidgetRef.btnFirstPrize
--     if not IAPSystem:IsIAPEnabled() then
--         btnFirstPrize:SetVisibility(ESlateVisibility.Collapsed)
--         return
--     end 
    
--     local tbState = Proto.FirstPurchaseState
--     local nState = IAPSystem:GetFirstPurchaseState()
--     if nState == tbState.NONE then
--         btnFirstPrize:HideTipIcon(true)
--         btnFirstPrize:SetVisibility(ESlateVisibility.Visible)
--     elseif nState == tbState.DEBT then
--         btnFirstPrize:HideTipIcon(false)
--         btnFirstPrize:SetVisibility(ESlateVisibility.Visible)
--     else
--         btnFirstPrize:SetVisibility(ESlateVisibility.Collapsed)
--     end
-- end

-- local function OnClickedFirstPrize(self)
--     UIManager:OpenWnd(UIDef.UI_FIRST_PRIZE)
-- end


--Item Buff
local function OnRefreshItemBuffBtnVisible(self)
    local bHasBuff = ItemBuffHelper.HasValidBuffs() 
    self.pWidgetRef.btnBuff:SetVisibility(bHasBuff and ESlateVisibility.Visible or ESlateVisibility.Collapsed)
end

local function OnBuffPressed(self)
    local tbBuffs = ItemBuffHelper.GetItemBuffs() 
    UIToolTipHelper:ShowCustomTipInAutoLayout(UIDef.UP_TWO_EXP,tbBuffs,self.pWidgetRef.btnBuff)
end

local function OnBuffReleased(self)
    UIToolTipHelper:HideTip()
end

function ULLobbyButton:OnBindEvent(EventHelper)
    local pWidgetRef = self.pWidgetRef
    --Email
    EventHelper:RegisterCppDelegate(pWidgetRef.btnMail.OnClicked, self, OnClickMail)
    EventHelper:RegisterEvent(ClientEventDef.EV_NEW_MAIL_NOTIFY_RECEIVED, self, OnNewMailNotified)
    EventHelper:RegisterEvent(ClientEventDef.EV_ALL_MAILS_RECEIVED, self, OnMailSynced)
    EventHelper:RegisterEvent(ClientEventDef.EV_MARK_MAIL_READ_RECEIVED, self, OnMailRead)
    EventHelper:RegisterEvent(ClientEventDef.EV_MAIL_ATTACHMENT_GOT_RECEIVED, self, OnMailAttachmentGet)

    --Friend
    EventHelper:RegisterCppDelegate(pWidgetRef.btnFriend.OnClicked, self, OnClickFriend)
    EventHelper:RegisterEvent(ClientEventDef.EV_ON_REFRESH_APPLY_FRIENDS, self, OnRefreshFriendApplyCount)
    EventHelper:RegisterEvent(ClientEventDef.EV_RELATION_NOT_PROCESS_REDDOT, self, OnRefreshFriendApplyCount)
    
    EventHelper:RegisterEvent(ClientEventDef.EV_ON_REFRESH_FRIENDS, self, RefreshFriendsOnline)

    --Team
    EventHelper:RegisterCppDelegate(self.pWidgetRef.btnInvite.OnClicked, self, OnInvitedClicked)
    EventHelper:RegisterEvent(ClientEventDef.EV_PRE_OPEN_UI, self, OnPreOpenUI)
    EventHelper:RegisterEvent(ClientEventDef.EV_PRE_CLOSE_UI, self, OnPreCloseUI)

    --Shop
    EventHelper:RegisterCppDelegate(pWidgetRef.btnShop.OnClicked, self, OnClickShopButton)

    --Setting
    EventHelper:RegisterCppDelegate(pWidgetRef.btnSet.OnClicked, self, OnClickSet)

    --First Prize
    -- EventHelper:RegisterCppDelegate(pWidgetRef.btnFirstPrize.OnClicked, self, OnClickedFirstPrize)
    -- EventHelper:RegisterEvent(ClientEventDef.EV_ON_FRESH_FIRST_PURCHASE, self, OnRefreshFirstPrize)

    --First Battle
    -- EventHelper:RegisterCppDelegate(pWidgetRef.btnFirstBattle.OnPressed, self, OnFirstBattlePressed)
    -- EventHelper:RegisterCppDelegate(pWidgetRef.btnFirstBattle.OnReleased, self, OnFirstBattleReleased)
    -- EventHelper:RegisterCppDelegate(pWidgetRef.txtFirstBattleTime.OnCountDownFinished, self, OnFirstBattleCDFinished)
    -- EventHelper:RegisterEvent(ClientEventDef.EV_FIRST_BATTLE_REFRESH_TIME, self, RefreshFirstBattleTime)

    --Item Buff
    EventHelper:RegisterCppDelegate(pWidgetRef.btnBuff.OnPressed, self, OnBuffPressed)
    EventHelper:RegisterCppDelegate(pWidgetRef.btnBuff.OnReleased, self, OnBuffReleased)
    EventHelper:RegisterEvent(ClientEventDef.EV_ITEM_BUFF_BTN_VISIBLE, self, OnRefreshItemBuffBtnVisible)
    EventHelper:RegisterEvent(ClientEventDef.EV_REFRESH_ITEM_BUFFS, self, OnRefreshItemBuffBtnVisible)
end

function ULLobbyButton:OnShow()
    if MailSystem:HasSynced() then
        SetRedDotVisible(self, MailSystem:HasUnreadMail())
    else
        SyncMails() -- 暂时不加延时，测试服务端的问题
        -- Timer.StartOwnerTimer(self, "SyncMailTimer", SyncMails, 2, false)
    end
    OnRefreshFriendApplyCount(self)
    --RefreshFirstBattleTime(self)
    OnRefreshItemBuffBtnVisible(self)
    RefreshFriendsOnline(self)
    SetSomeVisible(self, true)
end

return ULLobbyButton