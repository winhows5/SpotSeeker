import SwiftUI
import UIKit
import Foundation

struct TemplateItem: Identifiable {
    let id: Int
    let name: String
    let assetName: String
}

extension TemplateItem {
    static func loadAvailableTemplates() -> [TemplateItem] {
        var set = Set<String>()
        for ext in ["jpg","jpeg","png","heic"] {
            if let urls = Bundle.main.urls(forResourcesWithExtension: ext, subdirectory: "ImageSeries/DemoSeries") {
                for u in urls { set.insert(u.deletingPathExtension().lastPathComponent) }
            }
        }
        let names = Array(set).sorted()
        return names.enumerated().map { TemplateItem(id: $0.offset, name: $0.element, assetName: $0.element) }
    }
}

// In-memory cache for template images. Strip items re-render on every scroll
// tick, so they must never hit the disk or decode a full-size photo in body.
enum TemplateImageCache {
    private static let cache = NSCache<NSString, UIImage>()

    // Small decoded version for strip circles and the shutter (max 240px ≈ 80pt @3x)
    static func thumbnail(named assetName: String) -> UIImage? {
        image(named: assetName, maxDimension: 240, keyPrefix: "thumb")
    }

    // Full-size version for the fullscreen alignment overlay
    static func full(named assetName: String) -> UIImage? {
        image(named: assetName, maxDimension: nil, keyPrefix: "full")
    }

    private static func image(named assetName: String, maxDimension: CGFloat?, keyPrefix: String) -> UIImage? {
        let key = "\(keyPrefix):\(assetName)" as NSString
        if let cached = cache.object(forKey: key) { return cached }
        guard let url = resolveURL(for: assetName),
              let data = try? Data(contentsOf: url),
              var image = UIImage(data: data) else { return nil }
        if let maxDimension = maxDimension {
            image = downscaled(image, maxDimension: maxDimension)
        }
        cache.setObject(image, forKey: key)
        return image
    }

    private static func resolveURL(for assetName: String) -> URL? {
        let fm = FileManager.default
        if let appSupportURL = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
            for ext in ["jpg", "jpeg", "png", "heic"] {
                let u = appSupportURL.appendingPathComponent("ImageSeries/DemoSeries/\(assetName).\(ext)")
                if fm.fileExists(atPath: u.path) { return u }
            }
        }
        for ext in ["jpg", "jpeg", "png", "heic"] {
            if let u = Bundle.main.url(forResource: assetName, withExtension: ext, subdirectory: "ImageSeries/DemoSeries") { return u }
            if let u = Bundle.main.url(forResource: assetName, withExtension: ext) { return u }
        }
        return nil
    }

    private static func downscaled(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        let maxSide = max(image.size.width, image.size.height)
        guard maxSide > maxDimension else { return image }
        let ratio = maxDimension / maxSide
        let target = CGSize(width: image.size.width * ratio, height: image.size.height * ratio)
        return UIGraphicsImageRenderer(size: target).image { _ in
            image.draw(in: CGRect(origin: .zero, size: target))
        }
    }
}

struct RasterOverlayView: View {
    let assetName: String

    var body: some View {
        if let img = TemplateImageCache.full(named: assetName) {
            Image(uiImage: img)
                .resizable()
                .scaledToFit()
        } else {
            Color.clear
        }
    }
}

struct RasterTemplateView: View {
    let assetName: String

    var body: some View {
        if let img = TemplateImageCache.thumbnail(named: assetName) {
            Image(uiImage: img)
                .resizable()
                .scaledToFit()
        } else {
            Color.clear
        }
    }
}

struct TemplateStrip: View {
    let items: [TemplateItem]
    let selectedId: Int?
    let onSelect: (TemplateItem) -> Void

    struct CenterPrefKey: PreferenceKey {
        static var defaultValue: [String: CGFloat] = [:]
        static func reduce(value: inout [String: CGFloat], nextValue: () -> [String: CGFloat]) {
            value.merge(nextValue(), uniquingKeysWith: { $1 })
        }
    }
    @State private var centers: [String: CGFloat] = [:]
    @GestureState private var isDragging = false
    @State private var lastSnappedKey: String? = nil

    var body: some View {
        ScrollViewReader { proxy in
            GeometryReader { containerGeo in
                ScrollView(.horizontal, showsIndicators: false) {
                    let visibleCount = 5
                    let itemDiameter: CGFloat = 52
                    let spacingReference: CGFloat = 12
                    // The centered shutter (80pt) is wider than a strip item (52pt), so an
                    // evenly spaced strip looks crowded around it. Push items outward from
                    // the center: no push for the selected item (hidden behind the shutter)
                    // and at the edges, strongest for the shutter's direct neighbors.
                    let spreadFactor: CGFloat = 100
                    let availableWidth = containerGeo.size.width - 2 * spacingReference
                    let computedSpacing = max((availableWidth - CGFloat(visibleCount) * itemDiameter) / CGFloat(visibleCount - 1), 0)
                    // Half-width end insets let the first/last item scroll to the center
                    // (behind the shutter); the empty space beyond them marks the end of the strip.
                    let endInset = max(containerGeo.size.width / 2 - itemDiameter / 2, 0)
                    HStack(spacing: computedSpacing) {
                        ForEach(items) { item in
                            let key = "\(item.id)"
                            let containerCenter = containerGeo.frame(in: .global).midX
                            let centerX = centers[key] ?? containerCenter
                            let halfWidth = max(containerGeo.size.width / 2, 1)
                            let signedNorm = max(min((centerX - containerCenter) / halfWidth, 1), -1)
                            let normalized = abs(signedNorm)
                            let scale = 1.0 - 0.5 * normalized
                            let spread = signedNorm * (1 - normalized) * spreadFactor
                            // Fade out approaching the center so the item vanishes behind the
                            // shutter instead of peeking around it: invisible at dead center,
                            // fully opaque beyond a quarter of the half-width
                            let itemOpacity = min(normalized / 0.25, 1)
                            ZStack {
                                RasterTemplateView(assetName: item.assetName)
                                    .scaledToFill()
                                    .frame(width: 52, height: 52)
                                    .clipShape(Circle())
                                    .overlay(
                                        Circle()
                                            .stroke(Color.white.opacity(0.9), lineWidth: 1)
                                    )
                                    .padding(.vertical, 4)
                                    .allowsHitTesting(false)
                            }
                            .scaleEffect(scale)
                            .animation(.easeOut(duration: 0.15), value: scale)
                            .offset(x: spread)
                            .animation(.easeOut(duration: 0.15), value: spread)
                            .opacity(itemOpacity)
                            .animation(.easeOut(duration: 0.15), value: itemOpacity)
                            .background(GeometryReader { gp in
                                Color.clear.preference(key: CenterPrefKey.self, value: [key: gp.frame(in: .global).midX])
                            })
                            .id(key)
                        }
                    }
                    .padding(.horizontal, endInset)
                }
                .coordinateSpace(name: "stripSpace")
                .onPreferenceChange(CenterPrefKey.self) { newCenters in
                    centers = newCenters
                    let containerCenter = containerGeo.frame(in: .global).midX
                    if !isDragging, let nearest = centers.min(by: { abs($0.value - containerCenter) < abs($1.value - containerCenter) }) {
                        if lastSnappedKey != nearest.key {
                            withAnimation(.easeInOut) {
                                proxy.scrollTo(nearest.key, anchor: .center)
                            }
                            lastSnappedKey = nearest.key
                            if let id = Int(nearest.key), let item = items.first(where: { $0.id == id }) {
                                onSelect(item)
                            }
                        }
                    }
                }
                .gesture(
                    DragGesture()
                        .updating($isDragging) { _, state, _ in state = true }
                        .onEnded { _ in
                            let containerCenter = containerGeo.frame(in: .global).midX
                            if let nearest = centers.min(by: { abs($0.value - containerCenter) < abs($1.value - containerCenter) }) {
                                let key = nearest.key
                                lastSnappedKey = key
                                withAnimation(.easeInOut) {
                                    proxy.scrollTo(key, anchor: .center)
                                }
                                if let id = Int(key), let item = items.first(where: { $0.id == id }) {
                                    onSelect(item)
                                }
                            }
                        }
                )
                .onAppear {
                    if let id = selectedId ?? items.first?.id {
                        let targetId = "\(id)"
                        lastSnappedKey = targetId
                        DispatchQueue.main.async {
                            proxy.scrollTo(targetId, anchor: .center)
                        }
                    }
                }
                .onChange(of: selectedId) { id in
                    if let id = id {
                        let targetId = "\(id)"
                        lastSnappedKey = targetId
                        withAnimation(.easeInOut) {
                            proxy.scrollTo(targetId, anchor: .center)
                        }
                    }
                }
            }
        }
    }
}