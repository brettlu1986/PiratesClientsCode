--File Name    : InteractionHeadDialog.lua
--Author       : Zuo Kun
--Create Time  : 2017-03-28
--Description  : 气泡对话
-----------------------------------------------------
local luaclass = require("luaclass")
local InteractionBase = require("InteractionBase")
local InteractionHeadDialog = luaclass("InteractionHeadDialog", InteractionBase)
local SelfTimerHelper = require("SelfTimerHelper")
local UIDef = require("UIDef")
local SelfEventHelper = require("SelfEventHelper")
local ClientEventDef = require("ClientEventDef")
local DialogDataTable = require("DialogDataTable")
local NPCSystem = require("NPCSystem")
local InteractionDef = require("InteractionDef")
local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
local TextFragmentUtils = require("TextFragmentUtils")
local GlobalVariableSystem = dynamic_require("GlobalVariableSystem")
local L10N = require("L10N")
local SoundManager = require("SoundManager")
local SelfAnimationHelper = require("SelfAnimationHelper")

local DIALOG_DURATION_TIME = 5

InteractionHeadDialog.nInteractionType = InteractionDef.InteractionMode.HEAD_TOP_DIALOG
InteractionHeadDialog.pPlayerView = nil
InteractionHeadDialog.TimerHelper = nil
-- InteractionHeadDialog.EventHelper = nil
InteractionHeadDialog.nDialogID = 0
InteractionHeadDialog.nStep = 1
InteractionHeadDialog.tbDialogParams = nil
InteractionHeadDialog.EventHelper = nil


function InteractionHeadDialog:DoInteraction(tbSelectedNpc, tbParams)
	self.bControlUIByState = false
	if not self.EventHelper then
		self.EventHelper = SelfEventHelper()
		self.EventHelper:RegisterEvent(ClientEventDef.EV_LEAVE_PROCEDURE_WILD, self, self.OnPreLoadMap)
		self.EventHelper:RegisterEvent(ClientEventDef.EV_ENTER_PROCEDURE_WILD, self, self.OnPreLoadMap)
		self.EventHelper:RegisterEvent(ClientEventDef.EV_PRE_LOAD_MAP, self, self.OnPreLoadMap)
	end

	if tbSelectedNpc and not tbSelectedNpc.pUEActor then
		tbSelectedNpc = nil
	end
	InteractionHeadDialog.super.DoInteraction(self, tbSelectedNpc, tbParams)
	if tbSelectedNpc then
		if not tbSelectedNpc.HeadInfoComponent then
			self:OnDialogEnd()
			return
		end
		if not GlobalVariableSystem:IsInDungeon() then
			tbSelectedNpc.HeadInfoComponent:SetWidgetVisibility(UIDef.UP_NAME_WIDGET, false)
		end
		local ShipHeadInfoComponent = tbSelectedNpc.ShipHeadInfoComponent
		if ShipHeadInfoComponent then
			ShipHeadInfoComponent.pWidgetRef:SetVisibility(ESlateVisibility.Hidden)
		end
	end
	if not tbParams.nDialogID or tbParams.nDialogID <= 0 then
		if tbSelectedNpc then
			local tbDialogs = tbSelectedNpc.tbNpcTemplateData.tbDialogs
			if tbDialogs and #tbDialogs > 0 then

				local nIndex = math.random(1, #tbDialogs)
				self.nDialogID = tbDialogs[nIndex]
				self.bNeedSendToServerOnEnd = false
			end
		else
			logwarning("InteractionHeadDialog Error Never Select NPC")
		end
	else
		self.nDialogID = tbParams.nDialogID
	end
	self.tbDialogParams = tbParams.tbDialogParams

	if not self.TimerHelper then
		self.TimerHelper = SelfTimerHelper()
	end
	self.TimerHelper:ClearAllTimer()
	self.TimerHelper:NewTimerMethod(self, self.DoDialog, DIALOG_DURATION_TIME, true)

	self.nStep = 1
	self:DoDialog()
end

function InteractionHeadDialog:DoDialog()
	local tbDialog = DialogDataTable:GetTemplate(self.nDialogID, 1, self.nStep)
	self:ShowDialogue(tbDialog)
	self.nStep = self.nStep + 1
end

function InteractionHeadDialog:IsSingleInstance()
	return false
end

function InteractionHeadDialog:OnPreLoadMap()
	self:OnDialogEnd(true)
end

function InteractionHeadDialog:OnDialogEnd(bBreak)
	self.Owner:RemoveInstance(self)
	self:OnInteractionEnd(bBreak)
end

function InteractionHeadDialog:OnInteractionEnd(bBreak)
	if self.EventHelper then
		self.EventHelper:UnregisterAll()
		self.EventHelper = nil
	end

	if not bBreak and self.OnComplete then
		self.OnComplete:Fire(self)
		self.OnComplete:UnbindAll()
	end
	if self.TimerHelper then
		self.TimerHelper:ClearAllTimer()
		self.TimerHelper = nil
	end
	local tbSelectedNpc = self:GetSelectNpc()
	if tbSelectedNpc then
		if not GlobalVariableSystem:IsInDungeon() and tbSelectedNpc.HeadInfoComponent then
			tbSelectedNpc.HeadInfoComponent:SetWidgetVisibility(UIDef.UP_NAME_WIDGET, true)
		end
	end
end


function InteractionHeadDialog:RefreshInteractionData(tbParams)
	if not tbParams.nDialogID or tbParams.nDialogID <= 0 then
		return
	end

	self.nDialogID = tbParams.nDialogID
	self.tbDialogParams = tbParams.tbDialogParams
	self.nStep = 1
	if self.TimerHelper then
		self.TimerHelper:ClearAllTimer()
		self.TimerHelper:NewTimerMethod(self, self.DoDialog, DIALOG_DURATION_TIME, true)
	end

	self:DoDialog()

end


function InteractionHeadDialog:IsEnableInteraction(tbSelectedNpc, tbParams)
	local tbCurrentSelectedNpc = self:GetSelectNpc()
	if tbCurrentSelectedNpc == tbSelectedNpc then
		return false
	end
	return true
end

-- 显示气泡
function InteractionHeadDialog:ShowDialogue(tbDialog)
	if not tbDialog then
		self:OnDialogEnd()
		-- EventManager:OnFireEvent(ClientEventDef.EV_INTERACTION_END, self.nDialogID)
		-- self.TimerHelper:NewTimerMethod(self, self.DelayInteractionEnd, DIALOG_DURATION_TIME, false)
		return
	end
	local szMsg = tbDialog.szMsg
	if self.tbDialogParams then
		local tbDialogParam = self.tbDialogParams[tbDialog.nIndex]
		if tbDialogParam then
			local tbArgs = {}
			for i, v in ipairs(tbDialogParam.args) do
				tbArgs[i] = TextFragmentUtils:ParseTextFragment(v)
			end
			szMsg = L10N:FormatFromTable(szMsg, tbArgs)
		end
	end
	-- logdebug(tbDialog.nID)
	if tbDialog.nDisplayID == 0 then    -- 自己
		-- tbTarget =  GamePlayerSelfHelper:Get().pUEActor
		local PlayerSelf = GamePlayerSelfHelper:Get()
		self:ShowHeadDialog(PlayerSelf, szMsg, tbDialog.nDialogIconId)

		-- self:PlayAnimation(PlayerSelf, PlayerSelf.LobbyPropertyComponent.nHumanTemplateId, tbDialog.szAnimKey)
		SelfAnimationHelper:PlayHumanAnimation(PlayerSelf, tbDialog.szAnimKey)
		return
	end

	local tbTarget = nil

	if tbDialog.nDisplayID == - 1 then
		tbTarget = self:GetSelectNpc()
	else
		tbTarget = NPCSystem:GetNpcByTemplateID(tbDialog.nDisplayID)
	end

	if not tbTarget then
		tbTarget = self:GetSelectNpc()
	end

	if tbDialog.nSoundID and tbDialog.nSoundID > 0 then
		SoundManager:PlaySoundEffect(tbDialog.nSoundID)
	end

	if not tbTarget then
		logwarning("Error Dialogue NPC ID " .. tbDialog.nDisplayID)
		return
	end

	-- self:PlayAnimation(tbTarget, tbTarget.tbNpcTemplateData.nHumanID, tbDialog.szAnimKey)
	SelfAnimationHelper:PlayNPCAnimation(tbTarget, tbDialog.szAnimKey)

	self:ShowHeadDialog(tbTarget, szMsg, tbDialog.nDialogIconId)
end

function InteractionHeadDialog:ShowHeadDialog(tbTarget, szMsg, nDialogIconId)
    if not tbTarget or not tbTarget.HeadInfoComponent then
        return
    end
	tbTarget.HeadInfoComponent:RefreshWidget(UIDef.UP_DIALOG_WIDGET, {szText = szMsg})
end

function InteractionHeadDialog:CanStop()
	return true
end

return InteractionHeadDialog