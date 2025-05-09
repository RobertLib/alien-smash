//
//  WelcomeScene.swift
//  AlienSmash
//
//  Created by Robert Libšanský on 12.05.2025.
//

import SpriteKit

class WelcomeScene: SKScene {

    private var starField: StarField!
    private var newGameButton: GameButton!
    private var titleLabel: GameTitle!

    override func didMove(to view: SKView) {
        backgroundColor = .black
        setupStarField()
        setupTitle()
        setupNewGameButton()
    }

    private func setupStarField() {
        starField = StarField(size: self.size)
        addChild(starField)
    }

    private func setupTitle() {
        titleLabel = GameTitle(text: "ALIEN SMASH", fontSize: 56)
        titleLabel.position = CGPoint(x: frame.midX, y: frame.midY + 60)
        addChild(titleLabel)
        titleLabel.fadeIn()
    }

    private func setupNewGameButton() {
        newGameButton = GameButton(text: "NEW GAME")
        newGameButton.position = CGPoint(x: frame.midX, y: frame.midY - 60)
        newGameButton.onPressed = { [weak self] in
            self?.startGame()
        }
        addChild(newGameButton)
        newGameButton.fadeIn(after: 0.5)
    }

    override func update(_ currentTime: TimeInterval) {
        starField.update(deltaTime: 0.016)
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)

        if newGameButton.handleTouch(self.convert(location, to: newGameButton.parent!)) {}
    }

    private func startGame() {
        newGameButton.isUserInteractionEnabled = false

        titleLabel.fadeOut()
        newGameButton.fadeOut {
            if let view = self.view {
                if let gameScene = SKScene(fileNamed: "GameScene") {
                    gameScene.scaleMode = self.scaleMode
                    let transition = SKTransition.crossFade(withDuration: 1.0)
                    view.presentScene(gameScene, transition: transition)
                }
            }
        }
    }
}
