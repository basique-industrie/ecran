#!/usr/bin/env swift
import AppKit
import Foundation

/// Full-bleed master: dark fill to the canvas edge, three window panes, no inner squircle.
/// macOS and the README each apply one mask, so a second rounded plate would show as a double border.

let root = URL(fileURLWithPath: CommandLine.arguments[0])
    .standardizedFileURL
    .deletingLastPathComponent()
    .deletingLastPathComponent()

func renderMaster(size: CGFloat) -> NSBitmapImageRep {
    guard let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: Int(size),
        pixelsHigh: Int(size),
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    ) else {
        fputs("failed to allocate bitmap\n", stderr)
        exit(1)
    }
    rep.size = NSSize(width: size, height: size)
    NSGraphicsContext.saveGraphicsState()
    guard let context = NSGraphicsContext(bitmapImageRep: rep) else {
        fputs("failed to create graphics context\n", stderr)
        exit(1)
    }
    NSGraphicsContext.current = context
    let ctx = context.cgContext
    ctx.setShouldAntialias(true)
    ctx.setAllowsAntialiasing(true)

    let rect = CGRect(x: 0, y: 0, width: size, height: size)
    ctx.saveGState()
    let top = NSColor(calibratedWhite: 0.16, alpha: 1).cgColor
    let bottom = NSColor(calibratedWhite: 0.05, alpha: 1).cgColor
    let gradient = CGGradient(
        colorsSpace: CGColorSpaceCreateDeviceRGB(),
        colors: [top, bottom] as CFArray,
        locations: [0, 1]
    )!
    ctx.drawLinearGradient(
        gradient,
        start: CGPoint(x: 0, y: size),
        end: CGPoint(x: 0, y: 0),
        options: [.drawsBeforeStartLocation, .drawsAfterEndLocation]
    )
    ctx.restoreGState()

    ctx.saveGState()
    let sheen = CGGradient(
        colorsSpace: CGColorSpaceCreateDeviceRGB(),
        colors: [
            NSColor(calibratedWhite: 1, alpha: 0.08).cgColor,
            NSColor(calibratedWhite: 1, alpha: 0).cgColor,
        ] as CFArray,
        locations: [0, 1]
    )!
    ctx.drawRadialGradient(
        sheen,
        startCenter: CGPoint(x: size * 0.5, y: size * 0.78),
        startRadius: 0,
        endCenter: CGPoint(x: size * 0.5, y: size * 0.5),
        endRadius: size * 0.62,
        options: []
    )
    ctx.restoreGState()

    drawPanes(in: rect, ctx: ctx)
    NSGraphicsContext.restoreGraphicsState()
    return rep
}

func drawPanes(in rect: CGRect, ctx: CGContext) {
    let unitHeight: CGFloat = 38
    let scale = rect.width * 0.42 / unitHeight
    let paneWidth = 18 * scale
    let paneHeight = 38 * scale
    let halfHeight = 17.25 * scale
    let gap = 3.5 * scale
    let radius = 4.5 * scale
    let stroke = max(2.4 * scale, 2)
    let totalWidth = paneWidth * 2 + gap
    let origin = CGPoint(
        x: rect.midX - totalWidth / 2,
        y: rect.midY - paneHeight / 2
    )

    let left = CGRect(x: origin.x, y: origin.y, width: paneWidth, height: paneHeight)
    let topRight = CGRect(
        x: origin.x + paneWidth + gap,
        y: origin.y + halfHeight + gap,
        width: paneWidth,
        height: halfHeight
    )
    let bottomRight = CGRect(
        x: origin.x + paneWidth + gap,
        y: origin.y,
        width: paneWidth,
        height: halfHeight
    )

    ctx.setLineJoin(.round)
    ctx.setLineCap(.round)
    for pane in [left, topRight, bottomRight] {
        let path = CGPath(roundedRect: pane, cornerWidth: radius, cornerHeight: radius, transform: nil)
        ctx.addPath(path)
        ctx.setStrokeColor(NSColor(calibratedWhite: 1, alpha: 0.38).cgColor)
        ctx.setLineWidth(stroke)
        ctx.strokePath()

        ctx.saveGState()
        ctx.addPath(path)
        ctx.replacePathWithStrokedPath()
        ctx.clip()
        let shine = CGGradient(
            colorsSpace: CGColorSpaceCreateDeviceRGB(),
            colors: [
                NSColor(calibratedWhite: 1, alpha: 0.96).cgColor,
                NSColor(calibratedWhite: 1, alpha: 0.22).cgColor,
            ] as CFArray,
            locations: [0, 1]
        )!
        ctx.drawLinearGradient(
            shine,
            start: CGPoint(x: pane.minX, y: pane.maxY),
            end: CGPoint(x: pane.maxX, y: pane.minY),
            options: []
        )
        ctx.restoreGState()
    }
}

func pngData(_ rep: NSBitmapImageRep) -> Data {
    guard let data = rep.representation(using: .png, properties: [:]) else {
        fputs("failed to encode PNG\n", stderr)
        exit(1)
    }
    return data
}

func writePNG(_ rep: NSBitmapImageRep, to url: URL) {
    try! pngData(rep).write(to: url)
}

func maskedReadmeIcon(from master: NSBitmapImageRep, canvas: CGFloat) -> NSBitmapImageRep {
    guard let source = master.cgImage else {
        fputs("missing master cgImage\n", stderr)
        exit(1)
    }
    guard let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: Int(canvas),
        pixelsHigh: Int(canvas),
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    ) else {
        fputs("failed to allocate README bitmap\n", stderr)
        exit(1)
    }
    rep.size = NSSize(width: canvas, height: canvas)
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    let ctx = NSGraphicsContext.current!.cgContext
    ctx.setFillColor(NSColor.clear.cgColor)
    ctx.setBlendMode(.copy)
    ctx.fill(CGRect(x: 0, y: 0, width: canvas, height: canvas))
    ctx.setBlendMode(.normal)
    let padding = canvas * 0.02
    let side = canvas - padding * 2
    let iconRect = CGRect(x: padding, y: padding, width: side, height: side)
    let radius = side * 0.2237
    let path = CGPath(roundedRect: iconRect, cornerWidth: radius, cornerHeight: radius, transform: nil)
    ctx.setShouldAntialias(true)
    ctx.addPath(path)
    ctx.clip()
    ctx.draw(source, in: iconRect)
    NSGraphicsContext.restoreGraphicsState()
    return rep
}

func scaled(_ master: NSBitmapImageRep, pixels: Int) -> NSBitmapImageRep {
    guard let source = master.cgImage else {
        fputs("missing master cgImage\n", stderr)
        exit(1)
    }
    guard let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: pixels,
        pixelsHigh: pixels,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    ) else {
        fputs("failed to allocate \(pixels)px bitmap\n", stderr)
        exit(1)
    }
    rep.size = NSSize(width: pixels, height: pixels)
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    NSGraphicsContext.current?.cgContext.interpolationQuality = .high
    NSGraphicsContext.current?.cgContext.draw(
        source,
        in: CGRect(x: 0, y: 0, width: pixels, height: pixels)
    )
    NSGraphicsContext.restoreGraphicsState()
    return rep
}

let master = renderMaster(size: 1024)
let appIconURL = root.appendingPathComponent("Sources/Ecran/Resources/EcranAppIcon.png")
writePNG(master, to: appIconURL)

let readmeURL = root.appendingPathComponent("docs/assets/app-icon.png")
writePNG(maskedReadmeIcon(from: master, canvas: 512), to: readmeURL)

let iconset = FileManager.default.temporaryDirectory
    .appendingPathComponent("Ecran.iconset", isDirectory: true)
try? FileManager.default.removeItem(at: iconset)
try! FileManager.default.createDirectory(at: iconset, withIntermediateDirectories: true)

let sizes: [(name: String, pixels: Int)] = [
    ("icon_16x16.png", 16),
    ("icon_16x16@2x.png", 32),
    ("icon_32x32.png", 32),
    ("icon_32x32@2x.png", 64),
    ("icon_128x128.png", 128),
    ("icon_128x128@2x.png", 256),
    ("icon_256x256.png", 256),
    ("icon_256x256@2x.png", 512),
    ("icon_512x512.png", 512),
    ("icon_512x512@2x.png", 1024),
]
for entry in sizes {
    writePNG(scaled(master, pixels: entry.pixels), to: iconset.appendingPathComponent(entry.name))
}

let icnsURL = root.appendingPathComponent("Sources/Ecran/Resources/Ecran.icns")
let process = Process()
process.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
process.arguments = ["--convert", "icns", "--output", icnsURL.path, iconset.path]
try! process.run()
process.waitUntilExit()
guard process.terminationStatus == 0 else {
    fputs("iconutil failed\n", stderr)
    exit(1)
}

print("wrote \(appIconURL.path)")
print("wrote \(readmeURL.path)")
print("wrote \(icnsURL.path)")
