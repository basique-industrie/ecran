import AppKit
import Domain

enum PlacementIcon {
    static let menuSize = NSSize(width: 18, height: 12)

    static func image(for action: WindowAction, rotateThirdsForPortrait: Bool = false) -> NSImage {
        var image = draw(action: action)
        if rotateThirdsForPortrait, action.menuSubcategory == .thirds {
            image = image.rotated(by: 270)
        }
        image.size = menuSize
        image.isTemplate = true
        return image
    }

    private static func draw(action: WindowAction) -> NSImage {
        let size = menuSize
        let image = NSImage(size: size, flipped: false) { rect in
            NSGraphicsContext.current?.imageInterpolation = .high
            NSColor.black.set()
            drawScreen(in: rect, fill: action.menuIconUnitRect.cgRect, decoration: Decoration(action))
            return true
        }
        image.isTemplate = true
        return image
    }

    private static func drawScreen(in rect: NSRect, fill: CGRect, decoration: Decoration) {
        let screen = rect.insetBy(dx: 0.7, dy: 0.7)
        let outline = NSBezierPath(roundedRect: screen, xRadius: 1.6, yRadius: 1.6)
        outline.lineWidth = 1
        outline.stroke()

        let inner = screen.insetBy(dx: 1.15, dy: 1.15)
        let filled = CGRect(
            x: inner.minX + fill.minX * inner.width,
            y: inner.minY + fill.minY * inner.height,
            width: max(fill.width * inner.width, 1),
            height: max(fill.height * inner.height, 1)
        )
        NSBezierPath(roundedRect: filled, xRadius: 0.55, yRadius: 0.55).fill()

        switch decoration {
        case .none:
            break
        case .plus:
            drawPlus(in: inner)
        case .minus:
            drawMinus(in: inner)
        case .arrow(let angle):
            drawArrow(in: inner, angle: angle)
        case .tile:
            drawTile(in: inner)
        case .cascade:
            drawCascade(in: inner)
        case .glyph(let text):
            drawGlyph(text, in: inner)
        }
    }

    private static func drawPlus(in rect: NSRect) {
        let path = NSBezierPath()
        path.lineWidth = 1.1
        path.lineCapStyle = .round
        let cx = rect.midX
        let cy = rect.midY
        let arm: CGFloat = min(rect.width, rect.height) * 0.22
        path.move(to: NSPoint(x: cx - arm, y: cy))
        path.line(to: NSPoint(x: cx + arm, y: cy))
        path.move(to: NSPoint(x: cx, y: cy - arm))
        path.line(to: NSPoint(x: cx, y: cy + arm))
        NSGraphicsContext.current?.cgContext.setBlendMode(.destinationOut)
        path.stroke()
        NSGraphicsContext.current?.cgContext.setBlendMode(.normal)
    }

    private static func drawMinus(in rect: NSRect) {
        let path = NSBezierPath()
        path.lineWidth = 1.1
        path.lineCapStyle = .round
        let arm = min(rect.width, rect.height) * 0.22
        path.move(to: NSPoint(x: rect.midX - arm, y: rect.midY))
        path.line(to: NSPoint(x: rect.midX + arm, y: rect.midY))
        NSGraphicsContext.current?.cgContext.setBlendMode(.destinationOut)
        path.stroke()
        NSGraphicsContext.current?.cgContext.setBlendMode(.normal)
    }

    private static func drawArrow(in rect: NSRect, angle: CGFloat) {
        let path = NSBezierPath()
        path.lineWidth = 1.05
        path.lineCapStyle = .round
        path.lineJoinStyle = .round
        let length = min(rect.width, rect.height) * 0.28
        path.move(to: NSPoint(x: -length, y: 0))
        path.line(to: NSPoint(x: length, y: 0))
        path.move(to: NSPoint(x: length * 0.25, y: length * 0.45))
        path.line(to: NSPoint(x: length, y: 0))
        path.line(to: NSPoint(x: length * 0.25, y: -length * 0.45))
        var transform = AffineTransform()
        transform.translate(x: rect.midX, y: rect.midY)
        transform.rotate(byRadians: angle)
        path.transform(using: transform)
        NSGraphicsContext.current?.cgContext.setBlendMode(.destinationOut)
        path.stroke()
        NSGraphicsContext.current?.cgContext.setBlendMode(.normal)
    }

    private static func drawTile(in rect: NSRect) {
        let inset = rect.insetBy(dx: 0.4, dy: 0.4)
        let midX = inset.midX
        let midY = inset.midY
        let path = NSBezierPath()
        path.lineWidth = 0.7
        path.move(to: NSPoint(x: midX, y: inset.minY))
        path.line(to: NSPoint(x: midX, y: inset.maxY))
        path.move(to: NSPoint(x: inset.minX, y: midY))
        path.line(to: NSPoint(x: inset.maxX, y: midY))
        NSGraphicsContext.current?.cgContext.setBlendMode(.destinationOut)
        path.stroke()
        NSGraphicsContext.current?.cgContext.setBlendMode(.normal)
    }

    private static func drawCascade(in rect: NSRect) {
        NSGraphicsContext.current?.cgContext.setBlendMode(.destinationOut)
        let first = rect.insetBy(dx: rect.width * 0.18, dy: rect.height * 0.22)
        let second = first.offsetBy(dx: 1.4, dy: 1.1).insetBy(dx: 0.4, dy: 0.3)
        NSBezierPath(roundedRect: second, xRadius: 0.5, yRadius: 0.5).stroke()
        NSGraphicsContext.current?.cgContext.setBlendMode(.normal)
    }

    private static func drawGlyph(_ text: String, in rect: NSRect) {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 7, weight: .bold),
            .foregroundColor: NSColor.black,
        ]
        let size = text.size(withAttributes: attributes)
        let origin = NSPoint(x: rect.midX - size.width / 2, y: rect.midY - size.height / 2)
        NSGraphicsContext.current?.cgContext.setBlendMode(.destinationOut)
        text.draw(at: origin, withAttributes: attributes)
        NSGraphicsContext.current?.cgContext.setBlendMode(.normal)
    }

    private enum Decoration {
        case none
        case plus
        case minus
        case arrow(CGFloat)
        case tile
        case cascade
        case glyph(String)

        init(_ action: WindowAction) {
            switch action {
            case .larger, .largerWidth, .largerHeight, .doubleHeightUp, .doubleHeightDown,
                 .doubleWidthLeft, .doubleWidthRight:
                self = .plus
            case .smaller, .smallerWidth, .smallerHeight, .halveHeightUp, .halveHeightDown,
                 .halveWidthLeft, .halveWidthRight:
                self = .minus
            case .nextDisplay, .moveRight:
                self = .arrow(0)
            case .previousDisplay, .moveLeft:
                self = .arrow(.pi)
            case .moveUp:
                self = .arrow(.pi / 2)
            case .moveDown:
                self = .arrow(-.pi / 2)
            case .tileAll, .tileActiveApp:
                self = .tile
            case .cascadeAll, .cascadeActiveApp:
                self = .cascade
            case .reverseAll:
                self = .arrow(.pi)
            case .displayOne: self = .glyph("1")
            case .displayTwo: self = .glyph("2")
            case .displayThree: self = .glyph("3")
            case .displayFour: self = .glyph("4")
            case .displayFive: self = .glyph("5")
            case .displaySix: self = .glyph("6")
            case .displaySeven: self = .glyph("7")
            case .displayEight: self = .glyph("8")
            case .displayNine: self = .glyph("9")
            default:
                self = .none
            }
        }
    }
}

private extension MenuIconUnitRect {
    var cgRect: CGRect {
        CGRect(x: x, y: y, width: width, height: height)
    }
}

private extension NSImage {
    func rotated(by degrees: CGFloat) -> NSImage {
        let radians = degrees * .pi / 180
        let swapped = abs(sin(radians)) > 0.5
        let size = swapped ? NSSize(width: self.size.height, height: self.size.width) : self.size
        let rotated = NSImage(size: size, flipped: false) { rect in
            guard let context = NSGraphicsContext.current?.cgContext else { return false }
            context.translateBy(x: rect.midX, y: rect.midY)
            context.rotate(by: radians)
            let draw = NSRect(x: -self.size.width / 2, y: -self.size.height / 2, width: self.size.width, height: self.size.height)
            self.draw(in: draw)
            return true
        }
        rotated.isTemplate = true
        return rotated
    }
}
