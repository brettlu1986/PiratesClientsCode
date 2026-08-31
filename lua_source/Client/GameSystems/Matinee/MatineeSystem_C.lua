--File Name    : MatineeSystem.lua
--Author       : Zuo Kun
--Create Time  : 2017-06-09
--Description  : MatineeSystem
-----------------------------------------------------

local luaclass = require("luaclass")
local MatineeSystem = require("MatineeSystem")
local MatineeSystem_C = luaclass("MatineeSystem_C", MatineeSystem)

local ClientEventDef = require("ClientEventDef")
local SelfEventHelper = require("SelfEventHelper")


MatineeSystem_C.tbMatineeActors = {}
MatineeSystem_C.EventHelper = nil 

function MatineeSystem_C:Init()
	MatineeSystem_C.super.Init(self)
	self.EventHelper = SelfEventHelper()
	self.EventHelper:RegisterEvent(ClientEventDef.EV_ENTER_LOADING, self, self.OnPreLoading)
end

function MatineeSystem_C:Uninit()
	self:Clear()
	self.EventHelper:UnregisterAll()
	self.EventHelper = nil	
end




function MatineeSystem_C:OnPreLoading()
	self:Clear()
	-- self.tbMatinees = {}
end 

return MatineeSystem_C()

