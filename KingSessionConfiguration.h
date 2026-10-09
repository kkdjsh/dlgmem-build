// KingSessionConfiguration.h
// 对应原版 KingSessionConfiguration：swizzle NSURLSessionConfiguration，注册 JianghuPlayer
#import <Foundation/Foundation.h>

@interface KingSessionConfiguration : NSObject
@property (nonatomic, assign) BOOL isSwizzle;
+ (NSURLSessionConfiguration *)defaultConfiguration;
+ (void)swizzleSelector:(SEL)orig fromClass:(Class)from toClass:(Class)to;
@end
