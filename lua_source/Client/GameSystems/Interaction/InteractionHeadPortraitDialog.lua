--File Name    : InteractionHeadPortraitDialog.lua
--Author       : Zuo Kun
--Create Time  : 2017-04-08
--Description  : 有头像气泡对话
-----------------------------------------------------

local luaclass = require("luaclass")
local InteractionHeadDialog = require("InteractionHeadDialog")
local InteractionHeadPortraitDialog = luaclass("InteractionHeadPortraitDialog", InteractionHeadDialog)
local InteractionDef = require("InteractionDef")
local UIDef = require("UIDef")
local DialogHeadIconResData = require("DialogHeadIconResData")

InteractionHeadPortraitDialog.nInteractionType = InteractionDef.InteractionMode.HEAD_PORTRAIT_DIALOG

function InteractionHeadPortraitDialog:ShowHeadDialog(tbTarget, szMsg, nDialogIconId)
    -- TODO tbTarget 在Target 获取 ICON
    -- tbTarget.HeadInfoComponent:RefreshWidget(UIDef.UP_DIALOG_WIDGET, {szText = szMsg})    
    if not tbTarget or not tbTarget.HeadInfoComponent then 
        return 
    end 
    local tbDialogIcon = DialogHeadIconResData:GetTemplate(nDialogIconId)
    local szPath = ""
    if tbDialogIcon then 
        szPath = tbDialogIcon.szIconRes
    end 
    tbTarget.HeadInfoComponent:RefreshWidget(UIDef.UP_DIALOG_WIDGET, {szText = szMsg, szPortraitPath = szPath})    
end 

return InteractionHeadPortraitDialog