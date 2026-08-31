// Fill out your copyright notice in the Description page of Project Settings.

#include "Util/LogCatcher.h"
#include "Common.h"
#include "Engine.h"
#include "BuglyCrashReportBPLibrary.h"
#include "HAL/PlatformString.h"


class FLogCatcherV2 : public FOutputDevice
{
    class FAr : public FMemoryWriter
    {
    public:
        FAr(TArray<uint8>& InBytes)
            : FMemoryWriter(InBytes, true, false, TEXT("LogCatcherAr"))
        {
        }

        virtual void Serialize(void* Data, int64 Num) override
        {
            FMemoryWriter::Serialize(Data, Num);

            if (Num > 0 && ((uint8*)Data)[Num-1] == 0)
            {
                Flush();
            }
        }

        virtual void Flush() override
        {
            if (Offset > 0)
            {
                int TotalCount = Bytes.Num();
                for(int Start = 0, End = 0; End < Offset; ++End)
                {
                    if (Bytes[End] == '\0' && Start != End)
                    {
                        UBuglyCrashReportBPLibrary::LogInfo((ANSICHAR*)(Bytes.GetData() + Start));
                        Start = End + 1;
                    }
                }                
                Offset = 0;
            }
        }
    };

public:
    FLogCatcherV2()
    {
        Ar = new FAr(LogBuffer);
        AsyncWriter = new FAsyncWriter(*Ar);
    }
    virtual ~FLogCatcherV2()
    {
        AsyncWriter->Flush();
        delete AsyncWriter;
        delete Ar;
    }

    //virtual void Serialize(const TCHAR* V, ELogVerbosity::Type Verbosity, const class FName& Category) override
    //{
    //    if (Verbosity != ELogVerbosity::SetColor && V)
    //    {
    //        const int32 FrameCounterPrefixLen = 5;
    //        const int32 DefaultTempTextSize = 512;
    //        const int32 DataLength = FCString::Strlen(V);
    //        
    //        TArray<TCHAR, TInlineAllocator<DefaultTempTextSize> > TempText;
    //        TempText.AddUninitialized(FrameCounterPrefixLen + DataLength + 1);
    //        
    //        // Write frame counter
    //        FCString::Sprintf(TempText.GetData(), TEXT("[%3llu]"), GFrameCounter % 1000);

    //        TCHAR* Dest = TempText.GetData() + FrameCounterPrefixLen;

    //        // Copy characters to end of string, overwriting null terminator if we already have one
    //        FPlatformString::Convert(Dest, DataLength, V, DataLength);

    //        // (Re-)establish the null terminator
    //        Dest[DataLength] = '\0';
    //        
    //        UBuglyCrashReportBPLibrary::LogInfo(TempText.GetData());
    //    }
    //}

    virtual void Serialize(const TCHAR* V, ELogVerbosity::Type Verbosity, const class FName& Category) override
    {
        if (Verbosity != ELogVerbosity::SetColor && V)
        {
            const int32 FrameCounterPrefixLen = 5;
            TCHAR FramePrefix[FrameCounterPrefixLen + 1];
            FCString::Sprintf(FramePrefix, TEXT("[%3llu]"), GFrameCounter % 1000);

            const int32 DefaultTempTextSize = 512;
            TArray<ANSICHAR, TInlineAllocator<2 * DefaultTempTextSize>> ConvertedText;

            //const int32 ConvertedPrefixLength = FTCHARToUTF8_Convert::ConvertedLength(FramePrefix, FrameCounterPrefixLen);
            const int32 ConvertedPrefixLength = FrameCounterPrefixLen;
            const int32 DataLength = FCString::Strlen(V);
            const int32 ConvertedDataLength = FTCHARToUTF8_Convert::ConvertedLength(V, DataLength);
            ConvertedText.AddUninitialized(ConvertedPrefixLength + ConvertedDataLength + 1);

            FTCHARToUTF8_Convert::Convert(ConvertedText.GetData(), ConvertedPrefixLength, FramePrefix, FrameCounterPrefixLen);
            FTCHARToUTF8_Convert::Convert(ConvertedText.GetData() + ConvertedPrefixLength, ConvertedDataLength, V, DataLength);
            ConvertedText[ConvertedText.Num() - 1] = '\0';

            AsyncWriter->Serialize(ConvertedText.GetData(), ConvertedText.Num() * sizeof(ANSICHAR));
        }
    }

private:
    FAsyncWriter* AsyncWriter;
    FAr* Ar;
    TArray<uint8> LogBuffer;
};

//////////////////////////////////////////////////////////////////////////
static float MainThreadLogTotalTime = 0;
static float WorkThreadLogTotalTime = 0;
static FEvent* LogEvent = nullptr;

/**
* Thread heartbeat check class.
* Used by crash handling code to check for hangs.
* [] tags identify which thread owns a variable or function
*/
class FAsyncWriterX : public FRunnable, public FArchive
{
    enum EConstants
    {
        InitialBufferSize = 64 * 1024
    };

    /** Thread to run the worker FRunnable on. Serializes the ring buffer to CrashReporter. */
    volatile FRunnableThread* Thread;
    /** Stops this thread */
    FThreadSafeCounter StopTaskCounter;


    /** Data ring buffer */
    TArray<uint8> Buffer;
    TArray<uint8> TempBuffer;
    /** [WRITER THREAD] Position where the unserialized data starts in the buffer */
    volatile int32 BufferStartPos;
    /** [CLIENT THREAD] Position where the unserialized data ends in the buffer (such as if (BufferEndPos > BufferStartPos) Length = BufferEndPos - BufferStartPos; */
    volatile int32 BufferEndPos;
    /** [CLIENT THREAD] Sync object for the buffer pos */
    FCriticalSection BufferPosCritical;
    /** [CLIENT/WRITER THREAD] Outstanding serialize request counter. This is to make sure we flush all requests. */
    FThreadSafeCounter SerializeRequestCounter;
    /** [CLIENT/WRITER THREAD] Tells the writer thread, the client requested flush. */
    FThreadSafeCounter WantsArchiveFlush;


    /** [WRITER THREAD] Serialize the contents of the ring buffer to disk */
    void SerializeBufferToArchive()
    {
        struct FScopeTime
        {
            FScopeTime()
            {
                StartTime = FPlatformTime::Cycles();
            }
            ~FScopeTime()
            {
                float Time = FPlatformTime::ToMilliseconds(FPlatformTime::Cycles() - StartTime);
                WorkThreadLogTotalTime += Time;
            }

            uint32 StartTime;
        }ScopeTime;

        //SCOPED_NAMED_EVENT(FAsyncWriterX_SerializeBufferToArchive, FColor::Cyan);
        while (SerializeRequestCounter.GetValue() > 0)
        {
            // Grab a local copy of the end pos. It's ok if it changes on the client thread later on.
            // We won't be modifying it anyway and will later serialize new data in the next iteration.
            // Here we only serialize what we know exists at the beginning of this function.
            int32 ThisThreadEndPos = BufferEndPos;
            int32 TotalCount = 0;

            if (ThisThreadEndPos >= BufferStartPos)
            {
                TotalCount = ThisThreadEndPos - BufferStartPos;
                if (TotalCount > 0)
                {
                    TempBuffer.SetNumUninitialized(TotalCount + 1, false);
                    FMemory::Memcpy(TempBuffer.GetData(), Buffer.GetData() + BufferStartPos, TotalCount);
                    TempBuffer[TotalCount] = 0;
                    UBuglyCrashReportBPLibrary::LogInfo((ANSICHAR*)TempBuffer.GetData());
                }
                //Ar.Serialize(Buffer.GetData() + BufferStartPos, ThisThreadEndPos - BufferStartPos);
            }
            else
            {
                // Data is wrapped around the ring buffer
                int32 FirstPartLength = Buffer.Num() - BufferStartPos;
                TotalCount = FirstPartLength + BufferEndPos;
                if (TotalCount > 0)
                {
                    TempBuffer.SetNumUninitialized(TotalCount + 1, false);
                    if (FirstPartLength > 0)
                    {
                        check(TempBuffer.Num() <= FirstPartLength);
                        FMemory::Memcpy(TempBuffer.GetData(), Buffer.GetData() + BufferStartPos, FirstPartLength);
                    }

                    if (BufferEndPos > 0)
                    {
                        check(TempBuffer.Num() - FirstPartLength <= BufferEndPos);
                        FMemory::Memcpy(TempBuffer.GetData() + FirstPartLength, Buffer.GetData(), BufferEndPos);
                    }
                    TempBuffer[TotalCount] = 0;
                    UBuglyCrashReportBPLibrary::LogInfo((ANSICHAR*)TempBuffer.GetData());

                    //Ar.Serialize(Buffer.GetData() + BufferStartPos, Buffer.Num() - BufferStartPos);
                    //Ar.Serialize(Buffer.GetData(), BufferEndPos);
                }
            }

            // Modify the start pos. Only the worker thread modifies this value so it's ok to not guard it with a critical section.
            FPlatformAtomics::InterlockedExchange(&BufferStartPos, ThisThreadEndPos);

            // Decrement the request counter, we now know we serialized at least one request.
            // We might have serialized more requests but it's irrelevant, the counter will go down to 0 eventually
            SerializeRequestCounter.Decrement();

            // If no threading is available or when we explicitly requested flush (see FlushBuffer), flush immediately after writing.
            // In some rare cases we may flush twice (see above) but that's ok. We need a clear division between flushing because of the timer
            // and force flush on demand.
            if (WantsArchiveFlush.GetValue() > 0)
            {
                int32 FlushCount = WantsArchiveFlush.Decrement();
                check(FlushCount >= 0);
            }
        }
    }

    /** [CLIENT THREAD] Flush the memory buffer (doesn't force the archive to flush). Can only be used from inside of BufferPosCritical lock. */
    void FlushBuffer()
    {
        SerializeRequestCounter.Increment();
        LogEvent->Trigger();

        if (!Thread)
        {
            SerializeBufferToArchive();
        }
        while (SerializeRequestCounter.GetValue() != 0)
        {
            FPlatformProcess::SleepNoStats(0);
        }
        // Make sure there's been no unexpected concurrency
        check(SerializeRequestCounter.GetValue() == 0);
    }

public:

    FAsyncWriterX()
        : Thread(nullptr)
        , BufferStartPos(0)
        , BufferEndPos(0)
    {
        Buffer.AddUninitialized(InitialBufferSize);

        if (FPlatformProcess::SupportsMultithreading())
        {
            FPlatformAtomics::InterlockedExchangePtr((void**)&Thread, FRunnableThread::Create(this, TEXT("LogAsyncWriter"), 0, TPri_BelowNormal));
        }
    }

    virtual ~FAsyncWriterX()
    {
        Flush();
        delete Thread;
        Thread = nullptr;
    }

    /** [CLIENT THREAD] Serialize data to buffer that will later be saved to disk by the async thread */
    virtual void Serialize(void* InData, int64 Length) override
    {
        if (!InData || Length <= 0)
        {
            return;
        }

        const uint8* Data = (uint8*)InData;

        FScopeLock WriteLock(&BufferPosCritical);

        // Store the local copy of the current buffer start pos. It may get moved by the worker thread but we don't
        // care about it too much because we only modify BufferEndPos. Copy should be atomic enough. We only use it
        // for checking the remaining space in the buffer so underestimating is ok.
        {
            const int32 ThisThreadStartPos = BufferStartPos;
            // Calculate the remaining size in the ring buffer
            const int32 BufferFreeSize = ThisThreadStartPos <= BufferEndPos ? (Buffer.Num() - BufferEndPos + ThisThreadStartPos) : (ThisThreadStartPos - BufferEndPos);
            // Make sure the buffer is BIGGER than we require otherwise we may calculate the wrong (0) buffer EndPos for StartPos = 0 and Length = Buffer.Num()
            if (BufferFreeSize <= Length)
            {
                // Force the async thread to call SerializeBufferToArchive even if it's currently empty
                FlushBuffer();

                // Resize the buffer if needed
                if (Length >= Buffer.Num())
                {
                    // Keep the buffer bigger than we require so that % Buffer.Num() does not return 0 for Lengths = Buffer.Num()
                    Buffer.SetNumUninitialized(Length + 1, false);
                }
            }
        }

        // We now know there's enough space in the buffer to copy data
        const int32 WritePos = BufferEndPos;
        if ((WritePos + Length) <= Buffer.Num())
        {
            // Copy straight into the ring buffer
            FMemory::Memcpy(Buffer.GetData() + WritePos, Data, Length);
        }
        else
        {
            // Wrap around the ring buffer
            int32 BufferSizeToEnd = Buffer.Num() - WritePos;
            FMemory::Memcpy(Buffer.GetData() + WritePos, Data, BufferSizeToEnd);
            FMemory::Memcpy(Buffer.GetData(), Data + BufferSizeToEnd, Length - BufferSizeToEnd);
        }

        // Update the end position and let the async thread know we need to write to disk
        FPlatformAtomics::InterlockedExchange(&BufferEndPos, (BufferEndPos + Length) % Buffer.Num());
        SerializeRequestCounter.Increment();
        LogEvent->Trigger();

        // No async thread? Serialize now.
        if (!Thread)
        {
            SerializeBufferToArchive();
        }
    }

    void Flush() override
    {
        FScopeLock WriteLock(&BufferPosCritical);
        WantsArchiveFlush.Increment();
        FlushBuffer();
    }

    //~ Begin FRunnable Interface.
    virtual bool Init() override
    {
        return true;
    }

    virtual uint32 Run() override
    {
        while (StopTaskCounter.GetValue() == 0)
        {
            if (SerializeRequestCounter.GetValue() > 0)
            {
                SerializeBufferToArchive();
            }
            else
            {
                LogEvent->Wait();
            }
        }
        return 0;
    }

    virtual void Stop() override
    {
        StopTaskCounter.Increment();
    }
    //~ End FRunnable Interface
};

class FLogCatcher : public FOutputDevice
{
public:
    FLogCatcher()
    {
        LogEvent = FPlatformProcess::GetSynchEventFromPool(false);
        LogEvent->Reset();
        AsyncWriter = new FAsyncWriterX();
    }
    ~FLogCatcher()
    {
        if (AsyncWriter)
        {
            delete AsyncWriter;
            AsyncWriter = nullptr;

            FPlatformProcess::ReturnSynchEventToPool(LogEvent);
            LogEvent = nullptr;
        }
    }

protected:
    virtual void Serialize(const TCHAR* V, ELogVerbosity::Type Verbosity, const class FName& Category) override
    {
        struct FScopeTime
        {
            FScopeTime()
            {
                StartTime = FPlatformTime::Cycles();
            }
            ~FScopeTime()
            {
                float Time = FPlatformTime::ToMilliseconds(FPlatformTime::Cycles() - StartTime);
                MainThreadLogTotalTime += Time;
            }

            uint32 StartTime;
        }ScopeTime;

        if (Verbosity != ELogVerbosity::SetColor)
        {
            FOutputDeviceHelper::FormatCastAndSerializeLine(*AsyncWriter, V, Verbosity, Category, 0, true, true);
        }
    }

 private:

    /** Writes to a file on a separate thread */
    FAsyncWriterX* AsyncWriter;
};

static FOutputDevice* LogCatcher = nullptr;

bool ULogCatcher::IsEnabled()
{
    return LogCatcher != nullptr;
}

static int GnableLogCatcherV2 = 1;
static FAutoConsoleVariableRef CVarEnableLogCatcherV2(
    TEXT("log.enableLogCatcherV2"),
    GnableLogCatcherV2,
    TEXT("enableLogCatcherV2"),
    ECVF_Default);

void ULogCatcher::SetEnable(bool bEnable)
{
    if (bEnable)
    {
        if (LogCatcher == nullptr)
        {
            if (GnableLogCatcherV2)
            {
                LogCatcher = new FLogCatcherV2();
            }
            else
            {
                LogCatcher = new FLogCatcher();
            }
            
            FOutputDeviceRedirector::Get()->AddOutputDevice(LogCatcher);
        }
    }
    else if (LogCatcher)
    {
        FOutputDeviceRedirector::Get()->RemoveOutputDevice(LogCatcher);
        delete LogCatcher;
        LogCatcher = nullptr;
    }
}

//float ULogCatcher::GetMainThreadDumpLogTime()
//{
//    return MainThreadLogTotalTime;
//}
//
//float ULogCatcher::GetWorkThreadDumpLogTime()
//{
//    return WorkThreadLogTotalTime;
//}
