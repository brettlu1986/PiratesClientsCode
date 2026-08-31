-----------------------------------------------------
--File Name    : UPItemBuff.lua
--Author       : lzheng
--Create Time  : 2019-10-15
--Description  : 大厅物品buff
-----------------------------------------------------
local luaclass = require ("luaclass")
local ListItemBase = require("ListItemBase")
local UPItemBuff = luaclass("UPItemBuff", ListItemBase)
local ItemBuffHelper = require("ItemBuffHelper")
local UISetUtils = require("UISetUtils")
local TimeUtil = require("TimeUtil")
local L10N = require("L10N")
local Timer = require("Timer")
local ClientEventDef = require("ClientEventDef")

local TimeTypeTimer = "TimeTimer"

UPItemBuff.nTimeCount = 0

function UPItemBuff:OnLoad()
end

function UPItemBuff:OnShow()
end

function UPItemBuff:OnBindEvent(EventHelper)
end

function UPItemBuff:OnUnload()
    Timer.StopOwnerAllTimer(self, true)
end

function UPItemBuff:OnRefresh(tbData)
    local tbTemplate = ItemBuffHelper.GetBuffTemplate(tbData.id)

    local pWidgetRef = self.pWidgetRef
    UISetUtils.SetImageBrushRes(pWidgetRef.imgItem, tbTemplate.szIcon:load())

    pWidgetRef.txtTitleName:SetText(tbTemplate.l10nName)
    pWidgetRef.texDesc:SetText(tbTemplate.l10nDesc)
    if tbTemplate.bCountType then
        pWidgetRef.txtLeft:SetText(L10N:Format(UISetUtils.GetL10NTextByKey("BUFF_LEFT_TIMES"), tbData.unit))
    else  
        local nSecLeft = ItemBuffHelper.GetBuffTimeLeft(tbData.unit)
        local nDay, nHour, nMin, nSec = TimeUtil.GetDayHourMinuteSecond(nSecLeft)

        local l10nLeft = nil
        if nDay ~= 0 then 
            l10nLeft = L10N:Format(UISetUtils.GetL10NTextByKey("BUFF_LEFT_TIME_DAY"), nDay)
        elseif nHour ~= 0 then  
            l10nLeft = L10N:Format(UISetUtils.GetL10NTextByKey("BUFF_LEFT_TIME_HOUR"), nHour)
        elseif nMin ~= 0 then  
            l10nLeft = L10N:Format(UISetUtils.GetL10NTextByKey("BUFF_LEFT_TIME_MIN"), nMin)
        elseif nSec ~= 0 then  
            l10nLeft = L10N:Format(UISetUtils.GetL10NTextByKey("BUFF_LEFT_TIME_SEC"), nSec)
            self.nTimeCount = nSec
            Timer.StartOwnerTimer(self, TimeTypeTimer, function() 
                self.nTimeCount = self.nTimeCount - 1
                if self.nTimeCount <= 0 then  
                    Timer.StopOwnerTimer(self, TimeTypeTimer)
                    self.EventHelper:FireEvent(ClientEventDef.EV_REFRESH_ITEM_BUFFS)
                end
            end, 1, true)
            
        end
        pWidgetRef.txtLeft:SetText(l10nLeft)
    end
end

return UPItemBuff
