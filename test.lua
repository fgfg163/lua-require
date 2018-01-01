useNlog = true
require 'console'
local os_exit = require 'touchsprite-exit-hock'
require('lua-require')({
  os_exit = os_exit
})

require './subfolder/test2.lua'
--console.log(string.gsub('/a/b/c/d/e.test', '/[^/]*$', ''))
