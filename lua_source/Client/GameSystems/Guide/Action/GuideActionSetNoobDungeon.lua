-----------------------------------------------------
--File Name    : GuideActionDrag.lua
--Description  : 指引动作
-----------------------------------------------------
local luaclass                      = require("luaclass")
local GuideActionFunctional       = require("GuideActionFunctional")
local GuideActionSetNoobDungeon   = luaclass("GuideActionSetNoobDungeon",GuideActionFunctional)
--import
local UIManager = require("UIManager")
local UIDef     = require("UIDef")
-----------------------------------------------------
--local 

function GuideActionSetNoobDungeon:DoAction(tbTemplate)
    GuideActionSetNoobDungeon.super.DoAction(self, tbTemplate)
    local tbParam = tbTemplate.tbParam
    local nOpen = 0
    if not tbParam then
        nOpen = 0
    else
        nOpen = tonumber(tbParam[1])
    end
    local BornPointWnd = UIManager:GetWnd(UIDef.UI_FFA_SELECT_BORNPOINT)
    if not BornPointWnd then
        self:LogError("GuideActionSelectResIcon:ShowSelectEffect BornSelectWnd is nil")
        return
    end
    if nOpen >0 then
        BornPointWnd:SetNoobDungeon(true)
    else
        BornPointWnd:SetNoobDungeon(false)
    end
end

return GuideActionSetNoobDungeon
