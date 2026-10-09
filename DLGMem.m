// DLGMem.m
#import "DLGMem.h"
#import "DLGMemUIView.h"

static DLGMem *_instance;

@implementation DLGMem

+ (void)initAll {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [[DLGMem alloc] init];
        get_task();
        _instance.g_chain = create_search_result_chain();
    });
}

+ (void)launchDLGMem {
    [DLGMem initAll];
    UIWindow *win = [UIApplication sharedApplication].keyWindow;
    [DLGMemUIView addDLGMemUIViewToWindow:win withDelegate:nil];
}

+ (void)searchMem:(NSString *)value type:(NSInteger)type comparison:(NSInteger)comparison {
    if (!_instance.g_chain || _instance.g_chain->count == 0) {
        search_mem_first((int)type, 0, value.UTF8String);
    } else {
        search_mem_in_chain((int)type, 0, value.UTF8String, (int)comparison);
    }
    _instance.g_type = (int)type;
}

+ (void)modifyMem:(NSString *)address value:(NSString *)value type:(NSInteger)type {
    // address 是十六进制字符串
    unsigned long long addr = 0;
    NSScanner *sc = [NSScanner scannerWithString:address];
    [sc scanHexLongLong:&addr];

    size_t sz = size_of_type((int)type);
    uint8_t buf[16] = {0};
    value_of_type((int)type, value.UTF8String, buf);

    int rc = modify_mem((uint64_t)addr, buf, sz);
    if (rc == 0) {
        NSLog(@"Modified successfully.");
    } else {
        NSLog(@"Failed to modify. Error: %d", rc);
    }
}

+ (void)refresh {
    review_mem_in_chain(_instance.g_chain, _instance.g_type);
}

+ (void)reset {
    destroy_search_result_chain(_instance.g_chain);
    _instance.g_chain = create_search_result_chain();
}

+ (void)readMemoryAt:(NSString *)address size:(NSString *)size {
    unsigned long long addr = 0;
    NSScanner *sc = [NSScanner scannerWithString:address];
    [sc scanHexLongLong:&addr];
    size_t n = (size_t)[size longLongValue];
    print_mem((uint64_t)addr, n);
}

@end
