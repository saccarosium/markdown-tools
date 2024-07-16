vim.api.nvim_create_user_command("Pandoc", function(x)
    local u = require("markdown-tools.utils")
    local pandoc = require("markdown-tools.pandoc")
    local path = require("markdown-tools.path")

    local args = x.fargs
    if not vim.tbl_isempty(args) and not u.file_isvalid(path.getfull(args[#args])) then
        local file = vim.api.nvim_buf_get_name(0)
        if vim.bo.filetype ~= "markdown" then
            error("Filetype is not supported", 0)
        end
        table.insert(args, file)
    end

    pandoc.compile(args)
end, { nargs = "+", complete = require("markdown-tools.pandoc").completion })
