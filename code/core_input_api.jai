Game_Action_Index :: enum
{
    MOVE_UP;
    MOVE_DOWN;
    MOVE_LEFT;
    MOVE_RIGHT;
    INTERACT;
    ATTACK;
};

MOUSE_BUTTON_COUNT    :: 5;

Input_Manager :: struct
{
    keyboard_input   : Keyboard_Input_Data;
    controller_input : Controller_Input_Data;
    game_actions     : [..]Game_Action;

    is_controller    : bool;
    connected_controller_count: s32;
};

// TODO(Sleepster): Window size event 
c_handle_window_events :: (input_manager: *Input_Manager)
{
    event: SDL_Event;
    while SDL_PollEvent(*event)
    {
        if event.type == 
        {
            case SDL_QUIT;
            {
                d_end_all_profiling_and_report();
                os_exit_process();
            }
            case SDL_WINDOWEVENT;
            {
                if event.window.event == SDL_WINDOWEVENT_SIZE_CHANGED 
                {
                    global_window_data.old_window_size = global_window_data.current_window_size;
                    SDL_GL_GetDrawableSize(global_window_data.window,
                                          *global_window_data.current_window_size.x,
                                          *global_window_data.current_window_size.y);
                }
            }

            case SDL_CONTROLLERDEVICEADDED;
            {
                new_controller  := *input_manager.controller_input.platform_controller_data;
                controller_data := input_manager.controller_input;
                if new_controller.instance_id != 0
                {
                    log("There is a device already connected, returning...\n");
                    break;
                }
                
                if SDL_IsGameController(event.cdevice.which)
                {
                    new_controller.instance_id  = event.cdevice.which;

                    new_controller.gamepad_data = SDL_GameControllerOpen(new_controller.instance_id);
                    new_controller.stick_data   = SDL_GameControllerGetJoystick(new_controller.gamepad_data);
                    controller_data.has_rumble  = cast(bool)SDL_GameControllerRumble(new_controller.gamepad_data, 0xFFFF, 0xFFFF, 100000);
                    log("Controller Connected... Device: %\n", to_string(xx SDL_GameControllerName(new_controller.gamepad_data)));
                    input_manager.connected_controller_count += 1;
                }
            }
            case SDL_CONTROLLERDEVICEREMOVED;
            {
                controller := input_manager.controller_input.platform_controller_data.gamepad_data;
                joystick   := input_manager.controller_input.platform_controller_data.stick_data;

                SDL_GameControllerClose(controller);
                SDL_JoystickClose(joystick);

                input_manager.connected_controller_count -= 1;
            }

            case SDL_KEYUP; #through;
            case SDL_KEYDOWN;
            {
                using input_manager.keyboard_input;
                key_index  := event.key.keysym.scancode;
                key_values := event.key;
                input_key_this_event := *keys[key_index]; 

                input_key_this_event.is_pressed  = cast(bool)((key_values.state == SDL_PRESSED) &&
                                                              !input_key_this_event.is_pressed);

                input_key_this_event.is_down     = cast(bool)input_key_this_event.is_pressed && !input_key_this_event.is_released ;
                input_key_this_event.is_released = cast(bool)(key_values.state == SDL_RELEASED);

                if input_key_this_event.is_pressed || input_key_this_event.is_released
                then input_key_this_event.half_transition_counter += 1;
            }

            case SDL_MOUSEMOTION;
            {
                using input_manager.keyboard_input;
                old_mouse_pos_x := current_mouse_pos.x;
                old_mouse_pos_y := current_mouse_pos.y;
                
                current_mouse_pos.x = cast(float)event.motion.x;
                current_mouse_pos.y = cast(float)event.motion.y;

                delta_mouse_pos = .{current_mouse_pos.x - old_mouse_pos_x, current_mouse_pos.y - old_mouse_pos_y};
            }
            case SDL_MOUSEBUTTONUP; #through;
            case SDL_MOUSEBUTTONDOWN;
            {
                using input_manager.keyboard_input;
                button_index := cast(s32)event.button.button + cast(s32)SDL_NUM_SCANCODES;
                mouse_button_this_event := *keys[button_index]; 

                mouse_button_this_event.is_pressed  = cast(bool)((event.button.state == SDL_PRESSED) && !mouse_button_this_event.is_pressed);
                mouse_button_this_event.is_released = cast(bool)(event.button.state == SDL_RELEASED);
                if event.button.state == SDL_PRESSED       then mouse_button_this_event.is_down = true;
                else if event.button.state == SDL_RELEASED then mouse_button_this_event.is_down = false;

                if mouse_button_this_event.is_pressed || mouse_button_this_event.is_released
                then mouse_button_this_event.half_transition_counter += 1;
            }

            case SDL_CONTROLLERBUTTONUP; #through;
            case SDL_CONTROLLERBUTTONDOWN;
            {
                using input_manager.controller_input;
                button        := *button_states[event.cbutton.button];
                button_values := event.cbutton;

                button.is_pressed  = cast(bool)((button_values.state == SDL_PRESSED) && !button.is_pressed);
                button.is_down     = button.is_pressed; 
                button.is_released = cast(bool)(button_values.state == SDL_RELEASED);

                if button.is_pressed || button.is_released
                then button.half_transition_counter += 1;
            }
            case SDL_CONTROLLERAXISMOTION;
            {
                using input_manager.controller_input;
                analog_button_data := *axis_button_states[event.caxis.axis];
                analog_button_data.button_value = event.caxis.value;

                // left_stick_x        = SDL_GameControllerGetAxis(platform_controller_data.gamepad_data, SDL_CONTROLLER_AXIS_LEFTX);
                // left_stick_y        = SDL_GameControllerGetAxis(platform_controller_data.gamepad_data, SDL_CONTROLLER_AXIS_LEFTY);
                // right_stick_x       = SDL_GameControllerGetAxis(platform_controller_data.gamepad_data, SDL_CONTROLLER_AXIS_RIGHTX);
                // right_stick_y       = SDL_GameControllerGetAxis(platform_controller_data.gamepad_data, SDL_CONTROLLER_AXIS_RIGHTY);
                // left_trigger_value  = SDL_GameControllerGetAxis(platform_controller_data.gamepad_data, SDL_CONTROLLER_AXIS_TRIGGERLEFT);
                // right_trigger_value = SDL_GameControllerGetAxis(platform_controller_data.gamepad_data, SDL_CONTROLLER_AXIS_TRIGGERRIGHT);
            }
        }
    }
}

//////////////////
// KEYBOARD STUFF
//////////////////

Action_Button :: struct
{
    is_pressed              : bool;
    is_released             : bool;
    is_down                 : bool;
    half_transition_counter : u8;
};

Mouse_Buttons :: enum
{
    SDL_LEFT_MOUSE_BUTTON   :: 513;
    SDL_RIGHT_MOUSE_BUTTON  :: 514;
    SDL_MIDDLE_MOUSE_BUTTON :: 515;
    SDL_X1_MOUSE_BUTTON     :: 516;
    SDL_X2_MOUSE_BUTTON     :: 517;
};

Keyboard_Input_Data :: struct
{
    current_mouse_pos  : Vector2;
    last_mouse_pos     : Vector2;
    delta_mouse_pos    : Vector2;

    keys               : [SDL_NUM_SCANCODES + MOUSE_BUTTON_COUNT]Action_Button;
    SDL_keys           : *u8;
};

c_reset_key_states :: (using input_manager: *Input_Manager)
{
    for *key: keyboard_input.keys
    {
        key.is_pressed              = false;
        key.is_released             = false;
        key.half_transition_counter = 0;
    }

    for *button: controller_input.button_states
    {
        button.is_pressed              = false;
        button.is_pressed              = false;
        button.is_released             = false;
        button.half_transition_counter = 0;
    }

    for *stick: controller_input.axis_button_states
    {
        stick.button_deadzone = 8200;
    }
}

c_is_key_pressed :: inline (input_manager: *Input_Manager, key_index: s32) -> bool
{
    key_to_test := input_manager.keyboard_input.keys[key_index];
    return key_to_test.is_pressed;
}

c_is_key_down :: inline (input_manager: *Input_Manager, key_index: s32) -> bool
{
    key_to_test := input_manager.keyboard_input.keys[key_index];
    return key_to_test.is_down;
}

c_is_key_released :: inline (input_manager: *Input_Manager, key_index: s32) -> bool
{
    key_to_test := input_manager.keyboard_input.keys[key_index];
    return key_to_test.is_released;
}

c_consume_key_press :: inline (input_manager: *Input_Manager, key_index: s32)
{
    key_to_test := input_manager.keyboard_input.keys[key_index];
    key_to_test.half_transition_counter = 0;
    key_to_test.is_pressed = false;
}

c_consume_key_released :: inline (input_manager: *Input_Manager, key_index: s32)
{
    key_to_test := input_manager.keyboard_input.keys[key_index];
    key_to_test.half_transition_counter = 0;
    key_to_test.is_released = false;
}

c_consume_key_down :: inline (input_manager: *Input_Manager, key_index: s32)
{
    key_to_test := input_manager.keyboard_input.keys[key_index];
    key_to_test.half_transition_counter = 0;
    key_to_test.is_down = false;
}

////////////////////
// CONTROLLER STUFF
////////////////////

/*
typedef enum SDL_GameControllerButton
{
    SDL_CONTROLLER_BUTTON_INVALID = -1,
    SDL_CONTROLLER_BUTTON_A,
    SDL_CONTROLLER_BUTTON_B,
    SDL_CONTROLLER_BUTTON_X,
    SDL_CONTROLLER_BUTTON_Y,
    SDL_CONTROLLER_BUTTON_BACK,
    SDL_CONTROLLER_BUTTON_GUIDE,
    SDL_CONTROLLER_BUTTON_START,
    SDL_CONTROLLER_BUTTON_LEFTSTICK,
    SDL_CONTROLLER_BUTTON_RIGHTSTICK,
    SDL_CONTROLLER_BUTTON_LEFTSHOULDER,
    SDL_CONTROLLER_BUTTON_RIGHTSHOULDER,
    SDL_CONTROLLER_BUTTON_DPAD_UP,
    SDL_CONTROLLER_BUTTON_DPAD_DOWN,
    SDL_CONTROLLER_BUTTON_DPAD_LEFT,
    SDL_CONTROLLER_BUTTON_DPAD_RIGHT,
    SDL_CONTROLLER_BUTTON_MISC1,    /* Xbox Series X share button, PS5 microphone button, Nintendo Switch Pro capture button, Amazon Luna microphone button */
    SDL_CONTROLLER_BUTTON_PADDLE1,  /* Xbox Elite paddle P1 (upper left, facing the back) */
    SDL_CONTROLLER_BUTTON_PADDLE2,  /* Xbox Elite paddle P3 (upper right, facing the back) */
    SDL_CONTROLLER_BUTTON_PADDLE3,  /* Xbox Elite paddle P2 (lower left, facing the back) */
    SDL_CONTROLLER_BUTTON_PADDLE4,  /* Xbox Elite paddle P4 (lower right, facing the back) */
    SDL_CONTROLLER_BUTTON_TOUCHPAD, /* PS4/PS5 touchpad button */
    SDL_CONTROLLER_BUTTON_MAX
} SDL_GameControllerButton;
*/

SDL_Controller_Data :: struct
{
    gamepad_data : *SDL_GameController;
    stick_data   : *SDL_Joystick;
    instance_id  : s32;
}

Analog_Button_Data :: struct
{
    button_deadzone : s16;
    button_value    : s16;
};

Controller_Input_Data :: struct
{
    platform_controller_data : SDL_Controller_Data;

    has_rumble               : bool;
    rumble_value             : s32;
    button_states            : [SDL_CONTROLLER_BUTTON_MAX]Action_Button;
    axis_button_states       : [SDL_CONTROLLER_AXIS_MAX]Analog_Button_Data;
};

c_is_button_pressed :: inline (input_manager: *Input_Manager, button_index: s32) -> bool
{
    button := input_manager.controller_input.button_states[button_index]; 
    return button.is_pressed;
}

c_is_button_down :: inline (input_manager: *Input_Manager, button_index: s32) -> bool
{
    button := input_manager.controller_input.button_states[button_index]; 
    return button.is_down;
}

c_is_button_released :: inline (input_manager: *Input_Manager, button_index: s32) -> bool
{
    button := input_manager.controller_input.button_states[button_index]; 
    return button.is_released;
}

c_consume_button_press :: inline (input_manager: *Input_Manager, button_index: s32)
{
    button_to_test := input_manager.controller_input.button_states[button_index];
    button_to_test.half_transition_counter = 0;
    button_to_test.is_pressed = false;
}

c_consume_button_released :: inline (input_manager: *Input_Manager, button_index: s32)
{
    button_to_test := input_manager.controller_input.button_states[button_index];
    button_to_test.half_transition_counter = 0;
    button_to_test.is_released = false;
}

c_consume_button_down :: inline (input_manager: *Input_Manager, button_index: s32)
{
    button_to_test := input_manager.controller_input.button_states[button_index];
    button_to_test.half_transition_counter = 0;
    button_to_test.is_down= false;
}

// typedef enum SDL_GameControllerAxis
// {
//     SDL_CONTROLLER_AXIS_INVALID = -1,
//     SDL_CONTROLLER_AXIS_LEFTX,
//     SDL_CONTROLLER_AXIS_LEFTY,
//     SDL_CONTROLLER_AXIS_RIGHTX,
//     SDL_CONTROLLER_AXIS_RIGHTY,
//     SDL_CONTROLLER_AXIS_TRIGGERLEFT,
//     SDL_CONTROLLER_AXIS_TRIGGERRIGHT,
//     SDL_CONTROLLER_AXIS_MAX
// } SDL_GameControllerAxis;

// NOTE(Sleepster): if you call to check the analog button data, only use the x parts. We'll return both axis anyway
c_read_controller_axis :: inline (input_manager: *Input_Manager, stick_axis_index: s32) -> (s16, s16)
{
    return input_manager.controller_input.axis_button_states[stick_axis_index].button_value,
           input_manager.controller_input.axis_button_states[stick_axis_index + 1].button_value;
}

///////////////////
// GAME ACTION API
///////////////////

// TODO(Sleepster): AXIS ASSIGNMENT (things like controller left stick assignment) 
Game_Action :: struct
{
    // NOTE(Sleepster): "action_key" is for keyboard controls,
    //                  "action_button" is for controller
    action_key    : s32;
    action_button : s32;
};

c_game_action_set_action :: inline (input_manager: *Input_Manager, key_index: s32, button_index: s32) -> Game_Action
{
    result: Game_Action;
    result.action_key    = key_index;
    result.action_button = button_index;

    return result;
}

c_game_action_add_action :: inline (input_manager: *Input_Manager, key_index: s32, button_index: s32)
{
    action := c_game_action_set_action(input_manager, key_index, button_index);
    array_add(*input_manager.game_actions, *action);
}

// TODO(Sleepster): Instead of passing a pointer to the game action, why not just use the game_action enum index??? 
c_game_action_is_pressed :: inline (input_manager: *Input_Manager, action_index: Game_Action_Index) -> bool
{
    action := input_manager.game_actions[action_index];
    is_pressed: bool;
    
    is_pressed = c_is_key_pressed(input_manager, action.action_key);
    if is_pressed return is_pressed;

    is_pressed = c_is_button_pressed(input_manager, action.action_button);
    return is_pressed;
}

c_game_action_is_down :: inline (input_manager: *Input_Manager, action_index: Game_Action_Index) -> bool
{
    action := input_manager.game_actions[action_index];
    
    is_down: bool;
    
    is_down = c_is_key_down(input_manager, action.action_key);
    if is_down return is_down;

    is_down = c_is_button_down(input_manager, action.action_button);
    return is_down;
}

c_game_action_is_released :: inline (input_manager: *Input_Manager, action_index: Game_Action_Index) -> bool
{
    action := input_manager.game_actions[action_index];
    is_released: bool;
    
    is_released = c_is_key_released(input_manager, action.action_key);
    if is_released return is_released;

    is_released = c_is_button_released(input_manager, action.action_button);
    return is_released;
}

c_game_action_consume_is_pressed :: inline (input_manager: *Input_Manager, action_index: Game_Action_Index)
{
    action := input_manager.game_actions[action_index];
    c_consume_button_press(input_manager, action.action_button);
    c_consume_key_press(input_manager, action.action_key);
}

c_game_action_consume_is_down :: inline (input_manager: *Input_Manager, action_index: Game_Action_Index)
{
    action := input_manager.game_actions[action_index];
    c_consume_button_down(input_manager, action.action_button);
    c_consume_key_down(input_manager, action.action_key);
}

c_game_action_consume_is_released :: inline (input_manager: *Input_Manager, action_index: Game_Action_Index)
{
    action := input_manager.game_actions[action_index];
    c_consume_button_released(input_manager, action.action_button);
    c_consume_key_released(input_manager, action.action_key);
}
