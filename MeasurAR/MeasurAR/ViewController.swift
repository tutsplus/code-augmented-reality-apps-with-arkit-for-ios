 //
//  ViewController.swift
//  MeasurAR
//
//  Created by Markus Mühlberger on 09/18/2017.
//  Copyright © 2017 Markus Muehlberger. All rights reserved.
//

import UIKit
import ARKit
import SceneKit

class ViewController: UIViewController, ARSKViewDelegate {
    @IBOutlet weak var sceneView: ARSKView!
    @IBOutlet weak var infoLabel: UILabel!
    
    var isMeasuring : Bool = false {
        didSet {
            if isMeasuring {
                self.infoLabel.text = "Tap screen to end measuring"
            } else {
                self.infoLabel.text = "Tap screen to start measuring"
            }
        }
    }
    var activeStartPoint : SCNVector3 = SCNVector3Zero
    var measurements = [Measurement]()
    
    enum Mode {
        case notMeasuring
        case measuring
    }
    
    struct Measurement {
        let start : SCNVector3
        let end : SCNVector3
        let distance : Float
        
        init(start: SCNVector3, end: SCNVector3) {
            self.start = start
            self.end = end
            
            let vector = SCNVector3Make(end.x - start.x, end.y - start.y, end.z - start.z)
            self.distance = sqrt(vector.x * vector.x + vector.y * vector.y + vector.z * vector.z)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        sceneView.delegate = self
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(tappedScreen))
        self.sceneView.addGestureRecognizer(tapGestureRecognizer)
    }
    
    @objc func tappedScreen(recognizer: UIGestureRecognizer) {
        let touchLocation = self.sceneView.center
        let hitTestResults = sceneView.hitTest(touchLocation, types: .featurePoint)
        
        guard let result = hitTestResults.first else {
            return
        }
        
        let point = SCNVector3(result.worldTransform.columns.3.x,
                               result.worldTransform.columns.3.y,
                               result.worldTransform.columns.3.z)
        
        if !isMeasuring {
            activeStartPoint = point
            isMeasuring = true
        } else {
            let measurement = Measurement(start: activeStartPoint, end: point)
            measurements.append(measurement)
            isMeasuring = false
            
            
            
            print("Length: \(measurement.distance) (isMeasuring: \(isMeasuring))")
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        sceneView.session.run(configuration)
        
        // Prevent the screen from being dimmed after not interacting with the screen
        UIApplication.shared.isIdleTimerDisabled = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        sceneView.session.pause()
    }
    
    
}
