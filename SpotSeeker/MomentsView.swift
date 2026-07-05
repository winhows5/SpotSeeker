import SwiftUI
import UIKit

struct Post: Identifiable {
    let id = UUID()
    var images: [UIImage]
    var text: String
    var date: Date
    var location: String
    var manifestId: String?
}

struct MomentsView: View {
    @State private var posts: [Post]
    @State private var showComposer = false
    @State private var composeText = ""
    @State private var composeImages: [UIImage] = []
    @State private var showImagePicker = false
    @State private var composeLocation: String = ""

    init() {
        _posts = State(initialValue: PostsStore.loadPosts())
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

            List {
                Section {
                    Button {
                        showComposer = true
                    } label: {
                        HStack {
                            Spacer()
                            Text("发动态")
                                .foregroundColor(.white)
                                .font(.system(size: 16, weight: .semibold))
                            Spacer()
                        }
                    }
                }
                .listRowBackground(Color.clear)

                ForEach(posts) { post in
                    NavigationLink(destination:
                        PostGalleryView(
                            images: post.images,
                            text: post.text,
                            onDelete: post.manifestId.map { id in
                                { 
                                    PostsStore.deletePost(manifestId: id)
                                    posts.removeAll { $0.manifestId == id }
                                }
                            }
                        )
                    ) {
                        VStack(alignment: .leading, spacing: 8) {
                            if !post.text.isEmpty {
                                Text(post.text)
                                    .foregroundColor(.white)
                                    .font(.system(size: 16))
                            }
                            HStack(alignment: .top, spacing: 12) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(post.location.isEmpty ? "未知" : post.location)
                                        .foregroundColor(.white.opacity(0.8))
                                        .font(.system(size: 12))
                                    Text(Self.format(date: post.date))
                                        .foregroundColor(.white.opacity(0.7))
                                        .font(.system(size: 12))
                                }
                                .frame(width: 100, alignment: .leading)
                                if !post.images.isEmpty {
                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack(spacing: 4) {
                                            ForEach(Array(post.images.enumerated()), id: \.offset) { _, img in
                                                Image(uiImage: img)
                                                    .resizable()
                                                    .scaledToFill()
                                                    .frame(width: 90, height: 80)
                                                    .clipped()
                                                    .cornerRadius(6)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.vertical, 6)
                    }
                    .listRowBackground(Color.clear)
                }
            }
            .scrollContentBackground(.hidden)
            .listStyle(.plain)
        }
        .navigationTitle("动态")
        .sheet(isPresented: $showComposer) {
            ComposePostView(
                text: $composeText,
                images: $composeImages,
                location: $composeLocation,
                onPublish: {
                    guard !composeText.isEmpty || !composeImages.isEmpty else { return }
                    let p = PostsStore.savePost(text: composeText, images: composeImages, date: Date(), location: composeLocation)
                    posts.insert(p, at: 0)
                    composeText = ""
                    composeImages = []
                    composeLocation = ""
                    showComposer = false
                },
                onCancel: {
                    composeText = ""
                    composeImages = []
                    composeLocation = ""
                    showComposer = false
                }
            )
        }
    }

    static func format(date: Date) -> String {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .none
        return f.string(from: date)
    }

    
}

struct ComposePostView: View {
    @Binding var text: String
    @Binding var images: [UIImage]
    @Binding var location: String
    var onPublish: () -> Void
    var onCancel: () -> Void
    @State private var showPicker = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                TextEditor(text: $text)
                    .frame(height: 140)
                    .padding(12)
                    .background(Color.white.opacity(0.08))
                    .cornerRadius(10)
                    .foregroundColor(.white)

                TextField("位置", text: $location)
                    .padding(12)
                    .background(Color.white.opacity(0.08))
                    .cornerRadius(10)
                    .foregroundColor(.white)

                Button {
                    showPicker = true
                } label: {
                    Text("选择图片")
                        .foregroundColor(.white)
                        .font(.system(size: 16, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.white.opacity(0.18))
                        .cornerRadius(10)
                }

                if !images.isEmpty {
                    let columns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]
                    LazyVGrid(columns: columns, spacing: 6) {
                        ForEach(Array(images.enumerated()), id: \.offset) { _, img in
                            Image(uiImage: img)
                                .resizable()
                                .scaledToFill()
                                .frame(height: 100)
                                .clipped()
                                .cornerRadius(6)
                        }
                    }
                }

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
            .navigationTitle("发布动态")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") { onCancel() }
                        .foregroundColor(.white)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("发布") { onPublish() }
                        .foregroundColor(.white)
                }
            }
        }
        .sheet(isPresented: $showPicker) {
            MultiPhotoPicker(selectedImages: $images, selectionLimit: 9)
        }
    }
}
