#pragma once
//
//#include "ScriptActorComponent.h"
//#include "ActorDelegate.h"
//
//#define DECLEAR_ACTOR_NET_FUNCS() \
//        public: \
//            virtual void PostLoad() override;   \
//            virtual void OnActorChannelOpen(class FInBunch& InBunch, class UNetConnection* Connection) override;    \
//            virtual void OnSerializeNewActor(class FOutBunch& OutBunch) override;   \
//            virtual void OnNetCleanup(class UNetConnection* Connection) override;   \
//            virtual void PostNetInit() override;    \
//            virtual void BeginPlay() override;  \
//            void KMPostLoad();  \
//            void KMBeginPlay(); \
//            const FString& GetScriptType(); \
//            void CreateScriptActorComponent(); \
//            class UScriptActorComponent* GetScriptActorComponent();    \
//        private:
//
//#define IMPLEMENT_ACTOR_NET_FUNCS(ClassName, ScriptActor)    \
//            void ClassName::CreateScriptActorComponent()   \
//            {   \
//                ScriptActor = nullptr;  \
//                static FName DefaultScriptActorCompName = FName("ScriptActor");   \
//                ScriptActor = CreateOptionalDefaultSubobject<UScriptActorComponent>(DefaultScriptActorCompName);  \
//            }   \
//            UScriptActorComponent* ClassName::GetScriptActorComponent()    \
//            {   \
//                return ScriptActor;    \
//            }   \
//            void ClassName::OnActorChannelOpen(class FInBunch& InBunch, class UNetConnection* Connection)    \
//            {   \
//                Super::OnActorChannelOpen(InBunch, Connection); \
//                GetScriptActorComponent()->OnActorChannelOpen(InBunch, Connection);  \
//            }   \
//            void ClassName::OnSerializeNewActor(class FOutBunch& OutBunch)   \
//            {   \
//                Super::OnSerializeNewActor(OutBunch);   \
//                GetScriptActorComponent()->OnSerializeNewActor(OutBunch);    \
//            }   \
//            void ClassName::OnNetCleanup(class UNetConnection* Connection)   \
//            {   \
//                Super::OnNetCleanup(Connection);    \
//                GetScriptActorComponent()->OnNetCleanup(Connection);   \
//            }   \
//            void ClassName::PostNetInit()   \
//            {   \
//                Super::PostNetInit();    \
//                GetScriptActorComponent()->PostNetInit(); \
//            }   \
//            void ClassName::PostLoad()  \
//            {   \
//                Super::PostLoad();  \
//                KMPostLoad();   \
//                auto ScriptActorComponent = GetScriptActorComponent();  \
//                if (ScriptActorComponent)   \
//                {   \
//                    ScriptActorComponent->SetScriptType(GetScriptType());  \
//                }   \
//            }   \
//            void ClassName::BeginPlay()  \
//            {   \
//                Super::BeginPlay();  \
//                KMBeginPlay();   \
//                GetScriptActorComponent()->OnActorBeginPlay();  \
//            }
//
//#define DEFAULT_IMPLEMENT_KMACTOR_FUNCS(ClassName)  \
//            void ClassName::KMPostLoad() {} \
//            void ClassName::KMBeginPlay() {} \
//            const FString& ClassName::GetScriptType() { static FString EmptyString = TEXT(""); return EmptyString; }