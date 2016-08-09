express = require "express"
timeout = null
users = {}

module.exports = (robot) ->

  # serve static
  robot.router.use "/static", express.static "#{process.cwd()}/static"

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
        socket.userid = data.uid
        data.socket = socket
        users[data.uid] = data
      robot.messageRoom '#dnilabs', "user #{data.uid} views #{data.url}"

    socket.on 'sendmessage', (data)->
      user = users[data.uid]
      if !user.msgs
        user.msgs = []
      user.msgs.push data
      robot.messageRoom '#dnilabs', "user #{data.uid}: #{data.message}"

    robot.hear /useragent/i, (res) ->
      msg = res.message.text.split " "
      user = users[msg.splice(1, 1)]
      if user
        robot.messageRoom '#dnilabs', user.userAgent
      else
        robot.messageRoom '#dnilabs', "user not fount"

    robot.hear /livechat/i, (res) ->
      action = msg.splice 0, 1
      userid = msg.splice 0, 1
      user = users[userid]
      if user
        msg = res.message.text.split ":"
        message =
          date: new Date()
          userid: userid
          username: msg.splice 0, 1
          message: msg.join ":"
        user.socket.emit 'message', message
      else
        res.send "message not sent, user not found"
