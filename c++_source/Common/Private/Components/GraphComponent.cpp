// Fill out your copyright notice in the Description page of Project Settings.

#include "Components/GraphComponent.h"
#include "Common.h"

DEFINE_LOG_CATEGORY_STATIC(UGraphComponentLog, Log, All)
// Sets default values for this component's properties
UGraphComponent::UGraphComponent()
{
	// Set this component to be initialized when the game starts, and to be ticked every frame.  You can turn these features
	// off to improve performance if you don't need them.
	PrimaryComponentTick.bCanEverTick = true;

	// ...
    DebugMode = false;
    LineThickness = 10;
    EdgeLineThickness = 2;
    GridSize = 1;
}


// Called when the game starts
void UGraphComponent::BeginPlay()
{
	Super::BeginPlay();

    CollectNodeNeighbors();
}


// Called every frame
void UGraphComponent::TickComponent(float DeltaTime, ELevelTick TickType, FActorComponentTickFunction* ThisTickFunction)
{
    Super::TickComponent(DeltaTime, TickType, ThisTickFunction);

    if (DebugMode)
    {
        for (const FGraphEdge& Edge : Edges)
        {
            DrawDebugLine(this->GetWorld(), Nodes[Edge.NodeIndexA].Location, Nodes[Edge.NodeIndexB].Location,
                FColor(255, 255, 0), false, 0.01f, 0, 10.0f);
        }
    }


/*
	// Test code to do path finding.
    TArray<int32> Path;
    FindPathSimpleRandom(4, 12, Path);

    UE_LOG(LogScript, Warning, TEXT("Path Start"));
    for (int32 Node : Path)
    {        
        UE_LOG(LogScript, Warning, TEXT("%d"), Node);        
    }
    UE_LOG(LogScript, Warning, TEXT("Path End"));
*/


}

bool UGraphComponent::InitGrid(int32 inGridSize, int32 inGridCount)
{
    GridSize = inGridSize;
    GridCount = inGridCount;
    for (int i=0; i < Nodes.Num(); i++)
    {
        int32 GridX = Nodes[i].Location.X / GridSize;
        int32 GridY = Nodes[i].Location.Y / GridSize;
        //UE_LOG(UGraphComponentLog, Log, TEXT("InitGrid i = %d GridX = %d GridY = %d "), i, GridX, GridY);
        Nodes[i].GridPos = GridX << 16 | GridY;
        //Nodes[i].Location.Z = 0;
    }
    return true;
}

bool UGraphComponent::FindPathSimpleRandom(int32 StartNode, int32 EndNode, TArray<int32> &OutPath)
{
    CheckedNodes.Empty();
    OutPath.Empty();

    return SearchSubGraphForPathRandom(StartNode, EndNode, OutPath);
}

bool UGraphComponent::FindOffsetPathSimpleRandom(int32 StartNode, int32 EndNode, TArray<FVector> &OutPath)
{
	TArray<int32> Path;
	if (FindPathSimpleRandom(StartNode, EndNode, Path))
	{
		if (Path.Num() < 2)
		{
			for (int32 NodeIndex : Path)
			{
				OutPath.Add(Nodes[NodeIndex].Location);
			}
			//UE_LOG(UGraphComponentLog, Log, TEXT("1111111111111111111111"));
			return true;
		}

		for (int i = 0; i < Path.Num(); i++)
		{
			
			FVector Dir, Previous, Next;
			//UE_LOG(UGraphComponentLog, Log, TEXT("Node Index %d."), Path[i]);
			// Compute Dir vector;
			if (i == 0)
			{
				Dir = Nodes[Path[1]].Location - Nodes[Path[0]].Location;
				Dir.Normalize();
			}
			else if (i == Path.Num() - 1)
			{
				Dir = Nodes[Path.Num() - 1].Location - Nodes[Path.Num() - 2].Location;
				Dir.Normalize();
			}
			else
			{
				Previous = (Nodes[Path[i]].Location - Nodes[Path[i - 1]].Location);
				Next = (Nodes[Path[i + 1]].Location - Nodes[Path[i]].Location);
				Previous.Normalize();
				Next.Normalize();
				Dir = Previous + Next;
				Dir.Normalize();
			}
			float fDir = FMath::RandRange(0, 1) == 0 ? 1 : -1;

			float fRandomRage = FMath::RandRange(0.0f, Nodes[Path[i]].fRandomRage) * fDir;
			//UE_LOG(UGraphComponentLog, Log, TEXT("fRandomRage %f."), fRandomRage);
			OutPath.Add(FVector::CrossProduct(Dir, FVector::UpVector) * fRandomRage + Nodes[Path[i]].Location);
			//OutPath.Add(Nodes[i].Location);
		}

		return true;
	}
	else
	{
        UE_LOG(UGraphComponentLog, Warning, TEXT("Can't find Path StartNode = %d EndNode = %d"), StartNode, EndNode);
		return false;
	}
}

bool UGraphComponent::FindPathSimpleRandomVec(int32 StartNode, int32 EndNode, TArray<FVector> &OutPath)
{
    TArray<int32> Path;
    if (FindPathSimpleRandom(StartNode, EndNode, Path))
    {
        for (int32 NodeIndex : Path)
        {
            OutPath.Add(Nodes[NodeIndex].Location);
        }

        return true;
    }
    else
    {
        return false;
    }

}

void UGraphComponent::ApplyOffsetToPath(float Offset, const TArray<FVector> &InPath, TArray<FVector> &OutPath)
{
    if (InPath.Num() < 2)
    {
        for (const FVector Vec : InPath)
        {
            OutPath.Add(Vec);
        }
        
        return;
    }

    for (int i = 0; i < InPath.Num(); i++)
    {
        FVector Dir, Previous, Next;

        // Compute Dir vector;
        if (i == 0)
        {
            Dir = InPath[1] - InPath[0];
            Dir.Normalize();
        }
        else if (i == InPath.Num() - 1)
        {
            Dir = InPath[InPath.Num() - 1] - InPath[InPath.Num() - 2];
            Dir.Normalize();
        }
        else
        {
            Previous = (InPath[i] - InPath[i - 1]);
            Next = (InPath[i + 1] - InPath[i]);
            Previous.Normalize();
            Next.Normalize();
            Dir = Previous + Next;
            Dir.Normalize();
        }
		FVector dest = FVector::CrossProduct(Dir, FVector::UpVector) * Offset + InPath[i];
		dest.Z = 0;
        OutPath.Add(dest);
    }

    return;
}

bool UGraphComponent::SearchSubGraphForPathRandom(int32 StartNode, int32 EndNode, TArray<int32> &OutPath)
{
    if (StartNode < 0 || StartNode >= Nodes.Num() || Nodes[StartNode].Dead || CheckedNodes.Contains(StartNode))
    {
        return false;
    }

    CheckedNodes.Add(StartNode);
    OutPath.Add(StartNode);

    if (StartNode == EndNode)
    {            
        return true;
    }

    int32 NeighborCount = Nodes[StartNode].Neighbors.Num();
    int32 NeighborToCheck = ((int32)FPlatformTime::Seconds()) % NeighborCount;
    for (int32 i = 0; i < NeighborCount; i++)
    {
        if (SearchSubGraphForPathRandom(Nodes[StartNode].Neighbors[NeighborToCheck], EndNode, OutPath))
        {
            return true;
        }

        NeighborToCheck = (NeighborToCheck + 1) % NeighborCount;
    }
    
    // Failure try should be removed.
    OutPath.RemoveAt(OutPath.Num() - 1);

    return false;
}

void UGraphComponent::CollectNodeNeighbors()
{
    for (const FGraphEdge& Edge : Edges)
    {
        Nodes[Edge.NodeIndexA].Neighbors.Add(Edge.NodeIndexB);
        Nodes[Edge.NodeIndexB].Neighbors.Add(Edge.NodeIndexA);
    }
}

FVector UGraphComponent::GetNearestNodeLocation(FVector Location)
{
    int32 NodeIndex = GetNearestNodeIndex(Location);
    return NodeIndex >= 0 ? Nodes[NodeIndex].Location : FVector::ZeroVector;
}

int32 UGraphComponent::GetNearestNodeIndex(FVector Location)
{
    TArray<int32> NearNodes = GetNearestNodeIndexByGrid(Location, true);
    if (NearNodes.Num() < 1)
    {
        return -1;
    }

    float CurNearestDistSqr = FVector::DistSquared(Location, Nodes[NearNodes[0]].Location);
    int32 CurNearestNodeIndex = 0;

    for (int i = 1; i < NearNodes.Num(); i++)
    {
        if(Nodes[NearNodes[i]].Dead)
            continue;;
        float CurDistSqr = FVector::DistSquared(Location, Nodes[NearNodes[i]].Location);
        if (CurDistSqr < CurNearestDistSqr)
        {
            CurNearestNodeIndex = NearNodes[i];
            CurNearestDistSqr = CurDistSqr;
        }
    }
    //UE_LOG(UGraphComponentLog, Log, TEXT("CurNearestNodeIndex %d"), CurNearestNodeIndex);
    return CurNearestNodeIndex;
}

TArray<int32> UGraphComponent::GetNearestNodeIndexByGrid(FVector Location, bool bSelf)
{
    TArray<int32> NearestNodes;
    if (Nodes.Num() < 1)
    {
        return NearestNodes;
    }

    TMap<int32, bool> GridMap;

    int32 GridX = Location.X / GridSize;
    int32 GridY = Location.Y / GridSize;
    int32 HalfGridCount = (GridCount - 1) / 2;

    //UE_LOG(UGraphComponentLog, Log, TEXT("Start GridX = %d GridY = %d "), GridX, GridY);
    for (int i = 0; i < GridCount; i++)
    {
        for (int j = 0; j < GridCount; j++)
        {
            int32 x = GridX + i - HalfGridCount;
            int32 y = GridY + j - HalfGridCount;
            //UE_LOG(UGraphComponentLog, Log, TEXT("GridX = %d GridY = %d  pos %d"), x, y, x << 16 | y);
            GridMap.Add(x << 16 | y, true);
        }
    }

    for (int ii = 0; ii < Nodes.Num(); ii++)
    {
        if (Nodes[ii].Dead)
            continue;;
        
        //UE_LOG(UGraphComponentLog, Log, TEXT("Start ii = %d GridPos = %d "), ii, Nodes[ii].GridPos);
        if (GridMap.Find(Nodes[ii].GridPos))
        {
            //UE_LOG(UGraphComponentLog, Log, TEXT("NearestNodes = %d "), ii);
            NearestNodes.Add(ii);
        }
    }

    return NearestNodes;

}

bool UGraphComponent::InSameGrid(FVector Location, FVector OtherLocation)
{
    int32 GridX = Location.X / GridSize;
    int32 GridY = Location.Y / GridSize;

    int32 OtherGridX = OtherLocation.X / GridSize;
    int32 OtherGridY = OtherLocation.Y / GridSize;

    if ((FMath::Abs(GridX - OtherGridX) < GridCount) && (FMath::Abs(GridY - OtherGridY) < GridCount))
        return true;
    return false;
}

TArray<int32> UGraphComponent::GetNearestNodeIndexByDistance(FVector Location,int32 fDistance, int32 fNearDistance)
{
	TArray<int32> NearestNodes;
	if (Nodes.Num() < 1)
	{
		return NearestNodes;
	}

    TArray<int32> NearNodes = GetNearestNodeIndexByGrid(Location);

	for (int i = 0; i < NearNodes.Num(); i++)
	{
        if (Nodes[NearNodes[i]].Dead)
            continue;;
		float CurDistSqr = FVector::Dist(Location, Nodes[NearNodes[i]].Location);
		if (CurDistSqr < fDistance && CurDistSqr > fNearDistance)
		{
			NearestNodes.Add(NearNodes[i]);
		}
	}

	return NearestNodes;
}

int32 UGraphComponent::GetRandomNodeIndex()
{
    int32 Node = FMath::RandRange(0, Nodes.Num() - 1);
    for (int32 i = 0; i < Nodes.Num(); i++)
    {
        if (!Nodes[(Node + i) % Nodes.Num()].Dead)
        {
            return (Node + i) % Nodes.Num();
        }
    }

    return 0;
}

int32 UGraphComponent::GetNearestNodeIndexFromList(FVector Location, TArray<int> NodeIndexs, int32 &ListIndex)
{
    if (NodeIndexs.Num() < 1)
        return -1;
    float CurNearestDistSqr = 0;
    int CurNearestNodeIndex = -1;
    for (int i = 0; i < NodeIndexs.Num(); i++)
    {
        int32 nIndex = NodeIndexs[i];
        if(nIndex >= Nodes.Num() )
            continue;

        float CurDistSqr = FVector::DistSquared(Location, Nodes[nIndex].Location);
        if (CurDistSqr < CurNearestDistSqr || CurNearestDistSqr == 0)
        {
            CurNearestNodeIndex = nIndex;
            CurNearestDistSqr = CurDistSqr;
            ListIndex = i;
        }

    }
    return CurNearestNodeIndex;
}


bool UGraphComponent::FindPathFromList(int32 StartNode, TArray<int> NodeIndexs, TArray<FVector> &OutPath)
{
    if (NodeIndexs.Num() < 1)
        return false;

    for (int i = StartNode; i < NodeIndexs.Num(); i++)
    {
        int32 nIndex = NodeIndexs[i];
        if (nIndex >= Nodes.Num())
            continue;
        OutPath.Add(Nodes[nIndex].Location);
    }

    for (int i = 0; i < StartNode; i++)
    {
        int32 nIndex = NodeIndexs[i];
        if (nIndex >= Nodes.Num())
            continue;
        OutPath.Add(Nodes[nIndex].Location);
    }
    return true;
}