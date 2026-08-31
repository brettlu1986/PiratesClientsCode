-----------------------------------------------------
--File Name    : GuideTrigger.lua
--Description  : 指引触发
-----------------------------------------------------
local luaclass                      = require("luaclass")
local GuideActionSelectWidget       = require("GuideActionSelectWidget")
local GuideActionChangeWeapon       = luaclass("GuideActionChangeWeapon", GuideActionSelectWidget)

local GamePlayerSelfHelper          = require("GamePlayerSelfHelper")
local BattleItemSystemHelper        = require("BattleItemSystemHelper")
local BattleItemCategoryDef         = require("BattleItemCategoryDef")
local UIManager                     = require("UIManager")
local UIDef                         = require("UIDef")
local GuideSystem                   = require("GuideSystem")
-----------------------------------------------------
GuideActionChangeWeapon.szCurrentSlotName = ""
-----------------------------------------------------
function GuideActionChangeWeapon:GetSelectWidgets()
    self:DebugLog("GuideActionChangeWeapon:GetSelectWidgets")
    local Widget = nil
    local tbTemp = {}
    local PlayerSelf = GamePlayerSelfHelper:Get()
    local Wnd = UIManager:GetWnd(UIDef.UI_FFA_MAIN)
    if not Wnd then
        self:LogError("GuideActionChangeWeapon 1")
        return tbTemp
    end
    local WeaponComponent = PlayerSelf.HumanWeaponComponent
    if not WeaponComponent then
        self:LogError("GuideActionChangeWeapon 2")
        return tbTemp
    end
    local nInstanceId = PlayerSelf:GetServerInstanceId()
    local tbEquipItems = BattleItemSystemHelper:GetEquippedItems(nInstanceId, BattleItemCategoryDef.HUMAN_WEAPON, nInstanceId, true)
    if not tbEquipItems then
        self:LogError("GuideActionChangeWeapon 3")
        return tbTemp
    end
    local nEquipItemCount = 0
    for k,v in pairs(tbEquipItems) do
        nEquipItemCount = nEquipItemCount + 1
    end
    local pOwner = self.Owner
    local nStep = pOwner.tbTemplate.nStep
    local tbCurrentWeapon = WeaponComponent:GetCurrentWeapon()
    if not tbCurrentWeapon then
        if nEquipItemCount ~= 0 then
            --装备武器引导
            local nIndex = 4
            for k, v in pairs(tbEquipItems) do                
                nIndex = nIndex >= k and k or nIndex
            end
            self:DebugLog("GuideActionChangeWeapon  nIndex = " .. tostring(nIndex))
            Widget = Wnd.pWidgetRef.pbFFAHuman["pbFFAHumanSub" .. nIndex].btnBlueprintItem
            self.szCurrentSlotName = "pbFFAHumanSub" .. nIndex
            --skip next step
            pOwner.Owner:SkipStep(nStep + 2)
        end
    else
        pOwner.Owner:SkipStep(nStep + 1)
        return "skip"
    end
    table.insert(tbTemp, Widget)
    return tbTemp
end

function GuideActionChangeWeapon:GetParentScale(tbTemplate)
    local tbScaleParent = tbTemplate.tbScaleParent
    local eLayoutType = 0
    local szScaleParentName = ""
    if tbScaleParent then
        eLayoutType = tonumber(tbScaleParent[1])
        szScaleParentName = self.szCurrentSlotName
    end
    local Scale = GuideSystem:GetLayoutScale(eLayoutType, szScaleParentName) --RenderTransform.Scale
    return Scale
end

--override
function GuideActionChangeWeapon:Begin()
    GuideActionChangeWeapon.super.Begin(self)
end
return GuideActionChangeWeapon
