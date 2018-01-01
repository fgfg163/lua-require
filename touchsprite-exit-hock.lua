if type(lua_exit) == 'function' and not lua_exit_added then
  lua_exit_added = true
  local exit = os.exit
  os.exit = function(...)
    lua_exit(...)
    exit(...)
  end
end
return os.exit
