#include "main.h"
#include "AppDelegate.h"
#include "cocos2d.h"
#include "extern/qqHall/QQHallManager.h"
#include "Game.h"

#if CC_TARGET_PLATFORM == CC_PLATFORM_WIN32
#include "resource.h"
HICON hdicon;
#endif

USING_NS_CC;

int WINAPI _tWinMain(HINSTANCE hInstance,
                       HINSTANCE hPrevInstance,
                       LPTSTR    lpCmdLine,
                       int       nCmdShow)
{
#if CC_TARGET_PLATFORM == CC_PLATFORM_WIN32
    hdicon = LoadIcon(hInstance, MAKEINTRESOURCE(IDI_ICON1));
#endif

    UNREFERENCED_PARAMETER(hPrevInstance);
    UNREFERENCED_PARAMETER(lpCmdLine);
    
    // create the application instance
    int ret = -1;
    if ((wcslen(lpCmdLine) > 0 && CQQHallManager::GetInstance()->Init(lpCmdLine))
        || wcslen(lpCmdLine) == 0)
    {
        if (CGame::getInstance()->isDebug())
        {
            AllocConsole();
            freopen("CONIN$", "r", stdin);
            freopen("CONOUT$", "w", stdout);
            freopen("CONOUT$", "w", stderr);
        }

        AppDelegate app;
        ret = Application::getInstance()->run();
    }

    CQQHallManager::GetInstance()->Destory();

    if (CGame::getInstance()->isDebug())
    {
        FreeConsole();
    }

    return ret;
}
