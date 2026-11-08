import Foundation
import MementiCore

var totalTests = 0
var passedTests = 0

func assertTest(_ condition: Bool, _ name: String) {
    totalTests += 1
    if condition {
        passedTests += 1
        print("  ✅ [PASS] \(name)")
    } else {
        print("  ❌ [FAIL] \(name)")
        exit(1)
    }
}

print("========================================")
print("🚀 Running Mementi Automated Test Suite")
print("========================================")

let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent("mementi_test_\(UUID().uuidString)", isDirectory: true)
try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)

defer {
    try? FileManager.default.removeItem(at: tempDir)
}

// TEST 1: Expiration Lifecycle (3-Day Retention)
print("\n[Group 1: Expiration Lifecycle (3 Days)]")
let now = Date()
let freshItem = ClipItem(content: "Fresh text", createdAt: now)
assertTest(!freshItem.isExpired, "Fresh clip is not expired")
assertTest(freshItem.remainingTimeText.contains("d") || freshItem.remainingTimeText.contains("h"), "Fresh clip shows countdown (e.g. 2d 23h left)")

let twoDaysOld = now.addingTimeInterval(-2 * 24 * 3600)
let item2d = ClipItem(content: "2 days old", createdAt: twoDaysOld)
assertTest(!item2d.isExpired, "Clip at 2 days is still alive")

let seventyThreeHoursOld = now.addingTimeInterval(-73 * 3600)
let expiredItem = ClipItem(content: "Older than 3 days", createdAt: seventyThreeHoursOld, isHighlighted: false)
assertTest(expiredItem.isExpired, "Clip older than 3 days (73 hours) is marked expired")

// TEST 2: Yellow Highlight (Long Memory) Immunity
print("\n[Group 2: Yellow Highlight & Long Memory]")
let thirtyDaysOld = now.addingTimeInterval(-30 * 24 * 3600)
let highlightedLongMemory = ClipItem(
    content: "Permanent code snippet",
    createdAt: thirtyDaysOld,
    isHighlighted: true,
    highlightedAt: thirtyDaysOld
)
assertTest(!highlightedLongMemory.isExpired, "Yellow highlighted item NEVER expires even after 30 days")
assertTest(highlightedLongMemory.remainingTimeText == "Long Memory", "Remaining time text displays 'Long Memory'")

// TEST 3: StorageManager Integration
print("\n[Group 3: StorageManager & Pruning Behavior]")
let testStorageFile = tempDir.appendingPathComponent("clips.json")
let storage = StorageManager(customURL: testStorageFile)

let clip1 = storage.addClip(content: "Temporary Item 1")!
let clip2 = storage.addClip(content: "Highlighted Item 2 (Long Memory)")!
let clip3 = storage.addClip(content: "Temporary Item 3")!

assertTest(storage.clips.count == 3, "Added 3 clips successfully")

// Highlight clip2 with mouse action
storage.toggleHighlight(id: clip2.id)
assertTest(storage.clips.first(where: { $0.id == clip2.id })?.isHighlighted == true, "Clip 2 toggled to highlighted (yellow / Long Memory)")

// Simulate passage of 5 days for temporary clip 1 and clip 3, and 10 days for highlighted clip 2
let fiveDaysAgo = now.addingTimeInterval(-5 * 24 * 3600)
let tenDaysAgo = now.addingTimeInterval(-10 * 24 * 3600)

var simulatedClips = storage.clips
if let i1 = simulatedClips.firstIndex(where: { $0.id == clip1.id }) {
    simulatedClips[i1] = ClipItem(id: clip1.id, content: clip1.content, createdAt: fiveDaysAgo, isHighlighted: false)
}
if let i2 = simulatedClips.firstIndex(where: { $0.id == clip2.id }) {
    simulatedClips[i2] = ClipItem(id: clip2.id, content: clip2.content, createdAt: tenDaysAgo, isHighlighted: true)
}
if let i3 = simulatedClips.firstIndex(where: { $0.id == clip3.id }) {
    simulatedClips[i3] = ClipItem(id: clip3.id, content: clip3.content, createdAt: fiveDaysAgo, isHighlighted: false)
}

let encoder = JSONEncoder()
encoder.outputFormatting = .prettyPrinted
let encodedData = try! encoder.encode(simulatedClips)
try! encodedData.write(to: testStorageFile)

// Reload storage from disk to trigger auto-prune
let reloadedStorage = StorageManager(customURL: testStorageFile)

assertTest(reloadedStorage.clips.count == 1, "Storage pruned expired 3-day clips, leaving only 1 clip")
assertTest(reloadedStorage.clips.first?.id == clip2.id, "The surviving clip is the yellow-highlighted Long Memory item")
assertTest(reloadedStorage.clips.first?.isHighlighted == true, "Surviving clip preserved isHighlighted = true")

// TEST 4: Clear Temporary Clips
print("\n[Group 4: Clear Temporary Clips (Preserving Long Memory)]")
_ = reloadedStorage.addClip(content: "New Temp A")
_ = reloadedStorage.addClip(content: "New Temp B")
assertTest(reloadedStorage.clips.count == 3, "Added 2 new temporary clips alongside Long Memory item")

reloadedStorage.clearTemporaryClips()
assertTest(reloadedStorage.clips.count == 1, "Cleared temporary clips leaving exactly 1 item")
assertTest(reloadedStorage.clips.first?.id == clip2.id, "Long Memory item remained intact after temporary clear")

print("\n========================================")
print("🎉 All \(passedTests)/\(totalTests) tests passed successfully!")
print("========================================\n")
