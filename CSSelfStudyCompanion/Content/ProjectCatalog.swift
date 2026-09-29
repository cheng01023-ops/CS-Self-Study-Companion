import Foundation

struct ProjectMilestone: Identifiable {
    let id: String
    let title: String
    let detail: String
}

struct LearningProject: Identifiable {
    let id: String
    let title: String
    let summary: String
    let level: String
    let icon: String
    let themeHex: String
    let tags: [String]
    let deliverables: [String]
    let milestones: [ProjectMilestone]
}

enum ProjectCatalog {
    static let projects: [LearningProject] = [
        LearningProject(
            id: "cli-contacts",
            title: "命令行通讯录",
            summary: "用 C 结构体、文件读写和命令行参数完成可持久化的联系人工具。",
            level: "入门",
            icon: "person.2.fill",
            themeHex: "4F7CFF",
            tags: ["C", "文件", "结构体"],
            deliverables: ["源码", "示例数据", "README", "三个边界测试"],
            milestones: [
                ProjectMilestone(id: "model", title: "定义联系人和存储模型", detail: "明确字段、最大长度、唯一性和错误返回码。"),
                ProjectMilestone(id: "crud", title: "实现新增、查找和删除", detail: "使用结构体数组和文件持久化，处理重复姓名与空输入。"),
                ProjectMilestone(id: "cli", title: "完成命令行接口", detail: "支持 add、list、find、delete 子命令和清晰用法提示。"),
                ProjectMilestone(id: "accept", title: "完成验收与复盘", detail: "覆盖空文件、损坏数据和越界输入，记录一次错误修复。")
            ]
        ),
        LearningProject(
            id: "file-integrity",
            title: "文件校验工具",
            summary: "实现文件复制、大小统计、简单校验和错误恢复的终端工具。",
            level: "入门",
            icon: "checkmark.shield.fill",
            themeHex: "16A085",
            tags: ["C", "系统调用", "文件 I/O"],
            deliverables: ["可执行程序", "测试文件", "错误处理说明"],
            milestones: [
                ProjectMilestone(id: "io", title: "实现分块读写", detail: "正确处理 read/write 部分完成、EINTR 和 EOF。"),
                ProjectMilestone(id: "checksum", title: "加入简单校验和", detail: "对文件字节计算校验并输出十六进制结果。"),
                ProjectMilestone(id: "recover", title: "处理失败恢复", detail: "目标文件写入失败时清理临时文件，不留下半成品。"),
                ProjectMilestone(id: "accept", title: "验证不同大小文件", detail: "测试空文件、单字节、跨缓冲区和权限不足。")
            ]
        ),
        LearningProject(
            id: "mini-shell",
            title: "迷你 Shell",
            summary: "通过 fork、exec、wait、管道和重定向理解 Shell 的底层工作方式。",
            level: "进阶",
            icon: "terminal.fill",
            themeHex: "8E44AD",
            tags: ["C", "fork/exec", "管道"],
            deliverables: ["支持管道和重定向的 Shell", "进程回收测试", "信号处理说明"],
            milestones: [
                ProjectMilestone(id: "prompt", title: "实现提示符和命令解析", detail: "读取命令、拆分参数，并支持 exit 退出。"),
                ProjectMilestone(id: "fork", title: "实现 fork/exec/wait", detail: "正确回收子进程并返回真实退出状态。"),
                ProjectMilestone(id: "pipe", title: "加入管道和重定向", detail: "使用 pipe、dup2 组合多个命令。"),
                ProjectMilestone(id: "accept", title: "完成 Shell 验收", detail: "验证空命令、错误程序、管道失败和 Ctrl+C。")
            ]
        ),
        LearningProject(
            id: "tcp-chat",
            title: "TCP 聊天室",
            summary: "用 socket、线程或事件循环实现多人聊天和优雅断开。",
            level: "进阶",
            icon: "message.fill",
            themeHex: "2D98DA",
            tags: ["网络", "Socket", "并发"],
            deliverables: ["TCP 服务器", "客户端", "协议说明", "压力测试记录"],
            milestones: [
                ProjectMilestone(id: "protocol", title: "定义消息协议", detail: "明确长度、昵称、正文和断开消息，处理粘包与半包。"),
                ProjectMilestone(id: "server", title: "实现多客户端服务器", detail: "管理连接列表并广播消息，安全处理关闭。"),
                ProjectMilestone(id: "client", title: "实现客户端", detail: "接收用户输入、显示消息并支持退出。"),
                ProjectMilestone(id: "accept", title: "完成网络验收", detail: "测试断开、重复昵称、消息过长和并发连接。")
            ]
        ),
        LearningProject(
            id: "task-pool",
            title: "并发任务池",
            summary: "实现线程池、任务队列、关闭协议和资源回收。",
            level: "高级",
            icon: "cpu.fill",
            themeHex: "D35400",
            tags: ["pthread", "队列", "同步"],
            deliverables: ["线程池", "任务接口", "压力测试", "死锁排查记录"],
            milestones: [
                ProjectMilestone(id: "queue", title: "实现线程安全任务队列", detail: "使用互斥锁和条件变量，支持阻塞取出与关闭。"),
                ProjectMilestone(id: "workers", title: "实现工作线程", detail: "循环取任务、执行并安全处理异常返回。"),
                ProjectMilestone(id: "shutdown", title: "实现优雅关闭", detail: "等待队列完成或允许立即取消，并 join 所有线程。"),
                ProjectMilestone(id: "accept", title: "完成并发验收", detail: "测试空任务、高并发、关闭重复和内存回收。")
            ]
        ),
        LearningProject(
            id: "mini-compiler",
            title: "表达式编译器",
            summary: "从词法、语法、AST 到栈式解释器，完成一个计算器语言。",
            level: "高级",
            icon: "textformat.abc.dottedunderline",
            themeHex: "9B59B6",
            tags: ["编译原理", "AST", "IR"],
            deliverables: ["Lexer", "Parser", "AST", "解释器", "错误定位"],
            milestones: [
                ProjectMilestone(id: "lexer", title: "实现词法分析器", detail: "识别数字、括号、四则运算和错误字符。"),
                ProjectMilestone(id: "parser", title: "实现递归下降解析器", detail: "正确处理优先级、结合性和括号。"),
                ProjectMilestone(id: "ast", title: "构造并解释 AST", detail: "计算表达式并处理除零和非法语法。"),
                ProjectMilestone(id: "accept", title: "完成编译验收", detail: "测试嵌套表达式、空输入、超长输入和错误提示。")
            ]
        )
    ]
}
