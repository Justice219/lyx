
# Lyx Library

A full feature inclusive gmod lua library for creating content of all types. A GLUA developers biggest friend.

## Authors

- [@Justice](https://www.github.com/justice219)

## Feature Examples

# Chat Commands

| Method | Params     | Description                |
| :-------- | :------- | :------------------------- |
| `lyx:ChatAddCommand()` | `string name, table settings` | Creates Chat Command with args and other inclusive features |

#### Example

```lua
lyx:ChatAddCommand("test", {
    prefix = "!",
    func = function(ply, args)
        ply:ChatPrint("Hello " .. ply:Nick() .. "!")
    end
}, false)
```

Creates a console command with the name "test" and prints 
the callers nickname in chat.

