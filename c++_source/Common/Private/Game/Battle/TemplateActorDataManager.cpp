
#include "Game/Battle/TemplateActorDataManager.h"
#include "Common.h"
#include "Game/GameCommon.h"
#include "KMCharacter.h"
#include "Game/Battle/PiratesGridTriggerManager.h"
#include "Game/Battle/PiratesGridTypeManager.h"

#if ENABLE_GAME_MESSAGE_OBFUSCATION
THIRD_PARTY_INCLUDES_START
#include "ThirdParty/zlib/zlib-1.2.5/Inc/zlib.h"
THIRD_PARTY_INCLUDES_END
#endif

#if !UE_SERVER
#include "BuglyCrashReportBPLibrary.h"
#endif

DEFINE_LOG_CATEGORY_STATIC(LogTemplateActor, Log, All)

#define VERIFY_CONTAINER_SIZE(x, step) if(x.Num() == x.Max()) x.Reserve(x.Max() + step);

#define DEBUG_DATA 0
#if DEBUG_DATA
#define DEBUG_LOG UE_LOG
#else
#define DEBUG_LOG(...)
#endif

static const int CELL_POOL_STEP = 256;

UTemplateActorDataManager::UTemplateActorDataManager(const FObjectInitializer& ObjectInitializer)
    : Super(ObjectInitializer)
    , HumanCellSize(0.0f)
    , ShipCellSize(0.0f)
    , InitFinishedInServer(false)
#if ENABLE_DEBUG_TEMPLATE_ACTOR
    , TickInterval(0.3f)
#else
    , TickInterval(1.0f)
#endif    
    , TickTime(0.0f)
    , IsServer(false)    
{
}

void UTemplateActorDataManager::Init(float InMapWidth, float InMapHeight, float InMapCenterX, float InMapCenterY, float InHumanCellSize, float InShipCellSize)
{
    check(InMapWidth > 0.0f && InMapHeight > 0.0f);
    check(InHumanCellSize > 0.0f && InShipCellSize > 0.0f)

    Clear();

    MapSize.X = InMapWidth;
    MapSize.Y = InMapHeight;
    MapCenter.X = InMapCenterX;
    MapCenter.Y = InMapCenterY;
    HumanCellSize = InHumanCellSize;
    ShipCellSize = InShipCellSize;

    UWorld* World = GetWorld();
    IsServer = false;
    if (World)
    {
        IsServer = World->IsServer();
    }
    
    int HumanCellWCount = FMath::CeilToInt(InMapWidth / InHumanCellSize);
    int HumanCellHCount = FMath::CeilToInt(InMapHeight / InHumanCellSize);
    int ShipCellWCount = FMath::CeilToInt(InMapWidth / InShipCellSize);
    int ShipCellHCount = FMath::CeilToInt(InMapHeight / InShipCellSize);

    int HumanCellTotalCount = HumanCellWCount * HumanCellHCount;
    int ShipCellTotalCount = ShipCellWCount * ShipCellHCount;
    HumanCells.Reserve(HumanCellTotalCount);
    ShipCells.Reserve(ShipCellTotalCount);

    for (int ii=0; ii< HumanCellTotalCount; ++ii)
    {
        HumanCells.Add(-1);
    }
    for (int ii = 0; ii < ShipCellTotalCount; ++ii)
    {
        ShipCells.Add(-1);
    }
}

void UTemplateActorDataManager::Clear()
{
    auto TempPlayers = Players;
    Players.Empty();
    for (auto& Player: TempPlayers)
    {
        if (Player.IsValid())
        {
            Player->Clear();
        }        
    }

    HumanCells.Empty();
    ShipCells.Empty();
    CellPool.Empty();
    TemplateIndices.Empty();
    GlobalDataIds.Empty();
    TemplateDatas.Clear();
}

void UTemplateActorDataManager::AddData(int32 InstanceId, uint32 TemplateId, float X, float Y, float Z, uint16 Yaw, uint8 CustomType)
{
    check(FindTemplateData(InstanceId) == nullptr);

    auto RegionType = UGameCommon::Get(this)->GetGridTypeManager()->GetRegionType(X, Y);
    checkf(RegionType != EPiratesGridRegionType::Unknown, TEXT("GetGridType faild, InstanceId: %d, TemplateId: %d, Location [%.2f, %.2f, %.2f]"), 
        InstanceId, TemplateId, X, Y, Z);
    bool IsOcean = RegionType == EPiratesGridRegionType::Ocean || RegionType == EPiratesGridRegionType::Port;

    FVector_NetQuantize Location(X, Y, Z);
    uint32 ShipCellIndex = IsOcean ? FindCellIndex(true, X, Y) : INVALID_TEMPLATE_INDEX;
    uint32 HumanCellIndex = FindCellIndex(false, X, Y);    

    AddDataWithCellIndices(InstanceId, TemplateId, Location, Yaw, CustomType,
        ShipCellIndex, HumanCellIndex);
}

FTemplateActorData& UTemplateActorDataManager::AddDataWithCellIndices(int32 InstanceId, uint32 TemplateId, const FVector_NetQuantize& Location,
    uint16 Yaw, uint8 CustomType,
    uint32 ShipCellIndex, uint32 HumanCellIndex)
{
    check(FindTemplateData(InstanceId) == nullptr);
    check(ShipCellIndex != INVALID_TEMPLATE_INDEX || HumanCellIndex != INVALID_TEMPLATE_INDEX);

    int TemplateIndex = 0;
    FTemplateActorData& NewData = TemplateDatas.Alloc(TemplateIndex);    
    NewData.Set(InstanceId, TemplateId, Location, Yaw, CustomType, false);
    TemplateIndices.Add(InstanceId, TemplateIndex);

    auto AddToCell = [&](bool bShip, uint32 CellIndex) {
        if (CellIndex == INVALID_TEMPLATE_INDEX)
        {
            return;
        }
        auto& AllCells = bShip ? ShipCells : HumanCells;
#if UE_SERVER || WITH_EDITOR
        check(CellIndex < (uint32)AllCells.Num());
#else
        if (CellIndex >= (uint32)AllCells.Num())
        {
            UBuglyCrashReportBPLibrary::ReportExceptionWithCategory(6, TEXT("InvalidCellIndex"), TEXT("InvalidCellIndex"), 
                FString::Printf(TEXT("InstanceId: %d, TemplateId: %d, Pos: %.2f, %.2f, %.2f, Ship: %d, CellIndex: %d, AllCellCount: %d"), 
                    InstanceId, TemplateId,
                    Location.X, Location.Y, Location.Z,
                    bShip?1:0, CellIndex, AllCells.Num()));
            return;
        }
#endif
        auto& Cell = FindOrAddFromPool(AllCells, CellIndex);
        uint32 IndexInCell = Cell.Add(InstanceId, TemplateIndex, InitFinishedInServer);

        if (bShip)
        {
            NewData.ShipCellIndex = CellIndex;
            NewData.IndexInShipCell = IndexInCell;
        }
        else
        {
            NewData.HumanCellIndex = CellIndex;
            NewData.IndexInHumanCell = IndexInCell;
        }

        if (InitFinishedInServer)
        {
            for (auto Player : Cell.Players)
            {
                if (Player.IsValid())
                {
                    Player->OnCellDataAdded(bShip, CellIndex, Cell.History, NewData);
                }                
            }
        }
    };

    AddToCell(true, ShipCellIndex);
    AddToCell(false, HumanCellIndex);
    return NewData;
}

void UTemplateActorDataManager::GetGlobalData(TArray<FTemplateActorData>& Out)
{
    if (GlobalDataIds.Num() == 0)
    {
        return;
    }

    Out.Reserve(GlobalDataIds.Num());
    for (auto Iter = GlobalDataIds.CreateIterator(); Iter; ++Iter)
    {
        auto Data = FindTemplateData(*Iter);
        check(Data);
        Out.Emplace(*Data);
    }
}

void UTemplateActorDataManager::AddGlobalData(int32 InstanceId, uint32 TemplateId, float X, float Y, float Z, uint16 Yaw, uint8 CustomType)
{
    check(FindTemplateData(InstanceId) == nullptr);
    check(!GlobalDataIds.Contains(InstanceId));

    int TemplateIndex = 0;
    FVector_NetQuantize Location(X, Y, Z);
    FTemplateActorData& NewData = TemplateDatas.Alloc(TemplateIndex);
    NewData.Set(InstanceId, TemplateId, Location, Yaw, CustomType, false);
    TemplateIndices.Add(InstanceId, TemplateIndex);
    GlobalDataIds.Add(InstanceId);

    if (InitFinishedInServer)
    {
        for (auto Player : Players)
        {
            if (Player.IsValid())
            {
                Player->OnGlobalDataAdded(NewData);
            }
        }
    }
}

bool UTemplateActorDataManager::RemoveData(int32 InstanceId)
{
    int TemplateIndex = -1;
    if (!TemplateIndices.RemoveAndCopyValue(InstanceId, TemplateIndex))
    {
        DEBUG_LOG(LogTemplateActor, Log, TEXT("RemoveData failed, id: %d"), InstanceId);
        return false;
    }

    auto& Data = TemplateDatas[TemplateIndex];
    check(Data.InstanceId == InstanceId);

    auto DeleteFromCell = [&](bool bShip) {
        uint32 CellIndex = bShip ? Data.ShipCellIndex : Data.HumanCellIndex;
        uint32 IndexInCell = bShip ? Data.IndexInShipCell : Data.IndexInHumanCell;
        if (CellIndex == INVALID_TEMPLATE_INDEX || IndexInCell == INVALID_TEMPLATE_INDEX)
        {
            return;
        }

        FTemplateCellData& Cell = FindCheckFromPool(bShip ? ShipCells : HumanCells, CellIndex);        
        check(IndexInCell < (uint32)Cell.TemplateIndices.Num());
        Cell.Remove(InstanceId, IndexInCell, InitFinishedInServer);
        DEBUG_LOG(LogTemplateActor, Log, TEXT("RemoveData, id: %d, IsShip: %d, CellIndex: %d"), InstanceId, bShip?1:0, CellIndex);

        if (InitFinishedInServer)
        {
            for (auto Player : Cell.Players)
            {
                if (Player.IsValid())
                {
                    Player->OnCellDataRemoved(bShip, CellIndex, Cell.History, Data);
                }
            }
        }
    };
    
    DeleteFromCell(true);
    DeleteFromCell(false);

    if (GlobalDataIds.Remove(InstanceId) > 0)
    {
        if (InitFinishedInServer)
        {
            for (auto Player : Players)
            {
                if (Player.IsValid())
                {
                    Player->OnGlobalDataRemoved(InstanceId);
                }
            }
        }
    }

    TemplateDatas.Dealloc(TemplateIndex);

    DEBUG_LOG(LogTemplateActor, Log, TEXT("RemoveData successed, id: %d"), InstanceId);
    return true;
}

void UTemplateActorDataManager::FinishInit()
{
    if (InitFinishedInServer)
    {
        return;
    }

    InitFinishedInServer = true;

    if (GlobalDataIds.Num() > 0 && Players.Num() > 0)
    {
        TArray<FTemplateActorData> TempDatas;
        GetGlobalData(TempDatas);

        for (auto Player : Players)
        {
            if (Player.IsValid())
            {
                Player->OnMultiGlobalDataAdded(TempDatas);
            }
        }
    }
}

void UTemplateActorDataManager::AddPlayer(UTemplateActorDataComponent* Player)
{
    if (Players.Find(Player) != INDEX_NONE)
    {
        return;
    }

    Players.Add(Player);
}

void UTemplateActorDataManager::RemovePlayer(UTemplateActorDataComponent* Player)
{
    Players.Remove(Player);
}

FTemplateCellData* UTemplateActorDataManager::FindCellData(bool IsShip, uint32 CellIndex, bool bCreateIfNull)
{
    auto& AllCellData = IsShip ? ShipCells : HumanCells;
    if (CellIndex >= (uint32)AllCellData.Num())
    {
        return nullptr;
    }

    return bCreateIfNull ? &FindOrAddFromPool(AllCellData, CellIndex) : FindFromPool(AllCellData, CellIndex);    
}

uint32 UTemplateActorDataManager::FindCellIndex(bool IsShip, float X, float Y)
{
    check(MapSize.X > 0.0f && MapSize.Y > 0.0f);
    check(ShipCellSize > 0.0f && HumanCellSize > 0.0f);
    
    float CellSize = IsShip ? ShipCellSize : HumanCellSize;
    int CellXCount = FMath::CeilToInt(MapSize.X / CellSize);
    int CellYCount = FMath::CeilToInt(MapSize.Y / CellSize);
    int XIndex = (int)((X - MapCenter.X + MapSize.X / 2) / CellSize);
    int YIndex = (int)((Y - MapCenter.Y + MapSize.Y / 2) / CellSize);
    if ((XIndex < 0 || XIndex > CellXCount) || (YIndex < 0 || YIndex > CellYCount))
    {
        return INVALID_TEMPLATE_INDEX;
    }
   
    int RetIndex = YIndex * CellXCount + XIndex;    
    if (RetIndex >= 0 && RetIndex < (IsShip ? ShipCells.Num() : HumanCells.Num()))
    {
        return (uint32)RetIndex;
    }
    else
    {
        return INVALID_TEMPLATE_INDEX;
    }    
}

void UTemplateActorDataManager::Find9Cells(bool IsShip, uint32 CenterCell, TArray<uint32, TInlineAllocator<9> >& Out)
{
    check(CenterCell != INVALID_TEMPLATE_INDEX);

    float CellSize = IsShip ? ShipCellSize : HumanCellSize;
    int CellXCount = IsShip ? FMath::CeilToInt(MapSize.X / ShipCellSize) : FMath::CeilToInt(MapSize.X / HumanCellSize);
    int CellYCount = IsShip ? FMath::CeilToInt(MapSize.Y / ShipCellSize) : FMath::CeilToInt(MapSize.Y / HumanCellSize);
    int CellX = CenterCell % CellXCount;
    int CellY = CenterCell / CellXCount;

    auto TryAdd = [&](int TempCellX, int TempCellY) {
        if (TempCellX >= 0 && TempCellX < CellXCount && TempCellY >= 0 && TempCellY < CellYCount)
        {
            Out.Add(TempCellY * CellXCount + TempCellX);
        }
    };

    Out.Add(CenterCell);
    TryAdd(CellX - 1,   CellY - 1);
    TryAdd(CellX - 1,   CellY);
    TryAdd(CellX - 1,   CellY + 1);
    TryAdd(CellX,       CellY - 1);
    TryAdd(CellX,       CellY + 1);
    TryAdd(CellX + 1,   CellY - 1);
    TryAdd(CellX + 1,   CellY);
    TryAdd(CellX + 1,   CellY + 1);
}

void UTemplateActorDataManager::GetMapInfo(FVector2D& OutMapSize, FVector2D& OutMapCenter, float& OutHumanCellSize, float& OutShipCellSize)
{
    OutMapSize = MapSize;
    OutMapCenter = MapCenter;
    OutHumanCellSize = HumanCellSize;
    OutShipCellSize = ShipCellSize;
}

void UTemplateActorDataManager::SetPickuped(int32 InstanceId)
{
    auto* Data = FindTemplateData(InstanceId);
    if (!Data)
    {
        return;
    }

    if (Data->Pickuped)
    {
        return;
    }

    Data->Pickuped = true;

    if (!InitFinishedInServer)
    {
        return;
    }

    auto UpdatePickuped = [&](bool bShip) {
        uint32 CellIndex = bShip ? Data->ShipCellIndex : Data->HumanCellIndex;
        auto IndexInCell = bShip ? Data->IndexInShipCell : Data->IndexInHumanCell;
        if (CellIndex == INVALID_TEMPLATE_INDEX || IndexInCell == INVALID_TEMPLATE_INDEX)
        {
            return;
        }

        auto& Cell = FindCheckFromPool(bShip ? ShipCells : HumanCells, CellIndex);
        ++Cell.PickupHistory;
        for (auto Player : Cell.Players)
        {
            if (Player.IsValid())
            {
                Player->OnUpdatePickeuped(bShip, CellIndex, Cell.PickupHistory, *Data);
            }
        }
    };

    UpdatePickuped(true);
    UpdatePickuped(false);
}

FTemplateCellData* UTemplateActorDataManager::FindFromPool(TArray<int>& Cells, int Index)
{
    if (Index < 0 || Index >= Cells.Num())
    {
        return nullptr;
    }

    int PoolIndex = Cells[Index];
    if (PoolIndex < 0 || PoolIndex >= CellPool.Num())
    {
        return nullptr;
    }

    return &CellPool[PoolIndex];
}

FTemplateCellData& UTemplateActorDataManager::FindCheckFromPool(TArray<int>& Cells, int Index)
{
    auto Cell = FindFromPool(Cells, Index);
    check(Cell);
    return *Cell;
}

FTemplateCellData& UTemplateActorDataManager::FindOrAddFromPool(TArray<int>& Cells, int Index)
{
    check(Index >= 0 && Index < Cells.Num());

    int& PoolIndex = Cells[Index];
    check(PoolIndex < CellPool.Num());

    if (PoolIndex < 0)
    {
        VERIFY_CONTAINER_SIZE(CellPool, CELL_POOL_STEP);
        PoolIndex = CellPool.Emplace();
    }
    return CellPool[PoolIndex];
}

void UTemplateActorDataManager::PrintDebugInfo()
{
    int TotalDataCount = TemplateIndices.Num();
    int TotalPlayerCount = Players.Num();
    int ManagerSize = sizeof(UTemplateActorDataManager) +
        HumanCells.GetAllocatedSize() +
        ShipCells.GetAllocatedSize() +
        CellPool.GetAllocatedSize() +
        TemplateIndices.GetAllocatedSize() +
        TemplateDatas.GetAllocatedSize() +
        GlobalDataIds.GetAllocatedSize() +
        Players.GetAllocatedSize();
    
    auto CaculateMemorySize = [&](TArray<int>& AllCells, const TCHAR* Desc, int CellSize) ->int {
        int MemorySize = 0;
        int MaxDataCount = 0;
        int MaxActorHistory = 0;        
        int MaxPlayer = 0;
        int EmptyCellCount = 0;
        int NullCellCount = 0;
        int ActorLessThen16 = 0;
        int ActorLessThen64 = 0;
        int ActorLessThen128 = 0;
        int ActorMoreThen128 = 0;
        int ActorTotalCount = 0;

        int MaxPickupCount = 0;
        int TotalPickupCount = 0;
        

        MemorySize = AllCells.GetAllocatedSize();
        for (int ii=0; ii<AllCells.Num(); ++ii)
        {
            auto Cell = FindFromPool(AllCells, ii);
            if (Cell == nullptr)
            {
                ++NullCellCount;
                continue;
            }

            int DataCount = Cell->GetDataCount();
            ActorTotalCount += DataCount;
            MemorySize += Cell->GetAllocatedSize();
            MaxDataCount = FMath::Max(MaxDataCount, DataCount);
            MaxActorHistory = FMath::Max(MaxActorHistory, (int)Cell->History);
            MaxPlayer = FMath::Max(MaxPlayer, Cell->Players.Num());

            if (DataCount == 0)
            {
                ++EmptyCellCount;
            }
            else
            {
                if (DataCount <= 16)
                {
                    ++ActorLessThen16;
                }
                else if (DataCount <= 64)
                {
                    ++ActorLessThen64;
                }
                else if (DataCount <= 128)
                {
                    ++ActorLessThen128;
                }
                else
                {
                    ++ActorMoreThen128;
                }
            }

            int PickupCount = 0;
            for (int jj=0; jj<Cell->TemplateIndices.Num(); jj++)
            {
                int TemplateIndex = Cell->TemplateIndices[jj];
                if (TemplateIndex >= 0)
                {
                    auto& Data = GetTemplateData(TemplateIndex);
                    if (Data.Pickuped)
                    {
                        ++PickupCount;                        
                    }
                }
            }

            MaxPickupCount = FMath::Max(PickupCount, MaxPickupCount);
            TotalPickupCount += PickupCount;
        }

#define PERCENTAGE(v, d) (d<=0 ? 0.0f : v*100.0f/d)

        // 这里还可以把cell数量分布打出来    
        int TotalCellCount = AllCells.Num();
        int UsedCellCount = TotalCellCount - EmptyCellCount - NullCellCount;
        UE_LOG(LogTemplateActor, Display, TEXT("==================================================================================================="));
        UE_LOG(LogTemplateActor, Display, TEXT("%s: MemorySize: %.2f kb, CellSize: %.2f m, TotalCount: %d, Used: %d [%.2f], Empty: %d [%.2f], Null %d [%.2f]"),
            Desc, MemorySize / 1024.0f, CellSize/100.0f, TotalCellCount,
            UsedCellCount, PERCENTAGE(UsedCellCount, TotalCellCount), 
            EmptyCellCount, PERCENTAGE(EmptyCellCount, TotalCellCount),
            NullCellCount, PERCENTAGE(NullCellCount, TotalCellCount));
        UE_LOG(LogTemplateActor, Display, TEXT("AverageDataInUsedCell: %.2f, Actor<=16: %d [%.2f], 16<Actor<=64: %d [%.2f], 64<Actor<=128: %d [%.2f], Actor>128: %d [%.2f]"),
            UsedCellCount <= 0.0f ? 0.0f : ActorTotalCount*1.0f/UsedCellCount, 
            ActorLessThen16, PERCENTAGE(ActorLessThen16, UsedCellCount), 
            ActorLessThen64, PERCENTAGE(ActorLessThen64, UsedCellCount), 
            ActorLessThen128, PERCENTAGE(ActorLessThen128, UsedCellCount),
            ActorMoreThen128, PERCENTAGE(ActorMoreThen128, UsedCellCount));
        UE_LOG(LogTemplateActor, Display, TEXT("MaxDataCount: %d, MaxActorHistory: %d, MaxPickupCount: %d, TotalPickupedCount: %d, MaxPlayer: %d"),
            MaxDataCount, MaxActorHistory, MaxPickupCount, TotalPickupCount, MaxPlayer);
        return MemorySize;
    };

    UE_LOG(LogTemplateActor, Display, TEXT("MapWidth: %.2f m, MapHeight: %.2f m, MapCenter[%.2f m, %.2f m], TotalDataCount: %d, TotalPlayerCount: %d, TickInterval: %.2f s"),
        MapSize.X/100.0f, MapSize.Y/100.0f, MapCenter.X/100.0f, MapCenter.Y/100.0f, TotalDataCount, TotalPlayerCount, TickInterval);

    ManagerSize += CaculateMemorySize(HumanCells, TEXT("HumanCells"), HumanCellSize);
    ManagerSize += CaculateMemorySize(ShipCells, TEXT("ShipCells"), ShipCellSize);
    UE_LOG(LogTemplateActor, Display, TEXT("==================================================================================================="));

    TArray<uint32> PlayerCells;
    int PlayerMemorySize = 0;
    for (auto Player : Players)
    {
        APlayerController* Controller = Cast<APlayerController>(Player->GetOwner());
        if (!Controller || !Controller->GetPawn())
        {
            continue;
        }

        PlayerMemorySize += sizeof(UTemplateActorDataComponent) + Player->GetAllocatedSize();
        PlayerCells.Empty(9);
        Player->GetLocatedCells(PlayerCells);

        int PlayerDataCount = 0;
        auto& AllCells = Player->IsShip() ? ShipCells : HumanCells;
        for (auto CellIndex: PlayerCells)
        {
            if (CellIndex != INVALID_TEMPLATE_INDEX)
            {
                auto Cell = FindFromPool(AllCells, CellIndex);
                if (Cell)
                {
                    PlayerDataCount += Cell->GetDataCount();
                }                
            }            
        }
        
        UE_LOG(LogTemplateActor, Display, TEXT("Player: %s, IsShip: %s, DataAroundPlayer: %d, "),
            *Controller->GetPawn()->GetHumanReadableName(), Player->IsShip() ? TEXT("true"):TEXT("false"), PlayerDataCount);
    }

    UE_LOG(LogTemplateActor, Display, TEXT("==================================================================================================="));
    UE_LOG(LogTemplateActor, Display, TEXT("ManagerTotalMemorySize: %.2f kb, TemplateActorComponentTotalMemorySize: %.2f kb"),
        ManagerSize/1024.0f, PlayerMemorySize/1024.0f);
#undef PERCENTAGE
}

void UTemplateActorDataManager::Update(float DeltaTime)
{
    if (IsServer && !InitFinishedInServer)
    {
        return;
    }

    TickTime += DeltaTime;
    bool bNeedUpdate = false;
    while (TickTime >= TickInterval)
    {
        TickTime -= TickInterval;
        bNeedUpdate = true;
    }

    if (bNeedUpdate)
    {
        for (auto& Player : Players)
        {
            auto Component = Player.Get();
            if (Component)
            {
                Component->UpdateCells();
            }            
        }
    }

    if (!IsServer)
    {
        if (Players.Num() > 0)
        {
            auto Component = Players[0].Get();
            if (Component)
            {
                Component->ProcessPendingActors();
            }
        }
    }
}

void UTemplateActorDataManager::SetTickInterval(float Interval)
{
    TickInterval = Interval;
    TickTime = 0.0f;
}

int UTemplateActorDataManager::FindInstanceIdsInRadius(bool IsShip, const FVector& Location, float Radius, TArray<int32>& Out)
{
    check(Radius > 0);

    auto& AllCells = IsShip ? ShipCells : HumanCells;
    float CellSize = IsShip ? ShipCellSize : HumanCellSize;
    int CellXCount = IsShip ? FMath::CeilToInt(MapSize.X / ShipCellSize) : FMath::CeilToInt(MapSize.X / HumanCellSize);
    int XIndex = (int)((Location.X - MapCenter.X + MapSize.X / 2) / CellSize);
    int YIndex = (int)((Location.Y - MapCenter.Y + MapSize.Y / 2) / CellSize);
    uint32 CenterCell = (uint32)(YIndex * CellXCount + XIndex);

    if (CenterCell == INVALID_TEMPLATE_INDEX)
    {
        return 0;
    }

    auto CollectIds = [&](int CellIndex) {
        if (CellIndex >= 0 && CellIndex < AllCells.Num())
        {
            auto* Cell = FindFromPool(AllCells, CellIndex);
            if (Cell)
            {
                for (int ii=0; ii<Cell->TemplateIndices.Num(); ii++)
                {
                    auto& Index = Cell->TemplateIndices[ii];
                    if (Index >= 0)
                    {
                        auto& Data = GetTemplateData(Index);
                        Out.Add(Data.InstanceId);
                    }
                }
            }
        }
    };

    auto CollectLine = [&](int CellXStart, int CellXEnd, int CellY) {
        for (int X=CellXStart; X<=CellXEnd; ++X)
        {
            CollectIds(CellY*CellXCount + X);
        }
    };

    auto CollectColumn = [&](int CellX, int CellYStart, int CellYEnd) {
        for (int Y = CellYStart; Y <= CellYEnd; ++Y)
        {
            CollectIds(Y*CellXCount + CellX);
        }
    };
    
    
    int XStart, XEnd, YStart, YEnd;
    int MaxOffsetCell = FMath::CeilToInt(Radius / CellSize);
    
    // 岁数大了想不出来好算法，哎。。。
    // 从中心cell往外涨，一圈一圈的求out
    // 求中心
    CollectIds(CenterCell);

    // 开始一圈一圈的求
    for (int OffsetCell=1; OffsetCell <= MaxOffsetCell; ++OffsetCell)
    {
        // 四个角
        XStart = XIndex - OffsetCell;
        XEnd = XIndex + OffsetCell;
        YStart = YIndex - OffsetCell;
        YEnd = YIndex + OffsetCell;

        // 收集四条边
        CollectLine(XStart, XEnd, YStart);  // 上
        CollectLine(XStart, XEnd, YEnd);  // 下
        CollectColumn(XStart, YStart+1, YEnd-1); // 左
        CollectColumn(XEnd, YStart+1, YEnd-1); // 右
    }

    return Out.Num();
}

FVector UTemplateActorDataManager::FindLocationByInstanceId(int32 InstanceId)
{
    auto* Data = FindTemplateData(InstanceId);
    return Data ? Data->Location : FVector::ZeroVector;
}

FTemplateActorData* UTemplateActorDataManager::FindTemplateData(int32 InstanceId)
{
    int* TemplateIndex = TemplateIndices.Find(InstanceId);
    if (!TemplateIndex)
    {
        return nullptr;
    }
 
    return &TemplateDatas[*TemplateIndex];
}

FTemplateActorData& UTemplateActorDataManager::GetTemplateData(int TemplateIndex)
{
    return TemplateDatas[TemplateIndex];
}

bool UTemplateActorDataManager::IsValidLocation(float X, float Y)
{
    uint32 ShipCellIndex = FindCellIndex(true, X, Y);
    uint32 HumanCellIndex = FindCellIndex(false, X, Y);
    return ShipCellIndex != INVALID_TEMPLATE_INDEX || HumanCellIndex != INVALID_TEMPLATE_INDEX;
}

////////////////////////////////////////////////////////////////////////////
UTemplateActorDataComponent::UTemplateActorDataComponent(const FObjectInitializer& ObjectInitializer)
    : Super(ObjectInitializer)
    , Manager(nullptr)
    , Controller(nullptr)
    , CurrentCell(INVALID_TEMPLATE_INDEX)
    , IsShipPawn(false)
    , EnableUpdate(false)
    , ProcessActorCountInOneTick(2)
#if ENABLE_DEBUG_TEMPLATE_ACTOR
    , IsClientTested(false)
    , IsSendedAllToClient(false)
#endif
{
    bAutoActivate = false;
    //PrimaryComponentTick.bCanEverTick = true;
    //PrimaryComponentTick.TickInterval = 1.0f;
}

void UTemplateActorDataComponent::BeginPlay()
{
    Controller = Cast<APlayerController>(GetOwner());
    Super::BeginPlay();
}

bool UTemplateActorDataComponent::RegisterToManager(UTemplateActorDataManager* NewManager)
{
    check(NewManager);
    if (NewManager == Manager)
    {
        return false;
    }

    Clear();
    Manager = NewManager;
    Manager->AddPlayer(this);

#if ENABLE_DEBUG_TEMPLATE_ACTOR
    IsClientTested = false;
    IsSendedAllToClient = false;
    ClientTestInstanceIds.Empty();
#endif
    return true;
}

void UTemplateActorDataComponent::InitClientMapInfo()
{
    // 发map信息
    EnableUpdate = true;
    FVector2D MapSize, MapCenter;
    float HumanCellSize, ShipCellSize;
    Manager->GetMapInfo(MapSize, MapCenter, HumanCellSize, ShipCellSize);
    ClientReceivedMapInfo(MapSize, MapCenter, HumanCellSize, ShipCellSize);

    // 发global数据
    TArray<FTemplateActorData> TempDatas;
    Manager->GetGlobalData(TempDatas);
    if (TempDatas.Num() > 0)
    {
        OnMultiGlobalDataAdded(TempDatas);
    }    
}

void UTemplateActorDataComponent::EndPlay(const EEndPlayReason::Type EndPlayReason)
{
    Clear();
    Super::EndPlay(EndPlayReason);
}

//void UTemplateActorDataComponent::TickComponent(float DeltaTime, enum ELevelTick TickType, FActorComponentTickFunction *ThisTickFunction)
//{
//    Super::TickComponent(DeltaTime, TickType, ThisTickFunction);
//
//    Update();
//}

void UTemplateActorDataComponent::LeaveAllCells()
{
    if (!Manager)
    {
        return;
    }
    for (auto CellIndex : Cells)
    {
        if (CellIndex != INVALID_TEMPLATE_INDEX)
        {
            OnLeaveCell(CellIndex);
        }        
    }
    Cells.Empty();
    CurrentCell = INVALID_TEMPLATE_INDEX;
}

void UTemplateActorDataComponent::Clear()
{
    if (!Manager)
    {
        return;
    }

    LeaveAllCells();
    if (Manager)
    {
        Manager->RemovePlayer(this);
    }
    HumanCellHistory.Empty();
    ShipCellHistory.Empty();
    Sended.Empty();
    PendingActors.Clear();
    Manager = nullptr;
}

void UTemplateActorDataComponent::UpdateHistory(bool bShip, uint32 CellIndex, uint32 NewHistory, bool IsPickupedHistory)
{
    auto& CellHistories = bShip ? ShipCellHistory : HumanCellHistory;
    auto* SavedHistory = CellHistories.Find(CellIndex);
    if (!SavedHistory)
    {
        SavedHistory = &CellHistories.Add(CellIndex);        
    }
    uint32& History = IsPickupedHistory ? SavedHistory->PickupedHistory : SavedHistory->DataHistory;
    check(History == INVALID_TEMPLATE_INDEX || History == NewHistory - 1);
    History = NewHistory;
}

void UTemplateActorDataComponent::OnCellDataAdded(bool bShip, uint32 CellIndex, uint32 CellHistory, const FTemplateActorData& Data)
{
    UpdateHistory(bShip, CellIndex, CellHistory, false);

    bool bSendedToClient = true;
    TryAddSendedData(Data.InstanceId, Data.Location);
    ClientReceivedActorCreated(Data.InstanceId, Data.TemplateId, Data.Location, Data.Yaw, Data.CustomType,
        Data.ShipCellIndex, Data.HumanCellIndex);

    DEBUG_LOG(LogTemplateActor, Log, TEXT("%s, OnCellDataAdded, IsShip: %d, ShipCellIndex: %d, HumanCellIndex: %d, InstanceId: %d, SendedToClient: %d"),
        *GetOwner()->GetName(), bShip ? 1:0, Data.ShipCellIndex, Data.HumanCellIndex, Data.InstanceId, bSendedToClient?1:0);
}

void UTemplateActorDataComponent::OnCellDataRemoved(bool bShip, uint32 CellIndex, uint32 CellHistory, const FTemplateActorData& Data)
{
    UpdateHistory(bShip, CellIndex, CellHistory, false);

    bool bSendedToClient = true;
    TryRemoveSendedData(Data.InstanceId, Data.Location);
    ClientReceivedActorDestroyed(bShip, CellIndex, Data.InstanceId);    

    DEBUG_LOG(LogTemplateActor, Log, TEXT("%s, OnCellDataRemoved, IsShip: %d, CellIndex: %d, InstanceId: %d, SendedToClient: %d"),
        *GetOwner()->GetName(), bShip ? 1:0, CellIndex, Data.InstanceId, bSendedToClient ? 1 : 0);
}

void UTemplateActorDataComponent::OnUpdatePickeuped(bool IsShip, uint32 CellIndex, uint32 CellHistory, const FTemplateActorData& Data)
{
    UpdateHistory(IsShip, CellIndex, CellHistory, true);
    ClientReceivedPickupedId(Data.InstanceId);
}

void UTemplateActorDataComponent::UpdateCells()
{
    if (!Manager || !Controller || !EnableUpdate)
    {
        return;
    }

    APawn* Pawn = WatchedTarget.Get();
    if (!Pawn)
    {
        Pawn = Controller->GetPawn();
    }    
    if (!Pawn)
    {
        return;
    }

#if ENABLE_DEBUG_TEMPLATE_ACTOR
    if (GetWorld()->IsServer())
    {
        ServerTest();        
    }
    return;
#endif

    bool bChanged = false;
    bool IsNewShipPawn = Cast<AKMCharacter>(Pawn) == nullptr;
    if (IsNewShipPawn != IsShipPawn)
    {
        LeaveAllCells();
        IsShipPawn = IsNewShipPawn;
        bChanged = true;
        Sended.Empty();
    }

    auto NewLocation = Pawn->GetActorLocation();
    uint32 NewCellIndex = Manager->FindCellIndex(IsShipPawn, NewLocation.X, NewLocation.Y);
    if (NewCellIndex != CurrentCell)
    {
        CurrentCell = NewCellIndex;
        bChanged = true;
    }

    if (!bChanged)
    {
        return;
    }

    TArray<uint32, TInlineAllocator<9> > New9Cells;
    if (NewCellIndex != INVALID_TEMPLATE_INDEX)
    {
        Manager->Find9Cells(IsShipPawn, NewCellIndex, New9Cells);
    }
    
    TArray<int, TInlineAllocator<9> > EmptyIndices;
    int32 FindedIndex = -1;
    for (int ii = 0; ii < Cells.Num(); ii++)
    {
        auto OldCell = Cells[ii];
        if (OldCell == INVALID_TEMPLATE_INDEX)
        {
            EmptyIndices.Add(ii);
            continue;
        }
        if (New9Cells.Find(OldCell, FindedIndex))
        {
            New9Cells[FindedIndex] = INVALID_TEMPLATE_INDEX;
        }
        else
        {
            EmptyIndices.Add(ii);
            Cells[ii] = INVALID_TEMPLATE_INDEX;
            OnLeaveCell(OldCell);
        }
    }

    int TempIndex = 0;
    for (auto& NewCell : New9Cells)
    {
        if (NewCell != INVALID_TEMPLATE_INDEX)
        {
            if (TempIndex >= EmptyIndices.Num())
            {
                Cells.Add(NewCell);
                check(Cells.Num() <= 9);
            }
            else
            {
                Cells[EmptyIndices[TempIndex++]] = NewCell;
            }            
            OnEnterCell(NewCell);
        }
    }
}

int UTemplateActorDataComponent::GetAllocatedSize()
{
    return Cells.GetAllocatedSize() +
        HumanCellHistory.GetAllocatedSize() +
        ShipCellHistory.GetAllocatedSize() +
        Sended.GetAllocatedSize() +
        PendingActors.GetAllocatedSize();
}

void UTemplateActorDataComponent::GetLocatedCells(TArray<uint32>& OutCellIndices)
{
    OutCellIndices.Reserve(9);
    for (auto CellIndex : Cells)
    {
        if (CellIndex != 0)
        {
            OutCellIndices.Add(CellIndex);
        }
    }
}

void UTemplateActorDataComponent::OnLeaveCell(uint32 CellIndex)
{
    auto* Cell = Manager->FindCellData(IsShipPawn, CellIndex, false);
    check(Cell);
    Cell->RemovePlayer(this);

    DEBUG_LOG(LogTemplateActor, Log, TEXT("%s, OnLeaveCell, IsShip: %s, CellIndex: %d"),
        *GetOwner()->GetName(), IsShipPawn ? TEXT("true") : TEXT("false"), CellIndex);

    if (!GetWorld()->IsServer())
    {
        // 通知lua
        TArray<int32> InstanceIds;
        InstanceIds.Reserve(Cell->GetDataCount());
        for (int TempalteIndex : Cell->TemplateIndices)
        {
            if (TempalteIndex < 0)
            {
                continue;
            }
            auto& Data = Manager->GetTemplateData(TempalteIndex);
            if (TryRemoveSendedData(Data.InstanceId, Data.Location))
            {
                PendingActors.Remove(Data.InstanceId);
                InstanceIds.Add(Data.InstanceId);
            }
        }
        if (InstanceIds.Num())
        {
            Manager->OnMultiActorDestroyed.ExecuteIfBound(InstanceIds);
        }
    }
}

void UTemplateActorDataComponent::OnEnterCell(uint32 CellIndex)
{
    auto* Cell = Manager->FindCellData(IsShipPawn, CellIndex, true);
    check(Cell);
    Cell->AddPlayer(this);

    DEBUG_LOG(LogTemplateActor, Log, TEXT("%s, OnEnterCell, IsShip: %s, CellIndex: %d"),
        *GetOwner()->GetName(), IsShipPawn ? TEXT("true") : TEXT("false"), CellIndex);


    if (GetWorld()->IsServer())
    {
        // 发送history给客户端
        auto& SavedCellHistory = IsShipPawn ? ShipCellHistory : HumanCellHistory;
        auto* CellHistory = SavedCellHistory.Find(CellIndex);
        if (!CellHistory)
        {
            CellHistory = &SavedCellHistory.Add(CellIndex);
        }
        SendDataWhenEnterCell(CellIndex, *Cell, CellHistory->DataHistory);
        SendPickupedDataWhenEnterCell(CellIndex, *Cell, CellHistory->PickupedHistory);
    }
    else
    {
        // 进了新cell，通知lua
        for (int TemplateIndex : Cell->TemplateIndices)
        {
            if (TemplateIndex < 0)
            {
                continue;
            }

            auto& Data = Manager->GetTemplateData(TemplateIndex);
            if (TryAddSendedData(Data.InstanceId, Data.Location))
            {
                PendingActors.PushBack(Data.InstanceId);
            }
        }
        //if (SendedDatas.Num())
        //{
        //    Manager->OnMultiActorCreated.ExecuteIfBound(SendedDatas);
        //}
    }
}

void UTemplateActorDataComponent::SendDataWhenEnterCell(uint32 CellIndex, FTemplateCellData& Cell, uint32& SavedHistory)
{    
    uint32 OldHistory = SavedHistory;
    uint32 NewHistory = Cell.History;
    if (OldHistory != INVALID_TEMPLATE_INDEX && OldHistory == NewHistory)
    {
        return;
    }
    SavedHistory = NewHistory;
    
    static const int COUNT_PER_PACKAGE = 16;
    int DataCount = Cell.GetDataCount();
    TArray<FTemplateActorData> NewDatas;    
    TArray<int32> ToBeDeleted;
    TArray<int32> Remain;
    TArray<int32> EmptyIds;
    TArray<uint8> TempZipData;

    auto TryAddAndSendData = [&](const FTemplateActorData& Data) -> bool {
        if (!Data.IsValid())
        {
            return false;
        }

        if (!TryAddSendedData(Data.InstanceId, Data.Location))
        {
            return false;
        }

        NewDatas.Add(Data);
#if !ENABLE_GAME_MESSAGE_OBFUSCATION
        if (NewDatas.Num() == COUNT_PER_PACKAGE)
        {
            ClientReceivedMultiActorCreated(NewDatas, TempZipData);
            NewDatas.Empty(COUNT_PER_PACKAGE);
        }
#endif
        return true;
    };

    bool bRemain = false;
    int Type = 0;

    // 曾经进过，看delta history
    int DeltaHistory = NewHistory - OldHistory;
    int CurrentHistoryCount = Cell.HistoryIds.Num();
    check(DeltaHistory > 0);
    if (OldHistory == INVALID_TEMPLATE_INDEX || DeltaHistory >= DataCount || DeltaHistory >= CurrentHistoryCount)
    {
        // 第一次进，或者history差太多了，直接发所有
        Type = 1;
        bRemain = true;            
        Remain.Reserve(DataCount);
        NewDatas.Reserve(COUNT_PER_PACKAGE);
        for (int TemplateDataIndex : Cell.TemplateIndices)
        {
            if (TemplateDataIndex >= 0)
            {
                auto& TemplateData = Manager->GetTemplateData(TemplateDataIndex);
                TryAddAndSendData(TemplateData);
                Remain.Add(TemplateData.InstanceId);
            }
        }
    }
    else
    {
        Type = 2;
        // 发deleta history
        typedef TInlineAllocator<512> TTempStackInlineAllocator;
        TMap<int32, bool, TSetAllocator<TSparseArrayAllocator<TTempStackInlineAllocator, TTempStackInlineAllocator> > > ChangedIds;
        for (int ii = CurrentHistoryCount - DeltaHistory; ii < CurrentHistoryCount; ++ii)
        {
            // 因为有可能会产生来回扔一个道具的情况，history里可能会包含同一个id的正负好多数据，所以这里记录下来最后的状态，下面循环要用
            int32 InstanceId = Cell.HistoryIds[ii];
            ChangedIds.Add(FMath::Abs(InstanceId), InstanceId > 0);
        }

        ToBeDeleted.Reserve(ChangedIds.Num());
        for (auto Iter = ChangedIds.CreateIterator(); Iter; ++Iter)
        {
            int32 InstanceId = Iter->Key;
            bool bExist = Iter->Value;
            if (bExist)
            {
                auto* TemplateData = Manager->FindTemplateData(InstanceId);
                check(CellIndex == (IsShipPawn ? TemplateData->ShipCellIndex : TemplateData->HumanCellIndex));                    
                TryAddAndSendData(*TemplateData);
            }
            else
            {
                ToBeDeleted.Add(InstanceId);
            }
        }
    }

#if DEBUG_DATA
#define GET_ARRAY_STRING(__string, __array, __value) \
    for (int ii = 0; ii < __array.Num(); ii++) \
    { \
        __string.AppendInt(__value); \
        __string.AppendChar(','); \
    }

    FString NewDataString, RemainString, DeleteString;
    GET_ARRAY_STRING(NewDataString, NewDatas, NewDatas[ii].InstanceId);
    GET_ARRAY_STRING(RemainString, Remain, Remain[ii]);
    GET_ARRAY_STRING(DeleteString, ToBeDeleted, ToBeDeleted[ii]);
#undef GET_ARRAY_STRING

    DEBUG_LOG(LogTemplateActor, Log, TEXT("%s, SendDataWhenEnterCell, IsShip: %s, CellIndex: %d, Type: %d, New: %d {%s}, Remain: %d {%s}, ToBeDeleted: %d {%s}"),
        *GetOwner()->GetName(), IsShipPawn ? TEXT("true") : TEXT("false"), CellIndex,
        Type, 
        NewDatas.Num(), *NewDataString,
        Remain.Num(), *RemainString,
        ToBeDeleted.Num(), *DeleteString);
#endif


    // 把剩下的发了
    if (NewDatas.Num() == 1)
    {
        auto& TempData = NewDatas[0];
        ClientReceivedActorCreated(TempData.InstanceId, TempData.TemplateId, TempData.Location, 
            TempData.Yaw, TempData.CustomType,
            TempData.ShipCellIndex, TempData.HumanCellIndex);
    }
    else if (NewDatas.Num() > 1)
    {
#if ENABLE_GAME_MESSAGE_OBFUSCATION
        TArray<FTemplateActorData> Temp;
        Compress(NewDatas, TempZipData);
        DEBUG_LOG(LogTemplateActor, Log, TEXT("ClientReceivedMultiActorCreated compress before [%d], after [%d]"),
            NewDatas.Num()*FTemplateActorData::GetSerializeSize(), TempZipData.Num());
        ClientReceivedMultiActorCreated(Temp, TempZipData);
#else
        ClientReceivedMultiActorCreated(NewDatas, TempZipData);     
#endif
    }
    
    TempZipData.Empty(TempZipData.Max());
    if (bRemain)
    {
#if ENABLE_GAME_MESSAGE_OBFUSCATION
        Compress(Remain, TempZipData);
        DEBUG_LOG(LogTemplateActor, Log, TEXT("ClientReceivedRemainInstanceIds compress before [%d], after [%d]"),
            Remain.Num() * sizeof(int32), TempZipData.Num());
        ClientReceivedRemainInstanceIds(IsShipPawn, CellIndex, EmptyIds, TempZipData);
#else
        ClientReceivedRemainInstanceIds(IsShipPawn, CellIndex, Remain, TempZipData); 
#endif
    }
    else
    {
        if (ToBeDeleted.Num() == 1)
        {
            ClientReceivedActorDestroyed(IsShipPawn, CellIndex, ToBeDeleted[0]);
        }
        else if (ToBeDeleted.Num() > 1)
        {
#if ENABLE_GAME_MESSAGE_OBFUSCATION
            Compress(ToBeDeleted, TempZipData);
            DEBUG_LOG(LogTemplateActor, Log, TEXT("ClientReceivedMultiActorDestroyed compress before [%d], after [%d]"),
                ToBeDeleted.Num() * sizeof(int32), TempZipData.Num());
            ClientReceivedMultiActorDestroyed(IsShipPawn, CellIndex, EmptyIds, TempZipData);
#else
            ClientReceivedMultiActorDestroyed(IsShipPawn, CellIndex, ToBeDeleted, TempZipData);
#endif
        }
    }
}

void UTemplateActorDataComponent::SendPickupedDataWhenEnterCell(uint32 CellIndex, FTemplateCellData& Cell, uint32& SavedHistory)
{
    if (Cell.PickupHistory == SavedHistory)
    {
        return;
    }
    SavedHistory = Cell.PickupHistory;

    TArray<int32> Ids;
    Ids.Reserve(Cell.GetDataCount());
    for (auto& TemplateIndex : Cell.TemplateIndices)
    {
        if (TemplateIndex >= 0)
        {
            auto& TemplateData = Manager->GetTemplateData(TemplateIndex);
            if (TemplateData.Pickuped)
            {
                Ids.Add(TemplateData.InstanceId);
            }
        }
    }

    if (Ids.Num() == 1)
    {
        ClientReceivedPickupedId(Ids[0]);
    }
    else if(Ids.Num() > 1)
    {
        ClientReceivedMultiPickupedIds(Ids);
    }    
}

bool UTemplateActorDataComponent::TryRemoveData(int32 InstanceId)
{
    if (Manager->RemoveData(InstanceId))
    {
        if (Sended.Remove(InstanceId) > 0)
        {
            PendingActors.Remove(InstanceId);
            return true;
        }
#if ENABLE_DEBUG_TEMPLATE_ACTOR
        else
        {
            check(0);
        }
#endif
    }

    return false;
}

bool UTemplateActorDataComponent::TryAddData(int32 InstanceId, uint32 TemplateId, const FVector_NetQuantize& Location, 
    uint16 Yaw, uint8 CustomType,
    uint32 ShipCellIndex, uint32 HumanCellIndex)
{
    auto& TemplateData = Manager->AddDataWithCellIndices(InstanceId, TemplateId, Location, 
        Yaw, CustomType,
        ShipCellIndex, HumanCellIndex);

    auto CellIndex = IsShipPawn ? ShipCellIndex : HumanCellIndex;
    if (CellIndex != INVALID_TEMPLATE_INDEX 
#if !ENABLE_DEBUG_TEMPLATE_ACTOR
        && Cells.Find(CellIndex) != INDEX_NONE
#endif
        )
    {
        if (TryAddSendedData(InstanceId, Location))
        {
            PendingActors.PushBack(InstanceId);
            return true;
        }
#if ENABLE_DEBUG_TEMPLATE_ACTOR
        else
        {
            check(0);
        }
#endif
        //Manager->OnActorCreated.ExecuteIfBound(InstanceId, TemplateId, Location, Yaw, CustomType);
    }
    return false;
}

bool UTemplateActorDataComponent::TryAddSendedData(int32 InstanceId, const FVector_NetQuantize& Location)
{
    auto* SendedLocation = Sended.Find(InstanceId);
    if (SendedLocation && SendedLocation->Equals(Location))
    {
        return false;
    }

    if (SendedLocation)
    {
        *SendedLocation = Location;
    }
    else
    {
        Sended.Add(InstanceId, Location);
    }
    return true;
}

bool UTemplateActorDataComponent::TryRemoveSendedData(int32 InstanceId, const FVector_NetQuantize& Location)
{
    auto* SendedLocation = Sended.Find(InstanceId);
    if (SendedLocation && SendedLocation->Equals(Location))
    {
        Sended.Remove(InstanceId);
        return true;
    }

    return false;
}

void UTemplateActorDataComponent::ClientReceivedMapInfo_Implementation(const FVector2D& MapSize, const FVector2D& MapCenter, float InHumanCellSize, float InShipCellSize)
{
    auto GameCommon = UGameCommon::Get(this);
    check(GameCommon);
    auto TempManager = GameCommon->GetTemplateActorDataManager();
    check(TempManager);
    TempManager->Init(MapSize.X, MapSize.Y, MapCenter.X, MapCenter.Y, InHumanCellSize, InShipCellSize);
    RegisterToManager(TempManager);    
    EnableUpdate = true;
}

void UTemplateActorDataComponent::ClientReceivedRemainInstanceIds_Implementation(bool IsShip, uint32 CellIndex, const TArray<int32>& InstanceIds, const TArray<uint8>& ZipData)
{
    check(Manager);
    auto CellInfo = Manager->FindCellData(IsShip, CellIndex, true);
    check(CellInfo);

    TArray<int32> ToBeDeleted;
    ToBeDeleted.Reserve(CellInfo->GetDataCount());

    TArray<int32> TempIds;
    auto ServerIds = &InstanceIds;
#if ENABLE_GAME_MESSAGE_OBFUSCATION
    if (ZipData.Num() > 0)
    {
        check(InstanceIds.Num() == 0);
        Uncompress(ZipData, TempIds);
        ServerIds = &TempIds;
    }
#endif

    for (int ii = 0; ii < CellInfo->TemplateIndices.Num(); ++ii)
    {
        int TemplateIndex = CellInfo->TemplateIndices[ii];
        if (TemplateIndex < 0)
        {
            continue;
        }
        auto& Data = Manager->GetTemplateData(TemplateIndex);
        if (ServerIds->Find(Data.InstanceId) == INDEX_NONE)
        {
            ToBeDeleted.Add(Data.InstanceId);
        }
    }

    DEBUG_LOG(LogTemplateActor, Log, TEXT("ClientReceivedRemainInstanceIds, IsShip: %s, CellIndex: %d, Start"),
        IsShip ? TEXT("true") : TEXT("false"), CellIndex);

    if (ToBeDeleted.Num() == 1)
    {
        ClientReceivedActorDestroyed_Implementation(IsShip, CellIndex, ToBeDeleted[0]);
    }
    else if (ToBeDeleted.Num() > 1)
    {
        TArray<uint8> Temp;
        ClientReceivedMultiActorDestroyed_Implementation(IsShip, CellIndex, ToBeDeleted, Temp);
    }

    DEBUG_LOG(LogTemplateActor, Log, TEXT("ClientReceivedRemainInstanceIds, IsShip: %s, CellIndex: %d, End"),
        IsShip ? TEXT("true") : TEXT("false"), CellIndex);
}

void UTemplateActorDataComponent::ClientReceivedActorDestroyed_Implementation(bool IsShip, uint32 CellIndex, int32 InstanceId)
{
    check(Manager);
    auto* TemplateData = Manager->FindTemplateData(InstanceId);
    if (!TemplateData || CellIndex != ((IsShip ? TemplateData->ShipCellIndex : TemplateData->HumanCellIndex)))
    {
#if ENABLE_DEBUG_TEMPLATE_ACTOR
        check(0);
#endif // ENABLE_DEBUG_TEMPLATE_ACTOR

        return;
    }

    bool bSended = false;
    if (TryRemoveData(InstanceId))
    {
        bSended = true;
        Manager->OnActorDestroyed.ExecuteIfBound(InstanceId);     
    }
#if ENABLE_DEBUG_TEMPLATE_ACTOR
    else
    {
        check(0);
    }
#endif
    DEBUG_LOG(LogTemplateActor, Log, TEXT("ClientReceivedActorDestroyed, IsShip: %s, CellIndex: %d, InstanceId: %d, Sended: %d"),
        IsShip ? TEXT("true") : TEXT("false"), CellIndex, InstanceId, bSended ? 1 : 0);
}

void UTemplateActorDataComponent::ClientReceivedMultiActorDestroyed_Implementation(bool IsShip, uint32 CellIndex, const TArray<int32>& InstanceIds, const TArray<uint8>& ZipData)
{
    check(Manager);
    TArray<int32> ToBeDeleted;
    ToBeDeleted.Reserve(InstanceIds.Num());

    TArray<int32> TempIds;
    auto ServerIds = &InstanceIds;
#if ENABLE_GAME_MESSAGE_OBFUSCATION
    if (ZipData.Num() > 0)
    {
        check(InstanceIds.Num() == 0);
        Uncompress(ZipData, TempIds);
        ServerIds = &TempIds;
    }
#endif

    for (auto& InstanceId : *ServerIds)
    {
        auto* TemplateData = Manager->FindTemplateData(InstanceId);
        if (!TemplateData || CellIndex != ((IsShip ? TemplateData->ShipCellIndex : TemplateData->HumanCellIndex)))
        {
            continue;
        }

        bool bSended = false;
        if (TryRemoveData(InstanceId))
        {
            bSended = true;
            ToBeDeleted.Add(InstanceId);
        }

        DEBUG_LOG(LogTemplateActor, Log, TEXT("ClientReceivedMultiActorDestroyed, IsShip: %s, CellIndex: %d, InstanceId: %d, Sended: %d"),
            IsShip ? TEXT("true") : TEXT("false"), CellIndex, InstanceId, bSended?1:0);
    }
    if (ToBeDeleted.Num())
    {
        Manager->OnMultiActorDestroyed.ExecuteIfBound(ToBeDeleted);
    }    
}

void UTemplateActorDataComponent::ClientReceivedActorCreated_Implementation(int32 InstanceId, uint32 TemplateId, const FVector_NetQuantize& Location, 
    uint16 Yaw, uint8 CustomType,
    uint32 ShipCellIndex, uint32 HumanCellIndex)
{
    check(Manager);

    // 删除不调用delegate，lua那边会进行处理
    TryRemoveData(InstanceId);
    bool bSended = TryAddData(InstanceId, TemplateId, Location, 
        Yaw, CustomType,
        ShipCellIndex, HumanCellIndex);

    auto* TemplateData = Manager->FindTemplateData(InstanceId);
    check(TemplateData);
    DEBUG_LOG(LogTemplateActor, Log, TEXT("ClientReceivedActorCreated, InstanceId: %d, TemplateId: %d, Sended: %d, IsShip: %d, Cell: %d"),
        InstanceId, 
        TemplateId, 
        bSended?1:0, 
        IsShipPawn?1:0,
        IsShipPawn ? TemplateData->ShipCellIndex : TemplateData->HumanCellIndex);
}

void UTemplateActorDataComponent::ClientReceivedMultiActorCreated_Implementation(const TArray<FTemplateActorData>& NewActorDatas, const TArray<uint8>& ZipData)
{
    check(Manager);
    
    TArray<FTemplateActorData> TempDatas;
    auto NewDatas = &NewActorDatas;
#if ENABLE_GAME_MESSAGE_OBFUSCATION
    if (ZipData.Num() > 0)
    {
        check(NewActorDatas.Num() == 0);
        Uncompress(ZipData, TempDatas);
        NewDatas = &TempDatas;
    }
#endif

    for (auto& Data : *NewDatas)
    {
#if !ENABLE_DEBUG_TEMPLATE_ACTOR
        // 删除不调用delegate，lua那边会进行处理
        TryRemoveData(Data.InstanceId);
#endif
        bool bSended = TryAddData(Data.InstanceId, Data.TemplateId, Data.Location,
            Data.Yaw, Data.CustomType,
            Data.ShipCellIndex, Data.HumanCellIndex);

        auto* TemplateData = Manager->FindTemplateData(Data.InstanceId);
        check(TemplateData);
        DEBUG_LOG(LogTemplateActor, Log, TEXT("ClientReceivedMultiActorCreated, InstanceId: %d, TemplateId: %d, Sended: %d, IsShip: %d, Cell: %d"),
            Data.InstanceId,
            Data.TemplateId,
            bSended ? 1 : 0,
            IsShipPawn ? 1 : 0,
            IsShipPawn ? TemplateData->ShipCellIndex : TemplateData->HumanCellIndex);
    }
}

void UTemplateActorDataComponent::ClientReceivedPickupedId_Implementation(int32 InstanceId)
{
    check(Manager);
    Manager->SetPickuped(InstanceId);    
    Manager->OnPickupUpdate.ExecuteIfBound(InstanceId);    
}

void UTemplateActorDataComponent::ClientReceivedMultiPickupedIds_Implementation(const TArray<int32>& InstanceIds)
{
    check(Manager);
    for (auto& Id: InstanceIds)
    {
        Manager->SetPickuped(Id);
    }
    Manager->OnMultiPickupUpdate.ExecuteIfBound(InstanceIds);
}

void UTemplateActorDataComponent::ProcessPendingActors()
{
    if (!Manager || PendingActors.IsEmpty())
    {
        return;
    }

    static TArray<FTemplateActorData> Temp;
    Temp.Empty(ProcessActorCountInOneTick);
    for (uint32 ii=0; ii < ProcessActorCountInOneTick && !PendingActors.IsEmpty(); ++ii)
    {
        int32 InstanceId = PendingActors.PopFront();
        auto* Data = Manager->FindTemplateData(InstanceId);
        if (Data)
        {
            Temp.Add(*Data);
        }
    }

#if !ENABLE_DEBUG_TEMPLATE_ACTOR
    if (Temp.Num() == 1)
    {
        auto& Data = Temp[0];
        Manager->OnActorCreated.ExecuteIfBound(Data.InstanceId, Data.TemplateId, Data.Location, Data.Yaw, Data.CustomType);
    }
    else if (Temp.Num() > 0)
    {
        Manager->OnMultiActorCreated.ExecuteIfBound(Temp);
    }
#endif
}

void UTemplateActorDataComponent::OnMultiGlobalDataAdded(const TArray<FTemplateActorData>& Datas)
{
    ClientReceivedMultiGlobalActorCreated(Datas);
}

void UTemplateActorDataComponent::OnGlobalDataAdded(const FTemplateActorData& Data)
{
    ClientReceivedGlobalActorCreated(Data.InstanceId, Data.TemplateId, Data.Location, Data.Yaw, Data.CustomType);
}

void UTemplateActorDataComponent::OnGlobalDataRemoved(int32 InstanceId)
{
    ClientReceivedGlobalActorDestoryed(InstanceId);
}

void UTemplateActorDataComponent::ClientReceivedGlobalActorCreated_Implementation(int32 InstanceId, uint32 TemplateId, const FVector_NetQuantize& Location,
    uint16 Yaw, uint8 CustomType)
{
    check(Manager);

    Manager->AddGlobalData(InstanceId, TemplateId,
        Location.X, Location.Y, Location.Z,
        Yaw, CustomType);

    if (TryAddSendedData(InstanceId, Location))
    {
        PendingActors.PushBack(InstanceId);
    }
}

void UTemplateActorDataComponent::ClientReceivedMultiGlobalActorCreated_Implementation(const TArray<FTemplateActorData>& NewActorDatas)
{
    check(Manager);

    for (auto const& Data : NewActorDatas)
    {
        auto const& Location = Data.Location;
        Manager->AddGlobalData(Data.InstanceId, Data.TemplateId, 
            Location.X, Location.Y, Location.Z,
            Data.Yaw, Data.CustomType);

        if (TryAddSendedData(Data.InstanceId, Location))
        {
            PendingActors.PushBack(Data.InstanceId);
        }
    }
}

void UTemplateActorDataComponent::ClientReceivedGlobalActorDestoryed_Implementation(int32 InstanceId)
{
    if (TryRemoveData(InstanceId))
    {
        Manager->OnActorDestroyed.ExecuteIfBound(InstanceId);
    }
}

#if ENABLE_GAME_MESSAGE_OBFUSCATION
void UTemplateActorDataComponent::Compress(const TArray<uint8>& InData, TArray<uint8>& OutCompressedData)
{
    check(InData.Num() < 65535);
    unsigned long ComporessSize = compressBound(InData.Num());
    OutCompressedData.SetNumUninitialized(ComporessSize + 2, false);
    *(uint16*)&OutCompressedData[0] = (uint16)InData.Num();
    int32 Error = compress(&OutCompressedData[2], &ComporessSize, InData.GetData(), InData.Num());
    checkf(Error == Z_OK, TEXT("UTemplateActorDataComponent zlib failed to compress, which is very unexpected (err = %d)"), Error);
    OutCompressedData.SetNumUninitialized(ComporessSize + 2, false);    
}

void UTemplateActorDataComponent::Compress(const TArray<FTemplateActorData>& ActorDatas, TArray<uint8>& OutCompressedData)
{
    TempCompressBuffer.Empty(TempCompressBuffer.Max());
    FMemoryWriter Writer(TempCompressBuffer, true);
    Writer << (TArray<FTemplateActorData>&)ActorDatas;
    Compress(TempCompressBuffer, OutCompressedData);
}

void UTemplateActorDataComponent::Compress(const TArray<int32>& InstanceIds, TArray<uint8>& OutCompressedData)
{
    TempCompressBuffer.Empty(TempCompressBuffer.Max());
    FMemoryWriter Writer(TempCompressBuffer, true);
    Writer << (TArray<int32>&)InstanceIds;
    Compress(TempCompressBuffer, OutCompressedData);
}

void UTemplateActorDataComponent::Uncompress(const TArray<uint8>& InCompressedData, TArray<uint8>& OutData)
{
    check(InCompressedData.Num() >= 2);
    unsigned long OutDataSize = *(uint16*)&InCompressedData[0];
    OutData.SetNumUninitialized(OutDataSize, false);
    uncompress(OutData.GetData(), &OutDataSize, &InCompressedData[2], InCompressedData.Num()-2);
}

void UTemplateActorDataComponent::Uncompress(const TArray<uint8>& InCompressedData, TArray<FTemplateActorData>& OutActorDatas)
{
    TempCompressBuffer.Empty(TempCompressBuffer.Max());
    Uncompress(InCompressedData, TempCompressBuffer);
    FMemoryReader Reader(TempCompressBuffer, true);
    Reader << OutActorDatas;
}

void UTemplateActorDataComponent::Uncompress(const TArray<uint8>& InCompressedData, TArray<int32>& OutInstanceIds)
{
    TempCompressBuffer.Empty(TempCompressBuffer.Max());
    Uncompress(InCompressedData, TempCompressBuffer);
    FMemoryReader Reader(TempCompressBuffer, true);
    Reader << OutInstanceIds;
}
#endif

#if ENABLE_DEBUG_TEMPLATE_ACTOR
void UTemplateActorDataComponent::ClientTest_Implementation(const TArray<FTemplateActorData>& NewActorDatas, const TArray<uint32>& ShipCells, const TArray<uint32>& HumanCells)
{
    UE_LOG(LogTemplateActor, Error, TEXT("ClientTest %d"), NewActorDatas.Num());
    check(NewActorDatas.Num() == ShipCells.Num());
    check(NewActorDatas.Num() == HumanCells.Num());

    for (int ii=0; ii<NewActorDatas.Num(); ++ii)
    {
        auto& TestData = NewActorDatas[ii];
        auto& Location = TestData.Location;
        uint32 TestShipCell = ShipCells[ii];
        uint32 TestHumanCell = HumanCells[ii];

        uint32 ClientShipCell = INVALID_TEMPLATE_INDEX;
        uint32 ClientHumanCell = INVALID_TEMPLATE_INDEX;
        auto RegionType = UGameCommon::Get(this)->GetGridTypeManager()->GetRegionType(Location.X, Location.Y);
        bool IsOcean = RegionType == EPiratesGridRegionType::Ocean || RegionType == EPiratesGridRegionType::Port;
        if (IsOcean)
        {
            ClientShipCell = Manager->FindCellIndex(true, Location.X, Location.Y);
        }
        ClientHumanCell = Manager->FindCellIndex(false, Location.X, Location.Y);
        check(ClientShipCell == TestShipCell);
        check(ClientHumanCell == TestHumanCell);
    }
}

void UTemplateActorDataComponent::ServerTest()
{
    if (IsClientTested)
    {
        return;
    }
     
    int MaxSendedCount = 40;
    if (!IsSendedAllToClient)
    {        
        TArray<FTemplateActorData> TempSended;
        for (auto Iter = Manager->TemplateIndices.CreateIterator(); Iter; ++Iter)
        {
            int32 InstanceId = Iter->Key;
            int TemplateIndex = Iter->Value;
            auto* Finded = ClientTestInstanceIds.Find(InstanceId);
            if (Finded)
            {
                continue;
            }

            auto& Data = Manager->GetTemplateData(TemplateIndex);
            ClientTestInstanceIds.Add(InstanceId, Data.Location);
            TempSended.Add(Data);
            if (TempSended.Num() >= MaxSendedCount)
            {
                ClientReceivedMultiActorCreated(TempSended);
                return;
            }
        }

        if (TempSended.Num())
        {
            ClientReceivedMultiActorCreated(TempSended);
        }
        IsSendedAllToClient = true;
        ClientTestInstanceIds.Empty();
        return;
    }

    int TempSended = 0;
    for (auto Iter = Manager->TemplateIndices.CreateIterator(); Iter; ++Iter)
    {
        int32 InstanceId = Iter->Key;
        int TemplateIndex = Iter->Value;
        auto* Finded = ClientTestInstanceIds.Find(InstanceId);
        if (Finded)
        {
            continue;
        }

        auto& Data = Manager->GetTemplateData(TemplateIndex);
        ClientTestInstanceIds.Add(InstanceId, Data.Location);

        if (Data.HumanCellIndex != INVALID_TEMPLATE_INDEX && Data.IndexInHumanCell != INVALID_TEMPLATE_INDEX)
        {
            ClientReceivedActorDestroyed(false, Data.HumanCellIndex, InstanceId);
        }
        else
        {
            ClientReceivedActorDestroyed(true, Data.ShipCellIndex, InstanceId);
        }

        if (++TempSended >= MaxSendedCount)
        {
            return;
        }
    }

    IsClientTested = true;
}
#endif