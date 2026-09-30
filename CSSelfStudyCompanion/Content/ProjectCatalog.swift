import Foundation

enum ProjectTrack: String, CaseIterable, Identifiable {
    case foundation
    case systems
    case network
    case data
    case compilers
    case apple

    var id: String { rawValue }

    var title: String {
        switch self {
        case .foundation: "C 与 Linux 基础"
        case .systems: "系统与并发"
        case .network: "网络与服务"
        case .data: "数据与存储"
        case .compilers: "编译与语言"
        case .apple: "Apple 平台"
        }
    }

    var icon: String {
        switch self {
        case .foundation: "shippingbox.fill"
        case .systems: "cpu.fill"
        case .network: "network"
        case .data: "externaldrive.fill"
        case .compilers: "chevron.left.forwardslash.chevron.right"
        case .apple: "apple.logo"
        }
    }

    var tintHex: String {
        switch self {
        case .foundation: "4F7CFF"
        case .systems: "D35400"
        case .network: "2D98DA"
        case .data: "16A085"
        case .compilers: "9B59B6"
        case .apple: "E84393"
        }
    }

    var order: Int {
        switch self {
        case .foundation: 0
        case .systems: 1
        case .network: 2
        case .data: 3
        case .compilers: 4
        case .apple: 5
        }
    }
}

enum ProjectEngineeringPhase: String, CaseIterable, Identifiable {
    case specification
    case scaffold
    case core
    case tests
    case hardening
    case release

    var id: String { rawValue }

    var title: String {
        switch self {
        case .specification: "规格"
        case .scaffold: "骨架"
        case .core: "核心"
        case .tests: "测试"
        case .hardening: "加固"
        case .release: "发布"
        }
    }

    var icon: String {
        switch self {
        case .specification: "doc.text"
        case .scaffold: "square.grid.2x2"
        case .core: "hammer.fill"
        case .tests: "checkmark.diamond.fill"
        case .hardening: "shield.lefthalf.filled"
        case .release: "shippingbox.fill"
        }
    }
}

struct ProjectRepositoryArea: Identifiable, Hashable {
    let path: String
    let purpose: String

    var id: String { path }
}

struct ProjectMilestone: Identifiable {
    let id: String
    let phase: ProjectEngineeringPhase
    let title: String
    let detail: String
    let outputs: [String]
    let checks: [String]
}

struct LearningProject: Identifiable {
    let id: String
    let track: ProjectTrack
    let order: Int
    let estimatedHours: Int
    let title: String
    let summary: String
    let level: String
    let icon: String
    let themeHex: String
    let tags: [String]
    let prerequisites: [String]
    let repository: [ProjectRepositoryArea]
    let deliverables: [String]
    let qualityGates: [String]
    let releaseChecklist: [String]
    let readingMissionIDs: [String]
    let milestones: [ProjectMilestone]
}

enum ProjectCatalog {
    static let projects: [LearningProject] = [
        LearningProject(
            id: "cli-contacts",
            track: .foundation,
            order: 1,
            estimatedHours: 18,
            title: "命令行通讯录",
            summary: "用 C 结构体、文件读写和命令行参数完成可持久化的联系人工具。",
            level: "入门",
            icon: "person.2.fill",
            themeHex: "4F7CFF",
            tags: ["C", "文件", "结构体"],
            prerequisites: ["变量、函数、数组和结构体", "fopen/fgets/fprintf 基本用法"],
            repository: [
                ProjectRepositoryArea(path: "src/main.c", purpose: "命令分派、参数校验和退出码"),
                ProjectRepositoryArea(path: "src/contacts.c", purpose: "联系人模型、增删查改和持久化"),
                ProjectRepositoryArea(path: "include/contacts.h", purpose: "稳定的数据结构和函数接口"),
                ProjectRepositoryArea(path: "tests/", purpose: "边界输入、文件损坏和重启恢复测试"),
                ProjectRepositoryArea(path: "README.md", purpose: "数据格式、命令示例和已知限制")
            ],
            deliverables: ["源码", "示例数据", "README", "三个边界测试"],
            qualityGates: ["编译开启 -Wall -Wextra -Werror", "空文件、损坏数据和超长字段不会崩溃", "所有 fopen/malloc 都有错误路径"],
            releaseChecklist: ["从空目录按 README 构建", "运行示例并验证重启后数据仍在", "在 README 记录一个未解决问题"],
            readingMissionIDs: ["oss-coreutils", "oss-git"],
            milestones: [
                ProjectMilestone(id: "model", phase: .specification, title: "定义联系人和存储模型", detail: "明确字段、最大长度、唯一性、文件格式和错误返回码。", outputs: ["数据字典", "错误码表"], checks: ["一个联系人的每个字段都有类型和上限", "错误码能区分输入、文件和内存错误"]),
                ProjectMilestone(id: "scaffold", phase: .scaffold, title: "建立源码、头文件和测试骨架", detail: "拆分 main 与业务逻辑，准备 Makefile 或构建脚本。", outputs: ["目录结构", "构建脚本"], checks: ["从干净目录一条命令完成构建", "头文件不暴露内部实现"]),
                ProjectMilestone(id: "crud", phase: .core, title: "实现新增、查找、删除和列表", detail: "使用结构体数组或动态内存，所有输入都经过校验。", outputs: ["CRUD 命令", "示例数据"], checks: ["重复姓名、空输入和超长输入可解释", "进程退出码与错误一致"]),
                ProjectMilestone(id: "persist", phase: .tests, title: "完成文件和回归测试", detail: "覆盖空文件、损坏记录、写入失败和重启读取。", outputs: ["测试脚本", "失败复现记录"], checks: ["测试可重复运行", "错误路径不会留下半写记录"]),
                ProjectMilestone(id: "harden", phase: .hardening, title: "完成内存和输入加固", detail: "使用 AddressSanitizer 或 Valgrind 检查越界、泄漏和未初始化访问。", outputs: ["检查报告", "修复记录"], checks: ["未发现高危内存问题", "README 说明已知限制"]),
                ProjectMilestone(id: "release", phase: .release, title: "发布并做三分钟演示", detail: "从空目录重建，演示正常路径、一个失败路径和恢复过程。", outputs: ["Git 提交", "演示记录"], checks: ["另一位学习者可按 README 运行", "提交历史按功能拆分"])
            ]
        ),
        LearningProject(
            id: "file-integrity",
            track: .foundation,
            order: 2,
            estimatedHours: 20,
            title: "文件校验工具",
            summary: "实现分块读写、校验和、原子替换与错误恢复的终端工具。",
            level: "入门",
            icon: "checkmark.shield.fill",
            themeHex: "16A085",
            tags: ["C", "系统调用", "文件 I/O"],
            prerequisites: ["文件描述符与 open/read/write", "errno 和部分读写处理"],
            repository: [
                ProjectRepositoryArea(path: "src/main.c", purpose: "子命令和参数解析"),
                ProjectRepositoryArea(path: "src/copy.c", purpose: "分块复制、校验和与临时文件"),
                ProjectRepositoryArea(path: "src/error.c", purpose: "错误封装和退出码"),
                ProjectRepositoryArea(path: "tests/cases/", purpose: "不同大小和权限的测试输入"),
                ProjectRepositoryArea(path: "Makefile", purpose: "构建、测试和清理目标")
            ],
            deliverables: ["可执行程序", "测试文件", "错误处理说明"],
            qualityGates: ["正确处理部分读写和 EINTR", "失败时清理临时文件", "能识别空文件、大文件和无权限文件"],
            releaseChecklist: ["在 macOS 和 Linux 至少各运行一次", "保存一次权限失败证据", "README 标明支持的调用方式"],
            readingMissionIDs: ["oss-coreutils", "oss-git"],
            milestones: [
                ProjectMilestone(id: "spec", phase: .specification, title: "定义复制和校验语义", detail: "明确覆盖策略、校验算法、临时文件命名和错误码。", outputs: ["规格说明", "文件格式"], checks: ["覆盖与追加行为明确", "失败时不会静默留下半成品"]),
                ProjectMilestone(id: "io", phase: .core, title: "实现分块读写", detail: "正确处理 read/write 部分完成、EINTR 和 EOF。", outputs: ["copy 核心函数"], checks: ["空文件可处理", "跨缓冲区文件字节一致"]),
                ProjectMilestone(id: "checksum", phase: .core, title: "加入校验输出", detail: "对文件字节计算稳定校验并以十六进制输出。", outputs: ["checksum 子命令"], checks: ["相同输入结果一致", "文件变化能被发现"]),
                ProjectMilestone(id: "recover", phase: .hardening, title: "实现失败恢复", detail: "目标写入失败时清理临时文件，不破坏原目标。", outputs: ["恢复流程", "故障注入记录"], checks: ["权限不足和磁盘写入失败都可见", "重复运行不会产生垃圾文件"]),
                ProjectMilestone(id: "accept", phase: .tests, title: "覆盖文件边界", detail: "测试空文件、单字节、跨缓冲区和只读目录。", outputs: ["测试矩阵"], checks: ["关键边界都有结果", "每个失败都有退出码"]),
                ProjectMilestone(id: "release", phase: .release, title: "发布工具", detail: "整理 README、提交记录和一次性能/资源观察。", outputs: ["Release 提交", "演示记录"], checks: ["干净环境可构建", "能解释一次性能数据"])
            ]
        ),
        LearningProject(
            id: "mini-shell",
            track: .systems,
            order: 3,
            estimatedHours: 26,
            title: "迷你 Shell",
            summary: "通过 fork、exec、wait、管道、重定向和信号理解 Shell 的底层工作方式。",
            level: "进阶",
            icon: "terminal.fill",
            themeHex: "8E44AD",
            tags: ["C", "fork/exec", "管道"],
            prerequisites: ["进程与文件描述符", "fork/exec/wait 基本接口", "管道和 dup2"],
            repository: [
                ProjectRepositoryArea(path: "src/main.c", purpose: "REPL、命令分派和退出"),
                ProjectRepositoryArea(path: "src/parser.c", purpose: "词法拆分、引号和重定向解析"),
                ProjectRepositoryArea(path: "src/executor.c", purpose: "fork/exec、管道和等待"),
                ProjectRepositoryArea(path: "src/signals.c", purpose: "SIGINT、SIGCHLD 和前台进程组"),
                ProjectRepositoryArea(path: "tests/scripts/", purpose: "命令脚本和退出码测试")
            ],
            deliverables: ["支持管道和重定向的 Shell", "进程回收测试", "信号处理说明"],
            qualityGates: ["不存在僵尸进程", "管道两端在所有错误路径都关闭", "退出状态能正确传播"],
            releaseChecklist: ["交互模式和脚本模式都验证", "记录 Ctrl+C 行为", "README 列出尚未支持的功能"],
            readingMissionIDs: ["oss-coreutils", "oss-linux"],
            milestones: [
                ProjectMilestone(id: "spec", phase: .specification, title: "定义最小语法", detail: "明确空格、引号、管道、重定向和内建命令支持范围。", outputs: ["语法说明", "不支持列表"], checks: ["每个 token 有明确行为", "无法解析时不会执行半条命令"]),
                ProjectMilestone(id: "prompt", phase: .core, title: "实现提示符和命令解析", detail: "读取命令、拆分参数，并支持 exit 和空命令。", outputs: ["REPL", "token 列表"], checks: ["空输入不会崩溃", "引号和空格有测试"]),
                ProjectMilestone(id: "fork", phase: .core, title: "实现 fork/exec/wait", detail: "正确回收子进程并返回真实退出状态。", outputs: ["执行器", "退出码测试"], checks: ["找不到程序时报告 127", "子进程被回收"]),
                ProjectMilestone(id: "pipe", phase: .core, title: "加入管道和重定向", detail: "使用 pipe 和 dup2 组合多个命令，处理中间失败。", outputs: ["管道执行路径"], checks: ["两个和三个命令的管道可运行", "所有 fd 在错误路径关闭"]),
                ProjectMilestone(id: "harden", phase: .hardening, title: "处理信号和终端行为", detail: "处理 SIGINT、SIGCHLD，避免后台任务成为僵尸。", outputs: ["信号处理说明", "进程观察记录"], checks: ["Ctrl+C 不会杀死 Shell 本身", "ps 中不积累僵尸进程"]),
                ProjectMilestone(id: "release", phase: .release, title: "完成 Shell 验收", detail: "测试空命令、错误程序、管道失败和交互脚本。", outputs: ["验收脚本", "README"], checks: ["正常和失败路径都有证据", "限制被如实记录"])
            ]
        ),
        LearningProject(
            id: "task-pool",
            track: .systems,
            order: 4,
            estimatedHours: 30,
            title: "并发任务池",
            summary: "实现线程安全任务队列、工作线程、关闭协议和资源回收。",
            level: "高级",
            icon: "cpu.fill",
            themeHex: "D35400",
            tags: ["pthread", "队列", "同步"],
            prerequisites: ["互斥锁和条件变量", "线程创建、join 和生命周期"],
            repository: [
                ProjectRepositoryArea(path: "include/task_pool.h", purpose: "公开任务池接口"),
                ProjectRepositoryArea(path: "src/task_pool.c", purpose: "队列、worker 和关闭状态机"),
                ProjectRepositoryArea(path: "src/task.c", purpose: "任务函数、参数和释放回调"),
                ProjectRepositoryArea(path: "tests/stress.c", purpose: "并发压力与关闭测试"),
                ProjectRepositoryArea(path: "docs/invariants.md", purpose: "队列和关闭不变量")
            ],
            deliverables: ["线程池", "任务接口", "压力测试", "死锁排查记录"],
            qualityGates: ["任务不丢、不重复执行", "关闭后所有线程 join", "锁和条件变量顺序固定"],
            releaseChecklist: ["在 ThreadSanitizer 或重复压力下验证", "记录一次死锁假设与排除过程", "README 说明背压和取消规则"],
            readingMissionIDs: ["oss-redis", "oss-linux"],
            milestones: [
                ProjectMilestone(id: "spec", phase: .specification, title: "定义任务和关闭协议", detail: "明确任务所有权、返回值、取消、关闭和错误传播。", outputs: ["接口草案", "状态机"], checks: ["每个状态转换都有触发条件", "释放责任明确"]),
                ProjectMilestone(id: "queue", phase: .core, title: "实现线程安全任务队列", detail: "使用互斥锁和条件变量支持阻塞取出、入队和关闭。", outputs: ["任务队列"], checks: ["空队列不会忙等", "关闭能唤醒所有 worker"]),
                ProjectMilestone(id: "workers", phase: .core, title: "实现工作线程", detail: "循环取任务、执行并安全处理失败。", outputs: ["worker 线程"], checks: ["线程异常退出有记录", "任务返回值可观察"]),
                ProjectMilestone(id: "shutdown", phase: .hardening, title: "实现优雅关闭", detail: "等待队列完成或立即取消，并 join 所有线程。", outputs: ["关闭实现"], checks: ["重复关闭幂等", "关闭后不再接受新任务"]),
                ProjectMilestone(id: "stress", phase: .tests, title: "完成并发压力测试", detail: "覆盖空任务、高并发、慢任务和关闭竞态。", outputs: ["压力脚本", "资源报告"], checks: ["大量任务计数正确", "无死锁和线程泄漏"]),
                ProjectMilestone(id: "release", phase: .release, title: "整理工程交付", detail: "补充不变量、性能数据和故障复盘。", outputs: ["Git 历史", "项目演示"], checks: ["从干净目录构建", "能够解释吞吐和延迟取舍"])
            ]
        ),
        LearningProject(
            id: "tcp-chat",
            track: .network,
            order: 5,
            estimatedHours: 28,
            title: "TCP 聊天室",
            summary: "用 socket、事件循环或线程实现多人聊天、协议边界和优雅断开。",
            level: "进阶",
            icon: "message.fill",
            themeHex: "2D98DA",
            tags: ["网络", "Socket", "并发"],
            prerequisites: ["TCP 连接生命周期", "字节流、半包和粘包", "poll/select 或线程基础"],
            repository: [
                ProjectRepositoryArea(path: "src/server.c", purpose: "监听、连接管理和事件循环"),
                ProjectRepositoryArea(path: "src/client.c", purpose: "用户输入与消息显示"),
                ProjectRepositoryArea(path: "src/protocol.c", purpose: "消息编解码和长度校验"),
                ProjectRepositoryArea(path: "include/protocol.h", purpose: "协议边界"),
                ProjectRepositoryArea(path: "tests/protocol_tests.c", purpose: "半包、粘包和超长消息")
            ],
            deliverables: ["TCP 服务器", "客户端", "协议说明", "压力测试记录"],
            qualityGates: ["禁止按一次 read 当成完整消息", "连接关闭后从列表移除", "消息长度有硬上限"],
            releaseChecklist: ["使用 127.0.0.1 演示", "记录断网和客户端突然退出", "README 说明并发模型和限制"],
            readingMissionIDs: ["oss-curl", "oss-nginx"],
            milestones: [
                ProjectMilestone(id: "protocol", phase: .specification, title: "定义消息协议", detail: "明确长度、昵称、正文、版本和断开消息。", outputs: ["协议文档", "编解码接口"], checks: ["半包和粘包规则明确", "非法长度会被拒绝"]),
                ProjectMilestone(id: "server", phase: .core, title: "实现单连接服务器", detail: "完成 bind/listen/accept/read/write/close 的正常路径。", outputs: ["单连接服务器"], checks: ["端口和地址可控", "错误返回不会继续使用无效 fd"]),
                ProjectMilestone(id: "broadcast", phase: .core, title: "支持多客户端和广播", detail: "管理连接列表并安全处理关闭和写失败。", outputs: ["连接管理器"], checks: ["客户端退出会清理", "广播不会向失效 fd 写入"]),
                ProjectMilestone(id: "client", phase: .core, title: "实现可交互客户端", detail: "接收用户输入、显示消息并支持退出。", outputs: ["客户端"], checks: ["退出不会留下后台连接", "网络断开有明确提示"]),
                ProjectMilestone(id: "harden", phase: .hardening, title: "处理超时和资源上限", detail: "添加读写超时、最大连接和消息长度限制。", outputs: ["资源限制说明"], checks: ["慢连接不会无限占用", "达到上限时行为可见"]),
                ProjectMilestone(id: "accept", phase: .release, title: "完成网络验收", detail: "测试断开、重复昵称、消息过长和并发连接。", outputs: ["验收日志", "演示脚本"], checks: ["协议边界都有证据", "能解释并发模型取舍"])
            ]
        ),
        LearningProject(
            id: "http-file-server",
            track: .network,
            order: 6,
            estimatedHours: 32,
            title: "HTTP 静态文件服务器",
            summary: "实现 GET/HEAD、MIME、缓存头、目录安全、日志和压力测试。",
            level: "高级",
            icon: "server.rack",
            themeHex: "3498DB",
            tags: ["HTTP", "Socket", "安全"],
            prerequisites: ["完成 TCP 服务器", "理解 HTTP/1.1 请求和响应格式"],
            repository: [
                ProjectRepositoryArea(path: "src/http_server.c", purpose: "监听、请求读取和响应发送"),
                ProjectRepositoryArea(path: "src/http_request.c", purpose: "请求行/头解析和大小限制"),
                ProjectRepositoryArea(path: "src/http_response.c", purpose: "状态码、头和正文"),
                ProjectRepositoryArea(path: "src/path_safety.c", purpose: "URL 解码和路径穿越防护"),
                ProjectRepositoryArea(path: "tests/integration/", purpose: "curl 集成测试")
            ],
            deliverables: ["HTTP 服务器", "MIME 映射", "安全测试", "压力测试记录"],
            qualityGates: ["拒绝 ../ 路径穿越", "请求头和正文有上限", "Content-Length 与实际字节一致"],
            releaseChecklist: ["只监听 127.0.0.1 演示", "记录 200、404、405 和 400", "README 说明未支持 HTTP/2 和 TLS"],
            readingMissionIDs: ["oss-curl", "oss-nginx"],
            milestones: [
                ProjectMilestone(id: "spec", phase: .specification, title: "定义支持范围", detail: "明确 GET/HEAD、状态码、MIME、缓存和错误响应。", outputs: ["接口清单", "非目标清单"], checks: ["每个状态码都有触发条件", "安全边界写清楚"]),
                ProjectMilestone(id: "parse", phase: .core, title: "实现请求解析", detail: "解析请求行和头部，限制行长和头数量。", outputs: ["HTTP request 类型"], checks: ["畸形请求不会越界", "超出上限返回明确状态"]),
                ProjectMilestone(id: "serve", phase: .core, title: "实现文件响应", detail: "安全打开文件，设置 Content-Type 和 Content-Length。", outputs: ["响应构造器"], checks: ["空文件、二进制文件和不存在文件都正确"]),
                ProjectMilestone(id: "safety", phase: .hardening, title: "实现路径穿越防护", detail: "拒绝绝对路径、..、非法编码和符号链接逃逸。", outputs: ["安全测试用例"], checks: ["攻击样例全部被拒绝", "错误不会泄露服务器路径"]),
                ProjectMilestone(id: "log", phase: .hardening, title: "加入结构化日志", detail: "记录请求方法、状态、字节数和耗时，不记录敏感内容。", outputs: ["访问日志"], checks: ["错误请求可追踪", "日志不包含完整私密数据"]),
                ProjectMilestone(id: "accept", phase: .release, title: "完成功能和压力验收", detail: "用 curl、并发客户端和错误请求测试。", outputs: ["curl 脚本", "压测报告"], checks: ["正常和错误路径均可复现", "资源上限有数据支持"])
            ]
        ),
        LearningProject(
            id: "redis-lite",
            track: .data,
            order: 7,
            estimatedHours: 40,
            title: "Mini Redis",
            summary: "用 RESP 协议、哈希表、事件循环和过期策略实现一个小型 KV 服务。",
            level: "高级",
            icon: "cylinder.split.1x2.fill",
            themeHex: "E67E22",
            tags: ["Redis", "RESP", "事件循环"],
            prerequisites: ["哈希表和内存所有权", "TCP 服务器", "nonblocking I/O 基础"],
            repository: [
                ProjectRepositoryArea(path: "src/server.c", purpose: "事件循环和连接生命周期"),
                ProjectRepositoryArea(path: "src/resp.c", purpose: "RESP 解析和序列化"),
                ProjectRepositoryArea(path: "src/store.c", purpose: "键值存储、过期和命令分派"),
                ProjectRepositoryArea(path: "src/dict.c", purpose: "哈希表及扩容策略"),
                ProjectRepositoryArea(path: "tests/redis-cli.sh", purpose: "协议级集成测试")
            ],
            deliverables: ["RESP 解析器", "SET/GET/DEL/TTL", "事件循环服务", "压测记录"],
            qualityGates: ["协议解析支持半包和粘包", "过期键不会返回错误数据", "删除和覆盖时无内存泄漏"],
            releaseChecklist: ["用 redis-cli 或 nc 验证", "记录并发连接和内存变化", "README 明确只实现子集"],
            readingMissionIDs: ["oss-redis", "oss-sqlite"],
            milestones: [
                ProjectMilestone(id: "spec", phase: .specification, title: "定义协议和命令子集", detail: "确定支持命令、错误格式、键值类型和过期语义。", outputs: ["命令表", "RESP 说明"], checks: ["所有命令有输入和输出样例", "错误格式与正常格式区分"]),
                ProjectMilestone(id: "dict", phase: .core, title: "实现哈希表和内存所有权", detail: "支持插入、查找、删除、扩容和释放。", outputs: ["字典实现", "单元测试"], checks: ["冲突路径正确", "删除后释放值对象"]),
                ProjectMilestone(id: "resp", phase: .core, title: "实现 RESP 编解码", detail: "处理数组、批量字符串、错误、整数的分帧。", outputs: ["协议解析器"], checks: ["半包不会误解析", "畸形长度被拒绝"]),
                ProjectMilestone(id: "server", phase: .core, title: "实现事件循环和命令分派", detail: "管理多连接、读写缓冲区和安全关闭。", outputs: ["服务器"], checks: ["慢客户端不会阻塞所有连接", "断开后资源释放"]),
                ProjectMilestone(id: "ttl", phase: .hardening, title: "加入过期和容量限制", detail: "实现 TTL、惰性删除和最大键数量。", outputs: ["过期策略"], checks: ["过期键不会返回旧值", "容量上限有明确行为"]),
                ProjectMilestone(id: "accept", phase: .release, title: "完成协议和压力验收", detail: "记录功能测试、内存占用、并发连接和失败请求。", outputs: ["验收报告", "演示脚本"], checks: ["与公开协议样例对照", "限制和差异被记录"])
            ]
        ),
        LearningProject(
            id: "storage-engine",
            track: .data,
            order: 8,
            estimatedHours: 46,
            title: "页式键值存储引擎",
            summary: "实现页管理、B+ 树索引、事务日志和崩溃恢复的核心路径。",
            level: "专家",
            icon: "externaldrive.connected.to.line.below",
            themeHex: "16A085",
            tags: ["B+ 树", "WAL", "崩溃恢复"],
            prerequisites: ["文件 I/O", "B+ 树或数据库索引课程", "事务和日志基本概念"],
            repository: [
                ProjectRepositoryArea(path: "src/pager.c", purpose: "页缓存、读写和刷盘"),
                ProjectRepositoryArea(path: "src/btree.c", purpose: "B+ 树查找、插入和分裂"),
                ProjectRepositoryArea(path: "src/wal.c", purpose: "日志记录、检查点和恢复"),
                ProjectRepositoryArea(path: "src/db.c", purpose: "事务和键值 API"),
                ProjectRepositoryArea(path: "tests/recovery/", purpose: "崩溃和回放测试")
            ],
            deliverables: ["页管理器", "B+ 树索引", "WAL", "恢复测试"],
            qualityGates: ["页号和长度经过校验", "崩溃后能恢复到一致状态", "删除页面不会悬空引用"],
            releaseChecklist: ["在临时文件上执行故障注入", "记录一次损坏文件修复或拒绝策略", "README 说明不支持的 SQL 层"],
            readingMissionIDs: ["oss-sqlite", "oss-redis"],
            milestones: [
                ProjectMilestone(id: "format", phase: .specification, title: "定义页和记录格式", detail: "设计页头、空闲空间、记录编码和校验字段。", outputs: ["磁盘格式规范"], checks: ["每个字段有大小和边界", "损坏页可被检测"]),
                ProjectMilestone(id: "pager", phase: .core, title: "实现页管理和缓存", detail: "支持分配、读取、修改、刷盘和关闭。", outputs: ["Pager API"], checks: ["越界页号被拒绝", "关闭时缓存一致"]),
                ProjectMilestone(id: "btree", phase: .core, title: "实现 B+ 树查找和插入", detail: "处理叶子分裂、父节点更新和重复键。", outputs: ["B+ 树索引"], checks: ["随机插入后仍可查找", "分裂保持有序不变量"]),
                ProjectMilestone(id: "wal", phase: .core, title: "实现事务日志", detail: "记录更新并支持提交、回滚和恢复。", outputs: ["WAL"], checks: ["部分写日志能被识别", "提交前后语义清楚"]),
                ProjectMilestone(id: "recovery", phase: .tests, title: "完成崩溃恢复测试", detail: "在写入不同阶段终止进程并重新打开数据库。", outputs: ["故障注入脚本", "恢复矩阵"], checks: ["不丢失已提交数据", "半提交数据不会泄露"]),
                ProjectMilestone(id: "release", phase: .release, title: "发布存储引擎", detail: "整理格式文档、API、性能数据和限制。", outputs: ["格式文档", "基准报告"], checks: ["小型数据集可重复恢复", "性能数据有环境和规模说明"])
            ]
        ),
        LearningProject(
            id: "mini-compiler",
            track: .compilers,
            order: 9,
            estimatedHours: 40,
            title: "表达式编译器",
            summary: "从词法、语法、AST、IR 到解释器，完成一个可测试的计算器语言。",
            level: "高级",
            icon: "textformat.abc.dottedunderline",
            themeHex: "9B59B6",
            tags: ["编译原理", "AST", "IR"],
            prerequisites: ["递归和树结构", "基本文法概念", "C 结构与动态内存"],
            repository: [
                ProjectRepositoryArea(path: "src/lexer.c", purpose: "token 扫描和源位置"),
                ProjectRepositoryArea(path: "src/parser.c", purpose: "递归下降解析和错误恢复"),
                ProjectRepositoryArea(path: "src/ast.c", purpose: "AST 构造、遍历和释放"),
                ProjectRepositoryArea(path: "src/eval.c", purpose: "AST 或 IR 求值"),
                ProjectRepositoryArea(path: "tests/compiler/", purpose: "合法和非法输入")
            ],
            deliverables: ["Lexer", "Parser", "AST", "解释器", "错误定位"],
            qualityGates: ["运算符优先级正确", "每个 AST 节点都有释放路径", "错误包含行列和恢复行为"],
            releaseChecklist: ["从空目录构建", "运行正常、边界和非法输入", "README 记录语法和限制"],
            readingMissionIDs: ["oss-jq", "oss-llvm"],
            milestones: [
                ProjectMilestone(id: "grammar", phase: .specification, title: "定义 token 和文法", detail: "明确数字、标识符、运算符、括号和错误符号。", outputs: ["文法文档", "token 表"], checks: ["优先级和结合性明确", "每个 token 有最长匹配规则"]),
                ProjectMilestone(id: "lexer", phase: .core, title: "实现词法分析器", detail: "识别 token、位置和非法字符，输出可测试序列。", outputs: ["Lexer"], checks: ["空白和位置正确", "非法字符不会静默跳过"]),
                ProjectMilestone(id: "parser", phase: .core, title: "实现递归下降解析器", detail: "正确处理优先级、括号和错误恢复。", outputs: ["Parser"], checks: ["嵌套表达式正确", "错误不会无限循环"]),
                ProjectMilestone(id: "ast", phase: .core, title: "构造并遍历 AST", detail: "设计节点类型、所有权和释放策略。", outputs: ["AST"], checks: ["节点释放完整", "求值结果与手算一致"]),
                ProjectMilestone(id: "ir", phase: .hardening, title: "增加简单 IR", detail: "把 AST 转成三地址码或栈指令。", outputs: ["IR 类型", "打印器"], checks: ["IR 顺序可解释", "除零和未定义变量可见"]),
                ProjectMilestone(id: "accept", phase: .release, title: "完成编译验收", detail: "测试嵌套、空输入、超长输入和错误提示。", outputs: ["测试矩阵", "演示记录"], checks: ["错误信息包含位置", "已知限制写入 README"])
            ]
        ),
        LearningProject(
            id: "study-log-app",
            track: .apple,
            order: 10,
            estimatedHours: 36,
            title: "SwiftData 学习记录 App",
            summary: "用 SwiftUI + SwiftData 构建可离线使用、可搜索、可导出并适配 iOS/macOS 的作品。",
            level: "进阶",
            icon: "apple.logo",
            themeHex: "E84393",
            tags: ["SwiftUI", "SwiftData", "Apple 平台"],
            prerequisites: ["Swift 值类型、可选值和错误处理", "SwiftUI 状态和导航基础", "SwiftData @Model 与 @Query"],
            repository: [
                ProjectRepositoryArea(path: "App/", purpose: "应用入口和 ModelContainer"),
                ProjectRepositoryArea(path: "Models/", purpose: "SwiftData 实体、关系和迁移"),
                ProjectRepositoryArea(path: "Features/", purpose: "按功能拆分列表、详情、搜索和统计"),
                ProjectRepositoryArea(path: "Services/", purpose: "导入导出、提醒和业务服务"),
                ProjectRepositoryArea(path: "Tests/", purpose: "模型、搜索、迁移和边界测试")
            ],
            deliverables: ["可运行 iOS/macOS App", "版本化模型", "空状态", "导出与测试"],
            qualityGates: ["无虚构 API", "删除关系有明确规则", "无障碍标签和空状态完整", "数据迁移可测试"],
            releaseChecklist: ["在 iPhone 模拟器和 Mac 分别构建", "从空数据库运行一次", "README 写清截图、限制和后续计划"],
            readingMissionIDs: ["oss-swift", "oss-git"],
            milestones: [
                ProjectMilestone(id: "model", phase: .specification, title: "定义用户问题和数据模型", detail: "明确目标、非目标、实体、唯一标识、关系和删除规则。", outputs: ["需求说明", "ER 图"], checks: ["每个实体有生命周期", "删除规则可解释"]),
                ProjectMilestone(id: "shell", phase: .scaffold, title: "建立多平台 App 骨架", detail: "配置 iOS/macOS target、ModelContainer 和基础导航。", outputs: ["可运行空壳"], checks: ["两个平台均能构建", "预览和测试容器可创建"]),
                ProjectMilestone(id: "core", phase: .core, title: "完成新增、详情和搜索", detail: "实现核心用户路径并处理空状态和输入错误。", outputs: ["核心界面", "查询实现"], checks: ["数据重启后仍在", "搜索词为空和超长时正确"]),
                ProjectMilestone(id: "export", phase: .core, title: "加入导出和导入", detail: "提供稳定的数据格式、错误提示和合并策略。", outputs: ["JSON 导出", "导入结果"], checks: ["重复导入不会破坏数据", "失败时可恢复"]),
                ProjectMilestone(id: "quality", phase: .hardening, title: "完成无障碍和性能检查", detail: "支持动态字体、VoiceOver、窄窗口和大数据集。", outputs: ["无障碍检查", "性能记录"], checks: ["关键操作有标签", "列表滚动和查询没有明显卡顿"]),
                ProjectMilestone(id: "release", phase: .release, title: "发布作品", detail: "整理 README、截图、迁移说明、已知问题和演示。", outputs: ["Release", "三分钟演示"], checks: ["干净环境可安装", "限制和下一步如实记录"])
            ]
        )
    ]
}
