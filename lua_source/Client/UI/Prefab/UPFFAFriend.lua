local luaclass = require ("luaclass")
local PrefabBase = require("PrefabBase")
local UPFFAFriend = luaclass("UPFFAFriend", PrefabBase)
local UISetUtils = require("UISetUtils")
local Timer = require("Timer")
local GameObjectTypeDef = require("GameObjectTypeDef")
local GameObjectSystem = dynamic_require("GameObjectSystem")
local FriendIni = require("FriendIni")
local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
local SelfVerticalListHelper = require("SelfVerticalListHelper")
local ClientEventDef = require("ClientEventDef")
local FriendSystem = require("FriendSystem")
local GlobalVariableSystem_C = require("GlobalVariableSystem_C")
local BattleGameModeSystem = dynamic_require("BattleGameModeSystem")

UPFFAFriend.tbListHelper = nil
UPFFAFriend.bVisible  = nil
UPFFAFriend.tbPlayers = nil
UPFFAFriend.tbApplys  = nil
UPFFAFriend.tbTimer   = nil
UPFFAFriend.nCurTab   = nil
UPFFAFriend.nTime     = nil

local IMG_CLOSE = "PaperSprite'/Game/UI/FFA/Textures/UI_FFAMain/Frames/Spr_Talk17.Spr_Talk17'"
local IMG_OPEN = "PaperSprite'/Game/UI/Textures/LobbyMain/Frames/Spr_LobbyMain012.Spr_LobbyMain012'"
local INTERVAL = 2
local DEFAULTTAB = 1
local MAXTAB = 2
local ICON_SIZE = 60
local CHECKED, UNCHECKED = ECheckBoxState.Checked, ECheckBoxState.Unchecked

local function SetCurTab(self, nIndex)
    local pWidgetRef = self.pWidgetRef
    self.nCurTab = nIndex
    for i = 1, MAXTAB do
        pWidgetRef["cbTab"..i]:SetCheckedState(nIndex == i and CHECKED or UNCHECKED)
    end

    if self.nCurTab == DEFAULTTAB then
        self.tbListHelper:SetData(self.tbPlayers)
    else
        FriendSystem:WatchApplyInfo(self.nTime)
        self.tbListHelper:SetData(self.tbApplys or {})
    end
end

local function IsInRange(self, nX1, nY1, nX2, nY2, nRequireSquareDis)
    local nX, nY = nX1 - nX2, nY1 - nY2
    local nSquareDis = nX * nX + nY * nY 
    return nSquareDis, nSquareDis <= nRequireSquareDis    
end

local function NotInApplysAndNotInFriends(self, nId)
    -- local Component = FriendSystem:GetComponent()
    -- if Component:GetFriend(nId) then
    --     return false
    -- end
    -- if Component:GetApplyFriend(nId) then
    --     return false
    -- end

    return true
end

local function RefreshPlayers(self)
    local PlayerSelf = GamePlayerSelfHelper:Get()
    local nX, nY = PlayerSelf:GetLocationXYZ()
    local nDistance = FriendIni.tbFFA.nHumanNearDistance
    if PlayerSelf:IsShip() then
        nDistance = FriendIni.tbFFA.nShipNearDistance
    end
    local nRequireSquareDis = nDistance * nDistance
    local nSquareDis = 0
    local nX1, nY1 
    local bInRange = false

    self.tbPlayers = {}
    local tbAllObjs = GameObjectSystem:GetAllByObjectType(GameObjectTypeDef.PlayerOther)
    
    local tbGameState = BattleGameModeSystem:GetGameState()
    local tbPlayerInfos = tbGameState.rTrainingCampPlayerInfos:Get()
    tbPlayerInfos = tbPlayerInfos.PlayerInfos

    local fnGetPlayerInfo = function(nInstanceId)
        if tbPlayerInfos ~= nil then
            for i, v in ipairs(tbPlayerInfos) do
                if v.nInstanceId == nInstanceId then
                    return v
                end
            end
        end
    end

    for v, _ in pairs(tbAllObjs) do
        if NotInApplysAndNotInFriends(self, v.nPlayerId) then
            nX1, nY1 = v:GetLocationXYZ()
            nSquareDis, bInRange = IsInRange(self, nX1, nY1, nX, nY, nRequireSquareDis)
            if bInRange then
                table.insert(self.tbPlayers, {nId = v.nPlayerId, nSquareDis = nSquareDis, tbPlayerInfo = fnGetPlayerInfo(v.nServerInstanceId)})
            end
        end
    end

    local fnSort = function(a, b)
        if a.nSquareDis < b.nSquareDis then
            return true
        elseif a.nSquareDis > b.nSquareDis then
            return false
        else
            return a.nId < b.nId
        end
    end
    table.sort(self.tbPlayers, fnSort)

    if self.nCurTab == DEFAULTTAB then
        SetCurTab(self, self.nCurTab)
    end
end 

local function DestroyTimer(self)
    if self.tbTimer ~= nil then
        self.tbTimer:Clear()
        self.tbTimer = nil
    end
end

local function OnRefreshApplyFriendList(self)
    local Component = FriendSystem:GetComponent()
    local tbDatas = Component:GetDungeonApplyFriends(self.nTime)
    self.Owner.pWidgetRef.btnFriend:HideTipIcon(#tbDatas <= 0)
    self.pWidgetRef.cbTab2:HideTipIcon(#tbDatas <= 0)

    if not self.bVisible then
        return
    end 
    self.tbApplys = tbDatas
    if self.nCurTab ~= DEFAULTTAB then
        SetCurTab(self, self.nCurTab)
    end
end

local function OnClickedTab(self, nIndex)
    SetCurTab(self, nIndex)
end

function UPFFAFriend:OnLoad()
    self.tbListHelper:Init(self, self.pWidgetRef.vlistPlayer)
    self.bVisible = false
end

function UPFFAFriend:OnBindEvent(EventHelper)
    EventHelper:RegisterEvent(ClientEventDef.EV_ON_REFRESH_APPLY_FRIENDS, self, OnRefreshApplyFriendList)
    
    local pWidgetRef = self.pWidgetRef
    for i = 1, MAXTAB do
        EventHelper:RegisterCppDelegate(pWidgetRef["cbTab"..i].OnCheckStateChanged,  self, function(_, bActivate)
            OnClickedTab(self, i)
        end)
    end    
end

function UPFFAFriend:OnCreate()
    self.nTime = GlobalVariableSystem_C.nEnterDungeonTime or 0
    self.tbListHelper = SelfVerticalListHelper()
end

function UPFFAFriend:OnDestroy()
    self.tbPlayers = nil
    self.tbApplys = nil
    DestroyTimer(self)
    self.tbListHelper:Uninit()
    self.tbListHelper = nil
end

function UPFFAFriend:Activate()
    local pWidgetRef = self.pWidgetRef
    pWidgetRef:SetVisibility(ESlateVisibility_SelfHitTestInvisible)
    UISetUtils.SetButtonBrushRes(self.Owner.pWidgetRef.btnFriend, IMG_CLOSE:load(), false, true, ICON_SIZE, ICON_SIZE)

    self.tbTimer = Timer.NewTimer(function()
        RefreshPlayers(self) 
    end, INTERVAL, true)
    RefreshPlayers(self)
    OnRefreshApplyFriendList(self)
    SetCurTab(self, DEFAULTTAB)
end

function UPFFAFriend:Deactivate()
    DestroyTimer(self)
    self.pWidgetRef:SetVisibility(ESlateVisibility_Collapsed)
    UISetUtils.SetButtonBrushRes(self.Owner.pWidgetRef.btnFriend, IMG_OPEN:load(), false, true, ICON_SIZE, ICON_SIZE)
end

function UPFFAFriend:ToggleActivate()
    self.bVisible = not self.bVisible
    if not self.bVisible then
        self:Deactivate()
    else
        self:Activate()
    end
end

return UPFFAFriend
