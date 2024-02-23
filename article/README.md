# Blog

- generator: hugo
- theme: https://themes.gohugo.io/themes/hugo-theme-nostyleplease

# Build

```sh
xmake l setup.lua
```

```lua
# setup.lua
local build_dir = ""
local article_dir = "content/post"

function main()
    if not os.isdir(article_dir) then
        os.ln("path/to/post", article_dir)
    end

    os.execv("hugo", {"-d", build_dir})

    os.cd(build_dir)

    -- os.execv("git", {"add", "."})
    -- os.execv("git", {"commit", "-m", "v1.0.0"})
    -- os.execv("git", {"push"})
end
```
