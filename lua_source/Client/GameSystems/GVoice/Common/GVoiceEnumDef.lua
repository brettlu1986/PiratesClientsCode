-----------------------------------------------------
--File Name    : GVoiceDebug.lua
--Description  : 新手指引打印日志开关
-----------------------------------------------------
local GVoiceEnumDef = {
}

GVoiceEnumDef.ErrorCode = {

}

GVoiceEnumDef.CompleteCode = {
        
}

-- local nErrorCode = -1
-- local function InitErrorCode(szEnum)
--     nErrorCode = nErrorCode + 1 
--     GVoiceEnumDef.ErrorCode[szEnum] = nErrorCode
-- end

local nCompleteCode = 0
local function InitCompleteCode(szEnum)
    nCompleteCode = nCompleteCode + 1 
    GVoiceEnumDef.CompleteCode[szEnum] = nCompleteCode
end


InitCompleteCode("GV_ON_JOINROOM_SUCC")	                        --join room success
InitCompleteCode("GV_ON_JOINROOM_TIMEOUT")                      --join room timeout
InitCompleteCode("GV_ON_JOINROOM_SVR_ERR")                      --communication with svr meets some error, such as wrong data received from svr
InitCompleteCode("GV_ON_JOINROOM_UNKNOWN")                      --reserved, GVoice internal unknown error 
InitCompleteCode("GV_ON_NET_ERR")                               --network error, maybe can't connect to network
InitCompleteCode("GV_ON_QUITROOM_SUCC")                         --quitroom success, if you have joined room success first, quit room will alway return success
InitCompleteCode("GV_ON_MESSAGE_KEY_APPLIED_SUCC")              --apply message authkey succ
InitCompleteCode("GV_ON_MESSAGE_KEY_APPLIED_TIMEOUT")		    --apply message authkey timeout
InitCompleteCode("GV_ON_MESSAGE_KEY_APPLIED_SVR_ERR")           --communication with svr meets some error, such as wrong data received
InitCompleteCode("GV_ON_MESSAGE_KEY_APPLIED_UNKNOWN")           --reserved, GVoice internal unknown error
InitCompleteCode("GV_ON_UPLOAD_RECORD_DONE")                    --upload record file success
InitCompleteCode("GV_ON_UPLOAD_RECORD_ERROR")                   --upload record file meets some error
InitCompleteCode("GV_ON_DOWNLOAD_RECORD_DONE")	                --download record file success
InitCompleteCode("GV_ON_DOWNLOAD_RECORD_ERROR")	                --download record file meets some error
InitCompleteCode("GV_ON_STT_SUCC")                              --speech to text success
InitCompleteCode("GV_ON_STT_TIMEOUT")                           --speech to text timeout
InitCompleteCode("GV_ON_STT_APIERR")                            --server's error        
InitCompleteCode("GV_ON_RSTT_SUCC")                             --stream speech to text success
InitCompleteCode("GV_ON_RSTT_TIMEOUT")                          --stream speech to text timeout
InitCompleteCode("GV_ON_RSTT_APIERR")                           --server's error in stream speech to text        
InitCompleteCode("GV_ON_PLAYFILE_DONE")                         --the record file have played to the end        
InitCompleteCode("GV_ON_ROOM_OFFLINE")                          --dropped from the room
InitCompleteCode("GV_ON_UNKNOWN")
InitCompleteCode("GV_ON_ROLE_SUCC")                             --change role success
InitCompleteCode("GV_ON_ROLE_TIMEOUT")                          --change role timeout
InitCompleteCode("GV_ON_ROLE_MAX_AHCHOR")                       --too many anchors, no more than 5 anchors in the same time are allowed in a national room
InitCompleteCode("GV_ON_ROLE_NO_CHANGE")                        --the same role as before
InitCompleteCode("GV_ON_ROLE_SVR_ERROR")                        --server's error in change role        
InitCompleteCode("GV_ON_RSTT_RETRY")                            --need retry stt
InitCompleteCode("GV_ON_JOINROOM_RETRY_FAIL")                   --join room try again fail
InitCompleteCode("GV_ON_REPORT_SUCC")                           -- report other player succ
InitCompleteCode("GV_ON_DATA_ERROR")                            -- receive illegal or invalid data from serve
InitCompleteCode("GV_ON_PUNISHED")                              -- the player is punished because of being reported
InitCompleteCode("GV_ON_NOT_PUNISHED")                          -- the player
InitCompleteCode("GV_ON_SAVEDATA_SUCC")                         --LGAME Save RecData
InitCompleteCode("GV_ON_ROOM_MEMBER_INROOM")                    --member join or in room
InitCompleteCode("GV_ON_ROOM_MEMBER_OUTROOM")                   --member out of room
InitCompleteCode("GV_ON_UPLOAD_REPORT_INFO_ERROR")              --civilized voice reporting error
InitCompleteCode("GV_ON_UPLOAD_REPORT_INFO_TIMEOUT")            --civilized voice reporting timeout
InitCompleteCode("GV_ON_ST_SUCC")								--speech translate success
InitCompleteCode("GV_ON_ST_HTTP_ERROR")						    --http failed
InitCompleteCode("GV_ON_ST_SERVER_ERROR")						--server error
InitCompleteCode("GV_ON_ST_INVALID_JSON")						--parse rsp json faild.

return GVoiceEnumDef
