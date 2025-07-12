if vim.fn.exists("g:loaded_grok") == 1 then
	return
end
vim.g.loaded_grok = 1

-- Create user command
vim.api.nvim_create_user("Grok", function(opts)
	require("grok").query(table.concat(opts.fargs, " "))
end, { nargs = "*", desc = "Query Grok 4" })
