local luaclass = require("luaclass")
local PrefabBase = require("PrefabBase")
local UPCarronadeEffect = luaclass("UPCarronadeEffect", PrefabBase)

local UISetUtils = require("UISetUtils")
local LuaDelegate = require("LuaDelegate")
local CarronadeEffectDef = require("CarronadeEffectDef")

local EFFECT_DEFINE_LIST = {
    [CarronadeEffectDef.BOOM] = {
        szName = "爆炸",
        szNormalRes = "PaperSprite'/Game/UI/FFA/Textures/UI_MainSkill/Frames/Spr_Skill15_Normal.Spr_Skill15_Normal'",
        szPressedRes = "PaperSprite'/Game/UI/FFA/Textures/UI_MainSkill/Frames/Spr_Skill15_Pressed.Spr_Skill15_Pressed'"
    },
    [CarronadeEffectDef.FROZEN] = {
        szName = "冰冻",
        szNormalRes = "PaperSprite'/Game/UI/FFA/Textures/UI_MainSkill/Frames/Spr_Skill16_Normal.Spr_Skill16_Normal'",
        szPressedRes = "PaperSprite'/Game/UI/FFA/Textures/UI_MainSkill/Frames/Spr_Skill16_Pressed.Spr_Skill16_Pressed'"
    },
    [CarronadeEffectDef.FLASH] = {
        szName = "闪光",
        szNormalRes = "PaperSprite'/Game/UI/FFA/Textures/UI_MainSkill/Frames/Spr_Skill18_Normal.Spr_Skill18_Normal'",
        szPressedRes = "PaperSprite'/Game/UI/FFA/Textures/UI_MainSkill/Frames/Spr_Skill18_Pressed.Spr_Skill18_Pressed'"
    },
    [CarronadeEffectDef.SMOKE] = {
        szName = "烟雾",
        szNormalRes = "PaperSprite'/Game/UI/FFA/Textures/UI_MainSkill/Frames/Spr_Skill19_Normal.Spr_Skill19_Normal'",
        szPressedRes = "PaperSprite'/Game/UI/FFA/Textures/UI_MainSkill/Frames/Spr_Skill19_Pressed.Spr_Skill19_Pressed'"
    },
    [CarronadeEffectDef.BURN] = {
        szName = "燃烧",
        szNormalRes = "PaperSprite'/Game/UI/FFA/Textures/UI_MainSkill/Frames/Spr_Skill17_Normal.Spr_Skill17_Normal'",
        szPressedRes = "PaperSprite'/Game/UI/FFA/Textures/UI_MainSkill/Frames/Spr_Skill17_Pressed.Spr_Skill17_Pressed'"
    }
}

UPCarronadeEffect.nEffectType = CarronadeEffectDef.UNKONWN
UPCarronadeEffect.tbEffectInfo = nil
UPCarronadeEffect.OnClickedEffect = nil

local function OnClickedButton(self)
    self.OnClickedEffect:Fire(self.nEffectType)
end

function UPCarronadeEffect:OnCreate()
    self.OnClickedEffect = LuaDelegate()
end

function UPCarronadeEffect:OnBindEvent(EventHelper)
    EventHelper:RegisterCppDelegate(self.pWidgetRef.btnEffect.OnClicked, self, OnClickedButton)
end

function UPCarronadeEffect:SetEffect(nEffectType)
    self.nEffectType = nEffectType
    self.tbEffectInfo = EFFECT_DEFINE_LIST[nEffectType]

    self.pWidgetRef.txtEffect:SetText(self.tbEffectInfo.szName)

    local btnEffect = self.pWidgetRef.btnEffect
    local pNormalRes = self.tbEffectInfo.szNormalRes:load()
    local pPressedRes = self.tbEffectInfo.szPressedRes:load()
    UISetUtils.SetButtonNormalBrushRes(btnEffect, pNormalRes)
    UISetUtils.SetButtonHoveredBrushRes(btnEffect, pNormalRes)
    UISetUtils.SetButtonPressedBrushRes(btnEffect, pPressedRes)
end

function UPCarronadeEffect:SetSelected(bSelected)
    local btnEffect = self.pWidgetRef.btnEffect
    local pRes = nil
    if bSelected then
        pRes = self.tbEffectInfo.szPressedRes:load()
    else
        pRes = self.tbEffectInfo.szNormalRes:load()
    end
    UISetUtils.SetButtonNormalBrushRes(btnEffect, pRes)
    UISetUtils.SetButtonHoveredBrushRes(btnEffect, pRes)
end

return UPCarronadeEffect