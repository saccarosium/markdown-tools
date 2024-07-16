local M = {}

local function options_get()
    local options = {}
    local out = vim.system({ "pandoc", "--bash-completion" }):wait()
    for x in vim.gsplit(out.stdout, "\n") do
        local does_match = x:match("%w+=\"[^\\$].*\"")
        if does_match then
            local split = vim.split(does_match, "=")
            local left = split[1]
            local right = split[2]:gsub("\"", "")
            options[left] = vim.split(right, " ")
        end
    end
    return options
end

local function complete(cursor, tbl)
    local filterd_args = vim.tbl_filter(
        function(v) return v:find(cursor:lower(), 1, true) == 1 end,
        tbl
    )
    if not vim.tbl_isempty(filterd_args) then
        return filterd_args
    end
    return tbl
end

function M.completion(cursor, word, ...)
    local options = options_get()
    local match = require("markdown-tools.utils").match
    local m = function(t)
        return function(x) return vim.tbl_contains(t, x) end
    end
    local f = function(x)
        return function() return complete(cursor, x) end
    end

    local vargs = vim.split(word, " ")
    local prev = vargs[#vargs - 1]
    vim.print(prev)

    local x = match(prev, {
        [m({ "--from", "-f", "--read", "-r" })] = f(options.informats),
        [m({ "--to, -t, --write, -w, -D, --print-default-template" })] = f(options.outformats),
        ["--email-obfuscation"] = f({"references", "javascript", "none"}),
    })

    if vim.is_callable(x) then
        return x()
    end

    return match(cursor, {
        ["-.*"] = function() return complete(cursor, options.opts) end,
        _ = function() return vim.fn.getcompletion(cursor, "file") end,
    })()
end

---@param args string[]
function M.compile(args)
    local cmd = vim.list_extend({ "pandoc" }, args)
    local out = vim.system(cmd, { text = true }):wait()
    if vim.fn.empty(out.stderr) ~= 1 then
        local stderr = vim.split(out.stderr, "\n")
        vim.cmd("compiler pandoc")
        vim.fn.setqflist({}, "r", {
            lines = stderr,
        })
        vim.cmd.copen()
    else
        vim.notify("Done")
    end
end

return M
