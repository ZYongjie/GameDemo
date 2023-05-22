//
//  GameScene.swift
//  GameDemo Shared
//
//  Created by yongjie on 2023/4/28.
//

import SpriteKit

protocol CarGameSceneDelegate: AnyObject {
    func scene(didContactTrack scene: GameScene)
    func scene(didContactObstacle scene: GameScene)
}

class GameScene: SKScene, SKPhysicsContactDelegate {
    enum State {
        case idle, playing, over, passed
    }
    var state = State.idle
    
    let carSpeed: CGFloat = 200
    let maxCarSpeed: CGFloat = 500
    
    let carCategoryMask: UInt32 = 1
    let edgeCategoryMask: UInt32 = 1 << 1
    let obstacleCategoryMask: UInt32 = 1 << 2
    
    let noCollisionCategoryMask: UInt32 = 1 << 31
    
    weak var carDelegate: CarGameSceneDelegate?
    fileprivate var label : SKLabelNode?
    var des : SKLabelNode?
    var car: SKSpriteNode!
    lazy var bg = SKScrollingNode.scrollingNode("back", containerSize: size)
    fileprivate var spinnyNode : SKShapeNode?

    
    class func newGameScene() -> GameScene {
        // Load 'GameScene.sks' as an SKScene.
        guard let scene = SKScene(fileNamed: "GameScene") as? GameScene else {
            print("Failed to load GameScene.sks")
            abort()
        }
        
        // Set the scale mode to scale to fit the window
        scene.scaleMode = .aspectFill
//        scene.scaleMode = .resizeFill
        
        return scene
    }
    
    func replay() {
        removeAllChildren()
        setUpScene()
    }
    
    func setUpScene() {
        physicsWorld.contactDelegate = self
        
        bg.anchorPoint = .zero
        bg.position = .init(x: -1366 / 2, y: -1024 / 2)
        bg.physicsBody = .init()
        bg.physicsBody?.affectedByGravity = false
        addChild(bg)
        
        // Get label node from scene and store it for use later
        self.label = self.childNode(withName: "//helloLabel") as? SKLabelNode
        self.des = self.childNode(withName: "//des") as? SKLabelNode
        if let label = self.label {
            label.alpha = 0.0
            label.run(SKAction.fadeIn(withDuration: 2.0))
        }
        
        // Create shape node to use during mouse interaction
        let w = (self.size.width + self.size.height) * 0.05
        self.spinnyNode = SKShapeNode.init(rectOf: CGSize.init(width: w, height: w), cornerRadius: w * 0.3)
        
        if let spinnyNode = self.spinnyNode {
            spinnyNode.lineWidth = 4.0
            spinnyNode.run(SKAction.repeatForever(SKAction.rotate(byAngle: CGFloat(Double.pi), duration: 1)))
            spinnyNode.run(SKAction.sequence([SKAction.wait(forDuration: 0.5),
                                              SKAction.fadeOut(withDuration: 0.5),
                                              SKAction.removeFromParent()]))
        }
        
        label?.isHidden = true
        
        createTrack()
        
        let carWidth: CGFloat = 200
//        car = SKSpriteNode(imageNamed: "car")
        car = SKSpriteNode(color: .blue, size: .zero)
        car.size = .init(width: carWidth, height: 4320.0 / 7680 * carWidth)
        car.position = .init(x: 0, y: -200)
        car.physicsBody = .init(rectangleOf: car.size)
        car.physicsBody?.categoryBitMask = carCategoryMask
        car.physicsBody?.contactTestBitMask = 0xFFFFFFFF
        car.physicsBody?.collisionBitMask = 0xFFFFFFFF ^ noCollisionCategoryMask
        car.physicsBody?.affectedByGravity = false
        addChild(car)
        
        let camera = SKCameraNode()
        camera.physicsBody = .init()
        camera.physicsBody?.affectedByGravity = false
        addChild(camera)
        self.camera = camera
        
        setupPhysicsSpeed(dy: carSpeed)
        
        makeObstacle()
        currentMediaIndex = 0
        makeMedia()
        
        state = .playing
    }
    
    override func didMove(to view: SKView) {
        self.setUpScene()
    }
    
    override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
    }
    
    lazy var leftTrack = SKShapeNode(rect: .init(x: -500, y: -size.height / 2, width: 2, height: size.height))
    lazy var rightTrack = SKShapeNode(rect: .init(x: 500, y: -size.height / 2, width: 2, height: size.height))
    func createTrack() {
        leftTrack.fillColor = .blue
        leftTrack.physicsBody = .init(rectangleOf: leftTrack.frame.size, center: .init(x: leftTrack.frame.origin.x, y: 0))
        leftTrack.physicsBody?.affectedByGravity = false
        leftTrack.physicsBody?.isDynamic = false
        leftTrack.physicsBody?.categoryBitMask = edgeCategoryMask
        leftTrack.physicsBody?.friction = 0
        addChild(leftTrack)
        
        rightTrack.fillColor = .blue
        rightTrack.physicsBody = .init(rectangleOf: rightTrack.frame.size, center: .init(x: rightTrack.frame.origin.x, y: 0))
        rightTrack.physicsBody?.affectedByGravity = false
        rightTrack.physicsBody?.isDynamic = false
        rightTrack.physicsBody?.categoryBitMask = edgeCategoryMask
        rightTrack.physicsBody?.friction = 0
        addChild(rightTrack)
    }
    
    func setupPhysicsSpeed(dy: CGFloat) {

        [
            bg.physicsBody,
            car.physicsBody,
            camera?.physicsBody
        ].forEach { body in
            body?.linearDamping = 0
            body?.velocity = .init(dx: 0, dy: dy)
        }
        
        bg.scrollingSpeed = dy / 100
    }
    
    var speedTimer: Timer?
    var speedUpOffset = 0.0
    @objc func speedUp() {
        
//        perform(#selector(speedUp), with: nil, afterDelay: 0.1)
        speedTimer = .scheduledTimer(withTimeInterval: 0.1, repeats: true, block: { [weak self] _ in
            guard let self = self, self.state == .playing, self.car.physicsBody!.velocity.dy <= self.maxCarSpeed else {
                self?.speedTimer?.invalidate()
                self?.speedTimer = nil
                return
            }
            
            self.setupPhysicsSpeed(dy: min(self.carSpeed + self.speedUpOffset, self.maxCarSpeed))
            self.speedUpOffset += 20
        })
        speedTimer?.fire()
    }
    
    func resetSpeed() {
        speedTimer?.invalidate()
        speedTimer = nil
        guard state == .playing else {
            return
        }
        setupPhysicsSpeed(dy: carSpeed)
    }

    func makeSpinny(at pos: CGPoint, color: SKColor) {
//        if let spinny = self.spinnyNode?.copy() as! SKShapeNode? {
//            spinny.position = pos
//            spinny.strokeColor = color
//            self.addChild(spinny)
//        }
    }
    
    var obstacles = [SKSpriteNode]()
    func makeObstacle()  {
        let obstacle = SKSpriteNode(color: .red, size: .init(width: 100, height: 100))
        let x = CGFloat((-300...300).randomElement() ?? 0)
        let y = CGFloat((0...200).randomElement() ?? 0) + car.position.y + 400
        obstacle.position = .init(x: x, y: y)
        obstacle.physicsBody = .init(rectangleOf: .init(width: 100, height: 100))
        obstacle.physicsBody?.contactTestBitMask = 1
        obstacle.physicsBody?.categoryBitMask = 1
        obstacle.physicsBody?.isDynamic = false
        addChild(obstacle)
        
        obstacles.append(obstacle)
    }
    
    lazy var audioPlay = AudioPlay()
    var media: SKNode?
    var mediaList = (97...122).map({Character(UnicodeScalar($0))})
//    var mediaList = (97...98).map({Character(UnicodeScalar($0))})
    var moodList = ["good_job", "well_done", "excellent", "great_job", "fantastic", "outstanding", "impressive", "terrific", "superb"]
    var currentMediaIndex = 0
    func makeMedia() {
        guard currentMediaIndex < mediaList.count else {
            return
        }
        let wrapper = SKSpriteNode(color: .purple, size: .init(width: 100, height: 100))
        let text = SKLabelNode(text: .init(mediaList[currentMediaIndex].uppercased()))
        text.fontSize = 50
        text.fontName = "PingFangSC-Medium"
        text.verticalAlignmentMode = .center
        let x = CGFloat((-300...300).randomElement() ?? 0)
        let y = CGFloat((0...200).randomElement() ?? 0) + car.position.y + 400
        wrapper.position = .init(x: x, y: y)
        wrapper.physicsBody = .init(rectangleOf: .init(width: 100, height: 100))
        wrapper.anchorPoint = .init(x: 0.5, y: 0.5)
        
        wrapper.physicsBody?.categoryBitMask = noCollisionCategoryMask
//        wrapper.physicsBody?.contactTestBitMask = 1
//        wrapper.physicsBody?.collisionBitMask = 0
        
//        wrapper.physicsBody.
//        wrapper.physicsBody?.isDynamic = false
        wrapper.physicsBody?.affectedByGravity = false
        wrapper.physicsBody?.density = 0
        wrapper.addChild(text)
        addChild(wrapper)
        media = wrapper
    }
    
    func applyImpulse(dx: CGFloat) {
        guard let carPhysicsBody = car.physicsBody,
              state == .playing else { return }
        
        let v = carPhysicsBody.velocity.dx
        if (v > 0 && dx < 0) || (v < 0 && dx > 0 || dx == 0) {
            carPhysicsBody.velocity = .init(dx: 0, dy: carPhysicsBody.velocity.dy)
        }
        carPhysicsBody.applyImpulse(.init(dx: dx, dy: 0))
    }
    
    func gameOver() {
        state = .over
        
        setupPhysicsSpeed(dy: 0)
        gameOverNode.position = .init(x: 0, y: car.position.y + 200)
        if gameOverNode.parent == nil  {
            addChild(gameOverNode)
        }
    }
    
    func gamePassed() {
        state = .passed
        
        setupPhysicsSpeed(dy: 0)
        gamePassedNode.position = .init(x: 0, y: car.position.y + 200)
        if gamePassedNode.parent == nil  {
            addChild(gamePassedNode)
        }
    }
    
    lazy var gameOverNode: SKNode = {
        let bg = SKSpriteNode(color: .gray.withAlphaComponent(0.3), size: .init(width: 500, height: 400))
        let over = SKLabelNode(text: "Game over ❌")
        over.fontSize = 100
        over.fontName = "PingFangSC-Medium"
        over.fontColor = .orange
        bg.addChild(over)
        
        return bg
    }()
    
    lazy var gamePassedNode: SKNode = {
        let bg = SKSpriteNode(color: .gray.withAlphaComponent(0.3), size: .init(width: 500, height: 400))
        let passed = SKLabelNode(text: "Passed ✅")
        passed.fontSize = 100
        passed.fontName = "PingFangSC-Medium"
        passed.fontColor = .orange
        bg.addChild(passed)
        
        return bg
    }()
    
    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
        
        bg.update(currentTime)
//        print("car: ", car.physicsBody!.velocity.dy, car.position, "camera", camera!.physicsBody!.velocity.dy, camera!.position, leftTrack.position)
        
        [leftTrack, rightTrack]
            .forEach { track in
                track.position = .init(x: track.position.x, y: camera!.position.y)
            }
        
        let notNeedObstacles = obstacles.filter { o in
            o.position.y < car.position.y && !camera!.contains(o)
        }
        removeChildren(in: notNeedObstacles)
        obstacles.removeAll(where: { notNeedObstacles.contains($0) })
        if obstacles.count < 2 {
            makeObstacle()
        }
        
        if let media = media, media.position.y < car.position.y , !camera!.contains(media), media.parent != nil {
            media.removeFromParent()
            makeMedia()
        }
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
//        print("-----------------", contact.bodyA, contact.bodyB)
        if obstacles.map({ $0.physicsBody }).contains(where: { $0 === contact.bodyA || $0 === contact.bodyB }) {
            carDelegate?.scene(didContactObstacle: self)
            gameOver()
        }
        if [leftTrack, rightTrack].map({ $0.physicsBody! }).contains(where: { $0 === contact.bodyA || $0 === contact.bodyB }) {
            carDelegate?.scene(didContactTrack: self)
        }
        
        if let media = media, Set(arrayLiteral: contact.bodyA, contact.bodyB) == Set(arrayLiteral: media.physicsBody!, car.physicsBody!) {
            print("======= contact media")
            media.removeFromParent()
            
            let index = currentMediaIndex
            let step = self.mediaList.count / self.moodList.count
            let playMood = step > 0 && (index + 1) % step == 0 && index < self.mediaList.count - 1
            
            DispatchQueue.global().async {
                self.audioPlay.play(character: self.mediaList[index])
                
                if playMood {
                    DispatchQueue.global().asyncAfter(deadline: .now() + 1)  {
                        self.audioPlay.play(mood: self.moodList[(index + 1) / step])
                    }
                }
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + (playMood ? 2 : 0)) {
                self.currentMediaIndex += 1
                self.makeMedia()
            }
            
            if currentMediaIndex == mediaList.count {
                gamePassed()
            }
        }
    }
    
    func didEnd(_ contact: SKPhysicsContact) {
    }
    
    override func didSimulatePhysics() {
        super.didSimulatePhysics()
    }
}

#if os(iOS) || os(tvOS)
// Touch-based event handling
extension GameScene {

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
//        if state == .over {
//            replay()
//        }
        if state == .playing {
            speedUpOffset = 1
            
            speedTimer?.invalidate()
            speedTimer = .scheduledTimer(withTimeInterval: 0.2, repeats: true, block: { [weak self] _ in
//                self?.speedUp()
            })
        }
        
        if let label = self.label {
            label.run(SKAction.init(named: "Pulse")!, withKey: "fadeInOut")
        }
        
        for t in touches {
            self.makeSpinny(at: t.location(in: self), color: SKColor.green)
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches {
            self.makeSpinny(at: t.location(in: self), color: SKColor.blue)
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches {
            self.makeSpinny(at: t.location(in: self), color: SKColor.red)
        }
        
//        resetSpeed()
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches {
            self.makeSpinny(at: t.location(in: self), color: SKColor.red)
        }
        
//        resetSpeed()
    }
}
#endif

#if os(OSX)
// Mouse-based event handling
extension GameScene {

    override func mouseDown(with event: NSEvent) {
        if state == .over {
            replay()
        }
        
        if let label = self.label {
            label.run(SKAction.init(named: "Pulse")!, withKey: "fadeInOut")
        }
        self.makeSpinny(at: event.location(in: self), color: SKColor.green)
    }
    
    override func mouseDragged(with event: NSEvent) {
        self.makeSpinny(at: event.location(in: self), color: SKColor.blue)
    }
    
    override func mouseUp(with event: NSEvent) {
        self.makeSpinny(at: event.location(in: self), color: SKColor.red)
    }

}
#endif

