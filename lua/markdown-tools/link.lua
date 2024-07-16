local M = {}

local match = require("markdown-tools.utils").match

---@param node TSNode
---@return string
local function get_url_from_label(node)
    local label = vim.treesitter.get_node_text(node, 0)
    local parser = vim.treesitter.get_parser()
    local root = parser:parse()[1]:root()
    local parse_query = vim.treesitter.query.parse("markdown", [[
  (link_reference_definition
    (link_label) @label (#eq? @label "]] .. label .. [[")
    (link_destination) @link_destination)
  ]])
    -- Problem with handling whitespace in filenames elegently is with this iter_matches
    for _, captures, _ in parse_query:iter_matches(root, 0) do
        local node_text = vim.treesitter.get_node_text(captures[2], 0)
        -- Kludgy method right now is to require that filenames with spaces are wrapped in <>,
        -- which are stripped out after the matching is complete
        ---@diagnostic disable-next-line: redundant-return-value
        return node_text:gsub("[<>]", "")
    end
end

local function get_url_from_link(link)
    local ts_utils = require("nvim-treesitter.ts_utils")

    local to_unpack = function(x)
        return x == "link_reference_definition" or x == "inline_link" or x == "full_reference_link"
    end

    local provide = match(link:type(), {
        ["link_destination"] = function() return vim.treesitter.get_node_text(link, 0) end,
        ["link_label"] = function() return get_url_from_label(link) end,
        ["link_text"] = function() return get_url_from_link(assert(ts_utils.get_next_node(link))) end,
        ["[%w]*_autolink"] = function()
            local node_text = vim.treesitter.get_node_text(link, 0)
            return node_text:sub(2, #node_text - 1)
        end,
        [to_unpack] = function()
            local child_nodes = ts_utils.get_named_children(link)
            local _, node_next = unpack(child_nodes)
            return get_url_from_link(node_next)
        end,
    })

    return vim.is_callable(provide) and vim.split(provide(), "\n")[1] or nil
end

---@return TSNode
local function get_link_under_cursor()
    local ts_utils = require("nvim-treesitter.ts_utils")
    local node_at_cursor = assert(ts_utils.get_node_at_cursor())
    return match(node_at_cursor:type(), {
        ["[_a-z]*link[_a-z]*"] = node_at_cursor,
        _ = nil,
    })
end

function M.follow()
    local link_under_cursor = get_link_under_cursor()
    if not link_under_cursor then
        return
    end

    local url_unresolved = get_url_from_link(link_under_cursor)
    if not url_unresolved then
        return
    end

    local url_resolved, url_type = unpack(match(url_unresolved, {
        ["[%w]*://[^ >,;]*"] = { url_unresolved, "url" },
        ["[%w.]+@%w+%.%w+$"] = { url_unresolved, "email" },
        _ = { vim.fs.normalize(url_unresolved), "path" },
    }))

    local follow = match(url_type, {
        path = vim.cmd.edit,
        url = vim.ui.open,
        email = function(x) vim.system({ "xdg-email", x }) end,
    })

    follow(url_resolved)
end

function M.create()
    local link_trasform = function(x) return ("[%s](%s.md)"):format(x, x) end
    local cword = vim.fn.expand("<cword>")
    if vim.fn.empty(cword) == 1 then
        return
    end
    local link = link_trasform(cword)
    local pos = vim.api.nvim_win_get_cursor(0)
    local lnr = pos[1] - 1
    local _, start_col, end_col =
        unpack(vim.fn.matchstrpos(vim.fn.getline("."), cword, pos[2] - #cword))
    vim.api.nvim_buf_set_text(0, lnr, start_col, lnr, end_col, { link })
    pos[2] = pos[2] + 1
    vim.api.nvim_win_set_cursor(0, pos)
end

function M.follow_or_create()
    if get_link_under_cursor() then
        M.follow()
    else
        M.create()
    end
end

return M
