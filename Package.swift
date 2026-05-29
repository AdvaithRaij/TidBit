// swift-tools-version: 6.1
import PackageDescription

let package = Package(
    name: "TopbarTodo",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "TopbarTodo", targets: ["TopbarTodo"])
    ],
    targets: [
        .executableTarget(
            name: "TopbarTodo",
            path: "Sources"
        )
    ]
)
