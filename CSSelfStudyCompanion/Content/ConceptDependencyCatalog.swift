import Foundation

enum ConceptDependencyCatalog {
    static func prerequisites(for conceptID: String) -> [String] {
        dependencies[conceptID] ?? []
    }

    private static let dependencies: [String: [String]] = [
        "pointer": ["memory-layout"],
        "memory-layout": ["virtual-memory"],
        "stack-frame": ["pointer", "memory-layout"],
        "compilation": [],
        "linking": ["compilation"],
        "process": ["virtual-memory"],
        "thread": ["process"],
        "mutex": ["thread"],
        "virtual-memory": ["memory-layout"],
        "file-descriptor": ["system-call"],
        "system-call": ["process"],
        "signal": ["process"],
        "socket": ["file-descriptor"],
        "tcp": ["socket"],
        "http": ["tcp"],
        "dns": ["tcp"],
        "tree": ["hash-table"],
        "graph": ["tree"],
        "complexity": [],
        "cache": ["complexity"],
        "assembly": ["register"],
        "kernel": ["system-call"],
        "namespace": ["process", "kernel"],
        "cgroup": ["process", "kernel"],
        "transaction": ["database-index"],
        "database-index": ["tree"],
        "lexer": [],
        "parser": ["lexer"],
        "ast": ["parser"],
        "ir": ["ast", "assembly"],
        "mmap": ["virtual-memory", "file-descriptor"],
        "epoll": ["file-descriptor", "socket"]
    ]
}
