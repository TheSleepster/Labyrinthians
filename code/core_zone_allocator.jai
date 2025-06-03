/*
   NOTE(Sleepster): 
    I don't know if we should have both an arena allocator and a zone
    allocator. The two together  seem redundant, but at the same time they
    fill two completely different roles so I'm unsure.

    On one hand, the two being in the same program is fine since we
    are not memory limited. However, on the other hand this might turn
    into a "Why don't we just use the Zone Allocator everywhere, since
    we're specifically building this allocator just to solve the asset
    allocation problem". Idk, I guess we'll have to see if this makes
    sense down the line. The word "alloc" just scares me.



API DEFINITIONS:

za_init                :: (block_size) -> *Zone_Allocator;
za_alloc               :: (zone: *Zone_Allocator, size_init: u64, tag: Allocation_Tag) -> *void;
za_free                :: (zone: *Zone_Allocator, pointer: *void);
za_free_zone_tag       :: (zone: *Zone_Allocator, tag: Allocation_Tag);
za_free_zone_tag_range :: (zone: *Zone_Allocator, low_tag: Allocation_Tag, high_tag: Allocation_Tag);
za_deinit              :: (zone: **Zone_Allocator);

DEBUG:

za_print_block_list    :: (zone: *Zone_Allocator);
za_validate_block_list :: (zone: *Zone_Allocator);
*/

/////////////////
// TICKET MUTEX
/////////////////

Ticket_Mutex :: struct
{
    serving    : u32;
    next_ticket: u32;
};

tm_lock :: (mutex: *Ticket_Mutex) -> bool
{
    ticket_init     := mutex.next_ticket;
    success, ticket := interlocked_compare_exchange(*mutex.next_ticket, ticket_init, ticket_init + 1);
    if ticket == ticket_init
    {
        while ticket != mutex.serving
        {
        };
    }

    return success;
}

tm_unlock :: (mutex: *Ticket_Mutex)
{
    interlocked_increment(*mutex.serving);
}

////////////////////
// ZONE ALLOCATOR
////////////////////

MAX_MEMORY_FRAGMENTATION :: 524288;
DEBUG_ZONE_ID            :: 0x1d4a11;

Allocation_Tag :: enum
{
    // NOTE(Sleepster): Can be freed at any time...
    NONE;
    DYNAMIC;
    CACHED;

    UNPURGABLE;

    // NOTE(Sleepster): Manually freed 
    STATIC;
};

// NOTE(Sleepster): If user is null, the block currently lacks an owner. 
Zone_Memory_Block :: struct
{
    block_id      :  u64;
    is_allocated  :  bool;
    block_size    :  u64;
    allocation_tag:  Allocation_Tag;

    next_block    : *Zone_Memory_Block;
    prev_block    : *Zone_Memory_Block;
};

Zone_Allocator :: struct
{
    mutex          : Ticket_Mutex;
    
    total_allocated:  u64;
    memory_base    : *u8;
    block_list     :  Zone_Memory_Block;

    // NOTE(Sleepster): currently free block 
    cursor         : *Zone_Memory_Block;
};

za_init :: (block_size: u64) -> *Zone_Allocator
{
    result                := cast(*Zone_Allocator)os_allocate_memory(block_size);
    result.memory_base     = (cast(*u8)result + size_of(Zone_Allocator));
    result.total_allocated = block_size;

    block := cast(*Zone_Memory_Block)(result.memory_base);
    result.block_list.prev_block = block;
    result.block_list.next_block = result.block_list.prev_block;

    result.block_list.is_allocated   = true;
    result.block_list.allocation_tag = .STATIC;
    result.block_list.block_id       = DEBUG_ZONE_ID;
    result.cursor = block;

    block.next_block            = *result.block_list;
    block.prev_block            = block.next_block;
    block.next_block.prev_block = block;
    block.is_allocated          = false;
    block.block_size            = result.total_allocated - size_of(Zone_Allocator);
    block.block_id              = DEBUG_ZONE_ID;

    return result;
}

za_alloc :: (zone: *Zone_Allocator, size_init: u64, tag: Allocation_Tag) -> *void
{
    // NOTE(Sleepster): Allign to 16 bytes... 
    size := (size_init + 15) & ~15;
    size  = size + size_of(Zone_Memory_Block);

    base_block := zone.cursor;
    if !base_block.prev_block.is_allocated
    {
        base_block = base_block.prev_block;
    }

    block_cursor   := base_block;
    starting_block := base_block.prev_block;

    while base_block.is_allocated || base_block.block_size < size
    {
        if block_cursor == starting_block
        {
            log_error("Failed to allocate memory to the ZA, allocation size: %...\n", size);
            return null;
        }

        if block_cursor.is_allocated
        {
            if block_cursor.allocation_tag < .UNPURGABLE
            {
                // NOTE(Sleepster): Free this block... 
                base_block = base_block.prev_block;
                za_free(zone, cast(**void)*(cast(*u8)block_cursor + size_of(Zone_Memory_Block)));

                base_block   = base_block.next_block;
                block_cursor = base_block.next_block;
            }
            else
            {
                // NOTE(Sleepster): This block cannot be freed, go next 
                block_cursor = block_cursor.next_block;
                base_block   = block_cursor; 
            }
        }
        else
        {
            block_cursor = block_cursor.next_block;
        }
    }

    leftover_memory: u64 = base_block.block_size - size;
    if leftover_memory > MAX_MEMORY_FRAGMENTATION
    {
        new_block := cast(*Zone_Memory_Block)(cast(*u8)base_block + size);
        new_block.block_size     = leftover_memory;
        new_block.is_allocated   = false;
        new_block.allocation_tag = .NONE;
        new_block.prev_block     = base_block;
        new_block.next_block     = base_block.next_block;
        new_block.next_block.prev_block = new_block;
        new_block.block_id       = 0;

        base_block.next_block = new_block;
        base_block.block_size = size;
    }

    base_block.is_allocated   = true;
    base_block.allocation_tag = tag; 
    base_block.block_id       = DEBUG_ZONE_ID;
    zone.cursor               = base_block.next_block;

    log("[INFO]: Zone Allocated: '%' bytes...\n", size);
    return(cast(*u8)base_block + size_of(Zone_Memory_Block));
}

za_free :: (zone: *Zone_Allocator, pointer: **void)
{
    block := cast(*Zone_Memory_Block)(cast(*u8)pointer.* - size_of(Zone_Memory_Block)); 
    assert(block.block_id == DEBUG_ZONE_ID);

    block_size := block.block_size;
    block_tag  := block.allocation_tag;
    if block.is_allocated
    {
        block.is_allocated   =  false;
        block.allocation_tag = .NONE;
        block.block_id       = 0;

        other := block.prev_block;
        if !other.is_allocated
        {
            other.block_size += block.block_size;
            other.next_block  = block.next_block;
            other.next_block.prev_block = other;
            if block == zone.cursor
            {
                zone.cursor = other;
            }
            block = other;
        }

        other = block.next_block;
        if !other.is_allocated
        {
            block.block_size           += other.block_size;
            block.next_block            = other.next_block;
            block.next_block.prev_block = block;
            if other == zone.cursor
            {
                zone.cursor = block;
            }
        }

        pointer.* = null;
        log("[INFO]: Freed a zone block with the size of '%', had an allocation tag of: '%'...", block_size, block_tag);
    }
    else
    {
        log_error("Attempted to free a block that is not allocated...\n");
    }
}

za_free_zone_tag :: (zone: *Zone_Allocator, tag: Allocation_Tag)
{
    block := zone.block_list.next_block;
    while block != *zone.block_list
    {
        next_block := block.next_block;
        if block.is_allocated
        {
            if block.allocation_tag == tag
            {
                za_free(zone, cast(**void)*(cast(*u8)block + size_of(Zone_Memory_Block)));
            }
        }

        block = next_block;
    }
}

// NOTE(Sleepster): This might be really slow... 
za_free_zone_tag_range :: (zone: *Zone_Allocator, low_tag: Allocation_Tag, high_tag: Allocation_Tag)
{
    block := zone.block_list.next_block;
    while block != *zone.block_list
    {
        next_block := block.next_block;
        if block.is_allocated
        {
            if block.allocation_tag > low_tag && block.allocation_tag < high_tag
            {
                za_free_zone_tag(zone, block.allocation_tag);
            }
        }

        block = next_block;
    }
}

za_change_zone_tag :: (zone: *Zone_Allocator, pointer: *void, tag: Allocation_Tag)
{
    block := cast(*Zone_Memory_Block)(cast(*u8)pointer - size_of(Zone_Memory_Block));
    if block.block_id != DEBUG_ZONE_ID
    {
        log("[ERROR]: Attempted to change the tag of a block that is not valid...\n");
        return;
    }

    block.allocation_tag = tag; 
}

za_deinit :: (zone: **Zone_Allocator)
{
    log("[INFO]: Zone Memory Allocator of size: '%' has been deinited...\n", zone.*.total_allocated);
    os_deallocate_memory(zone, zone.*.total_allocated);
    zone.* = null;
}

za_print_block_list :: (zone: *Zone_Allocator)
{
    block := zone.block_list.next_block;
    print("Block List State:\n");
    while (block != *zone.block_list)
    {
        print("  Block at %: size=%, allocated=%, tag=%, id=%\n",
               block, block.block_size, block.is_allocated, block.allocation_tag, block.block_id);
        block = block.next_block;
    }
    print("  Cursor at %\n", zone.cursor);
}

za_validate_block_list :: (zone: *Zone_Allocator)
{
    block :=  zone.block_list.next_block;
    start :=  block;

    if block == *zone.block_list
    {
        log("[ERROR]: List za_block_list is empty...");
    }

    while true
    {
        assert(block.prev_block.next_block == block);
        assert(block.next_block.prev_block == block);

        block = block.next_block;
        if block == *zone.block_list
        {
            break;
        }
    }
    assert(block == *zone.block_list);
}
