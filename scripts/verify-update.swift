import CryptoKit
import Foundation

func fail(_ message: String) -> Never {
    FileHandle.standardError.write(Data((message + "\n").utf8))
    exit(1)
}

guard CommandLine.arguments.count == 4 else {
    fail("Usage: swift verify-update.swift <app Info.plist> <appcast.xml> <DMG>")
}
let plist = try Data(contentsOf: URL(fileURLWithPath: CommandLine.arguments[1]))
let info = try PropertyListSerialization.propertyList(from: plist, format: nil) as? [String: Any]
guard let key = info?["SUPublicEDKey"] as? String, let keyBytes = Data(base64Encoded: key) else {
    fail("Missing Sparkle public key in the built app.")
}
let feed = try XMLDocument(contentsOf: URL(fileURLWithPath: CommandLine.arguments[2]), options: [.nodeLoadExternalEntitiesNever])
let enclosures = try feed.nodes(forXPath: "/rss/channel/item/enclosure")
let namespace = "http://www.andymatuschak.org/xml-namespaces/sparkle"
guard enclosures.count == 1, let enclosure = enclosures.first as? XMLElement,
      let encoded = enclosure.attribute(forLocalName: "edSignature", uri: namespace)?.stringValue,
      let signature = Data(base64Encoded: encoded) else {
    fail("Missing Sparkle signature for the download in the appcast.")
}
let dmg = try Data(contentsOf: URL(fileURLWithPath: CommandLine.arguments[3]), options: .mappedIfSafe)
let publicKey = try Curve25519.Signing.PublicKey(rawRepresentation: keyBytes)
guard enclosure.attribute(forName: "length")?.stringValue == String(dmg.count),
      publicKey.isValidSignature(signature, for: dmg) else {
    fail("The download in the appcast does not match the app's Sparkle key or the expected size.")
}
