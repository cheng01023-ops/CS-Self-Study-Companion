import Foundation

enum CatalogAdvanced {
    static let stages: [LearningStageSeed] = [
        LearningStageSeed(
            id: "stage-8",
            order: 8,
            title: "编译原理",
            subtitle: "让源代码经过词法、语法、语义和代码生成，变成可执行语义。",
            icon: "textformat.abc.dottedunderline",
            themeHex: "9B59B6",
            topics: [
                LearningTopicSeed(
                    id: "topic-compiler",
                    order: 1,
                    title: "从词法分析到代码生成",
                    summary: "实现一个小型表达式语言的完整编译流水线。",
                    estimatedMinutes: 360,
                    tutorials: [
                        LearningTutorialSeed(
                            id: "tutorial-compiler",
                            order: 1,
                            title: "编译器把文本变成结构",
                            summary: "理解 token、语法、AST、IR 和代码生成，并手写一个词法分析器。",
                            markdown: #"""
# 编译器解决什么问题

编译器把源语言程序转换成目标语言或机器码，过程中必须检查语法和语义，并保持程序行为符合语言规范。典型前端包括词法分析、语法分析、语义分析、中间表示；后端包括优化、寄存器分配、指令选择和代码生成。学习编译原理不只是写编译器，也能帮助你设计配置语言、查询语言和解析器。

## 词法分析

词法分析器把字符流切成 token，例如标识符、整数、加号、括号和文件结束符。长匹配优先：`==` 必须识别为一个相等运算符，而不是两个 `=`。空白通常丢弃，但要记录行号列号用于报错。正则表达式适合描述 token，手写状态机适合控制和性能。

## 语法分析

语法定义 token 如何组合成表达式和语句。上下文无关文法常写成产生式：`expression → term (('+' | '-') term)*`。递归下降解析器为每个非终结符写一个函数，适合 LL(1) 文法；运算符优先级高的规则调用更底层规则。解析结果可以是具体语法树，但编译器通常构造更简洁的抽象语法树 AST。

AST 用结构体或类表示，例如 `Binary(left, op, right)` 和 `Number(value)`。节点不应携带所有文本细节，但可以保留源位置用于诊断。解析器遇到错误时不应无限循环，必须消费至少一个 token 或进入恢复模式。

## 语义分析与符号表

词法语法都正确不代表程序有意义。语义阶段检查变量是否声明、类型是否匹配、函数参数是否正确、是否重复定义。符号表保存作用域中的名字和类型。类型系统可以简单到只有整数和布尔值，也可以复杂到泛型和生命周期。诊断信息应给出位置、原因和可能的修复方案。

## IR 与代码生成

中间表示 IR 介于源代码和目标机器之间，便于优化和跨平台。常见形式有三地址码：`t1 = a + b`、`t2 = t1 * c`。SSA 进一步要求每个变量只赋值一次，方便数据流分析。优化包括常量折叠、常量传播、死代码删除和公共子表达式消除。代码生成把 IR 映射到目标指令，简单栈式虚拟机最容易起步：数字压栈，运算符弹两个值计算后压回。

## 最小项目路线

第一版只支持整数、四则运算和括号。先写 token 和 lexer，再用单元测试验证每个 token；接着写递归下降 parser，把结果打印成括号化表达式；然后做 AST 解释器；最后加入变量、赋值和错误行号。不要一开始支持类、泛型和优化，编译器是逐步扩展出来的。

测试要覆盖正确输入、空输入、非法字符、缺失右括号、除零和超长表达式。编译器错误信息要稳定可读，因为工具的使用者是人。
"""#,
                            codeLanguage: "c",
                            code: #"""
// 最小词法分析器：识别整数、运算符、括号
#include <ctype.h>
#include <stdio.h>
#include <stdlib.h>

typedef enum {
    TOKEN_NUMBER,
    TOKEN_PLUS,
    TOKEN_MINUS,
    TOKEN_STAR,
    TOKEN_SLASH,
    TOKEN_LPAREN,
    TOKEN_RPAREN,
    TOKEN_EOF,
    TOKEN_INVALID
} TokenKind;

typedef struct {
    TokenKind kind;
    long number;
    size_t position;
} Token;

static Token next_token(const char *source, size_t *position) {
    while (isspace((unsigned char)source[*position])) {
        (*position)++;
    }

    size_t start = *position;
    char current = source[(*position)++];

    if (current == '\0') return (Token){TOKEN_EOF, 0, start};
    if (isdigit((unsigned char)current)) {
        long value = current - '0';
        while (isdigit((unsigned char)source[*position])) {
            value = value * 10 + (source[(*position)++] - '0');
        }
        return (Token){TOKEN_NUMBER, value, start};
    }

    switch (current) {
        case '+': return (Token){TOKEN_PLUS, 0, start};
        case '-': return (Token){TOKEN_MINUS, 0, start};
        case '*': return (Token){TOKEN_STAR, 0, start};
        case '/': return (Token){TOKEN_SLASH, 0, start};
        case '(': return (Token){TOKEN_LPAREN, 0, start};
        case ')': return (Token){TOKEN_RPAREN, 0, start};
        default: return (Token){TOKEN_INVALID, 0, start};
    }
}

int main(void) {
    const char *source = "12 + 30 * (4 - 1)";
    size_t position = 0;
    Token token;
    do {
        token = next_token(source, &position);
        printf("kind=%d position=%zu", token.kind, token.position);
        if (token.kind == TOKEN_NUMBER) printf(" value=%ld", token.number);
        putchar('\n');
    } while (token.kind != TOKEN_EOF && token.kind != TOKEN_INVALID);
    return token.kind == TOKEN_INVALID ? 1 : 0;
}
"""#,
                            secondCodeLanguage: "swift",
                            secondCode: #"""
// AST 与解释器思想：Swift 版本只演示结构
indirect enum Expression {
    case number(Int)
    case binary(Expression, String, Expression)
}

func evaluate(_ expression: Expression) -> Int {
    switch expression {
    case let .number(value):
        return value
    case let .binary(left, operation, right):
        let lhs = evaluate(left)
        let rhs = evaluate(right)
        switch operation {
        case "+": return lhs + rhs
        case "-": return lhs - rhs
        case "*": return lhs * rhs
        default: fatalError("未知运算符")
        }
    }
}

let tree = Expression.binary(.number(2), "+", .binary(.number(3), "*", .number(4)))
print(evaluate(tree)) // 14
"""#,
                            commonMistakes: #"""
- 词法分析时把多字符运算符拆成单字符。
- 递归下降解析器遇到非法 token 不前进，造成死循环。
- AST 节点混淆值、变量和类型，语义阶段难以检查。
- 忽略源位置，错误信息只能显示“语法错误”。
- 过早加入优化，基础解析和测试尚未稳定。
"""#
                        )
                    ],
                    exercises: [
                        LearningExerciseSeed(
                            id: "exercise-compiler-choice",
                            order: 1,
                            title: "判断编译阶段",
                            kind: .multipleChoice,
                            question: "判断 `if (` 后缺少条件表达式，属于哪个阶段最容易发现的错误？",
                            options: ["词法分析", "语法分析", "链接", "运行"],
                            answer: "语法分析",
                            explanation: "词法分析能得到 if 和左括号 token，但它们不符合语法产生式，因此在语法分析阶段报错。"
                        ),
                        LearningExerciseSeed(
                            id: "exercise-compiler-code",
                            order: 2,
                            title: "扩展词法分析器",
                            kind: .coding,
                            question: "在示例词法分析器中加入比较运算符 `<`、`>`、`==`，并正确处理双字符 `==`。",
                            answer: #"""
typedef enum {
    TOKEN_NUMBER, TOKEN_PLUS, TOKEN_MINUS, TOKEN_STAR, TOKEN_SLASH,
    TOKEN_LPAREN, TOKEN_RPAREN, TOKEN_LT, TOKEN_GT, TOKEN_EQ,
    TOKEN_EOF, TOKEN_INVALID
} TokenKind;

static Token next_operator(const char *source, size_t *position, size_t start) {
    if (*position >= start + 1) {
        char current = source[*position - 1];
        if (current == '<') return (Token){TOKEN_LT, 0, start};
        if (current == '>') return (Token){TOKEN_GT, 0, start};
        if (current == '=' && source[*position] == '=') {
            (*position)++;
            return (Token){TOKEN_EQ, 0, start};
        }
    }
    return (Token){TOKEN_INVALID, 0, start};
}
"""#,
                            explanation: "识别 `==` 的关键是看到第一个 `=` 后再查看下一个字符并消费它。真实语言还要处理 `!=`、`<=`、`>=` 和赋值 `=`。",
                            starterCode: "// 复用教程中的 next_token，加入 < > ==\n",
                            codeLanguage: "c"
                        )
                    ]
                )
            ]
        ),
        LearningStageSeed(
            id: "stage-9",
            order: 9,
            title: "数据库系统",
            subtitle: "理解数据如何持久化、索引、并发和恢复。",
            icon: "cylinder.split.1x2",
            themeHex: "D35400",
            topics: [
                LearningTopicSeed(
                    id: "topic-database",
                    order: 1,
                    title: "SQL、索引、事务与存储引擎",
                    summary: "从查询语句进入 B+ 树、事务隔离、锁和日志恢复。",
                    estimatedMinutes: 360,
                    tutorials: [
                        LearningTutorialSeed(
                            id: "tutorial-database",
                            order: 1,
                            title: "数据库不会丢数据的原因",
                            summary: "用 SQL、索引、事务和 WAL 串联数据库的核心机制。",
                            markdown: #"""
# 数据库的职责

数据库不只是存文件。它提供结构化查询、并发控制、崩溃恢复、权限和一致性。应用开发者必须理解事务边界和索引，否则会出现慢查询、重复数据和并发冲突。关系数据库用表、行、列和约束描述数据；SQL 是声明式语言，你描述想要的结果，查询优化器决定执行计划。

## SQL 基础

`SELECT` 查询，`INSERT` 插入，`UPDATE` 修改，`DELETE` 删除。`WHERE` 过滤，`JOIN` 组合表，`GROUP BY` 聚合，`ORDER BY` 排序。主键唯一标识行，外键保证引用完整性。NULL 表示未知，不能用 `= NULL` 判断，应使用 `IS NULL`。参数化查询把数据和 SQL 分开，能防止 SQL 注入。

## 索引

没有索引时，数据库可能扫描整张表。B+ 树索引按排序键组织数据，适合等值查询和范围查询。`WHERE email = ?` 在 email 上有索引时通常只访问少量页；在低选择性列上建索引收益有限。复合索引遵循最左前缀原则：索引 `(user_id, created_at)` 可服务 `user_id` 或 `user_id + created_at`，通常不能单独高效服务 `created_at`。索引会占空间并降低写入速度，所以要基于查询模式设计。

`EXPLAIN` 或 `EXPLAIN ANALYZE` 显示执行计划。看到全表扫描不一定坏，小表扫描可能比走索引更便宜；看到大量临时文件排序、估算行数严重偏差才值得排查。

## 事务与并发控制

事务具有 ACID：原子性、一致性、隔离性、持久性。`BEGIN` 开始，`COMMIT` 提交，`ROLLBACK` 回滚。经典隔离级别包括读未提交、读已提交、可重复读、串行化。并发异常有脏读、不可重复读、幻读和写偏斜。数据库通过锁、MVCC、快照等机制实现隔离；MVCC 让读不阻塞写，但长事务会保留旧版本，增加清理压力。

## 存储引擎与恢复

存储引擎负责页管理、缓存、索引、事务和日志。写入通常先写预写日志 WAL，再修改内存页，最后异步刷盘。崩溃后通过 redo 重放已提交更改，通过 undo 回滚未提交事务。B+ 树节点对应磁盘页，随机 I/O 昂贵，因此一次读取尽量拿一页数据是设计重点。

## 实践建议

用 SQLite 做本地练习：创建用户、订单表，插入数据，写带 JOIN 和 GROUP BY 的查询，用 EXPLAIN QUERY PLAN 观察索引。然后用两个终端模拟并发事务，观察锁和隔离级别。不要把“加了索引一定快”“事务越大越好”当规律，要用数据和执行计划验证。
"""#,
                            codeLanguage: "sql",
                            code: #"""
-- 建立订单和用户表
CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    email TEXT NOT NULL UNIQUE,
    name TEXT NOT NULL
);

CREATE TABLE orders (
    id INTEGER PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id),
    amount_cents INTEGER NOT NULL CHECK (amount_cents >= 0),
    created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_orders_user_created
ON orders(user_id, created_at DESC);

-- 统计每个用户的订单金额
SELECT u.name, COUNT(o.id) AS order_count, SUM(o.amount_cents) AS total_cents
FROM users AS u
LEFT JOIN orders AS o ON o.user_id = u.id
GROUP BY u.id
ORDER BY total_cents DESC;
"""#,
                            secondCodeLanguage: "sql",
                            secondCode: #"""
-- 事务示例：转账要么全部成功，要么全部回滚
BEGIN IMMEDIATE;

UPDATE accounts
SET balance_cents = balance_cents - 10000
WHERE id = 1 AND balance_cents >= 10000;

-- 应用层应检查受影响行数是否为 1
UPDATE accounts
SET balance_cents = balance_cents + 10000
WHERE id = 2;

COMMIT;
"""#,
                            commonMistakes: #"""
- 拼接用户输入生成 SQL，造成 SQL 注入；使用参数化查询。
- 为每一列都建索引，忽略写入成本和选择性。
- 长事务中途等待用户输入，阻塞清理和并发。
- 只测小数据集查询，生产数据量下才暴露问题。
- 把数据库文件复制当在线备份；需要事务一致的备份机制。
"""#
                        )
                    ],
                    exercises: [
                        LearningExerciseSeed(
                            id: "exercise-database-choice",
                            order: 1,
                            title: "理解索引前缀",
                            kind: .multipleChoice,
                            question: "已有复合索引 `(user_id, created_at)`，哪类查询通常最能利用它？",
                            options: ["只按 created_at 查询", "按 user_id 查询", "按 amount 查询", "按随机 UUID 排序"],
                            answer: "按 user_id 查询",
                            explanation: "复合 B+ 树通常按最左列组织，user_id 是前缀，可以高效定位；单独按 created_at 往往无法直接使用该索引。"
                        ),
                        LearningExerciseSeed(
                            id: "exercise-database-code",
                            order: 2,
                            title: "编写聚合查询",
                            kind: .coding,
                            question: "写 SQL 查询：统计每个用户已完成订单数量与总金额，只显示已完成订单，并按总金额降序。",
                            answer: #"""
SELECT
    u.id,
    u.name,
    COUNT(o.id) AS completed_count,
    COALESCE(SUM(o.amount_cents), 0) AS total_cents
FROM users AS u
LEFT JOIN orders AS o
    ON o.user_id = u.id
   AND o.status = 'completed'
GROUP BY u.id, u.name
ORDER BY total_cents DESC;
"""#,
                            explanation: "把 status 条件放在 JOIN 的 ON 子句中，可以保留没有已完成订单的用户；COALESCE 把 NULL 总额转为 0。",
                            starterCode: "SELECT u.name, COUNT(o.id)\nFROM users u\nLEFT JOIN orders o ON o.user_id = u.id\n-- 完成聚合和排序\n",
                            codeLanguage: "sql"
                        )
                    ]
                )
            ]
        ),
        LearningStageSeed(
            id: "stage-10",
            order: 10,
            title: "方向专精",
            subtitle: "在共同基础上选择嵌入式、后端、内核、安全或 Apple 平台方向。",
            icon: "scope",
            themeHex: "34495E",
            topics: [
                LearningTopicSeed(
                    id: "topic-specialization",
                    order: 1,
                    title: "选择方向并做作品",
                    summary: "比较五条路线的核心能力，并以一个可运行作品完成结业。",
                    estimatedMinutes: 300,
                    tutorials: [
                        LearningTutorialSeed(
                            id: "tutorial-specialization",
                            order: 1,
                            title: "从学习路线走向个人作品",
                            summary: "了解五条专精路线的差异，并用 SwiftUI + SwiftData 构建有持久化的作品。",
                            markdown: #"""
# 专精不是抛弃基础

阶段 0 到 9 建立的是共同底座：C、Linux、系统、网络、数据库和工程工具。专精决定你把时间投入到哪类问题。选择时不要只问“哪个薪资高”，还要看自己愿意长期调试什么：硬件、分布式请求、内核故障、攻击面，还是交互体验。

嵌入式方向深入 C/C++、寄存器、GPIO、RTOS、交叉编译、通信协议和功耗。后端方向深入数据库、缓存、消息队列、API 设计、可观测性和高并发。内核方向关注内存管理、调度、文件系统、驱动和补丁流程。安全方向需要网络、系统、密码学和逆向基础，必须坚持授权测试。iOS/macOS 方向关注 Swift、SwiftUI、平台框架、性能、无障碍和 App Store 生命周期。

## 一个合格的专精作品

作品必须有明确用户、可运行入口、错误处理和持久化/联网能力。不要只做演示页面。以“学习记录 App”为例，至少包含路线列表、详情、完成状态、搜索、重启后保留数据。先画数据模型，再写测试数据，然后做最小界面；只有核心闭环稳定后才添加动画和主题。

## SwiftUI 与 SwiftData

SwiftUI 是声明式 UI，视图描述界面在状态下的样子。`@State` 拥有本地值，`@Query` 读取 SwiftData，`NavigationStack` 管理页面栈，`NavigationLink` 或路径驱动跳转。数据模型用 `@Model` 标记，`modelContainer` 放在 App 场景上。关系删除规则决定删除父对象时子对象如何处理。

不要把业务数据全部塞进 View。页面负责展示和触发动作，服务负责持久化规则，模型负责关系与约束。代码量增长后，把视图拆成小组件，把通用样式和数据变换提取出来。

## 工程与发布

正式开发要使用 Git 分支和小提交，配置 Debug/Release，打开编译警告，处理空状态和无障碍。iOS 与 macOS 的交互不同：iOS 以触摸和窄屏为主，macOS 要考虑键盘、鼠标、窗口尺寸和多窗口。使用 `#if os(macOS)` 只在必须时隔离平台代码，优先使用跨平台 API。

性能问题先用 Instruments 测量。网络请求失败要给出可恢复提示，数据迁移要考虑旧版本用户。发布前检查 App Icon、隐私说明、权限用途和崩溃日志。

## 结业标准

给自己设一个可验收目标：从空目录开始，两周内完成可运行 App；代码进入 Git；README 写清安装、运行和已知问题；录一段三分钟演示；至少完成一次重构和一次性能改进。能独立安装依赖、定位错误、解释设计取舍，才算完成从教程到工程的转变。
"""#,
                            codeLanguage: "swift",
                            code: #"""
import SwiftData
import SwiftUI

@Model
final class StudyRecord {
    var title: String
    var isCompleted: Bool
    var createdAt: Date

    init(title: String, isCompleted: Bool = false, createdAt: Date = .now) {
        self.title = title
        self.isCompleted = isCompleted
        self.createdAt = createdAt
    }
}

struct StudyRecordList: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \StudyRecord.createdAt) private var records: [StudyRecord]

    var body: some View {
        List {
            ForEach(records) { record in
                Button {
                    record.isCompleted.toggle()
                    try? context.save()
                } label: {
                    Label(record.title, systemImage: record.isCompleted ? "checkmark.circle.fill" : "circle")
                }
            }
        }
        .toolbar {
            Button("添加", systemImage: "plus") {
                context.insert(StudyRecord(title: "新学习记录"))
                try? context.save()
            }
        }
    }
}
"""#,
                            secondCodeLanguage: "swift",
                            secondCode: #"""
import SwiftData
import SwiftUI

@main
struct StudyApp: App {
    var body: some Scene {
        WindowGroup {
            StudyRecordList()
        }
        .modelContainer(for: StudyRecord.self)
    }
}
"""#,
                            commonMistakes: #"""
- 只收藏教程不完成作品，缺少调试和设计经验。
- 选择方向后完全放弃 C、Linux 和网络基础。
- 在 View 中混入大量持久化和网络逻辑，难以测试。
- 只适配模拟器，不测试真机、键盘、窗口变化和离线状态。
- 发布前不处理隐私、权限和错误恢复。
"""#
                        )
                    ],
                    exercises: [
                        LearningExerciseSeed(
                            id: "exercise-specialization-choice",
                            order: 1,
                            title: "选择专精方向",
                            kind: .multipleChoice,
                            question: "希望研究调度器、驱动和内存管理，最适合优先深入哪个方向？",
                            options: ["前端", "Linux 内核", "数据库产品", "App Store 运营"],
                            answer: "Linux 内核",
                            explanation: "调度、驱动、内存管理等核心机制位于内核，需要扎实的 C、汇编、操作系统和系统编程基础。"
                        ),
                        LearningExerciseSeed(
                            id: "exercise-specialization-code",
                            order: 2,
                            title: "为学习记录增加搜索",
                            kind: .coding,
                            question: "用 SwiftUI 给记录列表增加搜索：按标题过滤，并展示空结果提示。",
                            answer: #"""
import SwiftData
import SwiftUI

struct SearchableStudyList: View {
    @Query(sort: \StudyRecord.createdAt) private var records: [StudyRecord]
    @State private var query = ""

    private var filtered: [StudyRecord] {
        let value = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty else { return records }
        return records.filter { $0.title.localizedCaseInsensitiveContains(value) }
    }

    var body: some View {
        List(filtered) { record in
            Text(record.title)
        }
        .overlay {
            if filtered.isEmpty {
                ContentUnavailableView.search(text: query)
            }
        }
        .searchable(text: $query, prompt: "搜索记录")
    }
}
"""#,
                            explanation: "示例使用本地过滤来保持简单。数据量很大时应在数据库层查询，并考虑分页或索引。`localizedCaseInsensitiveContains` 适合用户可读的本地搜索。",
                            starterCode: "import SwiftData\nimport SwiftUI\n\n// 为 StudyRecord 列表增加 searchable 和空状态\n",
                            codeLanguage: "swift"
                        )
                    ]
                )
            ]
        )
    ]
}
