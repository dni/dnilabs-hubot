message =
  welcome: "Hi! Mein Name ist Bochelli. Ich bin ein Chatroboter, bei Fragen oder Anregungen leite ich Ihre Nachrichten in den Chat weiter, wenn jemand von uns Online ist wird er sich melden, ansonsten leite ich Ihre Nachrichten per Email weiter. Gerne können Sie auch direkt unseren IRC Raum #dnilabs betreten. <a href='https://kiwiirc.com/client/chat.freenode.net'>Webchat</a>"


express = require "express"

timeout = null

module.exports = (robot) ->

  robot.brain.on "loaded", ->

    console.log "brain is loaded"

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
        users = robot.brain.get "users"
        user = users[data.uid]
        if user
          user.socket = socket
          user.url = data.url
          if user.msgs
            user.msgs.forEach (msg)->
              socket.emit 'message', msg
        else
          data.socket = socket
          data.lastActivity = new Date()
          data.msgs = []
          data.msgs.push
              date: new Date()
              userid: userid
              username: "Bochelli"
              message: bochelli.welcome
          users[data.uid] = data
        robot.brain.set "users", users
        robot.messageRoom '#dnilabs', "user #{data.uid} views #{data.url}"

      socket.on 'sendmessage', (data)->
        users = robot.brain.get "users"
        user = users[data.uid]
        if !user.msgs
          user.msgs = []
        user.msgs.push data
        robot.brain.set "users", users
        robot.messageRoom '#dnilabs', "user #{data.uid}: #{data.message}"

    robot.hear /useragent/i, (res) ->
      msg = res.message.text.split " "
      users = robot.brain.get "users"
      user = users[msg.splice(1, 1)]
      if user
        robot.messageRoom '#dnilabs', user.userAgent
      else
        robot.messageRoom '#dnilabs', "user not fount"

    robot.hear /showbrain/i, (res) ->
      users = robot.brain.get "users"
      Object.keys(users).forEach (key)->
        user = users[key]
        robot.messageRoom '#dnilabs', "#{user.uid}: #{user.url}: #{user.userAgent}"


    robot.hear /listusers/i, (res) ->
      users = robot.brain.get "users"
      Object.keys(users).forEach (key)->
        user = users[key]
        robot.messageRoom '#dnilabs', "#{user.uid}: #{user.url}: #{user.userAgent}"

    robot.hear /livechat/i, (res) ->
      msg = res.message.text.split ":"
      action = msg.splice 0, 1
      userid = msg.splice 0, 1
      users = robot.brain.get "users"
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
