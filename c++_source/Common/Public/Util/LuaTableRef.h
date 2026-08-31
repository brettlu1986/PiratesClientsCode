#pragma once

#include <string>

#include "lua.hpp"
#include "LuaTableRef.generated.h"

class COMMON_API FLuaUtil
{
private:

    // Helper template for static_assert
    template <typename T>
    struct always_false
    {
        static constexpr bool value = false;
    };

public:

    template<typename T>
    static bool GetLuaValue(lua_State* L, T &outValue)
    {
        // This is intentional
        static_assert(always_false<T>::value, "No specialization exists!");
    }
};

struct COMMON_API FLuaTableRef
{
    FLuaTableRef(const FLuaTableRef& Other) = delete;
    FLuaTableRef(lua_State* State, int TableIndex)
    {
        L = State;
        RefID = LUA_REFNIL;
        if (L)
        {
            luaL_checktype(L, TableIndex, LUA_TTABLE);
            lua_pushvalue(L, TableIndex);
            RefID = luaL_ref(L, LUA_REGISTRYINDEX);
        }
    }
    ~FLuaTableRef()
    {
        if (L)
        {
            luaL_unref(L, LUA_REGISTRYINDEX, RefID);
            RefID = LUA_REFNIL;
        }
    }

    template<typename T>
    bool ReadTableForKey(const std::string& key, T &outValue, int32 index)
    {
        bool ret = false;
        lua_pushstring(L, key.c_str());
        lua_rawget(L, index);

        ret = FLuaUtil::GetLuaValue<T>(L, outValue);

        lua_pop(L, 1);

        return ret;
    }

    template<typename T>
    bool ReadTableForIndex(const int32& keyIndex, T &outValue, int32 luaIndex)
    {
        bool ret = false;
        lua_rawgeti(L, luaIndex, keyIndex);

        ret = FLuaUtil::GetLuaValue<T>(L, outValue);

        lua_pop(L, 1);

        return ret;
    }

    int32 BeginReadSubTable(const std::string& key, int32 index)
    {
        lua_pushstring(L, key.c_str());
        lua_rawget(L, index);
        return lua_gettop(L);
    }

    // return stack index
    int32 BeginReadTable()
    {
        lua_rawgeti(L, LUA_REGISTRYINDEX, RefID);
        return lua_gettop(L);
    }

    void EndReadTable()
    {
        lua_pop(L, 1);
    }

    lua_State* L;
    int RefID;
};

UCLASS()
class COMMON_API ULuaTableRef : public UObject
{
    GENERATED_BODY()

public:

    TSharedPtr<struct FLuaTableRef> TableRef;
};

#define LUA_TABLE_REF_U2F(UPtr) ((UPtr) != nullptr ? (UPtr)->TableRef.Get() : nullptr)

template<>
inline bool FLuaUtil::GetLuaValue<int32>(lua_State* L, int32 &outValue)
{
    if (!lua_isinteger(L, -1))
    {
        return false;
    }
    outValue = (int32)lua_tointeger(L, -1);
    return true;
}

template<>
inline bool FLuaUtil::GetLuaValue<int64>(lua_State* L, int64 &outValue)
{
    if (!lua_isinteger(L, -1))
    {
        return false;
    }
    outValue = (int64)lua_tointeger(L, -1);
    return true;
}

template<>
inline bool FLuaUtil::GetLuaValue<uint32>(lua_State* L, uint32 &outValue)
{
    if (!lua_isinteger(L, -1))
    {
        return false;
    }
    outValue = (uint32)lua_tounsigned(L, -1);
    return true;
}

template<>
inline bool FLuaUtil::GetLuaValue<uint64>(lua_State* L, uint64 &outValue)
{
    if (!lua_isinteger(L, -1))
    {
        return false;
    }
    outValue = (uint64)lua_tounsigned(L, -1);
    return true;
}

template<>
inline bool FLuaUtil::GetLuaValue<long>(lua_State* L, long &outValue)
{
    if (!lua_isinteger(L, -1))
    {
        return false;
    }
    outValue = (long)lua_tointeger(L, -1);
    return true;
}

template<>
inline bool FLuaUtil::GetLuaValue<unsigned long>(lua_State* L, unsigned long &outValue)
{
    if (!lua_isinteger(L, -1))
    {
        return false;
    }
    outValue = (unsigned long)lua_tounsigned(L, -1);
    return true;
}

template<>
inline bool FLuaUtil::GetLuaValue<double>(lua_State* L, double &outValue)
{
    if (!lua_isnumber(L, -1))
    {
        return false;
    }
    outValue = (double)lua_tonumber(L, -1);
    return true;
}

template<>
inline bool FLuaUtil::GetLuaValue<float>(lua_State* L, float &outValue)
{
    if (!lua_isnumber(L, -1))
    {
        return false;
    }
    outValue = (float)lua_tonumber(L, -1);
    return true;
}

template<>
inline bool FLuaUtil::GetLuaValue<bool>(lua_State* L, bool &outValue)
{
    if (!lua_isboolean(L, -1))
    {
        return false;
    }

    outValue = (lua_toboolean(L, -1)) == 0 ? false : true;
    return true;
}

template<>
inline bool FLuaUtil::GetLuaValue<std::string>(lua_State* L, std::string &outValue)
{
    if (!lua_isstring(L, -1))
    {
        return false;
    }

    outValue = lua_tostring(L, -1);
    return true;
}
