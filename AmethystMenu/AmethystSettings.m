#import "AmethystSettings.h"

static NSString *const kAmethystDomain = @"com.amethyst.menu.settings";

static NSString *AmethystModKey(AmethystMod mod) {
    switch (mod) {
        case AmethystModEnemyHealth:
            return @"enemy_health_numbers";
        case AmethystModAnaksorInvisHighlight:
            return @"anaksor_invis_highlight";
        case AmethystModLayoutRobotSlots:
            return @"layout_robot_slots";
        case AmethystModLayoutSlotRobots:
            return @"layout_slot_robots";
        case AmethystModLayoutRobotWeapons:
            return @"layout_robot_weapons";
        case AmethystModLayoutTitanWeapons:
            return @"layout_titan_weapons";
        default:
            return @"unknown";
    }
}

@implementation AmethystSettings

+ (instancetype)shared {
    static AmethystSettings *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[AmethystSettings alloc] init];
    });
    return instance;
}

- (BOOL)isEnabled:(AmethystMod)mod {
    return [[NSUserDefaults standardUserDefaults] boolForKey:AmethystModKey(mod)];
}

- (void)setEnabled:(BOOL)enabled forMod:(AmethystMod)mod {
    [[NSUserDefaults standardUserDefaults] setBool:enabled forKey:AmethystModKey(mod)];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (AmethystModCategory)categoryForMod:(AmethystMod)mod {
    if (mod <= AmethystModAnaksorInvisHighlight) {
        return AmethystModCategoryInformational;
    }
    return AmethystModCategoryLayouts;
}

- (NSString *)categoryTitle:(AmethystModCategory)category {
    switch (category) {
        case AmethystModCategoryInformational:
            return @"informational mods";
        case AmethystModCategoryLayouts:
            return @"layouts";
        default:
            return @"mods";
    }
}

- (NSArray<NSNumber *> *)modsForCategory:(AmethystModCategory)category {
    NSMutableArray<NSNumber *> *mods = [NSMutableArray array];
    for (NSInteger i = 0; i < AmethystModCount; i++) {
        AmethystMod mod = (AmethystMod)i;
        if ([self categoryForMod:mod] == category) {
            [mods addObject:@(mod)];
        }
    }
    return mods;
}

- (BOOL)isLayoutMod:(AmethystMod)mod {
    return [self categoryForMod:mod] == AmethystModCategoryLayouts;
}

- (NSString *)keyForMod:(AmethystMod)mod {
    return AmethystModKey(mod);
}

- (NSString *)titleForMod:(AmethystMod)mod {
    switch (mod) {
        case AmethystModEnemyHealth:
            return @"enemy team health numbers";
        case AmethystModAnaksorInvisHighlight:
            return @"anaksor invisibility highlight";
        case AmethystModLayoutRobotSlots:
            return @"log robot slots";
        case AmethystModLayoutSlotRobots:
            return @"log slot robots";
        case AmethystModLayoutRobotWeapons:
            return @"log robot weapons";
        case AmethystModLayoutTitanWeapons:
            return @"log titan weapons";
        default:
            return @"unknown";
    }
}

- (NSString *)descriptionForMod:(AmethystMod)mod {
    switch (mod) {
        case AmethystModEnemyHealth:
            return @"display numeric hp above enemy robots";
        case AmethystModAnaksorInvisHighlight:
            return @"outline anaksor while stealth is active";
        case AmethystModLayoutRobotSlots:
            return @"record hangar slot ids to layouts.log";
        case AmethystModLayoutSlotRobots:
            return @"record robot name/id per slot";
        case AmethystModLayoutRobotWeapons:
            return @"record equipped weapons per robot";
        case AmethystModLayoutTitanWeapons:
            return @"record titan and titan weapon loadout";
        default:
            return @"";
    }
}

@end
