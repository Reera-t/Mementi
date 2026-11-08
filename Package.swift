// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Mementi",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "Mementi",
            targets: ["MementiApp"]
        ),
        .executable(
            name: "MementiTestRunner",
            targets: ["MementiTestRunner"]
        )
    ],
    dependencies: [],
    targets: [
        .target(
            name: "MementiCore",
            dependencies: [],
            path: "Sources/MementiCore"
        ),
        .executableTarget(
            name: "MementiApp",
            dependencies: ["MementiCore"],
            path: "Sources/MementiApp"
        ),
        .executableTarget(
            name: "MementiTestRunner",
            dependencies: ["MementiCore"],
            path: "Sources/MementiTestRunner"
        )
    ]
)
