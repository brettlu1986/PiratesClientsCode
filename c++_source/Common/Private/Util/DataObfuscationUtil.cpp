
#include "Util/DataObfuscationUtil.h"
#include "Common.h"

#if ENABLE_GAME_MESSAGE_OBFUSCATION
THIRD_PARTY_INCLUDES_START
#include "ThirdParty/zlib/zlib-1.2.5/Inc/zlib.h"
THIRD_PARTY_INCLUDES_END
#endif

//////////////////////////////////////////////////////////////////////////
static const uint8 XOR_KEY8 = 0xcd;
static const uint16 XOR_KEY16 = 0xcdcd;
static const uint32 XOR_KEY32 = 0xcdcdcdcd;
static const uint64 XOR_KEY64 = 0xcdcdcdcdcdcdcdcd;

void FDataObfuscationUtil::XOR(float& Dest, float Src)
{
    *(int32*)&Dest = *(int32*)&Src ^ XOR_KEY32;
}

void FDataObfuscationUtil::XOR(int64& Dest, int64 Src)
{
    Dest = Src ^ XOR_KEY64;
}

void FDataObfuscationUtil::XOR(uint8* Dest, const uint8* Src, uint32 Len)
{
    for (uint32 ii = 0; ii < Len; ++ii)
    {
        Dest[ii] = Src[ii] ^ XOR_KEY8;
    }
}

//////////////////////////////////////////////////////////////////////////
void FDataObfuscationUtil::Zip(TArray<uint8>& Dest, const uint8* Src, uint32 SrcLen)
{
#if ENABLE_GAME_MESSAGE_OBFUSCATION
    check(SrcLen < 65535);
    unsigned long ComporessSize = compressBound(SrcLen);
    Dest.SetNumUninitialized(ComporessSize + 2, false);
    *(uint16*)&Dest[0] = (uint16)SrcLen;
    int32 Error = compress(&Dest[2], &ComporessSize, Src, SrcLen);
    checkf(Error == Z_OK, TEXT("FDataObfuscationUtil zlib failed to compress, which is very unexpected (err = %d)"), Error);
    Dest.SetNumUninitialized(ComporessSize + 2, false);
#else
    check(0);
#endif
}

void FDataObfuscationUtil::UnZip(TArray<uint8>& Dest, const uint8* Src, uint32 SrcLen)
{
#if ENABLE_GAME_MESSAGE_OBFUSCATION
    check(SrcLen >= 2);
    unsigned long OutDataSize = *(uint16*)Src;
    Dest.SetNumUninitialized(OutDataSize, false);
    uncompress(Dest.GetData(), &OutDataSize, &Src[2], SrcLen - 2);
#else
    check(0);
#endif
}

//////////////////////////////////////////////////////////////////////////
struct FObfuscationWithRedundancy
{
    static const uint32 const_r_u32 = 0xa5e3b0c6;  // 随机数

    // UINT_X's width must be less than sizeof(uint32), it can be uint8 or uint16
    template <typename UINT_X>
    inline static uint32 obfuscate32(UINT_X const& val, uint32 const& r_u32) {
        if (sizeof(uint32) <= sizeof(UINT_X)) return val;
        uint32 rr = 0;
        uint8 b[sizeof(UINT_X) * 8];
        uint8 bii[sizeof(UINT_X) * 8];

        //per bytes contain bit count
        uint8 pbcbc = (sizeof(UINT_X) * 8) / (sizeof(uint32) / sizeof(uint8));

        for (int i = 0; i < (sizeof(UINT_X) * 8); i++) {
            if ((i%pbcbc) == 0) {
                b[i] = ((r_u32 >> ((5 + ((i / pbcbc) << 3))) & 0x7) % 5) & 0xFF;
                bii[i] = b[i];
            }
            else {
                b[i] = ((b[i - 1] + 1) % 5);
                bii[i] = bii[i - 1];
            }

            uint8 bi = 0;
            if (val&(0x01 << i)) {
                bi |= (0x01 << b[i]);
            }
            bi |= ((0x7 & bii[i]) << 5);
            rr |= ((0xFFFFFFFF & bi) << ((i / pbcbc) << 3));
        }
        return rr;
    }

    template <typename UINT_X>
    inline static UINT_X deobfuscate32(uint32 const& val) {
        UINT_X r = 0;
        uint8 pbcbc = (sizeof(UINT_X) * 8) / (sizeof(uint32) / sizeof(uint8));
        UINT_X b[sizeof(UINT_X) * 8];

        for (int i = 0; i < (sizeof(UINT_X) * 8); i++) {
            if ((i%pbcbc) == 0) {
                b[i] = ((val >> ((5 + ((i / pbcbc) << 3))) & 0x7) % 5) & 0xFF;
            }
            else {
                b[i] = ((b[i - 1] + 1) % 5);
            }
            r |= (((val >> (b[i] + ((i / pbcbc) << 3))) & 0x1) << i);
        }
        return r;
    }

    inline static uint32 u8_obfuscate(uint8 const& val) {
        return obfuscate32<uint8>(val, const_r_u32);
    }
    inline static uint32 u16_obfuscate(uint16 const& val) {
        return obfuscate32<uint16>(val, const_r_u32);
    }
    inline static uint8 u8_deobfuscate(uint32 const& val) {
        return deobfuscate32<uint8>(val);
    }
    inline static uint16 u16_deobfuscate(uint32 const& val) {
        return deobfuscate32<uint16>(val);
    }
};

void FDataObfuscationUtil::ObfuscateWithRedundancy(TArray<uint8>& Dest, const uint8* Src, uint32 SrcLen)
{
    Dest.SetNumUninitialized(SrcLen * 2, false);
    for (uint32 ii = 0; ii < SrcLen; ++ii)
    {
        Dest[ii * 2] = Src[ii] & 0x55;
        Dest[ii * 2 + 1] = Src[ii] & 0xaa;
    }
}

void FDataObfuscationUtil::DeobfuscateWithRedundancy(TArray<uint8>& Dest, const uint8* Src, uint32 SrcLen)
{
    check(SrcLen % 2 == 0);
    int DestLen = SrcLen / 2;
    Dest.SetNumUninitialized(DestLen, false);
    for (int ii = 0; ii < DestLen; ++ii)
    {
        Dest[ii] = Src[ii * 2] | Src[ii * 2 + 1];
    }
}
//////////////////////////////////////////////////////////////////////////