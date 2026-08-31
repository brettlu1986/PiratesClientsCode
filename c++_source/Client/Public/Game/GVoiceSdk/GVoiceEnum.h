// Fill out your copyright notice in the Description page of Project Settings.

#pragma once
UENUM()
enum GVoiceViceMode
{
    GVUnknown = -1,
    GVRealTime = 0,           // realtime mode for TeamRoom, NationalRoom, RangeRoom
    GVMessages,           // voice message mode
    GVTranslation,     // speach to text mode
    GVRSTT,                   // real-time speach to text mode
    GVHIGHQUALITY,     // high quality realtime voice mode[deprecated], will cost more network traffic
};

UENUM()
enum GVoiceCompleteCode
{
    GV_JOINROOM_SUCC = 1,	               //join room success
    GV_JOINROOM_TIMEOUT,                    //join room timeout
    GV_JOINROOM_SVR_ERR,                    //communication with svr meets some error, such as wrong data received from svr
    GV_JOINROOM_UNKNOWN,                    //reserved, GVoice internal unknown error

    GV_NET_ERR,                             //network error, maybe can't connect to network

    GV_QUITROOM_SUCC,                       //quitroom success, if you have joined room success first, quit room will alway return success

    GV_MESSAGE_KEY_APPLIED_SUCC,            //apply message authkey succ
    GV_MESSAGE_KEY_APPLIED_TIMEOUT,		   //apply message authkey timeout
    GV_MESSAGE_KEY_APPLIED_SVR_ERR,         //communication with svr meets some error, such as wrong data received
    GV_MESSAGE_KEY_APPLIED_UNKNOWN,         //reserved, GVoice internal unknown error

    GV_UPLOAD_RECORD_DONE,                  //upload record file success
    GV_UPLOAD_RECORD_ERROR,                 //upload record file meets some error
    GV_DOWNLOAD_RECORD_DONE,	               //download record file success
    GV_DOWNLOAD_RECORD_ERROR,	           //download record file meets some error

    GV_STT_SUCC,                            //speech to text success
    GV_STT_TIMEOUT,                         //speech to text timeout
    GV_STT_APIERR,                          //server's error

    GV_RSTT_SUCC,                           //stream speech to text success
    GV_RSTT_TIMEOUT,                        //stream speech to text timeout
    GV_RSTT_APIERR,                         //server's error in stream speech to text

    GV_PLAYFILE_DONE,                       //the record file have played to the end

    GV_ROOM_OFFLINE,                        //dropped from the room
    GV_UNKNOWN,
    GV_ROLE_SUCC,                           //change role success
    GV_ROLE_TIMEOUT,                        //change role timeout
    GV_ROLE_MAX_AHCHOR,                     //too many anchors, no more than 5 anchors in the same time are allowed in a national room
    GV_ROLE_NO_CHANGE,                      //the same role as before
    GV_ROLE_SVR_ERROR,                      //server's error in change role

    GV_RSTT_RETRY,                          //need retry stt
    GV_JOINROOM_RETRY_FAIL,                 //join room try again fail
    GV_REPORT_SUCC, // report other player succ
    GV_DATA_ERROR,  // receive illegal or invalid data from serve
    GV_PUNISHED, // the player is punished because of being reported
    GV_NOT_PUNISHED, // the player
    GV_SAVEDATA_SUCC,  //LGAME Save RecData
    GV_ROOM_MEMBER_INROOM,   //member join or in room
    GV_ROOM_MEMBER_OUTROOM, //member out of room
    GV_UPLOAD_REPORT_INFO_ERROR, //civilized voice reporting error
    GV_UPLOAD_REPORT_INFO_TIMEOUT, //civilized voice reporting timeout
    GV_ST_SUCC,								//speech translate success
    GV_ST_HTTP_ERROR,						//http failed
    GV_ST_SERVER_ERROR,						//server error
    GV_ST_INVALID_JSON,						//parse rsp json faild.
};