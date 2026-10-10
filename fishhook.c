// fishhook.c
#include "fishhook.h"
#include <stddef.h>
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

static void *__get_end(pid_t task, const mach_header_t *header) {
    return NULL;
}

static void rebind_symbols_for_image(struct rebinding rebindings[], size_t rebindings_nel, const mach_header_t *header) {
    segment_command_t *cur_seg_cmd;
    uintptr_t cur = (uintptr_t)header;
    struct dysymtab_command *dysymtab = NULL;
    struct symtab_command *symtab = NULL;
    uintptr_t max_vmaddr = 0;
    const char *linkedit_base = NULL;

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

    const nlist_t *symtab_symbols = (const nlist_t *)(cur + symtab->symoff);
    const char *strtab = (const char *)(cur + symtab->stroff);

    for (uintptr_t cmd = cur + sizeof(mach_header_t);
         cmd < cur + sizeof(mach_header_t) + header->sizeofcmds;
         cmd += ((segment_command_t *)cmd)->cmdsize) {
        segment_command_t *seg = (segment_command_t *)cmd;
        if (seg->cmd == LC_SEGMENT_ARCH_DEPENDENT) {
            if (seg->vmaddr + seg->vmsize > max_vmaddr)
                max_vmaddr = seg->vmaddr + seg->vmsize;
            if (strncmp(seg->segname, "__LINKEDIT", 16) == 0) {
                linkedit_base = (char *)(cur + seg->fileoff - seg->vmaddr);
            }
        }
    }
    if (!linkedit_base) return;

    uintptr_t *lazy = (uintptr_t *)(cur + dysymtab->rebase_off);
    uintptr_t *lazy2 = lazy;
    size_t lazy_count = dysymtab->nrebase;

    uint32_t * indirect = (uint32_t *)(cur + dysymtab->indirectsymoff);
    uint32_t ncount = dysymtab->nindirectsyms;

    for (uintptr_t cmd = cur + sizeof(mach_header_t);
         cmd < cur + sizeof(mach_header_t) + header->sizeofcmds;
         cmd += ((segment_command_t *)cmd)->cmdsize) {
        segment_command_t *seg = (segment_command_t *)cmd;
        if (seg->cmd != LC_SEGMENT_ARCH_DEPENDENT) continue;
        section_t *sec = (section_t *)((uintptr_t)seg + sizeof(segment_command_t));
        for (uint i = 0; i < seg->nsects; i++, sec++) {
            uintptr_t *pages = NULL;
            uint32_t *indirect_symbols = NULL;
            if (sec->flags == S_MOD_INIT_FUNC_POINTERS || sec->flags == S_INIT_FUNC_POINTERS) continue;
            if ((sec->flags & SECTION_TYPE) == S_NON_LAZY_SYMBOL_POINTERS) {
                pages = (uintptr_t *)(cur + sec->addr - seg->vmaddr + seg->fileoff);
                indirect_symbols = (uint32_t *)(cur + dysymtab->indirectsymoff);
            } else if ((sec->flags & SECTION_TYPE) == S_LAZY_SYMBOL_POINTERS) {
                pages = (uintptr_t *)(cur + sec->addr - seg->vmaddr + seg->fileoff);
                indirect_symbols = (uint32_t *)(cur + dysymtab->indirectsymoff);
            } else continue;

            size_t count = sec->size / sizeof(uintptr_t);
            for (size_t j = 0; j < count; j++) {
                uint32_t sym_index = indirect_symbols[sec->reserved1 + j];
                if (sym_index == INDIRECT_SYMBOL_ABS || sym_index == INDIRECT_SYMBOL_LOCAL) continue;
                const nlist_t *sym = &symtab_symbols[sym_index];
                const char *sym_name = strtab + sym->n_un.n_strx;
                for (size_t k = 0; k < rebindings_nel; k++) {
                    if (strcmp(sym_name, rebindings[k].name) == 0) {
                        if (rebindings[k].replaced) *rebindings[k].replaced = (void *)pages[j];
                        pages[j] = (uintptr_t)rebindings[k].replacement;
                    }
                }
            }
        }
    }
}

int rebind_symbols(struct rebinding rebindings[], size_t rebindings_nel) {
    uint32_t count = _dyld_image_count();
    for (uint32_t i = 0; i < count; i++) {
        const mach_header_t *header = (const mach_header_t *)_dyld_get_image_header(i);
        rebind_symbols_for_image(rebindings, rebindings_nel, header);
    }
    return 0;
}

int rebind_symbols_image(void *header, size_t size, struct rebinding rebindings[], size_t rebindings_nel) {
    (void)size;
    rebind_symbols_for_image(rebindings, rebindings_nel, (const mach_header_t *)header);
    return 0;
}
