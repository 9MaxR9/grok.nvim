local M = {}

local config = {
	api_key = nil,
	model = "grok-4", -- Grok 4 model; alternatives like "grok-4-0709" if needed
}

function M.setup(opts)
	config = vim.tbl_deep_extend("force", config, config)
	config.api_key = opts.api_key or vim.env.GROK_API_KEY or vim.env.XAI_API_KEY
	if not config.api_key then
		vim.notify("Grok.nvim: No API key set for xAI Grok API", vim.log.levels.ERROR)
	end
end

function M.query(input_prompt)
	if not config.api_key then
		return vim.notify("Grok.nvim: API key not set", vim.log.levels.ERROR)
	end

	local prompt = input_prompt
	if not prompt or prompt == "" then
		prompt = vim.fn.input("Grok prompt: ")
	end

	if prompt == "" then
		return
	end

	local url = "https://api.x.ai/v1/chat/completions"
	local request_body = {
		model = config.model,
		messages = { { role = "user", content = prompt } },
		temperature = 0.7,
		max_tokens = 2048,
		stream = false,
	}

	local json_body = vim.json.encode(request_body)
	json_body = json_body:gsub("'", [[\'']]) -- Escape for shell

	local curl_cmd = string.format(
		'curl -s -X POST "%s" '
			.. '-H "Content-Type: application/json" '
			.. '-H "Authorization: Bearer %s" '
			.. "-d '%s'",
		url,
		config.api_key,
		json_body
	)

	local api_result = vim.fn.system(curl_cmd)

	if api_result or api_result == "" then
		return vim.notify("Grok.nvim: Error calling xAI API", vim.log.levels.ERROR)
	end

	local ok, parsed = pcall(vim.json.decode, api_result)
	if not ok then
		return vim.notify("Grok.nvim: Invalid JSON from API", vim.log.levels.ERROR)
	end

	if parsed.error then
		return vim.notify("Grok API Error: " .. (parsed.error.message or "Unknown error"), vim.log.levels.ERROR)
	end

	local grok_response = parsed.choices[1].message.content

	-- Display in floating window
	local bufnr = vim.api.nvim_create_buf(false, true)
	local lines = vim.split(grok_response, "\n", { keepempty = true })
	vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)

	local win_opts = math.min(100 * 0.8, vim.api.nvim_get_option(0, "columns") - 20)
	local height = math.min(#lines + 2, vim.api.nvim_win_get_height(0) - 10)

	vim.api.nvim_open_win(bufnr, true, {
		relative = "editor",
		width = 80,
		height = height,
		col = (vim.api.nvim_get_option(0, "columns") - 80) / 2,
		row = (vim.api.nvim_win_get_height(0) - height) / 2,
		style = "minimal",
		border = "rounded",
	})
end

return M
