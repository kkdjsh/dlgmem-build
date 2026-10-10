// fishhook.h
#ifndef FISHHOOK_H
#define FISHHOOK_H
#include <sys/types.h>
#include <mach/mach.h>

struct rebinding {
    const char *name;
    void *replacement;
    void **replaced;
};

extern "C" {
#endif

int rebind_symbols(struct rebinding rebindings[], size_t rebindings_nel);

#ifdef __cplusplus
}
#endif

#endif
