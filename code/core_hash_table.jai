////////////////////////////////////////////
// NOTE(Sleepster): GENERIC HASH
////////////////////////////////////////////
C_Hash_Pair_Entry :: struct
{
    key   :  string;
    value : *void;
}

C_Hash_Table :: struct
{
    pairs         : []C_Hash_Pair_Entry;
    entry_counter : s32;
    max_entries   : s32;
}

c_hash_table_create :: (memory_arena: *Memory_Arena, max_entries: s64) -> C_Hash_Table
{
    result: C_Hash_Table = ---;
    result.max_entries    = xx max_entries;
    result.pairs          = c_arena_push_array(memory_arena, C_Hash_Pair_Entry, xx max_entries);
    result.entry_counter  = 0;

    return result;
}

c_hash_table_create_za :: (zone: *Zone_Allocator, max_entries: s64) -> C_Hash_Table
{
    result: C_Hash_Table = ---;
    result.max_entries    = xx max_entries;
    result.pairs          = za_alloc_array(zone, C_Hash_Pair_Entry, 512, .STATIC);
    result.entry_counter  = 0;

    return result;
}

c_hash_equate_index :: (hash_table: *C_Hash_Table, key: string) -> s64
{
    hash := 14695981039346656037;
    string_index: s32;
    for 0..key.count - 1
    {
        c := (key.data + string_index).*;
        string_index += 1;

        hash = hash ^ c;
        hash = hash * 1099511628211;
    }
    return (hash % hash_table.max_entries + hash_table.max_entries) % hash_table.max_entries;
}

c_hash_insert_pair :: (table: *C_Hash_Table, key: string, value: *void)
{
    hash_index := c_hash_equate_index(table, key);
    assert(hash_index >= 0);
    if table.pairs[hash_index].key != ""
    {
        if compare_strings(table.pairs[hash_index].key, key) == 0
        {
            table.pairs[hash_index].value = value;
            log("Value at index % in the hash has been updated...\n", hash_index);
            return;
        }
    }

    table.pairs[hash_index].key    = key;
    table.pairs[hash_index].value  = value;
    table.entry_counter           += 1;
}

c_hash_get_value :: (table: *C_Hash_Table, key: string) -> *void
{
    hash_index := c_hash_equate_index(table, key);
    assert(hash_index >= 0);
    if table.pairs[hash_index].key != ""
    {
        if compare_strings(table.pairs.data[hash_index].key, key) == 0
        {
            return table.pairs[hash_index].value;
        }
        else
        {
            return null;
        }
    }
    else
    {
        log("[ERROR]: hash table does not contain a valid string at index '%', which key '%' gave...\n", hash_index, key);
        return null;
    }
}

c_hash_remove_value_at_index :: inline (table: *C_Hash_Table, hash_index: s32)
{
    table.pairs[hash_index].value = null;
}

c_hash_remove_index :: inline (table: *C_Hash_Table, hash_index: s32)
{
    table.pairs[hash_index].value = null;
    table.pairs[hash_index].key   = "";
}

c_hash_clear_table :: inline (table: *C_Hash_Table)
{
    for index: 0..table.entry_counter - 1
    {
        table.pairs[index].key   = "";
        table.pairs[index].value = null;
    }
}
