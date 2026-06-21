#import <Foundation/Foundation.h>

@interface AmethystLayoutLogger : NSObject

+ (NSString *)logFilePath;
+ (BOOL)anyLayoutLoggerEnabled;
+ (void)logLayoutsNow;
+ (void)logLayoutsIfEnabled;

@end
