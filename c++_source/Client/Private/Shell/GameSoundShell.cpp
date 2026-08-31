// Fill out your copyright notice in the Description page of Project Settings.

#include "GameSoundShell.h"
#include "Client.h"
#include "ClientShell.h"
#include "GameClient.h"
#include "Components/AudioComponent.h"
#include "Kismet/GameplayStatics.h"

#include "AudioDevice.h"
#include "AudioDeviceManager.h"
#include "ActiveSound.h"
#include "TimerManager.h"


DEFINE_LOG_CATEGORY_STATIC(UGameSoundShellLog, Log, All)

UGameSoundShell::UGameSoundShell(const FObjectInitializer& ObjectInitializer)
    : Super(ObjectInitializer)
    , ClientShell(nullptr)
{
}

void UGameSoundShell::Init(UClientShell* Shell)
{
    ClientShell = Shell;
}

static FAudioDevice* GetAudioDevice(UWorld* World, uint32 AudioDeviceHandle)
{
    FAudioDevice* AudioDevice = nullptr;

    if (GEngine)
    {
        if (AudioDeviceHandle != INDEX_NONE)
        {
            FAudioDeviceManager* AudioDeviceManager = GEngine->GetAudioDeviceManager();
            AudioDevice = (AudioDeviceManager ? AudioDeviceManager->GetAudioDeviceRaw(AudioDeviceHandle) : nullptr);
        }
        else if (World)
        {
            AudioDevice = World->GetAudioDeviceRaw();
        }
        else
        {
            AudioDevice = GEngine->GetMainAudioDeviceRaw();
        }
    }
    return AudioDevice;
}

bool UGameSoundShell::PlaySound2D(UObject* Sound, bool bOneShot, float FadeInDuration, uint32& OutAudioDeviceHandle, uint64& OutAudioComponentID, float& OutDuration, bool Ref /* = false */)
{
    OutAudioDeviceHandle = INDEX_NONE;
    OutAudioComponentID = INDEX_NONE;
	OutDuration = 0.0f;
    USoundBase* Object = Cast<USoundBase>(Sound);
    if (!Object)
    {
        UE_LOG(UGameSoundShellLog, Error, TEXT("PlaySound2D failed, invalid sound resource"));
        return false;
    }

	OutDuration = Object->Duration;
    uint64 AudioComponentID = 0;
    if (bOneShot)
    {
        UGameplayStatics::PlaySound2D(ClientShell->GetWorld(), Object);
    }
    else
    {
        UAudioComponent* AudioComponent = UGameplayStatics::SpawnSound2D(ClientShell->GetWorld(), Object, 1.0f, 1.0f, 0.0f, nullptr, true);
        if (!AudioComponent)
        {
            UE_LOG(UGameSoundShellLog, Error, TEXT("PlaySound2D failed, SpawnSound2D failed"));
            return false;
        }
        OutAudioComponentID = AudioComponent->GetAudioComponentID();
        OutAudioDeviceHandle = AudioComponent->AudioDeviceID;
        AudioComponent->bAutoDestroy = false;

        //AudioComponent->OnAudioFinishedNative.AddUObject(this, &UGameSoundShell::OnAudioFinished);
        if (FadeInDuration > 0.0f)
        {
            AudioComponent->FadeIn(FadeInDuration);
        }
        else
        {
            AudioComponent->Play();
        }
        if (Ref)
        {
            UGameClient::Get(this)->AddReferencedObject(AudioComponent);
        }
    }
    return true;
}

void UGameSoundShell::StopSound2D(uint32 AudioDeviceHandle, uint64 AudioComponentID, float FadeOutDuration, float FadeVolumeLevel, bool Ref /* = false */)
{
    UAudioComponent* Component = FindComponent(AudioComponentID);
    if (Component)
    {
        if (FadeOutDuration > 0.0f)
        {
            Component->FadeOut(FadeOutDuration, FadeVolumeLevel);

            FTimerHandle TimerHandler;
            FTimerManager& TimerManager = ClientShell->GetWorld()->GetTimerManager();
            TimerManager.SetTimer(TimerHandler, [this, Ref, AudioComponentID]()
            {
                UAudioComponent* ComponentToDestroy = UAudioComponent::GetAudioComponentFromID(AudioComponentID);
                if (ComponentToDestroy && IsValid(ComponentToDestroy))
                {
                    UGameClient* pGameClient = UGameClient::Get(this);
                    if (pGameClient && Ref)
                    {
                        pGameClient->RemoveReferencedObject(ComponentToDestroy);
                    }
                    ComponentToDestroy->DestroyComponent();
                }
            }
            , FadeOutDuration + 1.0f, false);
        }
        else
        {
            if (Ref)
            {
                UGameClient::Get(this)->RemoveReferencedObject(Component);
            }
            Component->Stop();
            Component->DestroyComponent();
        }
    }
    else
    {
        if (FAudioDevice* AudioDevice = GetAudioDevice(ClientShell->GetWorld(), AudioDeviceHandle))
        {
            if (FadeOutDuration > 0.0f)
            {
                DECLARE_CYCLE_STAT(TEXT("FAudioThreadTask.FadeOutGameSound"), STAT_AudioFadeOutGameSound, STATGROUP_AudioThreadCommands);
                const uint64 MyAudioComponentID = AudioComponentID;
                FAudioThread::RunCommandOnAudioThread([AudioDevice, MyAudioComponentID, FadeOutDuration, FadeVolumeLevel]()
                {
                    FActiveSound* ActiveSound = AudioDevice->FindActiveSound(MyAudioComponentID);
                    if (ActiveSound)
                    {
                        ActiveSound->FadeOut = FActiveSound::EFadeOut::User;
                        Audio::FVolumeFader& Fader = ActiveSound->ComponentVolumeFader;
                        Fader.SetActiveDuration(FadeOutDuration);
                        Fader.StartFade(FadeVolumeLevel, FadeOutDuration, Audio::EFaderCurve::Linear);
                    }
                }, GET_STATID(STAT_AudioFadeOutGameSound));
            }
            else
            {
                DECLARE_CYCLE_STAT(TEXT("FAudioThreadTask.StopActiveGameSound"), STAT_AudioStopActiveGameSound, STATGROUP_AudioThreadCommands);

                const uint64 MyAudioComponentID = AudioComponentID;
                FAudioThread::RunCommandOnAudioThread([AudioDevice, MyAudioComponentID]()
                {
                    AudioDevice->StopActiveSound(MyAudioComponentID);
                }, GET_STATID(STAT_AudioStopActiveGameSound));
            }
        }
    }
}

void UGameSoundShell::SetPaused(uint32 AudioDeviceHandle, uint64 AudioComponentID,bool bPaused)
{
    UAudioComponent* Component = FindComponent(AudioComponentID);
    if (Component)
    {
        Component->SetPaused(bPaused);
    }
    else
    {
        if (FAudioDevice* AudioDevice = GetAudioDevice(ClientShell->GetWorld(), AudioDeviceHandle))
        {
            DECLARE_CYCLE_STAT(TEXT("FAudioThreadTask.FadeGameSound"), STAT_AudioFadeGameSound, STATGROUP_AudioThreadCommands);
            const uint64 MyAudioComponentID = AudioComponentID;
            FAudioThread::RunCommandOnAudioThread([AudioDevice, MyAudioComponentID, bPaused]()
            {
                AudioDevice->PauseActiveSound(MyAudioComponentID, bPaused);
            }, GET_STATID(STAT_AudioFadeGameSound));
        }
    }
}

UAudioComponent* UGameSoundShell::FindComponent(uint64 AudioComponentID)
{
    UAudioComponent* Component = UAudioComponent::GetAudioComponentFromID(AudioComponentID);
    if (Component && IsValid(Component))
    {
        return Component;
    }
    return nullptr;
}

//uint64 UGameSoundShell::RegisterToGlobalActor(UAudioComponent* AudioComponent)
//{
//    if (!AudioComponent)
//    {
//        UE_LOG(UGameSoundShellLog, Error, TEXT("AudioComponent is null"));
//        return 0;
//    }
//
//    UWorld* World = ClientShell->GetWorld();   
//    if (!IsValid(World))
//    {
//        UE_LOG(UGameSoundShellLog, Error, TEXT("World is a nullptr or invalid"));
//        return 0;
//    }
//
//    return RegisterToActor(World->PersistentLevel->GetLevelScriptActor(), AudioComponent);
//}
//
//uint64 UGameSoundShell::RegisterToActor(AActor* Actor, UAudioComponent* AudioComponent)
//{
//    if (!Actor || !AudioComponent)
//    {
//        UE_LOG(UGameSoundShellLog, Error, TEXT("Actor or AudioComponent is null"));
//        return 0;
//    }
//
//    AudioComponent->OnAudioFinishedNative.AddUObject(this, &UGameSoundShell::OnAudioFinished);
//    //AudioComponent->RegisterComponentWithWorld(Actor->GetWorld());
//    //Actor->AddOwnedComponent(AudioComponent);
//    FAttachmentTransformRules AttachmentRules(EAttachmentRule::KeepRelative, false);
//    AudioComponent->AttachToComponent(Actor->GetRootComponent(), AttachmentRules);
//    AudioComponent->bAutoDestroy = true;
//    return AudioComponent->GetAudioComponentID();
//}

//void UGameSoundShell::DestroyComponent(uint64 AudioComponentID)
//{
//    UAudioComponent* Component = FindComponent(AudioComponentID);
//    if (Component)
//    {
//        AActor* Actor = Component->GetOwner();
//        Actor->K2_DestroyComponent(Component);
//    }
//}

//void UGameSoundShell::OnAudioFinished(UAudioComponent* AudioComponent)
//{
//    AudioComponent->RemoveFromRoot();
//    OnSoundFinished.Broadcast(AudioComponent->GetAudioComponentID());
//}