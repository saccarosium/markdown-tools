local M = {}

local function gather_headings(bufnr)
    local parser = vim.treesitter.get_parser()
    local query = vim.treesitter.query.parse(
        "markdown",
        [[
        (atx_heading
          (atx_h1_marker) @h1_marker
          heading_content: (inline) @h1_content)

        (atx_heading
          (atx_h2_marker) @h2_marker
          heading_content: (inline) @h2_content)

        (atx_heading
          (atx_h3_marker) @h3_marker
          heading_content: (inline) @h3_content)

        (atx_heading
          (atx_h4_marker) @h4_marker
          heading_content: (inline) @h4_content)

        (atx_heading
          (atx_h5_marker) @h5_marker
          heading_content: (inline) @h5_content)

        (atx_heading
          (atx_h6_marker) @h6_marker
          heading_content: (inline) @h6_content)
        ]]
    )
    local indent
    local root = parser:parse()[1]:root()
    local headings = {}
    for id, node, _, _ in query:iter_captures(root, bufnr) do
        local text = vim.treesitter.get_node_text(node, bufnr)
        local name = query.captures[id]
        local row, _ = node:start()
        if name:match("%w_marker") then
            indent = (" "):rep(#text - 1)
        else
            table.insert(headings, {
                bufnr = bufnr,
                lnum = row + 1,
                text = indent .. text,
            })
        end
    end
    return headings
end

-- For reference
-- https://github.com/neovim/neovim/pull/29238/commits/6592873f773b4c358ea950bfcfa8cbc3fc3bc8cc
function M.open()
    local bufnr = vim.api.nvim_get_current_buf()
    local headings = gather_headings(bufnr)
    local path = vim.api.nvim_buf_get_name(bufnr)
    local title = ("%s TOC"):format(vim.fs.basename(path))
    vim.fn.setloclist(0, headings, " ")
    vim.fn.setloclist(0, {}, "a", { title = title })
    vim.cmd.lopen()
end

return M
