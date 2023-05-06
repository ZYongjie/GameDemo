//
//  GameViewController.swift
//  GameDemo iOS
//
//  Created by yongjie on 2023/4/28.
//

import UIKit
import SpriteKit
import GameplayKit
import CoreMotion
import CocoaAsyncSocket
import AudioToolbox

class GameViewController: UIViewController {

    weak var scene: GameScene?
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let scene = GameScene.newGameScene()
        scene.carDelegate = self
        self.scene = scene

        // Present the scene
        let skView = self.view as! SKView
        skView.presentScene(scene)
        
//        skView.ignoresSiblingOrder = true
        skView.showsFPS = true
        skView.showsNodeCount = true
        skView.showsPhysics = true
        
        setupMotion()
        setupSocket()
    }
    
    private lazy var motionManager = CMMotionManager()
    private func setupMotion() {
        assert(motionManager.isAccelerometerAvailable)
        assert(motionManager.isGyroAvailable)
        
        motionManager.accelerometerUpdateInterval = 1 / 24
        motionManager.startAccelerometerUpdates(to: .main) { data, error in
            guard let data = data else { return }
            let y = data.acceleration.y
//            guard abs(y) > 0.02 else {
//                self.scene?.applyImpulse(dx: 0)
//                return
//            }
            
//            print("acceleration y:", y)
            
            var xOffset = 0.0
            switch abs(y) {
            case 0.04..<0.25:
                xOffset = y * 100
            case 0.25...0.5:
                xOffset = y * 300
            case 0.5...Double.infinity:
                xOffset = 0.5 * 1000 * (y > 0 ? 1 : -1)
            default:
                break
            }
            
            self.updateDes(", offset: \(xOffset.twoDecimals)")
//            self.scene?.changePosition(offset: .init(x: xOffset, y: 0))
            self.scene?.applyImpulse(dx: xOffset)
            
            if self.socket.isConnected {
                let d = [
                    "xOffset": xOffset,
                    "tag": self.tag
                ]
                
                var json = try! JSONSerialization.data(withJSONObject: d)
                json.append("---".data(using: .utf8)!)
                
                //TODO 发送频率过高，会导致消息积压，多条消息合并发送
                self.socket.write(json, withTimeout: 1, tag: self.tag)
                self.tag += 1
            }
        }
        
        motionManager.gyroUpdateInterval = 1 / 60
        motionManager.startGyroUpdates(to: .main) { data, error in
            guard let data = data else { return }
            
            let z = data.rotationRate.z
            guard abs(z) > 0.02 else { return }
//            print("ratation z", z)
            self.updateDes()
            
        }
    }
    
    func updateDes(_ other: String? = nil) {
        let aY = motionManager.accelerometerData?.acceleration.y ?? .nan
        let gZ = motionManager.gyroData?.rotationRate.z ?? .nan
        
        scene?.des?.text = "acceleration y: \(aY.twoDecimals)\n rotation z: \(gZ.twoDecimals)\n \(other ?? "")"
        
//        socket.write("\(aY)".data(using: .utf8), withTimeout: -1, tag: 1)
    }
    
    func startVibrate(_ level: UIImpactFeedbackGenerator.FeedbackStyle) {
//        AudioToolbox.AudioServicesPlaySystemSound(1519)
//        AudioToolbox.AudioServicesPlaySystemSound(1520)
//        AudioToolbox.AudioServicesPlaySystemSound(1521)
//        AudioToolbox.AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
        let generator = UIImpactFeedbackGenerator(style: level)
        generator.prepare()
        generator.impactOccurred()
    }
    
    var tag = 0
    lazy var socket = GCDAsyncSocket(delegate: self, delegateQueue: .main)
    func setupSocket() {
        do {
//            try socket.connect(toHost: "172.20.10.7", onPort: 4000, withTimeout: 3)
            try socket.connect(toHost: "192.168.241.64", onPort: 4000, withTimeout: 3)
        } catch let error {
            print("connect error", error)
        }
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .landscapeLeft
        if UIDevice.current.userInterfaceIdiom == .phone {
            return .allButUpsideDown
        } else {
            return .all
        }
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
}

extension GameViewController: GCDAsyncSocketDelegate {
    func socket(_ sock: GCDAsyncSocket, didConnectToHost host: String, port: UInt16) {
        
        print("!!!!!! connected !!!!!!")
    }
    
    func socketDidDisconnect(_ sock: GCDAsyncSocket, withError err: Error?) {
        print("disconnected", err)
    }
    
    func socket(_ sock: GCDAsyncSocket, didWriteDataWithTag tag: Int) {
    }
    
}

extension Double {
    var twoDecimals: Double {
        (self * 100).rounded() / 100
    }
}

extension GameViewController: CarGameSceneDelegate {
    func scene(didContactTrack scene: GameScene) {
        startVibrate(.light)
    }
    
    func scene(didContactObstacle scene: GameScene) {
        startVibrate(.heavy)
    }
    
    
}
