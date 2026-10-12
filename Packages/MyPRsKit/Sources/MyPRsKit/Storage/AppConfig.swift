import Foundation

public enum AppConfig {
    static let appGroupID = "688YYDN5Z4.com.zaintech.myprs"
    public static let widgetKind = "MyPRsWidget"
    public static let urlScheme = "myprs"
    public static let gitHubClientID = "Ov23li7Ghr091fkSv2eG"
    public static let organizationAccessURL = URL(string: "https://github.com/settings/connections/applications/\(gitHubClientID)")!
    public static let authCallbackURL = "https://myprs-auth.zaintech.com.br/callback"
}
