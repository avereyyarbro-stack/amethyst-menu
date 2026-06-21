#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, AmethystModCategory) {
    AmethystModCategoryInformational = 0,
    AmethystModCategoryLayouts,
    AmethystModCategoryCount
};

typedef NS_ENUM(NSInteger, AmethystMod) {
    AmethystModEnemyHealth = 0,
    AmethystModAnaksorInvisHighlight,
    AmethystModLayoutRobotSlots,
    AmethystModLayoutSlotRobots,
    AmethystModLayoutRobotWeapons,
    AmethystModLayoutTitanWeapons,
    AmethystModCount
};

@interface AmethystSettings : NSObject

+ (instancetype)shared;

- (BOOL)isEnabled:(AmethystMod)mod;
- (void)setEnabled:(BOOL)enabled forMod:(AmethystMod)mod;
- (AmethystModCategory)categoryForMod:(AmethystMod)mod;
- (NSString *)categoryTitle:(AmethystModCategory)category;
- (NSArray<NSNumber *> *)modsForCategory:(AmethystModCategory)category;
- (BOOL)isLayoutMod:(AmethystMod)mod;
- (NSString *)keyForMod:(AmethystMod)mod;
- (NSString *)titleForMod:(AmethystMod)mod;
- (NSString *)descriptionForMod:(AmethystMod)mod;

@end
