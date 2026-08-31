local luaclass = require("luaclass")

local LobbyCaptainDataPicker = luaclass("LobbyCaptainDataPicker")

local SelfVerticalListHelper = require("SelfVerticalListHelper")
local UIDef = require("UIDef")

LobbyCaptainDataPicker.tbOwner = nil
LobbyCaptainDataPicker.TitleCheckboxDelegate = nil
LobbyCaptainDataPicker.SelfVerticalListHelper = nil
LobbyCaptainDataPicker.tbDatas = nil
LobbyCaptainDataPicker.tbTitleInfo = nil


local function GetOwnerPrefab(self)
    return self.tbOwner
end

local function GetPrefabWidget(self)
    local tbOwner = GetOwnerPrefab(self)
    assert(tbOwner)
    return tbOwner.pWidgetRef
end

function LobbyCaptainDataPicker:Activate()
    local pWidgetRef = GetPrefabWidget(self)
    
    if not self.SelfVerticalListHelper then
        self.SelfVerticalListHelper = SelfVerticalListHelper()
        local tbOwner = GetOwnerPrefab(self)
        local cellPrefabName = self:GetPickerCellItemScript()
        self.SelfVerticalListHelper:Init(tbOwner, pWidgetRef.kmvlistContent, {}, cellPrefabName)
    end
    
    -- self:BindEventOnActivate(EventHelper)
    -- pWidgetRef.chboxTip:SetIsChecked(false)
    -- HideTip(self)
end

function LobbyCaptainDataPicker:Deactivate()
    -- local EventHelper = GetEventHelper(self)
    -- self:UnBindEventOnDeactivate(EventHelper)
    if self.SelfVerticalListHelper then
        self.SelfVerticalListHelper:SetEnable(false)
        self.SelfVerticalListHelper:Uninit()
        self.SelfVerticalListHelper = nil
    end
end

function LobbyCaptainDataPicker:GetPickerCellItemScript()
    return UIDef.UP_LOBBY_CAPTAIN_PICKER_ITEM
end

function LobbyCaptainDataPicker:SetOwnerPrefab(tbOwner)
    self.tbOwner = tbOwner
end

function LobbyCaptainDataPicker:SetDatas(tbDatas)
    self.tbDatas = tbDatas
    self.SelfVerticalListHelper:SetData(tbDatas, true)
end


function LobbyCaptainDataPicker:SetSelectedIndexState(nIndex)
    self.SelfVerticalListHelper:SetSelectedIndexState(nIndex)
end

function LobbyCaptainDataPicker:SetSelectedIndex(nIndex)
    self.SelfVerticalListHelper:SetSelectedIndex(nIndex)
end




return LobbyCaptainDataPicker