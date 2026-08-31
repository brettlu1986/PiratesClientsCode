-----------------------------------------------------
--File Name    : GuideTrigger.lua
--Description  : 指引触发
-----------------------------------------------------
local luaclass                      = require("luaclass")
local GuideActionSelectWidget       = require("GuideActionSelectWidget")
local GuideActionSelectWeapon       = luaclass("GuideActionSelectWeapon", GuideActionSelectWidget)

local GamePlayerSelfHelper          = require("GamePlayerSelfHelper")
local BattleItemSystemHelper        = require("BattleItemSystemHelper")
local BattleItemCategoryDef         = require("BattleItemCategoryDef")
local UIManager                     = require("UIManager")
local UIDef                         = require("UIDef")
local GuideSystem                   = require("GuideSystem")
-----------------------------------------------------
GuideActionSelectWeapon.szCurrentSlotName = ""
-----------------------------------------------------
function GuideActionSelectWeapon:GetSelectWidgets()
    self:DebugLog(" GuideActionSelectWeapon:GetSelectWidgets")
    local Widget = nil
    local tbTemp = {}
    local Wnd = UIManager:GetWnd(UIDef.UI_FFA_MAIN)
    if not Wnd then
        self:LogError(" GuideActionSelectWeapon 1")
        return tbTemp
    end
    local WeaponComponent = GamePlayerSelfHelper:Get().HumanWeaponComponent
    if not WeaponComponent then
        self:LogError(" GuideActionSelectWeapon 2")
        return tbTemp
    end
    local tbCurrentWeapon = WeaponComponent:GetCurrentWeapon()
    local tbParam = self.tbTemplate.tbParam
    if not tbParam or tbParam[1] == "equipt" then
        if not tbCurrentWeapon then
            self:LogError(" GuideActionSelectWeapon 3")
            return tbTemp
        end
        local nCurrentWeaponSlot = tbCurrentWeapon.nSlot
        self:DebugLog(" GuideActionSelectWeapon:GetSelectWidgets CurrentWeaponSlot = " .. tostring(nCurrentWeaponSlot))
        if Wnd.pWidgetRef and Wnd.pWidgetRef.pbFFAHuman["pbFFAHumanSub" .. nCurrentWeaponSlot] then
            Widget = Wnd.pWidgetRef.pbFFAHuman["pbFFAHumanSub" .. nCurrentWeaponSlot].btnBlueprintItem
            self.szCurrentSlotName = "pbFFAHumanSub" .. nCurrentWeaponSlot
            self:DebugLog(" Widget = " .. tostring(Widget))
        end
    else
        local PlayerSelf = GamePlayerSelfHelper:Get()
        local nInstanceId = PlayerSelf:GetServerInstanceId()
        local tbEquipItems = BattleItemSystemHelper:GetEquippedItems(nInstanceId, BattleItemCategoryDef.HUMAN_WEAPON, nInstanceId, true)
        local nIndex = 4
        for k, v in pairs(tbEquipItems) do
            --local nSlot = v.tbStorageLocation.nSlotIndex
            if not v:IsCurrentWeapon() then
            --if nCurrentWeaponSlot ~= nSlot then
                nIndex = nIndex >= k and k or nIndex
            end
        end
        if Wnd.pWidgetRef and Wnd.pWidgetRef.pbFFAHuman["pbFFAHumanSub" .. nIndex] then
            Widget = Wnd.pWidgetRef.pbFFAHuman["pbFFAHumanSub" .. nIndex].btnBlueprintItem
            self.szCurrentSlotName = "pbFFAHumanSub" .. nIndex
        end
    end
    table.insert(tbTemp, Widget)
    return tbTemp
end

function GuideActionSelectWeapon:GetParentScale(tbTemplate)
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

return GuideActionSelectWeapon
