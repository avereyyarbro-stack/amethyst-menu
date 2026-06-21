#import "AmethystSettings.h"

static NSString *const kAmethystDomain = @"com.amethyst.menu.settings";

static NSString *AmethystModKey(AmethystMod mod) {
    switch (mod) {
        case AmethystModEnemyHealth:
            return @"enemy_health_numbers";
        case AmethystModAnaksorInvisHighlight:
            return @"anaksor_invis_highlight";
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

- (NSString *)titleForMod:(AmethystMod)mod {
    switch (mod) {
        case AmethystModEnemyHealth:
            return @"enemy team health numbers";
        case AmethystModAnaksorInvisHighlight:
            return @"anaksor invisibility highlight";
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
        default:
            return @"";
    }
}

@end
