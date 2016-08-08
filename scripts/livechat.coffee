express = require "express"
timeout = null
users = {}

module.exports = (robot) ->

  # serve js
  robot.router.use "/js", express.static "#{process.cwd()}/js"

  throw new Error 'HTTP server not available' unless (server = robot.server)?

  # Attach socket.io to http server and configure it.
  io = (require 'socket.io').listen server

  io.on 'connection', (socket)->

    socket.on 'disconnect', ->
      timeout = setTimeout ->
        robot.messageRoom '#dnilabs', "a user disconnected"
      , 3000

    socket.on 'initUser', (data)->
      clearTimeout timeout
      console.log data
      user = users[data.uid]
      if user
        if user.msgs
          user.msgs.forEach (msg)->
            socket.emit 'message', msg
      else
        users[data.uid] = data
      robot.messageRoom '#dnilabs', "user #{data.uid} views #{data.url}"

    socket.on 'sendmessage', (data)->
      console.log "sendmessage: ", data
      user = users[data.uid]
      if !user.msgs
        user.msgs = []
      user.msgs.push data
      robot.messageRoom '#dnilabs', "user #{data.uid}: #{data.message}"

    robot.hear /livechat/i, (res) ->
      msg = res.message.text.split " "
      console.log msg
      action = msg.splice 0
      userid = msg.splice 0
      message = msg.join " "
      socket.emit 'message', hello: 'world'

  robot.hear /dnilabs/i, (res) ->
    robot.send "dnilabs is the best"
