Meteor.methods
  mission: (playerId, mission)->
    check playerId, String
    user = Meteor.user()
    if not user
      throw new Meteor.Error "not-authorized"
    leader = TraitorPlayers.findOne _id: user._id, leader: true
    if not leader
      throw new Meteor.Error "You are not the leader"
    TraitorPlayers.update {_id: playerId, gameKey: leader.gameKey},
      {$set: {mission: mission}},
      (error) -> throw error if error

  startMission: ->
    user = Meteor.user()
    if not user
      throw new Meteor.Error "not-authorized"
    leader = TraitorPlayers.findOne _id: user._id, leader: true
    if not leader
      throw new Meteor.Error "You are not the leader"
    game = TraitorGames.findOne leader.gameKey
    if not game
      throw new Meteor.Error "Invalid game"
    players = TraitorPlayers.find(gameKey: leader.gameKey).fetch()
    playersOnMission = _.filter(players, (player) -> player.mission).length
    if playersOnMission isnt TraitorConstant.PLAYERS_PER_ROUND[players.length][game.rounds.length]
      throw new Meteor.Error "Invalid number of players"
    TraitorPlayers.update gameKey: leader.gameKey,
      {$unset: {vote: true, secret_vote: true}}
    TraitorGames.update leader.gameKey,
      {$set: {state: TraitorGameState.MISSION_VOTING}},
      (error) -> throw error if error

  vote: (vote) ->
    check vote, Boolean
    user = Meteor.user()
    if not user
      throw new Meteor.Error "not-authorized"
    TraitorPlayers.update
      _id: user._id,
      {$set: {secret_vote: vote}},
      (error) -> throw error if error

    player = TraitorPlayers.findOne user._id
    players = TraitorPlayers.find(gameKey: player.gameKey).fetch()
    if players.length isnt _.filter(players, (p) -> p.secret_vote?).length
      return

    game = TraitorGames.findOne player.gameKey
    if game.state is TraitorGameState.MISSION_VOTING
      if _.filter(players, (p) -> p.secret_vote).length > players.length / 2
        game.state = TraitorGameState.ON_MISSION
        game.rejected_missions = 0
      else
        game.rejected_missions++

      for player in players
        TraitorPlayers.update player._id,
          {$set: {vote: player.secret_vote}, $unset: {secret_vote: true}}
    else if game.state is TraitorGameState.ON_MISSION
      true