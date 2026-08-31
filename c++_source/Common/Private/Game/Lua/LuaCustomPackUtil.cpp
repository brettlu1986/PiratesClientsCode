#include "LuaCustomPackUtil.h"
#include "Common.h"
#include "lua.hpp"
#include "Serialization/MemoryWriter.h"
#include "Serialization/MemoryReader.h"


DEFINE_LOG_CATEGORY_STATIC(LogLuaCustomPackUtil, Log, All);

#define MAX_PARAM_COUNT 30

class FLuaCustomPackUtilImpl
{
    enum class LuaCustomPackFlag : int8
    {
        None,
        LuaNil,  // can not use Nil, because of the macro "#define Nil nullptr" in macOS SDK
        Boolean,
        Integer,
        Float,
        String,
        TableBegin, // normal table begin 
        TableArrayBegin, // table with sequence begin
        ArrayEnd,     // sequence in table end
        TableEnd    // table end
    };

public:

    static bool UnpackLuaValue(lua_State* L, FMemoryReader& Reader)
    {
        LuaCustomPackFlag t = UnpackFlagType(Reader);
        bool bResult = UnpackLuaValue(L, Reader, t);
        return bResult;
    }

    static bool PackLuaValue(lua_State* L, int index, FMemoryWriter& Writer)
    {
        int t = lua_type(L, index);
        return PackLuaValue(L, index, Writer, t);
    }

private:

    static bool UnpackLuaValue(lua_State* L, FMemoryReader& Reader, LuaCustomPackFlag FlagType)
    {
        bool bResult = true;
        switch (FlagType)
        {
        case LuaCustomPackFlag::LuaNil:
            bResult = UnpackToLuaNil(L, Reader);
            break;
        case LuaCustomPackFlag::Boolean:
            bResult = UnpackToLuaBoolean(L, Reader);
            break;
        case LuaCustomPackFlag::Integer:
            bResult = UnpackToLuaInteger(L, Reader);
            break;
        case LuaCustomPackFlag::Float:
            bResult = UnpackToLuaFloat(L, Reader);
            break;
        case LuaCustomPackFlag::String:
            bResult = UnpackToLuaString(L, Reader);
            break;
        case LuaCustomPackFlag::TableArrayBegin:
            bResult = UnpackToLuaTable(L, Reader, true);
            break;
        case LuaCustomPackFlag::TableBegin:
            bResult = UnpackToLuaTable(L, Reader, false);
            break;
        default:
        {
            int8 FlagTypeValue = static_cast<int8>(FlagType);
            UE_LOG(LogLuaCustomPackUtil, Error, TEXT("UnpackLuaValue type error, type : %d"), FlagTypeValue);
            bResult = false;
            break;
        }
        }
        return bResult;
    }

    static LuaCustomPackFlag UnpackFlagType(FMemoryReader& Reader)
    {
        int8 FlagValue = 0;
        Reader << FlagValue;
        LuaCustomPackFlag FlagType = (LuaCustomPackFlag)FlagValue;
        return FlagType;
    }

    static bool UnpackToLuaInteger(lua_State* L, FMemoryReader& Reader)
    {
        int64 iValue = 0;
        Reader << iValue;
        if (!Reader.IsError() && lua_checkstack(L, 1) != 0)
        {
            lua_pushinteger(L, iValue);
            return true;
        }
        else
        {
            return false;
        }
    }

    static bool UnpackToLuaFloat(lua_State* L, FMemoryReader& Reader)
    {
        double fValue = 0.0;
        Reader << fValue;
        if (!Reader.IsError() && lua_checkstack(L, 1) != 0)
        {
            lua_pushnumber(L, fValue);
            return true;
        }
        else
        {
            return false;
        }
    }

    static bool UnpackToLuaNil(lua_State* L, FMemoryReader& Reader)
    {
        if (lua_checkstack(L, 1) != 0)
        {
            lua_pushnil(L);
            return true;
        }
        else
        {
            return false;
        }
    }

    static bool UnpackToLuaBoolean(lua_State* L, FMemoryReader& Reader)
    {
        bool bValue = false;
        Reader << bValue;
        if (!Reader.IsError() && lua_checkstack(L, 1) != 0)
        {
            lua_pushboolean(L, bValue ? 1 : 0);
            return true;
        }
        else
        {
            return false;
        }
    }

    static bool UnpackToLuaString(lua_State* L, FMemoryReader& Reader)
    {
        FString Temp;
        Reader << Temp;
        if (!Reader.IsError() && lua_checkstack(L, 1) != 0)
        {
            lua_pushstring(L, TCHAR_TO_UTF8(Temp.GetCharArray().GetData()));
            return true;
        }
        else
        {
            return false;
        }
    }

    static bool UnpackToLuaTable(lua_State* L, FMemoryReader& Reader, bool HasArrayPart)
    {
        lua_newtable(L);
        if (HasArrayPart)
        {
            int i = 1;
            while (true)
            {
                LuaCustomPackFlag TempType = UnpackFlagType(Reader);
                if (TempType == LuaCustomPackFlag::ArrayEnd)
                {
                    break;
                }
                lua_pushinteger(L, i); // numerical key
                if (!UnpackLuaValue(L, Reader, TempType))// value
                {
                    return false;
                }
                lua_settable(L, -3);
                i++;
            }
        }
        while (true)
        {
            LuaCustomPackFlag FlagType = UnpackFlagType(Reader);
            if (FlagType == LuaCustomPackFlag::TableEnd)
            {
                break;
            }
            if (!UnpackLuaValue(L, Reader, FlagType) || !UnpackLuaValue(L, Reader))
            {
                return false;
            }
            lua_settable(L, -3);
        }
        return true;
    }

    static bool PackLuaValue(lua_State* L, int index, FMemoryWriter& Writer, int LuaValueType)
    {
        bool bResult = true;
        switch (LuaValueType)
        {
        case LUA_TNIL:
        {
            bResult = PackLuaNil(L, index, Writer);
            break;
        }
        case LUA_TNUMBER:
        {
            bResult = PackLuaNumber(L, index, Writer);
            break;
        }
        case LUA_TBOOLEAN:
        {
            bResult = PackLuaBoolean(L, index, Writer);
            break;
        }
        case LUA_TSTRING:
        {
            bResult = PackLuaString(L, index, Writer);
            break;
        }
        case LUA_TTABLE:
        {
            bResult = PackLuaTable(L, index, Writer);
            break;
        }
        default:
        {
            bResult = false;
            UE_LOG(LogLuaCustomPackUtil, Error, TEXT("The type of value to pack is invalid, invalid type : %d"), LuaValueType);
            break;
        }
        }
        return bResult;
    }

    static bool PackLuaNumber(lua_State* L, int ValueIndex, FMemoryWriter& Writer)
    {
        if (lua_isinteger(L, ValueIndex)) // Serialize for integer
        {
            PackFlag(Writer, LuaCustomPackFlag::Integer);
            int64 iValue = lua_tointeger(L, ValueIndex);
            Writer << iValue;
        }
        else // Serialize for float
        {
            PackFlag(Writer, LuaCustomPackFlag::Float);
            double dValue = lua_tonumber(L, ValueIndex);
            Writer << dValue;
        }
        return !Writer.IsError();
    }

    static bool PackLuaString(lua_State* L, int ValueIndex, FMemoryWriter& Writer)
    {
        PackFlag(Writer, LuaCustomPackFlag::String);
        FString TempValue(UTF8_TO_TCHAR(lua_tostring(L, ValueIndex)));
        Writer << TempValue;
        return !Writer.IsError();
    }

    static bool PackLuaNil(lua_State* L, int ValueIndex, FMemoryWriter& Writer)
    {
        PackFlag(Writer, LuaCustomPackFlag::LuaNil);
        // do nothing
        return !Writer.IsError();
    }

    static bool PackLuaBoolean(lua_State* L, int ValueIndex, FMemoryWriter& Writer)
    {
        PackFlag(Writer, LuaCustomPackFlag::Boolean);
        bool bValue = lua_toboolean(L, ValueIndex) != 0;
        Writer << bValue;
        return !Writer.IsError();
    }

    static bool PackLuaTable(lua_State* L, int TableStackIndex, FMemoryWriter& Writer)
    {
        bool bCheckResult = lua_checkstack(L, 1) != 0;
        if (!bCheckResult)
        {
            UE_LOG(LogLuaCustomPackUtil, Error, TEXT("The lua stack does not have enough space"));
            return false;
        }

        int i = 1;
        // firstly,  traverse sequence part
        while (true)
        {
            int t = lua_geti(L, TableStackIndex, i);
            if (t != LUA_TNIL)
            {
                // serialize array begin
                if (i == 1)
                {
                    PackFlag(Writer, LuaCustomPackFlag::TableArrayBegin);
                }
                if (!PackLuaValue(L, -1, Writer, t))
                {
                    return false;
                }
                lua_pop(L, 1);
            }
            else //loop until nil
            {
                if (i > 1)
                {
                    PackFlag(Writer, LuaCustomPackFlag::ArrayEnd);
                }
                lua_pop(L, 1);
                break;
            }
            i++;
        }
        if (i == 1)
        {
            PackFlag(Writer, LuaCustomPackFlag::TableBegin);
        }

        // next, traverse hash part
        bCheckResult = lua_checkstack(L, 2) != 0;
        if (!bCheckResult)
        {
            UE_LOG(LogLuaCustomPackUtil, Error, TEXT("The lua stack does not have enough space"));
            return false;
        }

        lua_pushnil(L);  // push first key
        if (TableStackIndex < 0)
            TableStackIndex--;
        while (lua_next(L, TableStackIndex) != 0)
        {
            if (lua_isinteger(L, -2) == 0 || lua_tointeger(L, -2) <= 0 || lua_tointeger(L, -2) > i) // filter sequence part before
            {
                bool bResult = true;
                bResult &= PackLuaValue(L, -2, Writer);   // serialize key
                bResult &= PackLuaValue(L, -1, Writer);   // serialize value
                if (!bResult)
                {
                    return false;
                }
            }
            lua_pop(L, 1);
        }
        PackFlag(Writer, LuaCustomPackFlag::TableEnd);
        return true;
    }

    static void PackFlag(FMemoryWriter& Writer, LuaCustomPackFlag FlagType)
    {
        int8 FlagValue = static_cast<int8>(FlagType);
        Writer << FlagValue;
    }
};


bool FLuaCustomPackUtil::Pack(lua_State* L, TArray<uint8>& TargetData)
{
    check(TargetData.Num() == 0);
    FMemoryWriter Writer(TargetData);
    int ParamCount = lua_gettop(L);
    bool bResult = true;
    if (ParamCount > MAX_PARAM_COUNT)
    {
        UE_LOG(LogLuaCustomPackUtil, Error, TEXT("Parameter's count should less than %d"), MAX_PARAM_COUNT);
        bResult = false;
    }
    else
    {
        for (int i = 1; i <= ParamCount; i++)
        {
            bResult = FLuaCustomPackUtilImpl::PackLuaValue(L, i, Writer);
            if (!bResult)
                break;
        }
    }
    return bResult;
}

bool FLuaCustomPackUtil::Unpack(lua_State* L, const TArray<uint8>& SourceData, int& OutParamCount)
{
    FMemoryReader Reader(SourceData);
    OutParamCount = 0;
    int originTop = lua_gettop(L);
    while (Reader.Tell() < SourceData.Num())
    {
        bool bResult = FLuaCustomPackUtilImpl::UnpackLuaValue(L, Reader);
        if (!bResult || Reader.IsError())
        {
            lua_settop(L, originTop);
            OutParamCount = 0;
            return false;
        }
        else
        {
            OutParamCount++;
        }
    }
    return true;
}




