express = require "express"
timeout = null
users = {}



module.exports = (robot) ->

  timeoutFn = ->

  # serve js
  robot.router.use "/js", express.static "#{process.cwd()}/js"

  throw new Error 'HTTP server not available' unless (server = robot.server)?

  # Attach socket.io to http server and configure it.
  io = (require 'socket.io').listen server

  io.on 'connection', (socket)->

    socket.on 'disconnect', ->
      timeout = setTimeout ->
        robot.messageRoom '#dnilabs', "a user #{socket.user.uid} disconnected"
      , 3000

    socket.on 'initUser', (data)->
      clearTimout timeout
      user = users[data.uid]
      if user
        if user.msgs
          user.msgs.forEach (msg)->
            socket.emit 'message', msg
      else
        users[data.uid] = data
      socket.user = user
      robot.messageRoom '#dnilabs', "user dni views #{data.url}"

    socket.on 'sendmessage', (data)->
      user = users[data.uid]
      user.msgs.push data.msg
      robot.messageRoom '#dnilabs', data

    robot.hear /testmessage/i, (res) ->
      socket.emit 'message', hello: 'world'

  robot.hear /dnilabs/i, (res) ->
    robot.send "dnilabs is the best"
