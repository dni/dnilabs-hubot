express = require "express"
bochelli = require "messages.json"

timeout = null

module.exports = (robot) ->

  # init users in brain
  robot.brain.set "users", {} unless robot.brain.get "users"
  users = robot.brain.get "users"


  # serve static
  robot.router.use "/static", express.static "#{process.cwd()}/static"

  throw new Error 'HTTP server not available' unless (server = robot.server)?

  # Attach socket.io to http server and configure it.
  io = (require 'socket.io').listen server

  io.on 'connection', (socket)->

    socket.on 'disconnect', ->
      timeout = setTimeout ->
        robot.messageRoom '#dnilabs', "user #{socket.userid} closed one socket"
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
          message =
            date: new Date()
            userid: userid
            username: "Bochelli"
            message: bochelli.welcome
            message: "Hi! Mein Name ist Bochelli. Ich bin ein Chatroboter ich leite Ihre Nachrichten in den Chat, wenn jemand Online ist wird er sich melden, ansonten leite ich Ihre Nachrichten per Email weiter"
          user.msgs.push message

      else
        data.socket = socket
        users[data.uid] = data
      robot.brain.set "users", users
      robot.messageRoom '#dnilabs', "user #{data.uid} views #{data.url}"

    socket.on 'sendmessage', (data)->
      user = users[data.uid]
      if !user.msgs
        user.msgs = []
      user.msgs.push data
      robot.brain.set "users", users
      robot.messageRoom '#dnilabs', "user #{data.uid}: #{data.message}"

  robot.hear /useragent/i, (res) ->
    msg = res.message.text.split " "
    user = users[msg.splice(1, 1)]
    if user
      robot.messageRoom '#dnilabs', user.userAgent
    else
      robot.messageRoom '#dnilabs', "user not fount"

  robot.hear /listusers/i, (res) ->
    Object.keys(users).forEach (key)->
      user = users[key]
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
      robot.brain.set "users", users
      user.socket.emit 'message', message
    else
      res.send "message not sent, user not found"
