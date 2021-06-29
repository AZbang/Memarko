import CoreMotion
import SpriteKit
import UIKit

extension SKSpriteNode {
    func drawBorder(color: UIColor, width: CGFloat) {
        let shapeNode = SKShapeNode(circleOfRadius: size.width/2)
        shapeNode.fillColor = .clear
        shapeNode.strokeColor = color
        shapeNode.lineWidth = 100
        addChild(shapeNode)
    }
}

class FacesScene: SKScene {
    private let motionManager = CMMotionManager()
    private var dragNode: SKNode?
    private var dragJoint: SKPhysicsJointPin?
    
    override func didMove(to view: SKView) {
        self.backgroundColor = .clear
        physicsBody = SKPhysicsBody(edgeLoopFrom: frame.inset(by: UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)))
        motionManager.startAccelerometerUpdates()
    }
    
    public func addDroplet(image: UIImage) {
        let value = Int.random(in: 90..<140)
        let size = CGSize(width: value, height: value)
        let texture = SKTexture(image: image.circleMasked()!)
        let ball = SKSpriteNode(texture: texture)
        ball.position = CGPoint(x: self.frame.width/2, y: self.frame.height/2)
        ball.drawBorder(color: #colorLiteral(red: 0.2365181744, green: 0.3842029572, blue: 1, alpha: 1), width: 4)

        let crop = SKCropNode()
        crop.maskNode = SKShapeNode(circleOfRadius: size.width/2)
        let loader = SKShapeNode(rectOf: ball.size)
        loader.fillColor = #colorLiteral(red: 0.3647058904, green: 0.06666667014, blue: 0.9686274529, alpha: 1)
        ball.zPosition = 1
        crop.zPosition = 2
        loader.zPosition = 3
        crop.addChild(loader)
        ball.addChild(crop)
        ball.scale(to:size)

        ball.physicsBody = SKPhysicsBody(circleOfRadius: size.width/2)
        ball.physicsBody?.isDynamic = true
        ball.physicsBody?.allowsRotation = true
        ball.physicsBody?.restitution = 0.7
        ball.physicsBody?.friction = 1
        addChild(ball)
                
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

    let i = 0
    override func update(_ currentTime: TimeInterval) {
        
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
