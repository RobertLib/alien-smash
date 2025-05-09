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
    private var respawnDelay: TimeInterval = 2.0
    private var respawnCheckDelay: TimeInterval = 0.5

    private var restartButton: SKNode?
    private var gameOverNode: SKNode?
    private var gameState: GameState = .playing

    override func didMove(to view: SKView) {
        backgroundColor = .black
        setupStarField()
        setupPhysics()
        setupLives()
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

    private func setupPaddle() {
        paddle = Paddle()
        paddle.position = CGPoint(x: frame.midX, y: frame.minY + paddleYPosition)
        addChild(paddle)
    }

    private func setupBall() {
        ball = Ball()
        ball.position = CGPoint(x: frame.midX, y: paddle.position.y + 30)
        addChild(ball)
    }

    private func setupAliens() {
        formationManager = FormationManager(scene: self)
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

        ball.reset(at: CGPoint(x: paddle.position.x, y: paddle.position.y + 30))
        ball.isHidden = false
    }

    private func checkForGameOver() {
        guard gameState == .waitingForGameOver else { return }

        let isSceneCalm = formationManager.areAllAliensInFormation() && alienBullets.isEmpty

        if isSceneCalm {
            gameState = .gameOver
            showGameOverScreen()
        } else {
            let waitAction = SKAction.wait(forDuration: respawnCheckDelay)
            let checkAction = SKAction.run { [weak self] in
                self?.checkForGameOver()
            }
            run(SKAction.sequence([waitAction, checkAction]))
        }
    }

    private func showGameOverScreen() {
        let gameOverGroup = SKNode()
        gameOverGroup.zPosition = 1000
        addChild(gameOverGroup)
        gameOverNode = gameOverGroup

        let gameOverLabel = SKLabelNode(fontNamed: "Helvetica-Bold")
        gameOverLabel.text = "GAME OVER"
        gameOverLabel.fontSize = 42
        gameOverLabel.fontColor = .white
        gameOverLabel.position = CGPoint(x: 0, y: 40)
        gameOverGroup.addChild(gameOverLabel)

        let buttonBackground = SKShapeNode(rectOf: CGSize(width: 200, height: 50), cornerRadius: 10)
        buttonBackground.fillColor = UIColor(white: 0.3, alpha: 1.0)
        buttonBackground.strokeColor = .white
        buttonBackground.lineWidth = 2
        buttonBackground.position = CGPoint(x: 0, y: -40)
        buttonBackground.name = "restartButton"
        gameOverGroup.addChild(buttonBackground)

        let buttonLabel = SKLabelNode(fontNamed: "Helvetica-Bold")
        buttonLabel.text = "NEW GAME"
        buttonLabel.fontSize = 24
        buttonLabel.fontColor = .white
        buttonLabel.position = CGPoint(x: 0, y: 0)
        buttonLabel.verticalAlignmentMode = .center
        buttonLabel.horizontalAlignmentMode = .center
        buttonLabel.name = "restartButton"
        buttonBackground.addChild(buttonLabel)

        restartButton = buttonBackground
        gameOverGroup.position = CGPoint(x: frame.midX, y: frame.midY)

        ball.physicsBody?.velocity = CGVector.zero

        for bullet in alienBullets {
            bullet.removeFromParent()
        }
        alienBullets.removeAll()
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
            ball.updatePosition(in: frame, paddle: paddle)

            if ball.position.y < frame.minY {
                ball.reset(at: CGPoint(x: paddle.position.x, y: paddle.position.y + 30))
                loseLife()
            }

            let newBullets = formationManager.update(
                currentTime: currentTime, playerPosition: paddle.position)
            alienBullets.append(contentsOf: newBullets)

        case .waitingToRespawn, .waitingForGameOver, .respawning:
            break

        case .gameOver:
            break
        }
    }

    private func restartGame() {
        self.removeAllChildren()
        self.removeAllActions()

        alienBullets.removeAll()
        livesNodes.removeAll()
        gameOverNode = nil
        restartButton = nil

        gameState = .playing
        lives = 3
        lastUpdateTime = 0

        backgroundColor = .black
        setupStarField()
        setupPhysics()
        setupLives()
        setupPaddle()
        setupBall()
        setupAliens()

        formationManager.resetTimers()
    }

    func touchDown(atPoint pos: CGPoint) {
        if gameState == .gameOver {
            let nodes = nodes(at: pos)
            if nodes.contains(where: {
                $0.name == "restartButton" || ($0.parent?.name == "restartButton")
            }) {
                restartGame()
            }
            return
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
        }
    }
}
