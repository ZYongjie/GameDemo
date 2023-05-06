//
//  SKScrollingNode.swift
//  GameDemo
//
//  Created by yongjie on 2023/5/4.
//

import SpriteKit

class SKScrollingNode: SKSpriteNode {
    var scrollingSpeed = 1.0
    
    class func scrollingNode(_ imageNamed: String, containerSize: CGSize) -> SKScrollingNode {
        let image = SKTexture(imageNamed: imageNamed)
        
        let result = SKScrollingNode(color: .clear, size: CGSize(width: CGFloat(containerSize.width), height: containerSize.height));
        result.scrollingSpeed = 1.0;
        
        var total:CGFloat = 0.0;
        while(total < CGFloat(containerSize.height) + image.size().height) {
            let child = SKSpriteNode(imageNamed: imageNamed);
            child.size = containerSize
            child.anchorPoint = CGPoint.zero;
            child.position = CGPoint(x: 0, y: total);
            result.addChild(child);
            total+=child.size.height;
        }
        return result;
    }
    
//    class func scrollingNode(_ imageNamed: String, containerWidth: CGFloat) -> SKScrollingNode {
//        let image = UIImage(named: imageNamed);
//
//        let result = SKScrollingNode(color: UIColor.clear, size: CGSize(width: CGFloat(containerWidth), height: image!.size.height));
//        result.scrollingSpeed = 1.0;
//
//        var total:CGFloat = 0.0;
//        while(total < CGFloat(containerWidth) + image!.size.width) {
//            let child = SKSpriteNode(imageNamed: imageNamed);
//            child.anchorPoint = CGPoint.zero;
//            child.position = CGPoint(x: total, y: 0);
//            result.addChild(child);
//            total+=child.size.width;
//        }
//        return result;
//    }
    
    func update(_ currentTime: TimeInterval) {
        let runBlock: () -> Void = {
            for child in self.children as! [SKSpriteNode] {
                
                
                child.position = CGPoint(x: child.position.x, y: child.position.y - self.scrollingSpeed);
                if(child.position.y <= -child.size.height) {
                    let delta = child.position.y + child.size.height;
                    child.position = CGPoint(x: child.position.x, y: child.size.height * CGFloat(self.children.count - 1) + delta);
                }
            }
        }
        runBlock();
    }
    
}
