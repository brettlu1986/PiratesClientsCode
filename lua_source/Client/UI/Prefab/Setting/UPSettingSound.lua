local luaclass = require("luaclass")
local PrefabBase = require("PrefabBase")
local UPSettingSound = luaclass("UPSettingSound", PrefabBase)
local SettingSystemNew = require("SettingSystemNew")
local SettingClassType = require("SettingClassType")
local UISetUtils = require("UISetUtils")
local SettingKeyDef = require("SettingKeyDef")

local LocalKeys = SettingKeyDef.LocalKeys
local GetL10NTextByKey = UISetUtils.GetL10NTextByKey

local MAX_UP_COUNT = 6

local SOUNDS = {
    {
        szTitle = GetL10NTextByKey("UISETTING_SOUND_ALLSOUND"),
        nKey = LocalKeys.ALL_SOUND,
        bActivate = true
    },
    {
        szTitle = GetL10NTextByKey("UISETTING_SOUND_OTHERSOUND"),
        nKey = LocalKeys.SFX_SOUND,
        bActivate = true
    },
    {
        szTitle = GetL10NTextByKey("UISETTING_SOUND_UISOUND"),
        nKey = LocalKeys.UI_SOUND,
        bActivate = true
    },
    {
        szTitle = GetL10NTextByKey("UISETTING_SOUND_MUSIC"),
        nKey = LocalKeys.MUSIC,
        bActivate = true
    },
    {
        szTitle = GetL10NTextByKey("UISETTING_SOUND_MIC"),
        nKey = LocalKeys.MIC,
        bActivate = true
    },
    {
        szTitle = GetL10NTextByKey("UISETTING_SOUND_HORN"),
        nKey = LocalKeys.HORN,
        bActivate = true
    },
}

UPSettingSound.pbSounds = nil

local function RefreshUI(self)
    for i, v in ipairs(self.pbSounds) do
        v:RefreshUI()
    end
end

function UPSettingSound:OnLoad()
    local pWidgetRef = self.pWidgetRef
    local tbSounds = {}
    for i = 1, MAX_UP_COUNT do
        local pbSound =self.PrefabHelper:BindPrefab(pWidgetRef["pbSound"..i])
        pbSound:InitUI(self, SOUNDS[i])
        table.insert(tbSounds, pbSound)
    end    
    self.pbSounds = tbSounds
end

function UPSettingSound:OnShow()
    RefreshUI(self)
end

function UPSettingSound:OnCreate()
    self.tbInstance = SettingSystemNew:GetInstance(SettingClassType.Setting_Sound)
end

function UPSettingSound:OnDestroy()
    self.tbInstance = nil
end

function UPSettingSound:OnBindEvent(EventHelper)
end

function UPSettingSound:Activate()

end

return UPSettingSound