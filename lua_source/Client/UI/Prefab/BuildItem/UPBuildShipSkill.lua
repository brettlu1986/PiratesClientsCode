local luaclass = require("luaclass")
local PrefabBase = require("PrefabBase")
local UPBuildShipSkill = luaclass("UPBuildShipSkill", PrefabBase)

local SkillDataTable = require("SkillDataTable")
local UISetUtils = require("UISetUtils")

UPBuildShipSkill.nSkillId = nil
UPBuildShipSkill.OnSkillButtonPressedDelegate = nil
UPBuildShipSkill.OnSkillButtonReleasedDelegate = nil

local function OnSkillButtonPressed(self, bChecked)
    if self.OnSkillButtonPressedDelegate then
        self.OnSkillButtonPressedDelegate:Fire(self.nSkillId, self.pWidgetRef.btnSkill)
    end
end

local function OnSkillButtonReleased(self, bChecked)
    if self.OnSkillButtonReleasedDelegate then
        self.OnSkillButtonReleasedDelegate:Fire()
    end
end

function UPBuildShipSkill:SetOnSkillButtonPressedDelegate(OnSkillButtonPressedDelegate)
    self.OnSkillButtonPressedDelegate = OnSkillButtonPressedDelegate
end

function UPBuildShipSkill:SetOnSkillButtonReleasedDelegate(OnSkillButtonReleasedDelegate)
    self.OnSkillButtonReleasedDelegate = OnSkillButtonReleasedDelegate
end

function UPBuildShipSkill:OnLoad()

end

function UPBuildShipSkill:OnBindEvent(EventHelper)
    local btnSkill = self.pWidgetRef.btnSkill
    EventHelper:RegisterCppDelegate(btnSkill.OnPressed, self, OnSkillButtonPressed)
    EventHelper:RegisterCppDelegate(btnSkill.OnReleased, self, OnSkillButtonReleased)
end

function UPBuildShipSkill:Collapsed()
    self.pWidgetRef:SetVisibility(ESlateVisibility.Collapsed)
end

function UPBuildShipSkill:Refresh(nSkillId)
    local pWidgetRef = self.pWidgetRef
    local tbSkillResTemplate = SkillDataTable:GetResTemplate(nSkillId)
    local iconRes = tbSkillResTemplate.szDisplayIconRes
    if iconRes and tbSkillResTemplate.bDisplay then
        UISetUtils.SetButtonBrushRes(pWidgetRef.btnSkill, iconRes:load())
        local bgRes = tbSkillResTemplate.szDisplayBgRes
        if bgRes then
            UISetUtils.SetBorderBrushRes(pWidgetRef.bdrBg, bgRes:load())
        end
    else
        self:Collapsed()
        return
    end

    self.nSkillId = nSkillId
    pWidgetRef.txtSkillName:SetText(tbSkillResTemplate.l10nName)
    pWidgetRef:SetVisibility(ESlateVisibility.Visible)
end

function UPBuildShipSkill:ShowSkillName()
    self.pWidgetRef.txtSkillName:SetVisibility(ESlateVisibility.HitTestInvisible)
end

return UPBuildShipSkill