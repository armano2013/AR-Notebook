//
//  arScene.swift
//  ARNotebook
//
//  Created by AR Notebook on 10/15/17.
//  Copyright © 2017 AR Notebook. All rights reserved.
//

import Foundation

import UIKit
import ARKit
import SceneKit


class ARScene: SKScene {
    
    var SceneView: ARSKView{
      return view as! ARSKView
    }
    
    var isWorldSetUp = false
    


    private func setUpWorld(){
        guard let currentFrame = SceneView.session.currentFrame
    else {return}
        
        
        var translation = matrix_identity_float4x4
        // 1 0 0 0
        // 0 1 0 0
        // 0 0 1 0
        // 0 0 0 1
        translation.columns.3.z = 0.001
        // 0 1 2 3
        // 1 0 0 0     x
        // 0 1 0 0     y
        // 0 0 1 -0.3  z
        // 0 0 0 1     1
        
        // Anchor the scene using our transfomraion matrix
        let transform = currentFrame.camera.transform * translation
        // this the Detection ARAnchor like the on apple keyNote Conferernce
        let anchor = ARAnchor(transform: transform)
        SceneView.session.add(anchor: anchor)
        
        
        
        isWorldSetUp = true
        
    
    }
    
    override func update(_ currentTime: TimeInterval) {
        
        if !isWorldSetUp {
            setUpWorld()
        
        }
    }
    

    
    
    
}
