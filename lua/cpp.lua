-- C/C++ helpers: compile_commands.json discovery for clangd (CMake + Makefile).
local M = {}

local BUILD_DIR_CANDIDATES = {
	"build",
	"Build",
	"out",
	"cmake-build-debug",
	"cmake-build-release",
	"cmake-build-relwithdebinfo",
	"debug",
	"release",
}

local function notify(msg, level)
	vim.notify(msg, level or vim.log.levels.INFO, { title = "CppCompileDb" })
end

---@return string|nil
local function find_root(start)
	start = start or vim.api.nvim_buf_get_name(0)
	if start == "" then
		start = vim.fn.getcwd()
	end
	return vim.fs.root(start, {
		"compile_commands.json",
		"CMakeLists.txt",
		"Makefile",
		"makefile",
		"GNUmakefile",
		".clangd",
		".git",
	})
end

---@param root string
---@return "cmake"|"make"|nil
local function detect_build_system(root)
	if vim.fn.filereadable(root .. "/CMakeLists.txt") == 1 then
		return "cmake"
	end
	for _, name in ipairs({ "Makefile", "makefile", "GNUmakefile" }) do
		if vim.fn.filereadable(root .. "/" .. name) == 1 then
			return "make"
		end
	end
	return nil
end

--- Directory that contains compile_commands.json (project root or a build dir).
---@param root string|nil
---@return string|nil
function M.find_compile_commands_dir(root)
	root = root or find_root()
	if not root then
		return nil
	end
	if vim.fn.filereadable(root .. "/compile_commands.json") == 1 then
		return root
	end
	for _, dir in ipairs(BUILD_DIR_CANDIDATES) do
		local candidate = root .. "/" .. dir
		if vim.fn.filereadable(candidate .. "/compile_commands.json") == 1 then
			return candidate
		end
	end
	return nil
end

---@param root string
---@param db_path string absolute path to compile_commands.json
---@return boolean, string|nil
local function link_compile_commands(root, db_path)
	local dest = root .. "/compile_commands.json"
	if vim.fn.filereadable(db_path) ~= 1 then
		return false, "compile_commands.json was not created at " .. db_path
	end
	if vim.fn.filereadable(dest) == 1 and vim.fn.resolve(dest) == vim.fn.resolve(db_path) then
		return true
	end
	-- Prefer symlink so regenerating the build dir stays in sync.
	vim.fn.delete(dest)
	local ok = vim.uv.fs_symlink(db_path, dest)
	if not ok then
		vim.fn.writefile(vim.fn.readfile(db_path), dest)
	end
	return true
end

--- Write/update a minimal .clangd pointing at a compilation database directory.
---@param root string
---@param db_dir string absolute directory containing compile_commands.json
local function write_clangd_config(root, db_dir)
	local rel = db_dir
	if vim.startswith(db_dir, root .. "/") then
		rel = db_dir:sub(#root + 2)
	end
	-- Only manage a tiny generated block; don't clobber a custom .clangd.
	local path = root .. "/.clangd"
	local marker = "# generated-by-nvim-cpp-compile-db"
	if vim.fn.filereadable(path) == 1 then
		local existing = table.concat(vim.fn.readfile(path), "\n")
		if not existing:find(marker, 1, true) then
			return -- user-owned config
		end
	end
	vim.fn.writefile({
		marker,
		"CompileFlags:",
		"  CompilationDatabase: " .. rel,
	}, path)
end

local function run(cmd, cwd, on_exit)
	notify("Running: " .. table.concat(cmd, " "))
	vim.system(cmd, { cwd = cwd, text = true }, function(result)
		vim.schedule(function()
			on_exit(result)
		end)
	end)
end

local function restart_clangd()
	local ok = pcall(vim.cmd, "LspRestart clangd")
	if not ok then
		for _, client in ipairs(vim.lsp.get_clients({ name = "clangd" })) do
			client:stop(true)
		end
		vim.defer_fn(function()
			vim.cmd("edit")
		end, 200)
	end
end

--- If compile_commands.json lives under build/, expose it at the project root
--- (symlink + .clangd) so clangd actually uses the project's -std=... flags.
---@param silent boolean|nil
---@return boolean changed
function M.ensure_compile_commands(silent)
	local root = find_root()
	if not root then
		return false
	end

	local db_dir = M.find_compile_commands_dir(root)
	if not db_dir or db_dir == root then
		return false
	end

	local db_path = db_dir .. "/compile_commands.json"
	local root_db = root .. "/compile_commands.json"
	local changed = false

	local already_linked = vim.fn.filereadable(root_db) == 1
		and vim.fn.resolve(root_db) == vim.fn.resolve(db_path)
	if not already_linked then
		local ok = select(1, link_compile_commands(root, db_path))
		if ok then
			changed = true
		end
	end

	local clangd_path = root .. "/.clangd"
	local marker = "# generated-by-nvim-cpp-compile-db"
	local needs_clangd = true
	if vim.fn.filereadable(clangd_path) == 1 then
		local existing = table.concat(vim.fn.readfile(clangd_path), "\n")
		if not existing:find(marker, 1, true) then
			needs_clangd = false -- user-owned
		else
			local rel = db_dir
			if vim.startswith(db_dir, root .. "/") then
				rel = db_dir:sub(#root + 2)
			end
			if existing:find("CompilationDatabase: " .. rel, 1, true) then
				needs_clangd = false
			end
		end
	end
	if needs_clangd then
		write_clangd_config(root, db_dir)
		changed = true
	end

	if changed and not silent then
		notify("Using compilation database: " .. db_path)
	end
	return changed
end

local function generate_cmake(root)
	local existing = root .. "/build/compile_commands.json"
	if vim.fn.filereadable(existing) == 1 then
		local ok, err = link_compile_commands(root, existing)
		if not ok then
			notify(err, vim.log.levels.ERROR)
			return
		end
		write_clangd_config(root, root .. "/build")
		notify("Linked existing build/compile_commands.json. Restarting clangd.")
		restart_clangd()
		return
	end

	if vim.fn.executable("cmake") ~= 1 then
		notify("cmake not found in PATH", vim.log.levels.ERROR)
		return
	end

	local build = root .. "/build"
	vim.fn.mkdir(build, "p")

	run({
		"cmake",
		"-S",
		root,
		"-B",
		build,
		"-DCMAKE_EXPORT_COMPILE_COMMANDS=ON",
	}, root, function(result)
		if result.code ~= 0 then
			notify("cmake failed:\n" .. (result.stderr or result.stdout or ""), vim.log.levels.ERROR)
			return
		end
		local ok, err = link_compile_commands(root, build .. "/compile_commands.json")
		if not ok then
			notify(err, vim.log.levels.ERROR)
			return
		end
		write_clangd_config(root, build)
		notify("Linked compile_commands.json from build/ (CMake). Restarting clangd.")
		restart_clangd()
	end)
end

local function generate_make(root)
	-- Prefer compiledb dry-run (no rebuild). Fall back to bear (intercepts a real make).
	if vim.fn.executable("compiledb") == 1 then
		run({ "compiledb", "-n", "make" }, root, function(result)
			if result.code ~= 0 then
				notify("compiledb failed:\n" .. (result.stderr or result.stdout or ""), vim.log.levels.ERROR)
				return
			end
			if vim.fn.filereadable(root .. "/compile_commands.json") ~= 1 then
				notify("compiledb finished but compile_commands.json is missing", vim.log.levels.ERROR)
				return
			end
			notify("Generated compile_commands.json via compiledb. Restarting clangd.")
			restart_clangd()
		end)
		return
	end

	if vim.fn.executable("bear") == 1 then
		local cmd = { "bear", "--", "make" }
		if vim.fn.filereadable(root .. "/compile_commands.json") == 1 then
			cmd = { "bear", "--append", "--", "make" }
		end
		run(cmd, root, function(result)
			if result.code ~= 0 then
				notify("bear -- make failed:\n" .. (result.stderr or result.stdout or ""), vim.log.levels.ERROR)
				return
			end
			if vim.fn.filereadable(root .. "/compile_commands.json") ~= 1 then
				notify("bear finished but compile_commands.json is missing", vim.log.levels.ERROR)
				return
			end
			notify("Generated compile_commands.json via bear. Restarting clangd.")
			restart_clangd()
		end)
		return
	end

	notify(
		"No Makefile compile DB tool found. Install one of:\n"
			.. "  pipx install compiledb   (preferred: dry-run, no rebuild)\n"
			.. "  brew install bear         (intercepts a real `make`)\n"
			.. "Then re-run :CppCompileDb",
		vim.log.levels.ERROR
	)
end

--- Generate / refresh compile_commands.json from CMake or Makefile, then restart clangd.
function M.compile_db()
	local root = find_root()
	if not root then
		notify("Could not find project root", vim.log.levels.ERROR)
		return
	end

	local kind = detect_build_system(root)
	if kind == "cmake" then
		notify("Detected CMake project at " .. root)
		generate_cmake(root)
	elseif kind == "make" then
		notify("Detected Makefile project at " .. root)
		generate_make(root)
	else
		notify(
			"No CMakeLists.txt or Makefile in "
				.. root
				.. ".\n"
				.. "Add one, or place a compile_commands.json / .clangd config there.",
			vim.log.levels.WARN
		)
	end
end

--- Show which compilation database / -std flag applies to the current file.
function M.info()
	local root = find_root()
	local lines = {}
	table.insert(lines, "root: " .. (root or "(none)"))

	local db_dir = M.find_compile_commands_dir(root)
	table.insert(lines, "compile_commands dir: " .. (db_dir or "(none)"))

	local bufname = vim.api.nvim_buf_get_name(0)
	if db_dir and bufname ~= "" then
		local db_path = db_dir .. "/compile_commands.json"
		local ok, data = pcall(function()
			return vim.json.decode(table.concat(vim.fn.readfile(db_path), "\n"))
		end)
		if ok and type(data) == "table" then
			local abs = vim.fn.fnamemodify(bufname, ":p")
			local found = nil
			for _, entry in ipairs(data) do
				if type(entry) == "table" and type(entry.file) == "string" then
					local entry_abs = vim.fn.fnamemodify(entry.file, ":p")
					if entry_abs == abs or entry.file:find(vim.fn.fnamemodify(bufname, ":t"), 1, true) then
						found = entry
						if entry_abs == abs then
							break
						end
					end
				end
			end
			if found then
				local cmd = found.command or table.concat(found.arguments or {}, " ")
				table.insert(lines, "db entry: " .. (found.file or "?"))
				local std = cmd:match("%-std=%S+") or cmd:match("%-std%S+")
				table.insert(lines, "standard flag: " .. (std or "(none in command — check CMAKE_CXX_STANDARD)"))
				table.insert(lines, "command: " .. cmd)
			else
				table.insert(lines, "db entry: (current file not listed — clangd will use fallback flags)")
			end
		else
			table.insert(lines, "failed to parse compile_commands.json")
		end
	end

	notify(table.concat(lines, "\n"), vim.log.levels.INFO)
end

function M.setup()
	vim.api.nvim_create_user_command("CppCompileDb", function()
		M.compile_db()
	end, {
		desc = "Generate/link compile_commands.json from CMake or Makefile for clangd",
	})

	vim.api.nvim_create_user_command("CppCompileDbInfo", function()
		M.info()
	end, {
		desc = "Show which compile_commands.json / -std applies to the current file",
	})

	-- Auto-expose build/compile_commands.json so clangd picks up -std=c++11 etc.
	vim.api.nvim_create_autocmd("FileType", {
		pattern = { "c", "cpp", "objc", "objcpp", "cuda" },
		callback = function()
			local changed = M.ensure_compile_commands(true)
			if changed then
				-- Restart only if clangd is already attached (otherwise first start will see the link).
				local clients = vim.lsp.get_clients({ name = "clangd", bufnr = 0 })
				if #clients > 0 then
					restart_clangd()
				end
			end
		end,
	})
end

return M
