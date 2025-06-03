/*
// NOTE(Sleepster): API DEFINITIONS
 
c_arena_init                            ::        (minimum_block_size: u64) -> Memory_Arena;
c_arena_init_from_base                  ::        (base: *void, capacity: u64) -> Memory_Arena;

c_arena_push_size                       ::        (arena: *Memory_Arena, size_init: s64, alignment: u32 = 4) -> *void;
c_arena_push_struct                     :: inline (arena: *Memory_Arena, $T: Type, alignment: u32 = 4) -> *T; 
c_arena_push_array                      :: inline (arena: *Memory_Arena, $T: Type, count: u32, alignment: u32 = 4) -> []T;
c_arena_arena_bootstrap_allocate_struct :: inline ($bootstrap: Type, offset: s64, minimum_block_size: u32 = 0) -> *bootstrap;

c_arena_begin_temporary_memory :: (arena: *Memory_Arena) -> Scratch_Arena;
c_arena_end_temporary_memory   :: (arena: *Memory_Arena)
c_arena_reset                  :: (arena: *Memory_Arena)

*/

Memory_Arena_Footer :: struct
{
    block_last_used    : u64;
    block_last_capacity: u64;
    block_last_base    : *u8;
};

Scratch_Arena :: struct
{
    parent_arena: *Memory_Arena;
    parent_base : *u8;

    parent_used :  u64;
};

Memory_Arena :: struct
{
    base                  : *u8;
    used                  :  u64;
    block_capacity        :  u64;
    minimum_block_size    :  u64;

    total_allocation_size :  u64;
    allocation_block_count:  u32;

    scratch_buffer_count  :  u32;
    is_growing_allocator  :  bool;
};

c_arena_init :: (minimum_block_size: u64, is_growing_allocator: bool = true) -> Memory_Arena
{
    result: Memory_Arena = ---;
    result.base                   = null;
    result.used                   = 0;
    result.block_capacity         = 0;
    result.minimum_block_size     = minimum_block_size;
    result.total_allocation_size  = 0;
    result.allocation_block_count = 0;
    result.scratch_buffer_count   = 0;
    result.is_growing_allocator   = is_growing_allocator;

    return result;
}

c_arena_init_from_base :: (base: *void, capacity: u64, is_growing_allocator: bool = true) -> Memory_Arena
{
    result: Memory_Arena;
    result.base                 = cast(*u8)base;
    result.block_capacity       = capacity;
    result.used                 = 0;
    result.is_growing_allocator = is_growing_allocator;

    return result;
}

get_alignment_offset :: (arena: *Memory_Arena, alignment: u32 = 4) -> u64
{
    offset: u32 = cast(u32)(arena.base + arena.used);
    alignment_mask := alignment - 1;

    alignment_offset: u64 = 0;
    if offset & alignment_mask
    {
        alignment_offset = alignment - (offset & alignment_mask);
    }
    return alignment_offset;
}

get_effective_allocation_size :: (arena: *Memory_Arena, allocation_size: u32, alignment_offset: u32 = 4) -> u32
{
    result := allocation_size;
    offset := get_alignment_offset(arena, alignment_offset);
    
    result += xx offset;
    return result;
}

get_footer :: inline (arena: *Memory_Arena) -> *Memory_Arena_Footer
{
    result := cast(*Memory_Arena_Footer)(arena.base + arena.block_capacity);
    return result;
}

c_arena_push_size :: (arena: *Memory_Arena, size_init: s64, alignment: u32 = 4) -> *void
{
    result: *void;
    
    size := get_effective_allocation_size(arena, xx size_init, alignment);
    if ((arena.used + size) > arena.block_capacity) && arena.is_growing_allocator
    {
        if !arena.minimum_block_size
        {
            arena.minimum_block_size = cast(u32)MB(1);
        }

        save: Memory_Arena_Footer;
        save.block_last_base     = arena.base;
        save.block_last_capacity = arena.block_capacity;
        save.block_last_used     = arena.used;
        
        size = xx size_init;
        new_block_size := ifx size > (arena.minimum_block_size + size_of(Memory_Arena_Footer)) then size else arena.minimum_block_size; 

        arena.block_capacity            = new_block_size - size_of(Memory_Arena_Footer);
        arena.base                      = os_allocate_memory(new_block_size);
        arena.used                      = 0;
        arena.allocation_block_count   += 1;
        arena.total_allocation_size    += new_block_size;

        footer  := get_footer(arena);
        footer.* = save;
    }
    else if !arena.is_growing_allocator 
    {
        log_error("[ERROR]: Arena is full, we are returning null pointer...\n");
        assert(false);

        return null;
    }
    assert((arena.used + size) <= arena.block_capacity);
    assert(size >= size_init);

    alignment_offset := get_alignment_offset(arena, alignment);
    result      = (arena.base + arena.used + alignment_offset);
    arena.used += size;
    return result;
}

c_arena_bootstrap_allocate_struct :: inline ($bootstrap: Type, offset: s64, minimum_block_size: u32 = 0) -> *bootstrap
{
    bootstrap_arena: Memory_Arena;
    bootstrap_arena.minimum_block_size = minimum_block_size;
    bootstrap_struct := push_struct(*bootstrap_arena, bootstrap);

    (cast(*Memory_Arena)(bootstrap_struct + offset)).* = bootstrap_arena;

    return bootstrap_struct;
}

c_arena_push_struct :: inline (arena: *Memory_Arena, $T: Type, alignment: u32 = 4) -> *T
{
    result := c_arena_push_size(arena, size_of(T), alignment);
    return result;
}

c_arena_push_array :: inline (arena: *Memory_Arena, $T: Type, count: u32, alignment: u32 = 4) -> []T
{
    result: []T;
    result.data  = c_arena_push_size(arena, size_of(T) * count, alignment);
    result.count = count;

    return result;
}

c_arena_begin_temporary_memory :: (arena : *Memory_Arena) -> Scratch_Arena
{
    result: Scratch_Arena;
    result.parent_arena = arena;
    result.parent_base  = arena.base;
    result.parent_used  = arena.used;

    arena.scratch_buffer_count += 1;
    return result;
}

free_last_block :: inline (arena: *Memory_Arena)
{
    free          := cast(*void)arena.base; 
    old_capacity  := arena.block_capacity;

    memory_footer       := get_footer(arena);
    arena.base           = memory_footer.block_last_base;
    arena.used           = memory_footer.block_last_used;
    arena.block_capacity = memory_footer.block_last_capacity;

    arena.total_allocation_size -= old_capacity;
    arena.allocation_block_count -= 1;

    os_deallocate_memory(free, old_capacity);
}

c_arena_end_temporary_memory :: (scratch: *Scratch_Arena)
{
    arena := scratch.parent_arena;
    while arena.base != scratch.parent_base
    {
        free_last_block(arena);
        log("[INFO]: [end_temporary_block]: Block freed...\n");
    }

    assert(arena.used >= scratch.parent_used);

    arena.used = scratch.parent_used;
    arena.base = scratch.parent_base;
    arena.scratch_buffer_count  -= 1;
}

c_arena_reset :: (arena: *Memory_Arena)
{
    while arena.allocation_block_count > 1
    {
        free_last_block(arena);
    }
    // TODO(Sleepster): This may be slower than I think, but memsetting HAS to be faster than that of releasing
    // the whole page to the OS and immediately allocing it next time... Right?
    memset(arena.base, 0, xx arena.used);

    arena.used                 = 0;
    arena.scratch_buffer_count = 0;
}
