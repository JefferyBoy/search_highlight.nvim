-- 多关键词搜索(/a\|b)时，每个关键词使用不同颜色的色块高亮，方便对比分析日志
-- 实现：监听@/寄存器，按\|拆分成关键词后逐个matchadd，优先级高于hlsearch
local M = {}

-- 使用catppuccin mocha主题色板，按顺序循环使用
local COLORS = {
	{ fg = "#1a1c2a", bg = "#ea7183" }, -- 红
	{ fg = "#1a1c2a", bg = "#96d382" }, -- 绿
	{ fg = "#1a1c2a", bg = "#739df2" }, -- 蓝
	{ fg = "#1a1c2a", bg = "#eaca89" }, -- 黄
	{ fg = "#1a1c2a", bg = "#b889f4" }, -- 紫
	{ fg = "#1a1c2a", bg = "#78cec1" }, -- 青
	{ fg = "#1a1c2a", bg = "#f39967" }, -- 橙
}

-- 窗口id -> matchid列表
local matches = {}
-- 窗口id -> 上次已应用的关键词，避免重复刷新
local applied_pattern = {}

local function clear_win(winid)
	if matches[winid] then
		for _, id in ipairs(matches[winid]) do
			pcall(vim.fn.matchdelete, id)
		end
		matches[winid] = nil
	end
	applied_pattern[winid] = nil
end

-- 把搜索模式拆成多个关键词，每个关键词是正则表达式，可直接传给matchadd
local function split_keywords(pattern)
	if pattern:sub(1, 2) == "\\V" or pattern:sub(1, 2) == "\\M" then
		-- 非魔法模式下\|不是分隔符，整个模式作为一个关键词
		return { pattern }
	elseif pattern:sub(1, 2) == "\\v" then
		return vim.split(pattern:sub(3), "|")
	end
	return vim.split(pattern, "\\|")
end

local function apply_win(winid)
	local pattern = vim.fn.getreg("/")
	-- :noh后不显示高亮
	if vim.v.hlsearch == 0 or pattern == "" then
		clear_win(winid)
		return
	end
	if applied_pattern[winid] == pattern then
		return
	end
	clear_win(winid)
	local keywords = split_keywords(pattern)
	-- 单个关键词保持原生hlsearch高亮，不覆盖
	if #keywords <= 1 then
		applied_pattern[winid] = pattern
		return
	end
	matches[winid] = {}
	for i, kw in ipairs(keywords) do
		if kw ~= "" then
			local group = "KeywordSearch" .. ((i - 1) % #COLORS + 1)
			-- 优先级要高于hlsearch(优先级0)，靠前的关键词优先级更高
			local ok, id = pcall(vim.fn.matchadd, group, kw, #keywords - i + 10)
			if ok and id > 0 then
				table.insert(matches[winid], id)
			end
		end
	end
	applied_pattern[winid] = pattern
end

-- 搜索是全局行为，所有窗口都刷新，与hlsearch保持一致
local function apply_all()
	for _, winid in ipairs(vim.api.nvim_list_wins()) do
		if vim.api.nvim_win_is_valid(winid) then
			apply_win(winid)
		end
	end
end

local function apply_current()
	apply_win(vim.api.nvim_get_current_win())
end

function M.setup()
	for i, color in ipairs(COLORS) do
		vim.api.nvim_set_hl(0, "KeywordSearch" .. i, {
			fg = color.fg,
			bg = color.bg,
			default = true,
		})
	end

	local group = vim.api.nvim_create_augroup("SearchHighlight", { clear = true })
	-- 搜索命令执行后刷新（/搜索、:noh、:let @/等）
	vim.api.nvim_create_autocmd("CmdlineLeave", { group = group, callback = apply_all })
	-- 切换窗口/分屏后刷新
	vim.api.nvim_create_autocmd("WinEnter", { group = group, callback = apply_current })
	-- 兜底：*等不经过命令行直接修改@/的情况
	vim.api.nvim_create_autocmd("CursorHold", { group = group, callback = apply_current })
	-- 窗口关闭后清理
	vim.api.nvim_create_autocmd("WinClosed", {
		group = group,
		callback = function(args)
			matches[tonumber(args.match)] = nil
			applied_pattern[tonumber(args.match)] = nil
		end,
	})
end

return M
