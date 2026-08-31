local luaclass = require("luaclass")
local GMSystem = luaclass("GMSystem")

local CppDelegate = require("CppDelegate")

GMSystem.tbCommand = nil
GMSystem.DelegateHandle = nil

local function SetLogReport(szParam)
	local StringUtil = require("StringUtil")
	local LogReportSystem = dynamic_require("LogReportSystem")
	local tbParams = StringUtil.Split(szParam, ' ')
	if (#tbParams >= 3) and (not StringUtil.IsEmptyString(tbParams[3])) then
		LogReportSystem:SetErrorFiltered(tbParams[3] == "1")
	end
	if (#tbParams >= 2) and (not StringUtil.IsEmptyString(tbParams[2])) then
		LogReportSystem:SetWarningFiltered(tbParams[2] == "1")
	end
	if (#tbParams >= 1) and (not StringUtil.IsEmptyString(tbParams[1])) then
		LogReportSystem:SetEnabled(tbParams[1] == "1")
    end
end

local function OutputLog(szParam)
    local nPos = string.find(szParam, " ")
    local szLogLevel = "1"
    if nPos then
        szLogLevel = string.sub(szParam, 1, 1)
        szParam = string.sub(szParam, nPos + 1, -1)
    end
    if szLogLevel == "1" then
        log("[OutputLog]", szParam)
    elseif szLogLevel == "2" then
        logwarning("[OutputLog]", szParam)
    elseif szLogLevel == "3" then
        logerror("[OutputLog]", szParam)
    end
end

function GMSystem:RegisterCommands()
	self:Register("setlogreport", SetLogReport)
	self:Register("outputlog", OutputLog)
end

function GMSystem:Init()
    self.tbCommand = {}
    self:RegisterCommands()

    local fnFunc = function(szCommand)
        return self:Exec(szCommand)
    end
    local DelegateManager = EngineExtShell.Get(GWorld):GetKMDelegateManager()
    self.DelegateHandle = CppDelegate:Bind(DelegateManager.OnExecCommand, fnFunc)
    return true
end

function GMSystem:Uninit()
    self.tbCommand = nil
    if(self.DelegateHandle) then
        self.DelegateHandle:Unbind()
        self.DelegateHandle = nil
    end
end

local ParseCommand = function(szStr, szDelim)
    if (type(szDelim) ~= 'string') or (string.len(szDelim) <= 0) then
        return szStr, nil
    end

    local nStart = 1
    local nPos = string.find(szStr, szDelim, nStart, true) -- plain find
    if not nPos then
        return szStr, nil
    end

    local szCommand = string.sub(szStr, 1, nPos - 1)
    local szParam = string.sub(szStr, nPos+1, string.len(szStr))
    return szCommand, szParam
end

function GMSystem:IsEnabled()
    return true
end

function GMSystem:Exec(szInputCommand)
    local szCommand, szParam = ParseCommand(szInputCommand, " ")
    if szCommand and self:IsEnabled() then
        local fnFunc = self.tbCommand[szCommand]
        if(fnFunc) then
            if(szParam) then
                log("GMSystem:Exec["..szCommand.."], Param["..szParam.."]")
            else
                log("GMSystem:Exec["..szCommand.."]")
            end
            fnFunc(szParam)
            return true
        end
    end
    return false
end

function GMSystem:Register(szCommand, fnFunc)
    self.tbCommand[szCommand] = fnFunc
end

return GMSystem()
