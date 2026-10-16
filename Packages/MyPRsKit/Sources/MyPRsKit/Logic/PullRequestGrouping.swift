import Foundation

public enum PullRequestGrouping {
    public static func groups<Item: GroupablePullRequest>(_ items: [Item]) -> [PullRequestGroup<Item>] {
        var uniqueItems: [Item] = []
        var itemByID: [String: Item] = [:]
        for item in items where !item.id.isEmpty && itemByID[item.id] == nil {
            itemByID[item.id] = item
            uniqueItems.append(item)
        }

        let childrenByHead = Dictionary(grouping: uniqueItems.compactMap { item -> (BranchKey, Item)? in
            guard let repository = normalizedRepository(item.headRepository), !item.headBranch.isEmpty else { return nil }
            return (BranchKey(repository: repository, branch: item.headBranch), item)
        }, by: \.0)

        var parentByChild: [String: String] = [:]
        for child in uniqueItems {
            guard !child.baseBranch.isEmpty, let repository = normalizedRepository(child.repository) else { continue }
            let candidates = (childrenByHead[BranchKey(repository: repository, branch: child.baseBranch)]?.map(\.1) ?? [])
                .filter { $0.id != child.id }
            guard candidates.count == 1, let parent = candidates.first else { continue }
            parentByChild[child.id] = parent.id
        }

        let cyclicIDs = cycleMembers(in: parentByChild)
        parentByChild = parentByChild.filter { !cyclicIDs.contains($0.key) && !cyclicIDs.contains($0.value) }

        var childrenByParent: [String: [String]] = [:]
        for (child, parent) in parentByChild { childrenByParent[parent, default: []].append(child) }

        let roots = uniqueItems.filter { parentByChild[$0.id] == nil }
        let built = roots.map { root -> PullRequestGroup<Item> in
            var descendantIDs: [String] = []
            var stack = [root.id]
            while let current = stack.popLast() {
                descendantIDs.append(current)
                stack.append(contentsOf: childrenByParent[current] ?? [])
            }
            let groupItems = descendantIDs.compactMap { itemByID[$0] }.sorted { lhs, rhs in
                if lhs.createdAt != rhs.createdAt { return lhs.createdAt > rhs.createdAt }
                return lhs.id < rhs.id
            }
            var parents: [String: Int] = [:]
            for id in descendantIDs {
                guard let parentID = parentByChild[id], let parent = itemByID[parentID] else { continue }
                parents[id] = parent.number
            }
            return PullRequestGroup(
                id: root.id,
                items: groupItems,
                repository: root.repository,
                baseBranch: root.baseBranch,
                parentNumbers: parents
            )
        }

        return built.sorted { lhs, rhs in
            let leftDate = lhs.items.reduce(.distantPast) { max($0, $1.createdAt) }
            let rightDate = rhs.items.reduce(.distantPast) { max($0, $1.createdAt) }
            if leftDate != rightDate { return leftDate > rightDate }
            return lhs.id < rhs.id
        }
    }

    private static func normalizedRepository(_ name: String?) -> String? {
        guard let name, !name.isEmpty else { return nil }
        return name.lowercased()
    }

    private static func cycleMembers(in parents: [String: String]) -> Set<String> {
        var cyclic: Set<String> = []
        for start in parents.keys {
            var path: [String] = []
            var indexByID: [String: Int] = [:]
            var current: String? = start
            while let id = current, let parent = parents[id] {
                if let cycleStart = indexByID[id] {
                    cyclic.formUnion(path[cycleStart...])
                    break
                }
                indexByID[id] = path.count
                path.append(id)
                current = parent
            }
        }
        return cyclic
    }
}

private struct BranchKey: Hashable {
    let repository: String
    let branch: String
}
