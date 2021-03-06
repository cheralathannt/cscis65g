//
//  GridView.swift
//  Assignment3-4
//
//  Created by tinaun on 7/10/16.
//  Copyright © 2016 tinaun. All rights reserved.
//

import UIKit

@IBDesignable class GridView: UIView {
    typealias GridBounds = (left: CGFloat, top: CGFloat, width: CGFloat, height: CGFloat)
    
    var rows: Int = 20
    var cols: Int = 20

    @IBInspectable var compactCells: Bool = false
    
    @IBInspectable var livingColor: UIColor = UIColor.whiteColor()
    
    @IBInspectable var emptyColor: UIColor = UIColor.blackColor()
    
    @IBInspectable var bornColor: UIColor = UIColor(red: CGFloat(0.9),
                                                    green: CGFloat(1.0),
                                                    blue: CGFloat(0.9),
                                                    alpha: CGFloat(1.0))
    @IBInspectable var diedColor: UIColor = UIColor(red: CGFloat(0.2),
                                                    green: CGFloat(0.1),
                                                    blue: CGFloat(0.1),
                                                    alpha: CGFloat(1.0))
    
    @IBInspectable var gridColor: UIColor = UIColor.lightGrayColor()
    
    @IBInspectable var gridWidth: CGFloat = 1.0
    
    // computed properties for grid layout
    
    var gridSpacing: CGFloat {
        get {
            return min(bounds.width / CGFloat(cols), bounds.height / CGFloat(rows))
        }
    }
    
    var gridBounds: GridBounds {
        get {
            let height = CGFloat(rows) * gridSpacing
            let width =  CGFloat(cols) * gridSpacing
            let top = (bounds.height - height) / 2
            let left = (bounds.width - width) / 2
            
            return (left, top, width, height)
        }
    }
    
    // helper functions for grid layout
    func getCellBoundsForIndex(x: Int, _ y: Int) -> CGRect {
        let xPos = gridBounds.left + CGFloat(x) * gridSpacing
        let yPos = gridBounds.top + CGFloat(y) * gridSpacing
        
        return CGRect(x: xPos, y: yPos, width: gridSpacing, height: gridSpacing)
    }
    
    func getNearestIndex(point point: CGPoint) -> (Int, Int)  {
        let x = Int( floor((point.x - gridBounds.left) / gridSpacing) )
        let y = Int( floor((point.y - gridBounds.top) / gridSpacing) )
        
        return (x, y)
    }
    
    func getCellAtPoint(point: CGPoint) -> CellState {
        let (x, y) = getNearestIndex(point: point)
        
        return grid[x,y]
    }
    
    func setCellAtPoint(point: CGPoint, state: CellState) {
        let (x, y) = getNearestIndex(point: point)
        
        grid[x,y] = state
        
        StandardEngine.singletonInstance.delegate!.engineDidUpdate(grid)
        
        self.setNeedsDisplayInRect(self.getCellBoundsForIndex(x,y))
    }
    
    func toggleCellAtPoint(point: CGPoint) {
        let (x, y) = getNearestIndex(point: point)
        
        grid[x,y] = grid[x,y].toggle()
        
        StandardEngine.singletonInstance.delegate!.engineDidUpdate(grid)
        
        self.setNeedsDisplayInRect(self.getCellBoundsForIndex(x,y))
    }
    
    func embed(pattern pattern: Pattern){
        let padding = 4
        
        let newRows = pattern.data.rows + padding > rows ? pattern.data.rows + padding : rows
        let newCols = pattern.data.cols + padding > cols ? pattern.data.cols + padding : cols
        
        LifeGridNotification.resized(rows: newRows, cols: newCols)
        
        let startPos = (col: cols/2 + pattern.startPos.0, row: rows/2 + pattern.startPos.1)
        
        grid.loadFrom(subGrid: pattern.data, startPos: startPos)
        LifeGridNotification.gridChanged(grid)
    }
    
    var grid: GridProtocol {
        didSet {
            rows = grid.rows
            cols = grid.cols
            
            self.setNeedsDisplay()
        }
    }
    
    // both are required for interface builder to not crash
    // i could have set a default value for grid to not have to implement these
    // but then i couldn't have used the rows and cols values instead of redefining constants
    
    // contentMode.Redraw tells ios to redraw everything on resize
    required init?(coder aDecoder: NSCoder) {
        grid = StandardEngine.singletonInstance.grid
        
        super.init(coder: aDecoder)
        contentMode = .Redraw
    }
    
    override init(frame: CGRect) {
        grid = StandardEngine.singletonInstance.grid
        
        super.init(frame: frame)
        contentMode = .Redraw
    }
    
    
    override func drawRect(rect: CGRect) {
        let gridPath = UIBezierPath()
        gridPath.lineWidth = gridWidth
        gridPath.lineCapStyle = .Round
        
        if rows <= 0 || cols <= 0 {
            return
        }
        
        let compactMode = gridSpacing < 3 || compactCells
        
        
        // prevents odd line widths from being blurry
        let strokeCorrect: CGFloat = gridWidth % 2 == 0 ? 0 : 0.5

        //row and column offsets
        func getRowOffset(row: Int) -> CGFloat {
            let row = CGFloat(row)
            
            return round(gridBounds.top + row * gridSpacing) + strokeCorrect
        }
        
        func getColumnOffset(column: Int) -> CGFloat {
            let col = CGFloat(column)
            
            return round(gridBounds.left + col * gridSpacing) + strokeCorrect
        }
        
        //white bg
        let bgPath = UIBezierPath(rect: CGRect(x: gridBounds.left, y: gridBounds.top, width: gridBounds.width, height: gridBounds.height))
        
        UIColor.whiteColor().setFill()
        bgPath.fill()
        
        
        //vertical grid lines
        for column in 1..<cols {
            
            gridPath.moveToPoint(CGPoint(
                x: getColumnOffset(column), y: gridBounds.top + gridWidth
            ))
            
            gridPath.addLineToPoint(CGPoint(
                x: getColumnOffset(column), y: gridBounds.top + gridBounds.height - gridWidth
            ))
        }
        
        //horizontal grid lines
        for row in 1..<rows {
            
            gridPath.moveToPoint(CGPoint(
                x: gridBounds.left + gridWidth , y: getRowOffset(row)
            ))
            
            gridPath.addLineToPoint(CGPoint(
                x: gridBounds.left + gridBounds.width - gridWidth, y: getRowOffset(row)
            ))
        }
        
        if !compactMode {
            gridColor.setStroke()
            gridPath.stroke()
        }
        
        //cells
        for y in 0..<rows {
            for x in 0..<cols {
                let xPos = getColumnOffset(x)
                let yPos = getRowOffset(y)
            
                let width = getColumnOffset(x+1) - xPos
                let height = getRowOffset(y+1) - yPos
                
                var cellPath: UIBezierPath
                
                if compactMode {
                    let cellRect = CGRect(x: xPos, y: yPos, width: width, height: height)
                    cellPath = UIBezierPath(rect: cellRect)
                } else {
                    let cellRect = CGRect(x: xPos + gridWidth / 2, y: yPos + gridWidth / 2,
                                          width: width - gridWidth, height: height - gridWidth)
                
                    cellPath = UIBezierPath(ovalInRect: cellRect)
                }
                
                switch grid[x, y] {
                case .Empty:
                    emptyColor.setFill()
                case .Born:
                    bornColor.setFill()
                case .Died:
                    diedColor.setFill()
                case .Living:
                    livingColor.setFill()
                }
                
                cellPath.fill()
            }
        }
        
    }
    

}
