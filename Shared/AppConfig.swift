import Foundation

enum AppConfig {
    static let appGroupID = "688YYDN5Z4.com.zaintech.myprs"
    static let widgetKind = "MyPRsWidget"
    static let urlScheme = "myprs"
    static let gitHubClientID = "Ov23li7Ghr091fkSv2eG"
    static let organizationAccessURL = URL(string: "https://github.com/settings/connections/applications/\(gitHubClientID)")!
    static let authCallbackURL = "https://myprs-auth.zaintech.com.br/callback"
}
