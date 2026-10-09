// memory_engine.h
// 对应原版 C++ 导出符号：JRMemoryEngine / search_int* / search_uint* / search_float/double
// 基于 mach_vm_* 的进程内内存扫描引擎
#ifndef memory_engine_h
#define memory_engine_h

#include <stdint.h>
#include <stddef.h>
#include <mach/mach.h>

#ifdef __cplusplus
extern "C" {
#endif

// 值类型（对应原版 dlgmemvalueKind / I8 I16 I32 I64 F32 F64 字符串）
typedef enum {
    DLGMemValueType_Int8   = 0,
    DLGMemValueType_Int16  = 1,
    DLGMemValueType_Int32  = 2,
    DLGMemValueType_Int64 = 3,
    DLGMemValueType_Float  = 4,
    DLGMemValueType_Double = 5
} DLGMemValueType;

// 比较方式（对应原版 scComparison）
typedef enum {
    DLGMemComparison_Equal        = 0,  // =
    DLGMemComparison_GreaterThan  = 1,  // >
    DLGMemComparison_LessThan     = 2,  // <
    DLGMemComparison_IncreasedBy   = 3,  // 增加了 N
    DLGMemComparison_DecreasedBy   = 4,  // 减少了 N
    DLGMemComparison_Changed       = 5,  // 变化了
    DLGMemComparison_Unchanged     = 6   // 没变
} DLGMemComparison;

// 单个结果节点
typedef struct search_result {
    uint64_t address;
    uint64_t padding;
    struct search_result *next;
} search_result_t;

// 结果链头
typedef struct search_result_chain {
    search_result_t *head;
    search_result_t *tail;
    int64_t count;
} search_result_chain_t;

// 全局 task port（对应 DLGMem.g_task）
extern mach_port_t g_task;
extern search_result_chain_t *g_chain;
extern int g_type;

// ---- C API（对应原版导出函数）----
int      get_task(void);                       // task_for_pid(mach_task_self)
uint64_t get_base_address(void);
int      get_all_images(struct _image *imgs);  // dyld 镜像枚举
int      read_mem(uint64_t addr, void *buf, size_t n);          // mach_vm_read_overwrite
int      write_mem(uint64_t addr, const void *buf, size_t n);   // mach_vm_write
int      read_region(uint64_t addr, vm_region_basic_info_64_t *info, mach_msg_type_number_t *size);
int      read_range_mem(uint64_t addr, int64_t size, int type, void *out, size_t *outsz);

search_result_chain_t *create_search_result_chain(void);
void    destroy_search_result_chain(search_result_chain_t *c);
void    destroy_all_search_result_chain(void);
void    show_search_result_chain(search_result_chain_t *c);
void    print_chain(search_result_chain_t *c);
void    print_mem(uint64_t addr, size_t n);
void    review_mem_in_chain(search_result_chain_t *c, int type);

size_t  size_of_type(int type);
int     value_of_type(int type, const char *str, void *out);
int     compare_value(int cmp, const void *cur, const void *old, const void *input);

// 按类型扫描
int search_mem_first(int type, int isUnsigned, const char *value);          // 首次扫描，建链
int search_mem_in_chain(int type, int isUnsigned, const char *value, int cmp); // 链内过滤
int search_mem_value(int type, int isUnsigned, uint64_t addr, const void *val);

// 逐类型搜索（内部）
int search_int8(uint64_t addr, uint64_t size, int8_t  val);
int search_int16(uint64_t addr, uint64_t size, int16_t val);
int search_int32(uint64_t addr, uint64_t size, int32_t val);
int search_int64(uint64_t addr, uint64_t size, int64_t val);
int search_uint8(uint64_t addr, uint64_t size, uint8_t  val);
int search_uint16(uint64_t addr, uint64_t size, uint16_t val);
int search_uint32(uint64_t addr, uint64_t size, uint32_t val);
int search_uint64(uint64_t addr, uint64_t size, uint64_t val);
int search_float(uint64_t addr, uint64_t size, float   val);
int search_double(uint64_t addr, uint64_t size, double val);

// 修改
int modify_mem(uint64_t address, const void *value, size_t n);

#ifdef __cplusplus
}
#endif

#endif /* memory_engine_h */
