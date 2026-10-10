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

extern int rebind_symbols(struct rebinding rebindings[], size_t rebindings_nel);
extern int rebind_symbols_image(void *header, size_t size, struct rebinding rebindings[], size_t rebindings_nel);

#endif
