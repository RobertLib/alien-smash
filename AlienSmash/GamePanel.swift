//
//  GamePanel.swift
//  AlienSmash
//
//  Created by Robert Libšanský on 12.05.2025.
//

import SpriteKit

class GamePanel: SKNode {

  private var backgroundPanel: SKShapeNode!
  private var titleLabel: GameTitle!
  private var subtitleLabel: GameTitle?
  private var infoLabels: [GameTitle] = []
  private var actionButton: GameButton?

  private let panelWidth: CGFloat = 500
  private var panelHeight: CGFloat = 350
  private let padding: CGFloat = 60
  private let lineSpacing: CGFloat = 50
  private let minHeight: CGFloat = 200

  override init() {
    super.init()
    self.zPosition = 1000
    setupBackground()
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  private func setupBackground() {
    backgroundPanel?.removeFromParent()

    backgroundPanel = SKShapeNode(
      rectOf: CGSize(width: panelWidth, height: panelHeight), cornerRadius: 20)
    backgroundPanel.fillColor = UIColor(red: 0.1, green: 0.1, blue: 0.2, alpha: 0.95)
    backgroundPanel.strokeColor = UIColor(red: 0.3, green: 0.6, blue: 1.0, alpha: 1.0)
    backgroundPanel.lineWidth = 3
    backgroundPanel.glowWidth = 2
    addChild(backgroundPanel)

    let innerShadow = SKShapeNode(
      rectOf: CGSize(width: panelWidth - 10, height: panelHeight - 10), cornerRadius: 15)
    innerShadow.fillColor = UIColor(red: 0.05, green: 0.05, blue: 0.15, alpha: 0.8)
    innerShadow.strokeColor = .clear
    innerShadow.zPosition = -1
    backgroundPanel.addChild(innerShadow)

    let topStripe = SKShapeNode(rectOf: CGSize(width: panelWidth - 20, height: 4), cornerRadius: 2)
    topStripe.fillColor = UIColor(red: 0.3, green: 0.6, blue: 1.0, alpha: 1.0)
    topStripe.strokeColor = .clear
    topStripe.position = CGPoint(x: 0, y: panelHeight / 2 - 20)
    topStripe.glowWidth = 1
    backgroundPanel.addChild(topStripe)

    let bottomStripe = SKShapeNode(
      rectOf: CGSize(width: panelWidth - 20, height: 4), cornerRadius: 2)
    bottomStripe.fillColor = UIColor(red: 0.3, green: 0.6, blue: 1.0, alpha: 1.0)
    bottomStripe.strokeColor = .clear
    bottomStripe.position = CGPoint(x: 0, y: -panelHeight / 2 + 20)
    bottomStripe.glowWidth = 1
    backgroundPanel.addChild(bottomStripe)
  }

  func setupContent(
    title: String,
    subtitle: String? = nil,
    infoTexts: [String] = [],
    buttonText: String? = nil,
    buttonAction: (() -> Void)? = nil
  ) {
    clearContent()

    var contentHeight: CGFloat = 0

    contentHeight += 36

    if subtitle != nil {
      contentHeight += 20
      contentHeight += 28
    }

    if !infoTexts.isEmpty {
      contentHeight += 30
      contentHeight += CGFloat(infoTexts.count) * 28
      contentHeight += CGFloat(infoTexts.count - 1) * 22
    }

    if buttonText != nil {
      contentHeight += 30
      contentHeight += 50
    }

    panelHeight = max(contentHeight + (padding * 2), minHeight)

    setupBackground()

    var currentY: CGFloat = contentHeight / 2

    titleLabel = GameTitle(text: title, fontSize: 36)
    titleLabel.fontColor = UIColor(red: 1.0, green: 0.9, blue: 0.3, alpha: 1.0)
    titleLabel.position = CGPoint(x: 0, y: currentY - 18)
    titleLabel.alpha = 1.0
    addChild(titleLabel)

    currentY -= 36

    if let subtitle = subtitle {
      currentY -= 28

      subtitleLabel = GameTitle(text: subtitle, fontSize: 28)
      subtitleLabel!.fontColor = UIColor(red: 0.8, green: 0.9, blue: 1.0, alpha: 1.0)
      subtitleLabel!.position = CGPoint(x: 0, y: currentY - 14)
      subtitleLabel!.alpha = 1.0
      addChild(subtitleLabel!)

      currentY -= 28
    }

    if !infoTexts.isEmpty {
      currentY -= 30

      for infoText in infoTexts {
        let infoLabel = GameTitle(text: infoText, fontSize: 28)
        infoLabel.fontColor = UIColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1.0)
        infoLabel.position = CGPoint(x: 0, y: currentY - 14)
        infoLabel.alpha = 1.0
        infoLabels.append(infoLabel)
        addChild(infoLabel)

        currentY -= 28
        if infoText != infoTexts.last {
          currentY -= 22
        }
      }
    }

    if let buttonText = buttonText, let buttonAction = buttonAction {
      currentY -= 30

      actionButton = GameButton(text: buttonText, size: CGSize(width: 200, height: 50))
      actionButton!.position = CGPoint(x: 0, y: currentY - 25)
      actionButton!.onPressed = buttonAction
      actionButton!.alpha = 1.0
      addChild(actionButton!)
    }
  }

  private func clearContent() {
    titleLabel?.removeFromParent()
    titleLabel = nil

    subtitleLabel?.removeFromParent()
    subtitleLabel = nil

    for label in infoLabels {
      label.removeFromParent()
    }
    infoLabels.removeAll()

    actionButton?.removeFromParent()
    actionButton = nil
  }

  func show(with animation: Bool = true) {
    if animation {
      self.setScale(0.1)
      self.alpha = 0.0

      let scaleAction = SKAction.scale(to: 1.0, duration: 0.4)
      scaleAction.timingMode = .easeOut

      let fadeAction = SKAction.fadeIn(withDuration: 0.4)

      let bounceAction = SKAction.sequence([
        SKAction.scale(to: 1.05, duration: 0.1),
        SKAction.scale(to: 1.0, duration: 0.1),
      ])

      let fullAnimation = SKAction.sequence([
        SKAction.group([scaleAction, fadeAction]),
        bounceAction,
      ])

      self.run(fullAnimation)
    }
  }

  func hide(completion: (() -> Void)? = nil) {
    let scaleAction = SKAction.scale(to: 0.1, duration: 0.3)
    let fadeAction = SKAction.fadeOut(withDuration: 0.3)
    let groupAction = SKAction.group([scaleAction, fadeAction])

    self.run(groupAction) {
      completion?()
    }
  }

  func handleTouch(_ location: CGPoint) -> Bool {
    guard let button = actionButton else { return false }
    return button.handleTouch(self.convert(location, to: button.parent!))
  }
}
