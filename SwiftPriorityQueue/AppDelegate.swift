//
//  AppDelegate.swift
//  SwiftPriorityQueue
//
//  Copyright (c) 2015-2019 David Kopec
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.

// This is an example of a maze search that uses astar via SwiftPriorityQueue

import Cocoa

// A Cell represents a grid location in the maze
enum Cell {
    case empty
    case blocked
    case start
    case goal
    case path
    func color() -> CGColor {
        switch (self) {
        case .empty: return NSColor.white.cgColor
        case .blocked: return NSColor.black.cgColor
        case .start: return NSColor.green.cgColor
        case .goal: return NSColor.red.cgColor
        case .path: return NSColor.yellow.cgColor
        }
    }
}

// A point is a way to refer to the row and column of a cell
struct Point: Hashable {
    let x: Int
    let y: Int
}

func == (lhs: Point, rhs: Point) -> Bool {
    return lhs.x == rhs.x && lhs.y == rhs.y
}


class MazeView: NSView {
    let NUM_ROWS: Int = 20
    let NUM_COLS: Int = 20
    var hasStart: Bool = false
    var start: Point = Point(x: -1, y: -1)
    var goal: Point = Point(x: -1, y: -1)
    var path: [Point] = [Point]()
    var position: [[Cell]] = [[Cell]]()
    var cellLayers:[[CALayer]] = [[CALayer]]()
    
    // initialize the cells
    override func awakeFromNib() {
        wantsLayer = true
        let width: CGFloat = self.bounds.size.width
        let height: CGFloat = self.bounds.size.height
        for i in 0..<NUM_ROWS {
            cellLayers.append([CALayer]())
            position.append([Cell]())
            for j in 0..<NUM_COLS {
                let temp: CALayer = CALayer()
                var cell: Cell = .empty
                let x = arc4random_uniform(5)
                if x == 0 {
                    cell = .blocked
                }
                position[i].append(cell)
                temp.borderColor = NSColor.purple.cgColor
                temp.backgroundColor = cell.color()
                temp.frame = CGRect(x: CGFloat(CGFloat(j) * (width / CGFloat(NUM_COLS))), y: CGFloat(CGFloat(i) * (height / CGFloat(NUM_ROWS))), width: (width / CGFloat(NUM_COLS)), height: (height / CGFloat(NUM_ROWS)))
                layer?.addSublayer(temp)
                cellLayers[i].append(temp)
            }
        }
    }
    
    // when a click occurs, place a start and a goal cell, then ultimately do an astar search
    override func mouseDown(with theEvent: NSEvent) {
        let width: CGFloat = self.bounds.size.width
        let height: CGFloat = self.bounds.size.height
        let mousePlace:NSPoint = self.convert(theEvent.locationInWindow, from: nil)
        let col: Int = Int(mousePlace.x / (width / CGFloat(NUM_ROWS)))
        let row: Int = Int(mousePlace.y / (height / CGFloat(NUM_COLS)))
        if position[row][col] != .empty {  //can only click on empty cells
            return
        }
        if !hasStart {
            if start.x != -1 {
                position[start.x][start.y] = .empty
                cellLayers[start.x][start.y].backgroundColor = position[start.x][start.y].color()
            }
            if goal.x != -1 {
                position[goal.x][goal.y] = .empty
                cellLayers[goal.x][goal.y].backgroundColor = position[goal.x][goal.y].color()
            }
            for p in path {  // clear path
                if p != start && p != goal {
                    let row = p.x
                    let col = p.y
                    position[row][col] = .empty
                    CATransaction.begin()
                    CATransaction.setValue(NSNumber(value: 0.5), forKey: kCATransactionAnimationDuration)
                    cellLayers[row][col].backgroundColor = position[row][col].color()
                    CATransaction.commit()
                }
            }
            position[row][col] = .start
            CATransaction.begin()
            CATransaction.setValue(NSNumber(value: 0.5), forKey: kCATransactionAnimationDuration)
            cellLayers[row][col].backgroundColor = position[row][col].color()
            CATransaction.commit()
            hasStart = true
            start = Point(x: row, y: col)
        } else {
            position[row][col] = .goal
            CATransaction.begin()
            CATransaction.setValue(NSNumber(value: 0.5), forKey: kCATransactionAnimationDuration)
            cellLayers[row][col].backgroundColor = position[row][col].color()
            CATransaction.commit()
            hasStart = false
            goal = Point(x: row, y: col)
            
            //find path
            
            func goalTest(_ x: Point) -> Bool {
                if x == goal {
                    return true
                }
                return false
            }
            
            func successors(_ p: Point) -> [Point] { //can't go on diagonals
                var ar: [Point] = [Point]()
                if (p.x + 1 < NUM_ROWS) && (position[p.x + 1][p.y] != .blocked) {
                    ar.append(Point(x: p.x + 1, y: p.y))
                }
                if (p.x - 1 >= 0) && (position[p.x - 1][p.y] != .blocked) {
                    ar.append(Point(x: p.x - 1, y: p.y))
                }
                if (p.y + 1 < NUM_COLS) && (position[p.x][p.y + 1] != .blocked) {
                    ar.append(Point(x: p.x, y: p.y + 1))
                }
                if (p.y - 1 >= 0) && (position[p.x][p.y - 1] != .blocked) {
                    ar.append(Point(x: p.x, y: p.y - 1))
                }
                
                return ar
            }
            
            func heuristic(_ p: Point) -> Float {  // Manhattan distance
                let xdist = abs(p.x - goal.x)
                let ydist = abs(p.y - goal.y)
                return Float(xdist + ydist)
            }
            
            if let pathresult:[Point] = astar(start, goalTestFn: goalTest, successorFn: successors, heuristicFn: heuristic) {
                path = pathresult
                for p in path {
                    if p != start && p != goal {
                        let row = p.x
                        let col = p.y
                        position[row][col] = .path
                        CATransaction.begin()
                        CATransaction.setValue(NSNumber(value: 0.5), forKey: kCATransactionAnimationDuration)
                        cellLayers[row][col].backgroundColor = position[row][col].color()
                        CATransaction.commit()
                    }
                }
            }
        }
    }
}

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    @IBOutlet weak var window: NSWindow!


    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }


}

