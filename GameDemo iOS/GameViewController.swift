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
        setupGestures()
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .landscapeLeft
    }

    override var prefersStatusBarHidden: Bool {
        return true
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
            
            print("acceleration y:", y.twoDecimals)
            
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
            
            self.udpSocket.sendMessage([
                MessageKey.actionName.rawValue: ClientAction.accelerate.rawValue,
                MessageKey.impulse.rawValue: xOffset,
            ])
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
    
//    lazy var udpSocket = UdpClientSocket(remoteHost: "172.20.10.7", port: 4002, delegate: self)
    lazy var udpSocket = UdpClientSocket(remoteHost: "192.168.241.64", port: 4002, delegate: self)
    private func send(action: ClientAction, for messageKey: MessageKey) {
        udpSocket.sendMessage([
            messageKey.rawValue: action.rawValue
        ])
        scene?.hanle(client: action)
    }
    
    //MARK: ---------- handle actions ---------
    func handleAction(_ dic: [String: Any]) {
        switch SeverAction(rawValue: dic[MessageKey.actionName.rawValue] as! String) {
        case .impactFeedback:
            startVibrate(.init(rawValue: dic[MessageKey.feedbackStyle.rawValue] as! Int)!)
        default:
            break
        }
    }
    
    //MARK: ---------- gestures ---------
    func setupGestures() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(didTapSelf))
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(didLongPress(sender:)))
        
        [tap, longPress].forEach({ view.addGestureRecognizer($0) })
    }
        
    @objc func didTapSelf() {
        send(action: .didTap, for: .actionName)
//        udpSocket.sendMessage([
//            MessageKey.actionName.rawValue: ClientAction.didTap.rawValue
//        ])
    }
    
    @objc private func didLongPress(sender: UIGestureRecognizer) {
        switch sender.state {
        case .began:
            send(action: .startLongPress, for: .actionName)
//            udpSocket.sendMessage([
//                MessageKey.actionName.rawValue: ClientAction.startLongPress.rawValue
//            ])
        case .cancelled, .ended, .failed:
            send(action: .stopLongPress, for: .actionName)
//            udpSocket.sendMessage([
//                MessageKey.actionName.rawValue: ClientAction.stopLongPress.rawValue
//            ])
        default:
            break
        }
    }
}

extension GameViewController: SocketDelegate {
    func socket(_ socket: SocketProtocol, didReceiveMessages messages: [[String : Any]]) {
        messages.forEach { msg in
            handleAction(msg)
        }
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
