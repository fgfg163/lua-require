local originRequire = require
local _ENV = _ENV

do
  string.split = string.split or function(str, d)
    if str == '' and d ~= '' then
      return { str }
    elseif str ~= '' and d == '' then
      local lst = {}
      for key = 1, string.len(str) do
        table.insert(lst, string.sub(str, key, 1))
      end
      return lst
    else
      local lst = {}
      local n = string.len(str) --长度
      local start = 1
      while start <= n do
        local i = string.find(str, d, start) -- find 'next' 0
        if i == nil then
          table.insert(lst, string.sub(str, start, n))
          break
        end
        table.insert(lst, string.sub(str, start, i - 1))
        if i == n then
          table.insert(lst, "")
          break
        end
        start = i + 1
      end
      return lst
    end
  end
end

local path = (function()
  local path = {}
  path.separator = string.find(package.path, '/') and '/' or '\\'
  path.basename = function(thePath)
    thePath = string.gsub(thePath, '\\', '/')
    local thePathArray = string.split(thePath, '/')
    local res = table.remove(thePathArray)
    return res
  end
  path.dirname = function(thePath)
    thePath = string.gsub(thePath, '\\', '/')
    local thePathArray = string.split(thePath, '/')
    table.remove(thePathArray)
    return table.concat(thePathArray, path.separator)
  end
  path.extname = function()
  end
  path.join = function(...)
    local pathArray = { ... }
    local resultPathArray = {}
    for key = 1, #pathArray do
      if pathArray[key] ~= '' then
        local thePath = string.gsub(pathArray[key], '\\', '/')
        local thePathArray = string.split(thePath, '/')
        for key2 = 1, #thePathArray do
          local theName = thePathArray[key2]
          if theName == '' and #resultPathArray > 0 then
          elseif theName == '.' and #resultPathArray > 0 then
          elseif theName == '..' and #resultPathArray == 1 and resultPathArray[1] == '' then
            table.remove(resultPathArray)
          elseif theName == '..' and #resultPathArray == 1 and resultPathArray[1] == '.' then
            resultPathArray = { '..' }
          elseif theName == '..' and #resultPathArray > 0 then
            table.remove(resultPathArray)
          else
            table.insert(resultPathArray, theName)
          end
        end
      end
    end
    return table.concat(resultPathArray, path.separator)
  end
  path.relative = function()
  end
  path.resolve = function(...)
    local pathArray = { ... }
    local resultPathArray = {}
    for key = 1, #pathArray do
      if pathArray[key] ~= '' then
        local thePath = string.gsub(string.gsub(pathArray[key], '\\', '/'), '/$', '')
        local thePathArray = string.split(thePath, '/')
        for key2 = 1, #thePathArray do
          local theName = thePathArray[key2]
          if theName == '' and key2 == 1 then
            resultPathArray = { '' }
          elseif theName == '.' and #resultPathArray > 0 then
          elseif theName == '..' and #resultPathArray == 1 and resultPathArray[1] == '' then
            table.remove(resultPathArray)
          elseif theName == '..' and #resultPathArray == 1 and resultPathArray[1] == '.' then
            resultPathArray = { '..' }
          elseif theName == '..' and #resultPathArray > 0 then
            table.remove(resultPathArray)
          else
            table.insert(resultPathArray, theName)
          end
        end
      end
    end
    return table.concat(resultPathArray, path.separator)
  end
  return path
end)()

local basePath = ''

local requireFactory
requireFactory = function(filePath)
  return function(loadpath)
    if type(loadpath) ~= 'string' then
      error('bad argument #1 to \'require\' (string expected, got ' .. type(loadpath) .. ')', 2)
    end

    local requirePath = path.resolve(filePath, loadpath)
    local absolutePath = path.join(basePath, requirePath)

    if not package.loaded[requirePath] then
      if not package.preload[requirePath] then
        local file
        local requireSource
        local res, err = pcall(function()
          file = io.open(absolutePath, 'r')
          requireSource = file:read('*a')
        end)
        if not res then
          error('file \'' .. absolutePath .. '\' not exist', 2)
        end
        if file then
          file.close()
        end
        requireSource = 'local require, modePath = ...; ' .. requireSource
        package.preload[requirePath] = assert(load(requireSource, '@' .. absolutePath, 'bt', _ENV))
      end
      package.loaded[requirePath] = package.preload[requirePath](requireFactory(path.dirname(requirePath)), requirePath) or true
    end
    return package.loaded[requirePath]
  end
end

return function()
  local result = debug.getinfo(2, 'S')
  if string.match(result.short_src, '%[string') then
    local newMain = string.gsub(result.source, '%.lua$', '')
    package.preload[newMain] = nil
    package.loaded[newMain] = nil
    originRequire(newMain)
    os.exit()
    return
  end

  if not _require then
    _require = require
    local filePath = string.gsub(result.source, '^@', '')
    basePath = path.dirname(filePath)
    require = requireFactory('/')
  end
end