-----------------------------------------------------
--File Name    : BattlePickPosDef.lua
--Author       : ranjie
--Create Time  : 2018-12-14
--Description  : 拾取位置定义
-----------------------------------------------------

local UIDef = require("UIDef")

local BattlePickPosDef =
{
    DefaultPos = {
        [UIDef.UI_PICKUP_ITEM] = {X_OFFSET = 0, Y_OFFSET = 80},
        [UIDef.UI_PICKUP_BOX] = {X_OFFSET = 0, Y_OFFSET = 80},
        ULPickupButton = {X_OFFSET = 0, Y_OFFSET = 0},
    },
    CustomPos =
    {
        [UIDef.UI_FFABACKPACK] = {
            [UIDef.UI_PICKUP_ITEM] = {X_OFFSET = 0, Y_OFFSET = 80, X_SHIFT_OFFSET = -260, },
            [UIDef.UI_PICKUP_BOX] = {X_OFFSET = 0, Y_OFFSET = 80, X_SHIFT_OFFSET = -260, },
            ULPickupButton = {X_OFFSET = 0, Y_OFFSET = 0, X_SHIFT_OFFSET = -260,},
            Priority = 1,
        },
        [UIDef.UI_BUILD_ITEM] = {
            [UIDef.UI_PICKUP_ITEM] = {X_OFFSET = 0, Y_OFFSET = 80, X_SHIFT_OFFSET = -260, },
            [UIDef.UI_PICKUP_BOX] = {X_OFFSET = 0, Y_OFFSET = 80, X_SHIFT_OFFSET = -260, },
            ULPickupButton = {X_OFFSET = 0, Y_OFFSET = 0, X_SHIFT_OFFSET = -260,},
            Priority = 2,
        }
    }
}

function BattlePickPosDef.GetFirstPriorityWnd(tbWndMap)
    local nFirstPriority = -1
    local szWndName = nil
    local tbUIPos = BattlePickPosDef.CustomPos
    for k, v in pairs(tbWndMap) do
        local nCurrentPriority = tbUIPos[k].Priority
        if nCurrentPriority > nFirstPriority then
            nFirstPriority = nCurrentPriority
            szWndName = k
        end
    end
    return szWndName
end

return BattlePickPosDef