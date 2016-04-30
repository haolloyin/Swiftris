//
//  Array2D.swift
//  Swiftris
//
//  Created by hao on 4/13/16.
//  Copyright © 2016 hao. All rights reserved.
//

// 把数组简单封装成二维数组，提供更直观的下标语法 array[column, row] 来读取元素
// https://www.bloc.io/tutorials/swiftris-build-your-first-ios-game-with-swift#!/chapters/679

class Array2D<T> {
    let columns: Int
    let rows: Int
    
    // T 是泛型，? 是 optional，表明数组元素可以为 nil
    var array: Array<T?>
    
    init(columns: Int, rows: Int) {
        self.columns = columns
        self.rows = rows
        
        // repeatedValue 设置为 nil，和 T? 对应
        array = Array<T?>(count: rows * columns, repeatedValue: nil)
    }
    
    // 提供下标语法，注意参数是先 column 后 row
    subscript(column: Int, row: Int) -> T? {
        get {
            return array[(row * columns) + column]
        }
        set(newValue) {
            array[(row * columns) + column] = newValue
        }
    }
}
