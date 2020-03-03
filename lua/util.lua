-- Try to overwrite some util function

local protocol = require 'vim.lsp.protocol'
local vim = vim
local validate = vim.validate
local api = vim.api
local all_buffer_diagnostics = {}
local M ={}
local split = vim.split
local function split_lines(value)
  return split(value, '\n', true)
end

local function highlight_range(bufnr, ns, hiname, start, finish)
  if start[1] == finish[1] then
    api.nvim_buf_add_highlight(bufnr, ns, hiname, start[1], start[2], finish[2])
  else
    api.nvim_buf_add_highlight(bufnr, ns, hiname, start[1], start[2], -1)
    for line = start[1] + 1, finish[1] - 1 do
      api.nvim_buf_add_highlight(bufnr, ns, hiname, line, 0, -1)
    end
    api.nvim_buf_add_highlight(bufnr, ns, hiname, finish[1], 0, finish[2])
  end
end

local diagnostic_ns = api.nvim_create_namespace("vim_lsp_diagnostics")
local reference_ns = api.nvim_create_namespace("vim_lsp_references")
local sign_ns = 'vim_lsp_signs'
local underline_highlight_name = "LspDiagnosticsUnderline"
vim.cmd(string.format("highlight default %s gui=underline cterm=underline", underline_highlight_name))
for kind, _ in pairs(protocol.DiagnosticSeverity) do
  if type(kind) == 'string' then
    vim.cmd(string.format("highlight default link %s%s %s", underline_highlight_name, kind, underline_highlight_name))
  end
end

local severity_highlights = {}

local default_severity_highlight = {
  [protocol.DiagnosticSeverity.Error] = { guifg = "Red" };
  [protocol.DiagnosticSeverity.Warning] = { guifg = "Orange" };
  [protocol.DiagnosticSeverity.Information] = { guifg = "LightBlue" };
  [protocol.DiagnosticSeverity.Hint] = { guifg = "LightGrey" };
}

-- Initialize default severity highlights
for severity, hi_info in pairs(default_severity_highlight) do
  local severity_name = protocol.DiagnosticSeverity[severity]
  local highlight_name = "LspDiagnostics"..severity_name
  -- Try to fill in the foreground color with a sane default.
  local cmd_parts = {"highlight", "default", highlight_name}
  for k, v in pairs(hi_info) do
    table.insert(cmd_parts, k.."="..v)
  end
  api.nvim_command(table.concat(cmd_parts, ' '))
  severity_highlights[severity] = highlight_name
end

function M.buf_clear_diagnostics(bufnr)
  validate { bufnr = {bufnr, 'n', true} }
  bufnr = bufnr == 0 and api.nvim_get_current_buf() or bufnr

  -- clear sign group
  vim.fn.sign_unplace(sign_ns, {buffer=bufnr})

  -- clear virtual text namespace
  api.nvim_buf_clear_namespace(bufnr, diagnostic_ns, 0, -1)
end


function M.open_floating_preview(contents, filetype, opts)
  validate {
    contents = { contents, 't' };
    filetype = { filetype, 's', true };
    opts = { opts, 't', true };
  }
  opts = opts or {}

  -- Trim empty lines from the end.
  contents = vim.lsp.util.trim_empty_lines(contents)

  local width = opts.width
  local height = opts.height or #contents
  if not width then
    width = 0
    for i, line in ipairs(contents) do
      -- Clean up the input and add left pad.
      line = " "..line:gsub("\r", "")
      -- TODO(ashkan) use nvim_strdisplaywidth if/when that is introduced.
      local line_width = vim.fn.strdisplaywidth(line)
      width = math.max(line_width, width)
      contents[i] = line
    end
    -- Add right padding of 1 each.
    width = width + 1
  end

  local floating_bufnr = api.nvim_create_buf(false, true)
  if filetype then
    api.nvim_buf_set_option(floating_bufnr, 'filetype', filetype)
  end
  local float_option = vim.lsp.util.make_floating_popup_options(width, height, opts)
  local floating_winnr = api.nvim_open_win(floating_bufnr, false, float_option)
  if filetype == 'markdown' then
    api.nvim_win_set_option(floating_winnr, 'conceallevel', 2)
  end
  api.nvim_buf_set_lines(floating_bufnr, 0, -1, true, contents)
  api.nvim_buf_set_option(floating_bufnr, 'modifiable', false)
  -- Disable InsertCharPre
  api.nvim_command("autocmd CursorMoved,BufHidden <buffer> ++once lua pcall(vim.api.nvim_win_close, "..floating_winnr..", true)")
  return floating_bufnr, floating_winnr
end


function M.get_severity_highlight_name(severity)
  return severity_highlights[severity]
end

function M.show_line_diagnostics()
  local bufnr = api.nvim_get_current_buf()
  local line = api.nvim_win_get_cursor(0)[1] - 1
  -- local marks = api.nvim_buf_get_extmarks(bufnr, diagnostic_ns, {line, 0}, {line, -1}, {})
  -- if #marks == 0 then
  --   return
  -- end
  -- local buffer_diagnostics = all_buffer_diagnostics[bufnr]
  local lines = {"Diagnostics:"}
  local highlights = {{0, "Bold"}}

  local buffer_diagnostics = all_buffer_diagnostics[bufnr]
  if not buffer_diagnostics then return end
  local line_diagnostics = buffer_diagnostics[line]
  if not line_diagnostics then return end

  for i, diagnostic in ipairs(line_diagnostics) do
  -- for i, mark in ipairs(marks) do
  --   local mark_id = mark[1]
  --   local diagnostic = buffer_diagnostics[mark_id]

    -- TODO(ashkan) make format configurable?
    local prefix = string.format("%d. ", i)
    local hiname = severity_highlights[diagnostic.severity]
    local message_lines = split_lines(diagnostic.message)
    table.insert(lines, prefix..message_lines[1])
    table.insert(highlights, {#prefix + 1, hiname})
    for j = 2, #message_lines do
      table.insert(lines, message_lines[j])
      table.insert(highlights, {0, hiname})
    end
  end
  local popup_bufnr, winnr = M.open_floating_preview(lines, 'plaintext')
  for i, hi in ipairs(highlights) do
    local prefixlen, hiname = unpack(hi)
    -- Start highlight after the prefix
    api.nvim_buf_add_highlight(popup_bufnr, -1, hiname, i-1, prefixlen, -1)
  end
  return popup_bufnr, winnr
end

function M.buf_diagnostics_save_positions(bufnr, diagnostics)
  validate {
    bufnr = {bufnr, 'n', true};
    diagnostics = {diagnostics, 't', true};
  }
  if not diagnostics then return end
  bufnr = bufnr == 0 and api.nvim_get_current_buf() or bufnr

  if not all_buffer_diagnostics[bufnr] then
    -- Clean up our data when the buffer unloads.
    api.nvim_buf_attach(bufnr, false, {
      on_detach = function(b)
        all_buffer_diagnostics[b] = nil
      end
    })
  end
  all_buffer_diagnostics[bufnr] = {}
  local buffer_diagnostics = all_buffer_diagnostics[bufnr]

  for _, diagnostic in ipairs(diagnostics) do
    local start = diagnostic.range.start
    -- local mark_id = api.nvim_buf_set_extmark(bufnr, diagnostic_ns, 0, start.line, 0, {})
    -- buffer_diagnostics[mark_id] = diagnostic
    local line_diagnostics = buffer_diagnostics[start.line]
    if not line_diagnostics then
      line_diagnostics = {}
      buffer_diagnostics[start.line] = line_diagnostics
    end
    table.insert(line_diagnostics, diagnostic)
  end
end

function M.buf_diagnostics_underline(bufnr, diagnostics)
  for _, diagnostic in ipairs(diagnostics) do
    local start = diagnostic.range["start"]
    local finish = diagnostic.range["end"]

    local hlmap = {
      [protocol.DiagnosticSeverity.Error]='Error',
      [protocol.DiagnosticSeverity.Warning]='Warning',
      [protocol.DiagnosticSeverity.Information]='Information',
      [protocol.DiagnosticSeverity.Hint]='Hint',
    }

    -- TODO care about encoding here since this is in byte index?
    highlight_range(bufnr, diagnostic_ns,
      underline_highlight_name..hlmap[diagnostic.severity],
      {start.line, start.character},
      {finish.line, finish.character}
    )
  end
end

function M.buf_clear_references(bufnr)
  validate { bufnr = {bufnr, 'n', true} }
  api.nvim_buf_clear_namespace(bufnr, reference_ns, 0, -1)
end

function M.buf_highlight_references(bufnr, references)
  validate { bufnr = {bufnr, 'n', true} }
  for _, reference in ipairs(references) do
    local start_pos = {reference["range"]["start"]["line"], reference["range"]["start"]["character"]}
    local end_pos = {reference["range"]["end"]["line"], reference["range"]["end"]["character"]}
    local document_highlight_kind = {
      [protocol.DocumentHighlightKind.Text] = "LspReferenceText";
      [protocol.DocumentHighlightKind.Read] = "LspReferenceRead";
      [protocol.DocumentHighlightKind.Write] = "LspReferenceWrite";
    }
    highlight_range(bufnr, reference_ns, document_highlight_kind[reference["kind"]], start_pos, end_pos)

  end
end

function M.buf_diagnostics_virtual_text(bufnr, diagnostics)
  local buffer_line_diagnostics = all_buffer_diagnostics[bufnr]
  local prefix = api.nvim_get_var('diagnostic_virtual_text_prefix')
  local spaces = string.rep(" ", api.nvim_get_var('space_before_virtual_text'))
  if not buffer_line_diagnostics then
    M.buf_diagnostics_save_positions(bufnr, diagnostics)
  end
  buffer_line_diagnostics = all_buffer_diagnostics[bufnr]
  if not buffer_line_diagnostics then
    return
  end
  for line, line_diags in pairs(buffer_line_diagnostics) do
    local virt_texts = {}
    table.insert(virt_texts, {spaces})
    for i = 1, #line_diags - 1 do
      table.insert(virt_texts, {prefix, severity_highlights[line_diags[i].severity]})
    end
    local last = line_diags[#line_diags]
    -- TODO(ashkan) use first line instead of subbing 2 spaces?
    if api.nvim_get_var('diagnostic_trimmed_virtual_text') ~= nil then
      local trimmed_text = last.message:gsub("\r", ""):gsub("\n", "  ")
      trimmed_text = string.sub(trimmed_text, 1, api.nvim_get_var('diagnostic_trimmed_virtual_text'))
      if #trimmed_text == api.nvim_get_var('diagnostic_trimmed_virtual_text') then
        trimmed_text = trimmed_text.."..."
      end
      table.insert(virt_texts, {prefix.." "..trimmed_text, severity_highlights[last.severity]})
    else
      table.insert(virt_texts, {prefix.." "..last.message:gsub("\r", ""):gsub("\n", "  "), severity_highlights[last.severity]})
    end
    api.nvim_buf_set_virtual_text(bufnr, diagnostic_ns, line, virt_texts, {})
  end
end

function M.buf_diagnostics_count(kind)
  local bufnr = vim.api.nvim_get_current_buf()
  local buffer_line_diagnostics = all_buffer_diagnostics[bufnr]
  if not buffer_line_diagnostics then return end
  local count = 0
  for _, line_diags in pairs(buffer_line_diagnostics) do
    for _, diag in ipairs(line_diags) do
      if protocol.DiagnosticSeverity[kind] == diag.severity then count = count + 1 end
    end
  end
  return count
end

function M.buf_diagnostics_signs(bufnr, diagnostics)
  vim.fn.sign_define('LspDiagnosticsErrorSign', {text=vim.g['LspDiagnosticsErrorSign'] or 'E', texthl='LspDiagnosticsError', linehl='', numhl=''})
  vim.fn.sign_define('LspDiagnosticsWarningSign', {text=vim.g['LspDiagnosticsWarningSign'] or 'W', texthl='LspDiagnosticsWarning', linehl='', numhl=''})
  vim.fn.sign_define('LspDiagnosticsInformationSign', {text=vim.g['LspDiagnosticsInformationSign'] or 'I', texthl='LspDiagnosticsInformation', linehl='', numhl=''})
  vim.fn.sign_define('LspDiagnosticsHintSign', {text=vim.g['LspDiagnosticsHintSign'] or 'H', texthl='LspDiagnosticsHint', linehl='', numhl=''})

  for _, diagnostic in ipairs(diagnostics) do
    local diagnostic_severity_map = {
      [protocol.DiagnosticSeverity.Error] = "LspDiagnosticsErrorSign";
      [protocol.DiagnosticSeverity.Warning] = "LspDiagnosticsWarningSign";
      [protocol.DiagnosticSeverity.Information] = "LspDiagnosticsInformationSign";
      [protocol.DiagnosticSeverity.Hint] = "LspDiagnosticsHintSign";
    }
    vim.fn.sign_place(0, sign_ns, diagnostic_severity_map[diagnostic.severity], bufnr, {lnum=(diagnostic.range.start.line+1)})
  end
end

return M
