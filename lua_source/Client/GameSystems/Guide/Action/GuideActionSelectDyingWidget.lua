-----------------------------------------------------
--File Name    : GuideActionSelectDyingWidget.lua
--Description  : 高亮重伤队友血条
-----------------------------------------------------
local luaclass                      = require("luaclass")
local GuideActionSelectWidget       = require("GuideActionSelectWidget")
local GuideActionSelectDyingWidget   = luaclass("GuideActionSelectDyingWidget", GuideActionSelectWidget)

local UIManager                     = require("UIManager")
local UIDef                         = require("UIDef")
local Proto                         = require("DungeonCommonProtoNames")
local TeamWatchClientHelper         = require("TeamWatchClientHelper")

-----------------------------------------------------
GuideActionSelectDyingWidget.szCurrentSlotName = ""
local EState = Proto.TeamInfo_EState
-----------------------------------------------------

function GuideActionSelectDyingWidget:GetSelectWidgets()
    local Widget = nil
    local tbTemp = {}
    local Wnd = UIManager:GetWnd(UIDef.UI_FFA_MAIN)
    if not Wnd then
        self:LogError(" GuideActionSelectDyingWidget 1")
        return tbTemp
    end
   
    local tbTeamInfos = TeamWatchClientHelper.GetCurrentTeamInfo() 
    local nDyingSlot = -1
    for k, v in ipairs(tbTeamInfos) do  
        if v.nState == EState.DYING then  
            nDyingSlot = v.nIndex
            break
        end
    end

    if nDyingSlot > 0 then
        if Wnd.pWidgetRef and Wnd.pWidgetRef["pbTeammateInfo0" .. nDyingSlot] then
            Widget = Wnd.pWidgetRef["pbTeammateInfo0" .. nDyingSlot].pbgHp
        end
        table.insert(tbTemp, Widget)
    end
    
    return tbTemp
end


--override
function GuideActionSelectDyingWidget:Begin()
    GuideActionSelectDyingWidget.super.Begin(self)
end
return GuideActionSelectDyingWidget
