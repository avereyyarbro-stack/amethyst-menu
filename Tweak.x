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
        if (windowScene.windows.count > 0) {
            return windowScene.windows.firstObject;
        }
    }
    return UIApplication.sharedApplication.keyWindow;
}

static void AmethystInstallOverlayWithRetry(NSInteger attempt);

static void AmethystInstallOverlayWithRetry(NSInteger attempt) {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIWindow *keyWindow = AmethystKeyWindow();
        if (!keyWindow) {
            if (attempt < 40) {
                dispatch_after(
                    dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)),
                    dispatch_get_main_queue(), ^{
                        AmethystInstallOverlayWithRetry(attempt + 1);
                    });
            }
            return;
        }

        AmethystMenuViewController *menu = [AmethystMenuViewController sharedController];
        [menu attachToWindow:keyWindow];

        AmethystFloatingButton *button = [AmethystFloatingButton sharedButton];
        [button attachToWindow:keyWindow];
        [keyWindow bringSubviewToFront:button];
    });
}

static void AmethystInstallOverlay(void) {
    AmethystInstallOverlayWithRetry(0);
}

static void AmethystRegisterLifecycleHooks(void) {
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center addObserverForName:UIApplicationDidFinishLaunchingNotification
                        object:nil
                         queue:[NSOperationQueue mainQueue]
                    usingBlock:^(NSNotification *note) {
                        (void)note;
                        dispatch_after(
                            dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)),
                            dispatch_get_main_queue(), ^{
                                AmethystInstallOverlay();
                            });
                    }];
    [center addObserverForName:UIApplicationDidBecomeActiveNotification
                        object:nil
                         queue:[NSOperationQueue mainQueue]
                    usingBlock:^(NSNotification *note) {
                        (void)note;
                        AmethystInstallOverlay();
                    }];
}

static void AmethystBootstrap(void) {
    NSLog(@"[Amethyst] sideload build loaded - tap menu top-right");
    AmethystRegisterLifecycleHooks();
    dispatch_after(
        dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)),
        dispatch_get_main_queue(), ^{
            AmethystInstallOverlay();
        });
}

%ctor {
    dispatch_async(dispatch_get_main_queue(), ^{
        AmethystBootstrap();
    });
}
