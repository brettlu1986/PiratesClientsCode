#include "AI/Smoke/AISmokeManager.h"
#include "Game/Battle/PiratesGridTypeManager.h"
#include "Shell/CommonShell.h"
#include "Engine/World.h"


struct SmokeLifeTime_Predicate
{
    bool operator()(const FAISmoke& Smoke) const
    {
        return Smoke.RemainTime <= 0;
    }
};

UAISmokeManager::UAISmokeManager(const FObjectInitializer& ObjectInitializer)
    : Super(ObjectInitializer)
{

}

void UAISmokeManager::AddSmoke(const FVector& Location, float Radius, float ExistTime)
{
    FAISmoke NewSmoke;
    NewSmoke.Location = Location;
    NewSmoke.Radius = Radius;
    NewSmoke.RemainTime = ExistTime;
    Smokes.Emplace(NewSmoke);
}

void UAISmokeManager::Tick(float Delta)
{
    static const SmokeLifeTime_Predicate Predicate;
    for (FAISmoke& Smoke : Smokes)
    {
        Smoke.RemainTime -= Delta;
    }
    Smokes.RemoveAllSwap<SmokeLifeTime_Predicate>(Predicate);
}

void UAISmokeManager::QuerySmoke(const FVector& Location, float Radius, TArray<FAISmoke>& OutSmokes) const
{
    FSphere Querier(Location, Radius);
    for (const FAISmoke& Smoke : Smokes)
    {
        if (Smoke.RemainTime >0 && Querier.Intersects(FSphere(Smoke.Location, Smoke.Radius)))
        {
            OutSmokes.Emplace(Smoke);
        }
    }
}