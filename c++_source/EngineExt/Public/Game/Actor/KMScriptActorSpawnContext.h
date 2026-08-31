// Fill out your copyright notice in the Description page of Project Settings.
#pragma once

class ENGINEEXT_API FKMScriptActorSpawnContext
{
public:
    FKMScriptActorSpawnContext()
        : LogicInstanceId(-1)
        , IsBeginPlayManually(false)
    {

    }

    inline TArray<uint8>& GetData()
    { 
        return Data; 
    }

    inline void SetInstanceId(int Id) { LogicInstanceId = Id; }
    inline void SetBeginPlayManually(bool bManual) { IsBeginPlayManually = bManual;}

    inline void PopData(TArray<uint8>& Out, int& OutInstanceId, bool& OutBeginPlayManually)
    {
        if (Data.Num() > 0)
        {
            Out.Empty(Data.Num());
            Out.Append(Data);
            Data.Empty(Data.Max());
        }
        //if (LogicInstanceId > 0)
        {
            OutInstanceId = LogicInstanceId;
            LogicInstanceId = -1;
            OutBeginPlayManually = IsBeginPlayManually;
            IsBeginPlayManually = false;
        }
    }
    inline void Reset()
    {
        LogicInstanceId = -1;
        IsBeginPlayManually = false;
        Data.Empty(Data.Max());
    }

private:
    TArray<uint8> Data;
    int LogicInstanceId;
    bool IsBeginPlayManually;
};

//////////////////////////////////////////////////////////////////////////
class FPrintTimeHelper
{
public:
    FPrintTimeHelper(const TCHAR* InDesc, bool bEnableLog=true)
        : StartTime(FPlatformTime::Seconds())
        , Desc(InDesc)
        , EnableLog(bEnableLog)
    {        
    }

    ~FPrintTimeHelper()
    {
        if (!EnableLog)
        {
            return;
        }

        double NowTime = FPlatformTime::Seconds();
        int Num = Infos.Num();
        if (Num == 0)
        {
            UE_LOG(LogTemp, Display, TEXT("Totaltime %s: %.2f ms"),
                *Desc, GetIntervalMS(NowTime, StartTime));
        }
        else if (Num == 1)
        {
            UE_LOG(LogTemp, Display, TEXT("Totaltime %s: %.2f ms, detail: %s: %.2f ms"), 
                *Desc, GetIntervalMS(NowTime, StartTime),
                *Infos[0].Key, GetIntervalMS(Infos[0].Value, StartTime));
        }
        else if (Num == 2)
        {
            UE_LOG(LogTemp, Display, TEXT("Totaltime %s: %.2f ms, detail: %s: %.2f ms, %s: %.2f ms"),
                *Desc, GetIntervalMS(NowTime, StartTime),
                *Infos[0].Key, GetIntervalMS(Infos[0].Value, StartTime),
                *Infos[1].Key, GetIntervalMS(Infos[1].Value, Infos[0].Value));
        }
        else if (Num == 3)
        {
            UE_LOG(LogTemp, Display, TEXT("Totaltime %s: %.2f ms, detail: %s: %.2f ms, %s: %.2f ms, %s: %.2f ms"),
                *Desc, GetIntervalMS(NowTime, StartTime),
                *Infos[0].Key, GetIntervalMS(Infos[0].Value, StartTime),
                *Infos[1].Key, GetIntervalMS(Infos[1].Value, Infos[0].Value),
                *Infos[2].Key, GetIntervalMS(Infos[2].Value, Infos[1].Value));
        }
        else
        {
            FString Output = FString::Printf(TEXT("Totaltime %s: %.2f ms, detail: %s: %.2f ms"), 
                *Desc, GetIntervalMS(NowTime, StartTime),
                *Infos[0].Key, GetIntervalMS(Infos[0].Value, StartTime));
            for (int ii = 1; ii < Infos.Num(); ii++)
            {
                Output.Append(FString::Printf(TEXT(", %s: %.2f ms"), 
                    *Infos[ii].Key, GetIntervalMS(Infos[ii].Value, Infos[ii-1].Value)));
            }
        }
    }

    void Stamp(const TCHAR* TempDesc)
    {
        Infos.Add(TKeyValuePair<FString, double>(TempDesc, FPlatformTime::Seconds()));
    }

private:
    inline float GetIntervalMS(double InNowTime, double InStartTime)
    {
        return (float)(InNowTime - InStartTime)*1000.0f;
    }

private:
    double StartTime;
    FString Desc;
    TArray<TKeyValuePair<FString, double> > Infos;    
    bool EnableLog;
};