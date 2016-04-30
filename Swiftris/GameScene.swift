//
//  GameScene.swift
//  Swiftris
//
//  Created by hao on 4/12/16.
//  Copyright (c) 2016 hao. All rights reserved.
//

import SpriteKit

// #7
let BlockSize: CGFloat = 20.0 // Sprites.atlas 目录下的图片本身就是 20x20 的
let LayerPosition = CGPoint(x: 6, y: -6)

// NSTimeInterval 实际上是 Double 类型，而且以 秒 计数。
// 这里把初始设置为每 600ms（0.6秒）则方块下降一格，故意把 NSTimeInterval 当做毫秒来用
let TickLengthLevelOne = NSTimeInterval(600)


// https://www.bloc.io/tutorials/swiftris-build-your-first-ios-game-with-swift#!/chapters/680
// 继承 SKScene 的类会由系统每一帧调用 update(currentTime: CFTimeInterval) 方法，currentTime 是调用时的时间

class GameScene: SKScene {
    
    // #8
    let gameLayer = SKNode()
    let shapeLayer = SKNode()
    
    var textureCache = Dictionary<String, SKTexture>() // 用于缓存 Block
    
    var tick: (() -> ())? // 无参数无返回的闭包，用来在每次时钟到时调用更新游戏 UI
    var tickLengthMillis = TickLengthLevelOne // 初始设置为没 600ms（0.6秒）则方块下降一格
    var lastTick: NSDate? // 上一次调用 update() 的时间戳
    
    required init(coder aDecoder: NSCoder) {
        fatalError("NSCoder not supported")
    }
    
    override init(size: CGSize) {
        super.init(size: size)
        
        anchorPoint = CGPoint(x: 0, y: 1.0)
        
        // 游戏 UI 从左到右是包含关系及其类型
        // GameScene(SKScene) -> background(SKSpriteNode) -> gameLayer(SKNode) -> shapeLayer(SKNode) -> gameBoard(SKSpriteNode)
        
        let background = SKSpriteNode(imageNamed: "background")
        background.position = CGPoint(x: 0, y: 0)
        background.anchorPoint = CGPoint(x: 0, y: 1.0)
        addChild(background)
        
        addChild(gameLayer)
        
        let gameBoardTexture = SKTexture(imageNamed: "gameboard")
        let gameBoard = SKSpriteNode(texture: gameBoardTexture, size: CGSizeMake(BlockSize * CGFloat(NumColumns), BlockSize * CGFloat(NumRows)))
        gameBoard.anchorPoint = CGPoint(x:0, y:1.0)
        gameBoard.position = LayerPosition
        
        shapeLayer.position = LayerPosition
        shapeLayer.addChild(gameBoard)
        gameLayer.addChild(shapeLayer)
        
        // 循环播放俄罗斯方块的经典背景音乐
        runAction(SKAction.repeatActionForever(SKAction.playSoundFileNamed("theme.mp3", waitForCompletion: true)))
    }
    
    override func update(currentTime: CFTimeInterval) {
        /* Called before each frame is rendered */
        
        // 将实例变量 lastTick 即上次更新时间赋值给本地变量 lastTick，
        // 显然实例变量 lastTick 一开始是 nil，执行 return 语句，整个 update() 方法啥都没干
        
        // guard let xx ＝ yy 语法的使用，yy 为 nil 则执行 else 部分，不为 nil 则 yy 赋值给 xx
        guard let lastTick = lastTick else {
            return
        }
        
        // timeIntervalSinceNow 明显返回秒数的负值，
        // 所以乘以 －1000 转成正的毫秒数，和实例变量 tickLengthMillis 来比较
        let timePassed = lastTick.timeIntervalSinceNow * -1000.0
        if timePassed > tickLengthMillis {
            self.lastTick = NSDate()
            tick?() // 执行每次时钟到达后的擦左
            /* 等同于
                 if tick != nil {
                    tick!()
                 }
            */
        }
    }
    
    func startTicking() {
        // 实例变量赋值后，update() 才有可能会开始调用 tick?() 闭包更新 UI
        // 所以 startTicking() 一定是游戏开始前被调用的
        lastTick = NSDate()
    }
    
    func stopTicking() {
        lastTick = nil
    }
    
    // #9 指定行列下 Block 的原点坐标，注意 Y 轴向下是递减
    func pointForColumn(column: Int, row: Int) -> CGPoint {
        let x = LayerPosition.x + (CGFloat(column) * BlockSize) + (BlockSize / 2)
        let y = LayerPosition.y - ((CGFloat(row) * BlockSize) + (BlockSize / 2))
        return CGPointMake(x, y)
    }
    
    func addPreviewShapeToScene(shape:Shape, completion:() -> ()) {
        for block in shape.blocks {
            // #10
            var texture = textureCache[block.spriteName]
            if texture == nil {
                texture = SKTexture(imageNamed: block.spriteName)   // 用图片来渲染
                textureCache[block.spriteName] = texture            // 缓存
            }
            let sprite = SKSpriteNode(texture: texture)
            
            // #11
            sprite.position = pointForColumn(block.column, row:block.row - 2) // row - 2 是为了让下一个 Shape 具有从高处滑下的动画效果
            shapeLayer.addChild(sprite)
            block.sprite = sprite
            
            // GameScene(SKScene) -> background(SKSpriteNode) -> gameLayer(SKNode) 
            //      -> shapeLayer(SKNode) -> gameBoard(SKSpriteNode)
            //                            -> blockSprite(SKSpriteNode)
            
            // #12 Animation，让新出现的 Shape 有动画
            sprite.alpha = 0
            let moveAction = SKAction.moveTo(pointForColumn(block.column, row: block.row), duration: NSTimeInterval(0.2))
            moveAction.timingMode = .EaseOut
            let fadeInAction = SKAction.fadeAlphaTo(0.7, duration: 0.4)
            fadeInAction.timingMode = .EaseOut
            sprite.runAction(SKAction.group([moveAction, fadeInAction]))
        }
        runAction(SKAction.waitForDuration(0.4), completion: completion)
    }
    
    func movePreviewShape(shape:Shape, completion:() -> ()) {
        for block in shape.blocks {
            let sprite = block.sprite!
            let moveTo = pointForColumn(block.column, row:block.row)
            let moveToAction:SKAction = SKAction.moveTo(moveTo, duration: 0.2)
            moveToAction.timingMode = .EaseOut
            sprite.runAction(
                SKAction.group([moveToAction, SKAction.fadeAlphaTo(1.0, duration: 0.2)]), completion:{})
        }
        runAction(SKAction.waitForDuration(0.2), completion: completion)
    }
    
    func redrawShape(shape:Shape, completion:() -> ()) {
        for block in shape.blocks {
            let sprite = block.sprite!
            let moveTo = pointForColumn(block.column, row:block.row)
            let moveToAction:SKAction = SKAction.moveTo(moveTo, duration: 0.05)
            moveToAction.timingMode = .EaseOut
            if block == shape.blocks.last {
                sprite.runAction(moveToAction, completion: completion)
            } else {
                sprite.runAction(moveToAction)
            }
        }
    }
    
    func animateCollapsingLines(linesToRemove: Array<Array<Block>>, fallenBlocks: Array<Array<Block>>, completion:() -> ()) {
        var longestDuration: NSTimeInterval = 0
        // #2
        for (columnIdx, column) in fallenBlocks.enumerate() {
            for (blockIdx, block) in column.enumerate() {
                let newPosition = pointForColumn(block.column, row: block.row)
                let sprite = block.sprite!
                // #3
                let delay = (NSTimeInterval(columnIdx) * 0.05) + (NSTimeInterval(blockIdx) * 0.05)
                let duration = NSTimeInterval(((sprite.position.y - newPosition.y) / BlockSize) * 0.1)
                let moveAction = SKAction.moveTo(newPosition, duration: duration)
                moveAction.timingMode = .EaseOut
                sprite.runAction(
                    SKAction.sequence([
                        SKAction.waitForDuration(delay),
                        moveAction]))
                longestDuration = max(longestDuration, duration + delay)
            }
        }
        
        for rowToRemove in linesToRemove {
            for block in rowToRemove {
                // #4
                let randomRadius = CGFloat(UInt(arc4random_uniform(400) + 100))
                let goLeft = arc4random_uniform(100) % 2 == 0
                
                var point = pointForColumn(block.column, row: block.row)
                point = CGPointMake(point.x + (goLeft ? -randomRadius : randomRadius), point.y)
                
                let randomDuration = NSTimeInterval(arc4random_uniform(2)) + 0.5
                // #5
                var startAngle = CGFloat(M_PI)
                var endAngle = startAngle * 2
                if goLeft {
                    endAngle = startAngle
                    startAngle = 0
                }
                let archPath = UIBezierPath(arcCenter: point, radius: randomRadius, startAngle: startAngle, endAngle: endAngle, clockwise: goLeft)
                let archAction = SKAction.followPath(archPath.CGPath, asOffset: false, orientToPath: true, duration: randomDuration)
                archAction.timingMode = .EaseIn
                let sprite = block.sprite!
                // #6
                sprite.zPosition = 100
                sprite.runAction(
                    SKAction.sequence(
                        [SKAction.group([archAction, SKAction.fadeOutWithDuration(NSTimeInterval(randomDuration))]),
                            SKAction.removeFromParent()]))
            }
        }
        // #7
        runAction(SKAction.waitForDuration(longestDuration), completion:completion)
    }
    
    func playSound(sound:String) {
        runAction(SKAction.playSoundFileNamed(sound, waitForCompletion: false))
//        SKTAudio.sharedInstance().playSoundEffect(sound) // Play the sound once
    }
}








