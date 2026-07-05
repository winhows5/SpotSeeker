import SwiftUI

struct ProfileView: View {
    @AppStorage("isLoggedIn") private var isLoggedIn = false
    @State private var user: UserModel = UsersStore.currentUser()
    @State private var badges: [String] = ["会员"]

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
                HStack(spacing: 16) {
                    Image(systemName: user.avatarSymbol)
                        .font(.system(size: 58))
                        .foregroundColor(.white)
                    VStack(alignment: .leading, spacing: 6) {
                        Text(user.nickname)
                            .foregroundColor(.white)
                            .font(.system(size: 20, weight: .semibold))
                        Text("微信号：\(user.wechatId)")
                            .foregroundColor(.white.opacity(0.75))
                            .font(.system(size: 13))
                        Text(user.region)
                            .foregroundColor(.white.opacity(0.75))
                            .font(.system(size: 13))
                        HStack(spacing: 8) {
                            ForEach(badges, id: \.self) { b in
                                Text(b)
                                    .foregroundColor(.white)
                                    .font(.system(size: 12, weight: .medium))
                                    .padding(.vertical, 4)
                                    .padding(.horizontal, 8)
                                    .background(Color.white.opacity(0.12))
                                    .cornerRadius(6)
                            }
                        }
                    }
                    Spacer()
                    Image(systemName: "qrcode.viewfinder")
                        .foregroundColor(.white.opacity(0.9))
                        .font(.system(size: 22))
                }
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)

                Section {
                    NavigationLink(destination: EmptyView()) {
                        Row(icon: "creditcard", color: .green, title: "支付")
                    }
                    NavigationLink(destination: EmptyView()) {
                        Row(icon: "star", color: .yellow, title: "收藏")
                    }
                    NavigationLink(destination: MomentsView()) {
                        Row(icon: "text.bubble", color: .purple, title: "我的时间线")
                    }
                }
                .listRowBackground(Color.clear)

                Section {
                    NavigationLink(destination: EmptyView()) {
                        Row(icon: "gearshape", color: .gray, title: "设置")
                    }
                }
                .listRowBackground(Color.clear)
                
                Section {
                    HStack {
                        Spacer()
                        Button("EXIT LOGIN") {
                            isLoggedIn = false
                        }
                        .foregroundColor(.red)
                        .font(.system(size: 16, weight: .semibold))
                        Spacer()
                    }
                }
                .listRowBackground(Color.clear)
            }
            .scrollContentBackground(.hidden)
            .listStyle(.insetGrouped)
        }
    }
}

private struct Row: View {
    let icon: String
    let color: Color
    let title: String

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .fill(color.opacity(0.18))
                    .frame(width: 34, height: 34)
                Image(systemName: icon)
                    .foregroundColor(.white)
            }
            Text(title)
                .foregroundColor(.white)
                .font(.system(size: 16, weight: .regular))
            Spacer()
        }
        .listRowBackground(Color.clear)
        .listRowSeparator(.visible)
    }
}
