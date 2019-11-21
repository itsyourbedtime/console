-- console
-- @its_your_bedtime
--
-- basic stdout
--

local keyb = hid.connect()
local keycodes = include("lib/keycodes")
local wordarray, output, history, offset = {}, {}, {entries = {[0] = ''}, index = 0}, { x = 0, y = 0 }
local keyinput, keyoutput, prompt = "", "", "> "

function init()
  screen.aa(0)
  metro_redraw = metro.init(function(stage) redraw() end, 1 / 15)
  metro_redraw:start()
end

local function capture(cmd)
  local f = assert(io.popen(cmd, 'r'))
  table.insert(output, prompt .. cmd)
  table.insert(history.entries, 1, cmd)
  offset.x = 0 offset.y = 0 history.index = 0
  for line in f:lines() do table.insert(output, line) end
  f:close()
end

function enc(n,d)
  if n == 2 then 
    offset.x = util.clamp(offset.x - d, 0, (#output - 7))
  elseif n == 3 then 
    offset.y = util.clamp(offset.y + d, 0, 80)
  end
end

local function buildword()
    if keyinput ~= "Enter" then
      table.insert(wordarray,keyinput)
      keyoutput = table.concat(wordarray )
      if history.index > 0 then 
        keyoutput = history.entries[history.index]
      end
    else
      keyoutput = ""
      wordarray = {}
    end
end

local function get_key(code, val, shift)
  if keycodes.keys[code] ~= nil and val == 1 then 
    if (shift) then
      if keycodes.shifts[code] ~= nil then 
        --print (keycodes.shifts[code])
        return(keycodes.shifts[code])    
      else
        return(keycodes.keys[code])
      end
    else
      return(string.lower(keycodes.keys[code]))
    end
  elseif keycodes.cmds[code] ~= nil and val == 1 then 
    if (code == hid.codes.KEY_ENTER) then
      if history.index == 0 then keyoutput = table.concat(wordarray) end
      capture(keyoutput)
      wordarray = {}
    elseif (code == hid.codes.KEY_BACKSPACE or code == hid.codes.KEY_DELETE) then
      table.remove(wordarray)
    end
  end   
end 

function keyb.event(typ, code, val)
    if (code == hid.codes.KEY_LEFTSHIFT) and (val == 2) then
      shift = true;
    elseif (code == hid.codes.KEY_LEFTSHIFT) and (val == 0) then
      shift = false;
    elseif (code == hid.codes.KEY_UP) and (val == 1) then 
      history.index = util.clamp(history.index + 1, 0, #history.entries)
    elseif (code == hid.codes.KEY_DOWN) and (val == 1) then 
      history.index = util.clamp(history.index - 1, 0, #history.entries)
    end
    keyinput = get_key(code, val, shift)
    buildword(keyinput)
end

local function render_stdout(t)
  local line = 1
  screen.level(6)
  for i = #t - 8, #t do
    screen.move(0 - offset.y, (8 * line) - 18)
    screen.text(t[i - offset.x] or '')
    line = line + 1 % 8
  end
  screen.level(15)
  if #keyoutput > 29 then
    local offset =  (#keyoutput * 8 ) / 2
    screen.move(110 - offset, 62)
  else 
    screen.move(0, 62)
  end
  screen.text(prompt .. keyoutput or '')
end

function redraw()
  screen.clear()
  screen.font_face(25)
  screen.font_size(6)
  render_stdout(output) 
  screen.update()
end