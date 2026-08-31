-----------------------------------------------------
--File Name    : InteractionHelper.lua
--Author       : Zuo Kun
--Create Time  : 2017-03-27
--Description  : 交互帮助类
-----------------------------------------------------
local InteractionSystem = require("InteractionSystem")
local InteractionDef = require("InteractionDef")
local InteractionHelper = {}

function InteractionHelper:CreateCameraDialog(nDialogID, inNpc, fnOnInteractionEnd, fnParent)
	local tbParams = {}
	tbParams.nDialogID = nDialogID
	return InteractionSystem:OnInteractionStart(InteractionDef.InteractionMode.SPECIAL_CAMERA, tbParams, inNpc, fnOnInteractionEnd, fnParent)
end

function InteractionHelper:CreateHeadDialog(nDialogID, inDialogParams, inNpc, fnOnInteractionEnd, fnParent)
	local tbParams = {}
	tbParams.nDialogID = nDialogID
	tbParams.tbDialogParams = inDialogParams 
	return InteractionSystem:OnInteractionStart(InteractionDef.InteractionMode.HEAD_TOP_DIALOG, tbParams, inNpc, fnOnInteractionEnd, fnParent)
end

function InteractionHelper:CreatePortraitHeadDialog(nDialogID, inDialogParams, inNpc, fnOnInteractionEnd, fnParent)
	local tbParams = {}
	tbParams.nDialogID = nDialogID
	tbParams.tbDialogParams = inDialogParams 
	return InteractionSystem:OnInteractionStart(InteractionDef.InteractionMode.HEAD_PORTRAIT_DIALOG, tbParams, inNpc, fnOnInteractionEnd, fnParent)
end


function InteractionHelper:CreateMatinee(nMatineeID, bLoop, fnOnInteractionEnd, fnParent, bControlUIByState)
	local tbParams = {}
	tbParams.nID = nMatineeID
	tbParams.bLoop = bLoop
	tbParams.bControlUIByState = bControlUIByState
	return InteractionSystem:OnInteractionStart(InteractionDef.InteractionMode.MATINEE, tbParams, nil, fnOnInteractionEnd, fnParent)
end

function InteractionHelper:CreateExplore(nExploreID,bIsNeedSendServer, fnOnInteractionEnd, fnParent)
	local tbParams = {}
	tbParams.nID = nExploreID
	tbParams.bNeedSendToServerOnEnd = (bIsNeedSendServer and bIsNeedSendServer or false)
	return InteractionSystem:OnInteractionStart(InteractionDef.InteractionMode.EXPLORE, tbParams, nil, fnOnInteractionEnd, fnParent)
end

function InteractionHelper:CreatePortrait(nDialogID, bControlUIByState, fnOnInteractionEnd, fnParent)
	local tbParams = {}
	tbParams.nDialogID = nDialogID
	tbParams.bControlUIByState = bControlUIByState
	return InteractionSystem:OnInteractionStart(InteractionDef.InteractionMode.UI_PORTRAIT, tbParams, nil, fnOnInteractionEnd, fnParent)
end


function InteractionHelper:CreateNoPortrait(nDialogID, bControlUIByState, fnOnInteractionEnd, fnParent)
	local tbParams = {}
	tbParams.nDialogID = nDialogID
	tbParams.bControlUIByState = bControlUIByState
	return InteractionSystem:OnInteractionStart(InteractionDef.InteractionMode.UI_NO_PORTRAIT, tbParams, nil, fnOnInteractionEnd, fnParent)
end

function InteractionHelper:CreateBattlePortrait(nDialogID, bControlUIByState, fnOnInteractionEnd, fnParent)
	local tbParams = {}
	tbParams.nDialogID = nDialogID
	tbParams.bControlUIByState = bControlUIByState
	return InteractionSystem:OnInteractionStart(InteractionDef.InteractionMode.UI_BATTLE_PORTRAIT, tbParams, nil, fnOnInteractionEnd, fnParent)
end

function InteractionHelper:AbortInteraction(nType)
	InteractionSystem:OnInteractionAbort(nType)
end 

return InteractionHelper 