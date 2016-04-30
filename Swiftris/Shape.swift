//
//  Shape.swift
//  Swiftris
//
//  Created by hao on 4/15/16.
//  Copyright © 2016 hao. All rights reserved.
//

import SpriteKit


// https://www.bloc.io/tutorials/swiftris-build-your-first-ios-game-with-swift#!/chapters/682

let NumOrientations: UInt32 = 4 // 一共就 4个方向

// 个人觉得用 up/down/left/right 来表示似乎更直观，现在用角度，详见原文的图
enum Orientation: Int, CustomStringConvertible {
    case Zero = 0, Ninety, OneEighty, TwoSeventy
    
    var description: String {
        switch self {
            case .Zero:
                return "0"
            case .Ninety:
                return "90"
            case .OneEighty:
                return "180"
            case .TwoSeventy:
                return "270"
        }
    }
    
    static func random() -> Orientation {
        return Orientation(rawValue: Int(arc4random_uniform(NumOrientations)))!
    }
    
    // 类方法，旋转一个 Shape
    static func rotate(orientation: Orientation, clockwise: Bool) -> Orientation {
        var rotated = orientation.rawValue + (clockwise ? 1 : -1)
        if rotated > Orientation.TwoSeventy.rawValue {
            rotated = Orientation.Zero.rawValue
        }
        else if rotated < 0 {
            rotated = Orientation.TwoSeventy.rawValue
        }
        
        // 反正枚举是 Int 型，以上的 if 判断改成 ％ 4 也可以，不过不够直观
//        rotated = orientation.rawValue + (clockwise ? 1 : 3) // 反时钟方向加 3
//        rotated = rotated % 4
        
        return Orientation(rawValue: rotated)!
    }
}


let NumShapeTypes: UInt32 = 7 // 俄罗斯方块一共 7种不同的形状（镜像成对的算成两个）

// 注意到所有 7种不同形状都是由 4 个 Block 构成的
let FirstBlockIdx: Int = 0
let SecondBlockIdx: Int = 1
let ThirdBlockIdx: Int = 2
let FourthBlockIdx: Int = 3

class Shape: Hashable, CustomStringConvertible {
    let color: BlockColor // 一个 Shape 只有一个颜色，说明所有 Block 都是同一种颜色
    
    var blocks = Array<Block>()     // 构成当前 Shape 的 Block 实例，放在数组种
    var orientation: Orientation    // 方向
    var column, row: Int            // 当前所在的点
    
    // 这是一个计算型属性，同时用于被子类重写。
    // 它以每个 Shape 最左上角的一点作为当前 Shape 的基准点，即锚点，每个 Block 都以此计算位移，即 diff
    // 看类型定义是字典 <方向: 元素为二元组的数组>，结合子类的实现和文章来看才能懂
    // 另，Orientation 是 Int 类型的枚举，天然支持 Hashable，可以作为字典的 key
    var blockRowColumnPositions: [Orientation: Array<(columnDiff: Int, rowDiff: Int)>] {
        return [:] // 空字典，注意字典中取到的值都是 optional 的
    }
    
    // 这是为了在后面游戏时每个 Shape 往下跌落时，每一列只要有一列遇到障碍物就要停止，俄罗斯方块谁都玩过吧。。。
    var bottomBlocksForOrientations: [Orientation: Array<Block>] {
        return [:]
    }
    
    var bottomBlocks: Array<Block> {
        guard let bottomBlocks = bottomBlocksForOrientations[orientation] else {
            return []
        }
        return bottomBlocks
    }
    
    var hashValue: Int {
        // 对 blocks 中对每个 Block 对象都执行 ^ 运算得到哈希码
        return blocks.reduce(0) { $0.hashValue ^ $1.hashValue }
    }
    
    var description: String {
        return "\(color) block facing \(orientation): \(blocks[FirstBlockIdx]), \(blocks[SecondBlockIdx]), \(blocks[ThirdBlockIdx]), \(blocks[FourthBlockIdx])"
    }
    
    init(column: Int, row: Int, color: BlockColor, orientation: Orientation) {
        self.column = column
        self.row = row
        self.color = color
        self.orientation = orientation
        
        initializeBlocks()
    }
    
    // 便利构造方法，子类也可以无需重写
    convenience init(column: Int, row: Int) {
        self.init(column: column, row: row, color: BlockColor.random(), orientation: Orientation.random())
    }
    
    // final 修饰表示无法被子类重写
    final func initializeBlocks() {
        // 判断实例变量 blockRowColumnPositions 是否有值
        // 子类必然已经实现，所以跳到下一步
        guard let blockRowColumnTranslations = blockRowColumnPositions[orientation] else {
            return
        }
        
        // 对当前方向上的行列，即 Array<(columnDiff: Int, rowDiff: Int)>，diff 是一个二元组
        // 根据当前 Shape 的锚点进行位移计算得到计算后的 Shape 所在位置
        blocks = blockRowColumnTranslations.map { (diff) -> Block in
            return Block(column: column + diff.columnDiff, row: row + diff.rowDiff, color: color)
        }
    }
    
    final func rotateBlocks(orientation: Orientation) {
        // 注意这里传入了 Orientation 参数，是指将当前 Orientation 转成传入的这个 Orientation
        // 但实际上根本不用管当前方向是啥，直接把 Shape 的 Block 组装成新的方向即可
        guard let blockRowColumnTranslation = blockRowColumnPositions[orientation] else {
            return
        }
        
        // 所以这里直接操作实例变量 blocks，用当前 Shape 的基准锚点（column 和 row），加上行列的 diff 即可
        for (idx, diff) in blockRowColumnTranslation.enumerate() {
            blocks[idx].column = column + diff.columnDiff
            blocks[idx].row = row + diff.rowDiff
        }
    }
    
    final func rotateClockwise() {
        let newOrientation = Orientation.rotate(orientation, clockwise: true)
        rotateBlocks(newOrientation)
        orientation = newOrientation
    }
    
    final func rotateCounterClockwise() {
        let newOrientation = Orientation.rotate(orientation, clockwise: false)
        rotateBlocks(newOrientation)
        orientation = newOrientation
    }
    
    // 下落一行，即 row 加 1
    final func lowerShapeByOneRow() {
        shiftBy(0, rows: 1)
    }
    
    final func raiseShapeByOneRow() {
        shiftBy(0, rows:-1)
    }
    
    final func shiftRightByOneColumn() {
        shiftBy(1, rows:0)
    }
    
    final func shiftLeftByOneColumn() {
        shiftBy(-1, rows:0)
    }
    
    // #2
    final func shiftBy(columns: Int, rows: Int) {
        // 按给定行列移动，Shape 本身要记录
        // 然后 Shape 的每一个 Block 也要移动
        self.column += columns
        self.row += rows
        for block in blocks {
            block.column += columns
            block.row += rows
        }
    }
    
    // #3，把 Shape 移动到绝对路径，即先位移 Shape 的锚点，再用 rotateBlocks() 让它来位移 Block 的位置
    final func moveTo(column: Int, row: Int) {
        self.column = column
        self.row = row
        rotateBlocks(orientation)
    }
    
    // #4，随机生成一个 Shape
    final class func random(startingColumn: Int, startingRow: Int) -> Shape {
        switch Int(arc4random_uniform(NumShapeTypes)) {
            case 0:
                return SquareShape(column:startingColumn, row:startingRow)
            case 1:
                return LineShape(column:startingColumn, row:startingRow)
            case 2:
                return TShape(column:startingColumn, row:startingRow)
            case 3:
                return LShape(column:startingColumn, row:startingRow)
            case 4:
                return JShape(column:startingColumn, row:startingRow)
            case 5:
                return SShape(column:startingColumn, row:startingRow)
            default:
                return ZShape(column:startingColumn, row:startingRow)
        }
    }
}

func ==(lhs: Shape, rhs: Shape) -> Bool {
    return lhs.row == rhs.row && lhs.column == rhs.column
}






