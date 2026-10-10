// fishhook.c - rebind symbols
#include "fishhook.h"
#include <string.h>
#include <mach-o/dyld.h>
#include <mach-o/loader.h>
#include <mach-o/nlist.h>

#ifdef __LP64__
typedef struct mach_header_64 mach_header_t;
typedef struct segment_command_64 segment_command_t;
typedef struct section_64 section_t;
typedef struct nlist_64 nlist_t;
#define LC_SEGMENT_ARCH_DEPENDENT LC_SEGMENT_64
#else
typedef struct mach_header mach_header_t;
typedef struct segment_command segment_command_t;
typedef struct section section_t;
typedef struct nlist nlist_t;
#define LC_SEGMENT_ARCH_DEPENDENT LC_SEGMENT
#endif

static void rebind_with_section(section_t *sect, intptr_t slide,
                                nlist_t *symtab, char *strtab,
                                uint32_t *indirect,
                                struct rebinding rebinds[], size_t n) {
    uintptr_t *table = (uintptr_t *)(slide + sect->addr);
    uint32_t *idx = (uint32_t *)(indirect + sect->reserved1);
    uint32_t count = sect->size / sizeof(uintptr_t);
    for (uint32_t i = 0; i < count; i++) {
        uint32_t si = idx[i];
        if (si & INDIRECT_SYMBOL_LOCAL || si & INDIRECT_SYMBOL_ABS) continue;
        const char *name = strtab + symtab[si].n_un.n_strx;
        for (size_t j = 0; j < n; j++) {
            if (strcmp(name, rebinds[j].name) == 0) {
                if (rebinds[j].replaced) *rebinds[j].replaced = (void *)table[i];
                table[i] = (uintptr_t)rebinds[j].replacement;
            }
        }
    }
}

static void rebind_image(struct rebinding rebinds[], size_t n,
                         const mach_header_t *hdr, intptr_t slide) {
    segment_command_t *seg;
    uintptr_t p = (uintptr_t)hdr;
    struct symtab_command *symtab = NULL;
    struct dysymtab_command *dysym = NULL;
    for (uintptr_t c = p + sizeof(mach_header_t);
         c < p + sizeof(mach_header_t) + hdr->sizeofcmds;
         c += seg->cmdsize) {
        seg = (segment_command_t *)c;
        if (seg->cmd == LC_SYMTAB) symtab = (void *)c;
        else if (seg->cmd == LC_DYSYMTAB) dysym = (void *)c;
    }
    if (!symtab || !dysym) return;
    nlist_t *syms = (nlist_t *)(slide + symtab->symoff);
    char *strs = (char *)(slide + symtab->stroff);
    uint32_t *ind = (uint32_t *)(slide + dysym->indirectsymoff);
    for (uintptr_t c = p + sizeof(mach_header_t);
         c < p + sizeof(mach_header_t) + hdr->sizeofcmds;
         c += seg->cmdsize) {
        seg = (segment_command_t *)c;
        if (seg->cmd != LC_SEGMENT_ARCH_DEPENDENT) continue;
        section_t *sect = (section_t *)((uintptr_t)seg + sizeof(segment_command_t));
        for (uint i = 0; i < seg->nsects; i++, sect++) {
            uint32_t t = sect->flags & SECTION_TYPE;
            if (t == S_LAZY_SYMBOL_POINTERS || t == S_NON_LAZY_SYMBOL_POINTERS)
                rebind_with_section(sect, slide, syms, strs, ind, rebinds, n);
        }
    }
}

int rebind_symbols(struct rebinding rebinds[], size_t n) {
    uint32_t cnt = _dyld_image_count();
    for (uint32_t i = 0; i < cnt; i++) {
        rebind_image(rebinds, n, (const mach_header_t *)_dyld_get_image_header(i),
                     _dyld_get_image_vmaddr_slide(i));
    }
    return 0;
}
