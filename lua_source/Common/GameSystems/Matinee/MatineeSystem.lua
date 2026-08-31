--File Name    : MatineeSystem.lua
--Author       : Zuo Kun
--Create Time  : 2017-06-09
--Description  : MatineeSystem
-----------------------------------------------------
local Matinee = dynamic_require("Matinee")
local luaclass = require("luaclass")
local MatineeSystem = luaclass("MatineeSystem")
local GlobalVariableSystem = dynamic_require("GlobalVariableSystem")
local DelayTimer = require("DelayTimer")
local MatineeDataTable = require("MatineeDataTable")

MatineeSystem.tbMatinees = {}
MatineeSystem.tbDelayTimerHandles = {}

function MatineeSystem:Init()
end

local function ClearTimer(self)
	for k, v in pairs(self.tbDelayTimerHandles) do	
		DelayTimer:ClearTimer(v)
		v = nil
	end
	self.tbDelayTimerHandles = {}
end

function MatineeSystem:Uninit()
	ClearTimer(self)
	self:Clear()
end


function MatineeSystem:Clear()
	for _,v in pairs(self.tbMatinees) do
		v:Destroy()
	end
	self.tbMatinees = {}
end 

function MatineeSystem:PlayMatinee(nID, bLoop, fnOnComplete, fnOnPlay, bReverse)
	local tbTemplate = MatineeDataTable:GetTemplate(nID)
	if not GlobalVariableSystem:IsClient() and tbTemplate.bPlayInServer and tbTemplate.nTime then
		local tbDelayTimerHandle = self:GetMatineeTimerHandle(nID)
		if tbDelayTimerHandle then
			log("matinee has timer ", nID)
			return nil 
		end
		tbDelayTimerHandle = DelayTimer:DelayRun(function() 
				self:OnMatineeTimeOut(nID, fnOnComplete) 
			end, tbTemplate.nTime)
		self.tbDelayTimerHandles[nID] = tbDelayTimerHandle
		return nil
	else	
		local matinee = self:GetMatinee(nID)
		if matinee then 
			log("matinee has played", nID)
			return matinee
		end 
		matinee = Matinee()
		if matinee:Create(nID, bLoop, function(tbMatinee)
			self:OnMatineeComplete(tbMatinee)
			if fnOnComplete then 
				fnOnComplete(tbMatinee)
			end 
		end, fnOnPlay, bReverse) then	
			self.tbMatinees[nID] = matinee
			return matinee
		end
	end 
	return nil
end

function MatineeSystem:Pause()
	for _,v in pairs(self.tbMatinees) do
		v:Pause()
	end
end 

function MatineeSystem:GetMatinee(nID)
	return self.tbMatinees[nID]
end 

function MatineeSystem:GetMatineeTimerHandle(nID)
	return self.tbDelayTimerHandles[nID]
end

function MatineeSystem:OnMatineeComplete(tbMatinee)
	self.tbMatinees[tbMatinee.nID] = nil
end

function MatineeSystem:OnMatineeTimeOut(nID, fnOnComplete)
	if self.tbDelayTimerHandles[nID] ~= nil then
		DelayTimer:ClearTimer(self.tbDelayTimerHandles[nID])
		self.tbDelayTimerHandles[nID] = nil
	end
	if fnOnComplete then
		fnOnComplete()
	end
end

return MatineeSystem()

