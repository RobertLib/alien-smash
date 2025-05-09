//
//  GameOver.swift
//  AlienSmash
//
//  Created by Robert Libšanský on 11.05.2025.
//

import SpriteKit

class GameOver: SKNode {

    private var restartButton: GameButton!
    private var gameOverTitle: GameTitle!
    private var levelInfoLabel: GameTitle?
    private var scoreInfoLabel: GameTitle?
    var onRestartPressed: (() -> Void)?

    override init() {
        super.init()
        self.zPosition = 1000
        setupGameOver()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupGameOver() {
        gameOverTitle = GameTitle(text: "GAME OVER")
        gameOverTitle.position = CGPoint(x: 0, y: 160)
        addChild(gameOverTitle)

        restartButton = GameButton(text: "NEW GAME")
        restartButton.position = CGPoint(x: 0, y: -100)
        restartButton.onPressed = { [weak self] in
            self?.onRestartPressed?()
        }
        addChild(restartButton)

        self.setScale(0.1)
        self.run(SKAction.scale(to: 1.0, duration: 0.5))

        gameOverTitle.alpha = 1.0
        restartButton.alpha = 1.0
    }

    func handleTouch(_ location: CGPoint) -> Bool {
        return restartButton.handleTouch(self.convert(location, to: restartButton.parent!))
    }

    func setStats(_ level: Int, _ score: Int) {
        levelInfoLabel = GameTitle(text: "LEVEL REACHED: \(level)", fontSize: 32)
        levelInfoLabel?.position = CGPoint(x: 0, y: 80)
        addChild(levelInfoLabel!)
        levelInfoLabel?.fadeIn()

        scoreInfoLabel = GameTitle(text: "FINAL SCORE: \(score)", fontSize: 32)
        scoreInfoLabel?.position = CGPoint(x: 0, y: 0)
        addChild(scoreInfoLabel!)
        scoreInfoLabel?.fadeIn()
    }
}
