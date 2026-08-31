#pragma once

#include "GameSoundShell.generated.h"

class UClientShell;
class UAudioComponent;
class FAudioDevice;

DECLARE_DYNAMIC_MULTICAST_DELEGATE_OneParam(FOnGameSoundFinished, uint64, AudioComponentID);

UCLASS()
class CLIENT_API UGameSoundShell : public UObject
{
public:
    GENERATED_UCLASS_BODY()

    void Init(UClientShell* Shell);

    // 如果要切地图时背景乐还有声音，那么只能在wave里looping，soundcue里不能有loop，这样的话切图时component会删掉，但audio不会删，
    // 这种情况下就需要手动删除audio，这函数返出来OutAudioDeviceHandle和OutAudioComponentID，也是为了删除时能用的上
    UFUNCTION()
    bool PlaySound2D(UObject* Sound, bool bOneShot, float FadeInDuration, 
		uint32& OutAudioDeviceHandle, uint64& OutAudioComponentID, float& OutDuration, bool Ref = false);

    UFUNCTION()
    void StopSound2D(uint32 AudioDeviceHandle, uint64 AudioComponentID, float FadeOutDuration, float FadeVolumeLevel, bool Ref = false);

    UFUNCTION()
    void SetPaused(uint32 AudioDeviceHandle, uint64 AudioComponentID,bool bPaused);

    UFUNCTION()
    UAudioComponent* FindComponent(uint64 AudioComponentID);

    //UFUNCTION()
    //uint64 RegisterToGlobalActor(UAudioComponent* AudioComponent);

    //UFUNCTION()
    //uint64 RegisterToActor(AActor* Actor, UAudioComponent* AudioComponent);

    //UFUNCTION()
    //void DestroyComponent(uint64 AudioComponentID);

    //UPROPERTY()
    //FOnGameSoundFinished OnSoundFinished;

private:
    //void OnAudioFinished(UAudioComponent* AudioComponent);
    //FAudioDevice* GetAudioDevice(uint32 AudioDeviceHandle) const;

private:
    UClientShell* ClientShell;
};