#include "Network/SocketMessageQueue.h"
#include "Common.h"

DEFINE_LOG_CATEGORY_STATIC(SocketMessageQueueLog, Log, All);

struct SMessageQueueHelper
{
    static int32 Write(uint8* Buffer, int32 SocketID, uint16 MessageID, const uint8* MessageData, int32 Size)
    {
        check(Buffer);
        check(MessageData);
        check(Size > 0);
        *(int32*)Buffer = SocketID;
        *(uint16*)(Buffer + 4) = MessageID;
        *(int32*)(Buffer + 6) = Size;
        FMemory::Memcpy(Buffer + 10, MessageData, Size);
        return Size + 10;
    }
    static const int32 Read(const uint8* Buffer, int32& SocketID, uint16& MessageID, const uint8* &MessageData, int32& Size)
    {
        check(Buffer);
        SocketID = *(const int32*)Buffer;
        MessageID = *(const uint16*)(Buffer + 4);
        Size = *(const int32*)(Buffer + 6);
        MessageData = Buffer + 10;
        check(MessageData);
        check(Size > 0);
        return Size + 10;
    }
    static uint8* GetHeader(uint8* MessageData)
    {
        return MessageData - 10;
    }
    static const int32 GetHeaderLen()
    {
        return 10;
    }
};

FSocketMessageQueue::FSocketMessageQueue()
    : Head(0)
    , Tail(0)
    , InitSize(0)
    , MessageCount(0)
{

}

void FSocketMessageQueue::Init(int32 Size)
{
    check(Size > 0);
    InitSize = Size;
    Reset();
}

void FSocketMessageQueue::Push(int32 SocketID, uint16 MessageID, const uint8* MessageData, int32 Size)
{
    check(Size > 0 && MessageData);
    check(Head == Tail
        || (Tail > Head + SMessageQueueHelper::GetHeaderLen() && Tail <= QueueData.Num()));

    if (Head >= QueueData.Num() / 2)
    {
        Adjust();
    }

    int32 NewTail = Tail + Size + SMessageQueueHelper::GetHeaderLen();
    while (NewTail > QueueData.Num())
    {
        // alloc new        
        QueueData.AddUninitialized(QueueData.Num());
        UE_LOG(SocketMessageQueueLog, Log, TEXT("FSocketMessageQueue realloc [%d]"), QueueData.Num());
    }

    Tail += SMessageQueueHelper::Write(&QueueData[Tail], SocketID, MessageID, MessageData, Size);
    check(NewTail == Tail && Tail <= QueueData.Num());
    ++MessageCount;
}

bool FSocketMessageQueue::Pop(int32& SocketID, uint16& MessageID, const uint8* &MessageData, int32& Size)
{
    if (Head == Tail)
    {
        if (Head != 0)
        {
            Head = 0;
            Tail = 0;            
            if (QueueData.Num() > InitSize)
            {
                Reset();
            }
        }
        return false;
    }

    check(Head >= 0 && Tail > Head + SMessageQueueHelper::GetHeaderLen() && Tail <= QueueData.Num());
    Head += SMessageQueueHelper::Read(&QueueData[Head], SocketID, MessageID, MessageData, Size);
    check(Head <= Tail && Head <= QueueData.Num());
    --MessageCount;
    check(MessageCount >= 0);
    return true;
}

void FSocketMessageQueue::Adjust()
{
    if (Head > 0)
    {
        FMemory::Memmove(&QueueData[0], &QueueData[Head], Tail - Head);
        Tail = Tail - Head;
        Head = 0;
    }
}

void FSocketMessageQueue::Reset()
{
    QueueData.Empty(InitSize);
    QueueData.AddUninitialized(InitSize);
    Head = 0;
    Tail = Head;
    MessageCount = 0;
}
