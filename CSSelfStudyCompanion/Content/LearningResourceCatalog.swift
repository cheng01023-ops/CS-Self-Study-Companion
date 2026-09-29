import Foundation

enum LearningResourceCatalog {
    static let all: [LearningResourceSeed] = [
        resource("r-missing-semester", "tutorial-mac-terminal", "The Missing Semester of Your CS Education", "MIT", "https://missing.csail.mit.edu/", "系统讲解 Shell、命令行环境、Git、调试和开发工具，非常适合在完成阶段 0 后作为第一份系统补充。", "English", "入门"),
        resource("r-terminal-guide", "tutorial-mac-terminal", "Apple Terminal 用户指南", "Apple", "https://support.apple.com/guide/terminal/welcome/mac", "官方说明 macOS Terminal 的窗口、标签、快捷键和基础操作，适合边操作边查阅。", "中文/English", "入门"),
        resource("r-pro-git", "tutorial-mac-terminal", "Pro Git 中文版", "Git", "https://git-scm.com/book/zh/v2", "免费 Git 教材，重点阅读第 1–3 章，建立提交、分支、合并和远程仓库的基本模型。", "中文", "入门"),

        resource("r-cs50", "tutorial-computer-basics", "CS50x", "Harvard University", "https://cs50.harvard.edu/x/", "从二进制、抽象、算法到 C、内存和 Web 的完整入门课程，适合作为计算机通识的主干课程。", "English", "入门"),
        resource("r-nand2tetris", "tutorial-computer-basics", "Nand2Tetris", "Hebrew University", "https://www.nand2tetris.org/", "从逻辑门一路构建到 CPU、汇编、虚拟机和编译器，帮助理解抽象层次如何逐层建立。", "English", "入门到进阶"),
        resource("r-bottom-up-cs", "tutorial-computer-basics", "Computer Science from the Bottom Up", "Ian Wienand", "https://www.bottomupcs.com/", "从二进制、机器、操作系统和网络逐层向上解释计算机系统，适合配合 CPU 与内存章节阅读。", "English", "入门"),

        resource("r-cppreference-c", "tutorial-c-foundation", "cppreference C 语言参考", "cppreference", "https://en.cppreference.com/w/c", "C 标准库、类型、指针和关键字的高质量参考，遇到不确定的函数签名或行为时优先查这里。", "中文/English", "查阅"),
        resource("r-beej-c", "tutorial-c-foundation", "Beej's Guide to C Programming", "Brian Hall", "https://beej.us/guide/bgc/", "通俗讲解 C 的类型、数组、结构体、指针和文件 I/O，示例短而完整，适合配合教程逐章练习。", "English", "入门"),
        resource("r-glibc-manual", "tutorial-c-foundation", "GNU C Library Manual", "GNU Project", "https://www.gnu.org/software/libc/manual/", "标准库函数、错误码和系统接口的权威说明，适合作为 C 代码调试和查漏补缺的长期参考。", "English", "进阶/查阅"),

        resource("r-ubuntu-server-install", "tutorial-linux-l0", "Ubuntu Server 安装教程", "Canonical", "https://ubuntu.com/tutorials/install-ubuntu-server", "官方安装流程，覆盖虚拟机、网络、用户和安装选项，适合作为 L0 环境搭建的第一手资料。", "English", "入门"),
        resource("r-docker-start", "tutorial-linux-l0", "Docker Get Started", "Docker", "https://docs.docker.com/get-started/", "理解镜像、容器、端口和卷的最短路径，适合快速获得一个可练习的 Linux 环境。", "中文/English", "入门"),
        resource("r-ssh-academy", "tutorial-linux-l0", "SSH Academy", "SSH Communications", "https://www.ssh.com/academy/ssh", "介绍 SSH 密钥、认证、端口转发和安全配置，适合与 SSH 登录实验配合使用。", "English", "入门"),

        resource("r-ubuntu-cli", "tutorial-linux-l1", "Ubuntu 命令行入门", "Canonical", "https://ubuntu.com/tutorials/command-line-for-beginners", "覆盖目录、文件、权限、用户和 apt 的官方入门教程，适合 L1 逐项对照操作。", "English", "入门"),
        resource("r-linux-journey", "tutorial-linux-l1", "Linux Journey", "Linux Journey", "https://linuxjourney.com/", "以短课程组织 Linux 基础命令和概念，适合每天完成一个小节并复述命令用途。", "English", "入门"),
        resource("r-man-pages", "tutorial-linux-l1", "Linux man-pages", "Linux man-pages project", "https://man7.org/linux/man-pages/", "命令和系统调用接口的权威参考；遇到参数、错误码和行为差异时，应优先查这里。", "English", "查阅"),

        resource("r-bash-manual", "tutorial-linux-l2", "GNU Bash Manual", "GNU Project", "https://www.gnu.org/software/bash/manual/bash.html", "Shell 变量、展开、条件、循环、函数和重定向的官方资料，适合精读参数展开与错误处理章节。", "English", "进阶"),
        resource("r-gnu-sed", "tutorial-linux-l2", "GNU sed Manual", "GNU Project", "https://www.gnu.org/software/sed/manual/sed.html", "系统说明 sed 的地址、替换、删除和流处理，适合配合日志清洗实验。", "English", "查阅"),
        resource("r-gnu-awk", "tutorial-linux-l2", "GNU Awk Manual", "GNU Project", "https://www.gnu.org/software/gawk/manual/gawk.html", "讲解字段、模式、数组和报表统计，适合用真实日志完成计数、求和和格式化输出。", "English", "进阶"),

        resource("r-systemd", "tutorial-linux-l3", "systemd Manuals", "systemd", "https://www.freedesktop.org/software/systemd/man/latest/", "服务单元、journalctl、定时器和资源控制的官方文档，适合部署自己的后台服务时查阅。", "English", "进阶"),
        resource("r-linux-sysadmin", "tutorial-linux-l3", "The Linux System Administrator's Guide", "The Linux Documentation Project", "https://tldp.org/LDP/sag/html/index.html", "覆盖进程、用户、文件系统、网络和服务管理的传统系统管理指南。", "English", "进阶"),
        resource("r-ufw", "tutorial-linux-l3", "Ubuntu UFW Community Documentation", "Ubuntu Community", "https://help.ubuntu.com/community/UFW", "UFW 防火墙的使用说明和示例，适合理解默认拒绝、服务放行和来源限制。", "English", "进阶"),

        resource("r-ostep", "tutorial-linux-l4", "Operating Systems: Three Easy Pieces", "University of Wisconsin", "https://pages.cs.wisc.edu/~remzi/OSTEP/", "免费操作系统教材，系统讲解虚拟化、并发、持久化和文件系统，是阶段 6 的核心资料。", "English", "进阶"),
        resource("r-beej-ipc", "tutorial-linux-l4", "Beej's Guide to Interprocess Communication", "Brian Hall", "https://beej.us/guide/bgipc/", "用完整 C 示例讲解管道、FIFO、共享内存和信号，适合边读边在 Linux 上运行。", "English", "进阶"),
        resource("r-tlpi", "tutorial-linux-l4", "The Linux Programming Interface", "Michael Kerrisk", "https://man7.org/tlpi/", "Linux 系统编程权威参考；书中代码和目录可用于系统调用、进程、线程和 IPC 的深入查阅。", "English", "高级/查阅"),

        resource("r-beej-network", "tutorial-linux-l5", "Beej's Guide to Network Programming", "Brian Hall", "https://beej.us/guide/bgnet/", "从 socket API 到 TCP/UDP 客户端的经典免费指南，特别适合配合 C HTTP 服务器项目阅读。", "English", "进阶"),
        resource("r-mdn-http", "tutorial-linux-l5", "MDN HTTP Overview", "Mozilla", "https://developer.mozilla.org/en-US/docs/Web/HTTP", "清晰解释请求方法、状态码、头部、缓存和连接，适合配合抓包实验理解协议语义。", "中文/English", "入门到进阶"),
        resource("r-nginx-docs", "tutorial-linux-l5", "Nginx Documentation", "Nginx", "https://nginx.org/en/docs/", "Nginx 配置、反向代理、负载均衡和日志的官方资料，适合在实验室中逐项验证。", "English", "进阶"),
        resource("r-wireshark-docs", "tutorial-linux-l5", "Wireshark User's Guide", "Wireshark", "https://www.wireshark.org/docs/", "抓包过滤、协议解析和 TLS 观察的官方指南，建议先学习 capture filter 与 display filter 的区别。", "English", "进阶"),

        resource("r-kernel-docs", "tutorial-linux-l6", "/proc、sysfs 与内核文档", "Linux Kernel", "https://www.kernel.org/doc/html/latest/", "Linux 内核官方文档，覆盖文件系统、网络、驱动、性能和内核接口，适合按子系统查阅。", "English", "高级/查阅"),
        resource("r-perf", "tutorial-linux-l6", "perf Wiki", "Linux Kernel", "https://perf.wiki.kernel.org/index.php/Main_Page", "perf 事件、采样和热点分析资料，适合在建立性能基线后使用。", "English", "高级"),
        resource("r-strace", "tutorial-linux-l6", "strace Project", "strace", "https://strace.io/", "系统调用跟踪工具的主页和文档入口，适合确认程序实际访问的文件、网络和错误码。", "English", "进阶"),

        resource("r-docker-docs", "tutorial-linux-l7", "Docker Documentation", "Docker", "https://docs.docker.com/", "镜像、容器、网络、存储和安全配置的官方入口，适合从 Dockerfile 到 Compose 逐步学习。", "中文/English", "进阶"),
        resource("r-kubernetes-tutorials", "tutorial-linux-l7", "Kubernetes Tutorials", "Kubernetes", "https://kubernetes.io/docs/tutorials/", "从 Pod、Deployment 到 Service 的官方交互教程，建议先在小集群中逐项完成。", "中文/English", "进阶"),
        resource("r-namespaces", "tutorial-linux-l7", "Linux Namespaces man page", "man7", "https://man7.org/linux/man-pages/man7/namespaces.7.html", "权威解释 PID、mount、network、UTS、user 等 namespace，帮助把容器从黑盒变成清晰的隔离模型。", "English", "高级"),

        resource("r-owasp-top10", "tutorial-linux-l8", "OWASP Top 10", "OWASP", "https://owasp.org/www-project-top-ten/", "Web 安全风险清单和修复资料，适合检查输入、认证、权限、日志和依赖风险。", "中文/English", "进阶"),
        resource("r-apparmor", "tutorial-linux-l8", "AppArmor Documentation", "AppArmor", "https://gitlab.com/apparmor/apparmor/-/wikis/Documentation", "Ubuntu 常用强制访问控制的配置和排错资料，适合研究进程可以访问哪些文件和资源。", "English", "高级"),
        resource("r-ufw-security", "tutorial-linux-l8", "Ubuntu Security Documentation", "Ubuntu", "https://documentation.ubuntu.com/security/", "Ubuntu 安全更新、权限和加固相关资料，适合建立服务器安全检查清单。", "English", "进阶"),

        resource("r-visualgo", "tutorial-dsa", "VisuAlgo", "VisuAlgo", "https://visualgo.net/en", "用动画观察排序、树、图、哈希和查找等算法执行过程，适合在阅读伪代码后对照操作。", "中文/English", "入门到进阶"),
        resource("r-opendsa", "tutorial-dsa", "OpenDSA", "OpenDSA", "https://opendsa-server.cs.vt.edu/ODSA/Books/CS3/html/", "开放教材与互动练习结合，覆盖数据结构、排序、树、图和时间复杂度。", "English", "进阶"),
        resource("r-cp-algorithms", "tutorial-dsa", "cp-algorithms", "cp-algorithms", "https://cp-algorithms.com/", "算法实现和复杂度推导资料，适合在掌握基础后研究图算法、字符串和高级数据结构。", "English", "高级"),

        resource("r-csapp", "tutorial-architecture", "CS:APP Course Materials", "Carnegie Mellon University", "https://www.cs.cmu.edu/~213/", "从 C 程序出发理解机器表示、汇编、链接、缓存和并发，适合配合课本实验。", "English", "进阶"),
        resource("r-nand2tetris-arch", "tutorial-architecture", "Nand2Tetris Hardware", "Nand2Tetris", "https://www.nand2tetris.org/", "从逻辑门构建 CPU 和计算机，适合补足寄存器、指令和硬件抽象的直觉。", "English", "入门到进阶"),
        resource("r-compiler-explorer", "tutorial-architecture", "Compiler Explorer", "Godbolt", "https://godbolt.org/", "在线观察不同编译器和优化级别生成的汇编，非常直观地验证栈帧、寄存器和优化行为。", "English", "进阶"),

        resource("r-ostep-os", "tutorial-os-systems", "OSTEP：Operating Systems", "University of Wisconsin", "https://pages.cs.wisc.edu/~remzi/OSTEP/", "进程、线程、调度、虚拟内存、文件和并发章节完整，适合与 C 系统调用实验对照学习。", "English", "进阶"),
        resource("r-mit-6s081", "tutorial-os-systems", "MIT 6.S081 Operating System Engineering", "MIT", "https://pdos.csail.mit.edu/6.S081/2024/", "通过 xv6 和实验理解内核、进程、页表、文件系统和系统调用。", "English", "高级"),
        resource("r-man7", "tutorial-os-systems", "man7.org", "Michael Kerrisk", "https://man7.org/", "系统调用、C 库和 Linux 手册页的集中入口，适合遇到接口歧义时查阅。", "English", "查阅"),

        resource("r-beej-net", "tutorial-networking", "Beej's Guide to Network Programming", "Brian Hall", "https://beej.us/guide/bgnet/", "C Socket API 的经典教程，包含 TCP、UDP、地址解析和错误处理。", "English", "进阶"),
        resource("r-rfc9110", "tutorial-networking", "RFC 9110：HTTP Semantics", "IETF", "https://www.rfc-editor.org/rfc/rfc9110.html", "HTTP 方法、状态码、字段语义的标准文本，适合深入理解服务器响应设计。", "English", "高级/查阅"),
        resource("r-tcpdump", "tutorial-networking", "tcpdump Manual", "tcpdump", "https://www.tcpdump.org/manpages/tcpdump.1.html", "抓包命令和过滤表达式手册，适合边构造过滤器边观察真实数据包。", "English", "进阶"),
        resource("r-cloudflare-http", "tutorial-networking", "MDN HTTP Overview", "Mozilla", "https://developer.mozilla.org/en-US/docs/Web/HTTP/Overview", "从浏览器请求角度解释 HTTP，适合作为协议术语的快速补充阅读。", "English", "入门"),

        resource("r-crafting-interpreters", "tutorial-compiler", "Crafting Interpreters", "Robert Nystrom", "https://craftinginterpreters.com/", "从扫描、解析、AST 到字节码虚拟机完整实现两门解释器，和本教程的编译流水线高度对应。", "English", "高级"),
        resource("r-llvm-kaleidoscope", "tutorial-compiler", "LLVM Kaleidoscope Tutorial", "LLVM", "https://llvm.org/docs/tutorial/MyFirstLanguageFrontend/index.html", "实现一个小语言并生成 LLVM IR，适合理解 AST、IR 和后端代码生成。", "English", "高级"),
        resource("r-compiler-explorer-ir", "tutorial-compiler", "Compiler Explorer", "Godbolt", "https://godbolt.org/", "可以观察前端、IR 和目标汇编变化，建议用于比较不同优化级别下的代码生成。", "English", "进阶"),

        resource("r-sqlite-docs", "tutorial-database", "SQLite Documentation", "SQLite", "https://sqlite.org/docs.html", "轻量数据库的 SQL、事务、索引和文件格式文档，适合本地立即验证数据库概念。", "English", "入门到进阶"),
        resource("r-postgres-tutorial", "tutorial-database", "PostgreSQL Tutorial", "PostgreSQL", "https://www.postgresql.org/docs/current/tutorial.html", "官方 SQL 教程，覆盖查询、连接、聚合、事务和并发基础。", "中文/English", "入门到进阶"),
        resource("r-index-luke", "tutorial-database", "Use The Index, Luke!", "Markus Winand", "https://use-the-index-luke.com/", "用执行计划解释索引、最左前缀、排序和查询性能，适合优化真实数据库查询。", "English", "进阶"),
        resource("r-cmu-db", "tutorial-database", "CMU 15-445 Database Systems", "Carnegie Mellon University", "https://15445.courses.cs.cmu.edu/", "覆盖存储引擎、索引、事务、恢复和查询执行的大学课程资料。", "English", "高级"),

        resource("r-apple-dev", "tutorial-specialization", "Apple Developer Documentation", "Apple", "https://developer.apple.com/documentation/", "SwiftUI、Foundation、SwiftData 和平台框架的官方入口，发布前应优先核对 API 文档。", "中文/English", "进阶/查阅"),
        resource("r-swift-book", "tutorial-specialization", "The Swift Programming Language", "Apple", "https://docs.swift.org/swift-book/documentation/the-swift-programming-language/", "Swift 语言官方教材，适合补足类型、协议、并发、错误处理和泛型基础。", "中文/English", "入门到进阶"),
        resource("r-freertos", "tutorial-specialization", "FreeRTOS Book", "FreeRTOS", "https://www.freertos.org/Documentation/RTOS_book.html", "嵌入式实时系统的任务、调度、队列、信号量和内存管理教材。", "English", "高级"),
        resource("r-system-design", "tutorial-specialization", "System Design Primer", "GitHub", "https://github.com/donnemartin/system-design-primer", "开源系统设计资料，适合后端方向理解缓存、负载均衡、数据库和可扩展性。", "中文/English", "高级"),
        resource("r-kernel-specialization", "tutorial-specialization", "Linux Kernel Documentation", "Linux Kernel", "https://www.kernel.org/doc/html/latest/", "内核、驱动、调度、内存和文件系统的官方入口，适合选择内核方向后深入阅读。", "English", "高级")
    ]

    private static func resource(
        _ id: String,
        _ tutorialID: String,
        _ title: String,
        _ provider: String,
        _ url: String,
        _ explanation: String,
        _ language: String,
        _ difficulty: String
    ) -> LearningResourceSeed {
        LearningResourceSeed(
            id: id,
            tutorialID: tutorialID,
            title: title,
            provider: provider,
            urlString: url,
            explanation: explanation,
            language: language,
            difficulty: difficulty,
            order: 0
        )
    }
}
