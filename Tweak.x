#import <UIKit/UIKit.h>
#import "AmethystMenu/AmethystMenuViewController.h"
#import "AmethystMenu/AmethystFloatingButton.h"
#import "AmethystMenu/AmethystSettings.h"

static UIWindow *AmethystKeyWindow(void) {
    for (UIScene *scene in UIApplication.sharedApplication.connectedScenes) {
        if (![scene isKindOfClass:[UIWindowScene class]]) continue;
        UIWindowScene *windowScene = (UIWindowScene *)scene;
        for (UIWindow *window in windowScene.windows) {
            if (window.isKeyWindow) return window;
        }
    }
    return nil;
}

static void AmethystInstallOverlay(void) {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIWindow *keyWindow = AmethystKeyWindow();
        if (!keyWindow) return;

        AmethystMenuViewController *menu = [AmethystMenuViewController sharedController];
        [menu attachToWindow:keyWindow];

        AmethystFloatingButton *button = [AmethystFloatingButton sharedButton];
        [button attachToWindow:keyWindow];
        [keyWindow bringSubviewToFront:button];
    });
}

%hook UIApplication

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    BOOL result = %orig;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        AmethystInstallOverlay();
    });
    return result;
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    %orig;
    AmethystInstallOverlay();
}

%end

%ctor {
    NSLog(@"[Amethyst] loaded — tap 'menu' top-right to open overlay");
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        AmethystInstallOverlay();
    });
}
