import CoreMotion
import SpriteKit
import UIKit

extension SKSpriteNode {
    func drawBorder(color: UIColor, width: CGFloat) {
        let shapeNode = SKShapeNode(circleOfRadius: size.width/2)
        shapeNode.fillColor = .clear
        shapeNode.strokeColor = color
        shapeNode.lineWidth = 40
        addChild(shapeNode)
    }
}

class MemarkoObject {
    var memarko: Memarko
    var sprite: SKSpriteNode
    var loader: SKLabelNode
    var progress: SKShapeNode
    
    init(scene: SKScene, memarko: Memarko) {
        self.memarko = memarko
        
        let value = Int.random(in: 80..<130)
        let size = CGSize(width: value, height: value)
        let texture = SKTexture(image: memarko.photo.circleMasked()!)
        
        sprite = SKSpriteNode(texture: texture)
        sprite.position = CGPoint(x: scene.frame.width/2, y: scene.frame.height/2)
        sprite.drawBorder(color: #colorLiteral(red: 0.2365181744, green: 0.3842029572, blue: 1, alpha: 1), width: 4)
        sprite.zPosition = 1

        self.loader = SKLabelNode(text: "0%")
        self.loader.zPosition = 4
        self.loader.horizontalAlignmentMode = .center
        self.loader.verticalAlignmentMode = .center
        self.loader.fontSize = 120
        self.loader.fontName = "Futura"
        self.loader.fontColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        sprite.addChild(self.loader)

        //let crop = SKCropNode()
        //crop.maskNode = SKShapeNode(circleOfRadius: size.width/2)
        self.progress = SKShapeNode(circleOfRadius: sprite.size.width/2)
        self.progress.fillColor = #colorLiteral(red: 0.2365181744, green: 0.3842029572, blue: 1, alpha: 1)
        self.progress.zPosition = 2
        self.progress.xScale += 0.1
        self.progress.yScale += 0.1
        //sprite.addChild(self.progress)
        
        sprite.scale(to:size)
        sprite.physicsBody = SKPhysicsBody(circleOfRadius: size.width/2)
        sprite.physicsBody?.isDynamic = true
        sprite.physicsBody?.allowsRotation = true
        sprite.physicsBody?.restitution = 0.7
        sprite.physicsBody?.friction = 1
    }
    
    func update() {
        if (self.memarko.error != nil && self.sprite.parent != nil) {
            sprite.removeFromParent()
        }
    
        self.loader.alpha = 1 - CGFloat(self.memarko.progress)/100
        self.loader.text = "\(self.memarko.progress)%"
    }
}



class FacesScene: SKScene {
    private let motionManager = CMMotionManager()
    private var dragNode: SKNode?
    private var dragJoint: SKPhysicsJointPin?
    private var memas: [MemarkoObject] = []
    
    override func didMove(to view: SKView) {
        self.backgroundColor = .clear
        physicsBody = SKPhysicsBody(edgeLoopFrom: frame.inset(by: UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)))
        
        let node = SKNode()
        node.position = CGPoint(x: size.width/2, y: size.height/2)
        node.physicsBody = SKPhysicsBody(circleOfRadius: 60)
        node.physicsBody?.isDynamic = false
        addChild(node)
        
        motionManager.startAccelerometerUpdates()
    }
    
    public func addDroplet(memarko: Memarko) {
        let object = MemarkoObject(scene: self, memarko: memarko)
        self.memas.append(object)
        self.addChild(object.sprite)

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
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.stopDragging()
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first, let node = self.dragNode {
            let touchLocation = touch.location(in: self)
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
