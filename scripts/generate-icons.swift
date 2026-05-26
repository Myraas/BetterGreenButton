#!/usr/bin/env swift
import AppKit

func drawAppIcon(size: Int) -> CGImage? {
    let sizeF = CGFloat(size)
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    guard let ctx = CGContext(
        data: nil,
        width: size, height: size,
        bitsPerComponent: 8,
        bytesPerRow: size * 4,
        space: colorSpace,
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    ) else { return nil }

    let cornerRadius = sizeF * 0.225
    let bgPath = CGPath(
        roundedRect: CGRect(x: 0, y: 0, width: sizeF, height: sizeF),
        cornerWidth: cornerRadius,
        cornerHeight: cornerRadius,
        transform: nil
    )
    ctx.saveGState()
    ctx.addPath(bgPath)
    ctx.clip()
    let bgGradient = CGGradient(
        colorsSpace: colorSpace,
        colors: [
            CGColor(red: 0.98, green: 1.00, blue: 0.98, alpha: 1.0),
            CGColor(red: 0.86, green: 0.95, blue: 0.86, alpha: 1.0)
        ] as CFArray,
        locations: [0, 1]
    )!
    ctx.drawLinearGradient(
        bgGradient,
        start: CGPoint(x: sizeF / 2, y: sizeF),
        end: CGPoint(x: sizeF / 2, y: 0),
        options: []
    )
    ctx.restoreGState()

    let circleDiameter = sizeF * 0.62
    let circleRect = CGRect(
        x: (sizeF - circleDiameter) / 2,
        y: (sizeF - circleDiameter) / 2,
        width: circleDiameter,
        height: circleDiameter
    )
    ctx.setShadow(
        offset: CGSize(width: 0, height: -sizeF * 0.012),
        blur: sizeF * 0.035,
        color: CGColor(red: 0, green: 0, blue: 0, alpha: 0.30)
    )
    ctx.setFillColor(CGColor(red: 0.21, green: 0.78, blue: 0.36, alpha: 1.0))
    ctx.fillEllipse(in: circleRect)

    ctx.setShadow(offset: .zero, blur: 0, color: nil)
    ctx.saveGState()
    ctx.addEllipse(in: circleRect)
    ctx.clip()
    let highlightGradient = CGGradient(
        colorsSpace: colorSpace,
        colors: [
            CGColor(red: 1, green: 1, blue: 1, alpha: 0.35),
            CGColor(red: 1, green: 1, blue: 1, alpha: 0.0)
        ] as CFArray,
        locations: [0, 1]
    )!
    let cx = circleRect.midX
    let cy = circleRect.midY
    ctx.drawRadialGradient(
        highlightGradient,
        startCenter: CGPoint(x: cx, y: cy + circleDiameter * 0.18),
        startRadius: 0,
        endCenter: CGPoint(x: cx, y: cy + circleDiameter * 0.18),
        endRadius: circleDiameter * 0.55,
        options: []
    )
    ctx.restoreGState()

    drawMaximizeArrows(
        in: ctx,
        center: CGPoint(x: cx, y: cy),
        circleDiameter: circleDiameter,
        strokeColor: CGColor(red: 1, green: 1, blue: 1, alpha: 1),
        lineWidth: sizeF * 0.040
    )

    return ctx.makeImage()
}

func drawMaximizeArrows(
    in ctx: CGContext,
    center: CGPoint,
    circleDiameter: CGFloat,
    strokeColor: CGColor,
    lineWidth: CGFloat
) {
    let armLen = circleDiameter * 0.20
    let headLen = circleDiameter * 0.115
    let innerGap = circleDiameter * 0.06

    ctx.setStrokeColor(strokeColor)
    ctx.setLineWidth(lineWidth)
    ctx.setLineCap(.round)

    let tlInner = CGPoint(x: center.x - innerGap, y: center.y + innerGap)
    let tlTip = CGPoint(x: tlInner.x - armLen, y: tlInner.y + armLen)
    ctx.move(to: tlInner)
    ctx.addLine(to: tlTip)
    ctx.move(to: tlTip)
    ctx.addLine(to: CGPoint(x: tlTip.x + headLen, y: tlTip.y))
    ctx.move(to: tlTip)
    ctx.addLine(to: CGPoint(x: tlTip.x, y: tlTip.y - headLen))

    let brInner = CGPoint(x: center.x + innerGap, y: center.y - innerGap)
    let brTip = CGPoint(x: brInner.x + armLen, y: brInner.y - armLen)
    ctx.move(to: brInner)
    ctx.addLine(to: brTip)
    ctx.move(to: brTip)
    ctx.addLine(to: CGPoint(x: brTip.x - headLen, y: brTip.y))
    ctx.move(to: brTip)
    ctx.addLine(to: CGPoint(x: brTip.x, y: brTip.y + headLen))

    ctx.strokePath()
}

func drawMenuIcon(size: Int) -> CGImage? {
    let sizeF = CGFloat(size)
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    guard let ctx = CGContext(
        data: nil,
        width: size, height: size,
        bitsPerComponent: 8,
        bytesPerRow: size * 4,
        space: colorSpace,
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    ) else { return nil }

    ctx.clear(CGRect(x: 0, y: 0, width: sizeF, height: sizeF))

    let inset = sizeF * 0.14
    let circleRect = CGRect(
        x: inset,
        y: inset,
        width: sizeF - 2 * inset,
        height: sizeF - 2 * inset
    )
    let outlineWidth = sizeF * 0.07
    ctx.setStrokeColor(CGColor(red: 0, green: 0, blue: 0, alpha: 1))
    ctx.setLineWidth(outlineWidth)
    ctx.strokeEllipse(in: circleRect)

    drawMaximizeArrows(
        in: ctx,
        center: CGPoint(x: circleRect.midX, y: circleRect.midY),
        circleDiameter: circleRect.width,
        strokeColor: CGColor(red: 0, green: 0, blue: 0, alpha: 1),
        lineWidth: sizeF * 0.07
    )

    return ctx.makeImage()
}

func writePng(_ image: CGImage, to path: String) {
    let rep = NSBitmapImageRep(cgImage: image)
    if let data = rep.representation(using: .png, properties: [:]) {
        try? data.write(to: URL(fileURLWithPath: path))
    }
}

let fm = FileManager.default
let scriptDir = URL(fileURLWithPath: CommandLine.arguments[0])
    .deletingLastPathComponent()
let projectDir = scriptDir.deletingLastPathComponent()
fm.changeCurrentDirectoryPath(projectDir.path)

let iconsetPath = "dist/icon.iconset"
let icnsPath = "assets/icon.icns"
let menuIcon2xPath = "assets/menu-icon@2x.png"

try? fm.removeItem(atPath: iconsetPath)
try? fm.createDirectory(atPath: iconsetPath, withIntermediateDirectories: true)
try? fm.createDirectory(atPath: "assets", withIntermediateDirectories: true)

let appIconSizes: [(Int, String)] = [
    (1024, "icon_512x512@2x.png")
]
for (size, name) in appIconSizes {
    guard let img = drawAppIcon(size: size) else { continue }
    writePng(img, to: "\(iconsetPath)/\(name)")
}

let iconutil = Process()
iconutil.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
iconutil.arguments = ["-c", "icns", iconsetPath, "-o", icnsPath]
try iconutil.run()
iconutil.waitUntilExit()

if let img = drawMenuIcon(size: 44) {
    writePng(img, to: menuIcon2xPath)
}

if let img = drawAppIcon(size: 512) {
    writePng(img, to: "assets/icon.png")
}
