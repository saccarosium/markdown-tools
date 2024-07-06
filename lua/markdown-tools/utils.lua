local M = {}

---@param term string | number
---@param matches {any: any}
---@return any?
function M.match(term, matches)
    assert(term)
    assert(matches)

    setmetatable(matches, {
        __index = function(self, key)
            local default
            for k, v in pairs(self) do
                if k == "_" then
                    default = v
                elseif type(k) == "table" then
                    if vim.deep_equal(k, key) then
                        return v
                    end
                elseif type(k) == "function" then
                    if k(key) then
                        return v
                    end
                elseif type(k) == "string" then
                    if key:match(k) == key then
                        return v
                    end
                elseif type(k) == "number" or type(k) == "boolean" then
                    if k == key then
                        return v
                    end
                end
            end
            return default
        end,
    })

    return matches[term]
end

function M.plug_define(mode, lhs, rhs, opts)
    opts = vim.tbl_deep_extend("force", { buffer = true }, opts or {})
    lhs = "<Plug>Markdown" .. lhs
    vim.keymap.set(mode, lhs, rhs, opts)
end

function M.map(mode, lhs, rhs, opts)
    vim.keymap.set(mode, lhs, rhs, opts)
end

function M.lmap(mode, lhs, rhs, opts)
    opts = vim.tbl_deep_extend("force", { buffer = true }, opts or {})
    vim.keymap.set(mode, lhs, rhs, opts)
end

return M
