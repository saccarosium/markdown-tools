vim.opt_local.tabstop = 2
vim.opt_local.softtabstop = 2
vim.opt_local.shiftwidth = 2
vim.opt_local.expandtab = false

local u = require("markdown-tools.utils")

----------
-- Link --
----------

u.plug_define(
    "n",
    "LinkFollowOrCreate",
    function() require("markdown-tools.link").follow_or_create() end
)

u.lmap("n", "<CR>", "<Plug>MarkdownLinkFollowOrCreate")

u.plug_define("n", "LinkFollow", function() require("markdown-tools.link").follow() end)
u.plug_define("n", "CreateLink", function() require("markdown-tools.link").create() end)

---------
-- Toc --
---------

u.plug_define("n", "TocOpen", function() require("markdown-tools.toc").open() end)

u.lmap("n", "gO", "<Plug>MarkdownTocOpen")
