#pragma once

class COMMON_API FDataObfuscationUtil
{
public:
    static void XOR(float& Dest, float Src);
    static void XOR(int64& Dest, int64 Src);
    static void XOR(uint8* Dest, const uint8* Src, uint32 Len);

    static void Zip(TArray<uint8>& Dest, const uint8* Src, uint32 SrcLen);
    static void UnZip(TArray<uint8>& Dest, const uint8* Src, uint32 SrcLen);

    // 通过增加冗余位对数据进行混淆
    static void ObfuscateWithRedundancy(TArray<uint8>& Dest, const uint8* Src, uint32 SrcLen);
    static void DeobfuscateWithRedundancy(TArray<uint8>& Dest, const uint8* Src, uint32 SrcLen);
};