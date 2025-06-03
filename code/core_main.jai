#import "Basic";

#load "L_labyrinthian_main.jai";

main :: ()
{
    result := SDL_Init(SDL_INIT_EVERYTHING);
    if result == 0
    {
        L_labyrinthian_main();
    }
    else
    {
        log_error("[ERROR]:  Failure to init SDL... error: %...\n", to_string(SDL_GetError()));
    }
}
