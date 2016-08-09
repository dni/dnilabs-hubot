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
        robot.messageRoom '#dnilabs', "user #{socket.userid} disconnected"
      , 3000

    socket.on 'initUser', (data)->
      clearTimeout timeout
      socket.userid = data.uid
      user = users[data.uid]
      if user
        user.socket = socket
        user.url = data.url
        if user.msgs
          user.msgs.forEach (msg)->
            socket.emit 'message', msg
      else
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

  robot.hear /listusers/i, (res) ->
    users.forEach (user)->
      robot.messageRoom '#dnilabs', "#{user.uid}: #{user.url}: #{user.userAgent}"

  robot.hear /livechat/i, (res) ->
    msg = res.message.text.split ":"
    action = msg.splice 0, 1
    userid = msg.splice 0, 1
    user = users[userid]
    if user
      message =
        date: new Date()
        userid: userid
        username: msg.splice 0, 1
        message: msg.join ":"
      user.msgs.push message
      user.socket.emit 'message', message
    else
      res.send "message not sent, user not found"
