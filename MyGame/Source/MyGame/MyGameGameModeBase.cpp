#include "MyGameGameModeBase.h"
#include "MyGamePawn.h"
#include "MyGamePlayerController.h"
#include "MyGameHUD.h"

AMyGameGameModeBase::AMyGameGameModeBase()
{
	DefaultPawnClass = AMyGamePawn::StaticClass();
	PlayerControllerClass = AMyGamePlayerController::StaticClass();
	HUDClass = AMyGameHUD::StaticClass();
}
