// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "HAL/Platform.h"
#include "Containers/Array.h"

extern "C" {
    struct lua_State;
}

namespace google
{
    namespace protobuf
    {
        class Message;
    }
}

class FString;
struct FLuaTableRef;
class ProtobufCodec;

class COMMON_API FMessageLuaUtil
{
public:
    typedef TArray<uint8, TInlineAllocator<512> > FTempRawBuffer;

public:

    static int MessageToLuaTable(const google::protobuf::Message* Message, lua_State* L);

    static const google::protobuf::Message* LuaTableToMessage(
        ProtobufCodec* Codec,
        const FString& MessageName,
        FLuaTableRef* Table);

    static bool LuaTableToRawBuffer(
        ProtobufCodec* Codec,
        const FString& MessageName,
        FLuaTableRef* Table,
        FString* DebugInfo,
        uint8* Buffer,
        int32 BufferMaxSize,
        int32& OutMessageSize,
        bool UseProtoFrame=true);

    static bool LuaTableToArrayData(
        ProtobufCodec* Codec,
        const FString& MessageName,
        FLuaTableRef* Table,
        FString* DebugInfo,
        TArray<uint8>& OutRawData,
        bool UseProtoFrame = true);

	static bool LuaTableToTempBuffer(
		ProtobufCodec* Codec,
		const FString& MessageName,
        FLuaTableRef* Table,
        FString* DebugInfo,
        FTempRawBuffer& OutRawData,
        bool UseProtoFrame = true);
};
