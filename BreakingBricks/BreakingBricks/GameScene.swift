//
//  GameScene.swift
//  BreakingBricks
//
//  Created by Mobile on 12/18/20.
//  Copyright © 2020 Mobile. All rights reserved.
//

import SpriteKit
import GameplayKit

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    var player:SKSpriteNode!
    var ball:SKSpriteNode!
    var scoreLabel:SKLabelNode!
    var comboLabel:SKLabelNode!
    
    var playerVel:CGFloat = 0
    
    var score:Int = 0
    var combo:Int = 0
    
    // Preload sounds
    let blipSound:SKAction = SKAction.playSoundFileNamed("blip", waitForCompletion: false)
    let brickHitSound:SKAction = SKAction.playSoundFileNamed("brickhit", waitForCompletion: false)
    let gameOverSound:SKAction = SKAction.playSoundFileNamed("gameover", waitForCompletion: false)
    
    // Bitmask setup
    let noCategory:UInt32 = 0
    let playerCategory:UInt32 = 1
    let ballCategory:UInt32 = 2
    let brickCategory:UInt32 = 4
    // Note: The bottom edge category was not working for me, but I found a way around it (see update function)
    
    override func didMove(to view: SKView) {
        // Tell iOS that this class will implement SKPhysicsContactDelegate
        self.physicsWorld.contactDelegate = self
        
        // Give Scene Physics Body:
        self.scene?.physicsBody = SKPhysicsBody.init(edgeLoopFrom: self.scene!.frame)
        
        // Initialize Player:
        player = (self.childNode(withName: "player") as! SKSpriteNode)
        player.position.y = CGFloat(-self.size.height / 2 + 175)
        
        player.physicsBody?.categoryBitMask = playerCategory
        player.physicsBody?.contactTestBitMask = ballCategory
        
        // Initialize Ball:
        ball = (self.childNode(withName: "ball") as! SKSpriteNode)
        
        ball.physicsBody?.categoryBitMask = ballCategory
        ball.physicsBody?.contactTestBitMask = brickCategory | playerCategory
        
        // Setup trail:
        if let emitter = SKEmitterNode.init(fileNamed: "Trail") {
            emitter.targetNode = self.scene
            ball.addChild(emitter)
        }
        
        // Initialize Bricks:
        initializeBricks()
        
        // Initialize Score Label:
        scoreLabel = (self.childNode(withName: "scoreLabel") as! SKLabelNode)
        scoreLabel.text = "0"
        
        // Initialize Combo Label:
        comboLabel = (self.childNode(withName: "comboLabel") as! SKLabelNode)
        
    }
    
    // Code to handle contacts:
    func didBegin(_ contact: SKPhysicsContact) {
        
        let categoryA = contact.bodyA.categoryBitMask
        let categoryB = contact.bodyB.categoryBitMask
        
        // Make sure the bodies actually exist:
        if contact.bodyA.node?.parent == nil || contact.bodyB.node?.parent == nil {
            return
        }
        
        // Handle ball contacts:
        if categoryA == ballCategory || categoryB == ballCategory {
            // Figure out which body is the ball (and which is the brick)
            let notTheBall:SKNode = (categoryA == ballCategory) ? contact.bodyB.node! : contact.bodyA.node!
            // Do the proper actions
            ballDidContact(with: notTheBall)
        }
        
    }
    
    func ballDidContact(with otherNode: SKNode) {
        if otherNode.physicsBody?.categoryBitMask == brickCategory { // Contact ball with brick
            // Remove brick from game:
            otherNode.removeFromParent()
            // Increase the score by 1:
            increaseScore(by: 1 + combo)
            // Increase combo if it is less than 3:
            if combo < 3 {
                combo += 1
            }
            updateComboLabel()
            // Play sound:
            self.run(brickHitSound)
            // Run fire acton:
            if let fire = SKEmitterNode(fileNamed: "Fire") {
                self.addChild(fire)
                fire.setScale(0.75)
                fire.position = otherNode.position
            }
        } else if otherNode.physicsBody?.categoryBitMask == playerCategory { // Contact ball with player
            // Slightly change the balls x velocity (to ensure it doesn't get stuck)
            let adjustedPlayerVel = playerVel * 3 // Change these numbers to adjust the amont of change
            changeBallVelocity(dx: adjustedPlayerVel, dy: 0)
            // If the ball is too flat, give it more y velocity
            if ball.physicsBody!.velocity.dy.magnitude <= CGFloat(350) {
                changeBallVelocity(dx: 0, dy: 350)
                print("changed y vel")
            }
            // Reset combo
            combo = 0
            updateComboLabel()
            // Play sound:
            self.run(blipSound)
            // Run spark action
            if let spark = SKEmitterNode(fileNamed: "Spark") {
                self.addChild(spark)
                spark.setScale(0.75)
                spark.position = ball.position
                spark.position.y -= 10
            }
        }
        
    }
    
    func increaseScore(by amount: Int) {
        score += amount
        scoreLabel.text = String(score)
    }
    
    func updateComboLabel() {
        comboLabel.text = "+" + String(combo + 1)
        if combo == 0 {
            comboLabel.fontColor = .white
        }
        if combo > 0 {
            comboLabel.fontColor = .yellow
        }
        if combo > 2 {
            comboLabel.fontColor = .red
        }
    }
    
    func initializeBricks() {
        let testBrick = SKSpriteNode(imageNamed: "brick")
        let brickWidth = testBrick.size.width
        let brickHeight = testBrick.size.height
        
        let spacing:CGFloat = 20 // Change this to set the spacing between bricks
        let xAdjustment:CGFloat = 5 // Change this to center the bricks (shifts all bricks to the right by this number of pixels)
        let yAdjustment:CGFloat = 60 // Change this if you want a space above the top row of bricks (shifts all bricks down by this number of pixels)
        let numberOfRows:CGFloat = 5 // Change this to set the number of rows
        
        var ypos = self.size.height/2 - spacing - brickHeight/2
        while ypos > CGFloat(self.size.height/2) - numberOfRows * CGFloat(spacing + brickHeight) {
            var xpos = -self.size.width/2
            xpos += spacing + brickWidth/2
            while xpos < self.size.width/2 - spacing {
                makeBrick(x:xpos + xAdjustment, y:ypos - yAdjustment)
                xpos += spacing + brickWidth
            }
            ypos -= spacing + brickHeight
        }
    }
    
    func makeBrick(x:CGFloat, y:CGFloat) {
        let brick = SKSpriteNode(imageNamed: "brick")
        brick.physicsBody = SKPhysicsBody(rectangleOf: brick.frame.size)
        brick.physicsBody?.isDynamic = false
        brick.position.x = x
        brick.position.y = y
        
        brick.physicsBody?.categoryBitMask = brickCategory
        brick.physicsBody?.contactTestBitMask = ballCategory
        
        self.addChild(brick)
    }
    
    func changeBallVelocity(dx:CGFloat, dy:CGFloat) {
        ball.physicsBody?.applyImpulse(CGVector(dx: dx * ball.physicsBody!.mass, dy: dy * ball.physicsBody!.mass))
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches {
            // Make sure the touch is on screen
            if t.location(in: self).x > -self.size.width/2 && t.location(in: self).x < self.size.width/2 {
                player.position.x = t.location(in: self).x
            }
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches {
            // Make sure the touch is on screen
            if t.location(in: self).x > -self.size.width/2 && t.location(in: self).x < self.size.width/2 {
                let playerLastPos = player.position.x
                player.position.x = t.location(in: self).x
                // Determine (relative) player velocity
                playerVel = player.position.x - playerLastPos
            }
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        playerVel = 0
    }
    
    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
        
        // Note: The bottomEdge method of ending the game was not working for me, so this alternative is functionally the same (check if the ball is near the bottom each frame)
        if ball.position.y < -self.size.height/2 + ball.size.height/2 + 10 {
            endGame()
        }
    }
    
    func endGame() {
        self.run(gameOverSound)
        if let scene = SKScene(fileNamed: "StartScene") as? StartScene {
            scene.scaleMode = .aspectFill
            view!.presentScene(scene, transition: .doorsCloseHorizontal(withDuration: 2.0))
        }
    }
}
