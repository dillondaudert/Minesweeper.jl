

# overview of game engine responsibilities

# while not exiting:
#   1. handle user input
#   2. update game state
#   3. render game state

abstract type AppState end

struct MainMenuState <: AppState end

struct ResultState <: AppState end
struct PlayState <: AppState end
struct QuitState <: AppState end

function handle_input end

function handle_input(state::AppState)

    event_ref = Ref{SDL_Event}()
    
    while Bool(SDL_PollEvent(event_ref))
        event = event_ref[]
        type = SDL_EventType(event.type) # cast the Uint to an SDL_EventType
        # handle inputs (mostly mouse, but some keyboard events like ESC)
        # we want to change behavior based on app state.
        result = handle_input(state, Val(type), event)

        if !isnothing(result)
            return result
        end 
    end
    # if we haven't returned a new state to transition to, return the current state 
    return state
end

handle_input(state, type, event) = nothing
handle_input(state, event, type, key) = nothing

# quit from anywhere whenever we receive a QUIT event
handle_input(::AppState, ::Val{SDL_QUIT}, _) = QuitState()

# handle keyboard events - we need to pull out the scancode of the button to dispatch
function handle_input(state::AppState, type::Val{SDL_KEYDOWN}, event)
    scancode = event.key.keysym.scancode
    # dispatch on state, SDL_KeyboardEvent, SDL_KEYDOWN, which key (scancode)
    return handle_input(state, event.key, type, Val(scancode))
end

handle_input(::MainMenuState, ::SDL_KeyboardEvent, ::Val{SDL_KEYDOWN}, ::Val{SDL_SCANCODE_ESCAPE}) = QuitState()




function start_game()

    # INITIALIZE SDL
    call_SDL(() -> SDL_Init(SDL_INIT_EVERYTHING), res -> res == 0)
    # Initialize TTF for text rendering
    call_SDL(() -> TTF_Init(), res -> res == 0)
    # create window and renderer
    win = call_SDL(() -> SDL_CreateWindow("Minesweeper", SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED, WIN_WIDTH, WIN_HEIGHT, SDL_WINDOW_SHOWN), res -> res != C_NULL)
    renderer = call_SDL(() -> SDL_CreateRenderer(win, -1, SDL_RENDERER_ACCELERATED | SDL_RENDERER_PRESENTVSYNC), res -> res != C_NULL)

    eng_state = MainMenuState()

    try

        while !(eng_state isa QuitState)

            eng_state = handle_input(eng_state)

            SDL_Delay(1000 ÷ 60)
        end
    finally

        # SDL TEARDOWN
        TTF_Quit()
        SDL_DestroyRenderer(renderer)
        SDL_DestroyWindow(win)
        SDL_Quit()
    end
end