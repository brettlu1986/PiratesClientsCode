-----------------------------------------------------
--File Name    : AsyncHelperSystem.lua
--Author       : Zuo Kun
--Create Time  : 2019-08-13
--Description  : 异步Spawn
-----------------------------------------------------

local AsyncHelperSystem = {}

local DelayTimer = require("DelayTimer")

AsyncHelperSystem.AsyncTimeHandler = nil 
AsyncHelperSystem.tbAsyncLists = {}

local MAX_ASYNC_SPAWN_TIME = 0.02
local RunAsync = nil 

function AsyncHelperSystem:Init()
end 

function AsyncHelperSystem:Uninit() 
    if self.AsyncTimeHandler then 
        DelayTimer:ClearTimer(self.AsyncTimeHandler)
        self.AsyncTimeHandler = nil 
    end
    self.tbAsyncLists = nil 
end 


local function AsyncTick(self) 
    if not self.tbAsyncLists then  
        return
    end 
    local nTimer = 0
    local nStartTime = getseconds()

    while #self.tbAsyncLists > 0 and nTimer < MAX_ASYNC_SPAWN_TIME do
        local tbInstance = self.tbAsyncLists[1]
        table.remove(self.tbAsyncLists, 1)
        if tbInstance then  
            tbInstance.tbCallBack(tbInstance.tbParam)
        end 
        nTimer = getseconds()- nStartTime 
    end

    self.AsyncTimeHandler = nil 
    RunAsync(self)
end 

RunAsync = function(self) 
    if not self.AsyncTimeHandler and #self.tbAsyncLists > 0 then  
        self.AsyncTimeHandler = DelayTimer:RunNextTick(function() 
            AsyncTick(self)
        end)   
    end 
end 

function AsyncHelperSystem:AddToAsyncList(tbParam, CallBack)
    table.insert(self.tbAsyncLists, {tbParam = tbParam, tbCallBack = CallBack})

end

function AsyncHelperSystem:ReadyForAsync()
    RunAsync(self)
end

return AsyncHelperSystem 