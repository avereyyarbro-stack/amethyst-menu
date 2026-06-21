#import <UIKit/UIKit.h>
#import <objc/runtime.h>
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

static void AmethystInstallOverlay(void);
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

static void AmethystSwizzle(Class cls, SEL original, SEL replacement) {
    Method origMethod = class_getInstanceMethod(cls, original);
    Method newMethod = class_getInstanceMethod(cls, replacement);
    if (!origMethod || !newMethod) return;

    if (class_addMethod(cls, original, method_getImplementation(newMethod), method_getTypeEncoding(newMethod))) {
        class_replaceMethod(
            cls,
            replacement,
            method_getImplementation(origMethod),
            method_getTypeEncoding(origMethod));
    } else {
        method_exchangeImplementations(origMethod, newMethod);
    }
}

@interface UIApplication (AmethystSideload)
- (BOOL)amethyst_application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions;
- (void)amethyst_applicationDidBecomeActive:(UIApplication *)application;
@end

@implementation UIApplication (AmethystSideload)

- (BOOL)amethyst_application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    BOOL result = [self amethyst_application:application didFinishLaunchingWithOptions:launchOptions];
    dispatch_after(
        dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)),
        dispatch_get_main_queue(), ^{
            AmethystInstallOverlay();
        });
    return result;
}

- (void)amethyst_applicationDidBecomeActive:(UIApplication *)application {
    [self amethyst_applicationDidBecomeActive:application];
    AmethystInstallOverlay();
}

@end

static void AmethystBootstrap(void) {
    NSLog(@"[Amethyst] sideload build loaded — tap menu top-right");

    AmethystSwizzle(
        [UIApplication class],
        @selector(application:didFinishLaunchingWithOptions:),
        @selector(amethyst_application:didFinishLaunchingWithOptions:));
    AmethystSwizzle(
        [UIApplication class],
        @selector(applicationDidBecomeActive:),
        @selector(amethyst_applicationDidBecomeActive:));

    dispatch_after(
        dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)),
        dispatch_get_main_queue(), ^{
            AmethystInstallOverlay();
        });
}

__attribute__((constructor)) static void AmethystInit(void) {
    if (NSThread.isMainThread) {
        AmethystBootstrap();
    } else {
        dispatch_async(dispatch_get_main_queue(), AmethystBootstrap);
    }
}
