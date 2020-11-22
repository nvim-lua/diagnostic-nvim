-- Try to overwrite some util function

local protocol = require 'vim.lsp.protocol'
local vim = vim
local validate = vim.validate
local api = vim.api
-- TODO change all_buffer_diagnostics to built-in
local all_buffer_diagnostics = {}
local M ={}
local split = vim.split
local function split_lines(value)
  return split(value, '\n', true)
end

local function highlight_range(bufnr, ns, hiname, start, finish)
  if start[2] < 0 or finish[2] < start[2] then return end
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

-- Get the built-in namespace and highlight
local diagnostic_ns = api.nvim_create_namespace("vim_lsp_diagnostics")
local sign_ns = 'vim_lsp_signs'
local underline_highlight_name = "LspDiagnosticsUnderline"

local severity_highlights = {
  [protocol.DiagnosticSeverity.Error] = "LspDiagnosticsError";
  [protocol.DiagnosticSeverity.Warning] = "LspDiagnosticsWarning";
  [protocol.DiagnosticSeverity.Information] = "LspDiagnosticsInformation";
  [protocol.DiagnosticSeverity.Hint] = "LspDiagnosticsHint";
}

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

function M.buf_diagnostics_virtual_text(bufnr, diagnostics)
  local prefix = api.nvim_get_var('diagnostic_virtual_text_prefix')
  local spaces = string.rep(" ", api.nvim_get_var('space_before_virtual_text'))
  M.buf_diagnostics_save_positions(bufnr, diagnostics)
  local buffer_line_diagnostics = all_buffer_diagnostics[bufnr]
  if not buffer_line_diagnostics then
    return
  end
  for line, line_diagnostics in pairs(buffer_line_diagnostics) do
    local virt_texts = {}
    table.insert(virt_texts, {spaces})
    local last = line_diagnostics[#line_diagnostics]
    for i = 1, #line_diagnostics - 1 do
      table.insert(virt_texts, {prefix, severity_highlights[line_diagnostics[i].severity]})
    end

    -- TODO(ashkan) use first line instead of subbing 2 spaces?
    if api.nvim_get_var('diagnostic_trimmed_virtual_text') ~= nil then
      local trimmed_text = last.message:gsub("\r", ""):gsub("\n", "  ")
      trimmed_text = string.sub(trimmed_text, 1, api.nvim_get_var('diagnostic_trimmed_virtual_text'))
      if (
        #trimmed_text == api.nvim_get_var('diagnostic_trimmed_virtual_text')
        and vim.g.diagnostic_trimmed_virtual_text ~= 0
        ) then
        trimmed_text = trimmed_text.."..."
      end
      table.insert(virt_texts, {prefix.." "..trimmed_text, severity_highlights[last.severity]})
    else
      table.insert(virt_texts, {prefix.." "..last.message:gsub("\r", ""):gsub("\n", "  "), severity_highlights[last.severity]})
    end
    api.nvim_buf_set_virtual_text(bufnr, diagnostic_ns, line, virt_texts, {})
  end
end

local function sort_by_key(fn)
  return function(a,b)
    local ka, kb = fn(a), fn(b)
    assert(#ka == #kb)
    for i = 1, #ka do
      if ka[i] ~= kb[i] then
        return ka[i] < kb[i]
      end
    end
    -- every value must have been equal here, which means it's not less than.
    return false
  end
end

local position_sort = sort_by_key(function(v)
  return {v.start.line, v.start.character}
end)


function M.locations_to_items(locations)
  local items = {}
  local grouped = setmetatable({}, {
    __index = function(t, k)
      local v = {}
      rawset(t, k, v)
      return v
    end;
  })
  local fname = api.nvim_buf_get_name(0)
  for _, d in ipairs(locations) do
    local range = d.range or d.targetSelectionRange
    table.insert(grouped[fname], {start = range.start, message = d.message})
  end


  local keys = vim.tbl_keys(grouped)
  table.sort(keys)
  local rows = grouped[fname]

  table.sort(rows, position_sort)
  local bufnr = vim.fn.bufnr()
  for _, temp in ipairs(rows) do
    local pos = temp.start
    local row = pos.line
    local line = api.nvim_buf_get_lines(0, row, row+1, false)[1]
    if line then
      local col
      if pos.character > #line then
        col = #line
      else
        col = vim.str_byteindex(line, pos.character)
      end

      table.insert(items, {
        bufnr = bufnr,
        lnum = row + 1,
        col = col + 1;
        text = temp.message
      })
    end
  end
  return items
end

function M.buf_diagnostics_signs(bufnr, diagnostics)
  for _, diagnostic in ipairs(diagnostics) do
    local diagnostic_severity_map = {
      [protocol.DiagnosticSeverity.Error] = "LspDiagnosticsErrorSign";
      [protocol.DiagnosticSeverity.Warning] = "LspDiagnosticsWarningSign";
      [protocol.DiagnosticSeverity.Information] = "LspDiagnosticsInformationSign";
      [protocol.DiagnosticSeverity.Hint] = "LspDiagnosticsHintSign";
    }
    pcall(
      vim.fn.sign_place,
      0, sign_ns, diagnostic_severity_map[diagnostic.severity], bufnr, {lnum=(diagnostic.range.start.line+1), priority=vim.g.diagnostic_sign_priority}
    )
  end
end

function M.align_diagnostic_indices(diagnostics)
  for idx, diagnostic in ipairs(diagnostics) do
    if diagnostic.range.start.character < 0 then diagnostic.range.start.character = 0 end
    if diagnostic.range['end'].character < 0 then diagnostic.range['end'].character = 0 end
  end
end

return M
