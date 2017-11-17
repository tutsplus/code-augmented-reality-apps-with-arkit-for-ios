//
//  ViewController.swift
//  GetStARted
//
//  Created by Markus Mühlberger on 10/1/17.
//  Copyright © 2017 Markus Mühlberger. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

enum PhysicsType : Int {
    case box = 0b01
    case plane = 0b10
}

class ViewController: UIViewController, ARSCNViewDelegate {

    @IBOutlet var sceneView: ARSCNView!
    
    var planes = [UUID : SCNNode]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        
        // Create a new scene
        let scene = SCNScene()
        
        scene.lightingEnvironment.contents = UIImage(named: "environment")
        
        let noise = SCNNode()
        noise.physicsField = SCNPhysicsField.noiseField(smoothness: 0.0, animationSpeed: 1.0)
        noise.physicsField?.halfExtent = SCNVector3(3, 3, 3)
        noise.physicsField?.strength = 0.0
        noise.position = SCNVector3Zero
        
        scene.rootNode.addChildNode(noise)
        
        // Set the scene to the view
        sceneView.scene = scene
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        configuration.isLightEstimationEnabled = true

        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
//        guard let touch = touches.first?.location(in: sceneView), let hitResult = sceneView.hitTest(touch, options: [:]).first else {
//            return
//        }
        
        let camera = sceneView.session.currentFrame?.camera
        let transform = (camera != nil ? camera!.transform : matrix_identity_float4x4)
    
//        var position = hitResult.worldCoordinates
//        position.y += 0.25
        
        let material = SCNMaterial()
        material.lightingModel = .physicallyBased
        material.diffuse.contents = UIColor.orange
        material.locksAmbientWithDiffuse = true
        
        let cube = SCNBox(width: 0.2, height: 0.2, length: 0.2, chamferRadius: 0.0)
        cube.materials = [material]
        let node = SCNNode(geometry: cube)
//        node.position = position
        node.simdTransform = transform
        node.physicsBody = SCNPhysicsBody(type: .dynamic, shape: nil)
        node.physicsBody?.friction = 10.0
        
        let rotation = matrix_float3x3.init(
            simd_float3.init(transform.columns.0.x, transform.columns.0.y, transform.columns.0.z),
            simd_float3.init(transform.columns.1.x, transform.columns.1.y, transform.columns.1.z),
            simd_float3.init(transform.columns.2.x, transform.columns.2.y, transform.columns.2.z)
        )
        
        let directionVector = matrix_multiply(rotation, simd_float3(0,0,-2))
        let direction = SCNVector3Make(directionVector.x, directionVector.y, directionVector.z)
        
        node.physicsBody?.applyForce(direction, asImpulse: true)
        
        sceneView.scene.rootNode.addChildNode(node)
    }
    
    // MARK: - ARSCNViewDelegate
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        guard let estimate = sceneView.session.currentFrame?.lightEstimate else {
            return
        }
        
        sceneView.scene.lightingEnvironment.intensity = estimate.ambientIntensity / 1000.0
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard let anchor = anchor as? ARPlaneAnchor else {
            return
        }
        
        let material = SCNMaterial()
        material.diffuse.contents = UIColor(white: 1.0, alpha: 0.2)
        
        let planeGeometry = SCNPlane(width: CGFloat(anchor.extent.x), height: CGFloat(anchor.extent.z))
        planeGeometry.materials = [material]
        let planeNode = SCNNode(geometry: planeGeometry)
        planeNode.position = SCNVector3Make(anchor.center.x, 0, anchor.center.z)
        planeNode.transform = SCNMatrix4MakeRotation(-.pi / 2.0, 1, 0, 0)
        planeNode.physicsBody = SCNPhysicsBody(type: .static, shape: SCNPhysicsShape(geometry: planeGeometry, options: [:]))
        
        planes[anchor.identifier] = planeNode
        
        node.addChildNode(planeNode)
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let node = planes[anchor.identifier], let geometry = node.geometry as? SCNPlane, let anchor = anchor as? ARPlaneAnchor else {
            return
        }
        
        geometry.width = CGFloat(anchor.extent.x)
        geometry.height = CGFloat(anchor.extent.z)
        
        node.physicsBody = SCNPhysicsBody(type: .static, shape: SCNPhysicsShape(geometry: geometry, options: [:]))
        
        node.position = SCNVector3Make(anchor.center.x, 0, anchor.center.z)
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didRemove node: SCNNode, for anchor: ARAnchor) {
        guard let node = planes[anchor.identifier] else {
            return
        }
        
        planes[anchor.identifier] = nil
        node.removeFromParentNode()
    }
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        
    }
}
