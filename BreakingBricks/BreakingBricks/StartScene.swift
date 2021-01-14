//
//  StartScene.swift
//  BreakingBricks
//
//  Created by Mobile on 1/7/21.
//  Copyright © 2021 Mobile. All rights reserved.
//

import Foundation
import SpriteKit

class StartScene: SKScene {
    
    override func didMove(to view: SKView) {
        // Initialize Emitter
        let emitter = (self.childNode(withName: "emitter") as! SKEmitterNode)
        emitter.advanceSimulationTime(35.0)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let scene = SKScene(fileNamed: "GameScene") {
            // Set the scale mode to scale to fit the window
            scene.scaleMode = .aspectFill
            
            // Present the scene
            view!.presentScene(scene, transition: .doorsOpenHorizontal(withDuration: 2.0))
        }
    }
    
}
