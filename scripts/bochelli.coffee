module.exports = (robot) ->

  robot.hear /dnilabs/i, (res) ->
    res.send "dnilabs is the best"

  robot.hear /bochi/i, (res) ->
    res.send "miau"

  robot.hear /bochelli/i, (res) ->
    res.send "miau"

  enterReplies = ['Hi', 'Target Acquired', 'Ahoi', 'Hello friend.', 'Serwus', 'Griasdi']
  leaveReplies = ['wo isa hi?', 'Target lost', 'Searching']

  robot.enter (res) ->
    res.send res.random enterReplies
  robot.leave (res) ->
    res.send res.random leaveReplies
