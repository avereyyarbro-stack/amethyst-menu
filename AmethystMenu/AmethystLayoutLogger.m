#import "AmethystLayoutLogger.h"
#import "AmethystSettings.h"

@implementation AmethystLayoutLogger

+ (NSString *)logDirectory {
    NSArray<NSString *> *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documents = paths.firstObject ?: NSTemporaryDirectory();
    NSString *dir = [documents stringByAppendingPathComponent:@"Amethyst"];
    [[NSFileManager defaultManager] createDirectoryAtPath:dir withIntermediateDirectories:YES attributes:nil error:nil];
    return dir;
}

+ (NSString *)logFilePath {
    return [[self logDirectory] stringByAppendingPathComponent:@"layouts.log"];
}

+ (BOOL)anyLayoutLoggerEnabled {
    AmethystSettings *settings = [AmethystSettings shared];
    for (NSNumber *modNum in [settings modsForCategory:AmethystModCategoryLayouts]) {
        if ([settings isEnabled:(AmethystMod)modNum.integerValue]) {
            return YES;
        }
    }
    return NO;
}

+ (NSArray<NSString *> *)enabledLayoutLoggerNames {
    AmethystSettings *settings = [AmethystSettings shared];
    NSMutableArray<NSString *> *names = [NSMutableArray array];
    for (NSNumber *modNum in [settings modsForCategory:AmethystModCategoryLayouts]) {
        AmethystMod mod = (AmethystMod)modNum.integerValue;
        if ([settings isEnabled:mod]) {
            [names addObject:[settings keyForMod:mod]];
        }
    }
    return names;
}

+ (BOOL)string:(NSString *)value matchesAny:(NSArray<NSString *> *)needles {
    NSString *lower = value.lowercaseString;
    for (NSString *needle in needles) {
        if ([lower containsString:needle]) {
            return YES;
        }
    }
    return NO;
}

+ (void)collectFromPlist:(id)plist
                    path:(NSMutableArray<NSString *> *)path
               robotSlots:(NSMutableArray *)robotSlots
               slotRobots:(NSMutableArray *)slotRobots
            robotWeapons:(NSMutableArray *)robotWeapons
             titanWeapons:(NSMutableArray *)titanWeapons
                  sources:(NSMutableArray<NSString *> *)sources {
    if ([plist isKindOfClass:[NSDictionary class]]) {
        NSDictionary *dict = (NSDictionary *)plist;
        for (NSString *key in dict) {
            NSMutableArray<NSString *> *nextPath = [path mutableCopy] ?: [NSMutableArray array];
            [nextPath addObject:key];
            NSString *joined = [nextPath componentsJoinedByString:@"."];

            if ([self string:key matchesAny:@[@"slot", @"hangar", @"bay", @"roster"]]) {
                [sources addObject:joined];
                if ([[AmethystSettings shared] isEnabled:AmethystModLayoutRobotSlots]) {
                    [robotSlots addObject:@{@"path": joined, @"value": dict[key] ?: @""}];
                }
            }
            if ([self string:key matchesAny:@[@"robot", @"mech", @"bot"]]) {
                if ([[AmethystSettings shared] isEnabled:AmethystModLayoutSlotRobots]) {
                    [slotRobots addObject:@{@"path": joined, @"value": dict[key] ?: @""}];
                }
            }
            if ([self string:key matchesAny:@[@"weapon", @"equip", @"gun", @"module"]]) {
                if ([[AmethystSettings shared] isEnabled:AmethystModLayoutRobotWeapons]) {
                    if ([self string:joined matchesAny:@[@"titan"]]) {
                        if ([[AmethystSettings shared] isEnabled:AmethystModLayoutTitanWeapons]) {
                            [titanWeapons addObject:@{@"path": joined, @"value": dict[key] ?: @""}];
                        }
                    } else {
                        [robotWeapons addObject:@{@"path": joined, @"value": dict[key] ?: @""}];
                    }
                }
            }
            if ([self string:key matchesAny:@[@"titan"]] && [[AmethystSettings shared] isEnabled:AmethystModLayoutTitanWeapons]) {
                [titanWeapons addObject:@{@"path": joined, @"value": dict[key] ?: @""}];
            }

            [self collectFromPlist:dict[key]
                              path:nextPath
                         robotSlots:robotSlots
                         slotRobots:slotRobots
                      robotWeapons:robotWeapons
                       titanWeapons:titanWeapons
                            sources:sources];
        }
        return;
    }

    if ([plist isKindOfClass:[NSArray class]]) {
        NSArray *array = (NSArray *)plist;
        [array enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            NSMutableArray<NSString *> *nextPath = [path mutableCopy] ?: [NSMutableArray array];
            [nextPath addObject:[NSString stringWithFormat:@"[%lu]", (unsigned long)idx]];
            [self collectFromPlist:obj
                              path:nextPath
                         robotSlots:robotSlots
                         slotRobots:slotRobots
                      robotWeapons:robotWeapons
                       titanWeapons:titanWeapons
                            sources:sources];
        }];
    }
}

+ (NSDictionary *)buildSnapshot {
    NSMutableArray *robotSlots = [NSMutableArray array];
    NSMutableArray *slotRobots = [NSMutableArray array];
    NSMutableArray *robotWeapons = [NSMutableArray array];
    NSMutableArray *titanWeapons = [NSMutableArray array];
    NSMutableArray<NSString *> *sources = [NSMutableArray array];

    NSDictionary *defaults = [[NSUserDefaults standardUserDefaults] dictionaryRepresentation];
    [self collectFromPlist:defaults
                      path:[@[@"userdefaults"] mutableCopy]
                 robotSlots:robotSlots
                 slotRobots:slotRobots
              robotWeapons:robotWeapons
               titanWeapons:titanWeapons
                    sources:sources];

    NSArray<NSString *> *supportDirs = @[
        [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES).firstObject
            stringByAppendingPathComponent:@"Preferences"],
        NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject ?: @""
    ];

    NSFileManager *fm = NSFileManager.defaultManager;
    for (NSString *dir in supportDirs) {
        if (dir.length == 0 || ![fm fileExistsAtPath:dir]) continue;
        NSArray<NSString *> *files = [fm contentsOfDirectoryAtPath:dir error:nil] ?: @[];
        for (NSString *file in files) {
            NSString *lower = file.lowercaseString;
            if (![lower containsString:@"pixonic"] && ![lower containsString:@"wwr"] && ![lower containsString:@"warrobots"]) {
                continue;
            }
            NSString *fullPath = [dir stringByAppendingPathComponent:file];
            id parsed = nil;
            if ([lower hasSuffix:@".plist"]) {
                parsed = [NSDictionary dictionaryWithContentsOfFile:fullPath];
            } else if ([lower hasSuffix:@".json"]) {
                NSData *data = [NSData dataWithContentsOfFile:fullPath];
                parsed = data ? [NSJSONSerialization JSONObjectWithData:data options:0 error:nil] : nil;
            }
            if (!parsed) continue;
            [sources addObject:fullPath.lastPathComponent];
            [self collectFromPlist:parsed
                              path:[@[fullPath.lastPathComponent] mutableCopy]
                         robotSlots:robotSlots
                         slotRobots:slotRobots
                      robotWeapons:robotWeapons
                       titanWeapons:titanWeapons
                    sources:sources];
        }
    }

    NSDateFormatter *fmt = [[NSDateFormatter alloc] init];
    fmt.dateFormat = @"yyyy-MM-dd'T'HH:mm:ss'Z'";
    fmt.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"UTC"];

    return @{
        @"timestamp": [fmt stringFromDate:[NSDate date]] ?: @"",
        @"category": @"layouts",
        @"enabled_loggers": [self enabledLayoutLoggerNames],
        @"robot_slots": robotSlots,
        @"slot_robots": slotRobots,
        @"robot_weapons": robotWeapons,
        @"titan_weapons": titanWeapons,
        @"sources_scanned": sources,
    };
}

+ (void)appendSnapshot:(NSDictionary *)snapshot {
    NSData *json = [NSJSONSerialization dataWithJSONObject:snapshot options:0 error:nil];
    if (!json) return;

    NSMutableData *payload = [json mutableCopy];
    [payload appendData:[@"\n" dataUsingEncoding:NSUTF8StringEncoding]];

    NSFileHandle *handle = [NSFileHandle fileHandleForWritingAtPath:[self logFilePath]];
    if (!handle) {
        [payload writeToFile:[self logFilePath] atomically:YES];
        return;
    }
    [handle seekToEndOfFile];
    [handle writeData:payload];
    [handle closeFile];
}

+ (void)logLayoutsNow {
    if (![self anyLayoutLoggerEnabled]) {
        NSLog(@"[Amethyst] layouts: enable at least one layouts toggle first");
        return;
    }
    NSDictionary *snapshot = [self buildSnapshot];
    [self appendSnapshot:snapshot];
    NSLog(@"[Amethyst] layouts logged -> %@", [self logFilePath]);
}

+ (void)logLayoutsIfEnabled {
    if ([self anyLayoutLoggerEnabled]) {
        [self logLayoutsNow];
    }
}

@end
