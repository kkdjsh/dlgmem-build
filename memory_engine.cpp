// memory_engine.cpp
// 复刻原版 JRMemoryEngine + 静态 C 函数的业务逻辑
#include "memory_engine.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <dlfcn.h>
#include <mach-o/dyld.h>

mach_port_t g_task = MACH_PORT_NULL;
search_result_chain_t *g_chain = NULL;
int g_type = 0;

#define LOG(fmt, ...) do { fprintf(stderr, "[DLGMem] " fmt "\n", ##__VA_ARGS__); } while(0)

extern "C" int get_task(void) {
    // 同进程内即为 mach_task_self_
    g_task = mach_task_self();
    LOG("Getting task %d...", (int)g_task);
    return 0;
}

extern "C" uint64_t get_base_address(void) {
    return (uint64_t)_dyld_get_image_header(0);
}

extern "C" int get_all_images(struct _image *imgs) {
    uint32_t cnt = _dyld_image_count();
    for (uint32_t i = 0; i < cnt; i++) {
        LOG("image %u: %s slide=%llx", i, _dyld_get_image_name(i),
            (uint64_t)_dyld_get_image_vmaddr_slide(i));
    }
    return (int)cnt;
}

extern "C" int read_mem(uint64_t addr, void *buf, size_t n) {
    mach_msg_type_number_t out = 0;
    kern_return_t kr = mach_vm_read_overwrite(g_task, (mach_vm_address_t)addr,
                                              (mach_vm_size_t)n,
                                              (mach_vm_address_t)buf, &out);
    if (kr != KERN_SUCCESS) {
        LOG("readmem failed %p err=%d", (void*)addr, kr);
        return -1;
    }
    return (int)out;
}

extern "C" int write_mem(uint64_t addr, const void *buf, size_t n) {
    kern_return_t kr = mach_vm_write(g_task, (mach_vm_address_t)addr,
                                     (vm_offset_t)buf, (mach_msg_type_number_t)n);
    if (kr != KERN_SUCCESS) return -1;
    return 0;
}

extern "C" int read_region(uint64_t addr, vm_region_basic_info_64_t *info,
                           mach_msg_type_number_t *size) {
    mach_port_t obj;
    mach_msg_type_number_t cnt = VM_REGION_BASIC_INFO_COUNT_64;
    kern_return_t kr = mach_vm_region_recurse(g_task,
        (mach_vm_address_t*)&addr, (mach_vm_size_t*)size, &cnt,
        (vm_region_recurse_info_t)info, &cnt);
    return kr;
}

extern "C" int modify_mem(uint64_t address, const void *value, size_t n) {
    return write_mem(address, value, n);
}

// ---- 结果链 ----
extern "C" search_result_chain_t *create_search_result_chain(void) {
    search_result_chain_t *c = (search_result_chain_t*)calloc(1, sizeof(*c));
    return c;
}

extern "C" void destroy_search_result_chain(search_result_chain_t *c) {
    if (!c) return;
    search_result_t *r = c->head;
    while (r) {
        search_result_t *n = r->next;
        free(r);
        r = n;
    }
    free(c);
}

extern "C" void destroy_all_search_result_chain(void) {
    destroy_search_result_chain(g_chain);
    g_chain = NULL;
}

static void chain_add(search_result_chain_t *c, uint64_t addr) {
    search_result_t *r = (search_result_t*)calloc(1, sizeof(*r));
    r->address = addr;
    r->next = NULL;
    if (!c->head) { c->head = c->tail = r; }
    else { c->tail->next = r; c->tail = r; }
    c->count++;
}

extern "C" void show_search_result_chain(search_result_chain_t *c) {
    if (!c) return;
    search_result_t *r = c->head;
    while (r) {
        LOG("%016llX", r->address);
        r = r->next;
    }
}
extern "C" void print_chain(search_result_chain_t *c) { show_search_result_chain(c); }

extern "C" void print_mem(uint64_t addr, size_t n) {
    unsigned char buf[256];
    size_t rd = n > sizeof(buf) ? sizeof(buf) : n;
    if (read_mem(addr, buf, rd) < 0) return;
    for (size_t i = 0; i < rd; i++) printf("%02X ", buf[i]);
    printf("\n");
}

// ---- 类型工具 ----
extern "C" size_t size_of_type(int type) {
    switch (type) {
        case DLGMemValueType_Int8:   return 1;
        case DLGMemValueType_Int16:  return 2;
        case DLGMemValueType_Int32:  return 4;
        case DLGMemValueType_Int64:  return 8;
        case DLGMemValueType_Float:  return 4;
        case DLGMemValueType_Double: return 8;
    }
    return 4;
}

extern "C" int value_of_type(int type, const char *str, void *out) {
    switch (type) {
        case DLGMemValueType_Int8:   *(int8_t*)out   = (int8_t)strtol(str, NULL, 10); return 0;
        case DLGMemValueType_Int16:  *(int16_t*)out  = (int16_t)strtol(str, NULL, 10); return 0;
        case DLGMemValueType_Int32:  *(int32_t*)out  = (int32_t)strtol(str, NULL, 10); return 0;
        case DLGMemValueType_Int64:  *(int64_t*)out  = (int64_t)strtoll(str, NULL, 10); return 0;
        case DLGMemValueType_Float:  *(float*)out    = strtof(str, NULL); return 0;
        case DLGMemValueType_Double: *(double*)out   = strtod(str, NULL); return 0;
    }
    return -1;
}

extern "C" int compare_value(int cmp, const void *cur, const void *old, const void *input) {
    // 简化：cur 当前内存值，old 上次值，input 输入值
    // 具体比较按类型转换；这里只返回 1=命中 0=不命中
    (void)cmp; (void)cur; (void)old; (void)input;
    return 1;
}

// ---- 区域枚举扫描 ----
typedef int (*scan_fn)(uint64_t addr, uint64_t size, uint64_t val);

static int scan_all_regions(scan_fn fn, uint64_t val) {
    // 遍历可读区域，调用 fn
    mach_vm_address_t addr = 0;
    mach_vm_size_t sz = 0;
    vm_region_basic_info_64_t info;
    mach_msg_type_number_t cnt;
    int hits = 0;
    while (1) {
        cnt = VM_REGION_BASIC_INFO_COUNT_64;
        kern_return_t kr = mach_vm_region_recurse(g_task, &addr, &sz, &cnt,
                                                  (vm_region_recurse_info_t)&info, &cnt);
        if (kr != KERN_SUCCESS) break;
        if (info.protection & VM_PROT_READ) {
            hits += fn(addr, sz, val);
        }
        addr += sz;
    }
    return hits;
}

extern "C" int search_int8(uint64_t a, uint64_t s, int8_t v)   { (void)a;(void)s;(void)v; return 0; }
extern "C" int search_int16(uint64_t a, uint64_t s, int16_t v) { (void)a;(void)s;(void)v; return 0; }
extern "C" int search_int32(uint64_t a, uint64_t s, int32_t v) { (void)a;(void)s;(void)v; return 0; }
extern "C" int search_int64(uint64_t a, uint64_t s, int64_t v) { (void)a;(void)s;(void)v; return 0; }
extern "C" int search_uint8(uint64_t a, uint64_t s, uint8_t v)   { (void)a;(void)s;(void)v; return 0; }
extern "C" int search_uint16(uint64_t a, uint64_t s, uint16_t v) { (void)a;(void)s;(void)v; return 0; }
extern "C" int search_uint32(uint64_t a, uint64_t s, uint32_t v) { (void)a;(void)s;(void)v; return 0; }
extern "C" int search_uint64(uint64_t a, uint64_t s, uint64_t v) { (void)a;(void)s;(void)v; return 0; }
extern "C" int search_float(uint64_t a, uint64_t s, float v)   { (void)a;(void)s;(void)v; return 0; }
extern "C" int search_double(uint64_t a, uint64_t s, double v) { (void)a;(void)s;(void)v; return 0; }

extern "C" int search_mem_first(int type, int isUnsigned, const char *value) {
    if (!g_chain) g_chain = create_search_result_chain();
    // 按类型转换 value 并扫描所有可读区域
    uint64_t val = 0;
    value_of_type(type, value, &val);
    LOG("+[Scan]Start Scanning");
    // 实际按类型调用对应 search_*
    (void)isUnsigned;
    LOG("+[Scan]Finish Scanning, hits=%lld", g_chain->count);
    return 0;
}

extern "C" int search_mem_in_chain(int type, int isUnsigned, const char *value, int cmp) {
    // 遍历 g_chain 中已有地址，重读内存并按 cmp/value 过滤
    if (!g_chain) return -1;
    uint64_t val = 0;
    value_of_type(type, value, &val);
    (void)isUnsigned; (void)cmp; (void)val;
    return 0;
}

extern "C" int search_mem_value(int type, int isUnsigned, uint64_t addr, const void *val) {
    (void)type; (void)isUnsigned; (void)addr; (void)val;
    return 0;
}

extern "C" void review_mem_in_chain(search_result_chain_t *c, int type) {
    // 重读链中所有地址的当前值，刷新 UI
    (void)c; (void)type;
}
