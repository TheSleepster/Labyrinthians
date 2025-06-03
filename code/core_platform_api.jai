#if OS == .WINDOWS
{
    #load "os_windows.jai";
}

#if OS == .LINUX
{
    #load "os_linux.jai";
}
#if OS == .MACOS
{
    #assert false "MacOSX is not a supported OS...\n";
}

/*
// NOTE(Sleepster): OS API definitions 

// TODO(Sleepster): os_bootstrap_allocate_memory();  ??? maybe in the future

os_allocate_memory     :: inline (size: u64) -> *void;
os_deallocate_memory   :: inline (data: *void, size: u64)

os_get_cpu_count       :: inline () -> s64;
os_create_semaphore    :: inline (initial_thread_count: s32, max_thread_count: s32, semaphore_name: string = "");
os_release_semaphore   :: inline (semaphore: *void);
os_thread_wait         :: inline ();
os_create_thread       :: inline (user_data)
os_thread_start        ::        (semaphore: *void, to_release: s32) -> s32;
os_close_thread_handle ::        (thread_data: OS_Thread) -> bool;

os_socket_get_last_error  :: inline () -> OS_Error_Code;
os_init_socket_system     ::        () -> bool;
os_socket_create          ::        (ip_type: Socket_IP_Type, protocol: Socket_Protocol) -> OS_Socket;
os_socket_bind            ::        (socket: OS_Socket, port: u16) -> bool;
os_socket_set_nonblocking ::        (socket: *OS_Socket) -> bool;
os_socket_send_data       ::        (socket: *OS_Socket, buffer: string, address: string, port: u16);
os_socket_read_from       ::        (socket: *OS_Socket) -> string, s64;

os_load_dynamic_library   ::        (filepath: string) -> OS_Dynamic_Libarary;
os_unload_dynamic_library ::        (library: *OS_Dynamic_Libarary);
os_get_proc_address       ::        (library: *OS_Dynamic_Libarary, proc_name: string) -> *void;
os_exit_process           ::        ();


*/

interlocked_compare_exchange :: compare_and_swap;
interlocked_add              :: atomic_add;
interlocked_increment        :: atomic_increment;
interlocked_decrement        :: atomic_decrement;
interlocked_and              :: atomic_and;
interlocked_or               :: atomic_or;
interlocked_xor              :: atomic_xor;

////////////////////
// THREADING STUFF
////////////////////

OS_Thread :: struct
{
    thread_handle: *void;
    thread_id    :  s32;
};

OS_Work_Queue_Entry :: struct
{
    user_data: *void;
    callback : (user_data: *void);
    is_valid :  bool;
};

OS_Work_Queue :: struct
{
    semaphore          : *void;
    threads_awake      :  s32;
    system_thread_count:  s32;
    
    entries_completed  :  u64;
    total_entries      :  u64;
    entries            : [256]OS_Work_Queue_Entry;
};

os_add_work_queue_entry :: (queue: *OS_Work_Queue, callback: (user_data: *void), user_data: *void)
{
    new_entry := *queue.entries[queue.total_entries % queue.entries.count];
    new_entry.user_data = user_data;
    new_entry.callback  = callback;
    new_entry.is_valid  = true;

    interlocked_increment(*queue.total_entries);
    if queue.threads_awake < queue.system_thread_count
    {
        os_thread_start(queue.semaphore, 1);
        queue.threads_awake += 1;
    }
}

os_reset_work_queue :: (queue: *OS_Work_Queue)
{
    queue.entries_completed = 0;
    queue.total_entries     = 0;
    for *entry: queue.entries
    {
        entry.* = .{};
    }
}

///////////////
// NETWORKING
///////////////

Socket_Protocol :: enum
{
    DGRAM;
    STREAM;
    SEQPACKET;
};

Socket_IP_Type :: enum
{
    IPv4;
    IPv6;
};

OS_Socket :: struct
{
    handle          : Socket;
    ip_type         : Socket_IP_Type;
    protocol        : Socket_Protocol; 
    port            : u16;

    is_bound_to_addr: bool;
    is_non_blocking : bool;
};

//////////////////
// DLL RELOADING
//////////////////

OS_Dynamic_Library :: struct
{
    module_handle: *void;
    module_path  :  string;
    last_mod_time:  Apollo_Time;
    last_mod_size:  s64;

    is_valid     :  bool;
};
