local luaclass = require("luaclass")
local WndBase = require("WndBase")
local UILobbyFriendLevelup = luaclass("UILobbyFriendLevelup", WndBase)
local FriendRelationShipLevelDataTable = require("FriendRelationShipLevelDataTable")
local UISetUtils = require("UISetUtils")
local UIResourceDef = require("UIResourceDef")
local FriendSystem = require("FriendSystem")
local Timer = require("Timer")

local szAnimLoop = "animLobbyFriendLevelUpLoop"
local szRelationAnim = "animLobbyFriendLevelUpIn_0%s"
local LOOP_TIMER = "AnimLoopTimer"
local nLoopTime = 1.5

function UILobbyFriendLevelup:OnLoad()
    
end

function UILobbyFriendLevelup:OnShow()
    local tbRelationChangeInfo = self.tbOpenArgs.tbRelationChangeInfo

    local nRelationType = tbRelationChangeInfo.relationship.relationship_id
    local nRelationLevel = tbRelationChangeInfo.relationship.relationship_level

    local tbRelationLevelData = FriendRelationShipLevelDataTable:GetDataTemplate(nRelationType, nRelationLevel) 
    self.pWidgetRef.txtRelationLv:SetText(tbRelationLevelData.nLevel)
    self.pWidgetRef.txtRelationName:SetText(tbRelationLevelData.l10nName)
    self.pWidgetRef.txtRelationName:SetColorAndOpacity(UIResourceDef.FRIEND_RELATION_TXT_COLOR[nRelationType])
    UISetUtils.SetBorderBrushRes(self.pWidgetRef.bdrRelation, UIResourceDef.FRIEND_RELATION_IMG[nRelationType]:load())
    local nPlayerId = tbRelationChangeInfo.player_id
    local FriendComponent = FriendSystem:GetComponent()
    local tbFriendInfo = FriendComponent:GetFriend(nPlayerId)
    
    self.pWidgetRef.txtName:SetText(tbFriendInfo.player_summary.name)
    FriendSystem:ClearCacheMatchLevelUp()
    
    local szAnim = string.format(szRelationAnim, nRelationType)
    self:PlayAnimation(szAnim, 0, 1, EUMGSequencePlayMode.Forward, 1)
    Timer.StartOwnerTimer(self, LOOP_TIMER, function() 
        self:PlayAnimation(szAnimLoop, 0, 0, EUMGSequencePlayMode.Forward, 1)
    end, nLoopTime, false)
end

function UILobbyFriendLevelup:OnUnload()
    Timer.StopOwnerTimer(self, LOOP_TIMER)
end

function UILobbyFriendLevelup:OnBindEvent(EventHelper)
    EventHelper:RegisterCppDelegate(self.pWidgetRef.btnConfirm.OnClicked, self, function()
        self:CloseSelf()
    end)
end

return UILobbyFriendLevelup
