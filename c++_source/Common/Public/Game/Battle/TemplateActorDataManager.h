//////////////////////////////////////////////////////////////////////////
// 静态物管理，用于副本初始spawn的掉落物，因为量太大，所以搞成这种形式
// 服务器不真正创建actor，只存数据
// 玩家进入cell后服务器往客户端推cell中的数据，然后客户端在本地spawn掉落物
// history是为了客户端第二次进入cell时跟服务器比较，当自己的history与服务器的history差太多时，服务器直接将cell全部信息推下去，如果差的少，那么只推历史记录，历史记录只存当前cell数据的一半

#pragma once
#include "TemplateActorDataManager.generated.h"

#define ENABLE_DEBUG_TEMPLATE_ACTOR 0

class UTemplateActorDataComponent;

static const uint32 INVALID_TEMPLATE_INDEX = -1;

USTRUCT()
struct FTemplateActorData
{
    GENERATED_USTRUCT_BODY()

    UPROPERTY(Transient)
    int32 InstanceId;

    UPROPERTY(Transient)
    uint32 TemplateId;

    UPROPERTY(Transient)
    FVector_NetQuantize Location;

    UPROPERTY(Transient)
    uint16 Yaw;

    UPROPERTY(Transient)
    uint8 CustomType;

    UPROPERTY(Transient, NotReplicated)
    bool Pickuped;

    // 这俩必须传给客户端，如果让客户端自己靠location算出cell，有可能会因为浮点数原因不准，导致cell对不上
    UPROPERTY(Transient)
    uint32 HumanCellIndex;

    UPROPERTY(Transient)
    uint32 ShipCellIndex;

    uint32 IndexInHumanCell;
    uint32 IndexInShipCell;

    FORCEINLINE const bool IsValid() const
    {
        return InstanceId != 0;
    }

    FORCEINLINE void Clear()
    {
        InstanceId = 0;
        TemplateId = 0;
        Location = FVector::ZeroVector;
        Yaw = 0;
        CustomType = 0;
        Pickuped = false;

        HumanCellIndex = INVALID_TEMPLATE_INDEX;
        ShipCellIndex = INVALID_TEMPLATE_INDEX;
        IndexInHumanCell = INVALID_TEMPLATE_INDEX;
        IndexInShipCell = INVALID_TEMPLATE_INDEX;
    }

    FORCEINLINE void Set(int32 InInstanceId, uint32 InTemplateId, const FVector_NetQuantize& InLocation, uint16 InYaw, uint8 InCustomType, bool InPickuped)
    {
        InstanceId = InInstanceId;
        TemplateId = InTemplateId;
        Location = InLocation;
        Yaw = InYaw;
        CustomType = InCustomType;
        Pickuped = InPickuped;

        HumanCellIndex = INVALID_TEMPLATE_INDEX;
        ShipCellIndex = INVALID_TEMPLATE_INDEX;
        IndexInHumanCell = INVALID_TEMPLATE_INDEX;
        IndexInShipCell = INVALID_TEMPLATE_INDEX;
    }

    FORCEINLINE FTemplateActorData()
    {
        Clear();
    }

    FORCEINLINE FTemplateActorData(int32 InInstanceId, uint32 InTemplateId, const FVector_NetQuantize& InLocation, uint16 InYaw, uint8 InCustomType, bool InPickuped)
    {
        Set(InInstanceId, InTemplateId, InLocation, InYaw, InCustomType, InPickuped);
    }

    FORCEINLINE FTemplateActorData(const FTemplateActorData& Other)
    {
        InstanceId = Other.InstanceId;
        TemplateId = Other.TemplateId;
        Location = Other.Location;
        Yaw = Other.Yaw;
        CustomType = Other.CustomType;
        Pickuped = Other.Pickuped;

        HumanCellIndex = Other.HumanCellIndex;
        ShipCellIndex = Other.ShipCellIndex;
        IndexInHumanCell = Other.IndexInHumanCell;
        IndexInShipCell = Other.IndexInShipCell;
    }

    static FORCEINLINE int GetSerializeSize()
    {
        // 因为FVector_NetQuantize这东西有压缩，所以这里是粗略大小
        return sizeof(FTemplateActorData) - sizeof(uint32) - sizeof(uint32);
    }

    friend FORCEINLINE FArchive& operator<<(FArchive& Ar, FTemplateActorData& Data)
    {
        return Ar 
            << Data.InstanceId 
            << Data.TemplateId
            << Data.Location
            << Data.Yaw 
            << Data.CustomType
            << Data.Pickuped
            << Data.HumanCellIndex
            << Data.ShipCellIndex;
    }
};


//////////////////////////////////////////////////////////////////////////
struct FTemplateCellData
{
    static const int INIT_DATA_SIZE = 64; 
    static const int DELETE_INDEX_SIZE = INIT_DATA_SIZE/2;
    static const int INIT_HISTORY_SIZE = INIT_DATA_SIZE/2;
    static const int PLAYER_SIZE = 8;

#define VERIFY_ARRAY_SIZE(x, step) if(x.Num() == x.Max()) x.Reserve(x.Max() + step);

    FORCEINLINE FTemplateCellData()
        : History(0)
        , PickupHistory(0)
    {
    }

    FORCEINLINE void AddHistory(int32 InstanceId)
    {
        VERIFY_ARRAY_SIZE(HistoryIds, INIT_HISTORY_SIZE);
        HistoryIds.Add(InstanceId);
        ++History;
        if (HistoryIds.Num() >= TemplateIndices.Num()*2)
        {
            HistoryIds.RemoveAt(0, HistoryIds.Num() - TemplateIndices.Num());
        }
    }

    FORCEINLINE uint32 Add(int32 InstanceId, int TemplateIndex, bool bSaveToHistory)
    {
        if (bSaveToHistory)
        {
            AddHistory(InstanceId);
        }

        uint32 Ret = INVALID_TEMPLATE_INDEX;
        if (DeletedIndices.Num() > 0)
        {
            Ret = (uint32)DeletedIndices.Pop(false);
            TemplateIndices[Ret] = TemplateIndex;            
        }
        else
        {
            Ret = TemplateIndices.Num();
            VERIFY_ARRAY_SIZE(TemplateIndices, INIT_DATA_SIZE);
            TemplateIndices.Add(TemplateIndex);
        }

        return Ret;
    }

    FORCEINLINE void Remove(int32 InstanceId, int IndexInCell, bool bSaveToHistory)
    {
        check(IndexInCell >= 0 && IndexInCell <= TemplateIndices.Num());
        TemplateIndices[IndexInCell] = -1;
        
        VERIFY_ARRAY_SIZE(DeletedIndices, DELETE_INDEX_SIZE);
        DeletedIndices.Add(IndexInCell);

        if (bSaveToHistory)
        {
            AddHistory(-InstanceId);
        }
    }

    FORCEINLINE int GetTemplateIndex(int IndexInCell)
    {
        check(IndexInCell >= 0 && IndexInCell < TemplateIndices.Num());
        return TemplateIndices[IndexInCell];
    }

    FORCEINLINE const bool IsValidIndex(int TemplateIndex) const
    {
        return TemplateIndex >= 0;
    }

    FORCEINLINE void AddPlayer(UTemplateActorDataComponent* Player)
    {
        check(Players.Find(Player) == INDEX_NONE);
        Players.Add(Player);
    }

    FORCEINLINE void RemovePlayer(UTemplateActorDataComponent* Player)
    {
        Players.Remove(Player);
    }

    FORCEINLINE int GetDataCount()
    {
        return TemplateIndices.Num() - DeletedIndices.Num();
    }

    FORCEINLINE int GetAllocatedSize()
    {
        return TemplateIndices.GetAllocatedSize() +
            DeletedIndices.GetAllocatedSize() +
            HistoryIds.GetAllocatedSize() +            
            Players.GetAllocatedSize();
    }

    TArray<int, TInlineAllocator<INIT_DATA_SIZE> > TemplateIndices;
    TArray<int32, TInlineAllocator<DELETE_INDEX_SIZE> > DeletedIndices;
    TArray<int32, TInlineAllocator<INIT_HISTORY_SIZE> > HistoryIds;
    TArray<TWeakObjectPtr<UTemplateActorDataComponent>, TInlineAllocator<PLAYER_SIZE> > Players;
    uint32 History;
    uint32 PickupHistory;

#undef VERIFY_ARRAY_SIZE
};

//////////////////////////////////////////////////////////////////////////
UCLASS()
class COMMON_API UTemplateActorDataManager : public UObject
{
    GENERATED_UCLASS_BODY()

private:
    template<typename T, uint32 InitSize, uint32 StepSize>
    class TArrayWithRecycle
    {
    public:
        FORCEINLINE TArrayWithRecycle()
        {
            Realloc(InitSize);
        }
        FORCEINLINE T& Alloc(int& OutIndex)
        {
            if (Deleted.Num() == 0)
            {
                Realloc(StepSize);
            }
            OutIndex = Deleted.Pop(false);
            return Datas[OutIndex];
        }
        FORCEINLINE void Dealloc(int Index)
        {
            Deleted.Add(Index);
        }
        FORCEINLINE T& operator[](int Index)
        {
            return Datas[Index];
        }
        FORCEINLINE const T& operator[](int Index) const
        {
            return Datas[Index];
        }
        FORCEINLINE void Clear()
        {
            Deleted.Empty(Datas.Num());
            for (int ii=Datas.Num()-1; ii>=0; --ii)
            {
                Deleted.Add(ii);
            }
        }
        FORCEINLINE int GetAllocatedSize() const
        {
            return Datas.GetAllocatedSize() + Deleted.GetAllocatedSize();
        }
    private:
        FORCEINLINE void Realloc(int Size)
        {
            int OldCount = Datas.Num();
            Datas.AddDefaulted(Size);
            Deleted.Reserve(Datas.Num());
            for (int ii = Datas.Num() - 1; ii >= OldCount; --ii)
            {
                Deleted.Add(ii);
            }
        }
    private:
        TArray<T, TInlineAllocator<InitSize> > Datas;
        TArray<int, TInlineAllocator<InitSize> > Deleted;
    };

public:
    UFUNCTION()
    void Init(float InMapWidth, float InMapHeight, float InMapCenterX, float InMapCenterY, float InHumanCellSize, float InShipCellSize);

    UFUNCTION()
    void Clear();

    UFUNCTION()
    void AddData(int32 InstanceId, uint32 TemplateId, float X, float Y, float Z, uint16 Yaw, uint8 CustomType);

    UFUNCTION()
    void AddGlobalData(int32 InstanceId, uint32 TemplateId, float X, float Y, float Z, uint16 Yaw, uint8 CustomType);

    UFUNCTION()
    bool RemoveData(int32 InstanceId);

    UFUNCTION()
    void FinishInit();

    UFUNCTION()
    void SetPickuped(int32 InstanceId);

    UFUNCTION()
    void PrintDebugInfo();

    UFUNCTION()
    void SetTickInterval(float Interval);

    // 给AI用的俩接口
    UFUNCTION(BlueprintPure)
    int FindInstanceIdsInRadius(bool IsShip, const FVector& Location, float Radius, TArray<int32>& Out);

    UFUNCTION(BlueprintPure)
    FVector FindLocationByInstanceId(int32 InstanceId);

    UFUNCTION()
    bool IsValidLocation(float X, float Y);

public:
    void Update(float DeltaTime);    
    void AddPlayer(UTemplateActorDataComponent* Player);
    void RemovePlayer(UTemplateActorDataComponent* Player);
    FTemplateCellData* FindCellData(bool IsShip, uint32 CellIndex, bool bCreateIfNull);
    uint32 FindCellIndex(bool IsShip, float X, float Y);
    void Find9Cells(bool IsShip, uint32 CenterCell, TArray<uint32, TInlineAllocator<9> >& Out);    
    FTemplateActorData* FindTemplateData(int32 InstanceId);
    FTemplateActorData& GetTemplateData(int TemplateIndex);
    void GetMapInfo(FVector2D& OutMapSize, FVector2D& OutMapCenter, float& OutHumanCellSize, float& OutShipCellSize);    
    FTemplateActorData& AddDataWithCellIndices(int32 InstanceId, uint32 TemplateId, const FVector_NetQuantize& Location,
        uint16 Yaw, uint8 CustomType,
        uint32 ShipCellIndex, uint32 HumanCellIndex);
    void GetGlobalData(TArray<FTemplateActorData>& Out);
    
public:
    // 这些delegate其实放这不太好，放controller里更好，但放controller里就得有个绑定解绑的时机问题，所以最后还是为了方便放这里了
    DECLARE_DYNAMIC_DELEGATE_FiveParams(FOnActorCreated, int32, InstanceId, uint32, TemplateId, const FVector_NetQuantize&, Location, uint16, Yaw, uint8, CustomType);
    DECLARE_DYNAMIC_DELEGATE_OneParam(FOnMultiActorCreated, const TArray<FTemplateActorData>&, Datas);
    DECLARE_DYNAMIC_DELEGATE_OneParam(FOnActorDestroyed, int32, InstanceId);
    DECLARE_DYNAMIC_DELEGATE_OneParam(FOnMultiActorDestroyed, const TArray<int32>&, InstanceIds);
    DECLARE_DYNAMIC_DELEGATE_OneParam(FOnPickupUpdate, int32, InstanceId);
    DECLARE_DYNAMIC_DELEGATE_OneParam(FOnMultiPickupUpdate, const TArray<int32>&, InstanceIds);

    UPROPERTY()
    FOnActorCreated OnActorCreated;

    UPROPERTY()
    FOnMultiActorCreated OnMultiActorCreated;

    UPROPERTY()
    FOnActorDestroyed OnActorDestroyed;

    UPROPERTY()
    FOnMultiActorDestroyed OnMultiActorDestroyed;

    UPROPERTY()
    FOnPickupUpdate OnPickupUpdate;

    UPROPERTY()
    FOnMultiPickupUpdate OnMultiPickupUpdate;

private:
    FTemplateCellData* FindFromPool(TArray<int>& Cells, int Index);
    FTemplateCellData& FindCheckFromPool(TArray<int>& Cells, int Index);
    FTemplateCellData& FindOrAddFromPool(TArray<int>& Cells, int Index);

public:
    float HumanCellSize;
    float ShipCellSize;
    FVector2D MapSize;
    FVector2D MapCenter;

    bool InitFinishedInServer;
    float TickInterval;
    float TickTime;
    bool IsServer;

    // humancells和shipcells索引到cellPool中，之所以这样是因为在实际中，cell的利用率比较低，所以如果上来把FTemplateCellData都分配出来，肯定有大量浪费的，所以搞成了这种用时才分配的方式
    TArray<int> HumanCells;
    TArray<int> ShipCells;
    TArray<FTemplateCellData, TInlineAllocator<256> > CellPool;

    // 所有真正的data，也是靠索引对起来的
    TMap<int32, int> TemplateIndices;
    TArrayWithRecycle<FTemplateActorData, 512, 512> TemplateDatas;
    TSet<int32> GlobalDataIds;

    // 玩家
    TArray<TWeakObjectPtr<UTemplateActorDataComponent>, TInlineAllocator<100> > Players;
};


//////////////////////////////////////////////////////////////////////////
// 这东西挂到player controller上
UCLASS(Blueprintable, meta = (BlueprintSpawnableComponent))
class COMMON_API UTemplateActorDataComponent : public UActorComponent
{
    GENERATED_UCLASS_BODY()

public:
    void Clear();
    void OnCellDataAdded(bool IsShip, uint32 CellIndex, uint32 CellHistory, const FTemplateActorData& Data);
    void OnCellDataRemoved(bool IsShip, uint32 CellIndex, uint32 CellHistory, const FTemplateActorData& Data);
    void OnUpdatePickeuped(bool IsShip, uint32 CellIndex, uint32 CellHistory, const FTemplateActorData& Data);
    void UpdateCells();
    int GetAllocatedSize();
    void GetLocatedCells(TArray<uint32>& OutCellIndices);
    const bool IsShip() const { return IsShipPawn; }
    void ProcessPendingActors();
    void OnMultiGlobalDataAdded(const TArray<FTemplateActorData>& Datas);
    void OnGlobalDataAdded(const FTemplateActorData& Data);
    void OnGlobalDataRemoved(int32 InstanceId);    

private:
    virtual void BeginPlay() override;
    virtual void EndPlay(const EEndPlayReason::Type EndPlayReason) override;
    //virtual void TickComponent(float DeltaTime, enum ELevelTick TickType, FActorComponentTickFunction *ThisTickFunction) override;   

public:
    UFUNCTION()
    bool RegisterToManager(UTemplateActorDataManager* NewManager);

    UFUNCTION()
    const bool IsUpdateEnabled() const { return EnableUpdate; }

    UFUNCTION()
    void InitClientMapInfo();

    UFUNCTION()
    void SetProcessActorCountInOneTick(uint32 Count) { ProcessActorCountInOneTick = Count; }

    UFUNCTION()
    void SetWatchedTarget(APawn* Pawn) { WatchedTarget = Pawn; }

private:
    UFUNCTION(Reliable, Client)
    void ClientReceivedMapInfo(const FVector2D& InMapSize, const FVector2D& InMapCenter, float InHumanCellSize, float InShipCellSize);

    // 因为人船互换有时间差，所以rpc过来时可能还没换，所以这里加了个bool
    UFUNCTION(Reliable, Client)
    void ClientReceivedRemainInstanceIds(bool IsShip, uint32 CellIndex, const TArray<int32>& InstanceIds, const TArray<uint8>& ZipData);

    UFUNCTION(Reliable, Client)
    void ClientReceivedActorDestroyed(bool IsShip, uint32 CellIndex, int32 InstanceId);

    UFUNCTION(Reliable, Client)
    void ClientReceivedMultiActorDestroyed(bool IsShip, uint32 CellIndex, const TArray<int32>& InstanceIds, const TArray<uint8>& ZipData);

    UFUNCTION(Reliable, Client)
    void ClientReceivedActorCreated(int32 InstanceId, uint32 TemplateId, const FVector_NetQuantize& Location, 
        uint16 Yaw, uint8 CustomType, 
        uint32 ShipCellIndex, uint32 HumanCellIndex);

    UFUNCTION(Reliable, Client)
    void ClientReceivedMultiActorCreated(const TArray<FTemplateActorData>& NewActorDatas, const TArray<uint8>& ZipData);

    UFUNCTION(Reliable, Client)
    void ClientReceivedPickupedId(int32 InstanceId);

    UFUNCTION(Reliable, Client)
    void ClientReceivedMultiPickupedIds(const TArray<int32>& InstanceIds);

    UFUNCTION(Reliable, Client)
    void ClientReceivedGlobalActorCreated(int32 InstanceId, uint32 TemplateId, const FVector_NetQuantize& Location,
        uint16 Yaw, uint8 CustomType);

    UFUNCTION(Reliable, Client)
    void ClientReceivedMultiGlobalActorCreated(const TArray<FTemplateActorData>& NewActorDatas);

    UFUNCTION(Reliable, Client)
    void ClientReceivedGlobalActorDestoryed(int32 InstanceId);

    //UFUNCTION(Reliable, Client)
    //void ClientTest(const TArray<FTemplateActorData>& NewActorDatas, const TArray<uint32>& ShipCells, const TArray<uint32>& HumanCells);
    //void ServerTest();

private:
    template <size_t InitSize, size_t StepSize>
    class FPendingProcessList
    {
    private:
        struct FNode
        {
            FNode() : Self(-1), Pre(-1), Next(-1), Value(-1)
            {}

            int32 Self;
            int32 Pre;
            int32 Next;
            int32 Value;
        };
        typedef TArray<FNode, TInlineAllocator<InitSize>> TNodeList;

    public:
        FPendingProcessList()
            : Head(-1), Tail(-1), Deleted(-1)
        {
            check(InitSize > 0 && StepSize > 0);
            Expand(InitSize);
        }

        FORCEINLINE void PushBack(const int32& Value)
        {
            auto& NewNode = CreateNode();
            NewNode.Value = Value;

            if (Head < 0)
            {
                check(Tail < 0);
                Head = NewNode.Self;
                Tail = Head;
            }
            else
            {
                auto& OldTailNode = *GetNode(Tail);
                check(OldTailNode.Next < 0);
                Tail = NewNode.Self;
                OldTailNode.Next = Tail;
                NewNode.Pre = OldTailNode.Self;
            }
        }

        FORCEINLINE int32 PopFront()
        {
            if (Head < 0)
            {
                return -1;
            }

            auto& OldHeadNode = *GetNode(Head);
            int OutValue = OldHeadNode.Value;
            if (Tail == Head)
            {
                Tail = -1;
                Head = -1;
            }
            else
            {
                Head = OldHeadNode.Next;
                auto* NewHeadNode = GetNode(Head);
                check(NewHeadNode);
                NewHeadNode->Pre = -1;
            }

            DestroyNode(OldHeadNode);
            return OutValue;
        }

        FORCEINLINE void Remove(int32 Value)
        {
            if (Head < 0)
            {
                return;
            }

            for (auto* Node = GetNode(Head); Node; Node = GetNode(Node->Next))
            {
                if (Node->Value == Value)
                {
                    if (Node->Self == Head)
                    {
                        Head = Node->Next;
                    }
                    if (Node->Self == Tail)
                    {
                        Tail = Node->Pre;
                    }
                    auto* PreNode = GetNode(Node->Pre);
                    auto* NextNode = GetNode(Node->Next);
                    if (PreNode)
                    {
                        PreNode->Next = NextNode ? NextNode->Self : -1;
                    }
                    if (NextNode)
                    {
                        NextNode->Pre = PreNode ? PreNode->Self : -1;
                    }

                    DestroyNode(*Node);
                    break;
                }
            }
        }

        FORCEINLINE const bool IsEmpty() const
        {
            return Head < 0;
        }

        FORCEINLINE void Clear()
        {
            auto* TailNode = GetNode(Tail);
            if (TailNode)
            {
                TailNode->Next = Deleted;
                check(Head > 0);
                Deleted = Head;
            }            
            Head = -1;
            Tail = -1;
        }

        FORCEINLINE int GetAllocatedSize()
        {
            return NodeList.GetAllocatedSize();
        }

    private:
        FORCEINLINE FNode* GetNode(int32 Index)
        {
            if (Index < 0 || Index >= NodeList.Num())
            {
                return nullptr;
            }

            return &NodeList[Index];
        }

        FORCEINLINE void Expand(uint32 Count)
        {
            check(Deleted < 0);
            check(Count > 0);
            int Start = NodeList.Num();
            int End = Start + Count;
            NodeList.AddDefaulted(Count);
            NodeList[Start].Self = Start;
            for (int ii = Start+1; ii < End; ++ii)
            {
                auto& PreNode = NodeList[ii - 1];
                auto& CurrentNode = NodeList[ii];
                CurrentNode.Self = ii;
                PreNode.Next = ii;
            }

            NodeList[End - 1].Next = Deleted;
            Deleted = Start;
        }

        FORCEINLINE FNode& CreateNode()
        {            
            if (Deleted < 0)
            {
                Expand(StepSize);
            }

            check(Deleted >= 0);
            FNode& Ret = NodeList[Deleted];
            Deleted = Ret.Next;
            Ret.Next = -1;
            Ret.Pre = -1;
            return Ret;
        }

        FORCEINLINE void DestroyNode(FNode& Node)
        {
            Node.Next = Deleted;
            Deleted = Node.Self;
        }

    private:
        TNodeList NodeList;
        int32 Head;
        int32 Tail;
        int32 Deleted;
    };

    struct FSavedHistory
    {
        uint32 DataHistory;
        uint32 PickupedHistory;
        FSavedHistory()
            : DataHistory(INVALID_TEMPLATE_INDEX)
            , PickupedHistory(INVALID_TEMPLATE_INDEX)
        {}
    };

private:
    void UpdateHistory(bool bShip, uint32 CellIndex, uint32 NewHistory, bool IsPickupedHistory);
    void LeaveAllCells();
    void OnLeaveCell(uint32 CellIndex);
    void OnEnterCell(uint32 CellIndex);
    void SendDataWhenEnterCell(uint32 CellIndex, FTemplateCellData& Cell, uint32& SavedHistory);
    void SendPickupedDataWhenEnterCell(uint32 CellIndex, FTemplateCellData& Cell, uint32& SavedHistory);
    bool TryRemoveData(int32 InstanceId);
    bool TryAddData(int32 InstanceId, uint32 TemplateId, const FVector_NetQuantize& Location, 
        uint16 Yaw, uint8 CustomType,
        uint32 ShipCellIndex, uint32 HumanCellIndex);
    bool TryAddSendedData(int32 InstanceId, const FVector_NetQuantize& Location);
    bool TryRemoveSendedData(int32 InstanceId, const FVector_NetQuantize& Location);

#if ENABLE_GAME_MESSAGE_OBFUSCATION
private:
    void Compress(const TArray<uint8>& InData, TArray<uint8>& OutCompressedData);
    void Compress(const TArray<FTemplateActorData>& ActorDatas, TArray<uint8>& OutCompressedData);
    void Compress(const TArray<int32>& InstanceIds, TArray<uint8>& OutCompressedData);
    void Uncompress(const TArray<uint8>& InCompressedData, TArray<uint8>& OutData);
    void Uncompress(const TArray<uint8>& InCompressedData, TArray<FTemplateActorData>& OutActorDatas);
    void Uncompress(const TArray<uint8>& InCompressedData, TArray<int32>& OutInstanceIds);
#endif

private:
    TArray<uint32, TInlineAllocator<9> > Cells;
    TMap<uint32, FSavedHistory> HumanCellHistory;
    TMap<uint32, FSavedHistory> ShipCellHistory;
    TMap<int32, FVector_NetQuantize> Sended;     // 这个在服务器表示是否发给过客户端，在客户端表示是否发给了lua
    UTemplateActorDataManager* Manager;
    APlayerController* Controller;
    uint32 CurrentCell;
    bool IsShipPawn;
    bool EnableUpdate;
    FPendingProcessList<128, 64> PendingActors;
    uint32 ProcessActorCountInOneTick;
    TWeakObjectPtr<APawn> WatchedTarget;
    TArray<uint8> TempCompressBuffer;

#if ENABLE_DEBUG_TEMPLATE_ACTOR
    bool IsClientTested;
    bool IsSendedAllToClient;
    TMap<int32, FVector_NetQuantize> ClientTestInstanceIds;
#endif
};