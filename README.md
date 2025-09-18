
# Lyx: Revamped

A powerful lua library created for [Garry's Mod](https://gmod.facepunch.com/) 

``Lyx`` was created to speed up personal addon developoment, but is totally open to public domain.


## License

[![CC BY NC](https://img.shields.io/badge/License-CC%20BY%20NC-blue)](https://creativecommons.org/licenses/by-nc/2.0/deed.en)

Feel free to modify or redploy any of base Lyx code. Although, proper atributions must be made somewhere within your modified code, and or deployment page.


## Authors

- [@Justice](https://www.github.com/Justice219) Library Code
- [@CodeSteel](https://github.com/CodeSteel) Super Convienent UI Library


## Features

- Custom Chat Commands
- Global Message Broadcasting
- Hook Library
- Net Message Library
- Video Library
- Convienent UI Library
- Fast JSON Library
- Fast Key/Value (Settings) Library
- Fast Logging Library
- Performance 2D and 3D Drawing

## Usage/Examples
Custom chat command creation.

```lua
lyx:ChatAddCommand("test", {
    prefix = "!",
    func = function(ply, args)
            ply:ChatPrint("Hello " .. ply:Nick() .. "!")
    end
    }, false) 
```
OOP based hook library example.
```lua
local function ExampleHook()
lyx:HookCall("lyx_test", "Hello World!")            -- This or the hook.Run function can be used.
end

local test = lyx:HookStart("lyx_test", function(...)  -- Lets actually start the hook.
    local args = {...}                                -- This returns an ID for the hook to ease removing it.
    print(args[1])                                    -- Takes all arguments, you need to know what index to use.
end)                                                  -- This is a sort of example on how to access arguments.

ExampleHook()                                         -- Lets call the function to create a hook call.

lyx:HookRemove("lyx_test", test)                      -- Lets remove just to keep random hooks off the server.
```

## Documentation

### 📚 Official Documentation
Complete documentation for LYX is available at:  
**[https://xdjustice4.gitbook.io/lyx-docs/](https://xdjustice4.gitbook.io/lyx-docs/)**

The documentation includes:
- Getting started guides
- Complete API reference
- UI component documentation
- Networking and database guides
- Examples and best practices

### Legacy Wiki
The original wiki documentation can be found [here](https://github.com/Justice219/lyx/wiki)

### Real Project
[Gamemaster 3](https://github.com/Justice219/gamemaster3) - A powerful gamemaster system created using almost everything lyx has to offer; A prime example of lyx's capabilities.

![Image](https://i.imgur.com/bcsv4zw.gif)
