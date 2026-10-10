// fishhook.c - rebind symbols
#include "fishhook.h"

#include <assert.h>
#include <dlfcn.h>
#include <string.h>
#include <sys/param.h>
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

typedef struct {
    char *symname;
    uintptr_t impl;
} pending_rebinding_t;

static bool is_rebase_location(uint8_t *location, const segment_command_t *seg,
                                section_t *sect, uint32_t flags) {
    return ((uintptr_t)location >= (seg->vmaddr + sect->addr) &&
            (uintptr_t)location < (seg->vmaddr + sect->addr + sect->size) &&
            ((flags & SECTION_TYPE) == S_LAZY_SYMBOL_POINTERS ||
             (flags & SECTION_TYPE) == S_NON_LAZY_SYMBOL_POINTERS ||
             (flags & SECTION_TYPE) == S_MOD_INIT_FUNC_POINTERS ||
             (flags & SECTION_TYPE) == S_INIT_FUNC_POINTERS));
}

static void preinitialize() {}

static void perform_rebinding_with_section(section_t *section,
                                            uintptr_t slide,
                                            nlist_t *symtab,
                                            char *strtab,
                                            uint32_t *indirect_symtab,
                                            struct rebinding *rebindings,
                                            size_t rebindings_nel) {
    uintptr_t *symbol = (uintptr_t *)(slide + section->addr);
    uint32_t *indirect = (uint32_t *)(indirect_symtab + section->reserved1);
    uint32_t count = section->size / sizeof(uintptr_t);
    for (uint32_t idx = 0; idx < count; idx++) {
        uint32_t sym_idx = indirect[idx];
        if (sym_idx & INDIRECT_SYMBOL_LOCAL) continue;
        if (sym_idx & INDIRECT_SYMBOL_ABS) continue;
        char *sym_name = strtab + symtab[sym_idx].n_un.n_strx;
        for (size_t i = 0; i < rebindings_nel; i++) {
            if (strcmp(sym_name, rebindings[i].name) == 0) {
                if (rebindings[i].replaced) {
                    *rebindings[i].replaced = (void *)symbol[idx];
                }
                symbol[idx] = (uintptr_t)rebindings[i].replacement;
            }
        }
    }
}

static void rebind_symbols_for_image(struct rebinding rebindings[], size_t rebindings_nel,
                                      const mach_header_t *header,
                                      intptr_t slide) {
    segment_command_t *cur_seg_cmd;
    uintptr_t cur = (uintptr_t)header;
    struct symtab_command *symtab = NULL;
    struct dysymtab_command *dysymtab = NULL;

    for (uintptr_t cmd = cur + sizeof(mach_header_t);
         cmd < cur + sizeof(mach_header_t) + header->sizeofcmds;
         cmd += cur_seg_cmd->cmdsize) {
        cur_seg_cmd = (segment_command_t *)cmd;
        if (cur_seg_cmd->cmd == LC_SYMTAB) {
            symtab = (struct symtab_command *)cmd;
        } else if (cur_seg_cmd->cmd == LC_DYSYMTAB) {
            dysymtab = (struct dysymtab_command *)cmd;
        }
    }
    if (!symtab || !dysymtab) return;

    nlist_t *symtab_symbols = (nlist_t *)(slide + symtab->symoff);
    char *strtab = (char *)(slide + symtab->stroff);
    uint32_t *indirect = (uint32_t *)(slide + dysymtab->indirectsymoff);

    for (uintptr_t cmd = cur + sizeof(mach_header_t);
         cmd < cur + sizeof(mach_header_t) + header->sizeofcmds;
         cmd += cur_seg_cmd->cmdsize) {
        cur_seg_cmd = (segment_command_t *)cmd;
        if (cur_seg_cmd->cmd != LC_SEGMENT_ARCH_DEPENDENT) continue;
        if (strncmp(cur_seg_cmd->segname, "__TEXT", 16) != 0 &&
            strncmp(cur_seg_cmd->segname, "__DATA", 16) != 0 &&
            strncmp(cur_seg_cmd->segname, "__DATA_CONST", 16) != 0 &&
            strncmp(cur_seg_cmd->segname, "__LINKEDIT", 16) != 0) continue;
        section_t *sect = (section_t *)((uintptr_t)cur_seg_cmd + sizeof(segment_command_t));
        for (uint i = 0; i < cur_seg_cmd->nsects; i++, sect++) {
            uint32_t type = sect->flags & SECTION_TYPE;
            if (type == S_LAZY_SYMBOL_POINTERS || type == S_NON_LAZY_SYMBOL_POINTERS) {
                perform_rebinding_with_section(sect, slide, symtab_symbols, strtab,
                                                indirect, rebindings, rebindings_nel);
            }
        }
    }
}

int rebind_symbols(struct rebinding rebindings[], size_t rebindings_nel) {
    uint32_t count = _dyld_image_count();
    for (uint32_t i = 0; i < count; i++) {
        const mach_header_t *header = (const mach_header_t *)_dyld_get_image_header(i);
        intptr_t slide = _dyld_get_image_vmaddr_slide(i);
        rebind_symbols_for_image(rebindings, rebindings_nel, header, slide);
    }
    return 0;
}

int rebind_symbols_image(void *header, size_t size,
                          struct rebinding rebindings[], size_t rebindings_nel) {
    (void)size;
    rebind_symbols_for_image(rebindings, rebindings_nel, (const mach_header_t *)header, 0);
    return 0;
}
