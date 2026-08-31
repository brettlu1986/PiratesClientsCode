local luaclass = require("luaclass")
local PrefabBase = require("PrefabBase")
local UPChestItem = luaclass("UPChestItem", PrefabBase)
local UIUtils = require("UIUtils")
local UISetUtils = require("UISetUtils")
local ClientEventDef = require("ClientEventDef")
local UIToolTipHelper = require("UIToolTipHelper")
local UIResourceDef = require("UIResourceDef")

UPChestItem.tbInstance = nil
UPChestItem.nChestId = nil

local NOOPEN_IMG = "PaperSprite'/Game/UI/Textures/LobbyActivity/Frames/Spr_LobbyActivity69_Normal.Spr_LobbyActivity69_Normal'"
local OPEN_IMG = "PaperSprite'/Game/UI/Textures/LobbyActivity/Frames/Spr_LobbyActivity69_Pressed.Spr_LobbyActivity69_Pressed'"

local function RefreshChest(self)
    local tbData = self.tbInstance:GetData()
    local nKeyCount = self.tbInstance:GetKeyCount()
    local pWidgetRef = self.pWidgetRef
    local bOpened = tbData[self.nChestId] ~= nil
    pWidgetRef.imgNoOpen:SetVisibility(bOpened and ESlateVisibility_Collapsed or ESlateVisibility_SelfHitTestInvisible)
    UISetUtils.SetImageBrushRes(pWidgetRef.imgItem, bOpened and OPEN_IMG:load() or NOOPEN_IMG:load())
    UISetUtils.SetImageBrushColor(pWidgetRef.imgBg, bOpened and UIResourceDef.COLOR.BLACK or UIResourceDef.COLOR.WHITE)
    if not bOpened and nKeyCount > 0 then
        self:PlayAnimation("animGetRewardOn", 0, 0, EUMGSequencePlayMode.Forward, 1)        
    end
end

local function OnRefreshChest(self, tbData, nChestId, bSuccessed)
    if nChestId == nil or  self.nChestId ~= nChestId then
        return
    end
    if not bSuccessed then
        -- 抽宝箱没成功
        return
    end

    self:PlayAnimation("animGetRewardOff", 0, 1, EUMGSequencePlayMode.Forward, 1) 
    RefreshChest(self)
end

local function OnClickedItem(self)
    local tbOpenIds = self.tbInstance:GetData()
    local bOpened = tbOpenIds[self.nChestId] ~= nil
    if bOpened then
        UIUtils.ShowToast(UISetUtils.GetL10NTextByKey("LOBBY_SCHEDULE_CHEST_OPENED"))
        return
    end
    if self.tbInstance:GetKeyCount() <= 0 then
        UIUtils.ShowToast(UISetUtils.GetL10NTextByKey("LOBBY_SCHEDULE_CHEST_NO_KEY"))
        return
    end

    self.tbInstance:RequestOpenBox(self.nChestId)
end

local function OnPressed(self)
    local tbTipData = {
        szTitle = UISetUtils.GetL10NTextByKey("UI_LOBBY_SCHEDULE_CHEST_TIP"),
        szDetail = UISetUtils.GetL10NTextByKey("UI_SCHEDULE_CHEST_TIP")
    }        
    UIToolTipHelper:ShowTipInAutoLayout(UIToolTipHelper.TipType.TEXT_TIP,tbTipData, self.pWidgetRef.btnItem)
end

local function OnReleased(self)
    UIToolTipHelper:HideTip()
end

function UPChestItem:OnBindEvent(EventHelper)
    local btnItem = self.pWidgetRef.btnItem
    EventHelper:RegisterCppDelegate(btnItem.OnClicked, self, OnClickedItem)
    EventHelper:RegisterCppDelegate(btnItem.OnPressed, self, OnPressed)
    EventHelper:RegisterCppDelegate(btnItem.OnReleased, self, OnReleased)
    EventHelper:RegisterEvent(ClientEventDef.EV_SCHEDULE_CHEST_REFRESH, self, OnRefreshChest)
end

function UPChestItem:OnLoad()
end

function UPChestItem:OnDestroy()
end

function UPChestItem:SetInfo(tbInstance, nId)
    self.tbInstance = tbInstance
    self.nChestId = nId
    RefreshChest(self)
end

return UPChestItem