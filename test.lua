useNlog = true
require 'console'
local os_exit = require 'touchsprite-exit-hock'
require('lua-require')({
  os_exit = os_exit
})

local socket = require 'socket'
console.log(socket)
