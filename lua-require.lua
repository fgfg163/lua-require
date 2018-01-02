local originRequire = require
local _ENV = _ENV

do
  string.split = string.split or function(str, d)
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

local path = (function()
  local path = {}
  path.separator = string.find(package.path, '/') and '/' or '\\'
  path.basename = function(thePath)
    local thePathArray = string.split(thePath, path.separator)
    local res = table.remove(thePathArray)
    return res
  end
  path.dirname = function(thePath)
    local thePathArray = string.split(thePath, path.separator)
    table.remove(thePathArray)
    return table.concat(thePathArray, path.separator)
  end
  path.extname = function()
  end
  path.join = function()
  end
  path.relative = function()
  end
  path.resolve = function(...)
    local pathArray = { ... }
    local resultPathArray = {}
    for key = 1, #pathArray do
      local thePath = string.gsub(pathArray[key], '\\', '/')
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

    local requirePath = path.resolve(path.dirname(filePath), loadpath)
    local requirePathKey = string.gsub(requirePath, basePath, '')

    if not package.loaded[requirePathKey] then
      if not package.preload[requirePathKey] then
        local file
        local requireSource
        local res, err = pcall(function()
          file = io.open(requirePath, 'r')
          requireSource = file:read('*a')
        end)
        if not res then
          error('file \'' .. requirePath .. '\' not exist', 2)
        end
        if file then
          file.close()
        end
        requireSource = 'local require, modePath = ...; ' .. requireSource
        package.preload[requirePathKey] = assert(load(requireSource, '@' .. requirePath, 'bt', _ENV))
      end
      package.loaded[requirePathKey] = package.preload[requirePathKey](requireFactory(requirePath), requirePath) or true
    end
    return package.loaded[requirePathKey]
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
    require = requireFactory(filePath)
  end
end