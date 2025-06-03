#import "Windows";
#load "../misc/deps/generated_windows_networking.jai";

#scope_file
System :: #import "System";
#scope_export

Socket :: SOCKET;
WINSOCK_VERSION: u16 : 0x0202;
FIONBIO :: #run IOW(#char "f", 126, u32);

//////////////////////
// MEMORY ALLOCATION
//////////////////////

os_allocate_memory :: inline (size: u64) -> *void
{
    data := VirtualAlloc(null, xx size, MEM_COMMIT|MEM_RESERVE, PAGE_READWRITE);
    return data;
}

os_deallocate_memory :: inline (data: *void, size: u64)
{
    VirtualFree(data, 0, MEM_RELEASE);
}


//////////////
// THREADING
//////////////

os_get_cpu_count :: inline () -> s64 
{
    // NOTE(Sleepster): Windows is bad at thread switching without this 
    SetProcessDPIAware();
    timeBeginPeriod(1);

    system_info: SYSTEM_INFO;
    GetSystemInfo(*system_info);

    return system_info.dwNumberOfProcessors;
}

os_create_semaphore :: inline (initial_thread_count: s32, max_thread_count: s32, semaphore_name: string = "") -> *void
{
    assert(initial_thread_count <= max_thread_count);

    semaphore := CreateSemaphoreA(null, initial_thread_count, max_thread_count, temp_c_string(semaphore_name));
    if semaphore == null
    {
        log("[ERROR]: Failed to acquire the Windows platform Semaphore Object...\n");
        assert(false);

        semaphore = null;
    }
    
    return semaphore;
}

os_release_semaphore :: inline (semaphore: *void)
{
    CloseHandle(semaphore);
}

os_thread_wait :: inline (semaphore: *void, duration_ms: u32)
{
    if duration_ms == 0 duration_ms = INFINITE;
    WaitForSingleObject(semaphore, INFINITE);
}

os_thread_start :: (semaphore: *void, to_release: s32) -> s32
{
    threads_released: s32;
    W_success: BOOL;

    W_success = ReleaseSemaphore(semaphore, to_release, *threads_released);
    if W_success == 0
    {
        log("[ERROR]: Failure to release '%' threads on the Windows Semaphore...\n", to_release);
        assert(false);

        threads_released = 0;
    }

    return threads_released;
}

os_create_thread :: inline (user_data     : *void,
                            thread_proc   : (data: *void) -> s32 #c_call,
                            stack_size    :  s64,
                            close_handle  : bool = true) -> OS_Thread
{
    result: OS_Thread;
    
    assert(stack_size >= 0);
    result.thread_handle = CreateThread(null, stack_size, cast(*void)thread_proc, user_data, 0, *result.thread_id);
    if result.thread_handle != null
    {
        if close_handle
        {
            CloseHandle(result.thread_handle);
        }
    }
    else
    {
        log("[ERROR]: CreateThread (Windows) failed...\n");
        assert(false);

        result = .{};
    }

    return result;
}

os_close_thread_handle :: (thread_data: OS_Thread) -> bool
{
    result := CloseHandle(thread_data.thread_handle);
    if result == 0
    {
        log("[ERROR]: Failed to close thread handle...\n");
        assert(false);

        return false;
    }
    return true;
}


///////////////
// NETWORKING
///////////////

// NOTE(Sleepster): THIS IS UDP ONLY AND IPv4 ONLY!!!!!  
IOW :: (x: u8, y: u8, $T: Type) -> s32
{
    return (IOC_IN|((cast(s32)size_of(T)&IOCPARM_MASK)<<16)|((cast(u16)x)<<8)|(y));
}


os_socket_get_last_error :: inline () -> OS_Error_Code
{
    return WSAGetLastError();
}

os_init_socket_system :: () -> bool
{
    wsa_data: WSADATA;
    error := WSAStartup(WINSOCK_VERSION, *wsa_data);
    if error != 0
    {
        log_error("Could not initialize Winsock: % %", error, System.get_error_string(cast (OS_Error_Code)error));
        return false;
    }

    return true;
}

os_socket_create :: (ip_type: Socket_IP_Type, protocol: Socket_Protocol) -> OS_Socket
{
    result: OS_Socket;
    
    socket_handle := socket(AF_INET, .SOCK_DGRAM, .IPPROTO_UDP);
    if socket_handle != INVALID_SOCKET
    {
        result.handle   = socket_handle;
        result.ip_type  = ip_type;
        result.protocol = protocol;
    }
    else
    {
        log("[ERROR]: Failed to create the UDP socket...");
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
    socket_address.sin_family           = AF_INET;
    socket_address.sin_addr.S_un.S_addr = INADDR_ANY;
    socket_address.sin_port             = port;

    error := bind(socket.handle, cast(*sockaddr)*socket_address, size_of(sockaddr_in));
    if error != SOCKET_ERROR 
    {
        socket.port             = ntohs(port);
        socket.is_bound_to_addr = true;
    }
    else
    {
        log("[ERROR]: Failed to bind the socket...\n");
    }

    result = (error != -1);
    return result;
}

os_socket_set_nonblocking :: (socket: *OS_Socket) -> bool
{
    result: bool;

    should_block: u32 = 1;
    error := ioctlsocket(socket.handle, FIONBIO, *should_block);
    if error == 0 
    {
        socket.is_non_blocking = true;
    }
    else
    {
        log("[ERROR]: Failed to set the socket to be nonblocking...\n");
    }

    result = (error != -1);
    return result;
}

os_socket_send_data :: (socket: *OS_Socket, buffer: string, address: string, port: u16) -> s64
{
    c_address   := temp_c_string(address);
    net_address := inet_addr(c_address);
    
    socket_address: sockaddr_in;
    socket_address.sin_family           = AF_INET;
    socket_address.sin_addr.S_un.S_addr = net_address;
    socket_address.sin_port             = htons(port);

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
    from_size: s32 = size_of(sockaddr_in);

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
    result.module_handle = LoadLibraryA(c_filepath);
    if result.module_handle != null
    {
        result.is_valid = true;
    }

    return result;
}

os_unload_dynamic_library :: (library: *OS_Dynamic_Library)
{
    assert(library.module_handle != null);
    FreeLibrary(library.module_handle);

    library.module_handle = null;
    library.last_mod_time = .{};
    library.last_mod_size = 0;
    library.is_valid = false;
}

os_get_proc_address :: (libary: *OS_Dynamic_Library, proc_name: string) -> *void
{
    result: *void = null;
    proc_name_c_str := temp_c_string(proc_name);
    result = GetProcAddress(libary.module_handle, proc_name_c_str);
    if result == null
    {
        error := GetLastError();
        x := 0;
    }
    assert(result != null);

    return result;
}

os_exit_process :: ()
{
    ExitProcess(0);
}
