-----------
--  收集掉落物相关资源
-----------
local BattleItemDataTable = require("BattleItemDataTable")
local AnimationResDataTableNew = require("AnimationResDataTableNew")
local UIResourceDef = require("UIResourceDef")
local HumanWeaponHelper = require("HumanWeaponHelper")
local PrefabDataTable = require("PrefabDataTable")

local BattleTemplateActorResourceCollector = {}

local FIELD_NAMES = {
    "szIconPath", 
    "szEquipClassName", 
    "szSilhouettePath", 
    "szEquipmentDisplayPath",
}

local function CollectionItemRes(nTemplateId, tbDatas)
    local tbItemResData = BattleItemDataTable:GetResTemplate(nTemplateId)
    if tbItemResData == nil then
        return
    end
    for i, v in ipairs(FIELD_NAMES) do
        local szPath = tbItemResData[v]
        if szPath ~= nil and string.len(szPath) > 0 then
            table.insert(tbDatas, szPath)
        end 
    end
end

local function CollectionItemAnimation(tbGameObject, nTemplateId, tbDatas)
    if tbGameObject:IsHuman() then
        local nHumanId = tbGameObject.nDungeonHumanId 
        local fnAppendRes = function(tbRes)
            if tbRes ~= nil then
                for i, v in ipairs(tbRes) do
                    table.insert(tbDatas, v)
                end  
            end
        end
        fnAppendRes(AnimationResDataTableNew:GetWeaponRes(nHumanId, nTemplateId))
        local nCategory = HumanWeaponHelper.GetWeaponCategory(nTemplateId)
        if nCategory ~= nil then
            fnAppendRes(AnimationResDataTableNew:GetWeaponCategoryRes(nHumanId, nCategory))
        end
    end
end

local function CollectionItemUIRes(nTemplateId, tbDatas)
    local tbItemTemplate = BattleItemDataTable:GetTemplate(nTemplateId)
    if not tbItemTemplate then
        return
    end
    local szIcon = UIResourceDef.ITEM_COLOR_GRADE_ICON[tbItemTemplate.nColorGrade]
    if szIcon then
        table.insert(tbDatas, szIcon)
    end
    local nGrade = tbItemTemplate.nGrade
    szIcon = UIResourceDef.ITEM_GRADE_ICON[tbItemTemplate.nGrade]
    if szIcon then
        table.insert(tbDatas, szIcon)
    end
    szIcon = UIResourceDef.HUMAN_WEAPON_GRADE_ICON[nGrade]
    if szIcon then
        table.insert(tbDatas, szIcon)
    end
    local szSightRes = tbItemTemplate.szSightRes
    if szSightRes and szSightRes ~= "" then
        local tbPrefabTemplate = PrefabDataTable:GetTemplate(szSightRes)
        if tbPrefabTemplate then
            table.insert(tbDatas, tbPrefabTemplate.szUIPath)
        end
        
    end
end

-- 收集相关资源
-- tbGameObject: 一般情况下是GamePlayerSelf, 观战情况下是被观战的玩家
-- nTemplateId : 物品的TemplateId
-- tbDatas     : 返回 收集到的资源名
function BattleTemplateActorResourceCollector.CollectAll(tbGameObject, nTemplateId, tbDatas)
    -- 收集item_res表中相关资源
    CollectionItemRes(nTemplateId, tbDatas)
    -- 收集animation_res表中的物品相关动作
    CollectionItemAnimation(tbGameObject, nTemplateId, tbDatas)
    -- 收集item相关的ui图标资源
    CollectionItemUIRes(nTemplateId, tbDatas)
end

return BattleTemplateActorResourceCollector