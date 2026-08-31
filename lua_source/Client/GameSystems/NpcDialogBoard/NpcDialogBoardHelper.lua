-----------------------------------------------------
--File Name    : NpcDialogBoardHelper.lua
--Author       : Chang Nan
--Create Time  : 2017-12-27
--Description  : NPC喊话面板帮助类
-----------------------------------------------------
local NpcDialogBoradSystem = require("NpcDialogBoardSystem")

local NpcDialogBoardHelper = {}


function NpcDialogBoardHelper:OpenDialogBoard(nDialogID, GameObject)
  NpcDialogBoradSystem:OpenDialogBoard(nDialogID, GameObject)
end




return NpcDialogBoardHelper 