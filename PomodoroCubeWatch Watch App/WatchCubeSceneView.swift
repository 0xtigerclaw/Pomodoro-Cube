//
//  WatchCubeSceneView.swift
//  PomodoroCubeWatch Watch App
//
//  v2.4 - Correct Mapping & Fluid 3D System
//

import SwiftUI
import SceneKit
import WatchKit
import Combine
import CoreGraphics

class WatchCubeScene: ObservableObject {
    let scene: SCNScene
    let cubeNode: SCNNode
    
    // Internal rotation tracking for fluid movement
    private var baseRotation = SCNVector3(0.35, 0, 0)
    
    private let faceLabels = ["25", "5", "15", "45", "10", "60"]
    
    init() {
        scene = SCNScene()
        
        // Calculate dimensions
        let screenWidth = WKInterfaceDevice.current().screenBounds.width
        let computedCubeSize: CGFloat
        let computedCameraDistance: Float
        
        if screenWidth >= 200 { 
            computedCubeSize = 2.2
            computedCameraDistance = 4.6
        } else if screenWidth >= 185 { 
            computedCubeSize = 2.0
            computedCameraDistance = 4.3
        } else { 
            computedCubeSize = 1.8
            computedCameraDistance = 4.0
        }
        
        // Camera
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        // Offset Y slightly positive to move the cube down visually (Centering Correction)
        cameraNode.position = SCNVector3(0, 0.2, computedCameraDistance)
        scene.rootNode.addChildNode(cameraNode)
        
        // Studio Lighting
        let keyLight = SCNNode()
        keyLight.light = SCNLight()
        keyLight.light?.type = .omni
        keyLight.light?.intensity = 1000
        keyLight.position = SCNVector3(3, 3, 5)
        scene.rootNode.addChildNode(keyLight)
        
        let fillLight = SCNNode()
        fillLight.light = SCNLight()
        fillLight.light?.type = .ambient
        fillLight.light?.intensity = 500
        scene.rootNode.addChildNode(fillLight)
        
        let rimLight = SCNNode()
        rimLight.light = SCNLight()
        rimLight.light?.type = .omni
        rimLight.light?.intensity = 400
        rimLight.position = SCNVector3(-3, 2, -2)
        scene.rootNode.addChildNode(rimLight)
        
        // Cube
        let boxGeometry = SCNBox(width: computedCubeSize, height: computedCubeSize, length: computedCubeSize, chamferRadius: computedCubeSize * 0.12)
        cubeNode = SCNNode(geometry: boxGeometry)
        cubeNode.eulerAngles = baseRotation
        scene.rootNode.addChildNode(cubeNode)
        
        // Materials
        var materials: [SCNMaterial] = []
        for i in 0..<6 {
            let material = SCNMaterial()
            material.lightingModel = .physicallyBased
            material.diffuse.contents = Self.generateFaceTexture(label: faceLabels[i])
            material.metalness.contents = 0.2
            material.roughness.contents = 0.15
            material.specular.contents = CGColor(gray: 0.6, alpha: 1.0)
            materials.append(material)
        }
        boxGeometry.materials = materials
        scene.background.contents = CGColor(gray: 0, alpha: 1)
    }
    
    // MARK: - Interaction API
    
    /// Update rotation in real-time during drag (Fluid feel)
    func updateInterimRotation(hOffset: Float, vOffset: Float) {
        // hOffset/vOffset are deltas in radians from the current snap position
        cubeNode.eulerAngles = SCNVector3(
            baseRotation.x - vOffset, // Vertical swipe rotates X
            baseRotation.y - hOffset, // Horizontal swipe rotates Y
            0
        )
    }
    
    /// Snap to a specific logical face index with correct mapping
    func snapToFace(index: Int) {
        let targetAngle: SCNVector3
        
        // FIX: Mapping Mismatch
        // 0: Focus (Front) -> Z+
        // 1: Short (Right) -> X+ -> Requires Y rotation -pi/2
        // 2: Back (Back) -> Z- -> Requires Y rotation pi
        // 3: Deep (Left) -> X- -> Requires Y rotation +pi/2
        // 4: Quick (Top) -> Y+ -> Requires X rotation +pi/2
        // 5: Hour (Bottom) -> Y- -> Requires X rotation -pi/2
        
        switch index {
        case 0: targetAngle = SCNVector3(0.3, 0, 0)
        case 1: targetAngle = SCNVector3(0.3, -.pi / 2, 0)
        case 2: targetAngle = SCNVector3(0.3, .pi, 0)
        case 3: targetAngle = SCNVector3(0.3, .pi / 2, 0)
        case 4: targetAngle = SCNVector3(Float.pi / 2, 0, 0)
        case 5: targetAngle = SCNVector3(-Float.pi / 2, 0, 0)
        default: targetAngle = SCNVector3(0.3, 0, 0)
        }
        
        baseRotation = targetAngle
        
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0.5
        cubeNode.eulerAngles = targetAngle
        SCNTransaction.commit()
    }
    
    // MARK: - Timer Logic
    
    func updateAllTimerFaces(timeString: String) {
        guard let geometry = cubeNode.geometry else { return }
        for i in 0..<6 {
            geometry.materials[i].diffuse.contents = Self.generateFaceTexture(label: timeString, isCountdown: true)
        }
    }
    
    func resetFaceTextures() {
        guard let geometry = cubeNode.geometry else { return }
        for i in 0..<6 {
            geometry.materials[i].diffuse.contents = Self.generateFaceTexture(label: faceLabels[i])
        }
    }
    
    func addSubtleIdleAnimation() {
        cubeNode.removeAllActions()
        let hover = SCNAction.sequence([
            SCNAction.moveBy(x: 0, y: 0.05, z: 0, duration: 2.5),
            SCNAction.moveBy(x: 0, y: -0.05, z: 0, duration: 2.5)
        ])
        cubeNode.runAction(SCNAction.repeatForever(hover))
    }
    
    func addRunningAnimation() {
        cubeNode.removeAllActions()
        let rotate = SCNAction.rotateBy(x: 0.1, y: 0.2, z: 0, duration: 5)
        cubeNode.runAction(SCNAction.repeatForever(rotate))
    }
    
    // MARK: - Helpers
    
    private static func generateFaceTexture(label: String, isCountdown: Bool = false) -> CGImage? {
        let size: CGFloat = 256
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        
        guard let ctx = CGContext(
            data: nil,
            width: Int(size),
            height: Int(size),
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }
        
        ctx.setFillColor(CGColor(gray: 0.03, alpha: 1.0))
        ctx.fill(CGRect(x: 0, y: 0, width: size, height: size))
        
        ctx.setStrokeColor(CGColor(gray: 0.15, alpha: 1.0))
        ctx.setLineWidth(4)
        ctx.stroke(CGRect(x: 10, y: 10, width: size - 20, height: size - 20))
        
        let fontSize: CGFloat = isCountdown ? 85 : 100
        let font = CTFontCreateWithName("Helvetica-Bold" as CFString, fontSize, nil)
        let color = isCountdown ? CGColor(red: 1, green: 0.8, blue: 0, alpha: 1) : CGColor(red: 1, green: 1, blue: 1, alpha: 1)
        
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: color
        ]
        
        let attributedString = NSAttributedString(string: label, attributes: attributes)
        let line = CTLineCreateWithAttributedString(attributedString)
        let bounds = CTLineGetBoundsWithOptions(line, .useOpticalBounds)
        
        ctx.textPosition = CGPoint(
            x: (size - bounds.width) / 2 - bounds.origin.x,
            y: (size - bounds.height) / 2 - bounds.origin.y
        )
        CTLineDraw(line, ctx)
        
        return ctx.makeImage()
    }
}
