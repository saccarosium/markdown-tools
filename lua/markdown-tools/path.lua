local M = {}

function M.getfull(path)
    assert(path)
    return vim.fs.joinpath(vim.uv.cwd(), path)
end

return M
