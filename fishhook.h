#ifndef fishhook_h
#define fishhook_h
#include <stddef.h>

struct rebinding {
    const char *name;
    void *replacement;
    void **replaced;
};

#ifdef __cplusplus
extern "C" {
#endif

int rebind_symbols(struct rebinding rebindings[], size_t rebindings_nel);

#ifdef __cplusplus
}
#endif

#endif
