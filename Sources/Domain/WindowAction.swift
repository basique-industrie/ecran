import Foundation

public enum WindowAction: String, CaseIterable, Codable, Sendable, Identifiable {
    case leftHalf
    case rightHalf
    case centerHalf
    case topHalf
    case bottomHalf
    case topLeft
    case topRight
    case bottomLeft
    case bottomRight
    case firstThird
    case centerThird
    case lastThird
    case firstTwoThirds
    case centerTwoThirds
    case lastTwoThirds
    case topVerticalThird
    case middleVerticalThird
    case bottomVerticalThird
    case topVerticalTwoThirds
    case bottomVerticalTwoThirds
    case maximize
    case almostMaximize
    case maximizeHeight
    case larger
    case smaller
    case largerWidth
    case smallerWidth
    case largerHeight
    case smallerHeight
    case center
    case centerProminently
    case restore
    case nextDisplay
    case previousDisplay
    case moveLeft
    case moveRight
    case moveUp
    case moveDown
    case firstFourth
    case secondFourth
    case thirdFourth
    case lastFourth
    case firstThreeFourths
    case centerThreeFourths
    case lastThreeFourths
    case topLeftSixth
    case topCenterSixth
    case topRightSixth
    case bottomLeftSixth
    case bottomCenterSixth
    case bottomRightSixth
    case specified
    case reverseAll
    case topLeftNinth
    case topCenterNinth
    case topRightNinth
    case middleLeftNinth
    case middleCenterNinth
    case middleRightNinth
    case bottomLeftNinth
    case bottomCenterNinth
    case bottomRightNinth
    case topLeftThird
    case topRightThird
    case bottomLeftThird
    case bottomRightThird
    case topLeftEighth
    case topCenterLeftEighth
    case topCenterRightEighth
    case topRightEighth
    case bottomLeftEighth
    case bottomCenterLeftEighth
    case bottomCenterRightEighth
    case bottomRightEighth
    case tileAll
    case cascadeAll
    case cascadeActiveApp
    case tileActiveApp
    case leftTodo
    case rightTodo
    case doubleHeightUp
    case doubleHeightDown
    case doubleWidthLeft
    case doubleWidthRight
    case halveHeightUp
    case halveHeightDown
    case halveWidthLeft
    case halveWidthRight
    case topLeftTwelfth
    case topCenterLeftTwelfth
    case topCenterRightTwelfth
    case topRightTwelfth
    case middleLeftTwelfth
    case middleCenterLeftTwelfth
    case middleCenterRightTwelfth
    case middleRightTwelfth
    case bottomLeftTwelfth
    case bottomCenterLeftTwelfth
    case bottomCenterRightTwelfth
    case bottomRightTwelfth
    case topLeftSixteenth
    case topCenterLeftSixteenth
    case topCenterRightSixteenth
    case topRightSixteenth
    case upperMiddleLeftSixteenth
    case upperMiddleCenterLeftSixteenth
    case upperMiddleCenterRightSixteenth
    case upperMiddleRightSixteenth
    case lowerMiddleLeftSixteenth
    case lowerMiddleCenterLeftSixteenth
    case lowerMiddleCenterRightSixteenth
    case lowerMiddleRightSixteenth
    case bottomLeftSixteenth
    case bottomCenterLeftSixteenth
    case bottomCenterRightSixteenth
    case bottomRightSixteenth
    case displayOne
    case displayTwo
    case displayThree
    case displayFour
    case displayFive
    case displaySix
    case displaySeven
    case displayEight
    case displayNine

    public var id: String { rawValue }

    public var kebabName: String {
        rawValue.replacingOccurrences(
            of: "([a-z0-9])([A-Z])",
            with: "$1-$2",
            options: .regularExpression
        ).lowercased()
    }

    public var displayName: String {
        switch self {
        case .leftHalf: "Left Half"
        case .rightHalf: "Right Half"
        case .centerHalf: "Center Half"
        case .topHalf: "Top Half"
        case .bottomHalf: "Bottom Half"
        case .topLeft: "Top Left"
        case .topRight: "Top Right"
        case .bottomLeft: "Bottom Left"
        case .bottomRight: "Bottom Right"
        case .firstThird: "First Third"
        case .centerThird: "Center Third"
        case .lastThird: "Last Third"
        case .firstTwoThirds: "First Two Thirds"
        case .centerTwoThirds: "Center Two Thirds"
        case .lastTwoThirds: "Last Two Thirds"
        case .topVerticalThird: "Top Vertical Third"
        case .middleVerticalThird: "Middle Vertical Third"
        case .bottomVerticalThird: "Bottom Vertical Third"
        case .topVerticalTwoThirds: "Top Vertical Two Thirds"
        case .bottomVerticalTwoThirds: "Bottom Vertical Two Thirds"
        case .maximize: "Maximize"
        case .almostMaximize: "Almost Maximize"
        case .maximizeHeight: "Maximize Height"
        case .larger: "Larger"
        case .smaller: "Smaller"
        case .largerWidth: "Larger Width"
        case .smallerWidth: "Smaller Width"
        case .largerHeight: "Larger Height"
        case .smallerHeight: "Smaller Height"
        case .center: "Center"
        case .centerProminently: "Center Prominently"
        case .restore: "Restore"
        case .nextDisplay: "Next Display"
        case .previousDisplay: "Previous Display"
        case .moveLeft: "Move Left"
        case .moveRight: "Move Right"
        case .moveUp: "Move Up"
        case .moveDown: "Move Down"
        case .firstFourth: "First Fourth"
        case .secondFourth: "Second Fourth"
        case .thirdFourth: "Third Fourth"
        case .lastFourth: "Last Fourth"
        case .firstThreeFourths: "First Three Fourths"
        case .centerThreeFourths: "Center Three Fourths"
        case .lastThreeFourths: "Last Three Fourths"
        case .topLeftSixth: "Top Left Sixth"
        case .topCenterSixth: "Top Center Sixth"
        case .topRightSixth: "Top Right Sixth"
        case .bottomLeftSixth: "Bottom Left Sixth"
        case .bottomCenterSixth: "Bottom Center Sixth"
        case .bottomRightSixth: "Bottom Right Sixth"
        case .specified: "Specified Size"
        case .reverseAll: "Reverse All"
        case .topLeftNinth: "Top Left Ninth"
        case .topCenterNinth: "Top Center Ninth"
        case .topRightNinth: "Top Right Ninth"
        case .middleLeftNinth: "Middle Left Ninth"
        case .middleCenterNinth: "Middle Center Ninth"
        case .middleRightNinth: "Middle Right Ninth"
        case .bottomLeftNinth: "Bottom Left Ninth"
        case .bottomCenterNinth: "Bottom Center Ninth"
        case .bottomRightNinth: "Bottom Right Ninth"
        case .topLeftThird: "Top Left Two-Thirds"
        case .topRightThird: "Top Right Two-Thirds"
        case .bottomLeftThird: "Bottom Left Two-Thirds"
        case .bottomRightThird: "Bottom Right Two-Thirds"
        case .topLeftEighth: "Top Left Eighth"
        case .topCenterLeftEighth: "Top Center Left Eighth"
        case .topCenterRightEighth: "Top Center Right Eighth"
        case .topRightEighth: "Top Right Eighth"
        case .bottomLeftEighth: "Bottom Left Eighth"
        case .bottomCenterLeftEighth: "Bottom Center Left Eighth"
        case .bottomCenterRightEighth: "Bottom Center Right Eighth"
        case .bottomRightEighth: "Bottom Right Eighth"
        case .tileAll: "Tile All"
        case .cascadeAll: "Cascade All"
        case .cascadeActiveApp: "Cascade Active App"
        case .tileActiveApp: "Tile Active App"
        case .leftTodo: "Left Todo"
        case .rightTodo: "Right Todo"
        case .doubleHeightUp: "Double Height Up"
        case .doubleHeightDown: "Double Height Down"
        case .doubleWidthLeft: "Double Width Left"
        case .doubleWidthRight: "Double Width Right"
        case .halveHeightUp: "Halve Height Up"
        case .halveHeightDown: "Halve Height Down"
        case .halveWidthLeft: "Halve Width Left"
        case .halveWidthRight: "Halve Width Right"
        case .topLeftTwelfth: "Top Left Twelfth"
        case .topCenterLeftTwelfth: "Top Center Left Twelfth"
        case .topCenterRightTwelfth: "Top Center Right Twelfth"
        case .topRightTwelfth: "Top Right Twelfth"
        case .middleLeftTwelfth: "Middle Left Twelfth"
        case .middleCenterLeftTwelfth: "Middle Center Left Twelfth"
        case .middleCenterRightTwelfth: "Middle Center Right Twelfth"
        case .middleRightTwelfth: "Middle Right Twelfth"
        case .bottomLeftTwelfth: "Bottom Left Twelfth"
        case .bottomCenterLeftTwelfth: "Bottom Center Left Twelfth"
        case .bottomCenterRightTwelfth: "Bottom Center Right Twelfth"
        case .bottomRightTwelfth: "Bottom Right Twelfth"
        case .topLeftSixteenth: "Top Left Sixteenth"
        case .topCenterLeftSixteenth: "Top Center Left Sixteenth"
        case .topCenterRightSixteenth: "Top Center Right Sixteenth"
        case .topRightSixteenth: "Top Right Sixteenth"
        case .upperMiddleLeftSixteenth: "Upper Middle Left Sixteenth"
        case .upperMiddleCenterLeftSixteenth: "Upper Middle Center Left Sixteenth"
        case .upperMiddleCenterRightSixteenth: "Upper Middle Center Right Sixteenth"
        case .upperMiddleRightSixteenth: "Upper Middle Right Sixteenth"
        case .lowerMiddleLeftSixteenth: "Lower Middle Left Sixteenth"
        case .lowerMiddleCenterLeftSixteenth: "Lower Middle Center Left Sixteenth"
        case .lowerMiddleCenterRightSixteenth: "Lower Middle Center Right Sixteenth"
        case .lowerMiddleRightSixteenth: "Lower Middle Right Sixteenth"
        case .bottomLeftSixteenth: "Bottom Left Sixteenth"
        case .bottomCenterLeftSixteenth: "Bottom Center Left Sixteenth"
        case .bottomCenterRightSixteenth: "Bottom Center Right Sixteenth"
        case .bottomRightSixteenth: "Bottom Right Sixteenth"
        case .displayOne: "Display 1"
        case .displayTwo: "Display 2"
        case .displayThree: "Display 3"
        case .displayFour: "Display 4"
        case .displayFive: "Display 5"
        case .displaySix: "Display 6"
        case .displaySeven: "Display 7"
        case .displayEight: "Display 8"
        case .displayNine: "Display 9"
        }
    }

    public var category: WindowActionCategory {
        switch self {
        case .leftHalf, .rightHalf, .centerHalf, .topHalf, .bottomHalf:
            .halves
        case .topLeft, .topRight, .bottomLeft, .bottomRight:
            .corners
        case .firstThird, .centerThird, .lastThird, .firstTwoThirds, .centerTwoThirds, .lastTwoThirds,
             .topVerticalThird, .middleVerticalThird, .bottomVerticalThird, .topVerticalTwoThirds,
             .bottomVerticalTwoThirds:
            .thirds
        case .maximize, .almostMaximize, .maximizeHeight, .larger, .smaller, .largerWidth, .smallerWidth,
             .largerHeight, .smallerHeight, .doubleHeightUp, .doubleHeightDown, .doubleWidthLeft,
             .doubleWidthRight, .halveHeightUp, .halveHeightDown, .halveWidthLeft, .halveWidthRight:
            .size
        case .center, .centerProminently, .restore, .specified:
            .position
        case .nextDisplay, .previousDisplay, .displayOne, .displayTwo, .displayThree, .displayFour,
             .displayFive, .displaySix, .displaySeven, .displayEight, .displayNine:
            .displays
        case .moveLeft, .moveRight, .moveUp, .moveDown:
            .move
        case .firstFourth, .secondFourth, .thirdFourth, .lastFourth, .firstThreeFourths,
             .centerThreeFourths, .lastThreeFourths:
            .fourths
        case .topLeftSixth, .topCenterSixth, .topRightSixth, .bottomLeftSixth, .bottomCenterSixth,
             .bottomRightSixth:
            .sixths
        case .topLeftNinth, .topCenterNinth, .topRightNinth, .middleLeftNinth, .middleCenterNinth,
             .middleRightNinth, .bottomLeftNinth, .bottomCenterNinth, .bottomRightNinth:
            .ninths
        case .topLeftEighth, .topCenterLeftEighth, .topCenterRightEighth, .topRightEighth,
             .bottomLeftEighth, .bottomCenterLeftEighth, .bottomCenterRightEighth, .bottomRightEighth:
            .eighths
        case .topLeftTwelfth, .topCenterLeftTwelfth, .topCenterRightTwelfth, .topRightTwelfth,
             .middleLeftTwelfth, .middleCenterLeftTwelfth, .middleCenterRightTwelfth, .middleRightTwelfth,
             .bottomLeftTwelfth, .bottomCenterLeftTwelfth, .bottomCenterRightTwelfth, .bottomRightTwelfth:
            .twelfths
        case .topLeftSixteenth, .topCenterLeftSixteenth, .topCenterRightSixteenth, .topRightSixteenth,
             .upperMiddleLeftSixteenth, .upperMiddleCenterLeftSixteenth, .upperMiddleCenterRightSixteenth,
             .upperMiddleRightSixteenth, .lowerMiddleLeftSixteenth, .lowerMiddleCenterLeftSixteenth,
             .lowerMiddleCenterRightSixteenth, .lowerMiddleRightSixteenth, .bottomLeftSixteenth,
             .bottomCenterLeftSixteenth, .bottomCenterRightSixteenth, .bottomRightSixteenth:
            .sixteenths
        case .topLeftThird, .topRightThird, .bottomLeftThird, .bottomRightThird:
            .cornerThirds
        case .tileAll, .cascadeAll, .cascadeActiveApp, .tileActiveApp, .reverseAll:
            .arrange
        case .leftTodo, .rightTodo:
            .todo
        }
    }

    public var isMultiWindow: Bool {
        switch self {
        case .reverseAll, .tileAll, .cascadeAll, .cascadeActiveApp, .tileActiveApp:
            true
        default:
            false
        }
    }

    public var isDisplayTraversal: Bool {
        switch self {
        case .nextDisplay, .previousDisplay, .displayOne, .displayTwo, .displayThree, .displayFour,
             .displayFive, .displaySix, .displaySeven, .displayEight, .displayNine:
            true
        default:
            false
        }
    }

    public var isDragSnappable: Bool {
        switch category {
        case .halves, .corners, .thirds, .fourths, .sixths:
            true
        case .size:
            self == .maximize
        default:
            false
        }
    }

    public var gapSharedEdges: EdgeSet {
        switch self {
        case .leftHalf, .firstThird, .firstTwoThirds, .firstFourth, .firstThreeFourths, .moveLeft:
            [.right]
        case .rightHalf, .lastThird, .lastTwoThirds, .lastFourth, .lastThreeFourths, .moveRight:
            [.left]
        case .topHalf, .moveUp:
            [.bottom]
        case .bottomHalf, .moveDown:
            [.top]
        case .topLeft:
            [.right, .bottom]
        case .topRight:
            [.left, .bottom]
        case .bottomLeft:
            [.right, .top]
        case .bottomRight:
            [.left, .top]
        case .centerHalf, .centerThird, .centerTwoThirds, .centerThreeFourths, .secondFourth, .thirdFourth:
            [.left, .right]
        default:
            []
        }
    }

    /// Where a separator starts a new block in Rectangle's status menu.
    public var firstInGroup: Bool {
        switch self {
        case .leftHalf, .topLeft, .firstThird, .topVerticalThird, .maximize, .almostMaximize, .nextDisplay, .moveLeft,
             .firstFourth, .topLeftSixth, .topLeftEighth, .topLeftNinth, .topLeftTwelfth, .topLeftSixteenth,
             .tileAll, .leftTodo, .displayOne, .topLeftThird:
            true
        default:
            false
        }
    }

    /// Category used to nest items in the status menu. `nil` keeps the item at the top level.
    public var menuSubcategory: WindowActionCategory? {
        switch self {
        case .firstThird, .centerThird, .lastThird, .firstTwoThirds, .centerTwoThirds, .lastTwoThirds,
             .topVerticalThird, .middleVerticalThird, .bottomVerticalThird, .topVerticalTwoThirds,
             .bottomVerticalTwoThirds:
            .thirds
        case .almostMaximize, .maximizeHeight, .larger, .smaller, .largerWidth, .smallerWidth,
             .largerHeight, .smallerHeight, .specified, .doubleHeightUp, .doubleHeightDown,
             .doubleWidthLeft, .doubleWidthRight, .halveHeightUp, .halveHeightDown, .halveWidthLeft,
             .halveWidthRight:
            .size
        case .firstFourth, .secondFourth, .thirdFourth, .lastFourth, .firstThreeFourths,
             .centerThreeFourths, .lastThreeFourths:
            .fourths
        case .topLeftSixth, .topCenterSixth, .topRightSixth, .bottomLeftSixth, .bottomCenterSixth,
             .bottomRightSixth:
            .sixths
        case .topLeftEighth, .topCenterLeftEighth, .topCenterRightEighth, .topRightEighth,
             .bottomLeftEighth, .bottomCenterLeftEighth, .bottomCenterRightEighth, .bottomRightEighth:
            .eighths
        case .topLeftNinth, .topCenterNinth, .topRightNinth, .middleLeftNinth, .middleCenterNinth,
             .middleRightNinth, .bottomLeftNinth, .bottomCenterNinth, .bottomRightNinth:
            .ninths
        case .topLeftTwelfth, .topCenterLeftTwelfth, .topCenterRightTwelfth, .topRightTwelfth,
             .middleLeftTwelfth, .middleCenterLeftTwelfth, .middleCenterRightTwelfth, .middleRightTwelfth,
             .bottomLeftTwelfth, .bottomCenterLeftTwelfth, .bottomCenterRightTwelfth, .bottomRightTwelfth:
            .twelfths
        case .topLeftSixteenth, .topCenterLeftSixteenth, .topCenterRightSixteenth, .topRightSixteenth,
             .upperMiddleLeftSixteenth, .upperMiddleCenterLeftSixteenth, .upperMiddleCenterRightSixteenth,
             .upperMiddleRightSixteenth, .lowerMiddleLeftSixteenth, .lowerMiddleCenterLeftSixteenth,
             .lowerMiddleCenterRightSixteenth, .lowerMiddleRightSixteenth, .bottomLeftSixteenth,
             .bottomCenterLeftSixteenth, .bottomCenterRightSixteenth, .bottomRightSixteenth:
            .sixteenths
        case .topLeftThird, .topRightThird, .bottomLeftThird, .bottomRightThird:
            .cornerThirds
        case .moveLeft, .moveRight, .moveUp, .moveDown:
            .move
        case .displayOne, .displayTwo, .displayThree, .displayFour, .displayFive, .displaySix,
             .displaySeven, .displayEight, .displayNine:
            .displays
        case .tileAll, .tileActiveApp, .cascadeAll, .cascadeActiveApp, .reverseAll:
            .arrange
        case .leftTodo, .rightTodo:
            .todo
        default:
            nil
        }
    }

    /// Filled region inside the menu-bar placement icon, in unit space with the origin at the bottom left.
    public var menuIconUnitRect: MenuIconUnitRect {
        switch self {
        case .leftHalf, .moveLeft, .previousDisplay:
            MenuIconGrid.cell(columns: 2, rows: 1, column: 0, row: 0)
        case .rightHalf, .moveRight, .nextDisplay:
            MenuIconGrid.cell(columns: 2, rows: 1, column: 1, row: 0)
        case .centerHalf:
            MenuIconUnitRect(x: 0.25, y: 0, width: 0.5, height: 1)
        case .topHalf, .moveUp:
            MenuIconGrid.cell(columns: 1, rows: 2, column: 0, row: 1)
        case .bottomHalf, .moveDown:
            MenuIconGrid.cell(columns: 1, rows: 2, column: 0, row: 0)
        case .topLeft:
            MenuIconGrid.cell(columns: 2, rows: 2, column: 0, row: 1)
        case .topRight:
            MenuIconGrid.cell(columns: 2, rows: 2, column: 1, row: 1)
        case .bottomLeft:
            MenuIconGrid.cell(columns: 2, rows: 2, column: 0, row: 0)
        case .bottomRight:
            MenuIconGrid.cell(columns: 2, rows: 2, column: 1, row: 0)
        case .firstThird:
            MenuIconGrid.cell(columns: 3, rows: 1, column: 0, row: 0)
        case .centerThird:
            MenuIconGrid.cell(columns: 3, rows: 1, column: 1, row: 0)
        case .lastThird:
            MenuIconGrid.cell(columns: 3, rows: 1, column: 2, row: 0)
        case .firstTwoThirds:
            MenuIconGrid.cell(columns: 3, rows: 1, column: 0, row: 0, columnSpan: 2)
        case .centerTwoThirds:
            MenuIconUnitRect(x: 1.0 / 6.0, y: 0, width: 2.0 / 3.0, height: 1)
        case .lastTwoThirds:
            MenuIconGrid.cell(columns: 3, rows: 1, column: 1, row: 0, columnSpan: 2)
        case .topVerticalThird:
            MenuIconGrid.cell(columns: 1, rows: 3, column: 0, row: 2)
        case .middleVerticalThird:
            MenuIconGrid.cell(columns: 1, rows: 3, column: 0, row: 1)
        case .bottomVerticalThird:
            MenuIconGrid.cell(columns: 1, rows: 3, column: 0, row: 0)
        case .topVerticalTwoThirds:
            MenuIconGrid.cell(columns: 1, rows: 3, column: 0, row: 1, rowSpan: 2)
        case .bottomVerticalTwoThirds:
            MenuIconGrid.cell(columns: 1, rows: 3, column: 0, row: 0, rowSpan: 2)
        case .maximize, .tileAll, .tileActiveApp, .cascadeAll, .cascadeActiveApp, .reverseAll,
             .displayOne, .displayTwo, .displayThree, .displayFour, .displayFive, .displaySix,
             .displaySeven, .displayEight, .displayNine:
            MenuIconUnitRect(x: 0, y: 0, width: 1, height: 1)
        case .almostMaximize:
            MenuIconUnitRect(x: 0.08, y: 0.08, width: 0.84, height: 0.84)
        case .maximizeHeight, .largerHeight:
            MenuIconUnitRect(x: 0.2, y: 0, width: 0.6, height: 1)
        case .larger, .largerWidth:
            MenuIconUnitRect(x: 0.06, y: 0.22, width: 0.88, height: 0.56)
        case .smaller, .smallerWidth, .smallerHeight:
            MenuIconUnitRect(x: 0.24, y: 0.24, width: 0.52, height: 0.52)
        case .center:
            MenuIconUnitRect(x: 0.22, y: 0.18, width: 0.56, height: 0.64)
        case .centerProminently:
            MenuIconUnitRect(x: 0.12, y: 0.1, width: 0.76, height: 0.8)
        case .restore, .specified:
            MenuIconUnitRect(x: 0.28, y: 0.22, width: 0.44, height: 0.56)
        case .firstFourth:
            MenuIconGrid.cell(columns: 4, rows: 1, column: 0, row: 0)
        case .secondFourth:
            MenuIconGrid.cell(columns: 4, rows: 1, column: 1, row: 0)
        case .thirdFourth:
            MenuIconGrid.cell(columns: 4, rows: 1, column: 2, row: 0)
        case .lastFourth:
            MenuIconGrid.cell(columns: 4, rows: 1, column: 3, row: 0)
        case .firstThreeFourths:
            MenuIconGrid.cell(columns: 4, rows: 1, column: 0, row: 0, columnSpan: 3)
        case .centerThreeFourths:
            MenuIconUnitRect(x: 0.125, y: 0, width: 0.75, height: 1)
        case .lastThreeFourths:
            MenuIconGrid.cell(columns: 4, rows: 1, column: 1, row: 0, columnSpan: 3)
        case .topLeftSixth:
            MenuIconGrid.cell(columns: 3, rows: 2, column: 0, row: 1)
        case .topCenterSixth:
            MenuIconGrid.cell(columns: 3, rows: 2, column: 1, row: 1)
        case .topRightSixth:
            MenuIconGrid.cell(columns: 3, rows: 2, column: 2, row: 1)
        case .bottomLeftSixth:
            MenuIconGrid.cell(columns: 3, rows: 2, column: 0, row: 0)
        case .bottomCenterSixth:
            MenuIconGrid.cell(columns: 3, rows: 2, column: 1, row: 0)
        case .bottomRightSixth:
            MenuIconGrid.cell(columns: 3, rows: 2, column: 2, row: 0)
        case .topLeftNinth:
            MenuIconGrid.cell(columns: 3, rows: 3, column: 0, row: 2)
        case .topCenterNinth:
            MenuIconGrid.cell(columns: 3, rows: 3, column: 1, row: 2)
        case .topRightNinth:
            MenuIconGrid.cell(columns: 3, rows: 3, column: 2, row: 2)
        case .middleLeftNinth:
            MenuIconGrid.cell(columns: 3, rows: 3, column: 0, row: 1)
        case .middleCenterNinth:
            MenuIconGrid.cell(columns: 3, rows: 3, column: 1, row: 1)
        case .middleRightNinth:
            MenuIconGrid.cell(columns: 3, rows: 3, column: 2, row: 1)
        case .bottomLeftNinth:
            MenuIconGrid.cell(columns: 3, rows: 3, column: 0, row: 0)
        case .bottomCenterNinth:
            MenuIconGrid.cell(columns: 3, rows: 3, column: 1, row: 0)
        case .bottomRightNinth:
            MenuIconGrid.cell(columns: 3, rows: 3, column: 2, row: 0)
        case .topLeftThird:
            MenuIconUnitRect(x: 0, y: 1.0 / 3.0, width: 2.0 / 3.0, height: 2.0 / 3.0)
        case .topRightThird:
            MenuIconUnitRect(x: 1.0 / 3.0, y: 1.0 / 3.0, width: 2.0 / 3.0, height: 2.0 / 3.0)
        case .bottomLeftThird:
            MenuIconUnitRect(x: 0, y: 0, width: 2.0 / 3.0, height: 2.0 / 3.0)
        case .bottomRightThird:
            MenuIconUnitRect(x: 1.0 / 3.0, y: 0, width: 2.0 / 3.0, height: 2.0 / 3.0)
        case .topLeftEighth:
            MenuIconGrid.cell(columns: 4, rows: 2, column: 0, row: 1)
        case .topCenterLeftEighth:
            MenuIconGrid.cell(columns: 4, rows: 2, column: 1, row: 1)
        case .topCenterRightEighth:
            MenuIconGrid.cell(columns: 4, rows: 2, column: 2, row: 1)
        case .topRightEighth:
            MenuIconGrid.cell(columns: 4, rows: 2, column: 3, row: 1)
        case .bottomLeftEighth:
            MenuIconGrid.cell(columns: 4, rows: 2, column: 0, row: 0)
        case .bottomCenterLeftEighth:
            MenuIconGrid.cell(columns: 4, rows: 2, column: 1, row: 0)
        case .bottomCenterRightEighth:
            MenuIconGrid.cell(columns: 4, rows: 2, column: 2, row: 0)
        case .bottomRightEighth:
            MenuIconGrid.cell(columns: 4, rows: 2, column: 3, row: 0)
        case .topLeftTwelfth:
            MenuIconGrid.cell(columns: 4, rows: 3, column: 0, row: 2)
        case .topCenterLeftTwelfth:
            MenuIconGrid.cell(columns: 4, rows: 3, column: 1, row: 2)
        case .topCenterRightTwelfth:
            MenuIconGrid.cell(columns: 4, rows: 3, column: 2, row: 2)
        case .topRightTwelfth:
            MenuIconGrid.cell(columns: 4, rows: 3, column: 3, row: 2)
        case .middleLeftTwelfth:
            MenuIconGrid.cell(columns: 4, rows: 3, column: 0, row: 1)
        case .middleCenterLeftTwelfth:
            MenuIconGrid.cell(columns: 4, rows: 3, column: 1, row: 1)
        case .middleCenterRightTwelfth:
            MenuIconGrid.cell(columns: 4, rows: 3, column: 2, row: 1)
        case .middleRightTwelfth:
            MenuIconGrid.cell(columns: 4, rows: 3, column: 3, row: 1)
        case .bottomLeftTwelfth:
            MenuIconGrid.cell(columns: 4, rows: 3, column: 0, row: 0)
        case .bottomCenterLeftTwelfth:
            MenuIconGrid.cell(columns: 4, rows: 3, column: 1, row: 0)
        case .bottomCenterRightTwelfth:
            MenuIconGrid.cell(columns: 4, rows: 3, column: 2, row: 0)
        case .bottomRightTwelfth:
            MenuIconGrid.cell(columns: 4, rows: 3, column: 3, row: 0)
        case .topLeftSixteenth:
            MenuIconGrid.cell(columns: 4, rows: 4, column: 0, row: 3)
        case .topCenterLeftSixteenth:
            MenuIconGrid.cell(columns: 4, rows: 4, column: 1, row: 3)
        case .topCenterRightSixteenth:
            MenuIconGrid.cell(columns: 4, rows: 4, column: 2, row: 3)
        case .topRightSixteenth:
            MenuIconGrid.cell(columns: 4, rows: 4, column: 3, row: 3)
        case .upperMiddleLeftSixteenth:
            MenuIconGrid.cell(columns: 4, rows: 4, column: 0, row: 2)
        case .upperMiddleCenterLeftSixteenth:
            MenuIconGrid.cell(columns: 4, rows: 4, column: 1, row: 2)
        case .upperMiddleCenterRightSixteenth:
            MenuIconGrid.cell(columns: 4, rows: 4, column: 2, row: 2)
        case .upperMiddleRightSixteenth:
            MenuIconGrid.cell(columns: 4, rows: 4, column: 3, row: 2)
        case .lowerMiddleLeftSixteenth:
            MenuIconGrid.cell(columns: 4, rows: 4, column: 0, row: 1)
        case .lowerMiddleCenterLeftSixteenth:
            MenuIconGrid.cell(columns: 4, rows: 4, column: 1, row: 1)
        case .lowerMiddleCenterRightSixteenth:
            MenuIconGrid.cell(columns: 4, rows: 4, column: 2, row: 1)
        case .lowerMiddleRightSixteenth:
            MenuIconGrid.cell(columns: 4, rows: 4, column: 3, row: 1)
        case .bottomLeftSixteenth:
            MenuIconGrid.cell(columns: 4, rows: 4, column: 0, row: 0)
        case .bottomCenterLeftSixteenth:
            MenuIconGrid.cell(columns: 4, rows: 4, column: 1, row: 0)
        case .bottomCenterRightSixteenth:
            MenuIconGrid.cell(columns: 4, rows: 4, column: 2, row: 0)
        case .bottomRightSixteenth:
            MenuIconGrid.cell(columns: 4, rows: 4, column: 3, row: 0)
        case .leftTodo:
            MenuIconUnitRect(x: 0, y: 0, width: 0.28, height: 1)
        case .rightTodo:
            MenuIconUnitRect(x: 0.72, y: 0, width: 0.28, height: 1)
        case .doubleHeightUp:
            MenuIconUnitRect(x: 0.22, y: 0.12, width: 0.56, height: 0.88)
        case .doubleHeightDown:
            MenuIconUnitRect(x: 0.22, y: 0, width: 0.56, height: 0.88)
        case .doubleWidthLeft:
            MenuIconUnitRect(x: 0, y: 0.22, width: 0.88, height: 0.56)
        case .doubleWidthRight:
            MenuIconUnitRect(x: 0.12, y: 0.22, width: 0.88, height: 0.56)
        case .halveHeightUp:
            MenuIconUnitRect(x: 0.25, y: 0.5, width: 0.5, height: 0.35)
        case .halveHeightDown:
            MenuIconUnitRect(x: 0.25, y: 0.15, width: 0.5, height: 0.35)
        case .halveWidthLeft:
            MenuIconUnitRect(x: 0.15, y: 0.25, width: 0.35, height: 0.5)
        case .halveWidthRight:
            MenuIconUnitRect(x: 0.5, y: 0.25, width: 0.35, height: 0.5)
        }
    }

    public static let menuOrder: [WindowAction] = [
        .leftHalf, .rightHalf, .centerHalf, .topHalf, .bottomHalf,
        .topLeft, .topRight, .bottomLeft, .bottomRight,
        .firstThird, .centerThird, .lastThird, .firstTwoThirds, .centerTwoThirds, .lastTwoThirds,
        .topVerticalThird, .middleVerticalThird, .bottomVerticalThird, .topVerticalTwoThirds, .bottomVerticalTwoThirds,
        .maximize, .almostMaximize, .maximizeHeight, .larger, .smaller, .largerWidth, .smallerWidth, .largerHeight, .smallerHeight,
        .center, .centerProminently, .restore,
        .nextDisplay, .previousDisplay,
        .moveLeft, .moveRight, .moveUp, .moveDown,
        .firstFourth, .secondFourth, .thirdFourth, .lastFourth, .firstThreeFourths, .centerThreeFourths, .lastThreeFourths,
        .topLeftSixth, .topCenterSixth, .topRightSixth, .bottomLeftSixth, .bottomCenterSixth, .bottomRightSixth,
        .tileAll, .tileActiveApp, .cascadeAll, .cascadeActiveApp, .reverseAll,
        .leftTodo, .rightTodo,
    ]

    public static let additionalSizes: [WindowAction] = [
        .topLeftNinth, .topCenterNinth, .topRightNinth, .middleLeftNinth, .middleCenterNinth,
        .middleRightNinth, .bottomLeftNinth, .bottomCenterNinth, .bottomRightNinth,
        .topLeftEighth, .topCenterLeftEighth, .topCenterRightEighth, .topRightEighth,
        .bottomLeftEighth, .bottomCenterLeftEighth, .bottomCenterRightEighth, .bottomRightEighth,
        .topLeftTwelfth, .topCenterLeftTwelfth, .topCenterRightTwelfth, .topRightTwelfth,
        .middleLeftTwelfth, .middleCenterLeftTwelfth, .middleCenterRightTwelfth, .middleRightTwelfth,
        .bottomLeftTwelfth, .bottomCenterLeftTwelfth, .bottomCenterRightTwelfth, .bottomRightTwelfth,
        .topLeftSixteenth, .topCenterLeftSixteenth, .topCenterRightSixteenth, .topRightSixteenth,
        .upperMiddleLeftSixteenth, .upperMiddleCenterLeftSixteenth, .upperMiddleCenterRightSixteenth,
        .upperMiddleRightSixteenth, .lowerMiddleLeftSixteenth, .lowerMiddleCenterLeftSixteenth,
        .lowerMiddleCenterRightSixteenth, .lowerMiddleRightSixteenth, .bottomLeftSixteenth,
        .bottomCenterLeftSixteenth, .bottomCenterRightSixteenth, .bottomRightSixteenth,
        .topLeftThird, .topRightThird, .bottomLeftThird, .bottomRightThird,
        .specified, .centerProminently,
        .doubleHeightUp, .doubleHeightDown, .doubleWidthLeft, .doubleWidthRight,
        .halveHeightUp, .halveHeightDown, .halveWidthLeft, .halveWidthRight,
        .displayOne, .displayTwo, .displayThree, .displayFour, .displayFive,
        .displaySix, .displaySeven, .displayEight, .displayNine,
    ]

    public static func parse(name: String) -> WindowAction? {
        let folded = name
            .replacingOccurrences(of: "_", with: "-")
            .lowercased()
        let aliases: [String: WindowAction] = [
            "left-side": .leftHalf,
            "right-side": .rightHalf,
            "top-side": .topHalf,
            "bottom-side": .bottomHalf,
            "center-section": .centerHalf,
            "leftside": .leftHalf,
            "rightside": .rightHalf,
        ]
        if let aliased = aliases[folded] { return aliased }
        return WindowAction(rawValue: kebabToCamel(folded)) ?? WindowAction(rawValue: folded)
    }

    private static func kebabToCamel(_ value: String) -> String {
        let parts = value.split(separator: "-")
        guard let first = parts.first else { return value }
        return first.lowercased() + parts.dropFirst().map { $0.capitalized }.joined()
    }
}

public enum WindowActionCategory: String, CaseIterable, Sendable {
    case halves
    case corners
    case thirds
    case size
    case position
    case displays
    case move
    case fourths
    case sixths
    case ninths
    case eighths
    case twelfths
    case sixteenths
    case cornerThirds
    case arrange
    case todo

    public var displayName: String {
        switch self {
        case .halves: "Halves"
        case .corners: "Corners"
        case .thirds: "Thirds"
        case .size: "Size"
        case .position: "Position"
        case .displays: "Displays"
        case .move: "Move"
        case .fourths: "Fourths"
        case .sixths: "Sixths"
        case .ninths: "Ninths"
        case .eighths: "Eighths"
        case .twelfths: "Twelfths"
        case .sixteenths: "Sixteenths"
        case .cornerThirds: "Corner Two-Thirds"
        case .arrange: "Arrange"
        case .todo: "Todo"
        }
    }

    public var menuOrder: Int {
        switch self {
        case .halves: 0
        case .corners: 1
        case .thirds: 2
        case .size: 3
        case .position: 4
        case .displays: 5
        case .move: 6
        case .fourths: 7
        case .sixths: 8
        case .eighths: 9
        case .ninths: 10
        case .twelfths: 11
        case .sixteenths: 12
        case .cornerThirds: 13
        case .arrange: 14
        case .todo: 15
        }
    }
}

public struct MenuIconUnitRect: Equatable, Sendable {
    public var x: Double
    public var y: Double
    public var width: Double
    public var height: Double

    public init(x: Double, y: Double, width: Double, height: Double) {
        self.x = x
        self.y = y
        self.width = width
        self.height = height
    }

    public var maxX: Double { x + width }
    public var maxY: Double { y + height }
}

enum MenuIconGrid {
    static func cell(
        columns: Int,
        rows: Int,
        column: Int,
        row: Int,
        columnSpan: Int = 1,
        rowSpan: Int = 1
    ) -> MenuIconUnitRect {
        MenuIconUnitRect(
            x: Double(column) / Double(columns),
            y: Double(row) / Double(rows),
            width: Double(columnSpan) / Double(columns),
            height: Double(rowSpan) / Double(rows)
        )
    }
}

public struct EdgeSet: OptionSet, Hashable, Codable, Sendable {
    public let rawValue: Int

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    public static let left = EdgeSet(rawValue: 1 << 0)
    public static let right = EdgeSet(rawValue: 1 << 1)
    public static let top = EdgeSet(rawValue: 1 << 2)
    public static let bottom = EdgeSet(rawValue: 1 << 3)
}
