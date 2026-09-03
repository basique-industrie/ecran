import CoreGraphics
import Domain
import Foundation

public enum WindowLayoutEngine {
    public static func calculate(_ request: LayoutRequest) -> LayoutResult {
        let action = request.action
        var frameSettings = request.settings
        if action == .leftTodo || action == .rightTodo {
            frameSettings.todoMode = false
        }
        let frame = GapPolicy.usableFrame(for: request.screen, settings: frameSettings)
        if action == .restore {
            return LayoutResult(rect: request.window, action: .restore, screenIndex: request.screen.index)
        }
        if action.isDisplayTraversal {
            return displayResult(request)
        }

        var result = baseRect(for: action, request: request, frame: frame)
        result.rect = GapPolicy.applyGaps(result.rect, action: result.action, settings: request.settings)
        return result
    }

    public static func tile(_ windows: [CGRect], in frame: CGRect, settings: AppSettings) -> [CGRect] {
        guard !windows.isEmpty else { return [] }
        let columns = max(1, Int(ceil(sqrt(Double(windows.count)))))
        let rows = Int(ceil(Double(windows.count) / Double(columns)))
        return windows.enumerated().map { index, _ in
            let column = index % columns
            let row = index / columns
            let rect = RectMath.cell(in: frame, column: column, row: row, columns: columns, rows: rows)
            return GapPolicy.applyGaps(rect, action: .tileAll, settings: settings)
        }
    }

    public static func cascade(_ windows: [CGRect], in frame: CGRect, settings: AppSettings) -> [CGRect] {
        let delta = settings.cascadeDelta
        return windows.enumerated().map { index, window in
            var rect = window
            if rect.width == 0 || rect.height == 0 {
                rect.size = CGSize(width: frame.width * 0.6, height: frame.height * 0.6)
            }
            rect.origin.x = frame.minX + CGFloat(index) * delta
            rect.origin.y = frame.minY + CGFloat(index) * delta
            return rect
        }
    }

    public static func reverse(_ windows: [CGRect], in frame: CGRect) -> [CGRect] {
        windows.map { window in
            CGRect(
                x: frame.maxX - (window.maxX - frame.minX),
                y: window.minY,
                width: window.width,
                height: window.height
            )
        }
    }

    private static func baseRect(for action: WindowAction, request: LayoutRequest, frame: CGRect) -> LayoutResult {
        let portrait = request.screen.isPortrait
        let last = request.lastAction
        let repeated = last?.action == action && rectsMatch(last?.rect, request.window)
        let count = last?.count ?? 0

        switch action {
        case .leftHalf:
            return half(request, frame: frame, leading: true, horizontal: true, repeated: repeated, count: count)
        case .rightHalf:
            return half(request, frame: frame, leading: false, horizontal: true, repeated: repeated, count: count)
        case .topHalf:
            return half(request, frame: frame, leading: true, horizontal: false, repeated: repeated, count: count)
        case .bottomHalf:
            return half(request, frame: frame, leading: false, horizontal: false, repeated: repeated, count: count)
        case .centerHalf:
            return centerBand(request, frame: frame, repeated: repeated, count: count)
        case .topLeft:
            return corner(request, frame: frame, horizontalLeading: true, verticalLeading: true, repeated: repeated, count: count)
        case .topRight:
            return corner(request, frame: frame, horizontalLeading: false, verticalLeading: true, repeated: repeated, count: count)
        case .bottomLeft:
            return corner(request, frame: frame, horizontalLeading: true, verticalLeading: false, repeated: repeated, count: count)
        case .bottomRight:
            return corner(request, frame: frame, horizontalLeading: false, verticalLeading: false, repeated: repeated, count: count)
        case .firstThird:
            return cycleThirds(request, frame: frame, start: 0, reverse: false, portrait: portrait)
        case .centerThird:
            return LayoutResult(rect: third(frame, index: 1, portrait: portrait), action: action, subAction: "center", screenIndex: request.screen.index)
        case .lastThird:
            return cycleThirds(request, frame: frame, start: 2, reverse: true, portrait: portrait)
        case .firstTwoThirds:
            return LayoutResult(rect: twoThirds(frame, start: 0, portrait: portrait), action: action, screenIndex: request.screen.index)
        case .centerTwoThirds:
            return LayoutResult(rect: centerSpan(frame, fraction: 2.0 / 3.0, portrait: portrait), action: action, screenIndex: request.screen.index)
        case .lastTwoThirds:
            return LayoutResult(rect: twoThirds(frame, start: 1, portrait: portrait), action: action, screenIndex: request.screen.index)
        case .topVerticalThird:
            return LayoutResult(rect: RectMath.band(in: frame, index: 0, count: 3, horizontal: false), action: action, screenIndex: request.screen.index)
        case .middleVerticalThird:
            return LayoutResult(rect: RectMath.band(in: frame, index: 1, count: 3, horizontal: false), action: action, screenIndex: request.screen.index)
        case .bottomVerticalThird:
            return LayoutResult(rect: RectMath.band(in: frame, index: 2, count: 3, horizontal: false), action: action, screenIndex: request.screen.index)
        case .topVerticalTwoThirds:
            return LayoutResult(rect: RectMath.span(in: frame, start: 0, length: 2, count: 3, horizontal: false), action: action, screenIndex: request.screen.index)
        case .bottomVerticalTwoThirds:
            return LayoutResult(rect: RectMath.span(in: frame, start: 1, length: 2, count: 3, horizontal: false), action: action, screenIndex: request.screen.index)
        case .maximize:
            return LayoutResult(rect: frame, action: action, screenIndex: request.screen.index)
        case .almostMaximize:
            let width = frame.width * request.settings.almostMaximizeWidth
            let height = frame.height * request.settings.almostMaximizeHeight
            let rect = CGRect(
                x: frame.midX - width / 2,
                y: frame.midY - height / 2,
                width: width,
                height: height
            )
            return LayoutResult(rect: rect, action: action, screenIndex: request.screen.index)
        case .maximizeHeight:
            return LayoutResult(
                rect: CGRect(x: request.window.minX, y: frame.minY, width: request.window.width, height: frame.height),
                action: action,
                screenIndex: request.screen.index
            )
        case .larger, .smaller, .largerWidth, .smallerWidth, .largerHeight, .smallerHeight:
            return resize(request, frame: frame, action: action)
        case .center:
            return LayoutResult(rect: RectMath.centered(request.window, in: frame), action: action, screenIndex: request.screen.index)
        case .centerProminently:
            var rect = RectMath.centered(request.window, in: frame)
            rect.origin.y -= 0.25 * (frame.height - rect.height)
            return LayoutResult(rect: rect, action: action, screenIndex: request.screen.index)
        case .specified:
            let width = request.settings.specifiedWidth <= 1
                ? frame.width * request.settings.specifiedWidth
                : request.settings.specifiedWidth
            let height = request.settings.specifiedHeight <= 1
                ? frame.height * request.settings.specifiedHeight
                : request.settings.specifiedHeight
            let rect = CGRect(
                x: frame.midX - width / 2,
                y: frame.midY - height / 2,
                width: min(width, frame.width),
                height: min(height, frame.height)
            )
            return LayoutResult(rect: rect, action: action, screenIndex: request.screen.index)
        case .moveLeft, .moveRight, .moveUp, .moveDown:
            return directionalMove(request, frame: frame, action: action, repeated: repeated, count: count)
        case .firstFourth:
            return LayoutResult(rect: RectMath.band(in: frame, index: 0, count: 4, horizontal: !portrait), action: action, screenIndex: request.screen.index)
        case .secondFourth:
            return LayoutResult(rect: RectMath.band(in: frame, index: 1, count: 4, horizontal: !portrait), action: action, screenIndex: request.screen.index)
        case .thirdFourth:
            return LayoutResult(rect: RectMath.band(in: frame, index: 2, count: 4, horizontal: !portrait), action: action, screenIndex: request.screen.index)
        case .lastFourth:
            return LayoutResult(rect: RectMath.band(in: frame, index: 3, count: 4, horizontal: !portrait), action: action, screenIndex: request.screen.index)
        case .firstThreeFourths:
            return LayoutResult(rect: RectMath.span(in: frame, start: 0, length: 3, count: 4, horizontal: !portrait), action: action, screenIndex: request.screen.index)
        case .centerThreeFourths:
            return LayoutResult(rect: centerSpan(frame, fraction: 0.75, portrait: portrait), action: action, screenIndex: request.screen.index)
        case .lastThreeFourths:
            return LayoutResult(rect: RectMath.span(in: frame, start: 1, length: 3, count: 4, horizontal: !portrait), action: action, screenIndex: request.screen.index)
        case .topLeftSixth, .topCenterSixth, .topRightSixth, .bottomLeftSixth, .bottomCenterSixth, .bottomRightSixth:
            return grid(request, columns: 3, rows: 2, action: action)
        case .topLeftNinth, .topCenterNinth, .topRightNinth, .middleLeftNinth, .middleCenterNinth, .middleRightNinth,
             .bottomLeftNinth, .bottomCenterNinth, .bottomRightNinth:
            return grid(request, columns: 3, rows: 3, action: action)
        case .topLeftEighth, .topCenterLeftEighth, .topCenterRightEighth, .topRightEighth,
             .bottomLeftEighth, .bottomCenterLeftEighth, .bottomCenterRightEighth, .bottomRightEighth:
            return grid(request, columns: 4, rows: 2, action: action)
        case .topLeftTwelfth, .topCenterLeftTwelfth, .topCenterRightTwelfth, .topRightTwelfth,
             .middleLeftTwelfth, .middleCenterLeftTwelfth, .middleCenterRightTwelfth, .middleRightTwelfth,
             .bottomLeftTwelfth, .bottomCenterLeftTwelfth, .bottomCenterRightTwelfth, .bottomRightTwelfth:
            return grid(request, columns: 4, rows: 3, action: action)
        case .topLeftSixteenth, .topCenterLeftSixteenth, .topCenterRightSixteenth, .topRightSixteenth,
             .upperMiddleLeftSixteenth, .upperMiddleCenterLeftSixteenth, .upperMiddleCenterRightSixteenth,
             .upperMiddleRightSixteenth, .lowerMiddleLeftSixteenth, .lowerMiddleCenterLeftSixteenth,
             .lowerMiddleCenterRightSixteenth, .lowerMiddleRightSixteenth, .bottomLeftSixteenth,
             .bottomCenterLeftSixteenth, .bottomCenterRightSixteenth, .bottomRightSixteenth:
            return grid(request, columns: 4, rows: 4, action: action)
        case .topLeftThird, .topRightThird, .bottomLeftThird, .bottomRightThird:
            return cornerTwoThirds(request, frame: frame, action: action)
        case .leftTodo:
            return todo(request, frame: frame, left: true)
        case .rightTodo:
            return todo(request, frame: frame, left: false)
        case .doubleHeightUp, .doubleHeightDown, .doubleWidthLeft, .doubleWidthRight,
             .halveHeightUp, .halveHeightDown, .halveWidthLeft, .halveWidthRight:
            return scaleDimension(request, frame: frame, action: action)
        case .restore, .nextDisplay, .previousDisplay, .displayOne, .displayTwo, .displayThree, .displayFour,
             .displayFive, .displaySix, .displaySeven, .displayEight, .displayNine,
             .reverseAll, .tileAll, .cascadeAll, .cascadeActiveApp, .tileActiveApp:
            return LayoutResult(rect: request.window, action: action, screenIndex: request.screen.index)
        }
    }

    private static func half(
        _ request: LayoutRequest,
        frame: CGRect,
        leading: Bool,
        horizontal: Bool,
        repeated: Bool,
        count: Int
    ) -> LayoutResult {
        let mode = request.settings.subsequentExecutionMode
        if repeated, mode == .acrossMonitor || mode == .acrossAndResize, horizontal {
            let next = adjacentScreen(request, forward: !leading)
            let nextFrame = GapPolicy.usableFrame(for: next, settings: request.settings)
            let rect = leading
                ? RectMath.trailing(in: nextFrame, fraction: 0.5, horizontal: true)
                : RectMath.leading(in: nextFrame, fraction: 0.5, horizontal: true)
            return LayoutResult(rect: rect, action: request.action, screenIndex: next.index)
        }
        let fraction: Double
        if repeated, mode == .resize || mode == .resizeAndCycleQuadrants || mode == .acrossAndResize {
            fraction = CycleSize.next(after: count, selected: request.settings.selectedCycleSizes).fraction
        } else {
            fraction = 0.5
        }
        var rect = leading
            ? RectMath.leading(in: frame, fraction: fraction, horizontal: horizontal)
            : RectMath.trailing(in: frame, fraction: fraction, horizontal: horizontal)
        if request.settings.halvesPreserveOtherAxisSize {
            if horizontal {
                rect.origin.y = request.window.minY
                rect.size.height = request.window.height
            } else {
                rect.origin.x = request.window.minX
                rect.size.width = request.window.width
            }
        }
        return LayoutResult(rect: rect, action: request.action, screenIndex: request.screen.index)
    }

    private static func centerBand(
        _ request: LayoutRequest,
        frame: CGRect,
        repeated: Bool,
        count: Int
    ) -> LayoutResult {
        var fraction = 0.5
        if repeated, request.settings.centerHalfCycles || request.settings.subsequentExecutionMode == .resize {
            fraction = CycleSize.next(after: count, selected: request.settings.selectedCycleSizes).fraction
        }
        let horizontal = !request.screen.isPortrait
        let rect = centerSpan(frame, fraction: fraction, portrait: !horizontal)
        return LayoutResult(rect: rect, action: .centerHalf, screenIndex: request.screen.index)
    }

    private static func corner(
        _ request: LayoutRequest,
        frame: CGRect,
        horizontalLeading: Bool,
        verticalLeading: Bool,
        repeated: Bool,
        count: Int
    ) -> LayoutResult {
        var horizontalFraction = 0.5
        var verticalFraction = 0.5
        if repeated, request.settings.subsequentExecutionMode == .resize || request.settings.subsequentExecutionMode == .resizeAndCycleQuadrants {
            let fraction = CycleSize.next(after: count, selected: request.settings.selectedCycleSizes).fraction
            if request.settings.cornerCycleAxis == .horizontal {
                horizontalFraction = fraction
            } else {
                verticalFraction = fraction
            }
        }
        let horizontal = horizontalLeading
            ? RectMath.leading(in: frame, fraction: horizontalFraction, horizontal: true)
            : RectMath.trailing(in: frame, fraction: horizontalFraction, horizontal: true)
        let vertical = verticalLeading
            ? RectMath.leading(in: frame, fraction: verticalFraction, horizontal: false)
            : RectMath.trailing(in: frame, fraction: verticalFraction, horizontal: false)
        let rect = CGRect(x: horizontal.minX, y: vertical.minY, width: horizontal.width, height: vertical.height)
        return LayoutResult(rect: rect, action: request.action, screenIndex: request.screen.index)
    }

    private static func cycleThirds(
        _ request: LayoutRequest,
        frame: CGRect,
        start: Int,
        reverse: Bool,
        portrait: Bool
    ) -> LayoutResult {
        var index = start
        if request.lastAction?.action == request.action || request.lastAction?.action == (reverse ? .firstThird : .lastThird) {
            let sequence = reverse ? [2, 1, 0] : [0, 1, 2]
            let current = request.lastAction?.subAction.flatMap { ["first": 0, "center": 1, "last": 2][$0] } ?? start
            if let position = sequence.firstIndex(of: current) {
                index = sequence[(position + 1) % sequence.count]
            }
        }
        let labels = ["first", "center", "last"]
        return LayoutResult(
            rect: third(frame, index: index, portrait: portrait),
            action: request.action,
            subAction: labels[index],
            screenIndex: request.screen.index
        )
    }

    private static func third(_ frame: CGRect, index: Int, portrait: Bool) -> CGRect {
        RectMath.band(in: frame, index: index, count: 3, horizontal: !portrait)
    }

    private static func twoThirds(_ frame: CGRect, start: Int, portrait: Bool) -> CGRect {
        RectMath.span(in: frame, start: start, length: 2, count: 3, horizontal: !portrait)
    }

    private static func centerSpan(_ frame: CGRect, fraction: Double, portrait: Bool) -> CGRect {
        if portrait {
            let height = RectMath.floorDimension(frame.height * fraction)
            return CGRect(x: frame.minX, y: frame.midY - height / 2, width: frame.width, height: height)
        }
        let width = RectMath.floorDimension(frame.width * fraction)
        return CGRect(x: frame.midX - width / 2, y: frame.minY, width: width, height: frame.height)
    }

    private static func resize(_ request: LayoutRequest, frame: CGRect, action: WindowAction) -> LayoutResult {
        var rect = request.window
        let grow = action == .larger || action == .largerWidth || action == .largerHeight
        let step = action == .largerWidth || action == .smallerWidth
            ? request.settings.widthStepSize
            : request.settings.sizeOffset
        let delta = grow ? step : -step
        if action == .larger || action == .smaller || action == .largerWidth || action == .smallerWidth {
            rect.size.width = max(frame.width * request.settings.minimumWindowWidth, rect.width + delta)
            rect.origin.x -= delta / 2
        }
        if action == .larger || action == .smaller || action == .largerHeight || action == .smallerHeight {
            rect.size.height = max(frame.height * request.settings.minimumWindowHeight, rect.height + delta)
            rect.origin.y -= delta / 2
        }
        rect.size.width = min(rect.width, frame.width)
        rect.size.height = min(rect.height, frame.height)
        rect.origin.x = min(max(rect.minX, frame.minX), frame.maxX - rect.width)
        rect.origin.y = min(max(rect.minY, frame.minY), frame.maxY - rect.height)
        return LayoutResult(rect: rect, action: action, screenIndex: request.screen.index)
    }

    private static func directionalMove(
        _ request: LayoutRequest,
        frame: CGRect,
        action: WindowAction,
        repeated: Bool,
        count: Int
    ) -> LayoutResult {
        if request.settings.resizeOnDirectionalMove {
            switch action {
            case .moveLeft:
                return half(request, frame: frame, leading: true, horizontal: true, repeated: repeated, count: count)
            case .moveRight:
                return half(request, frame: frame, leading: false, horizontal: true, repeated: repeated, count: count)
            case .moveUp:
                return half(request, frame: frame, leading: true, horizontal: false, repeated: repeated, count: count)
            case .moveDown:
                return half(request, frame: frame, leading: false, horizontal: false, repeated: repeated, count: count)
            default:
                break
            }
        }
        var rect = request.window
        switch action {
        case .moveLeft:
            rect.origin.x = frame.minX
            if request.settings.centeredDirectionalMove {
                rect.origin.y = frame.midY - rect.height / 2
            }
        case .moveRight:
            rect.origin.x = frame.maxX - rect.width
            if request.settings.centeredDirectionalMove {
                rect.origin.y = frame.midY - rect.height / 2
            }
        case .moveUp:
            rect.origin.y = frame.minY
            if request.settings.centeredDirectionalMove {
                rect.origin.x = frame.midX - rect.width / 2
            }
        case .moveDown:
            rect.origin.y = frame.maxY - rect.height
            if request.settings.centeredDirectionalMove {
                rect.origin.x = frame.midX - rect.width / 2
            }
        default:
            break
        }
        return LayoutResult(rect: rect, action: action, screenIndex: request.screen.index)
    }

    private static func grid(_ request: LayoutRequest, columns: Int, rows: Int, action: WindowAction) -> LayoutResult {
        let cells = gridCells(columns: columns, rows: rows)
        let index = cells.firstIndex(of: action) ?? 0
        let column = index % columns
        let row = index / columns
        let frame = GapPolicy.usableFrame(for: request.screen, settings: request.settings)
        let rect = RectMath.cell(in: frame, column: column, row: row, columns: columns, rows: rows)
        return LayoutResult(rect: rect, action: action, screenIndex: request.screen.index)
    }

    private static func gridCells(columns: Int, rows: Int) -> [WindowAction] {
        switch (columns, rows) {
        case (3, 2):
            [.topLeftSixth, .topCenterSixth, .topRightSixth, .bottomLeftSixth, .bottomCenterSixth, .bottomRightSixth]
        case (3, 3):
            [
                .topLeftNinth, .topCenterNinth, .topRightNinth,
                .middleLeftNinth, .middleCenterNinth, .middleRightNinth,
                .bottomLeftNinth, .bottomCenterNinth, .bottomRightNinth,
            ]
        case (4, 2):
            [
                .topLeftEighth, .topCenterLeftEighth, .topCenterRightEighth, .topRightEighth,
                .bottomLeftEighth, .bottomCenterLeftEighth, .bottomCenterRightEighth, .bottomRightEighth,
            ]
        case (4, 3):
            [
                .topLeftTwelfth, .topCenterLeftTwelfth, .topCenterRightTwelfth, .topRightTwelfth,
                .middleLeftTwelfth, .middleCenterLeftTwelfth, .middleCenterRightTwelfth, .middleRightTwelfth,
                .bottomLeftTwelfth, .bottomCenterLeftTwelfth, .bottomCenterRightTwelfth, .bottomRightTwelfth,
            ]
        case (4, 4):
            [
                .topLeftSixteenth, .topCenterLeftSixteenth, .topCenterRightSixteenth, .topRightSixteenth,
                .upperMiddleLeftSixteenth, .upperMiddleCenterLeftSixteenth, .upperMiddleCenterRightSixteenth, .upperMiddleRightSixteenth,
                .lowerMiddleLeftSixteenth, .lowerMiddleCenterLeftSixteenth, .lowerMiddleCenterRightSixteenth, .lowerMiddleRightSixteenth,
                .bottomLeftSixteenth, .bottomCenterLeftSixteenth, .bottomCenterRightSixteenth, .bottomRightSixteenth,
            ]
        default:
            []
        }
    }

    private static func cornerTwoThirds(_ request: LayoutRequest, frame: CGRect, action: WindowAction) -> LayoutResult {
        let horizontalLeading = action == .topLeftThird || action == .bottomLeftThird
        let verticalLeading = action == .topLeftThird || action == .topRightThird
        let horizontal = horizontalLeading
            ? RectMath.leading(in: frame, fraction: 2.0 / 3.0, horizontal: true)
            : RectMath.trailing(in: frame, fraction: 2.0 / 3.0, horizontal: true)
        let vertical = verticalLeading
            ? RectMath.leading(in: frame, fraction: 2.0 / 3.0, horizontal: false)
            : RectMath.trailing(in: frame, fraction: 2.0 / 3.0, horizontal: false)
        let rect = CGRect(x: horizontal.minX, y: vertical.minY, width: horizontal.width, height: vertical.height)
        return LayoutResult(rect: rect, action: action, screenIndex: request.screen.index)
    }

    private static func todo(_ request: LayoutRequest, frame: CGRect, left: Bool) -> LayoutResult {
        let reserved = request.settings.todoIsFraction
            ? frame.width * request.settings.todoWidth
            : request.settings.todoWidth
        let rect = left
            ? CGRect(x: frame.minX, y: frame.minY, width: reserved, height: frame.height)
            : CGRect(x: frame.maxX - reserved, y: frame.minY, width: reserved, height: frame.height)
        return LayoutResult(rect: rect, action: request.action, screenIndex: request.screen.index)
    }

    private static func scaleDimension(_ request: LayoutRequest, frame: CGRect, action: WindowAction) -> LayoutResult {
        var rect = request.window
        switch action {
        case .doubleHeightUp:
            let bottom = rect.maxY
            rect.size.height = min(frame.height, rect.height * 2)
            rect.origin.y = max(frame.minY, bottom - rect.height)
        case .doubleHeightDown:
            rect.size.height = min(frame.height, rect.height * 2)
            rect.origin.y = min(rect.minY, frame.maxY - rect.height)
        case .doubleWidthLeft:
            rect.size.width = min(frame.width, rect.width * 2)
            rect.origin.x = max(frame.minX, rect.maxX - rect.width)
        case .doubleWidthRight:
            rect.size.width = min(frame.width, rect.width * 2)
            rect.origin.x = min(frame.maxX - rect.width, rect.minX)
        case .halveHeightUp:
            rect.size.height /= 2
        case .halveHeightDown:
            rect.origin.y += rect.height / 2
            rect.size.height /= 2
        case .halveWidthLeft:
            rect.size.width /= 2
        case .halveWidthRight:
            rect.origin.x += rect.width / 2
            rect.size.width /= 2
        default:
            break
        }
        return LayoutResult(rect: rect, action: action, screenIndex: request.screen.index)
    }

    private static func displayResult(_ request: LayoutRequest) -> LayoutResult {
        let screens = orderedScreens(request)
        let current = screens.firstIndex(where: { $0.index == request.screen.index }) ?? 0
        let target: ScreenFrame
        switch request.action {
        case .nextDisplay:
            target = request.settings.traverseSingleScreen
                ? request.screen
                : screens[(current + 1) % screens.count]
        case .previousDisplay:
            target = request.settings.traverseSingleScreen
                ? request.screen
                : screens[(current - 1 + screens.count) % screens.count]
        case .displayOne, .displayTwo, .displayThree, .displayFour, .displayFive, .displaySix, .displaySeven,
             .displayEight, .displayNine:
            let index = displayNumber(request.action) - 1
            target = index < screens.count ? screens[index] : request.screen
        default:
            target = request.screen
        }
        let frame = GapPolicy.usableFrame(for: target, settings: request.settings)
        if request.settings.autoMaximize, request.lastAction?.action == .maximize {
            return LayoutResult(rect: frame, action: request.action, screenIndex: target.index)
        }
        if request.settings.attemptMatchOnNextPrevDisplay,
           let last = request.lastAction,
           !last.action.isDisplayTraversal
        {
            var matched = request
            matched.action = last.action
            matched.screen = target
            return calculate(matched)
        }
        let rect = RectMath.centered(request.window, in: frame)
        return LayoutResult(rect: rect, action: request.action, screenIndex: target.index)
    }

    private static func displayNumber(_ action: WindowAction) -> Int {
        switch action {
        case .displayOne: 1
        case .displayTwo: 2
        case .displayThree: 3
        case .displayFour: 4
        case .displayFive: 5
        case .displaySix: 6
        case .displaySeven: 7
        case .displayEight: 8
        case .displayNine: 9
        default: 1
        }
    }

    private static func orderedScreens(_ request: LayoutRequest) -> [ScreenFrame] {
        switch request.settings.screensOrderedBy {
        case .yThenMinX:
            request.screens.sorted { lhs, rhs in
                if abs(lhs.full.minY - rhs.full.minY) > 1 {
                    return lhs.full.minY < rhs.full.minY
                }
                return lhs.full.minX < rhs.full.minX
            }
        case .minX:
            request.screens.sorted { $0.full.minX < $1.full.minX }
        case .midX:
            request.screens.sorted { $0.full.midX < $1.full.midX }
        }
    }

    private static func adjacentScreen(_ request: LayoutRequest, forward: Bool) -> ScreenFrame {
        if request.settings.traverseSingleScreen {
            return request.screen
        }
        let screens = orderedScreens(request)
        guard let current = screens.firstIndex(where: { $0.index == request.screen.index }) else {
            return request.screen
        }
        let next = forward
            ? (current + 1) % screens.count
            : (current - 1 + screens.count) % screens.count
        return screens[next]
    }

    private static func rectsMatch(_ snapshot: RectSnapshot?, _ rect: CGRect) -> Bool {
        guard let snapshot else { return false }
        return abs(snapshot.x - rect.minX) < 2
            && abs(snapshot.y - rect.minY) < 2
            && abs(snapshot.width - rect.width) < 2
            && abs(snapshot.height - rect.height) < 2
    }
}
