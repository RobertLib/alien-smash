//
//  Explosion.swift
//  AlienSmash
//
//  Created by Robert Libšanský on 10.05.2025.
//

import SpriteKit

class Explosion {

    static func createExplosion(
        at position: CGPoint, in scene: SKScene, color: UIColor, scale: CGFloat = 1.0
    ) {
        let emitter = SKEmitterNode()

        emitter.position = position
        emitter.zPosition = 5
        emitter.particleBirthRate = 100
        emitter.numParticlesToEmit = 50
        emitter.particleLifetime = 0.8
        emitter.particleLifetimeRange = 0.3
        emitter.emissionAngle = 0
        emitter.emissionAngleRange = CGFloat.pi * 2

        emitter.particleColor = color
        emitter.particleColorBlendFactor = 1.0
        emitter.particleColorSequence = nil
        emitter.particleSize = CGSize(width: 8, height: 8)
        emitter.particleScaleRange = 0.5
        emitter.particleScale = scale

        emitter.particleSpeed = 100
        emitter.particleSpeedRange = 50
        emitter.particleAlpha = 1.0
        emitter.particleAlphaRange = 0.2
        emitter.particleAlphaSpeed = -1.0
        emitter.xAcceleration = 0
        emitter.yAcceleration = 0

        scene.addChild(emitter)

        let wait = SKAction.wait(forDuration: 2.0)
        let remove = SKAction.removeFromParent()
        emitter.run(SKAction.sequence([wait, remove]))
    }
}
