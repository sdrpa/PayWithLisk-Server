// swift-tools-version:4.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
   name: "App",
   dependencies: [
      .package(url: "https://github.com/IBM-Swift/Kitura.git", from: "2.1.0"),
      .package(url: "https://github.com/sdrpa/Kitura-CORS.git", from: "2.0.1"),
      .package(url: "https://github.com/IBM-Swift/Kitura-WebSocket", from: "1.0.0"),
      .package(url: "https://github.com/IBM-Swift/Kitura-Cache", from: "2.0.0"),
      .package(url: "https://github.com/IBM-Swift/SwiftyJSON", from: "17.0.0"),
      .package(url: "https://github.com/sdrpa/Then", from: "1.0.0")

   ],
   targets: [
      .target(
         name: "Server",
         dependencies: [
            "Kitura",
            "Kitura-WebSocket",
            "KituraCache",
            "KituraCORS",
            "SwiftyJSON",
            "Then"
         ]),
      .testTarget(
         name: "ServerTests",
         dependencies: ["Server"]),
      .target(
         name: "App",
         dependencies: ["Server"])
      ]
)
