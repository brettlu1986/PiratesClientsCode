#pragma once

#include <functional>
#include <type_traits>

#if WITH_EDITOR
#define ENABLE_TAB_FILE_EDITOR
#endif

#if !UE_BUILD_SHIPPING
#if defined(_MSC_VER)
#define TAB_FILE_GET_PARAM_TYPE_INFO __FUNCTION__
#endif
#endif

template<typename T>
static T& TabFileGetParamByOffset(void* Data, unsigned int Offset)
{
    return *(T*)((char*)Data + Offset);
}
typedef bool(*FTabFileParamReadFunc)(void* Data, unsigned int Offset, const FString&, const TCHAR* RawData);
typedef bool(*FTabFileParamWriteFunc)(void* Data, unsigned int Offset, const FString&, FString& OutData);

template<typename TParamType>
struct FTabFileDataParamReader
{
#ifdef TAB_FILE_GET_PARAM_TYPE_INFO
    FTabFileDataParamReader()
    {
        static_assert(false, TAB_FILE_GET_PARAM_TYPE_INFO " have not be implemented.");
    }
#endif
    static bool Read(void* Data, unsigned int Offset, const FString&, const TCHAR* RawData)
    {
        check(false);
        return false;
    }
};

template<typename TParamType>
struct FTabFileDataParamWriter
{
#ifdef TAB_FILE_GET_PARAM_TYPE_INFO
    FTabFileDataParamWriter()
    {
        static_assert(false, TAB_FILE_GET_PARAM_TYPE_INFO " have not be implemented.");
    }
#endif
    static bool Write(void* Data, unsigned int Offset, const FString&, FString& OutData)
    {
        check(false);
        return false;
    }
};

//////////////////////////////////////////////////////////////////////////
struct FTabFileDataParamHelper
{
    template<typename TParamType>
    static FTabFileParamReadFunc GetReader(const TParamType&)
    {
#if !UE_BUILD_SHIPPING && defined(TAB_FILE_GET_PARAM_TYPE_INFO)
        static FTabFileDataParamReader<TParamType> StaticCheck;
#endif
        return &FTabFileDataParamReader<TParamType>::Read;
    }

    template<typename TParamType>
    static FTabFileParamWriteFunc GetWriter(const TParamType&)
    {
#if !UE_BUILD_SHIPPING && defined(TAB_FILE_GET_PARAM_TYPE_INFO)
        static FTabFileDataParamWriter<TParamType> StaticCheck;
#endif
        return &FTabFileDataParamWriter<TParamType>::Write;
    }

    template<typename TParamType>
    static bool Read(TParamType& Out, const TCHAR* RawData)
    {
        FString NullString;
        return FTabFileDataParamReader<TParamType>::Read((void*)&Out, 0, NullString, RawData);
    }

    template<typename TParamType>
    static bool Write(const TParamType& In, FString& OutData)
    {
        FString NullString;
        return FTabFileDataParamWriter<TParamType>::Write((void*)&In, 0, NullString, OutData);
    }
};

//////////////////////////////////////////////////////////////////////////
template<>
struct FTabFileDataParamReader<FString>
{
    static bool Read(void* Data, unsigned int Offset, const FString&, const TCHAR* RawData)
    {
        FString& Param = TabFileGetParamByOffset<FString>(Data, Offset);
        if (!RawData || !RawData[0])
        {
            Param.Empty();
        }
        else
        {
            Param = RawData;
        }
        return true;
    }
};

template<>
struct FTabFileDataParamWriter<FString>
{
    static bool Write(void* Data, unsigned int Offset, const FString&, FString& OutData)
    {
        FString& Param = TabFileGetParamByOffset<FString>(Data, Offset);
        OutData = Param;
        return true;
    }
};

//////////////////////////////////////////////////////////////////////////
template<>
struct FTabFileDataParamReader<FName>
{
    static bool Read(void* Data, unsigned int Offset, const FString&, const TCHAR* RawData)
    {
        FName& Param = TabFileGetParamByOffset<FName>(Data, Offset);
        if (!RawData || !RawData[0])
        {
            Param = FName();
        }
        else
        {
            Param = FName(RawData);
        }
        return true;
    }
};

template<>
struct FTabFileDataParamWriter<FName>
{
    static bool Write(void* Data, unsigned int Offset, const FString&, FString& OutData)
    {
        FName& Param = TabFileGetParamByOffset<FName>(Data, Offset);
        OutData = Param.ToString();
        return true;
    }
};

//////////////////////////////////////////////////////////////////////////
template<>
struct FTabFileDataParamReader<bool>
{
    static bool Read(void* Data, unsigned int Offset, const FString&, const TCHAR* RawData)
    {
        bool& Param = TabFileGetParamByOffset<bool>(Data, Offset);     
        Param = RawData[0] == 0 ? false : RawData[0] != LITERAL(TCHAR, '0');
        return true;
    }
};

template<>
struct FTabFileDataParamWriter<bool>
{
    static bool Write(void* Data, unsigned int Offset, const FString&, FString& OutData)
    {
        bool& Param = TabFileGetParamByOffset<bool>(Data, Offset);
        OutData = Param ? TEXT("1") : TEXT("0");
        return true;
    }
};

//////////////////////////////////////////////////////////////////////////
template<>
struct FTabFileDataParamReader<int>
{
    static bool Read(void* Data, unsigned int Offset, const FString&, const TCHAR* RawData)
    {
        int& Param = TabFileGetParamByOffset<int>(Data, Offset);
        Param = FCString::Atoi(RawData);
        return true;
    }
};

template<>
struct FTabFileDataParamWriter<int>
{
    static bool Write(void* Data, unsigned int Offset, const FString&, FString& OutData)
    {
        int& Param = TabFileGetParamByOffset<int>(Data, Offset);
        OutData.Empty();
        OutData.AppendInt(Param);
        return true;
    }
};

//////////////////////////////////////////////////////////////////////////
template<>
struct FTabFileDataParamReader<unsigned int>
{
    static bool Read(void* Data, unsigned int Offset, const FString&, const TCHAR* RawData)
    {
        int& Param = TabFileGetParamByOffset<int>(Data, Offset);
        Param = (unsigned int)FCString::Atoi(RawData);
        return true;
    }
};

template<>
struct FTabFileDataParamWriter<unsigned int>
{
    static bool Write(void* Data, unsigned int Offset, const FString&, FString& OutData)
    {
        unsigned int& Param = TabFileGetParamByOffset<unsigned int>(Data, Offset);
        OutData = LexToString(Param);
        return true;
    }
};

//////////////////////////////////////////////////////////////////////////
template<>
struct FTabFileDataParamReader<int64>
{
    static bool Read(void* Data, unsigned int Offset, const FString&, const TCHAR* RawData)
    {
        int64& Param = TabFileGetParamByOffset<int64>(Data, Offset);
        Param = FCString::Atoi64(RawData);
        return true;
    }
};

template<>
struct FTabFileDataParamWriter<int64>
{
    static bool Write(void* Data, unsigned int Offset, const FString&, FString& OutData)
    {
        int64& Param = TabFileGetParamByOffset<int64>(Data, Offset);
        OutData = LexToString(Param);
        return true;
    }
};

//////////////////////////////////////////////////////////////////////////
template<>
struct FTabFileDataParamReader<float>
{
    static bool Read(void* Data, unsigned int Offset, const FString&, const TCHAR* RawData)
    {
        float& Param = TabFileGetParamByOffset<float>(Data, Offset);
        Param = FCString::Atof(RawData);
        return true;
    }
};

template<>
struct FTabFileDataParamWriter<float>
{
    static bool Write(void* Data, unsigned int Offset, const FString&, FString& OutData)
    {
        float& Param = TabFileGetParamByOffset<float>(Data, Offset);
        OutData = LexToString(Param);
        return true;
    }
};

//////////////////////////////////////////////////////////////////////////
template<>
struct FTabFileDataParamReader<double>
{
    static bool Read(void* Data, unsigned int Offset, const FString&, const TCHAR* RawData)
    {
        double& Param = TabFileGetParamByOffset<double>(Data, Offset);
        Param = FCString::Atod(RawData);
        return true;
    }
};

template<>
struct FTabFileDataParamWriter<double>
{
    static bool Write(void* Data, unsigned int Offset, const FString&, FString& OutData)
    {
        double& Param = TabFileGetParamByOffset<double>(Data, Offset);
        OutData = LexToString(Param);
        return true;
    }
};

////////////////////////////////////////////////////////////////////////////
template<>
struct FTabFileDataParamReader<FVector>
{
    static bool Read(void* Data, unsigned int Offset, const FString&, const TCHAR* RawData)
    {
        FVector& Param = TabFileGetParamByOffset<FVector>(Data, Offset);
        const int TempLen = 256;
        TCHAR Temp[TempLen] = {};
        check(FCString::Strlen(RawData) < TempLen);
        FCString::Strcpy(Temp, TempLen, RawData);
        float* FloatParam[3] =
        {
            &Param.X, &Param.Y, &Param.Z
        };

        int Index = 0;
        TCHAR* Start = Temp;
        for (TCHAR* End = Temp; *End && Index<3; ++End)
        {
            if (*End == LITERAL(TCHAR, ','))
            {
                *End = 0;
                *FloatParam[Index++] = FCString::Atof(Start);
                Start = End+1;
            }
        }
        if (Index < 3)
        {
            *FloatParam[Index++] = FCString::Atof(Start);
        }
        return Index == 3;
    }
};

template<>
struct FTabFileDataParamWriter<FVector>
{
    static bool Write(void* Data, unsigned int Offset, const FString&, FString& OutData)
    {
        FVector& Param = TabFileGetParamByOffset<FVector>(Data, Offset);
        OutData = FString::Printf(TEXT("%f,%f,%f"), Param.X, Param.Y, Param.Z);
        return true;
    }
};

////////////////////////////////////////////////////////////////////////////
template<>
struct FTabFileDataParamReader<FRotator>
{
    static bool Read(void* Data, unsigned int Offset, const FString&, const TCHAR* RawData)
    {
        FRotator& Param = TabFileGetParamByOffset<FRotator>(Data, Offset);
        const int TempLen = 256;
        TCHAR Temp[TempLen] = {};
        check(FCString::Strlen(RawData) < TempLen);
        FCString::Strcpy(Temp, RawData);
        float* FloatParam[3] =
        {
            &Param.Yaw, &Param.Pitch, &Param.Roll
        };

        int Index = 0;
        TCHAR* Start = Temp;
        for (TCHAR* End = Temp; *End && Index < 3; ++End)
        {
            if (*End == LITERAL(TCHAR, ','))
            {
                *End = 0;
                *FloatParam[Index++] = FCString::Atof(Start);
                Start = End + 1;
            }
        }
        if (Index < 3)
        {
            *FloatParam[Index++] = FCString::Atof(Start);
        }
        return Index == 3;
    }
};

template<>
struct FTabFileDataParamWriter<FRotator>
{
    static bool Write(void* Data, unsigned int Offset, const FString&, FString& OutData)
    {
        FRotator& Param = TabFileGetParamByOffset<FRotator>(Data, Offset);
        OutData = FString::Printf(TEXT("%f,%f,%f"), Param.Yaw, Param.Pitch, Param.Roll);
        return true;
    }
};
