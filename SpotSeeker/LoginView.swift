import SwiftUI

struct LoginView: View {
    @AppStorage("isLoggedIn") private var isLoggedIn = false
    @State private var phoneOrId = ""
    @State private var password = ""
    @State private var showError = false

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

            VStack(spacing: 20) {
                Image(systemName: "person.crop.circle.fill")
                    .font(.system(size: 80, weight: .regular))
                    .foregroundColor(.white.opacity(0.9))

                VStack(spacing: 14) {
                    TextField("手机号 / WeChat ID", text: $phoneOrId)
                        .padding(14)
                        .background(Color.white.opacity(0.12))
                        .cornerRadius(10)
                        .foregroundColor(.white)
                        .keyboardType(.default)

                    SecureField("密码", text: $password)
                        .padding(14)
                        .background(Color.white.opacity(0.12))
                        .cornerRadius(10)
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 24)

                Button {
                    if phoneOrId.isEmpty || password.isEmpty {
                        showError = true
                    } else {
                        isLoggedIn = true
                    }
                } label: {
                    Text("登录")
                        .foregroundColor(.white)
                        .font(.system(size: 18, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.white.opacity(0.18))
                        .cornerRadius(12)
                        .padding(.horizontal, 24)
                }

                if showError {
                    Text("请输入有效的账号与密码")
                        .foregroundColor(.white.opacity(0.8))
                        .font(.system(size: 14))
                }

                Spacer()
            }
            .padding(.top, 80)
        }
    }
}
