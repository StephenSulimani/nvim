local M = {}

local did_setup = false
local visible = false

local augroup_name = "pycoverage__autocmds"

local ns = "pycoverage_ns"
local sign_covered = "pyCoverageCovered"
local sign_uncovered = "pyCoverageUncovered"

-- Match ray-x/go.nvim defaults: solid block, color via highlight group.
local sign_text = "█"
local sign_covered_hl = "String"
local sign_uncovered_hl = "Error"

local coverage_files_by_path = {}
local coverage_files_by_basename = {}
local totals = { total_lines = 0, covered_lines = 0, uncovered_lines = 0 }

local covfn = nil

-- Track placed line ids so we can remove them deterministically.
-- placed[bufnr] = { [lnum] = true, ... }
local placed = {}

local function list_to_set(list)
	if type(list) ~= "table" then
		return {}
	end
	local s = {}
	for _, v in ipairs(list) do
		local ln = v
		if type(v) == "string" then
			ln = tonumber(v)
		end
		if type(ln) == "number" and ln >= 1 then
			s[ln] = true
		end
	end
	return s
end

local function get_py_bufnrs()
	local bufs = vim.fn.getbufinfo({ bufloaded = 1, buflisted = 1 })
	local out = {}
	for _, b in ipairs(bufs) do
		local name = b.name or ""
		if name ~= "" and vim.fn.fnamemodify(name, ":e") == "py" then
			table.insert(out, b.bufnr)
		end
	end
	return out
end

local function buf_extension(bufnr)
	local name = vim.api.nvim_buf_get_name(bufnr)
	if name == "" then
		return ""
	end
	return vim.fn.fnamemodify(name, ":e")
end

local function remove_buf(bufnr)
	if placed[bufnr] == nil then
		return
	end
	for lnum, _ in pairs(placed[bufnr]) do
		vim.fn.sign_unplace(ns, { buffer = bufnr, id = lnum })
	end
	placed[bufnr] = nil
end

function M.remove_all()
	for _, bufnr in ipairs(get_py_bufnrs()) do
		remove_buf(bufnr)
	end
	visible = false
end

local function define_signs()
	-- Always redefine so config changes apply without restarting Neovim.
	vim.fn.sign_unplace(ns)
	pcall(vim.fn.sign_undefine, sign_covered)
	pcall(vim.fn.sign_undefine, sign_uncovered)

	vim.fn.sign_define(sign_covered, { text = sign_text, texthl = sign_covered })
	vim.fn.sign_define(sign_uncovered, { text = sign_text, texthl = sign_uncovered })

	vim.api.nvim_set_hl(0, sign_covered, { link = sign_covered_hl, default = true })
	vim.api.nvim_set_hl(0, sign_uncovered, { link = sign_uncovered_hl, default = true })
end

local function extract_executed_and_missing(info)
	-- coverage.py JSON (and pytest-cov) usually look like:
	-- { executed_lines: [..], missing_lines: [..], ... }
	if type(info) ~= "table" then
		return {}, {}
	end

	local executed = info.executed_lines
	local missing = info.missing_lines

	-- Fallback: some formats use `lines = { ["10"] = {...} }` or `lines = { ["10"]=true }`
	if executed == nil and missing == nil and type(info.lines) == "table" then
		executed = {}
		missing = {}
		for k, v in pairs(info.lines) do
			local ln = tonumber(k)
			if ln and ln >= 1 then
				if type(v) == "boolean" then
					if v then
						table.insert(executed, ln)
					else
						table.insert(missing, ln)
					end
				elseif type(v) == "table" then
					local ok_exec = v.executed
					if ok_exec == nil then
						-- Some formats use a `count` or similar.
						ok_exec = type(v.count) == "number" and v.count > 0
					end
					if ok_exec then
						table.insert(executed, ln)
					else
						table.insert(missing, ln)
					end
				else
					-- Unknown line entry; ignore.
				end
			end
		end
	end

	return executed or {}, missing or {}
end

local function load_cov(cov_path)
	local decoded = nil
	local ok = pcall(function()
		local lines = vim.fn.readfile(cov_path)
		if lines == nil or #lines == 0 then
			return nil
		end
		local json_str = table.concat(lines, "\n")
		decoded = vim.fn.json_decode(json_str)
	end)
	if not ok or type(decoded) ~= "table" then
		return false
	end

	local files = decoded.files or decoded["files"]
	if type(files) ~= "table" then
		return false
	end

	coverage_files_by_path = {}
	coverage_files_by_basename = {}
	totals = { total_lines = 0, covered_lines = 0, uncovered_lines = 0 }

	for key, info in pairs(files) do
		if type(key) == "string" and key ~= "" then
			local full = vim.fn.fnamemodify(key, ":p")
			coverage_files_by_path[full] = info
			local base = vim.fn.fnamemodify(full, ":t")
			if coverage_files_by_basename[base] == nil then
				coverage_files_by_basename[base] = info
			end
		end
	end

	-- Compute totals (best-effort).
	for _, info in pairs(coverage_files_by_path) do
		local executed_list, missing_list = extract_executed_and_missing(info)
		local exec_set = list_to_set(executed_list)
		local miss_set = list_to_set(missing_list)

		local covered = 0
		for lnum, _ in pairs(exec_set) do
			if not miss_set[lnum] then
				covered = covered + 1
			end
		end

		local uncovered = 0
		for lnum, _ in pairs(miss_set) do
			if not exec_set[lnum] then
				uncovered = uncovered + 1
			end
		end

		totals.covered_lines = totals.covered_lines + covered
		totals.uncovered_lines = totals.uncovered_lines + uncovered
		totals.total_lines = totals.total_lines + covered + uncovered
	end

	return true
end

local function place_for_buf(bufnr, file_info)
	if file_info == nil or type(file_info) ~= "table" then
		return
	end

	remove_buf(bufnr)

	local executed_list, missing_list = extract_executed_and_missing(file_info)
	local exec_set = list_to_set(executed_list)
	local miss_set = list_to_set(missing_list)

	local line_count = vim.api.nvim_buf_line_count(bufnr)
	local to_place = {}
	local placed_set = {}

	local covered_count = 0
	local uncovered_count = 0

	for lnum, _ in pairs(exec_set) do
		if not miss_set[lnum] and lnum <= line_count then
			table.insert(to_place, {
				id = lnum,
				group = ns,
				name = sign_covered,
				buffer = bufnr,
				lnum = lnum,
				priority = 10,
			})
			placed_set[lnum] = true
			covered_count = covered_count + 1
		end
	end

	for lnum, _ in pairs(miss_set) do
		if lnum <= line_count and not exec_set[lnum] then
			table.insert(to_place, {
				id = lnum,
				group = ns,
				name = sign_uncovered,
				buffer = bufnr,
				lnum = lnum,
				priority = 11,
			})
			placed_set[lnum] = true
			uncovered_count = uncovered_count + 1
		end
	end

	vim.fn.sign_placelist(to_place)
	placed[bufnr] = placed_set
end

function M.enable_all()
	if not visible then
		return
	end
	if vim.tbl_isempty(coverage_files_by_path) and vim.tbl_isempty(coverage_files_by_basename) then
		return
	end

	for _, bufnr in ipairs(get_py_bufnrs()) do
		local bufname = vim.api.nvim_buf_get_name(bufnr)
		if bufname ~= "" and buf_extension(bufnr) == "py" then
			local full = vim.fn.fnamemodify(bufname, ":p")
			local base = vim.fn.fnamemodify(full, ":t")
			local info = coverage_files_by_path[full] or coverage_files_by_basename[base]
			place_for_buf(bufnr, info)
		end
	end
end

local function total_percent()
	if totals.total_lines <= 0 then
		return nil
	end
	return (totals.covered_lines / totals.total_lines) * 100
end

function M.toggle(show)
	if show == nil then
		show = not visible
	end

	if show == false or visible == true and show == nil then
		M.remove_all()
		return
	end

	local cwd = vim.fn.getcwd()
	covfn = covfn or (cwd .. "/cover.py.json")

	if vim.fn.filereadable(covfn) ~= 1 then
		vim.notify("No cover file found: " .. covfn, vim.log.levels.WARN)
		return
	end

	if not load_cov(covfn) then
		vim.notify("Failed to read/parse coverage json: " .. covfn, vim.log.levels.WARN)
		return
	end

	visible = true
	define_signs()
	M.enable_all()

	local pct = total_percent()
	if pct ~= nil then
		vim.notify(string.format("Python coverage: %.1f%%", pct), vim.log.levels.INFO)
	end
end

local function is_test_file(abs_path)
	-- Basic heuristics: pytest will pick these up.
	-- test_*.py or *_test.py at any depth.
	return abs_path:match("(/|^)test_.*%.py$") ~= nil or abs_path:match("(/|^).*_test%.py$") ~= nil
end

function M.run(...)
	define_signs()

	local args = { ... }
	local pwd = vim.fn.getcwd()

	-- Defaults (match go.nvim-ish behavior: write a cover file into cwd).
	covfn = covfn or (pwd .. "/cover.py.json")
	local cov_target = "."

	local pytest_args = {}
	local i = 1
	while i <= #args do
		local a = args[i]
		if a == "-t" then
			return M.toggle(true)
		elseif a == "-r" then
			local bufnr = vim.api.nvim_get_current_buf()
			if vim.fn.fnamemodify(vim.api.nvim_buf_get_name(bufnr), ":e") == "py" then
				remove_buf(bufnr)
			end
			visible = false
			return
		elseif a == "-R" then
			return M.remove_all()
		elseif a == "-f" then
			local next_val = args[i + 1]
			if type(next_val) == "string" and next_val ~= "" then
				covfn = next_val
				i = i + 1
			end
		elseif a == "-p" then
			-- Cover current file's directory by default; allow override: -p <target>
			local next_val = args[i + 1]
			if next_val ~= nil and type(next_val) == "string" and next_val ~= "" and next_val:sub(1, 1) ~= "-" then
				cov_target = next_val
				i = i + 1
			else
				cov_target = vim.fn.expand("%:p:h")
			end
		else
			-- Remaining args are passed to pytest.
			for j = i, #args do
				table.insert(pytest_args, args[j])
			end
			break
		end
		i = i + 1
	end

	local test_selection = {}
	if #pytest_args > 0 then
		test_selection = pytest_args
	else
		local current = vim.fn.expand("%:p")
		if current ~= "" and is_test_file(current) then
			test_selection = { current }
		else
			test_selection = { "." }
		end
	end

	local cmd = {
		"pytest",
		"--cov=" .. cov_target,
		"--cov-report=term-missing",
		"--cov-report=json:" .. covfn,
	}
	cmd = vim.list_extend(cmd, test_selection)

	local lines = {}
	visible = true

	vim.fn.jobstart(cmd, {
		on_stdout = function(_, data, _)
			data = vim.fn.extend(data or {}, {})
			if data and #data > 0 then
				vim.list_extend(lines, data)
			end
		end,
		on_stderr = function(_, data, _)
			data = vim.fn.extend(data or {}, {})
			if data and #data > 0 then
				vim.list_extend(lines, data)
			end
		end,
		on_exit = function(_, code, event)
			if event ~= "exit" and code ~= 0 then
				vim.notify("PyCoverage failed (event=" .. tostring(event) .. ", exit=" .. tostring(code) .. ")", vim.log.levels.WARN)
			end

			if vim.fn.filereadable(covfn) == 1 and load_cov(covfn) then
				M.enable_all()
				local pct = total_percent()
				if pct ~= nil then
					vim.notify(string.format("Python coverage: %.1f%%", pct), vim.log.levels.INFO)
				end
			else
				visible = false
				vim.notify("Coverage json not found or failed to parse: " .. covfn, vim.log.levels.WARN)
			end

			-- Show pytest output in quickfix as a simple "results" panel.
			if lines == nil then
				lines = {}
			end
			vim.fn.setqflist({}, " ", {
				title = "PyCoverage: " .. tostring(table.concat(cmd, " ")),
				lines = lines,
			})
			vim.cmd("copen")
		end,
	})
end

function M.setup()
	if did_setup then
		return
	end
	did_setup = true

	define_signs()

	local au = vim.api.nvim_create_autocmd
	vim.api.nvim_create_augroup(augroup_name, { clear = true })

	au({ "ColorScheme" }, {
		group = augroup_name,
		pattern = "*.py",
		callback = function()
			define_signs()
			if visible then
				M.enable_all()
			end
		end,
	})

	au({ "BufWinEnter" }, {
		group = augroup_name,
		pattern = "*.py",
		callback = function()
			if visible then
				M.enable_all()
			end
		end,
	})

	au({ "BufWinLeave" }, {
		group = augroup_name,
		pattern = "*.py",
		callback = function(ev)
			if visible then
				remove_buf(ev.buf)
			end
		end,
	})

	vim.api.nvim_create_user_command("PyCoverage", function(opts)
		M.run(unpack(opts.fargs))
	end, {
		nargs = "*",
		desc = "Run pytest with coverage and show line coverage in buffers",
	})

	-- Handy alias (matches the user's wording "PyTest coverage").
	vim.api.nvim_create_user_command("PyTestCoverage", function(opts)
		M.run(unpack(opts.fargs))
	end, {
		nargs = "*",
		desc = "Alias for PyCoverage",
	})
end

return M

