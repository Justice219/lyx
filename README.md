
# Lyx Library

A full feature inclusive gmod lua library for creating content of all types. A GLUA developers biggest friend.

## Authors

- [@Justice](https://www.github.com/justice219)

## Feature Example

#### Get all items

```http
  GET /api/items
```

| Method | Params     | Description                |
| :-------- | :------- | :------------------------- |
| `lyx:ChatAddCommand()` | `string name, table settings` | Creates Chat Command with return function |

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

