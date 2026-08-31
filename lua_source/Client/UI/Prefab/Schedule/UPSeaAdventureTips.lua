-----------------------------------------------------
--File Name    : UPSeaAdventureTips.lua
-----------------------------------------------------
local luaclass = require("luaclass")
local PrefabBase = require("PrefabBase")
local UPSeaAdventureTips = luaclass("UPSeaAdventureTips", PrefabBase)

local L10N = require("L10N")
local UISetUtils = require("UISetUtils")
local SeaAdventureHelper = require("SeaAdventureHelper")

local function FillInfo(self)
    local tbInstance = self.Owner.tbInstance
    local tbTemplate = tbInstance:GetTemplate()
    if tbTemplate and tbTemplate.tbScheduleData then 
        local pWidgetRef = self.pWidgetRef
        local szTitle = L10N:Format(UISetUtils.GetL10NTextByKey("UI_SEAADVENTURE_DAY_TITLE"), tbTemplate.tbScheduleData.nDiceMaxDay, tbTemplate.tbScheduleData.nResetTime)
        pWidgetRef.txtTitle:SetText(szTitle)

        local tbTasks = tbTemplate.tbTask
        
        local tbSubTask = nil 
        for _, v in pairs(tbTasks) do  
            if v.nId == SeaAdventureHelper.ROLL_SUB_TASK_ID and v.nType ==  SeaAdventureHelper.ROLL_TASK_TYPE then 
                tbSubTask = v
                break
            end
        end

        for _, v in pairs(tbTasks) do 
            if v.nType ==  SeaAdventureHelper.ROLL_TASK_TYPE then 
                for _, v1 in pairs(SeaAdventureHelper.ROLL_TASK_ID) do  
                    if v.nId == v1 and pWidgetRef["txtMission"..v1] then  
                        pWidgetRef["txtMission"..v1]:SetText(v.l10nDesc)
                        local nCount = SeaAdventureHelper.GetRewardDiceCount(tbSubTask.tbRewards)
                        pWidgetRef["txtCount"..v1]:SetText(string.format("+%d", nCount * v.nTimes ))
                    end
                end
            end
        end
        local nMissionCount = tbInstance:GetCurrentTaskRewardCount()
        pWidgetRef.txtNumber:SetText(string.format("%d/%d", nMissionCount, tbTemplate.tbScheduleData.nDiceMaxDay))
    end
end

function UPSeaAdventureTips:OnBindEvent(EventHelper)
end

function UPSeaAdventureTips:OnLoad()
end

function UPSeaAdventureTips:OnShow()
    FillInfo(self)
end

function UPSeaAdventureTips:OnDestroy()
end

return UPSeaAdventureTips