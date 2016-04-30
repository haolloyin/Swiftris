//
//  SquareShape.swift
//  Swiftris
//
//  Created by hao on 4/16/16.
//  Copyright © 2016 hao. All rights reserved.
//

class SquareShape: Shape {
    /*
    | 0 | 1 |
    | 2 | 3 |
    */
    
    // 注意：是先 column 后 row
    // 在每个方向上，每一个点与 Shape 锚点的距离
    override var blockRowColumnPositions: [Orientation: Array<(columnDiff: Int, rowDiff: Int)>] {
        return [
            Orientation.Zero:       [(0,0), (1,0), (0,1), (1,1)],
            Orientation.Ninety:     [(0,0), (1,0), (0,1), (1,1)],
            Orientation.OneEighty:  [(0,0), (1,0), (0,1), (1,1)],
            Orientation.TwoSeventy: [(0,0), (1,0), (0,1), (1,1)]
        ]
    }
    
    // 见父类 Shape 的解释
    override var bottomBlocksForOrientations: [Orientation: Array<Block>] {
        return [
            Orientation.Zero:       [blocks[ThirdBlockIdx], blocks[FourthBlockIdx]],
            Orientation.Ninety:     [blocks[ThirdBlockIdx], blocks[FourthBlockIdx]],
            Orientation.OneEighty:  [blocks[ThirdBlockIdx], blocks[FourthBlockIdx]],
            Orientation.TwoSeventy: [blocks[ThirdBlockIdx], blocks[FourthBlockIdx]]
        ]
    }
}
