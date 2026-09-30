import Foundation

struct CodeReadingExercise: Identifiable {
    let id: String
    let title: String
    let focus: String
    let language: String
    let code: String
    let prompt: String
    let options: [String]
    let correctIndex: Int
    let explanation: String
}

enum CodeReadingCatalog {
    static let exercises: [CodeReadingExercise] = [
        CodeReadingExercise(
            id: "cr-pointer-swap",
            title: "指针参数为什么没有交换",
            focus: "C 指针",
            language: "c",
            code: """
            void swap(int a, int b) {
                int temp = a;
                a = b;
                b = temp;
            }
            int main(void) {
                int x = 1, y = 2;
                swap(x, y);
                printf("%d %d\\n", x, y);
            }
            """,
            prompt: "程序会输出什么，原因是什么？",
            options: ["1 2，因为 swap 只修改了参数副本", "2 1，因为 C 自动传递引用", "1 2，因为 printf 顺序相反", "编译失败，因为 swap 没有声明"],
            correctIndex: 0,
            explanation: "C 的参数默认按值传递。要修改调用者变量，需要传入 int *，并在函数内解引用。"
        ),
        CodeReadingExercise(
            id: "cr-array-bound",
            title: "数组越界的隐蔽错误",
            focus: "C 内存",
            language: "c",
            code: """
            int a[3] = {1, 2, 3};
            for (int i = 0; i <= 3; i++) {
                printf("%d ", a[i]);
            }
            """,
            prompt: "循环至少存在什么问题？",
            options: ["多访问一次 a[3]，造成越界读", "数组会自动扩展到 4 个元素", "printf 不能打印数组", "循环不会执行"],
            correctIndex: 0,
            explanation: "合法下标是 0 到 2。条件 i <= 3 会访问 a[3]，属于未定义行为。"
        ),
        CodeReadingExercise(
            id: "cr-strlen-null",
            title: "字符串终止符",
            focus: "C 字符串",
            language: "c",
            code: """
            char s[4] = {'t', 'e', 's', 't'};
            printf("%zu\\n", strlen(s));
            """,
            prompt: "这段代码为什么不可靠？",
            options: ["数组中没有 '\\0'，strlen 会继续越界读取", "strlen 只能用于 int 数组", "数组必须写成 char *s", "printf 不支持 %zu"],
            correctIndex: 0,
            explanation: "C 字符串必须以 '\\0' 结尾。这里四个字符刚好占满数组，没有终止符。"
        ),
        CodeReadingExercise(
            id: "cr-malloc-free",
            title: "释放后继续访问",
            focus: "C 内存",
            language: "c",
            code: """
            int *p = malloc(sizeof(int));
            *p = 42;
            free(p);
            printf("%d\\n", *p);
            """,
            prompt: "free 后的 printf 有什么风险？",
            options: ["use-after-free，结果未定义", "free 会把 p 自动设为 NULL", "printf 会自动重新分配内存", "没有风险，因为整数很小"],
            correctIndex: 0,
            explanation: "free 后指针值通常不会自动清空。继续解引用属于 use-after-free。"
        ),
        CodeReadingExercise(
            id: "cr-fork-order",
            title: "fork 创建了几个进程",
            focus: "Linux 进程",
            language: "c",
            code: """
            fork();
            fork();
            printf("A\\n");
            """,
            prompt: "正常情况下会打印几行 A？",
            options: ["4 行", "2 行", "3 行", "1 行"],
            correctIndex: 0,
            explanation: "第一次 fork 后有两个进程，第二次 fork 让每个进程再复制一次，共 4 个进程。"
        ),
        CodeReadingExercise(
            id: "cr-pipe-close",
            title: "管道 read 为什么一直阻塞",
            focus: "Linux IPC",
            language: "c",
            code: """
            int fd[2];
            pipe(fd);
            write(fd[1], "hi", 2);
            char buf[8];
            read(fd[0], buf, sizeof(buf));
            """,
            prompt: "单进程下 read 可能一直阻塞，关键原因是什么？",
            options: ["写端 fd[1] 仍然打开，read 认为以后还可能有数据", "pipe 不能在同一进程使用", "read 的缓冲区太小", "write 必须先 fork"],
            correctIndex: 0,
            explanation: "read 要等 EOF 或至少一个字节。EOF 只有在所有写端都关闭后才出现。"
        ),
        CodeReadingExercise(
            id: "cr-mutex-scope",
            title: "互斥锁保护范围",
            focus: "并发",
            language: "c",
            code: """
            pthread_mutex_lock(&mutex);
            int local = counter;
            pthread_mutex_unlock(&mutex);
            local++;
            counter = local;
            """,
            prompt: "这个实现为什么仍可能丢更新？",
            options: ["读取和写回没有被同一个临界区保护", "counter 必须是 double", "mutex 只能锁一次", "local 变量不能在线程中使用"],
            correctIndex: 0,
            explanation: "两个线程可能都读到相同的旧值，再分别写回，导致其中一个更新丢失。"
        ),
        CodeReadingExercise(
            id: "cr-shell-quote",
            title: "Shell 变量和空格",
            focus: "Shell",
            language: "bash",
            code: """
            file="a b.txt"
            rm $file
            """,
            prompt: "这段脚本可能发生什么？",
            options: ["rm 可能收到两个参数 a 和 b.txt", "Shell 会自动保留整个字符串", "rm 会拒绝未加引号的变量", "file 变量不会赋值"],
            correctIndex: 0,
            explanation: "未加引号的变量会发生词分割，应写成 rm -- \"$file\"。"
        ),
        CodeReadingExercise(
            id: "cr-grep-pipeline",
            title: "grep 管道的退出状态",
            focus: "Shell 管道",
            language: "bash",
            code: """
            grep -q error app.log | tee result.txt
            """,
            prompt: "为什么 tee 通常收不到内容？",
            options: ["grep -q 不输出内容，只设置退出状态", "tee 不能读取管道", "app.log 会被删除", "grep 只能处理一个文件"],
            correctIndex: 0,
            explanation: "-q 表示静默模式，只关心是否匹配，不输出匹配行。"
        ),
        CodeReadingExercise(
            id: "cr-sql-nplusone",
            title: "N+1 查询",
            focus: "数据库",
            language: "sql",
            code: """
            SELECT id, name FROM users;
            -- 对每一行再执行：
            SELECT * FROM orders WHERE user_id = ?;
            """,
            prompt: "这种访问模式叫什么？",
            options: ["N+1 查询问题", "全表死锁", "数据库逆范式", "索引覆盖"],
            correctIndex: 0,
            explanation: "一次查列表，再对 N 行执行 N 次关联查询。应使用 JOIN 或批量查询。"
        ),
        CodeReadingExercise(
            id: "cr-tcp-short-read",
            title: "TCP 一次 read 不一定收完整消息",
            focus: "网络",
            language: "c",
            code: """
            n = read(sock, buf, sizeof(buf));
            parse_message(buf, n);
            """,
            prompt: "这个服务器的核心问题是什么？",
            options: ["TCP 是字节流，应用层必须处理半包和粘包", "read 永远按行返回", "socket 必须使用 UDP", "sizeof(buf) 会导致死锁"],
            correctIndex: 0,
            explanation: "TCP 没有消息边界，需要长度前缀、分隔符或自描述协议处理半包和粘包。"
        ),
        CodeReadingExercise(
            id: "cr-recursion-base",
            title: "递归缺少终止条件",
            focus: "算法",
            language: "c",
            code: """
            int sum(int n) {
                return n + sum(n - 1);
            }
            """,
            prompt: "程序为什么会崩溃？",
            options: ["缺少 n <= 0 的基础情况，会无限递归", "sum 不能返回值", "递归只能运行两次", "n 必须使用指针"],
            correctIndex: 0,
            explanation: "递归必须在某个条件下停止，否则调用栈持续增长。"
        )
    ]
}

enum OpenSourceReadingLevel: Int, CaseIterable, Identifiable {
    case singleFile = 0
    case moduleMap
    case protocolTrace
    case dataStructure
    case systemBoundary
    case languageRuntime

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .singleFile: "L0 单文件入口"
        case .moduleMap: "L1 模块地图"
        case .protocolTrace: "L2 协议链路"
        case .dataStructure: "L3 数据结构与存储"
        case .systemBoundary: "L4 系统与事件循环"
        case .languageRuntime: "L5 语言与编译器运行时"
        }
    }

    var subtitle: String {
        switch self {
        case .singleFile: "从 main、参数和返回码读懂一个命令"
        case .moduleMap: "把模块、接口和调用方向画出来"
        case .protocolTrace: "沿一次请求或数据报文追踪完整路径"
        case .dataStructure: "从公开行为追到内存结构和持久化"
        case .systemBoundary: "观察用户态、内核接口和事件分发"
        case .languageRuntime: "理解类型、IR、代码生成和运行时支撑"
        }
    }

    var icon: String {
        switch self {
        case .singleFile: "doc.text"
        case .moduleMap: "square.grid.2x2"
        case .protocolTrace: "arrow.left.arrow.right"
        case .dataStructure: "externaldrive.connected.to.line.below"
        case .systemBoundary: "cpu"
        case .languageRuntime: "chevron.left.forwardslash.chevron.right"
        }
    }

    var tintName: String {
        switch self {
        case .singleFile: "teal"
        case .moduleMap: "blue"
        case .protocolTrace: "indigo"
        case .dataStructure: "orange"
        case .systemBoundary: "purple"
        case .languageRuntime: "pink"
        }
    }
}

struct OpenSourceReadingMission: Identifiable {
    let id: String
    let level: OpenSourceReadingLevel
    let order: Int
    let title: String
    let repoName: String
    let repositoryURL: String
    let language: String
    let license: String
    let estimatedMinutes: Int
    let summary: String
    let prerequisites: [String]
    let entryPoints: [String]
    let searchSymbols: [String]
    let tasks: [String]
    let evidence: [String]
    let checkpoints: [String]
    let pitfalls: [String]
    let reflectionQuestion: String
    let relatedProjectIDs: [String]
}

enum OpenSourceReadingCatalog {
    static let missions: [OpenSourceReadingMission] = [
        OpenSourceReadingMission(
            id: "oss-coreutils",
            level: .singleFile,
            order: 1,
            title: "coreutils：从一个命令看主流程",
            repoName: "coreutils/coreutils",
            repositoryURL: "https://github.com/coreutils/coreutils",
            language: "C",
            license: "GPL-3.0",
            estimatedMinutes: 60,
            summary: "从 cat 的 main、参数处理和 read/write 循环入手，建立阅读单文件 CLI 程序的模板。",
            prerequisites: ["会使用终端和 gcc/clang", "理解 argc、argv、文件描述符和退出码"],
            entryPoints: ["src/cat.c", "src/copy.c", "lib/"],
            searchSymbols: ["main", "usage", "write", "read", "close_stdout"],
            tasks: [
                "画出 main 到实际读取文件的调用链，标出参数校验点。",
                "找出正常处理多文件、无文件参数和文件不存在时的三条路径。",
                "解释一次 read/write 为什么可能只处理部分数据，以及上游如何处理。",
                "用一个小文本文件运行 cat，记录 stdout、stderr 和退出码。"
            ],
            evidence: ["调用链图", "一个失败分支的源码位置", "真实命令输出与退出码"],
            checkpoints: ["能找到程序入口", "能解释 CLI 参数和数据流", "能定位错误输出路径", "能复现一次行为"],
            pitfalls: ["只读 main，不追到实际 I/O", "把库函数行为当成本项目实现", "忽略退出码和 stderr"],
            reflectionQuestion: "如果让你把 cat 改成只读指定前缀，最小改动点在哪里？",
            relatedProjectIDs: ["cli-contacts", "file-integrity"]
        ),
        OpenSourceReadingMission(
            id: "oss-jq",
            level: .moduleMap,
            order: 2,
            title: "jq：解析、执行与值模型",
            repoName: "jqlang/jq",
            repositoryURL: "https://github.com/jqlang/jq",
            language: "C",
            license: "MIT",
            estimatedMinutes: 90,
            summary: "观察命令行程序如何把输入文本、解析器、执行器和 JSON 值模型组织成多个模块。",
            prerequisites: ["具备 C 结构体和函数指针基础", "了解词法/语法分析的基本术语"],
            entryPoints: ["src/main.c", "src/parser.y", "src/execute.c", "src/jv.c"],
            searchSymbols: ["jq_compile_args", "jv_parse", "jq_next", "block_bind"],
            tasks: [
                "画出输入 JSON、解析、编译过滤器、执行和输出的模块边界。",
                "选择一个过滤器表达式，追踪它从 argv 到执行器的路径。",
                "定位值类型 jv 的创建、复制和释放规则，列出所有权说明。",
                "找出错误处理和退出码之间的映射关系。"
            ],
            evidence: ["模块关系图", "一个表达式的端到端调用链", "资源所有权摘要"],
            checkpoints: ["能区分解析器和执行器", "能描述值类型生命周期", "能定位一条真实执行路径", "能说明错误传播"],
            pitfalls: ["把 parser.y 当成手写实现，忽略生成步骤", "只看函数名就断言所有权", "忽略构建系统对源文件的选择"],
            reflectionQuestion: "如果把 jq 改成支持一个新字面量，需要触碰哪些模块？",
            relatedProjectIDs: ["mini-compiler"]
        ),
        OpenSourceReadingMission(
            id: "oss-git",
            level: .moduleMap,
            order: 3,
            title: "Git：对象、引用与命令入口",
            repoName: "git/git",
            repositoryURL: "https://github.com/git/git",
            language: "C",
            license: "GPL-2.0",
            estimatedMinutes: 90,
            summary: "从 builtin 命令、对象存储和引用数据库三个方向理解 Git 的模块地图。",
            prerequisites: ["熟悉 Git 基本操作", "理解文件格式和哈希"],
            entryPoints: ["builtin/cat-file.c", "object-file.c", "refs/", "object-name.c"],
            searchSymbols: ["cmd_cat_file", "read_object_file", "refs_read_raw_ref", "get_oid"],
            tasks: [
                "列出 builtin 命令如何注册到主命令分派器。",
                "追踪一个对象 ID 从命令行输入到对象内容读取的过程。",
                "区分 loose object、packfile 和引用文件的职责。",
                "用 git cat-file 观察对象类型、长度和内容。"
            ],
            evidence: ["命令分派图", "对象读取调用链", "真实对象的类型/长度/内容"],
            checkpoints: ["能定位命令入口", "能说明对象寻址", "能区分 refs 与 objects", "能复现一个对象查询"],
            pitfalls: ["把工作区当成数据库", "把引用当成对象内容", "忽略 packed objects 和替代对象机制"],
            reflectionQuestion: "为什么 Git 可以在不读取完整对象的情况下判断类型和大小？",
            relatedProjectIDs: ["file-integrity", "storage-engine"]
        ),
        OpenSourceReadingMission(
            id: "oss-curl",
            level: .protocolTrace,
            order: 4,
            title: "curl：从 easy handle 到网络传输",
            repoName: "curl/curl",
            repositoryURL: "https://github.com/curl/curl",
            language: "C",
            license: "curl",
            estimatedMinutes: 120,
            summary: "沿 URL 解析、连接建立、协议转换和回调输出追踪一次 HTTP 请求。",
            prerequisites: ["理解 TCP/IP 与 HTTP 基础", "会使用 curl -v 和 socket 调试工具"],
            entryPoints: ["lib/easy.c", "lib/url.c", "lib/transfer.c", "src/tool_main.c"],
            searchSymbols: ["curl_easy_perform", "Curl_open", "Curl_connect", "Curl_readwrite"],
            tasks: [
                "画出 CLI 参数到 easy handle 的映射。",
                "追踪 URL 解析和连接目标选择，记录协议切换点。",
                "定位响应数据从 socket 到写回调的路径。",
                "用 curl -v 记录 DNS、TCP、TLS/HTTP 和退出码证据。"
            ],
            evidence: ["请求生命周期图", "连接建立与回调路径", "curl -v 原始输出"],
            checkpoints: ["能定位 URL 解析", "能描述连接生命周期", "能追踪数据回调", "能解释错误码"],
            pitfalls: ["把 libcurl 和 curl 命令行混成一层", "忽略重定向和重试", "只看 HTTP 正文不看连接阶段"],
            reflectionQuestion: "如果加入证书固定，应该在哪一层做，错误如何向上传播？",
            relatedProjectIDs: ["tcp-chat", "http-file-server"]
        ),
        OpenSourceReadingMission(
            id: "oss-redis",
            level: .dataStructure,
            order: 5,
            title: "Redis：事件循环、命令表与哈希表",
            repoName: "redis/redis",
            repositoryURL: "https://github.com/redis/redis",
            language: "C",
            license: "AGPL-3.0",
            estimatedMinutes: 120,
            summary: "从连接可读事件追到命令解析、命令表分派和字典读写。",
            prerequisites: ["理解 socket 与事件循环", "实现过哈希表或链表", "知道 RESP 协议的大致形态"],
            entryPoints: ["src/server.c", "src/networking.c", "src/dict.c", "src/t_hash.c"],
            searchSymbols: ["readQueryFromClient", "processCommand", "dictAdd", "dictFind"],
            tasks: [
                "画出客户端可读事件到命令执行的路径。",
                "找到一个命令如何通过命令表找到实现函数。",
                "追踪一次 HSET 如何创建或更新字典。",
                "分析扩容、过期和释放路径中的关键不变量。"
            ],
            evidence: ["事件到命令的调用链", "哈希表操作路径", "一条真实命令的日志或抓包"],
            checkpoints: ["能定位事件循环入口", "能解释命令分派", "能描述哈希表不变量", "能记录真实命令证据"],
            pitfalls: ["只读命令实现不追协议解析", "忽略数据库字典和对象编码", "把单线程模型理解成没有并发问题"],
            reflectionQuestion: "如果给一个小型 KV 服务增加 TTL，最小数据结构和清理策略是什么？",
            relatedProjectIDs: ["redis-lite", "task-pool"]
        ),
        OpenSourceReadingMission(
            id: "oss-sqlite",
            level: .dataStructure,
            order: 6,
            title: "SQLite：B-Tree、Pager 与 VDBE",
            repoName: "sqlite/sqlite",
            repositoryURL: "https://github.com/sqlite/sqlite",
            language: "C",
            license: "Public Domain",
            estimatedMinutes: 150,
            summary: "把 SQL 执行、B-Tree 页操作和事务日志串成一条存储引擎阅读路线。",
            prerequisites: ["理解 SQL、B+ 树和页缓存概念", "能阅读大型 C 模块的接口注释"],
            entryPoints: ["src/btree.c", "src/pager.c", "src/vdbe.c", "src/select.c"],
            searchSymbols: ["sqlite3BtreeInsert", "pager_write", "sqlite3VdbeExec", "sqlite3_prepare_v2"],
            tasks: [
                "记录一条 INSERT 从 SQL 编译到 VDBE 执行的调用链。",
                "定位 B-Tree 插入修改页的入口，画出页和游标的关系。",
                "说明 WAL 或 rollback journal 如何保证事务原子性。",
                "用 EXPLAIN QUERY PLAN 验证索引是否影响访问路径。"
            ],
            evidence: ["SQL 到 VDBE 的调用链", "页写入和事务边界图", "查询计划与索引对比"],
            checkpoints: ["能区分 SQL 层和存储层", "能追踪页写入", "能解释事务恢复", "能验证查询计划"],
            pitfalls: ["把 SQL 解析器和存储引擎混为一层", "忽略缓存与持久化边界", "只看一个函数就推断事务语义"],
            reflectionQuestion: "如果从零实现一个最小键值页存储，先保证哪个不变量？",
            relatedProjectIDs: ["storage-engine", "redis-lite"]
        ),
        OpenSourceReadingMission(
            id: "oss-nginx",
            level: .systemBoundary,
            order: 7,
            title: "Nginx：配置、事件模块与 HTTP 请求",
            repoName: "nginx/nginx",
            repositoryURL: "https://github.com/nginx/nginx",
            language: "C",
            license: "BSD-2-Clause",
            estimatedMinutes: 150,
            summary: "从配置解析、事件循环到 HTTP 请求状态机，理解高并发服务器的模块化结构。",
            prerequisites: ["理解 socket、epoll/select", "会配置和观察一个反向代理"],
            entryPoints: ["src/core/nginx.c", "src/event/ngx_event.c", "src/http/ngx_http.c", "src/http/ngx_http_request.c"],
            searchSymbols: ["ngx_http_init_connection", "ngx_epoll_process_events", "ngx_http_process_request"],
            tasks: [
                "画出启动配置、模块初始化和 worker 进程之间的关系。",
                "追踪一个连接从监听 socket 到 HTTP 状态机的过程。",
                "定位事件就绪、超时和连接关闭的处理路径。",
                "用最小 Nginx 配置抓取 access log 和上游转发证据。"
            ],
            evidence: ["启动与 worker 进程图", "连接状态机图", "access log 与配置片段"],
            checkpoints: ["能定位事件循环", "能追踪 HTTP 状态机", "能解释进程模型", "能复现代理请求"],
            pitfalls: ["把配置文件字段当运行时代码", "忽略 master/worker 进程边界", "只关注请求成功路径"],
            reflectionQuestion: "为什么高并发服务器通常避免为每个连接创建一个重量级线程？",
            relatedProjectIDs: ["http-file-server", "tcp-chat"]
        ),
        OpenSourceReadingMission(
            id: "oss-linux",
            level: .systemBoundary,
            order: 8,
            title: "Linux：从系统调用进入调度与内存",
            repoName: "torvalds/linux",
            repositoryURL: "https://github.com/torvalds/linux",
            language: "C",
            license: "GPL-2.0",
            estimatedMinutes: 180,
            summary: "沿 openat、缺页和进程切换追踪用户态到内核核心路径的边界。",
            prerequisites: ["理解 POSIX、进程和虚拟内存", "会使用 strace、perf 或 bpftrace 中的一个工具"],
            entryPoints: ["fs/open.c", "mm/memory.c", "kernel/sched/core.c", "kernel/fork.c"],
            searchSymbols: ["do_sys_openat2", "handle_mm_fault", "__schedule", "copy_process"],
            tasks: [
                "从一个 openat 系统调用追到文件描述符创建和错误返回。",
                "解释缺页异常如何进入页表处理和磁盘 I/O。",
                "定位一次上下文切换的调度入口和关键状态。",
                "用 strace 或 perf 记录一个真实进程的系统调用/调度证据。"
            ],
            evidence: ["系统调用调用链", "缺页或调度路径图", "真实 trace 输出"],
            checkpoints: ["能区分用户态与内核态", "能定位一条系统调用", "能说明内存映射", "能记录性能证据"],
            pitfalls: ["把内核源码当成线性阅读材料", "忽略配置和架构差异", "用一次 trace 推断所有负载"],
            reflectionQuestion: "为什么读内核源码前要先能稳定复现一个用户态观察？",
            relatedProjectIDs: ["task-pool", "redis-lite"]
        ),
        OpenSourceReadingMission(
            id: "oss-llvm",
            level: .languageRuntime,
            order: 9,
            title: "LLVM/Clang：从源码到 IR",
            repoName: "llvm/llvm-project",
            repositoryURL: "https://github.com/llvm/llvm-project",
            language: "C++/LLVM IR",
            license: "Apache-2.0 WITH LLVM-exception",
            estimatedMinutes: 180,
            summary: "用一个最小 C 文件追踪 Clang 解析、AST、LLVM IR 和优化 pass 的接口边界。",
            prerequisites: ["理解 C 类型和函数调用", "知道 AST、IR 和优化 pass 的基本概念"],
            entryPoints: ["clang/lib/Parse/", "clang/lib/CodeGen/", "llvm/lib/IR/", "llvm/lib/Transforms/"],
            searchSymbols: ["ParseAST", "CodeGenModule", "IRBuilder", "PassManager"],
            tasks: [
                "用 clang -cc1 -emit-llvm 生成一个函数的 IR，逐行解释。",
                "追踪 AST 节点如何进入 CodeGen 并构造 IRBuilder 调用。",
                "找出一个优化 pass 的输入、输出和注册位置。",
                "比较 O0 与 O2 的 IR，说明至少一项变化的原因。"
            ],
            evidence: ["C 与 IR 对照", "AST/CodeGen 调用链", "优化前后差异"],
            checkpoints: ["能生成并读 IR", "能定位 CodeGen", "能识别优化 pass", "能解释一个差异"],
            pitfalls: ["直接读数百万行代码却没有最小输入", "混淆 Clang AST 与 LLVM IR", "把优化结果当成语言语义"],
            reflectionQuestion: "为什么编译器需要一个独立于源语言和目标机器的 IR？",
            relatedProjectIDs: ["mini-compiler", "storage-engine"]
        ),
        OpenSourceReadingMission(
            id: "oss-swift",
            level: .languageRuntime,
            order: 10,
            title: "Swift：标准库、SIL 与 IRGen",
            repoName: "swiftlang/swift",
            repositoryURL: "https://github.com/swiftlang/swift",
            language: "Swift/C++",
            license: "Apache-2.0",
            estimatedMinutes: 180,
            summary: "从 Array/String 的公开接口追到 SIL 和 IRGen，建立 Swift 性能与语言实现阅读入口。",
            prerequisites: ["熟练使用 Swift 值类型和协议", "能读懂 Swift Package 或 Xcode 构建日志"],
            entryPoints: ["stdlib/public/core/", "lib/SIL/", "lib/Sema/", "lib/IRGen/"],
            searchSymbols: ["_ArrayBuffer", "String", "SILFunction", "IRGenModule"],
            tasks: [
                "选择一个 Array 或 String 操作，找到公开接口和标准库实现。",
                "用 swiftc -emit-sil 观察一个值类型操作，记录 SIL 级别变化。",
                "定位类型检查和协议 witness 相关目录，说明职责边界。",
                "用 -emit-ir 或优化级别比较一份最小 Swift 程序。"
            ],
            evidence: ["公开 API 到实现路径", "SIL/IR 片段", "类型与优化边界说明"],
            checkpoints: ["能定位标准库实现", "能生成并读 SIL", "能定位 IRGen", "能解释性能取舍"],
            pitfalls: ["把 Swift 源码等同于最终机器码", "忽略优化级别和所有权", "只看标准库不看编译器阶段"],
            reflectionQuestion: "为什么值类型语义不等于每次操作都会复制内存？",
            relatedProjectIDs: ["study-log-app", "mini-compiler"]
        )
    ]

    static func mission(id: String) -> OpenSourceReadingMission? {
        missions.first { $0.id == id }
    }

    static func missions(in level: OpenSourceReadingLevel) -> [OpenSourceReadingMission] {
        missions.filter { $0.level == level }.sorted { $0.order < $1.order }
    }

    static func stageProgressID(missionID: String, stage: Int) -> String {
        "open-source:\(missionID):stage:\(stage)"
    }

    static func checkpointProgressID(missionID: String, checkpointIndex: Int) -> String {
        "open-source:\(missionID):checkpoint:\(checkpointIndex)"
    }

    static func evidenceTargetID(_ missionID: String) -> String {
        "open-source:\(missionID):evidence"
    }
}

struct OpenSourceReadingEvidence: Codable, Equatable {
    var repositorySnapshot = ""
    var entryPointNotes = ""
    var callChain = ""
    var rawEvidence = ""
    var unresolvedQuestions = ""
    var reflection = ""

    static let empty = OpenSourceReadingEvidence()
}

enum OpenSourceReadingEvidenceCodec {
    private static let prefix = "CS-OPEN-SOURCE-READING-V1\n"

    static func encode(_ evidence: OpenSourceReadingEvidence) -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        guard let data = try? encoder.encode(evidence),
              let json = String(data: data, encoding: .utf8) else {
            return prefix
        }
        return prefix + json
    }

    static func decode(_ text: String) -> OpenSourceReadingEvidence {
        guard text.hasPrefix(prefix) else { return .empty }
        let json = String(text.dropFirst(prefix.count))
        guard let data = json.data(using: .utf8),
              let evidence = try? JSONDecoder().decode(OpenSourceReadingEvidence.self, from: data) else {
            return .empty
        }
        return evidence
    }
}
