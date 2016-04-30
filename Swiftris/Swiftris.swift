//
//  Swiftris.swift
//  Swiftris
//
//  Created by hao on 4/19/16.
//  Copyright © 2016 hao. All rights reserved.
//

// 一共 10 列 20 行
let NumColumns = 10
let NumRows = 20

// 每个新的 Shape 的锚点在第 4 列第 0 行
let StartingColumn = 4
let StartingRow = 0

// 下一个 Shape 的锚点在第 12 列第 1 行
let PreviewColumn = 12
let PreviewRow = 1

let PointsPerLine = 10
let LevelThreshold = 1000


protocol SwiftrisDelegate {
    // Invoked when the current round of Swiftris ends
    func gameDidEnd(swiftris: Swiftris)
    
    // Invoked after a new game has begun
    func gameDidBegin(swiftris: Swiftris)
    
    // Invoked when the falling shape has become part of the game board
    func gameShapeDidLand(swiftris: Swiftris)
    
    // Invoked when the falling shape has changed its location
    func gameShapeDidMove(swiftris: Swiftris)
    
    // Invoked when the falling shape has changed its location after being dropped
    func gameShapeDidDrop(swiftris: Swiftris)
    
    // Invoked when the game has reached a new level
    func gameDidLevelUp(swiftris: Swiftris)
}


// Swiftris 提供游戏需要的各种单元，是整个游戏规则的封装，因此需要用 SwiftrisDelegate 来将游戏某些关键事件通知出去，
// 这里是通知 GameViewController，让它去调用 GameScene 重绘 UI
class Swiftris {
    var blockArray: Array2D<Block>
    var nextShape: Shape?
    var fallingShape: Shape?
    var delegate:SwiftrisDelegate?
    
    var score = 0
    var level = 1
    
    init() {
        fallingShape = nil
        nextShape = nil
        blockArray = Array2D<Block>(columns: NumColumns, rows: NumRows)
    }
    
    // #5
    func beginGame() {
        if (nextShape == nil) {
            nextShape = Shape.random(PreviewColumn, startingRow: PreviewRow)
        }
        
        delegate?.gameDidBegin(self)
    }
    
    // #6
    func newShape() -> (fallingShape:Shape?, nextShape:Shape?) {
        fallingShape = nextShape
        nextShape = Shape.random(PreviewColumn, startingRow: PreviewRow)
        fallingShape?.moveTo(StartingColumn, row: StartingRow)
        
        // detectIllegalPlacement() == false 为假，即位于非法位置，执行 else 块，即游戏结束
        guard detectIllegalPlacement() == false else {
            nextShape = fallingShape
            nextShape!.moveTo(PreviewColumn, row: PreviewRow)
            endGame()
            return (nil, nil)
        }
        
        return (fallingShape, nextShape)
    }
    
    func detectIllegalPlacement() -> Bool {
        guard let shape = fallingShape else {
            return false // 当前没有正在下落的 Shape，必然不需要判断位置是否非法，会生成下一个 Shape 再去判断
        }
        for block in shape.blocks {
            if block.column < 0 || block.column >= NumColumns
                || block.row < 0 || block.row >= NumRows {
                // 如果有一个 Block 的位置超出边界则非法
                return true
            } else if blockArray[block.column, block.row] != nil {
                // 是否当前 Block 是否已被占
                return true
            }
        }
        return false
    }
    
    // 当前 Shape 已经无法再移动，固定之
    func settleShape() {
        guard let shape = fallingShape else {
            return
        }
        for block in shape.blocks {
            blockArray[block.column, block.row] = block
        }
        fallingShape = nil
        delegate?.gameShapeDidLand(self)
    }
    
    // #9
    func detectTouch() -> Bool {
        guard let shape = fallingShape else {
            return false
        }
        
        // 仅当当前 Shape 与 UI 底部碰触，或者下一行已经由其他 Block，则说明接触了，不能再下落
        for bottomBlock in shape.bottomBlocks {
            if bottomBlock.row == NumRows - 1
                || blockArray[bottomBlock.column, bottomBlock.row + 1] != nil {
                return true
            }
        }
        return false
    }
    
    func endGame() {
        score = 0
        level = 1
        delegate?.gameDidEnd(self)
    }
    
    // #10
    func removeCompletedLines() -> (linesRemoved: Array<Array<Block>>, fallenBlocks: Array<Array<Block>>) {
        var removedLines = Array<Array<Block>>()
        
        // 反向从最底部开始判断
        for row in (1...NumRows-1).reverse() {
            var rowOfBlocks = Array<Block>()
            // 从左到右判断每一列
            for column in 0..<NumColumns {
                guard let block = blockArray[column, row] else {
                    // 只要某一列没有 Block，直接 continue 即 rowOfBlocks 不会被追加
                    continue
                }
                rowOfBlocks.append(block)
            }
            
            // 有 Block 的数目等于列数时，才需要准备移除，然后设置为空
            if rowOfBlocks.count == NumColumns {
                removedLines.append(rowOfBlocks)
                for block in rowOfBlocks {
                    blockArray[block.column, block.row] = nil
                }
            }
        }
        
        // #12
        if removedLines.count == 0 {
            return ([], [])
        }
        // #13 加分
        let pointsEarned = removedLines.count * PointsPerLine * level
        score += pointsEarned
        if score >= level * LevelThreshold {
            level += 1
            delegate?.gameDidLevelUp(self)
        }
        
        var fallenBlocks = Array<Array<Block>>()
        for column in 0..<NumColumns {
            var fallenBlocksArray = Array<Block>()
            // #14
            
            for row in (1...removedLines[0][0].row - 1).reverse() {
                guard let block = blockArray[column, row] else {
                    continue
                }
                var newRow = row
                while (newRow < NumRows - 1 && blockArray[column, newRow + 1] == nil) {
                    newRow += 1
                }
                block.row = newRow
                blockArray[column, row] = nil
                blockArray[column, newRow] = block
                fallenBlocksArray.append(block)
            }
            if fallenBlocksArray.count > 0 {
                fallenBlocks.append(fallenBlocksArray)
            }
        }
        return (removedLines, fallenBlocks)
    }
    
    func dropShape() {
        guard let shape = fallingShape else {
            return
        }
        // 直接快速下落，直到非法位置，然后往上升一格
        while detectIllegalPlacement() == false {
            shape.lowerShapeByOneRow()
        }
        shape.raiseShapeByOneRow()
        delegate?.gameShapeDidDrop(self)
    }
    
    // #5
    func letShapeFall() {
        guard let shape = fallingShape else {
            return
        }
        
        // 先让当前 Shape 下落一格，然后判断当前 Shape 是否处于非法位置
        // 是的话就会滚往上一格，如果还是非法（例如先碰底了，往上一格又超出 UI 的情况），说明游戏结束，否则放置好
        shape.lowerShapeByOneRow()
        if detectIllegalPlacement() {
            shape.raiseShapeByOneRow()
            if detectIllegalPlacement() {
                endGame()
            } else {
                settleShape()
            }
        } else {
            // 下落到合法位置，重绘当前 Shape
            delegate?.gameShapeDidMove(self)
            
            // 判断是否与其他 Shape 或 UI 底部接触了
            if detectTouch() {
                settleShape()
            }
        }
    }
    
    // #6
    func rotateShape() {
        guard let shape = fallingShape else {
            return
        }
        shape.rotateClockwise()
        guard detectIllegalPlacement() == false else {
            shape.rotateCounterClockwise()
            return
        }
        delegate?.gameShapeDidMove(self)
    }
    
    // #7
    func moveShapeLeft() {
        guard let shape = fallingShape else {
            return
        }
        shape.shiftLeftByOneColumn()
        guard detectIllegalPlacement() == false else {
            shape.shiftRightByOneColumn()
            return
        }
        delegate?.gameShapeDidMove(self)
    }
    
    func moveShapeRight() {
        guard let shape = fallingShape else {
            return
        }
        shape.shiftRightByOneColumn()
        guard detectIllegalPlacement() == false else {
            shape.shiftLeftByOneColumn()
            return
        }
        delegate?.gameShapeDidMove(self)
    }
    
    func removeAllBlocks() -> Array<Array<Block>> {
        var allBlocks = Array<Array<Block>>()
        for row in 0..<NumRows {
            var rowOfBlocks = Array<Block>()
            for column in 0..<NumColumns {
                guard let block = blockArray[column, row] else {
                    continue
                }
                rowOfBlocks.append(block)
                blockArray[column, row] = nil
            }
            allBlocks.append(rowOfBlocks)
        }
        return allBlocks
    }
}
