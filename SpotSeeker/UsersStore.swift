import Foundation

struct UserModel: Codable, Identifiable {
    let id: String
    var nickname: String
    var wechatId: String
    var region: String
    var avatarSymbol: String
}

enum UsersStore {
    static func appSupportDir() -> URL? {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
    }

    static func usersDir() -> URL? {
        appSupportDir()?.appendingPathComponent("Users", isDirectory: true)
    }

    static func usersURL() -> URL? {
        usersDir()?.appendingPathComponent("users.json")
    }

    static func ensureDir() {
        if let dir = usersDir() {
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true, attributes: nil)
        }
    }

    static func loadUsers() -> [UserModel] {
        ensureDir()
        guard let url = usersURL(), let data = try? Data(contentsOf: url) else {
            let seed = seedUsers()
            saveUsers(seed)
            return seed
        }
        if let users = try? JSONDecoder().decode([UserModel].self, from: data) {
            return users
        }
        let seed = seedUsers()
        saveUsers(seed)
        return seed
    }

    static func saveUsers(_ users: [UserModel]) {
        ensureDir()
        guard let url = usersURL() else { return }
        if let data = try? JSONEncoder().encode(users) {
            try? data.write(to: url, options: .atomic)
        }
    }

    static func currentUserId() -> String {
        UserDefaults.standard.string(forKey: "currentUserId") ?? "me"
    }

    static func setCurrentUserId(_ id: String) {
        UserDefaults.standard.set(id, forKey: "currentUserId")
    }

    static func currentUser() -> UserModel {
        let users = loadUsers()
        if let u = users.first(where: { $0.id == currentUserId() }) {
            return u
        }
        return users.first(where: { $0.id == "me" }) ?? seedUsers().first!
    }

    static func updateCurrentUser(_ user: UserModel) {
        var users = loadUsers()
        if let idx = users.firstIndex(where: { $0.id == user.id }) {
            users[idx] = user
        } else {
            users.append(user)
        }
        saveUsers(users)
        setCurrentUserId(user.id)
    }

    static func seedUsers() -> [UserModel] {
        return [
            UserModel(id: "me", nickname: "鱼不卡", wechatId: "wenhao", region: "中国 · 北京", avatarSymbol: "person.circle"),
            UserModel(id: "u_li", nickname: "小李", wechatId: "xiao_li", region: "中国 · 北京", avatarSymbol: "person.crop.circle"),
            UserModel(id: "u_zhao", nickname: "小赵", wechatId: "xiao_zhao", region: "中国 · 上海", avatarSymbol: "person.crop.circle")
        ]
    }
}
