// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "Util/MessageLuaUtil.h"
#include "Common.h"
#include "Util/LuaTableRef.h"
#include "ProtobufCodec.h"

#include <google/protobuf/message.h>
#include <google/protobuf/descriptor.h>
#include <google/protobuf/reflection.h>

#include <functional>
#include <string>

DEFINE_LOG_CATEGORY_STATIC(MessageLuaUtilLog, Log, All)

static const int32 kEncodeBufferSize = 0xffff;

namespace pb = google::protobuf;
using CppType = pb::FieldDescriptor::CppType;

// Helper template for static_assert
template <typename T>
struct always_false
{
    static constexpr bool value = false;
};

// This type is for template specialization
struct pb_enum
{
};

class FLuaTableToMessageHelper
{
public:

    FLuaTableToMessageHelper(ProtobufCodec* Codec, FLuaTableRef* Table);
    ~FLuaTableToMessageHelper();

    pb::Message* ToMessage(const std::string& messageName);

private:

    template <typename T>
    void WriteRepeated(pb::Message* message, const pb::FieldDescriptor* field, int32 luaIndex);

    template <typename T>
    void WriteRegular(pb::Message* message, const pb::FieldDescriptor* field, int32 luaIndex);

private:

    void WriteMessage(pb::Message* message, int32 luaIndex);
    void WriteRegularField(pb::Message* message, const pb::FieldDescriptor* field, int32 luaIndex);
    void WriteRepeatedField(pb::Message* message, const pb::FieldDescriptor* field, int32 luaIndex);

private:

    ProtobufCodec* const Codec;
    FLuaTableRef* const Table;
    const int32 LuaIndex;
};

FLuaTableToMessageHelper::FLuaTableToMessageHelper(ProtobufCodec* InCodec, FLuaTableRef* InTable)
    : Codec(InCodec)
    , Table(InTable)
    , LuaIndex(Table->BeginReadTable())
{
}

FLuaTableToMessageHelper::~FLuaTableToMessageHelper()
{
    Table->EndReadTable();
}

struct FLuaStackAutoRestore
{
    FLuaStackAutoRestore(lua_State* TempL)
    {
        L = TempL;
        Stack = lua_gettop(L);
    }
    FLuaStackAutoRestore(lua_State* TempL, int CheckStack)
    {
        L = TempL;
        Stack = lua_gettop(L);
        lua_checkstack(L, Stack + CheckStack);
    }
    ~FLuaStackAutoRestore()
    {
        lua_settop(L, Stack);
    }
    inline const int GetTop() const { return Stack; }
private:
    int Stack;
    lua_State* L;
};
#define LUA_STACK_AUTO_RESTORE(__l, __stack) FLuaStackAutoRestore _Restorer(__l, __stack);

// Default template for non-Message types
template <typename T>
FORCEINLINE void FLuaTableToMessageHelper::WriteRepeated(pb::Message* message, const pb::FieldDescriptor* field, int32 luaIndex)
{
    LUA_STACK_AUTO_RESTORE(Table->L, 2);

    const int subTableIndex = Table->BeginReadSubTable(field->name(), luaIndex);
    // The repeated proto, when subtable is nil will error
    if (lua_isnil(Table->L, subTableIndex))
    {
        return;
    }

    const int subTableLength = luaL_len(Table->L, subTableIndex);
    auto reflection = message->GetReflection();
    for (int keyIndex = 1; keyIndex <= subTableLength; ++keyIndex)
    {
        T value{};
        Table->ReadTableForIndex<T>(keyIndex, value, subTableIndex);
        auto mutableRepeatedField = reflection->GetMutableRepeatedFieldRef<T>(message, field);
        mutableRepeatedField.Add(value);
    }
}

// Specialization for google::protobuf::Message
template <>
FORCEINLINE void FLuaTableToMessageHelper::WriteRepeated<pb::Message>(pb::Message* message, const pb::FieldDescriptor* field, int32 luaIndex)
{
    LUA_STACK_AUTO_RESTORE(Table->L, 3);

    const int subTableIndex = Table->BeginReadSubTable(field->name(), luaIndex);
    // The repeated proto, when subtable is nil will error
    if (lua_isnil(Table->L, subTableIndex))
    {
        return;
    }

    const int subTableLength = luaL_len(Table->L, subTableIndex);
    auto reflection = message->GetReflection();
    for (int keyIndex = 1; keyIndex <= subTableLength; ++keyIndex)
    {
        lua_rawgeti(Table->L, subTableIndex, keyIndex);
        auto subMessage = reflection->AddMessage(message, field);
        if (subMessage)
        {
            WriteMessage(subMessage, lua_gettop(Table->L));
        }
        lua_pop(Table->L, 1);
    }
}

template <typename T>
void FLuaTableToMessageHelper::WriteRegular(pb::Message* message, const pb::FieldDescriptor* field, int32 luaIndex)
{
    // This is intentional
    static_assert(always_false<T>::value, "No specialization exists!");
}

template <>
FORCEINLINE void FLuaTableToMessageHelper::WriteRegular<pb::int32>(pb::Message* message, const pb::FieldDescriptor* field, int32 luaIndex)
{
    pb::int32 value{};
    if (Table->ReadTableForKey<pb::int32>(field->name(), value, luaIndex))
    {
        auto reflection = message->GetReflection();
        reflection->SetInt32(message, field, value);
    }
}

template <>
FORCEINLINE void FLuaTableToMessageHelper::WriteRegular<pb::int64>(pb::Message* message, const pb::FieldDescriptor* field, int32 luaIndex)
{
    pb::int64 value{};
    if (Table->ReadTableForKey<pb::int64>(field->name(), value, luaIndex))
    {
        auto reflection = message->GetReflection();
        reflection->SetInt64(message, field, value);
    }
}

template <>
FORCEINLINE void FLuaTableToMessageHelper::WriteRegular<pb::uint32>(pb::Message* message, const pb::FieldDescriptor* field, int32 luaIndex)
{
    pb::uint32 value{};
    if (Table->ReadTableForKey<pb::uint32>(field->name(), value, luaIndex))
    {
        auto reflection = message->GetReflection();
        reflection->SetUInt32(message, field, value);
    }
}

template <>
FORCEINLINE void FLuaTableToMessageHelper::WriteRegular<pb::uint64>(pb::Message* message, const pb::FieldDescriptor* field, int32 luaIndex)
{
    pb::uint64 value{};
    if (Table->ReadTableForKey<pb::uint64>(field->name(), value, luaIndex))
    {
        auto reflection = message->GetReflection();
        reflection->SetUInt64(message, field, value);
    }
}

template <>
FORCEINLINE void FLuaTableToMessageHelper::WriteRegular<double>(pb::Message* message, const pb::FieldDescriptor* field, int32 luaIndex)
{
    double value{};
    if (Table->ReadTableForKey<double>(field->name(), value, luaIndex))
    {
        auto reflection = message->GetReflection();
        reflection->SetDouble(message, field, value);
    }
}

template <>
FORCEINLINE void FLuaTableToMessageHelper::WriteRegular<float>(pb::Message* message, const pb::FieldDescriptor* field, int32 luaIndex)
{
    float value{};
    if (Table->ReadTableForKey<float>(field->name(), value, luaIndex))
    {
        auto reflection = message->GetReflection();
        reflection->SetFloat(message, field, value);
    }
}

template <>
FORCEINLINE void FLuaTableToMessageHelper::WriteRegular<bool>(pb::Message* message, const pb::FieldDescriptor* field, int32 luaIndex)
{
    bool value{};
    if (Table->ReadTableForKey<bool>(field->name(), value, luaIndex))
    {
        auto reflection = message->GetReflection();
        reflection->SetBool(message, field, value);
    }
}

template <>
FORCEINLINE void FLuaTableToMessageHelper::WriteRegular<pb_enum>(pb::Message* message, const pb::FieldDescriptor* field, int32 luaIndex)
{
    pb::int32 value{};
    if (Table->ReadTableForKey<pb::int32>(field->name(), value, luaIndex))
    {
        auto reflection = message->GetReflection();
        // We must call SetEnumValue for enum fields
        // Calling SetInt32 would result crashing
        reflection->SetEnumValue(message, field, value);
    }
}

template <>
FORCEINLINE void FLuaTableToMessageHelper::WriteRegular<std::string>(pb::Message* message, const pb::FieldDescriptor* field, int32 luaIndex)
{
    std::string value{};
    if (Table->ReadTableForKey<std::string>(field->name(), value, luaIndex))
    {
        auto reflection = message->GetReflection();
        reflection->SetString(message, field, value);
    }
}

template <>
FORCEINLINE void FLuaTableToMessageHelper::WriteRegular<pb::Message>(pb::Message* message, const pb::FieldDescriptor* field, int32 luaIndex)
{
    int subLuaIndex = Table->BeginReadSubTable(field->name(), luaIndex);
    if (!lua_isnil(Table->L, subLuaIndex))
    {
        auto reflection = message->GetReflection();
        auto subMessage = reflection->MutableMessage(message, field);
        if (subMessage)
        {
            WriteMessage(subMessage, subLuaIndex);
        }
    }
    Table->EndReadTable();
}

pb::Message* FLuaTableToMessageHelper::ToMessage(const std::string& messageName)
{
    auto message = Codec->CreateMessage(messageName);
    if (message)
    {
        WriteMessage(message, this->LuaIndex);
    }
    return message;
}

void FLuaTableToMessageHelper::WriteMessage(pb::Message* message, int32 luaIndex)
{
    auto descriptor = message->GetDescriptor();
    const auto fieldCount = descriptor->field_count();

    for (int i = 0; i < fieldCount; ++i)
    {
        auto field = descriptor->field(i);
        if (field->is_repeated())
            WriteRepeatedField(message, field, luaIndex);
        else
            WriteRegularField(message, field, luaIndex);
    }
}

void FLuaTableToMessageHelper::WriteRegularField(pb::Message* message, const pb::FieldDescriptor* field, int32 luaIndex)
{
    #define WRITE_REGULAR_CASE(EnumType, CxxType) \
            case CppType::CPPTYPE_ ## EnumType : \
                WriteRegular<CxxType>(message, field, luaIndex); \
                break;

    const auto fieldCppType = field->cpp_type();
    switch (fieldCppType)
    {
        WRITE_REGULAR_CASE(INT32, pb::int32);
        WRITE_REGULAR_CASE(INT64, pb::int64);
        WRITE_REGULAR_CASE(UINT32, pb::uint32);
        WRITE_REGULAR_CASE(UINT64, pb::uint64);
        WRITE_REGULAR_CASE(DOUBLE, double);
        WRITE_REGULAR_CASE(FLOAT, float);
        WRITE_REGULAR_CASE(BOOL, bool);
        WRITE_REGULAR_CASE(ENUM, pb_enum);
        WRITE_REGULAR_CASE(STRING, std::string);
        WRITE_REGULAR_CASE(MESSAGE, pb::Message);

        default:
            checkf(false, TEXT("Invalid CppType %d"), (int32)fieldCppType);
            break;
    }

    #undef WRITE_REGULAR_CASE
}

void FLuaTableToMessageHelper::WriteRepeatedField(pb::Message* message, const pb::FieldDescriptor* field, int32 luaIndex)
{
    #define WRITE_REPEATED_CASE(EnumType, CxxType) \
        case CppType::CPPTYPE_ ## EnumType : \
            WriteRepeated<CxxType>(message, field, luaIndex); \
            break;    

    const auto fieldCppType = field->cpp_type();
    switch (fieldCppType)
    {
        WRITE_REPEATED_CASE(INT32, pb::int32);
        WRITE_REPEATED_CASE(INT64, pb::int64);
        WRITE_REPEATED_CASE(UINT32, pb::uint32);
        WRITE_REPEATED_CASE(UINT64, pb::uint64);
        WRITE_REPEATED_CASE(DOUBLE, double);
        WRITE_REPEATED_CASE(FLOAT, float);
        WRITE_REPEATED_CASE(BOOL, bool);
        WRITE_REPEATED_CASE(ENUM, pb::int32);
        WRITE_REPEATED_CASE(STRING, std::string);
        WRITE_REPEATED_CASE(MESSAGE, pb::Message);

        default:
            checkf(false, TEXT("Invalid CppType %d"), (uint32)fieldCppType);
            break;
    }

    #undef WRITE_REPEATED_CASE
}

class MessageToLuaTableHelper
{
public:

    MessageToLuaTableHelper(lua_State* InL);

    int ToLuaTable(const pb::Message* message);

private:

    template <typename T>
    void ReadRepeated(const pb::Message* message, const pb::FieldDescriptor* field, int32 luaIndex);

    template <typename T>
    void ReadRegular(const pb::Message* message, const pb::FieldDescriptor* field);

private:

    void ReadRepeatedField(const pb::Message* message, const pb::FieldDescriptor* field);
    void ReadRegularField(const pb::Message* message, const pb::FieldDescriptor* field);

private:
    lua_State* L;
};

MessageToLuaTableHelper::MessageToLuaTableHelper(lua_State* InL)
    : L(InL)
{
}

int MessageToLuaTableHelper::ToLuaTable(const pb::Message* message)
{
    lua_newtable(L);

    auto descriptor = message->GetDescriptor();
    const int fieldCount = descriptor->field_count();
    for (int i = 0; i < fieldCount; ++i)
    {
        auto field = descriptor->field(i);
        lua_pushstring(L, field->name().c_str());

        if (field->is_repeated())
            ReadRepeatedField(message, field);
        else
            ReadRegularField(message, field);
    }

    return 1;
}

template <typename T>
void MessageToLuaTableHelper::ReadRepeated(const pb::Message* message, const pb::FieldDescriptor* field, int32 luaIndex)
{
    static_assert(always_false<T>::value, "No specialization exists!");
}

template <>
FORCEINLINE void MessageToLuaTableHelper::ReadRepeated<pb::int32>(const pb::Message* message, const pb::FieldDescriptor* field, int32 luaIndex)
{
    auto reflection = message->GetReflection();
    auto repeatedField = reflection->GetRepeatedFieldRef<pb::int32>(*message, field);
    const auto fieldSize = repeatedField.size();
    for (int j = 0; j < fieldSize; ++j)
    {
        auto indexValue = repeatedField.Get(j);
        lua_pushinteger(L, indexValue);
        lua_rawseti(L, luaIndex, j + 1);
    }
}

template <>
FORCEINLINE void MessageToLuaTableHelper::ReadRepeated<pb::int64>(const pb::Message* message, const pb::FieldDescriptor* field, int32 luaIndex)
{
    auto reflection = message->GetReflection();
    auto repeatedField = reflection->GetRepeatedFieldRef<pb::int64>(*message, field);
    const auto fieldSize = repeatedField.size();
    for (int j = 0; j < fieldSize; ++j)
    {
        auto indexValue = repeatedField.Get(j);
        lua_pushinteger(L, indexValue);
        lua_rawseti(L, luaIndex, j + 1);
    }
}

template <>
FORCEINLINE void MessageToLuaTableHelper::ReadRepeated<pb::uint32>(const pb::Message* message, const pb::FieldDescriptor* field, int32 luaIndex)
{
    auto reflection = message->GetReflection();
    auto repeatedField = reflection->GetRepeatedFieldRef<pb::uint32>(*message, field);
    const auto fieldSize = repeatedField.size();
    for (int j = 0; j < fieldSize; ++j)
    {
        auto indexValue = repeatedField.Get(j);
        lua_pushunsigned(L, indexValue);
        lua_rawseti(L, luaIndex, j + 1);
    }
}

template <>
FORCEINLINE void MessageToLuaTableHelper::ReadRepeated<pb::uint64>(const pb::Message* message, const pb::FieldDescriptor* field, int32 luaIndex)
{
    auto reflection = message->GetReflection();
    auto repeatedField = reflection->GetRepeatedFieldRef<pb::uint64>(*message, field);
    const auto fieldSize = repeatedField.size();
    for (int j = 0; j < fieldSize; ++j)
    {
        auto indexValue = repeatedField.Get(j);
        lua_pushunsigned(L, indexValue);
        lua_rawseti(L, luaIndex, j + 1);
    }
}

template <>
FORCEINLINE void MessageToLuaTableHelper::ReadRepeated<double>(const pb::Message* message, const pb::FieldDescriptor* field, int32 luaIndex)
{
    auto reflection = message->GetReflection();
    auto repeatedField = reflection->GetRepeatedFieldRef<double>(*message, field);
    const auto fieldSize = repeatedField.size();
    for (int j = 0; j < fieldSize; ++j)
    {
        auto indexValue = repeatedField.Get(j);
        lua_pushnumber(L, indexValue);
        lua_rawseti(L, luaIndex, j + 1);
    }
}

template <>
FORCEINLINE void MessageToLuaTableHelper::ReadRepeated<float>(const pb::Message* message, const pb::FieldDescriptor* field, int32 luaIndex)
{
    auto reflection = message->GetReflection();
    auto repeatedField = reflection->GetRepeatedFieldRef<float>(*message, field);
    const auto fieldSize = repeatedField.size();
    for (int j = 0; j < fieldSize; ++j)
    {
        auto indexValue = repeatedField.Get(j);
        lua_pushnumber(L, indexValue);
        lua_rawseti(L, luaIndex, j + 1);
    }
}

template <>
FORCEINLINE void MessageToLuaTableHelper::ReadRepeated<bool>(const pb::Message* message, const pb::FieldDescriptor* field, int32 luaIndex)
{
    auto reflection = message->GetReflection();
    auto repeatedField = reflection->GetRepeatedFieldRef<bool>(*message, field);
    const auto fieldSize = repeatedField.size();
    for (int j = 0; j < fieldSize; ++j)
    {
        auto indexValue = repeatedField.Get(j);
        lua_pushboolean(L, indexValue ? 1 : 0);
        lua_rawseti(L, luaIndex, j + 1);
    }
}

template <>
FORCEINLINE void MessageToLuaTableHelper::ReadRepeated<pb_enum>(const pb::Message* message, const pb::FieldDescriptor* field, int32 luaIndex)
{
    auto reflection = message->GetReflection();
    auto repeatedField = reflection->GetRepeatedFieldRef<pb::int32>(*message, field);
    const auto fieldSize = repeatedField.size();
    for (int j = 0; j < fieldSize; ++j)
    {
        auto indexValue = repeatedField.Get(j);
        lua_pushinteger(L, indexValue);
        lua_rawseti(L, luaIndex, j + 1);
    }
}

template <>
FORCEINLINE void MessageToLuaTableHelper::ReadRepeated<std::string>(const pb::Message* message, const pb::FieldDescriptor* field, int32 luaIndex)
{
    auto reflection = message->GetReflection();
    auto repeatedField = reflection->GetRepeatedFieldRef<std::string>(*message, field);
    const auto fieldSize = repeatedField.size();
    for (int j = 0; j < fieldSize; ++j)
    {
        auto indexValue = repeatedField.Get(j);
        lua_pushstring(L, indexValue.c_str());
        lua_rawseti(L, luaIndex, j + 1);
    }
}

template <>
FORCEINLINE void MessageToLuaTableHelper::ReadRepeated<pb::Message>(const pb::Message* message, const pb::FieldDescriptor* field, int32 luaIndex)
{
    auto reflection = message->GetReflection();
    auto repeatedField = reflection->GetRepeatedFieldRef<pb::Message>(*message, field);
    const auto fieldSize = repeatedField.size();
    for (int j = 0; j < fieldSize; ++j)
    {
        const auto& subMessage = repeatedField.Get(j, nullptr);
        ToLuaTable(&subMessage);
        lua_rawseti(L, luaIndex, j + 1);
    }
}

template <typename T>
void MessageToLuaTableHelper::ReadRegular(const pb::Message* message, const pb::FieldDescriptor* field)
{
    static_assert(always_false<T>::value, "No specialization exists!");
}

template <>
FORCEINLINE void MessageToLuaTableHelper::ReadRegular<pb::int32>(const pb::Message* message, const pb::FieldDescriptor* field)
{
    auto reflection = message->GetReflection();
    lua_pushinteger(L, reflection->GetInt32(*message, field));
    lua_rawset(L, -3);
}

template <>
FORCEINLINE void MessageToLuaTableHelper::ReadRegular<pb::int64>(const pb::Message* message, const pb::FieldDescriptor* field)
{
    auto reflection = message->GetReflection();
    lua_pushinteger(L, reflection->GetInt64(*message, field));
    lua_rawset(L, -3);
}

template <>
FORCEINLINE void MessageToLuaTableHelper::ReadRegular<pb::uint32>(const pb::Message* message, const pb::FieldDescriptor* field)
{
    auto reflection = message->GetReflection();
    lua_pushunsigned(L, reflection->GetUInt32(*message, field));
    lua_rawset(L, -3);
}

template <>
FORCEINLINE void MessageToLuaTableHelper::ReadRegular<pb::uint64>(const pb::Message* message, const pb::FieldDescriptor* field)
{
    auto reflection = message->GetReflection();
    lua_pushunsigned(L, reflection->GetUInt64(*message, field));
    lua_rawset(L, -3);
}

template <>
FORCEINLINE void MessageToLuaTableHelper::ReadRegular<double>(const pb::Message* message, const pb::FieldDescriptor* field)
{
    auto reflection = message->GetReflection();
    lua_pushnumber(L, reflection->GetDouble(*message, field));
    lua_rawset(L, -3);
}

template <>
FORCEINLINE void MessageToLuaTableHelper::ReadRegular<float>(const pb::Message* message, const pb::FieldDescriptor* field)
{
    auto reflection = message->GetReflection();
    lua_pushnumber(L, reflection->GetFloat(*message, field));
    lua_rawset(L, -3);
}

template <>
FORCEINLINE void MessageToLuaTableHelper::ReadRegular<bool>(const pb::Message* message, const pb::FieldDescriptor* field)
{
    auto reflection = message->GetReflection();
    lua_pushboolean(L, reflection->GetBool(*message, field) ? 1 : 0);
    lua_rawset(L, -3);
}

template <>
FORCEINLINE void MessageToLuaTableHelper::ReadRegular<pb_enum>(const pb::Message* message, const pb::FieldDescriptor* field)
{
    auto reflection = message->GetReflection();
    lua_pushinteger(L, reflection->GetEnumValue(*message, field));
    lua_rawset(L, -3);
}

template <>
FORCEINLINE void MessageToLuaTableHelper::ReadRegular<std::string>(const pb::Message* message, const pb::FieldDescriptor* field)
{
    auto reflection = message->GetReflection();
    lua_pushstring(L, reflection->GetString(*message, field).c_str());
    lua_rawset(L, -3);
}

template <>
FORCEINLINE void MessageToLuaTableHelper::ReadRegular<pb::Message>(const pb::Message* message, const pb::FieldDescriptor* field)
{
    auto reflection = message->GetReflection();
    const auto& subMessage = reflection->GetMessage(*message, field);
    ToLuaTable(&subMessage);
    lua_rawset(L, -3);
}

void MessageToLuaTableHelper::ReadRepeatedField(const pb::Message* message, const pb::FieldDescriptor* field)
{
    #define READ_REPEATED_CASE(EnumType, CxxType) \
        case CppType::CPPTYPE_ ## EnumType : \
            ReadRepeated<CxxType>(message, field, luaIndex); \
            break;

    lua_newtable(L);
    const int32 luaIndex = lua_gettop(L);

    const auto fieldCppType = field->cpp_type();
    switch (fieldCppType)
    {
        READ_REPEATED_CASE(INT32, pb::int32);
        READ_REPEATED_CASE(INT64, pb::int64);
        READ_REPEATED_CASE(UINT32, pb::uint32);
        READ_REPEATED_CASE(UINT64, pb::uint64);
        READ_REPEATED_CASE(DOUBLE, double);
        READ_REPEATED_CASE(FLOAT, float);
        READ_REPEATED_CASE(BOOL, bool);
        READ_REPEATED_CASE(ENUM, pb::int32);
        READ_REPEATED_CASE(STRING, std::string);
        READ_REPEATED_CASE(MESSAGE, pb::Message);

    default:
        checkf(false, TEXT("Invalid CppType %d"), (int32)fieldCppType);
        break;
    }

    lua_rawset(L, -3);

    #undef READ_REPEATED_CASE
}

void MessageToLuaTableHelper::ReadRegularField(const pb::Message* message, const pb::FieldDescriptor* field)
{
    #define READ_REGULAR_CASE(EnumType, CxxType) \
            case CppType::CPPTYPE_ ## EnumType : \
                ReadRegular<CxxType>(message, field); \
                break;

    const auto fieldCppType = field->cpp_type();
    switch (fieldCppType)
    {
        READ_REGULAR_CASE(INT32, pb::int32);
        READ_REGULAR_CASE(INT64, pb::int64);
        READ_REGULAR_CASE(UINT32, pb::uint32);
        READ_REGULAR_CASE(UINT64, pb::uint64);
        READ_REGULAR_CASE(DOUBLE, double);
        READ_REGULAR_CASE(FLOAT, float);
        READ_REGULAR_CASE(BOOL, bool);
        READ_REGULAR_CASE(ENUM, pb_enum);
        READ_REGULAR_CASE(STRING, std::string);
        READ_REGULAR_CASE(MESSAGE, pb::Message);

        default:
            checkf(false, TEXT("Invalid CppType %d"), (int32)fieldCppType);
            break;
    }

    #undef READ_REGULAR_CASE
}

int FMessageLuaUtil::MessageToLuaTable(const pb::Message* Message, lua_State* L)
{
    if (Message == nullptr || L == nullptr)
        return 0;

    MessageToLuaTableHelper helper(L);
    return helper.ToLuaTable(Message);
}

const pb::Message* FMessageLuaUtil::LuaTableToMessage(ProtobufCodec* Codec, const FString& MessageName, FLuaTableRef* Table)
{
    check(Codec != nullptr);

    std::string MessageNameUTF8(TCHAR_TO_UTF8(*MessageName));

    // Table is allowed to be nullptr (nil in lua)
    if (Table == nullptr)
        return Codec->CreateMessage(MessageNameUTF8);

    FLuaTableToMessageHelper Helper(Codec, Table);
    auto Message = Helper.ToMessage(MessageNameUTF8);

    return Message;
}

bool FMessageLuaUtil::LuaTableToRawBuffer(
    ProtobufCodec* Codec,
    const FString& MessageName,
    FLuaTableRef* Table,
    FString* DebugInfo,
    uint8* Buffer,
    int32 BufferMaxSize,
    int32& OutMessageSize,
    bool UseProtoFrame)
{
    check(Codec != nullptr);

    auto Message = LuaTableToMessage(Codec, MessageName, Table);
    if (Message == nullptr)
    {
        UE_LOG(MessageLuaUtilLog, Error, TEXT("MessageLuaUtil::LuaTableToRawData create message failed %s"), *MessageName);
        return false;
    }

    bool bRet = false;
    if (UseProtoFrame)
    {
        bRet = Codec->Encode(*Message, Buffer, BufferMaxSize, OutMessageSize);
    }
    else
    {
        bRet = Codec->EncodeWithoutFrame(*Message, Buffer, BufferMaxSize, OutMessageSize);
    }
    
    if(!bRet)
    {
        UE_LOG(MessageLuaUtilLog, Error, TEXT("MessageLuaUtil::LuaTableToRawData encode failed, [%s]"), *MessageName);
    }
    else if (DebugInfo)
    {
        *DebugInfo = UTF8_TO_TCHAR(Message->Utf8DebugString().c_str());
    }

    Codec->DestroyMessage(Message);
    return bRet;
}

bool FMessageLuaUtil::LuaTableToArrayData(
    ProtobufCodec* Codec,
    const FString& MessageName,
    FLuaTableRef* Table,
    FString* DebugInfo,
    TArray<uint8>& OutRawData,
    bool UseProtoFrame)
{
    int32 MessageSize = 0;
	FString Temp;
    uint8 TempBuffer[kEncodeBufferSize];
    bool bRet = LuaTableToRawBuffer(Codec,
        MessageName,
        Table,
        DebugInfo,
        TempBuffer,
        sizeof(TempBuffer),
        MessageSize,
        UseProtoFrame);

	if (bRet)
	{
        OutRawData.Empty(MessageSize);
        OutRawData.Append(TempBuffer, MessageSize);        
	}
    return bRet;
}

bool FMessageLuaUtil::LuaTableToTempBuffer(
    ProtobufCodec* Codec,
    const FString& MessageName,
    FLuaTableRef* Table,
    FString* DebugInfo,
    FTempRawBuffer& OutRawData,
    bool UseProtoFrame)
{
    int32 MessageSize = 0;
    uint8 TempBuffer[kEncodeBufferSize];
    bool bRet = LuaTableToRawBuffer(Codec,
        MessageName,
        Table,
        DebugInfo,
        TempBuffer,
        sizeof(TempBuffer),
        MessageSize,
        UseProtoFrame);

    if (bRet)
    {
        OutRawData.Empty(MessageSize);
        OutRawData.Append(TempBuffer, MessageSize);
    }
    return bRet;
}
