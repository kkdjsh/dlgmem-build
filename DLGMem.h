// DLGMem.h
// 对应原版 DLGMem 类（g_task/g_chain/g_type/_memView）
#import <UIKit/UIKit.h>
#import "memory_engine.h"

@class DLGMemUIView;

@interface DLGMem : NSObject
@property (nonatomic, assign) mach_port_t g_task;
@property (nonatomic, assign) search_result_chain_t *g_chain;
@property (nonatomic, assign) int g_type;
@property (nonatomic, strong) DLGMemUIView *memView;

+ (void)initAll;
+ (void)launchDLGMem;

// 搜索：value 字符串，type=DLGMemValueType，comparison=DLGMemComparison
+ (void)searchMem:(NSString *)value
              type:(NSInteger)type
        comparison:(NSInteger)comparison;

// 修改：address 十六进制字符串，value 新值，type=DLGMemValueType
+ (void)modifyMem:(NSString *)address
             value:(NSString *)value
             type:(NSInteger)type;

+ (void)refresh;   // DLGMemUIRefresh
+ (void)reset;     // DLGMemUIReset
+ (void)readMemoryAt:(NSString *)address size:(NSString *)size; // DLGMemUIMemory:size:
@end
