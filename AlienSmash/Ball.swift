//
//  Ball.swift
//  AlienSmash
//
//  Created by Robert Libšanský on 09.05.2025.
//

import SpriteKit

class Ball: SKSpriteNode {

    private let radius: CGFloat
    private let ballSpeed: CGFloat
    private(set) var launched = false
    private var trailEmitter: SKEmitterNode?

    init(radius: CGFloat = 10, speed: CGFloat = 500) {
        self.radius = radius
        self.ballSpeed = speed
        super.init(texture: nil, color: .clear, size: CGSize(width: radius * 2, height: radius * 2))
        setupBall()
        setupTrailEffect()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupBall() {
        let ballShape = SKShapeNode(circleOfRadius: radius)
        ballShape.fillColor = .red
        ballShape.strokeColor = .red
        ballShape.position = CGPoint.zero
        ballShape.zPosition = 1

        addChild(ballShape)

        physicsBody = SKPhysicsBody(circleOfRadius: radius)
        physicsBody?.isDynamic = true
        physicsBody?.categoryBitMask = PhysicsCategory.ball
        physicsBody?.contactTestBitMask =
            PhysicsCategory.paddle | PhysicsCategory.alien | PhysicsCategory.alienBullet
        physicsBody?.collisionBitMask = PhysicsCategory.none
        physicsBody?.friction = 0
        physicsBody?.restitution = 1.0
        physicsBody?.linearDamping = 0
        physicsBody?.angularDamping = 0
        physicsBody?.allowsRotation = false
        physicsBody?.mass = 0.1
    }

    private func setupTrailEffect() {
        let emitter = SKEmitterNode()

        emitter.particleBirthRate = 60
        emitter.numParticlesToEmit = -1
        emitter.particleLifetime = 0.8
        emitter.particleLifetimeRange = 0.3

        emitter.targetNode = nil
        emitter.zPosition = -1

        emitter.particleSize = CGSize(width: radius * 1.0, height: radius * 1.0)
        emitter.particleScaleRange = 0.3
        emitter.particleScaleSpeed = -0.5

        emitter.particleColor = UIColor.orange
        emitter.particleColorBlendFactor = 1.0
        emitter.particleColorSequence = nil
        emitter.particleAlpha = 1.0
        emitter.particleAlphaRange = 0.2
        emitter.particleAlphaSpeed = -0.5

        emitter.particleSpeed = 0
        emitter.emissionAngle = 0
        emitter.emissionAngleRange = 0

        emitter.particleRotationRange = .pi * 2

        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 8, height: 8))
        let image = renderer.image { context in
            UIColor.white.setFill()
            context.cgContext.fillEllipse(in: CGRect(x: 0, y: 0, width: 8, height: 8))
        }
        emitter.particleTexture = SKTexture(image: image)

        trailEmitter = emitter
        addChild(emitter)

        emitter.isPaused = true
    }

    func launch() {
        if !launched {
            launched = true

            let angle = CGFloat.random(in: -CGFloat.pi / 4...CGFloat.pi / 4)
            let dx = ballSpeed * sin(angle)
            let dy = ballSpeed * cos(angle)

            physicsBody?.velocity = CGVector(dx: dx, dy: dy)

            if let scene = self.scene {
                trailEmitter?.targetNode = scene
            }

            trailEmitter?.isPaused = false
        }
    }

    func reset(at position: CGPoint) {
        physicsBody?.velocity = CGVector(dx: 0, dy: 0)
        self.position = position
        launched = false

        trailEmitter?.isPaused = true
        trailEmitter?.resetSimulation()
    }

    func updatePosition(in frame: CGRect, paddle: Paddle) {
        if !launched {
            position = CGPoint(x: paddle.position.x, y: paddle.position.y + 30)
            return
        }

        var correctionNeeded = false
        var newVelocity = physicsBody!.velocity
        var newPosition = position

        if position.x <= frame.minX + radius {
            newVelocity.dx = abs(newVelocity.dx)
            newPosition.x = frame.minX + radius + 1
            correctionNeeded = true
        } else if position.x >= frame.maxX - radius {
            newVelocity.dx = -abs(newVelocity.dx)
            newPosition.x = frame.maxX - radius - 1
            correctionNeeded = true
        }

        if position.y >= frame.maxY - radius {
            newVelocity.dy = -abs(newVelocity.dy)
            newPosition.y = frame.maxY - radius - 1
            correctionNeeded = true
        }

        if correctionNeeded {
            position = newPosition
            physicsBody?.velocity = newVelocity
        }

        let currentVelocity = physicsBody!.velocity
        let currentSpeed = sqrt(
            currentVelocity.dx * currentVelocity.dx + currentVelocity.dy * currentVelocity.dy)

        if currentSpeed < ballSpeed && currentSpeed > 0 {
            let multiplier = ballSpeed / currentSpeed
            let newVelocity = CGVector(
                dx: currentVelocity.dx * multiplier,
                dy: currentVelocity.dy * multiplier
            )
            physicsBody?.velocity = newVelocity
        }
    }

    func handlePaddleCollision(paddle: Paddle) {
        let xOffset = position.x - paddle.position.x
        let normalizedOffset = xOffset / (paddle.size.width / 2)
        let angle = normalizedOffset * .pi / 4
        let newDx = ballSpeed * sin(angle)
        let newDy = ballSpeed * cos(angle)

        physicsBody?.velocity = CGVector(dx: newDx, dy: abs(newDy))
    }
}
