#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, AmethystMod) {
    AmethystModEnemyHealth = 0,
    AmethystModAnaksorInvisHighlight,
    AmethystModCount
};

@interface AmethystSettings : NSObject

+ (instancetype)shared;

- (BOOL)isEnabled:(AmethystMod)mod;
- (void)setEnabled:(BOOL)enabled forMod:(AmethystMod)mod;
- (NSString *)titleForMod:(AmethystMod)mod;
- (NSString *)descriptionForMod:(AmethystMod)mod;

@end
