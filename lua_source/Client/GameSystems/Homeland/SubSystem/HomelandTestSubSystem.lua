-----------------------------------------------------
--File Name    : HomelandTestSubSystem.lua
--Author       : zhiyuan
--Create Time  : 2019-04-22
--Description  : 家园的子系统示例
-----------------------------------------------------
local HomelandTestSubSystem = {}

-----------------------------------------logic local function---------------------------------------------


-----------------------------------------System Init UnInit---------------------------------------------

function HomelandTestSubSystem:Init()
end

function HomelandTestSubSystem:Uninit()
end

function HomelandTestSubSystem:OnEnterHomeland()
end

function HomelandTestSubSystem:OnLeaveHomeland()
end

-----------------------------------------给外部模块的调用接口---------------------------------------------

return HomelandTestSubSystem
