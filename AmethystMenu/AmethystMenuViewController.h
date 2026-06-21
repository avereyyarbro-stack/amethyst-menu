#import <UIKit/UIKit.h>

@interface AmethystMenuViewController : UIViewController
+ (instancetype)sharedController;
- (void)attachToWindow:(UIWindow *)window;
- (void)showMenu;
- (void)hideMenu;
- (void)toggleVisibility;
@end
