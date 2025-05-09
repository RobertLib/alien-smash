//
//  GameOver.swift
//  AlienSmash
//
//  Created by Robert Libšanský on 11.05.2025.
//

import SpriteKit

class GameOver: SKNode {

    private var gamePanel: GamePanel!
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
        gamePanel = GamePanel()
        addChild(gamePanel)

        gamePanel.setupContent(
            title: "GAME OVER",
            buttonText: "NEW GAME",
            buttonAction: { [weak self] in
                self?.onRestartPressed?()
            }
        )

        gamePanel.show()
    }

    func handleTouch(_ location: CGPoint) -> Bool {
        return gamePanel.handleTouch(self.convert(location, to: gamePanel))
    }

    func setStats(_ level: Int, _ score: Int) {
        gamePanel.setupContent(
            title: "GAME OVER",
            infoTexts: [
                "LEVEL REACHED: \(level)",
                "FINAL SCORE: \(score)",
            ],
            buttonText: "NEW GAME",
            buttonAction: { [weak self] in
                self?.onRestartPressed?()
            }
        )
    }
}
