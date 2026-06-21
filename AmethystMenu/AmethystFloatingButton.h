#import <UIKit/UIKit.h>

@interface AmethystFloatingButton : UIButton
+ (instancetype)sharedButton;
- (void)attachToWindow:(UIWindow *)window;
@end
