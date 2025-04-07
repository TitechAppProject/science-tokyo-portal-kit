import Foundation

public struct ScienceTokyoPortalAccount {
    let username: String
    let password: String
    let totpSecret: String?

    public init(username: String, password: String, totpSecret: String?) {
        self.username = username
        self.password = password
        self.totpSecret = totpSecret
    }
}
