addPlayer = (stage, player, index) ->
  circle = new createjs.Shape()
  circle.name = 'picture'
  circle.graphics.setStrokeStyle 2
  circle.graphics.beginStroke 'Blue'
  circle.graphics.beginFill 'DeepSkyBlue'
  circle.graphics.drawCircle 0, 0, 50

  text = new createjs.Text player.name, '20px Arial', 'White'
  text.name = 'name'
  text.y = 55

  container = new createjs.Container()
  container.name = player._id
  container.x = (index * 125) + 100
  container.y = 25
  container.alpha = 0
  container.addChild circle, text

  stage.addChild container

  createjs.Tween.get(container).to({alpha: 1, y: 75}, 1000, createjs.Ease.getBackInOut(5))

Template.game.onRendered ->
  gameKey = @data.gameKey #TODO move to router?

  stage = new createjs.Stage 'gameCanvas'
  createjs.Ticker.setFPS 60
  createjs.Ticker.addEventListener 'tick', stage
  createjs.Touch.enable(stage);

  TraitorGames.find(gameKey).observe
    added: (newGame)-> game = newGame
    changed: (newGame, oldGame) -> game = newGame
    removed: (oldGame) -> game = null # TODO ??

  TraitorPlayers.find(gameKey: gameKey, {sort: {order: 1}}).observe
    addedAt: (player, index, before) -> addPlayer(stage, player, index)
    removed: (player) ->
      createjs.Tween.get(stage.getChildByName(player._id))
      .to({alpha: 0, y: 25}, 800, createjs.Ease.getBackInOut(5))
      .call(-> stage.removeChild(this))

  btnBackground = new createjs.Shape()
  btnBackground.graphics.beginFill('DeepSkyBlue').drawRoundRect 0, 0, 125, 30, 10

  btnLabel = new createjs.Text "Join", '20px Arial', 'White'
  bound = btnLabel.getBounds()
  btnLabel.x = (125 - bound.width) / 2
  btnLabel.y = (30 - bound.height) / 2

  btn = new createjs.Container()
  btn.x = (800 - 125) / 2
  btn.y = 200
  btn.addChild btnBackground, btnLabel

  btn.addEventListener "click", (event) ->
    Meteor.call 'joinGame', gameKey, (error) -> throw error if error

  stage.addChild btn