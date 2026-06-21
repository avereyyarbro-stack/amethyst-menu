#import <UIKit/UIKit.h>
#import "AmethystSettings.h"

@interface AmethystToggleRow : UIControl

@property (nonatomic, assign) AmethystMod mod;
@property (nonatomic, copy) void (^onToggle)(AmethystMod mod, BOOL enabled);

- (instancetype)initWithMod:(AmethystMod)mod;

@end
