D_Profile_Timer :: struct
{
    // NOTE(Sleepster): SDL_GetPerformanceCounter
    end_counter          : u64;
    last_counter         : u64;
    delta_counter        : u64;
    time_in_ms           : float64;

    // NOTE(Sleepster): rdtsc 
    end_tsc              : u64;
    last_tsc             : u64;
    delta_tsc            : u64;
    
    megacycle_counter    : float64;
    label                : string;
    location             : Source_Code_Location;
};

d_get_new_timer :: () -> *D_Profile_Timer
{
    performance_count_frequency = SDL_GetPerformanceFrequency();

    timer := *debug_timers[active_timer_counter];
    active_timer_counter += 1;

    return timer;
}

d_start_profile_timer :: (timer: *D_Profile_Timer)
{
    timer.last_counter = SDL_GetPerformanceCounter();
    timer.last_tsc     = rdtsc();
}

d_end_profile_timer :: (timer: *D_Profile_Timer)
{
    timer.end_tsc           = rdtsc();
    timer.delta_tsc         = timer.end_tsc - timer.last_tsc;
    timer.megacycle_counter = cast(float32)timer.delta_tsc / (1000.0 * 1000.0);

    timer.end_counter     = SDL_GetPerformanceCounter();
    timer.delta_counter   = timer.end_counter - timer.last_counter;
    timer.time_in_ms      = cast(float64)(1000.0 * cast(float64)timer.delta_counter) / cast(float64)performance_count_frequency;

    timer.last_tsc        = timer.end_tsc;
    timer.last_counter    = timer.end_counter;
}

d_end_and_report_timer :: (timer: *D_Profile_Timer)
{
    d_end_profile_timer(timer);

    print("[DEBUG]: -----TIMER_STATS-----\n");
    print("         FUNCTION   : %\n",   timer.label);
    print("         LOCATION   : %\n",   timer.location);
    print("         TIME IN MS : %ms\n", timer.time_in_ms);
    print("         MEGA_CYCLES: %\n\n", timer.megacycle_counter);
}

d_profile_and_report :: (location := #caller_location)
{
    d_profile_scope(location);
}

d_end_all_profiling_and_report :: ()
{
    timer_index: u64 = 0;
    print("[DEBUG]: -----PROFILER_STATS-----\n\n\n");
    while timer_index < active_timer_counter
    {
        timer := *debug_timers[timer_index];
        
        print("[DEBUG]: ------TIMER_STATS------\n");
        print("         FUNCTION   : %\n",   timer.label);
        print("         LOCATION   : %\n",   timer.location);
        print("         TIME IN MS : %ms\n", timer.time_in_ms);
        print("         MEGA_CYCLES: %\n\n", timer.megacycle_counter);

        timer_index += 1;
    }
}

d_profile_scope :: (location := #caller_location) #expand
{
    timer         := #run d_get_new_timer();
    timer.label    = #procedure_name();
    timer.location = location;

    d_start_profile_timer(timer);
    `defer d_end_profile_timer(timer);
}

#scope_file
#no_reset active_timer_counter       : u64;
#no_reset performance_count_frequency: u64;

debug_timers               : [1024]D_Profile_Timer;


