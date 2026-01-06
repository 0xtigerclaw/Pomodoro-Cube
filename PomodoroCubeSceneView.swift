// PomodoroCubeSceneView.swift
// True 3D Pomodoro Cube using SceneKit embedded in SwiftUI
// Visuals: Dark Tech Aesthetic (Black Glossy Body, Digital Display)
// PERFORMANCE OPTIMIZED: Texture caching + throttled updates

import SwiftUI
import SceneKit
import UIKit

struct PomodoroCubeSceneView: UIViewRepresentable {
    @ObservedObject var cube: PomodoroCube
    
    func makeUIView(context: Context) -> SCNView {
        let sceneView = SCNView()
        // Maps SceneKit face indices [Front, Right, Back, Left, Top, Bottom]
        // to logical intervals so that face 0 (Front/+Z) is mapped to index 4 (10 mins).
        let faceOrder: [Int] = [4, 0, 5, 1, 3, 2]
        context.coordinator.faceOrder = faceOrder
        
        let scene = makeScene(faceOrder: faceOrder, coordinator: context.coordinator)
        sceneView.scene = scene
        
        // View Settings
        sceneView.allowsCameraControl = false
        sceneView.backgroundColor = UIColor.clear
        sceneView.autoenablesDefaultLighting = false
        sceneView.antialiasingMode = .multisampling4X
        sceneView.preferredFramesPerSecond = 60
        
        // Camera Control Config
        sceneView.cameraControlConfiguration.allowsTranslation = false
        
        // Find the cube node
        guard let cubeNode = scene.rootNode.childNodes.first(where: { $0.geometry is SCNBox }) else {
            return sceneView
        }
        context.coordinator.cubeNode = cubeNode
        
        // Start floating animation
        context.coordinator.startFloatingAnimation()
        
        context.coordinator.lastFrontFaceIndex = nil
        
        // Add pan gesture
        let panGesture = UIPanGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePan(_:)))
        sceneView.addGestureRecognizer(panGesture)
        
        // Start monitoring
        context.coordinator.startMonitoring(scene: scene, cube: cube)
        
        return sceneView
    }
    
    func updateUIView(_ scnView: SCNView, context: Context) {
        guard let cubeNode = context.coordinator.cubeNode,
              let scene = scnView.scene,
              let frontFaceIndex = detectFrontFaceIndex(cubeNode: cubeNode, scene: scene) else { return }
        
        let faceOrder = context.coordinator.faceOrder
        guard frontFaceIndex < faceOrder.count else { return }
        let mappedFaceIndex = faceOrder[frontFaceIndex]
        guard mappedFaceIndex < cube.faces.count else { return }
        
        // Prepare data
        let time = max(0, Int(cube.timeRemaining))
        let totalDuration = cube.faces[mappedFaceIndex].duration
        let progress = totalDuration > 0 ? Double(time) / totalDuration : 0
        
        let minutes = time / 60
        let seconds = time % 60
        let timeString = String(format: "%02d %02d", minutes, seconds)
        
        // OPTIMIZATION: Only update timer texture if time changed
        let currentTimeKey = "\(frontFaceIndex)_\(timeString)"
        if context.coordinator.lastTimerKey != currentTimeKey {
            context.coordinator.lastTimerKey = currentTimeKey
            
            if let labelImg = generateDigitalTimerImage(
                timeText: timeString,
                progress: progress,
                color: .white,
                isActive: true
            ) {
                if let materials = cubeNode.geometry?.materials, materials.count > frontFaceIndex {
                    materials[frontFaceIndex].diffuse.contents = labelImg
                    materials[frontFaceIndex].emission.contents = labelImg
                }
            }
        }
        
        // OPTIMIZATION: Use cached static textures for other faces
        if let materials = cubeNode.geometry?.materials {
            for i in 0..<6 {
                if i == frontFaceIndex { continue }
                if i >= materials.count { continue }
                
                // Use cached texture
                if let cachedTexture = context.coordinator.staticTextureCache[i] {
                    if materials[i].diffuse.contents as? UIImage !== cachedTexture {
                        materials[i].diffuse.contents = cachedTexture
                        materials[i].emission.contents = UIColor.black
                    }
                }
            }
        }
    }
    
    // MARK: - Scene Construction
    
    private func makeScene(faceOrder: [Int], coordinator: Coordinator) -> SCNScene {
        let scene = SCNScene()
        
        // 1. Camera
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.camera?.wantsHDR = true
        cameraNode.camera?.exposureOffset = 0.5
        cameraNode.position = SCNVector3(0, 0, 4.8)
        scene.rootNode.addChildNode(cameraNode)
        
        // 2. Lighting
        let rimLight = SCNLight()
        rimLight.type = .spot
        rimLight.intensity = 1500
        rimLight.spotInnerAngle = 0
        rimLight.spotOuterAngle = 90
        rimLight.color = UIColor(white: 0.9, alpha: 1.0)
        let rimNode = SCNNode()
        rimNode.light = rimLight
        rimNode.position = SCNVector3(-5, 5, -2)
        rimNode.look(at: SCNVector3(0,0,0))
        scene.rootNode.addChildNode(rimNode)
        
        let keyLight = SCNLight()
        keyLight.type = .omni
        keyLight.intensity = 800
        let keyNode = SCNNode()
        keyNode.light = keyLight
        keyNode.position = SCNVector3(5, 3, 8)
        scene.rootNode.addChildNode(keyNode)
        
        let fillLight = SCNLight()
        fillLight.type = .omni
        fillLight.intensity = 300
        let fillNode = SCNNode()
        fillNode.light = fillLight
        fillNode.position = SCNVector3(-5, -5, 5)
        scene.rootNode.addChildNode(fillNode)
        
        scene.lightingEnvironment.contents = UIColor(white: 0.2, alpha: 1.0)
        
        // 3. Geometry
        let box = SCNBox(width: 3.0, height: 3.0, length: 3.0, chamferRadius: 0.35)
        
        var materials: [SCNMaterial] = []
        for i in 0..<6 {
            let mat = SCNMaterial()
            mat.lightingModel = .physicallyBased
            mat.diffuse.contents = UIColor(white: 0.05, alpha: 1.0)
            mat.metalness.contents = 0.1
            mat.roughness.contents = 0.15
            mat.specular.contents = UIColor(white: 0.5, alpha: 1.0)
            
            // PRE-GENERATE and CACHE static textures
            let faceIdx = faceOrder[i]
            let labels = ["25", "5", "15", "10", "30", "50"]
            if faceIdx < labels.count {
                if let staticImg = generateStaticFaceImage(text: labels[faceIdx]) {
                    coordinator.staticTextureCache[i] = staticImg
                    mat.diffuse.contents = staticImg
                }
            }
            
            materials.append(mat)
        }
        
        box.materials = materials
        let cubeNode = SCNNode(geometry: box)
        scene.rootNode.addChildNode(cubeNode)
        
        return scene
    }
    
    // MARK: - Image Generation (Optimized resolution: 1024x1024)
    
    private func generateDigitalTimerImage(timeText: String, progress: Double, color: Color, isActive: Bool) -> UIImage? {
        let size = CGSize(width: 1024, height: 1024)
        UIGraphicsBeginImageContextWithOptions(size, true, 1.0)
        guard let ctx = UIGraphicsGetCurrentContext() else { return nil }
        
        // Background
        UIColor.black.setFill()
        ctx.fill(CGRect(origin: .zero, size: size))
        
        // Parse time string "MM SS" -> draw as 7-segment
        let components = timeText.replacingOccurrences(of: " ", with: "")
        
        // Draw 7-segment digits
        let digitWidth: CGFloat = 130
        let digitHeight: CGFloat = 230
        let spacing: CGFloat = 25
        let colonWidth: CGFloat = 30
        
        // Calculate total width: 4 digits + colon
        let totalWidth = (digitWidth * 4) + (spacing * 3) + colonWidth
        let startX = (size.width - totalWidth) / 2
        let startY = (size.height - digitHeight) / 2
        
        var xOffset = startX
        
        for (index, char) in components.enumerated() {
            if index == 2 {
                // Draw colon
                draw7SegmentColon(ctx: ctx, x: xOffset, y: startY, height: digitHeight)
                xOffset += colonWidth + spacing
            }
            
            if let digit = Int(String(char)) {
                draw7SegmentDigit(ctx: ctx, digit: digit, x: xOffset, y: startY, width: digitWidth, height: digitHeight)
            }
            xOffset += digitWidth + spacing
        }
        
        let result = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return result
    }
    
    // 7-segment digit renderer
    private func draw7SegmentDigit(ctx: CGContext, digit: Int, x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat) {
        // Segment definitions: [a, b, c, d, e, f, g]
        // a = top, b = top-right, c = bottom-right, d = bottom, e = bottom-left, f = top-left, g = middle
        let segments: [[Bool]] = [
            [true,  true,  true,  true,  true,  true,  false], // 0
            [false, true,  true,  false, false, false, false], // 1
            [true,  true,  false, true,  true,  false, true],  // 2
            [true,  true,  true,  true,  false, false, true],  // 3
            [false, true,  true,  false, false, true,  true],  // 4
            [true,  false, true,  true,  false, true,  true],  // 5
            [true,  false, true,  true,  true,  true,  true],  // 6
            [true,  true,  true,  false, false, false, false], // 7
            [true,  true,  true,  true,  true,  true,  true],  // 8
            [true,  true,  true,  true,  false, true,  true],  // 9
        ]
        
        let segmentOn = segments[digit]
        let segmentThickness: CGFloat = 20
        let gap: CGFloat = 6
        
        // Special case: Center the digit '1' for better optical balance
        // Standard 7-segment '1' is right-aligned (segments B+C).
        // We shift it left to the center of the slot.
        // Shift = -(width/2 - thickness/2)
        var xOffset: CGFloat = 0
        if digit == 1 {
            xOffset = -(width/2 - segmentThickness/2)
        }
        
        UIColor.white.setFill()
        
        // Segment A (top horizontal)
        if segmentOn[0] {
            let path = UIBezierPath()
            path.move(to: CGPoint(x: x + gap + segmentThickness, y: y))
            path.addLine(to: CGPoint(x: x + width - gap - segmentThickness, y: y))
            path.addLine(to: CGPoint(x: x + width - gap - segmentThickness - segmentThickness/2, y: y + segmentThickness))
            path.addLine(to: CGPoint(x: x + gap + segmentThickness + segmentThickness/2, y: y + segmentThickness))
            path.close()
            path.fill()
        }
        
        // Segment B (top-right vertical)
        if segmentOn[1] {
            let path = UIBezierPath()
            // Apply xOffset to shift B if it's a 1
            let bx = x + width + xOffset
            path.move(to: CGPoint(x: bx, y: y + gap + segmentThickness))
            path.addLine(to: CGPoint(x: bx, y: y + height/2 - gap))
            path.addLine(to: CGPoint(x: bx - segmentThickness/2, y: y + height/2))
            path.addLine(to: CGPoint(x: bx - segmentThickness, y: y + height/2 - gap))
            path.addLine(to: CGPoint(x: bx - segmentThickness, y: y + gap + segmentThickness + segmentThickness/2))
            path.close()
            path.fill()
        }
        
        // Segment C (bottom-right vertical)
        if segmentOn[2] {
            let path = UIBezierPath()
            let cx = x + width + xOffset
            path.move(to: CGPoint(x: cx - segmentThickness/2, y: y + height/2))
            path.addLine(to: CGPoint(x: cx, y: y + height/2 + gap))
            path.addLine(to: CGPoint(x: cx, y: y + height - gap - segmentThickness))
            path.addLine(to: CGPoint(x: cx - segmentThickness, y: y + height - gap - segmentThickness - segmentThickness/2))
            path.addLine(to: CGPoint(x: cx - segmentThickness, y: y + height/2 + gap))
            path.close()
            path.fill()
        }
        
        // Segment D (bottom horizontal)
        if segmentOn[3] {
            let path = UIBezierPath()
            path.move(to: CGPoint(x: x + gap + segmentThickness + segmentThickness/2, y: y + height - segmentThickness))
            path.addLine(to: CGPoint(x: x + width - gap - segmentThickness - segmentThickness/2, y: y + height - segmentThickness))
            path.addLine(to: CGPoint(x: x + width - gap - segmentThickness, y: y + height))
            path.addLine(to: CGPoint(x: x + gap + segmentThickness, y: y + height))
            path.close()
            path.fill()
        }
        
        // Segment E (bottom-left vertical)
        if segmentOn[4] {
            let path = UIBezierPath()
            path.move(to: CGPoint(x: x + segmentThickness/2, y: y + height/2))
            path.addLine(to: CGPoint(x: x + segmentThickness, y: y + height/2 + gap))
            path.addLine(to: CGPoint(x: x + segmentThickness, y: y + height - gap - segmentThickness - segmentThickness/2))
            path.addLine(to: CGPoint(x: x, y: y + height - gap - segmentThickness))
            path.addLine(to: CGPoint(x: x, y: y + height/2 + gap))
            path.close()
            path.fill()
        }
        
        // Segment F (top-left vertical)
        if segmentOn[5] {
            let path = UIBezierPath()
            path.move(to: CGPoint(x: x, y: y + gap + segmentThickness))
            path.addLine(to: CGPoint(x: x + segmentThickness, y: y + gap + segmentThickness + segmentThickness/2))
            path.addLine(to: CGPoint(x: x + segmentThickness, y: y + height/2 - gap))
            path.addLine(to: CGPoint(x: x + segmentThickness/2, y: y + height/2))
            path.addLine(to: CGPoint(x: x, y: y + height/2 - gap))
            path.close()
            path.fill()
        }
        
        // Segment G (middle horizontal)
        if segmentOn[6] {
            let path = UIBezierPath()
            path.move(to: CGPoint(x: x + segmentThickness/2, y: y + height/2))
            path.addLine(to: CGPoint(x: x + gap + segmentThickness, y: y + height/2 - segmentThickness/2))
            path.addLine(to: CGPoint(x: x + width - gap - segmentThickness, y: y + height/2 - segmentThickness/2))
            path.addLine(to: CGPoint(x: x + width - segmentThickness/2, y: y + height/2))
            path.addLine(to: CGPoint(x: x + width - gap - segmentThickness, y: y + height/2 + segmentThickness/2))
            path.addLine(to: CGPoint(x: x + gap + segmentThickness, y: y + height/2 + segmentThickness/2))
            path.close()
            path.fill()
        }
    }
    
    // Draw colon separator
    private func draw7SegmentColon(ctx: CGContext, x: CGFloat, y: CGFloat, height: CGFloat) {
        UIColor.white.setFill()
        let dotSize: CGFloat = 20
        
        // Top dot
        let topDot = CGRect(x: x + 5, y: y + height * 0.3, width: dotSize, height: dotSize)
        ctx.fillEllipse(in: topDot)
        
        // Bottom dot
        let bottomDot = CGRect(x: x + 5, y: y + height * 0.6, width: dotSize, height: dotSize)
        ctx.fillEllipse(in: bottomDot)
    }
    
    private func generateStaticFaceImage(text: String) -> UIImage? {
        let size = CGSize(width: 1024, height: 1024)
        UIGraphicsBeginImageContextWithOptions(size, true, 1.0) // Opaque + scale 1
        
        UIColor(white: 0.05, alpha: 1.0).setFill()
        UIGraphicsGetCurrentContext()?.fill(CGRect(origin: .zero, size: size))
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        
        let fontSize: CGFloat = 549 // Reduced by 2%
        let fontDescriptor = UIFont.systemFont(ofSize: fontSize, weight: .black).fontDescriptor.withDesign(.rounded) ?? UIFont.systemFont(ofSize: fontSize, weight: .black).fontDescriptor
        let font = UIFont(descriptor: fontDescriptor, size: fontSize)
        
        // Calculate total block height to center everything vertically
        let spacing: CGFloat = 20
        let minFontSize: CGFloat = 80
        let minFont = UIFont.systemFont(ofSize: minFontSize, weight: .bold)
        
        // Approximate height cap for the number font
        let numberBlockHeight = fontSize * 0.75 // Cap height approx
        let minBlockHeight = minFontSize
        let totalHeight = numberBlockHeight + spacing + minBlockHeight
        
        let startY = (size.height - totalHeight) / 2
        
        let attrs: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: UIColor.white,
            .paragraphStyle: paragraphStyle
        ]
        
        // Draw Number
        // Adjust Y to top of the block
        let textRect = CGRect(x: 0, y: startY - (fontSize * 0.12), width: size.width, height: fontSize + 100)
        (text as NSString).draw(in: textRect, withAttributes: attrs)
        
        // Draw "MIN" label
        let minAttrs: [NSAttributedString.Key: Any] = [
            .font: minFont,
            .foregroundColor: UIColor.gray,
            .paragraphStyle: paragraphStyle
        ]
        let minRect = CGRect(x: 0, y: startY + numberBlockHeight + spacing, width: size.width, height: 100)
        ("MIN" as NSString).draw(in: minRect, withAttributes: minAttrs)
        
        let result = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return result
    }
    
    // Face Detection
    private func detectFrontFaceIndex(cubeNode: SCNNode, scene: SCNScene) -> Int? {
        let faceNormals = [
            SCNVector3(0, 0, 1),
            SCNVector3(1, 0, 0),
            SCNVector3(0, 0, -1),
            SCNVector3(-1, 0, 0),
            SCNVector3(0, 1, 0),
            SCNVector3(0, -1, 0)
        ]
        
        guard let cameraNode = scene.rootNode.childNodes.first(where: { $0.camera != nil }) else { return nil }
        let cameraForward = cameraNode.worldFront
        
        var maxDot: Float = -Float.greatestFiniteMagnitude
        var frontFaceIndex: Int?
        
        for (index, localNormal) in faceNormals.enumerated() {
            let worldNormal = cubeNode.worldOrientation.act(localNormal)
            let dot = worldNormal.x * (-cameraForward.x) + worldNormal.y * (-cameraForward.y) + worldNormal.z * (-cameraForward.z)
            if dot > maxDot {
                maxDot = dot
                frontFaceIndex = index
            }
        }
        return frontFaceIndex
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator: NSObject {
        var lastFrontFaceIndex: Int?
        var timer: Timer?
        var cubeNode: SCNNode?
        var faceOrder: [Int] = [0, 1, 5, 2, 3, 4]
        
        // PERFORMANCE: Cache static textures
        var staticTextureCache: [Int: UIImage] = [:]
        var lastTimerKey: String = ""
        
        private var lastPanLocation: CGPoint?
        
        deinit {
            timer?.invalidate()
        }
        
        func startFloatingAnimation() {
            guard let node = cubeNode else { return }
            let moveUp = SCNAction.moveBy(x: 0, y: 0.1, z: 0, duration: 3.0)
            moveUp.timingMode = .easeInEaseOut
            let moveDown = SCNAction.moveBy(x: 0, y: -0.1, z: 0, duration: 3.0)
            moveDown.timingMode = .easeInEaseOut
            let sequence = SCNAction.sequence([moveUp, moveDown])
            node.runAction(SCNAction.repeatForever(sequence), forKey: "floating")
        }
        
        func startMonitoring(scene: SCNScene, cube: PomodoroCube) {
            timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
                guard let self = self, let cubeNode = self.cubeNode else { return }
                
                let faceNormals = [
                    SCNVector3(0, 0, 1),
                    SCNVector3(1, 0, 0),
                    SCNVector3(0, 0, -1),
                    SCNVector3(-1, 0, 0),
                    SCNVector3(0, 1, 0),
                    SCNVector3(0, -1, 0)
                ]
                
                guard let cameraNode = scene.rootNode.childNodes.first(where: { $0.camera != nil }) else { return }
                let cameraForward = cameraNode.worldFront
                
                var maxDot: Float = -Float.greatestFiniteMagnitude
                var frontFaceIndex: Int?
                
                for (index, localNormal) in faceNormals.enumerated() {
                    let worldNormal = cubeNode.worldOrientation.act(localNormal)
                    let dot = worldNormal.x * (-cameraForward.x) + worldNormal.y * (-cameraForward.y) + worldNormal.z * (-cameraForward.z)
                    if dot > maxDot {
                        maxDot = dot
                        frontFaceIndex = index
                    }
                }
                
                if let idx = frontFaceIndex, idx < self.faceOrder.count {
                    let mappedIdx = self.faceOrder[idx]
                    
                    if self.lastFrontFaceIndex != idx {
                        let isFirstDetection = self.lastFrontFaceIndex == nil
                        self.lastFrontFaceIndex = idx
                        
                        // ONLY select face if this is NOT the first detection (app launch)
                        // OR if you prefer: only if user rotated.
                        if !isFirstDetection {
                            DispatchQueue.main.async {
                                if mappedIdx < cube.faces.count {
                                    let face = cube.faces[mappedIdx]
                                    cube.select(face: face)
                                }
                            }
                        }
                    }
                }
            }
        }
        
        @objc func handlePan(_ sender: UIPanGestureRecognizer) {
            guard let cubeNode = cubeNode else { return }
            let location = sender.location(in: sender.view)
            
            switch sender.state {
            case .began:
                lastPanLocation = location
            case .changed:
                if let lastLocation = lastPanLocation {
                    let deltaX = Float(location.x - lastLocation.x)
                    let deltaY = Float(location.y - lastLocation.y)
                    let sensitivity: Float = 0.012
                    
                    var newPitch = cubeNode.eulerAngles.x + (-deltaY * sensitivity)
                    let pitchLimit: Float = .pi / 2 * 0.99
                    newPitch = max(min(newPitch, pitchLimit), -pitchLimit)
                    let newYaw = cubeNode.eulerAngles.y + (deltaX * sensitivity)
                    
                    cubeNode.eulerAngles.x = newPitch
                    cubeNode.eulerAngles.y = newYaw
                    lastPanLocation = location
                }
            case .ended, .cancelled, .failed:
                lastPanLocation = nil
                
                let faceEulerAngles: [SCNVector3] = [
                    SCNVector3(0, 0, 0),
                    SCNVector3(0, -Float.pi / 2, 0),
                    SCNVector3(0, Float.pi, 0),
                    SCNVector3(0, Float.pi / 2, 0),
                    SCNVector3(-Float.pi / 2, 0, 0),
                    SCNVector3(Float.pi / 2, 0, 0)
                ]
                
                let current = cubeNode.eulerAngles
                var bestIndex = 0
                var bestDistance = Float.greatestFiniteMagnitude
                
                for (index, canonical) in faceEulerAngles.enumerated() {
                    func angleDiff(_ a: Float, _ b: Float) -> Float {
                        var diff = a - b
                        while diff > Float.pi { diff -= 2 * Float.pi }
                        while diff < -Float.pi { diff += 2 * Float.pi }
                        return diff
                    }
                    let dx = angleDiff(current.x, canonical.x)
                    let dy = angleDiff(current.y, canonical.y)
                    let dist = dx * dx + dy * dy
                    if dist < bestDistance {
                        bestDistance = dist
                        bestIndex = index
                    }
                }
                
                SCNTransaction.begin()
                SCNTransaction.animationDuration = 0.3
                SCNTransaction.animationTimingFunction = CAMediaTimingFunction(name: .easeOut)
                cubeNode.eulerAngles = faceEulerAngles[bestIndex]
                SCNTransaction.commit()
                
            default:
                break
            }
        }
    }
}

private extension SCNQuaternion {
    func act(_ v: SCNVector3) -> SCNVector3 {
        let q = self
        let vq = SCNQuaternion(v.x, v.y, v.z, 0)
        let qConj = SCNQuaternion(-q.x, -q.y, -q.z, q.w)
        let rotated = q * vq * qConj
        return SCNVector3(rotated.x, rotated.y, rotated.z)
    }
}
private func *(lhs: SCNQuaternion, rhs: SCNQuaternion) -> SCNQuaternion {
    let w = lhs.w * rhs.w - lhs.x * rhs.x - lhs.y * rhs.y - lhs.z * rhs.z
    let x = lhs.w * rhs.x + lhs.x * rhs.w + lhs.y * rhs.z - lhs.z * rhs.y
    let y = lhs.w * rhs.y - lhs.x * rhs.z + lhs.y * rhs.w + lhs.z * rhs.x
    let z = lhs.w * rhs.z + lhs.x * rhs.y - lhs.y * rhs.x + lhs.z * rhs.w
    return SCNQuaternion(x, y, z, w)
}

private extension SCNNode {
    var worldFront: SCNVector3 {
        let localForward = SCNVector3(0, 0, -1)
        return worldOrientation.act(localForward)
    }
}
