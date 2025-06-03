#import "POSIX";
#load "../misc/deps/generated_linux_networking.jai";

Socket :: s32;

//////////////////////
// MEMORY ALLOCATION
//////////////////////

os_allocate_memory :: inline (size: u64) -> *void
{
    data := mmap(null, size, PROT_READ|PROT_WRITE, MAP_PRIVATE|MAP_ANONYMOUS, -1, 0);
    //log("[INFO]: mmap called with a size of: %mb\n", cast(float32)(size / 1048576.0));
    return data;
}

os_deallocate_memory :: inline (data: *void, size: u64)
{
    munmap(data, size);
}

//////////////
// THREADING
//////////////

os_get_cpu_count :: inline () -> s64 
{
    return sysconf(._SC_NPROCESSORS_ONLN);
}

os_create_semaphore :: (initial_thread_count : s32,
                         max_thread_count     : s32,
                         semaphore_name       : string = "") -> *void
{
    result: *sem_t = New(sem_t);
    
    if semaphore_name != ""
    {
        result = sem_open(temp_c_string(semaphore_name), O_CREAT, S_IRUSR | S_IWUSR, 0);
        if result == null 
        {
            perror("[ERROR]: sem_open failed...\n");
            assert(false);
        }
    }
    else
    {
        success := sem_init(result, 0, 0);
        if success != 0
        {
            perror("[ERROR]: sem_init failed...\n");
            assert(false);
        }
    }

    return result;
}

os_release_semaphore :: inline (semaphore: *void)
{
    sem_destroy(semaphore);
    free(semaphore);
}

os_thread_wait :: inline (semaphore: *void, duration_ms: u32)
{
    if duration_ms == 0
    {
        sem_wait(semaphore);
        return;
    }

    time_data: timespec;

    // NOTE(Sleepster): for some reason the compiler wouldn't find this otherwise 
    CLOCK_MONOTONIC :: 1;
    if clock_gettime(CLOCK_MONOTONIC, *time_data) == -1
    {
        perror("[ERROR]: Failure to get time for 'timed_wait'...\n");
        assert(false);

        sem_wait(semaphore);
        return;
    }

    time_data.tv_sec  += duration_ms / 1000;
    time_data.tv_nsec += (duration_ms % 1000) * 1000000;
    
    sem_timedwait(semaphore, *time_data);
}

os_thread_start :: (semaphore: *void, to_release: s32) -> s32
{
    started: s32;
    for thread_index: 0..to_release - 1
    {
        success := sem_post(semaphore);
        if success != 0
        {
            perror("[ERROR]: Failure to call 'sem_post'...\n");
            assert(false);
        }
        started += 1;
    }

    if started > to_release
    {
        log("[WARNING]: More threads awoken than are valid on the machine...\n");
    }

    return started;
}

os_create_thread :: (user_data    : *void,
                      thread_proc  :  (data: *void) -> s32 #c_call,
                      stack_size   :  s64,
                      close_handle :  bool = true) -> OS_Thread 
{
    result             : OS_Thread;
    linux_thread_handle: *pthread_t = New(pthread_t);

    if stack_size != 0
    {
        thread_attributes  : pthread_attr_t;
        if pthread_attr_init(*thread_attributes) != 0
        {
            perror("[ERROR]: Failed to initialize Linux thread attributes...\n");
            pthread_attr_destroy(*thread_attributes);
            return result;
        }

        if pthread_attr_setstacksize(*thread_attributes, xx stack_size) != 0
        {
            perror("[ERROR]:  failed to set the pthread_attr stack size...\n");
            pthread_attr_destroy(*thread_attributes);
            return result;
        }

        error := pthread_create(linux_thread_handle, *thread_attributes, xx thread_proc, user_data);
        if error != 0
        {
            perror("[ERROR]: Cannot 'pthread_create' failed...\n");
            pthread_attr_destroy(*thread_attributes);
            assert(false);

            return result;
        }
        pthread_attr_destroy(*thread_attributes);
    }
    else
    {
        error := pthread_create(linux_thread_handle, null, xx thread_proc, user_data);
        if error != 0
        {
            perror("[ERROR]: Cannot 'pthread_create' failed...\n");
            assert(false);

            return result;
        }
    }

    // NOTE(Sleepster): Couldn't be bothered to find a simple way to keep track of the thread id on Linux... 
    result.thread_handle = linux_thread_handle;
    result.thread_id     = -1;
    if close_handle
    {
        error := pthread_detach(linux_thread_handle.*);
        if error != 0
        {
            perror("[ERROR]: Failure to close the linux thread handle...\n");
        }
        
        free(linux_thread_handle);
    }

    return result;
}

os_close_thread_handle :: (thread_data: OS_Thread) -> bool
{
    linux_thread_handle: u64 = (cast(*u64)thread_data.thread_handle).*;
    
    error := pthread_detach(linux_thread_handle);
    if error != 0
    {
        perror("[ERROR]: Failure to close the linux thread handle...\n");
        return false;
    }
    
    free(thread_data.thread_handle);
    return true;
}

///////////////
// NETWORKING
///////////////

// NOTE(Sleepster): THIS IS UDP ONLY!!!!!  

os_socket_get_last_error :: inline () -> OS_Error_Code
{
    return errno();
}

os_init_socket_system :: inline () -> bool
{
    return true;
}

os_socket_create :: (ip_type: Socket_IP_Type, protocol: Socket_Protocol) -> OS_Socket
{
    result: OS_Socket;
    
    socket_handle := socket(AF_INET, .SOCK_DGRAM, .IPPROTO_UDP);
    if socket_handle != -1
    {
        result.handle   = socket_handle;
        result.ip_type  = ip_type;
        result.protocol = protocol;
    }
    else
    {
        perror("[ERROR]: Failed to create the UDP socket...");
    }

    return result;
}

os_socket_bind :: (socket: *OS_Socket, port: u16) -> bool
{
    result: bool;
    if port > 0
    {
        port = htons(port);
    }
    
    socket_address: sockaddr_in;
    socket_address.sin_family      = AF_INET;
    socket_address.sin_addr.s_addr = INADDR_ANY;
    socket_address.sin_port        = port;

    error := bind(socket.handle, cast(*sockaddr)*socket_address, size_of(sockaddr_in));
    if error != -1
    {
        socket.port             = ntohs(port);
        socket.is_bound_to_addr = true;
    }
    else
    {
        perror("[ERROR]: Failed to bind the socket...\n");
    }

    result = (error != -1);
    return result;
}

os_socket_set_nonblocking :: (socket: *OS_Socket) -> bool
{
    result: bool;

    should_block: s32 = 1;
    error := fcntl(socket.handle, F_SETFL, O_NONBLOCK, should_block);
    if error != -1
    {
        socket.is_non_blocking = true;
    }
    else
    {
        perror("[ERROR]: Failed to set the socket to be nonblocking...\n");
    }

    result = (error != -1);
    return result;
}

os_socket_send_data :: (socket: *OS_Socket, buffer: string, address: string, port: u16) -> s64
{
    c_address   := temp_c_string(address);
    net_address := inet_addr(c_address);
   
    socket_address: sockaddr_in;
    socket_address.sin_family      = AF_INET;
    socket_address.sin_addr.s_addr = net_address;
    socket_address.sin_port        = htons(port);

    bytes_sent := sendto(socket.handle,
                         buffer.data,
                         xx(buffer.count * size_of(u8)),
                         0,
                         cast(*sockaddr)*socket_address,
                         size_of(sockaddr_in));
    return bytes_sent;
}

// TODO(Sleepster): get rid of alloc 
os_socket_read_from :: (socket: *OS_Socket) -> string, s64
{
    buffer: string;
    buffer.data  = alloc(size_of(u8) * 512);
    buffer.count = 512;

    from: sockaddr_in;
    from_size: u32 = size_of(sockaddr_in);

    bytes_read := recvfrom(socket.handle,
                           buffer.data,
                           xx(buffer.count * size_of(u8)),
                           0,
                           cast(*sockaddr)*from,
                           *from_size);
    buffer.count = bytes_read;
    return buffer, bytes_read;
}

//////////////////
// DLL RELOADING
//////////////////

// NOTE(Sleepster): Error handling is left to the caller... 
os_load_dynamic_library :: (filepath: string) -> OS_Dynamic_Library
{
    result: OS_Dynamic_Library;
    result.module_path = filepath;
    result.last_mod_time, result.last_mod_size = file_modtime_and_size(filepath);
    
    c_filepath := temp_c_string(filepath);
    result.module_handle = dlopen(c_filepath, RTLD_LAZY);
    if result.module_handle != null
    {
        result.is_valid = true;
    }

    return result;
}

os_unload_dynamic_library :: (library: *OS_Dynamic_Library)
{
    assert(library.module_handle != null);
    dlclose(library.module_handle);

    library.module_handle = null;
    library.last_mod_time = .{};
    library.last_mod_size = 0;
    library.is_valid = false;
}

os_get_proc_address :: (libary: *OS_Dynamic_Library, proc_name: string) -> *void
{
    result: *void = null;
    proc_name_c_str := temp_c_string(proc_name);
    result = dlsym(libary.module_handle, proc_name_c_str);
    assert(result != null);

    return result;
}

os_exit_process :: ()
{
    exit(0);
}
