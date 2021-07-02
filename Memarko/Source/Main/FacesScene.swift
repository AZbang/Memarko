import CoreMotion
import SpriteKit
import UIKit

extension SKSpriteNode {
    func drawBorder(color: UIColor, width: CGFloat) {
        let shapeNode = SKShapeNode(circleOfRadius: size.width/2 / xScale)
        shapeNode.fillColor = .clear
        shapeNode.strokeColor = color
        shapeNode.lineWidth = width
        addChild(shapeNode)
    }
}

class MemarkoObject: SKSpriteNode {
    var loader: SKLabelNode
    var progress: SKShapeNode
    var memarko: Memarko?

    var scale = 1
    let colors = [#colorLiteral(red: 0.2365181744, green: 0.3842029572, blue: 1, alpha: 1), #colorLiteral(red: 0.8078431487, green: 0.02745098062, blue: 0.3333333433, alpha: 1), #colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1), #colorLiteral(red: 0.4666666687, green: 0.7647058964, blue: 0.2666666806, alpha: 1), #colorLiteral(red: 0.2392156869, green: 0.6745098233, blue: 0.9686274529, alpha: 1), #colorLiteral(red: 1, green: 0.293546468, blue: 0.8182056546, alpha: 1)]
    
    convenience init(scene: SKScene, memarko: Memarko) {
        let value = Int.random(in: 80..<130)
        let size = CGSize(width: value, height: value)
        let texture = SKTexture(image: memarko.photo.circleMasked()!)

        self.init(texture: texture)
        self.memarko = memarko
        self.scale(to: size)

        self.position = CGPoint(x: scene.frame.width/2, y: scene.frame.height/2 - 200)
        self.drawBorder(color: colors.randomElement()!, width: 10 / self.xScale)
        self.zPosition = 1

        self.loader = SKLabelNode(text: "0%")
        self.loader.zPosition = 4
        self.loader.horizontalAlignmentMode = .center
        self.loader.verticalAlignmentMode = .center
        self.loader.fontSize = 20 / self.xScale
        self.loader.fontName = "Futura"
        self.loader.fontColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        self.addChild(self.loader)

        //let crop = SKCropNode()
        //crop.maskNode = SKShapeNode(circleOfRadius: size.width/2)
        self.progress = SKShapeNode(circleOfRadius: self.size.width/2)
        self.progress.fillColor = #colorLiteral(red: 0.2365181744, green: 0.3842029572, blue: 1, alpha: 1)
        self.progress.zPosition = 2
        self.progress.xScale += 0.1
        self.progress.yScale += 0.1
        //sprite.addChild(self.progress)
        
        self.physicsBody = SKPhysicsBody(circleOfRadius: size.width/2 + 5)
        self.physicsBody?.isDynamic = true
        self.physicsBody?.allowsRotation = true
        self.physicsBody?.restitution = 0.7
        self.physicsBody?.friction = 1
    }
    
    override init(texture: SKTexture!, color: UIColor, size: CGSize) {
        self.loader = SKLabelNode()
        self.progress = SKShapeNode()
        super.init(texture: texture, color: color, size: size)
    }
    
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func tap() {
        self.memarko?.shareStickers()
    }
        
    func update() {
        guard let memarko = self.memarko else { return }
        if (memarko.error != nil && self.parent != nil) {
            self.removeFromParent() // TODO: Removing animation
        }
    
        // TODO: Loading animation
        self.loader.alpha = 1 - CGFloat(memarko.progress)/100
        self.loader.text = "\(memarko.progress)%"
    }
}



class FacesScene: SKScene {
    private let motionManager = CMMotionManager()
    private var dragNode: SKNode?
    private var dragJoint: SKPhysicsJointPin?
    private var memas: [MemarkoObject] = []
    
    private var initialTouch = CGPoint(x: 0, y: 0)
    private var isTapped = false
    
    override func didMove(to view: SKView) {
        self.backgroundColor = .clear
        physicsBody = SKPhysicsBody(edgeLoopFrom: frame.inset(by: UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)))
        
        let node = SKNode()
        node.position = CGPoint(x: size.width/2, y: size.height/2)
        node.physicsBody = SKPhysicsBody(circleOfRadius: 55)
        node.physicsBody?.isDynamic = false
        addChild(node)
        
        motionManager.startAccelerometerUpdates()
    }
    
    public func addDroplet(memarko: Memarko) {
        let object = MemarkoObject(scene: self, memarko: memarko)
        self.memas.append(object)
        self.addChild(object)

        for body in self.children {
            let dx = (Bool.random() ? -1 : 1) * Int.random(in: 100...200)
            let dy = -Int.random(in: 100...300)
            body.physicsBody?.applyImpulse(CGVector(dx: dx, dy: dy))
        }
    }
    
    
    func stopDragging() {
        // Remove the joint and the drag node.
        if (dragJoint != nil) {
            self.physicsWorld.remove(dragJoint!)
            dragNode?.removeFromParent()
            dragNode = nil
            dragJoint = nil
        }
  
    }

    override func update(_ currentTime: TimeInterval) {
        self.memas.forEach { object in object.update() }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.stopDragging()
        
        if (!self.isTapped) { return }
        self.isTapped = false

        if let touch = touches.first {
            let touchPosition = touch.location(in: self)
            let touchedNodes = self.nodes(at: touchPosition)
            let object = touchedNodes.first { (node) -> Bool in node is MemarkoObject }
            if object is MemarkoObject { (object as! MemarkoObject).tap() }
        }
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.stopDragging()
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first, let node = self.dragNode {
            let touchLocation = touch.location(in: self)
            self.isTapped = initialTouch.distance(to: touchLocation) < 10;
            node.position = touchLocation
        }
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            let touchPosition = touch.location(in: self)
            let touchedNodes = self.nodes(at: touchPosition)
            let touchedNode = touchedNodes.first { (node) -> Bool in node.physicsBody != nil }
        
            // Make sure that we're touching something that _can_ be dragged
            if touchedNode == dragNode || touchedNode == nil {
                return
            }
        
            // Create the invisible drag node, with a small static body
            let newDragNode = SKNode()
            newDragNode.position = touchPosition
            newDragNode.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: 10, height: 10))
            newDragNode.physicsBody?.isDynamic = false
            self.addChild(newDragNode)
            self.initialTouch = touchPosition
            self.isTapped = true
            
            // Link this new node to the object that got touched
            let newDragJoint = SKPhysicsJointPin.joint(
                withBodyA: touchedNode!.physicsBody!,
                bodyB:newDragNode.physicsBody!,
                anchor: touchPosition
            )
            
            self.physicsWorld.add(newDragJoint)
            self.dragNode = newDragNode
            self.dragJoint = newDragJoint
            
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
        }
    }
}
