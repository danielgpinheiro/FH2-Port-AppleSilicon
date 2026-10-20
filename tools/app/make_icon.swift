// Draws the app icon (a road running into a low sun over hills, no game
// branding) as a 1024x1024 PNG.
// Usage: swift tools/app/make_icon.swift <out.png>

import AppKit

let size: CGFloat = 1024
let out = CommandLine.arguments[1]

let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: Int(size), pixelsHigh: Int(size),
                           bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                           colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
let ctx = NSGraphicsContext.current!.cgContext
let space = CGColorSpaceCreateDeviceRGB()

func rgb(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat, _ a: CGFloat = 1) -> CGColor {
    CGColor(red: r, green: g, blue: b, alpha: a)
}

// macOS icon grid: 824 pt rounded square centred in 1024.
let tile = CGRect(x: 100, y: 100, width: 824, height: 824)
ctx.addPath(CGPath(roundedRect: tile, cornerWidth: 185, cornerHeight: 185, transform: nil))
ctx.clip()

// Sky: violet at the top, orange at the horizon.
let horizon: CGFloat = 470
let sky = CGGradient(colorsSpace: space,
                     colors: [rgb(0.23, 0.13, 0.42), rgb(0.78, 0.27, 0.42), rgb(1.0, 0.62, 0.30)] as CFArray,
                     locations: [0, 0.6, 1])!
ctx.drawLinearGradient(sky, start: CGPoint(x: 0, y: 924), end: CGPoint(x: 0, y: horizon), options: [])

// Low sun, half below the hills, with a soft glow.
let sun = CGPoint(x: 512, y: horizon + 40)
let glow = CGGradient(colorsSpace: space, colors: [rgb(1, 0.85, 0.55, 0.85), rgb(1, 0.6, 0.3, 0)] as CFArray,
                      locations: [0, 1])!
ctx.drawRadialGradient(glow, startCenter: sun, startRadius: 0, endCenter: sun, endRadius: 330, options: [])
ctx.setFillColor(rgb(1.0, 0.86, 0.52))
ctx.fillEllipse(in: CGRect(x: sun.x - 150, y: sun.y - 150, width: 300, height: 300))

// A row of hills, filled down to the bottom of the tile.
func hills(_ base: CGFloat, _ amp: CGFloat, _ phase: CGFloat, _ color: CGColor) {
    ctx.setFillColor(color)
    ctx.move(to: CGPoint(x: 100, y: 100))
    var x: CGFloat = 100
    while x <= 924 {
        let y = base + amp * sin((x / 824) * .pi * 2.2 + phase) + amp * 0.4 * sin((x / 824) * .pi * 5.1 + phase * 2)
        ctx.addLine(to: CGPoint(x: x, y: y))
        x += 8
    }
    ctx.addLine(to: CGPoint(x: 924, y: 100))
    ctx.closePath()
    ctx.fillPath()
}
// The near row of hills runs down to the bottom edge and is the ground.
hills(horizon + 30, 34, 0.6, rgb(0.42, 0.18, 0.36))
hills(horizon - 10, 26, 2.1, rgb(0.20, 0.10, 0.24))

// Road converging on the sun.
let vanish = CGPoint(x: 512, y: horizon - 18)
ctx.setFillColor(rgb(0.10, 0.10, 0.13))
ctx.move(to: vanish)
ctx.addLine(to: CGPoint(x: 900, y: 100))
ctx.addLine(to: CGPoint(x: 124, y: 100))
ctx.closePath()
ctx.fillPath()

// Road edges and dashed centre line, warm from the sunset.
ctx.setStrokeColor(rgb(1.0, 0.70, 0.40))
ctx.setLineWidth(10)
ctx.move(to: vanish); ctx.addLine(to: CGPoint(x: 890, y: 100))
ctx.move(to: vanish); ctx.addLine(to: CGPoint(x: 134, y: 100))
ctx.strokePath()
ctx.setFillColor(rgb(1.0, 0.92, 0.75))
var t: CGFloat = 0.10
while t < 1.0 {
    // dashes grow with perspective: t is the distance from the vanishing point
    let t2 = min(t + 0.07 + t * 0.06, 1.0)
    let y1 = vanish.y - (vanish.y - 100) * t, y2 = vanish.y - (vanish.y - 100) * t2
    let w1 = 4 + 26 * t, w2 = 4 + 26 * t2
    ctx.move(to: CGPoint(x: 512 - w1 / 2, y: y1))
    ctx.addLine(to: CGPoint(x: 512 + w1 / 2, y: y1))
    ctx.addLine(to: CGPoint(x: 512 + w2 / 2, y: y2))
    ctx.addLine(to: CGPoint(x: 512 - w2 / 2, y: y2))
    ctx.closePath()
    ctx.fillPath()
    t = t2 + 0.05 + t * 0.08
}

NSGraphicsContext.current = nil
try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: out))
