#pragma once

class COMMON_API FSocketMessageQueue
{
public:
    FSocketMessageQueue();
    void Init(int32 Size);
    void Push(int32 SocketID, uint16 MessageID, const uint8* MessageData, int32 Size);
    bool Pop(int32& SocketID, uint16& MessageID, const uint8* &MessageData, int32& Size);
    const int32 GetMessageCount() const { return MessageCount; }
    const int32 GetQueueSize() const { return Tail - Head; }
    void Reset();

private:
    void Adjust();

private:
    TArray<uint8> QueueData;
    int32 Head;
    int32 Tail;
    int32 InitSize;
    int32 MessageCount;
};
