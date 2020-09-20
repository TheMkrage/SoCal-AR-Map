//
//  ViewController.swift
//  SoCal AR Map - ARKit
//
//  Created by Matthew Krager on 9/15/20.
//  Copyright © 2020 Matthew Krager. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate, ARSessionDelegate {
    
    @IBOutlet var sceneView: ARSCNView!
    
    /// A serial queue for thread safety when modifying the SceneKit node graph.
    let updateQueue = DispatchQueue(label: Bundle.main.bundleIdentifier! +
        ".serialSceneKitQueue")
    
    /// Convenience accessor for the session owned by ARSCNView.
    var session: ARSession {
        return sceneView.session
    }
    
    // MARK: - View Controller Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sceneView.delegate = self
        sceneView.session.delegate = self
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Prevent the screen from being dimmed to avoid interuppting the AR experience.
        UIApplication.shared.isIdleTimerDisabled = true

        // Start the AR experience
        resetTracking()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        session.pause()
    }

    // MARK: - Session management (Image detection setup)
    
    /// Prevents restarting the session while a restart is in progress.
    var isRestartAvailable = true

    /// Creates a new AR configuration to run on the `session`.
    /// - Tag: ARReferenceImage-Loading
    func resetTracking() {
        
        guard let referenceImages = ARReferenceImage.referenceImages(inGroupNamed: "ImageRefs", bundle: nil) else {
            fatalError("Missing expected asset catalog resources.")
        }
        
        let configuration = ARWorldTrackingConfiguration()
        configuration.detectionImages = referenceImages
        session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
    }

    // MARK: - ARSCNViewDelegate (Image detection results)
    /// - Tag: ARImageAnchor-Visualizing
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard let imageAnchor = anchor as? ARImageAnchor else { return }
        let referenceImage = imageAnchor.referenceImage
        
        let nodeToAdd: SCNNode? = getNode(for: referenceImage.name ?? "", referenceWidth: referenceImage.physicalSize.width)
        updateQueue.async {
            guard let nodeToAdd = nodeToAdd else {
                return
            }
            // Add the plane visualization to the scene.
            node.addChildNode(nodeToAdd)
        }
    }
    
    private func getNode(for resource: String, referenceWidth: CGFloat) -> SCNNode? {
        guard let usdzURL = Bundle.main.url(forResource: resource, withExtension: "usdz"),
            let hbNode = SCNReferenceNode(url: usdzURL) else {
            return nil
        }
        hbNode.load()
        let threeDimensionalAssetToRealReferenceImageScale = referenceWidth / CGFloat(hbNode.boundingBox.max.x)
        hbNode.scale = SCNVector3(threeDimensionalAssetToRealReferenceImageScale, threeDimensionalAssetToRealReferenceImageScale, threeDimensionalAssetToRealReferenceImageScale)
        print(threeDimensionalAssetToRealReferenceImageScale)
        
        switch resource {
        case "Irvine", "LosAngeles":
            hbNode.light = SCNLight()

            hbNode.light?.intensity = 1000
            hbNode.castsShadow = true
            hbNode.position = SCNVector3Zero
            hbNode.light?.type = SCNLight.LightType.ambient
            hbNode.light?.color = UIColor.white

        default:
            hbNode.light = SCNLight()

            hbNode.light?.intensity = 1000
            hbNode.castsShadow = true
            hbNode.position = SCNVector3Zero
            hbNode.light?.type = SCNLight.LightType.directional
            hbNode.light?.color = UIColor.white
        }
        return hbNode
    }

    var imageHighlightAction: SCNAction {
        return .sequence([
            .wait(duration: 0.25),
            .fadeOpacity(to: 0.85, duration: 0.25),
            .fadeOpacity(to: 0.15, duration: 0.25),
            .fadeOpacity(to: 0.85, duration: 0.25),
            .fadeOut(duration: 0.5),
            .removeFromParentNode()
        ])
    }
}
