//
//  GameScene.swift
//  AlienSmash
//
//  Created by Robert Libšanský on 09.05.2025.
//

import GameplayKit
import SpriteKit

class GameScene: SKScene {

    enum GameState {
        case playing
        case waitingToRespawn
        case respawning
        case waitingForGameOver
        case gameOver
        case levelCompleted

        var canControlPaddle: Bool {
            return self == .playing
        }

        var requiresUpdate: Bool {
            return self != .gameOver
        }
    }

    private let paddleYPosition: CGFloat = 50

    private var paddle: Paddle!
    private var ball: Ball!
    private var formationManager: FormationManager!
    private var alienBullets: [AlienBullet] = []
    private var starField: StarField!

    private var lastUpdateTime: TimeInterval = 0

    private var lives = 3
    private var livesNodes: [SKSpriteNode] = []
    private var score = 0
    private var scoreLabel: SKLabelNode!
    private var respawnDelay: TimeInterval = 2.0
    private var respawnCheckDelay: TimeInterval = 0.5

    private var gameOver: GameOver?
    private var gameState: GameState = .playing
    private var levelCompleted: LevelCompleted?

    private var currentLevel = 1
    private var levelLabel: SKLabelNode!

    override func didMove(to view: SKView) {
        backgroundColor = .black
        setupStarField()
        setupPhysics()
        setupLives()
        setupScore()
        setupLevel()
        setupPaddle()
        setupBall()
        setupAliens()
    }

    private func setupStarField() {
        starField = StarField(size: self.size)
        addChild(starField)
    }

    private func setupPhysics() {
        physicsWorld.gravity = CGVector(dx: 0, dy: 0)
        physicsWorld.contactDelegate = self
    }

    private func setupLives() {
        for i in 0..<lives {
            let lifeNode = SKSpriteNode(color: .white, size: CGSize(width: 30, height: 8))
            lifeNode.position = CGPoint(x: 30 + CGFloat(i) * 40, y: frame.maxY - 30)
            lifeNode.zPosition = 100
            livesNodes.append(lifeNode)
            addChild(lifeNode)
        }
    }

    private func setupScore() {
        scoreLabel = SKLabelNode(fontNamed: "Helvetica-Bold")
        scoreLabel.text = "Score: 0"
        scoreLabel.fontSize = 28
        scoreLabel.fontColor = .white
        scoreLabel.horizontalAlignmentMode = .right
        scoreLabel.position = CGPoint(x: frame.maxX - 30, y: frame.maxY - 38)
        scoreLabel.zPosition = 100
        addChild(scoreLabel)
    }

    private func setupLevel() {
        levelLabel = SKLabelNode(fontNamed: "Helvetica-Bold")
        levelLabel.text = "Level: \(currentLevel)"
        levelLabel.fontSize = 28
        levelLabel.fontColor = .white
        levelLabel.horizontalAlignmentMode = .center
        levelLabel.position = CGPoint(x: frame.midX, y: frame.maxY - 38)
        levelLabel.zPosition = 100
        addChild(levelLabel)
    }

    private func setupPaddle() {
        paddle = Paddle()
        paddle.position = CGPoint(x: frame.midX, y: frame.minY + paddleYPosition)
        paddle.synchronizeTarget()
        addChild(paddle)
    }

    private func setupBall() {
        ball = Ball()
        ball.position = CGPoint(x: frame.midX, y: paddle.position.y + 30)
        addChild(ball)
    }

    private func setupAliens() {
        formationManager = FormationManager(scene: self)
        formationManager.onLevelCompleted = { [weak self] in
            self?.showLevelCompleted()
        }
    }

    private func loseLife() {
        guard gameState == .playing else { return }

        lives -= 1
        gameState = lives > 0 ? .waitingToRespawn : .waitingForGameOver

        if let lastLifeNode = livesNodes.popLast() {
            lastLifeNode.removeFromParent()
        }

        Explosion.createExplosion(at: paddle.position, in: self, color: .white, scale: 2.0)
        paddle.alpha = 0

        if !ball.launched {
            ball.isHidden = true
        }

        formationManager.stopAllActions()

        let waitAction = SKAction.wait(forDuration: respawnCheckDelay)
        let checkAction = SKAction.run { [weak self] in
            if self?.gameState == .waitingToRespawn {
                self?.checkForRespawn()
            } else if self?.gameState == .waitingForGameOver {
                self?.checkForGameOver()
            }
        }
        run(SKAction.sequence([waitAction, checkAction]))
    }

    private func checkForRespawn() {
        guard gameState == .waitingToRespawn else { return }

        let isSceneCalm = formationManager.areAllAliensInFormation() && alienBullets.isEmpty

        if isSceneCalm {
            gameState = .respawning
            respawnPlayer()
            formationManager.resetTimers()
        } else {
            let waitAction = SKAction.wait(forDuration: respawnCheckDelay)
            let checkAction = SKAction.run { [weak self] in
                self?.checkForRespawn()
            }
            run(SKAction.sequence([waitAction, checkAction]))
        }
    }

    private func respawnPlayer() {
        gameState = .playing

        paddle.position = CGPoint(x: frame.midX, y: frame.minY + paddleYPosition)
        paddle.alpha = 1.0
        paddle.synchronizeTarget()

        ball.reset(at: CGPoint(x: paddle.position.x, y: paddle.position.y + 30))
        ball.isHidden = false
    }

    private func checkForGameOver() {
        guard gameState == .waitingForGameOver else { return }

        let isSceneCalm = formationManager.areAllAliensInFormation() && alienBullets.isEmpty

        if isSceneCalm {
            gameState = .gameOver
            showGameOver()
        } else {
            let waitAction = SKAction.wait(forDuration: respawnCheckDelay)
            let checkAction = SKAction.run { [weak self] in
                self?.checkForGameOver()
            }
            run(SKAction.sequence([waitAction, checkAction]))
        }
    }

    private func showGameOver() {
        gameOver = GameOver()
        gameOver?.position = CGPoint(x: frame.midX, y: frame.midY)
        gameOver?.setStats(currentLevel, score)
        gameOver?.onRestartPressed = { [weak self] in
            self?.restartGame()
        }
        addChild(gameOver!)

        ball.physicsBody?.velocity = CGVector.zero

        for bullet in alienBullets {
            bullet.removeFromParent()
        }
        alienBullets.removeAll()
    }

    private func showLevelCompleted() {
        gameState = .levelCompleted

        levelCompleted = LevelCompleted()
        levelCompleted?.position = CGPoint(x: frame.midX, y: frame.midY)
        levelCompleted?.setStats(currentLevel, score)
        levelCompleted?.onNextLevelPressed = { [weak self] in
            self?.startNextLevel()
        }
        addChild(levelCompleted!)
    }

    private func startNextLevel() {
        currentLevel += 1
        levelLabel.text = "Level: \(currentLevel)"

        if let levelCompleted = levelCompleted {
            levelCompleted.removeFromParent()
            self.levelCompleted = nil
        }

        for bullet in alienBullets {
            bullet.removeFromParent()
        }
        alienBullets.removeAll()

        paddle.position = CGPoint(x: frame.midX, y: frame.minY + paddleYPosition)
        paddle.alpha = 1.0
        paddle.synchronizeTarget()

        if ball.launched {
            ball.reset(at: CGPoint(x: paddle.position.x, y: paddle.position.y + 30))
        }

        formationManager.resetLevel()
        gameState = .playing
    }

    private func restartGame() {
        self.removeAllChildren()
        self.removeAllActions()

        alienBullets.removeAll()
        livesNodes.removeAll()
        gameOver = nil

        gameState = .playing
        lives = 3
        score = 0
        currentLevel = 1
        lastUpdateTime = 0

        backgroundColor = .black
        setupStarField()
        setupPhysics()
        setupLives()
        setupScore()
        setupLevel()
        setupPaddle()
        setupBall()
        setupAliens()

        formationManager.resetTimers()
    }

    private func updateScore(by points: Int) {
        score += points
        scoreLabel.text = "Score: \(score)"
    }

    override func update(_ currentTime: TimeInterval) {
        let deltaTime = lastUpdateTime > 0 ? min(currentTime - lastUpdateTime, 1.0 / 30.0) : 0
        lastUpdateTime = currentTime

        starField.update(deltaTime: deltaTime)

        if !gameState.requiresUpdate {
            return
        }

        alienBullets = alienBullets.filter { bullet in
            if bullet.isOutOfBounds(in: frame) {
                bullet.removeFromParent()
                return false
            }
            return true
        }

        switch gameState {
        case .playing:
            paddle.update(deltaTime: deltaTime)
            ball.updatePosition(in: frame, paddle: paddle)

            if ball.position.y < frame.minY {
                ball.reset(at: CGPoint(x: paddle.position.x, y: paddle.position.y + 30))
                loseLife()
            }

            formationManager.update(currentTime: currentTime, allowShooting: true)

        case .waitingToRespawn, .waitingForGameOver, .respawning:
            formationManager.update(currentTime: currentTime, allowShooting: false)

        case .gameOver:
            break

        case .levelCompleted:
            break
        }
    }

    func touchDown(atPoint pos: CGPoint) {
        if gameState == .gameOver {
            if gameOver?.handleTouch(self.convert(pos, to: gameOver!)) == true {
                return
            }
        }

        if gameState == .levelCompleted {
            if levelCompleted?.handleTouch(self.convert(pos, to: levelCompleted!)) == true {
                return
            }
        }

        if gameState == .playing && !ball.launched {
            ball.launch()
        }
    }

    func touchMoved(toPoint pos: CGPoint) {
        if gameState.canControlPaddle {
            paddle.moveHorizontally(to: pos.x, in: frame)
        }
    }

    func touchUp(atPoint pos: CGPoint) {
        guard gameState.canControlPaddle else { return }
        if !ball.launched {
            ball.launch()
        }
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let touchLocation = touch.location(in: self)
        self.touchDown(atPoint: touchLocation)
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let touchLocation = touch.location(in: self)
        self.touchMoved(toPoint: touchLocation)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches { self.touchUp(atPoint: t.location(in: self)) }
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches { self.touchUp(atPoint: t.location(in: self)) }
    }

    func addAlienBullet(_ bullet: AlienBullet) {
        alienBullets.append(bullet)
        addChild(bullet)
    }
}

extension GameScene: SKPhysicsContactDelegate {
    func didBegin(_ contact: SKPhysicsContact) {
        let collision = contact.bodyA.categoryBitMask | contact.bodyB.categoryBitMask

        if collision == PhysicsCategory.ball | PhysicsCategory.paddle && gameState == .playing {
            let paddleNode =
                (contact.bodyA.categoryBitMask == PhysicsCategory.paddle)
                ? contact.bodyA.node as! Paddle
                : contact.bodyB.node as! Paddle

            let ballNode =
                (contact.bodyA.categoryBitMask == PhysicsCategory.ball)
                ? contact.bodyA.node as! Ball
                : contact.bodyB.node as! Ball

            ballNode.handlePaddleCollision(paddle: paddleNode)
        } else if collision == PhysicsCategory.ball | PhysicsCategory.alien {
            let alienNode =
                (contact.bodyA.categoryBitMask == PhysicsCategory.alien)
                ? contact.bodyA.node as! Alien
                : contact.bodyB.node as! Alien

            let points = alienNode.state == .formation ? 100 : 200
            updateScore(by: points)

            Explosion.createExplosion(at: alienNode.position, in: self, color: .green)

            formationManager.handleCollisionWithBall(alien: alienNode)
        } else if collision == PhysicsCategory.paddle | PhysicsCategory.alienBullet
            && gameState == .playing
        {
            let bulletNode =
                (contact.bodyA.categoryBitMask == PhysicsCategory.alienBullet)
                ? contact.bodyA.node as! AlienBullet
                : contact.bodyB.node as! AlienBullet

            Explosion.createExplosion(at: bulletNode.position, in: self, color: .yellow)

            bulletNode.removeFromParent()
            if let index = alienBullets.firstIndex(where: { $0 === bulletNode }) {
                alienBullets.remove(at: index)
            }

            loseLife()
        } else if collision == PhysicsCategory.paddle | PhysicsCategory.alien
            && gameState == .playing
        {
            let alienNode =
                (contact.bodyA.categoryBitMask == PhysicsCategory.alien)
                ? contact.bodyA.node as! Alien
                : contact.bodyB.node as! Alien

            Explosion.createExplosion(at: paddle.position, in: self, color: .white, scale: 1.5)
            Explosion.createExplosion(at: alienNode.position, in: self, color: .green)

            loseLife()
            alienNode.returnToFormation()
        } else if collision == PhysicsCategory.ball | PhysicsCategory.alienBullet {
            let bulletNode =
                (contact.bodyA.categoryBitMask == PhysicsCategory.alienBullet)
                ? contact.bodyA.node as! AlienBullet
                : contact.bodyB.node as! AlienBullet

            updateScore(by: 50)

            Explosion.createExplosion(at: bulletNode.position, in: self, color: .yellow, scale: 0.5)

            bulletNode.removeFromParent()
            if let index = alienBullets.firstIndex(where: { $0 === bulletNode }) {
                alienBullets.remove(at: index)
            }
        }
    }
}
