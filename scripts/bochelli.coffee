module.exports = (robot) ->

  robot.hear /dnilabs/i, (res) ->
    res.send "dnilabs is the best"

  robot.hear /bochi/i, (res) ->
    res.send "miau"
