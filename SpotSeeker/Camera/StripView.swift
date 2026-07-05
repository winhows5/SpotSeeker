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

struct RasterOverlayView: View {
    let assetName: String

    private func persistedImageURL(for assetName: String) -> URL? {
        let fm = FileManager.default
        guard let appSupportURL = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else { return nil }
        for ext in ["jpg","jpeg","png","heic"] {
            let u = appSupportURL.appendingPathComponent("ImageSeries/DemoSeries/\(assetName).\(ext)")
            if fm.fileExists(atPath: u.path) { return u }
        }
        return nil
    }

    private func bundledImageURL(for assetName: String) -> URL? {
        for ext in ["jpg","jpeg","png","heic"] {
            if let u = Bundle.main.url(forResource: assetName, withExtension: ext, subdirectory: "ImageSeries/DemoSeries") { return u }
        }
        return nil
    }

    private func resolvedImage() -> UIImage? {
        if let u = persistedImageURL(for: assetName), let d = try? Data(contentsOf: u), let img = UIImage(data: d) {
            print("[TemplateImage] Using persisted: \(u.path)")
            return img
        }
        if let u = bundledImageURL(for: assetName), let d = try? Data(contentsOf: u), let img = UIImage(data: d) {
            print("[TemplateImage] Using bundle: \(u.path)")
            return img
        }
        print("[TemplateImage] Missing image for \(assetName)")
        return nil
    }

    var body: some View {
        if let img = resolvedImage() {
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

    private func persistedImageURL(for assetName: String) -> URL? {
        let fm = FileManager.default
        guard let appSupportURL = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else { return nil }
        for ext in ["jpg","jpeg","png","heic"] {
            let u = appSupportURL.appendingPathComponent("ImageSeries/DemoSeries/\(assetName).\(ext)")
            if fm.fileExists(atPath: u.path) { return u }
        }
        return nil
    }

    private func bundledImageURL(for assetName: String) -> URL? {
        for ext in ["jpg","jpeg","png","heic"] {
            if let u = Bundle.main.url(forResource: assetName, withExtension: ext) { return u }
            if let u = Bundle.main.url(forResource: assetName, withExtension: ext, subdirectory: "ImageSeries/DemoSeries") { return u }
        }
        return nil
    }

    private func resolvedImage() -> UIImage? {
        if let u = bundledImageURL(for: assetName), let d = try? Data(contentsOf: u), let img = UIImage(data: d) {
            print("[OverlayImage] Using bundle: \(u.path)")
            return img
        }
        print("[OverlayImage] Missing image for \(assetName)")
        return nil
    }

    var body: some View {
        if let img = resolvedImage() {
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
            let loops = 5
            let middle = loops / 2
            let repeatedCount = loops * items.count

            GeometryReader { containerGeo in
                ScrollView(.horizontal, showsIndicators: false) {
                    let visibleCount = 5
                    let itemDiameter: CGFloat = 52
                    let horizontalPadding: CGFloat = 20
                    let availableWidth = containerGeo.size.width - 2 * horizontalPadding
                    let computedSpacing = max((availableWidth - CGFloat(visibleCount) * itemDiameter) / CGFloat(visibleCount - 1), 0)
                    HStack(spacing: computedSpacing) {
                        ForEach(0..<repeatedCount, id: \.self) { idx in
                            let loop = idx / items.count
                            let item = items[idx % items.count]
                            let key = "\(loop)-\(item.id)"
                            let containerCenter = containerGeo.frame(in: .global).midX
                            let centerX = centers[key] ?? containerCenter
                            let halfWidth = max(containerGeo.size.width / 2, 1)
                            let normalized = min(abs(centerX - containerCenter) / halfWidth, 1)
                            let scale = 1.0 - 0.8 * normalized
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
                            .background(GeometryReader { gp in
                                Color.clear.preference(key: CenterPrefKey.self, value: ["\(loop)-\(item.id)": gp.frame(in: .global).midX])
                            })
                            .id("\(loop)-\(item.id)")
                        }
                    }
                    .padding(.horizontal, horizontalPadding)
                }
                .coordinateSpace(name: "stripSpace")
                .onPreferenceChange(CenterPrefKey.self) { newCenters in
                    centers = newCenters
                    let containerCenter = containerGeo.frame(in: .global).midX
                    if !isDragging, let nearest = centers.min(by: { abs($0.value - containerCenter) < abs($1.value - containerCenter) }) {
                        print("[ShutterCenter] X=\(containerCenter)")
                        print("[CentralImage] X=\(nearest.value)")
                        if lastSnappedKey != nearest.key {
                            withAnimation(.easeInOut) {
                                proxy.scrollTo(nearest.key, anchor: .center)
                            }
                            lastSnappedKey = nearest.key
                            let parts = nearest.key.split(separator: "-")
                            if let idPart = parts.last, let id = Int(idPart), let item = items.first(where: { $0.id == id }) {
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
                            print("[ShutterCenter] X=\(containerCenter)")
                            if let nearest = centers.min(by: { abs($0.value - containerCenter) < abs($1.value - containerCenter) }) {
                                print("[CentralImage] X=\(nearest.value)")
                                let key = nearest.key
                                lastSnappedKey = key
                                withAnimation(.easeInOut) {
                                    proxy.scrollTo(key, anchor: .center)
                                }
                                let parts = key.split(separator: "-")
                                if let idPart = parts.last, let id = Int(idPart), let item = items.first(where: { $0.id == id }) {
                                    onSelect(item)
                                }
                            }
                        }
                )
                .onAppear {
                    if let id = selectedId ?? items.first?.id {
                        let targetId = "\(middle)-\(id)"
                        lastSnappedKey = targetId
                        DispatchQueue.main.async {
                            proxy.scrollTo(targetId, anchor: .center)
                        }
                    }
                }
                .onChange(of: selectedId) { id in
                    if let id = id {
                        let targetId = "\(middle)-\(id)"
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