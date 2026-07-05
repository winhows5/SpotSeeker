import SwiftUI

struct ImageSeriesView: View {
    @Environment(\.dismiss) private var dismiss
    private var demoItems: [TemplateItem] { TemplateItem.loadAvailableTemplates() }

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
                NavigationLink(destination: DemoSeriesAlbumView(items: demoItems)) {
                    HStack(spacing: 12) {
                        Image(systemName: "photo")
                            .foregroundColor(.white)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("DemoSeries")
                                .foregroundColor(.white)
                                .font(.system(size: 18, weight: .semibold))
                            Text("\(demoItems.count) images")
                                .foregroundColor(.white.opacity(0.7))
                                .font(.system(size: 13))
                        }
                        Spacer()
                    }
                }
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            }
            .scrollContentBackground(.hidden)
            .listStyle(.plain)
        }
        .navigationTitle("Image Series")
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .foregroundColor(.white)
                }
            }
        }
    }

    
}

struct DemoSeriesAlbumView: View {
    let items: [TemplateItem]
    private let columns: [GridItem] = Array(repeating: GridItem(.flexible(), spacing: 12), count: 3)

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

            ScrollView {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(items) { item in
                        RasterTemplateView(assetName: item.assetName)
                            .scaledToFill()
                            .frame(height: 100)
                            .clipped()
                            .cornerRadius(8)
                    }
                }
                .padding(16)
            }
        }
        .navigationTitle("DemoSeries")
    }
}
