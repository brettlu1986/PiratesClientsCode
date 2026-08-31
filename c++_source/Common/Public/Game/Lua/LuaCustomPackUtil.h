#pragma once

struct lua_State;

class COMMON_API FLuaCustomPackUtil
{
public:
    static bool Pack(lua_State* L, TArray<uint8>& TargetData);
    static bool Unpack(lua_State* L, const TArray<uint8>& SourceData, int& OutParamCount);
};