-----------------------------------------------------
--File Name    : GVoiceOpCtrlHelper.lua
--Description  : 语音麦克风扬声器选项配置
-----------------------------------------------------
local GlobalVariableSystem      = dynamic_require("GlobalVariableSystem")
local GVoiceDebug               = require("GVoiceDebug")

local GVoiceOpCtrlHelper = {}

--member veriable
GVoiceOpCtrlHelper.MIC =
{
    ALL       = 1,
    TEAM      = 2,
    MUTE      = 3,
    PRESSALL  = 4,
    PRESSTEAM = 5,
}

GVoiceOpCtrlHelper.SPEAKER =
{
    ALL       = 1,
    TEAM      = 2,
    MUTE      = 3,
}

GVoiceOpCtrlHelper.nCurrentSpeakerOp = GVoiceOpCtrlHelper.SPEAKER.ALL
GVoiceOpCtrlHelper.nCurrentMicOp     = GVoiceOpCtrlHelper.MIC.MUTE

function GVoiceOpCtrlHelper.SetCurrentSpeakerOp(nOption)
    if nOption < GVoiceOpCtrlHelper.SPEAKER.ALL or nOption > GVoiceOpCtrlHelper.SPEAKER.MUTE then
        return false
    end
    GVoiceOpCtrlHelper.nCurrentSpeakerOp = nOption
    return true
end

function GVoiceOpCtrlHelper.SetCurrentMicOp(nOption)
    if nOption < GVoiceOpCtrlHelper.MIC.ALL or nOption > GVoiceOpCtrlHelper.MIC.MUTE then
        return false
    end
    GVoiceOpCtrlHelper.nCurrentMicOp = nOption
    return true
end

function GVoiceOpCtrlHelper.GetCurrentSpeakerOp()
    return GVoiceOpCtrlHelper.nCurrentSpeakerOp
end

function GVoiceOpCtrlHelper.GetCurrentMicOp()
    return GVoiceOpCtrlHelper.nCurrentMicOp
end

function GVoiceOpCtrlHelper.ReadyToOpenMic(GVoiceSystem)
    GVoiceDebug:DebugLog("Current mic OP = " .. GVoiceOpCtrlHelper.nCurrentMicOp)
    local bSingle = GVoiceSystem.IsSelfSinglePlayer()
    if GVoiceOpCtrlHelper.nCurrentMicOp == GVoiceOpCtrlHelper.MIC.ALL then
        if not GVoiceSystem:CheckMicEnable() then
            return false
        end
        return true
    elseif GVoiceOpCtrlHelper.nCurrentMicOp == GVoiceOpCtrlHelper.MIC.TEAM then
        if bSingle then
            return false
        end
        if not GVoiceSystem:CheckMicEnable() then
            return false
        end
        return true
    end
    return false
end

function GVoiceOpCtrlHelper.ReadyToOpenSpeaker(GVoiceSystem)
    local bSingle = GVoiceSystem.IsSelfSinglePlayer()
    if GVoiceOpCtrlHelper.nCurrentSpeakerOp == GVoiceOpCtrlHelper.SPEAKER.ALL then
        return true
    elseif GVoiceOpCtrlHelper.nCurrentSpeakerOp == GVoiceOpCtrlHelper.SPEAKER.TEAM then
        if bSingle then
            return false
        end
        return true
    end
    return false
end

function GVoiceOpCtrlHelper.SetMultiRoomMic(GVoiceSystem)
    local bIsInDungeon = GlobalVariableSystem:IsInDungeon()
    if not bIsInDungeon or not GVoiceSystem then
        return
    end
    if GVoiceOpCtrlHelper.nCurrentMicOp == GVoiceOpCtrlHelper.MIC.ALL
    or GVoiceOpCtrlHelper.nCurrentMicOp == GVoiceOpCtrlHelper.MIC.PRESSALL then
        GVoiceSystem:EnableCurrentAllRoomMicrophone(true)
        GVoiceSystem:EnableCurrentTeamRoomMicrophone(true)
    elseif GVoiceOpCtrlHelper.nCurrentMicOp == GVoiceOpCtrlHelper.MIC.TEAM
    or GVoiceOpCtrlHelper.nCurrentMicOp == GVoiceOpCtrlHelper.MIC.PRESSTEAM then
        GVoiceSystem:EnableCurrentAllRoomMicrophone(false)
        GVoiceSystem:EnableCurrentTeamRoomMicrophone(true)
    end
end

function GVoiceOpCtrlHelper.SetMultiRoomSpeaker(GVoiceSystem)
    local bIsInDungeon = GlobalVariableSystem:IsInDungeon()
    if not bIsInDungeon or not GVoiceSystem then
        return
    end
    if GVoiceOpCtrlHelper.nCurrentSpeakerOp == GVoiceOpCtrlHelper.SPEAKER.ALL then
        GVoiceSystem:EnableCurrentAllRoomSpeaker(true)
        GVoiceSystem:EnableCurrentTeamRoomSpeaker(true)
    elseif GVoiceOpCtrlHelper.nCurrentSpeakerOp == GVoiceOpCtrlHelper.SPEAKER.TEAM then
        GVoiceSystem:EnableCurrentAllRoomSpeaker(false)
        GVoiceSystem:EnableCurrentTeamRoomSpeaker(true)
    end
end

return GVoiceOpCtrlHelper