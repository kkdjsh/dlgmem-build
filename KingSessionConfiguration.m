// KingSessionConfiguration.m
#import "KingSessionConfiguration.h"
#import "JianghuPlayer.h"
#import <objc/runtime.h>

static BOOL g_isSwizzle = NO;

@implementation KingSessionConfiguration

+ (void)load {
    if (g_isSwizzle) return;
    // 注册自定义 NSURLProtocol
    [NSURLProtocol registerClass:[JianghuPlayer class]];

    // swizzle NSURLSessionConfiguration defaultSessionConfiguration
    [self swizzleSelector:@selector(defaultSessionConfiguration)
                fromClass:NSClassFromString(@"__NSCFURLSessionConfiguration")
                   toClass:self];
    g_isSwizzle = YES;
}

+ (NSURLSessionConfiguration *)defaultConfiguration {
    NSURLSessionConfiguration *cfg = [KingSessionConfiguration defaultConfiguration];
    // 把 JianghuPlayer 加入 protocolClasses
    NSMutableArray *arr = [cfg.protocolClasses mutableCopy] ?: [NSMutableArray array];
    if (![arr containsObject:[JianghuPlayer class]]) {
        [arr insertObject:[JianghuPlayer class] atIndex:0];
    }
    cfg.protocolClasses = arr;
    return cfg;
}

+ (void)swizzleSelector:(SEL)orig fromClass:(Class)from toClass:(Class)to {
    if (!from) return;
    Method m1 = class_getClassMethod(from, orig);
    Method m2 = class_getClassMethod(to, orig);
    if (m1 && m2) method_exchangeImplementations(m1, m2);
}

@end
