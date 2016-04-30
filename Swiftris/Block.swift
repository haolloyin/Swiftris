//
//  Block.swift
//  Swiftris
//
//  Created by hao on 4/14/16.
//  Copyright © 2016 hao. All rights reserved.
//

import SpriteKit

// 定义 6 种颜色
let NumberOfColors: UInt32 = 6

// 实现 CustomStringConvertible 协议并重写 description 变量可以给实例提供可读性的名称
enum BlockColor: Int, CustomStringConvertible {
    
    case Blue = 0, Orange, Purple, Red, Teal, Yellow
    
    var spriteName: String {
        switch self {
            case .Blue:
                return "blue"
            case .Orange:
                return "orange"
            case .Purple:
                return "purple"
            case .Red:
                return "red"
            case .Teal:
                return "teal"
            case .Yellow:
                return "yellow"
        }
    }
    
    var description: String {
        return self.spriteName
    }
    
    // 用 static 修饰来定义类方法，生成随机颜色
    static func random() -> BlockColor {
        return BlockColor(rawValue: Int(arc4random_uniform(NumberOfColors)))!
    }
}


// 若干 Block 构成一个 Shape
class Block: Hashable, CustomStringConvertible {
    let color: BlockColor
    
    var column: Int
    var row: Int
    var sprite: SKSpriteNode? // 用于屏幕上渲染一个 Block
    
    // 直接返回 Block 的颜色，后面会用这个颜色值去取图片来渲染
    var spriteName: String {
        return color.spriteName
    }
    
    var hashValue: Int {
        return self.column ^ self.row
    }
    
    var description: String {
        return "\(color): [\(column), \(row)]"
    }
    
    init(column: Int, row: Int, color: BlockColor) {
        self.column = column
        self.row = row
        self.color = color
    }
}

// 操作符重载，只有当 行／列／颜色 全部一样时才是相同的
func ==(lhs: Block, rhs: Block) -> Bool {
    return lhs.column == rhs.column && lhs.row == rhs.row && lhs.color.rawValue == rhs.color.rawValue
}





