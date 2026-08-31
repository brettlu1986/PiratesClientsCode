-----------------------------------------------------
--File Name    : GVoiceDebug.lua
--Description  : 新手指引打印日志开关
-----------------------------------------------------
local GVoiceDebug = {}

--member veriable
GVoiceDebug.DebugLevel =
{
    LOG = 1,
    WARNING = 2,
    ERROR = 3,
}
GVoiceDebug.bDebugOpen = true
GVoiceDebug.nLevel = GVoiceDebug.DebugLevel.LOG

function GVoiceDebug:OpenDebug(bOpen, nLevel)
    self.bDebugOpen = bOpen
    if(nLevel ~= nil)then
        self.nLevel = nLevel
    end
end

function GVoiceDebug:DebugLog(szMsg)
    if(not self.bDebugOpen)then
        return
    end
    szMsg = "[GVoiceSDKSystem] " .. szMsg
    local nLevel = self.nLevel
    if(nLevel == 1)then
        log(szMsg)
    elseif(nLevel == 2)then
        logwarning(szMsg)
    else
        logerror(szMsg)
    end
end

function GVoiceDebug:Log(szMsg)
    szMsg = "[GVoiceSDKSystem] " .. szMsg
    log(szMsg)
end

function GVoiceDebug:LogError(szMsg)
    szMsg = "[GVoiceSDKSystem] [ERROR] " .. szMsg
    log(szMsg)
end

return GVoiceDebug
