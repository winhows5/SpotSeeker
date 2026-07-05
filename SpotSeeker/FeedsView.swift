import SwiftUI
import UIKit

struct FeedItem: Identifiable {
    let id = UUID()
    let author: String
    let avatarSymbol: String
    let text: String
    let images: [UIImage]
    let date: Date
    let tags: [String]
    let location: String
}

struct FeedsView: View {
    @State private var items: [FeedItem] = []
    @State private var selectedTag: String?
    @State private var showSearch = false
    @State private var searchQuery: String = ""
    private let allTags = ["all","nearby","travel","college","movie"]

    init() {
        _items = State(initialValue: FeedsView.buildFeed())
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.12, green: 0.12, blue: 0.16),
                    Color(red: 0.06, green: 0.06, blue: 0.10)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 8) {
                HStack {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(allTags, id: \.self) { tag in
                                Button {
                                    if selectedTag == tag { selectedTag = nil } else { selectedTag = tag }
                                } label: {
                                    Text(tag)
                                        .foregroundColor(.white)
                                        .font(.system(size: 14, weight: .semibold))
                                        .padding(.vertical, 6)
                                        .padding(.horizontal, 12)
                                        .background((selectedTag == tag ? Color.white.opacity(0.25) : Color.white.opacity(0.12)))
                                        .cornerRadius(16)
                                }
                            }
                        }
                        .padding(.horizontal, 12)
                    }
                    Button {
                        showSearch = true
                    } label: {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.white)
                            .frame(width: 36, height: 36)
                    }
                    .padding(.trailing, 12)
                }
                ScrollView {
                    let columns = [GridItem(.flexible()), GridItem(.flexible())]
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(filtered(items)) { item in
                            NavigationLink(destination: PostGalleryView(images: item.images, text: item.text, showForward: true)) {
                                VStack(alignment: .leading, spacing: 8) {
                                    FeedCover(image: item.images.first)
                                    HStack(spacing: 8) {
                                        Image(systemName: item.avatarSymbol)
                                            .foregroundColor(.white.opacity(0.7))
                                        Text(item.author)
                                            .foregroundColor(.white.opacity(0.7))
                                            .font(.system(size: 14, weight: .semibold))
                                    }
                                    Text(item.text)
                                        .foregroundColor(.white.opacity(0.95))
                                        .font(.system(size: 14))
                                        .lineLimit(2)
                                }
                            }
                        }
                    }
                    .padding(12)
                }
            }
        }
        .navigationTitle("发现")
        .sheet(isPresented: $showSearch) {
            SearchSheet(query: $searchQuery, onClose: { showSearch = false })
        }
    }

    static func buildFeed() -> [FeedItem] {
        var out: [FeedItem] = []
        let meUser = UsersStore.currentUser()
        let me = PostsStore.loadPosts().map { p in
            FeedItem(author: meUser.nickname, avatarSymbol: meUser.avatarSymbol, text: p.text, images: p.images, date: p.date, tags: inferTags(text: p.text), location: p.location)
        }
        out.append(contentsOf: me)
        let imgs = demoImages(limit: 9)
        let a1 = Array(imgs.prefix(3))
        let a2 = Array(imgs.dropFirst(3).prefix(3))
        let a3 = Array(imgs.dropFirst(6).prefix(3))
        let others = UsersStore.loadUsers().filter { $0.id != UsersStore.currentUserId() }
        if let li = others.first(where: { $0.id == "u_li" }) {
            out.append(FeedItem(author: li.nickname, avatarSymbol: li.avatarSymbol, text: "北京周末随拍", images: a1, date: Date().addingTimeInterval(-7200), tags: ["nearby"], location: "北京"))
            out.append(FeedItem(author: li.nickname, avatarSymbol: li.avatarSymbol, text: "美食记录", images: a2, date: Date().addingTimeInterval(-10800), tags: [], location: "北京"))
            out.append(FeedItem(author: li.nickname, avatarSymbol: li.avatarSymbol, text: "夜景", images: a3, date: Date().addingTimeInterval(-14400), tags: ["nearby"], location: "北京"))
        }
        if let zhao = others.first(where: { $0.id == "u_zhao" }) {
            out.append(FeedItem(author: zhao.nickname, avatarSymbol: zhao.avatarSymbol, text: "旅行图集", images: a1, date: Date().addingTimeInterval(-3600), tags: ["travel"], location: "上海"))
            out.append(FeedItem(author: zhao.nickname, avatarSymbol: zhao.avatarSymbol, text: "模板试拍", images: a2, date: Date().addingTimeInterval(-5400), tags: [], location: "上海"))
            out.append(FeedItem(author: zhao.nickname, avatarSymbol: zhao.avatarSymbol, text: "夜色街头", images: a3, date: Date().addingTimeInterval(-7200), tags: ["nearby"], location: "上海"))
        }
        return out
    }

    static func demoImages(limit: Int) -> [UIImage] {
        var out: [UIImage] = []
        let exts = ["jpg","jpeg","png","heic"]
        for ext in exts {
            if let urls = Bundle.main.urls(forResourcesWithExtension: ext, subdirectory: "ImageSeries/DemoSeries") {
                for u in urls {
                    if let d = try? Data(contentsOf: u), let img = UIImage(data: d) {
                        out.append(img)
                        if out.count >= limit { return out }
                    }
                }
            }
        }
        return out
    }

    func filtered(_ base: [FeedItem]) -> [FeedItem] {
        let baseList: [FeedItem]
        if let t = selectedTag, t != "all" {
            baseList = base.filter { $0.tags.contains(t) }
        } else {
            baseList = base
        }
        let searched = searchQuery.isEmpty
            ? baseList
            : baseList.filter {
                $0.text.localizedCaseInsensitiveContains(searchQuery)
                || $0.author.localizedCaseInsensitiveContains(searchQuery)
                || $0.location.localizedCaseInsensitiveContains(searchQuery)
            }
        return searched.sorted { $0.date > $1.date }
    }

    static func inferTags(text: String) -> [String] {
        var tags: [String] = []
        if text.localizedCaseInsensitiveContains("旅行") || text.localizedCaseInsensitiveContains("travel") { tags.append("travel") }
        if text.localizedCaseInsensitiveContains("大学") || text.localizedCaseInsensitiveContains("校园") || text.localizedCaseInsensitiveContains("college") { tags.append("college") }
        if text.localizedCaseInsensitiveContains("电影") || text.localizedCaseInsensitiveContains("movie") { tags.append("movie") }
        if text.localizedCaseInsensitiveContains("北京") || text.localizedCaseInsensitiveContains("周末") || text.localizedCaseInsensitiveContains("夜景") || text.localizedCaseInsensitiveContains("夜色") || text.localizedCaseInsensitiveContains("nearby") { tags.append("nearby") }
        return tags
    }
}

struct SearchSheet: View {
    @Binding var query: String
    var onClose: () -> Void

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                TextField("搜索", text: $query)
                    .padding(14)
                    .background(Color.white.opacity(0.12))
                    .cornerRadius(10)
                    .foregroundColor(.white)
                Spacer()
            }
            .padding(16)
            .background(
                LinearGradient(
                    colors: [
                        Color(red: 0.12, green: 0.12, blue: 0.16),
                        Color(red: 0.06, green: 0.06, blue: 0.10)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
            )
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") { onClose() }
                        .foregroundColor(.white)
                }
            }
        }
    }
}

struct FeedCover: View {
    let image: UIImage?
    var body: some View {
        GeometryReader { proxy in
            ZStack {
                if let image = image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: proxy.size.width, height: 200)
                        .clipped()
                } else {
                    Rectangle()
                        .fill(Color.white.opacity(0.08))
                        .frame(width: proxy.size.width, height: 200)
                }
            }
        }
        .frame(height: 200)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

struct PostGalleryView: View {
    let images: [UIImage]
    let text: String
    var onDelete: (() -> Void)?
    var showForward: Bool = false
    @Environment(\.dismiss) private var dismiss
    @State private var index: Int = 0
    @State private var showShare = false
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            TabView(selection: $index) {
                ForEach(Array(images.enumerated()), id: \.offset) { i, img in
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFit()
                        .tag(i)
                        .background(Color.black)
                        .ignoresSafeArea()
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .automatic))
            .padding(.bottom, 80)
            VStack {
                Spacer()
                Text(text)
                    .foregroundColor(.white)
                    .font(.system(size: 16))
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.black.opacity(0.45))
            }
            .padding(.bottom, 80)
            .ignoresSafeArea(edges: .bottom)
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Group {
                    if showForward {
                        Button("Forward") { showShare = true }
                            .foregroundColor(.white)
                    } else if let onDelete = onDelete {
                        Button("Delete") {
                            onDelete()
                            dismiss()
                        }
                        .foregroundColor(.red)
                    }
                }
            }
        }
        .sheet(isPresented: $showShare) {
            ActivityView(items: shareItems())
        }
    }
    private func shareItems() -> [Any] {
        var items: [Any] = []
        if images.indices.contains(index) {
            items.append(images[index])
        }
        if !text.isEmpty {
            items.append(text)
        }
        return items
    }
}

struct ActivityView: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
