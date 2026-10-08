import Foundation

struct DynamicPracticeQuestion: Identifiable, Sendable {
    let id: String
    let conceptID: String
    let conceptName: String
    let title: String
    let prompt: String
    let code: String?
    let options: [String]
    let correctIndex: Int
    let explanation: String
    let difficulty: String
}

struct SeededRandomNumberGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed == 0 ? 0xCAFE_F00D : seed
    }

    mutating func next() -> UInt64 {
        state = state &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
        return state
    }
}

enum AdaptivePracticeService {
    static func generateSession(
        concepts: [Concept],
        masteryRecords: [MasteryRecord],
        count: Int = 5,
        seed: UInt64 = UInt64(Date.now.timeIntervalSince1970)
    ) -> [DynamicPracticeQuestion] {
        guard !concepts.isEmpty, count > 0 else { return [] }

        let recordMap = Dictionary(uniqueKeysWithValues: masteryRecords.map { ($0.conceptID, $0) })
        let weak = concepts
            .filter { (recordMap[$0.id]?.score ?? 0.45) < 0.72 }
            .sorted { lhs, rhs in
                let left = recordMap[lhs.id]?.score ?? 0.45
                let right = recordMap[rhs.id]?.score ?? 0.45
                if left == right { return lhs.name < rhs.name }
                return left < right
            }
        let remaining = concepts
            .filter { concept in !weak.contains { $0.id == concept.id } }
            .sorted { $0.name < $1.name }

        var rng = SeededRandomNumberGenerator(seed: seed)
        var weakPool = weak
        var remainingPool = remaining
        weakPool.shuffle(using: &rng)
        remainingPool.shuffle(using: &rng)
        let pool = weakPool + remainingPool

        var selected: [Concept] = []
        while selected.count < count {
            let next = pool[selected.count % pool.count]
            selected.append(next)
            if selected.count >= pool.count, selected.count >= count { break }
        }

        return selected.enumerated().map { index, concept in
            generateQuestion(
                for: concept,
                allConcepts: concepts,
                record: recordMap[concept.id],
                index: index,
                rng: &rng
            )
        }
    }

    static func generateQuestion(
        for concept: Concept,
        allConcepts: [Concept],
        record: MasteryRecord?,
        index: Int = 0,
        rng: inout SeededRandomNumberGenerator
    ) -> DynamicPracticeQuestion {
        let difficulty: String
        switch record?.score ?? 0.45 {
        case 0.8...: difficulty = "进阶"
        case 0.55..<0.8: difficulty = "标准"
        default: difficulty = "基础"
        }

        let question: (title: String, prompt: String, code: String?, options: [String], correct: String, explanation: String)
        switch concept.id {
        case "set":
            let a = Int.random(in: 0...15, using: &rng)
            let b = Int.random(in: 0...15, using: &rng)
            question = (
                "位集合运算",
                "A = \(a)，B = \(b)。A & B 的结果是什么？",
                "A = \(String(a, radix: 2))\nB = \(String(b, radix: 2))",
                ["\(a & b)", "\(a | b)", "\(a ^ b)", "\(a + b)"],
                "\(a & b)",
                "按位与只保留两个数都为 1 的位。这里二进制结果对应十进制 \(a & b)。"
            )
        case "pointer":
            let values = (1...4).map { _ in Int.random(in: 1...20, using: &rng) }
            let index = Int.random(in: 0..<values.count, using: &rng)
            question = (
                "指针算术",
                "数组 a = \(values)，执行 `*(a + \(index))` 得到什么？",
                "int a[4] = {\(values.map(String.init).joined(separator: ", "))};",
                ["\(values[index])", "\(values[(index + 1) % values.count])", "\(values[0])", "地址值 \(index)"],
                "\(values[index])",
                "指针算术按元素大小移动，`*(a + \(index))` 等价于 `a[\(index)]`，得到 \(values[index])。"
            )
        case "complexity":
            let functions = ["O(1)", "O(log n)", "O(n)", "O(n log n)", "O(n²)"]
            let first = functions.randomElement(using: &rng) ?? "O(n)"
            var second = functions.randomElement(using: &rng) ?? "O(log n)"
            while first == second { second = functions.randomElement(using: &rng) ?? "O(log n)" }
            let rank = Dictionary(uniqueKeysWithValues: functions.enumerated().map { ($1, $0) })
            let correct = (rank[first] ?? 0) <= (rank[second] ?? 0) ? first : second
            question = (
                "复杂度比较",
                "当 n 足够大时，\(first) 与 \(second) 哪个增长更慢？",
                nil,
                [correct, correct == first ? second : first, "两者完全相同", "无法比较"],
                correct,
                "忽略常数和低阶项后，\(correct) 的增长阶低于另一个选项。"
            )
        case "matrix":
            let a = (1...3).map { _ in Int.random(in: -3...5, using: &rng) }
            let b = (1...3).map { _ in Int.random(in: -3...5, using: &rng) }
            let dot = zip(a, b).reduce(0) { $0 + $1.0 * $1.1 }
            question = (
                "向量点积",
                "向量 A = \(a)，B = \(b) 的点积是多少？",
                "dot = Σ A[i] × B[i]",
                ["\(dot)", "\(dot + 2)", "\(abs(dot) + 1)", "0"],
                "\(dot)",
                "逐项相乘再求和得到 \(dot)。点积为 0 才表示正交。"
            )
        case "probability":
            let first = Int.random(in: 1...6, using: &rng)
            let second = Int.random(in: 1...6, using: &rng)
            let sum = first + second
            let favorable = max(0, 6 - abs(sum - 7))
            question = (
                "骰子概率",
                "投掷两颗公平骰子，点数和为 \(sum) 的理论概率是多少？",
                "结果空间共有 36 个等可能结果。",
                ["\(favorable)/36", "\(max(1, favorable + 1))/36", "1/6", "\(favorable)/12"],
                "\(favorable)/36",
                "点数和为 \(sum) 的结果有 \(favorable) 个，因此概率是 \(favorable)/36。"
            )
        case "expectation":
            let sides = [2, 4, 6].randomElement(using: &rng) ?? 6
            let expectation = Double(sides + 1) / 2.0
            question = (
                "期望值",
                "公平 \(sides) 面骰子点数的期望是多少？",
                nil,
                [String(format: "%.1f", expectation), "\(sides / 2)", "\(sides)", "1.0"],
                String(format: "%.1f", expectation),
                "均匀分布的期望是所有结果的平均值，因此为 \((sides + 1))/2。"
            )
        case "entropy":
            question = (
                "信息熵",
                "以下哪种分布通常具有最大熵？",
                nil,
                ["均匀分布", "只有一个结果概率为 1", "两个结果概率相差很大", "所有结果概率都为 0"],
                "均匀分布",
                "在结果数量固定时，均匀分布的不确定性最大，熵最大。"
            )
        case "state-machine":
            let symbols = ["0", "1"]
            let input = (0..<4).map { _ in symbols.randomElement(using: &rng) ?? "0" }.joined()
            let accepts = input.hasSuffix("01")
            question = (
                "DFA 接受判断",
                "自动机接受“以 01 结尾”的二进制字符串。输入 `\(input)` 是否被接受？",
                "状态：起始 → 读到 0 → 读到 01。",
                ["接受", "拒绝", "输入非法", "无法判断"],
                accepts ? "接受" : "拒绝",
                "输入 \(input) \(accepts ? "以 01 结尾，因此到达接受状态。" : "没有以 01 结尾，因此不满足接受条件。")"
            )
        case "np-complete":
            question = (
                "NP 与验证",
                "NP 最准确的含义是什么？",
                nil,
                ["解可以在多项式时间验证", "不存在任何算法", "一定不能在指数时间求解", "所有问题都可以快速求解"],
                "解可以在多项式时间验证",
                "NP 表示解能在多项式时间验证。P 是否等于 NP 仍是开放问题。"
            )
        case "dynamic-programming":
            question = (
                "动态规划适用条件",
                "什么时候最适合优先考虑动态规划？",
                nil,
                ["子问题重叠且具有最优子结构", "每一步局部最优都能证明全局最优", "输入一定有序", "问题一定可以在 O(1) 求解"],
                "子问题重叠且具有最优子结构",
                "动态规划通过保存重叠子问题结果，并利用最优子结构组合答案。"
            )
        case "database-index":
            question = (
                "复合索引最左前缀",
                "复合索引为 `(last_name, first_name)`，单独按 `first_name` 查询通常能否高效使用该索引？",
                nil,
                ["通常不能直接使用最左前缀", "一定可以", "索引会自动交换列顺序", "必须删除 last_name"],
                "通常不能直接使用最左前缀",
                "复合索引通常要先匹配最左列。单独查询 first_name 往往无法利用该 B+ 树前缀。"
            )
        case "lexer":
            let expression = ["12+3", "4*(5-1)", "7/2+1"].randomElement(using: &rng) ?? "12+3"
            question = (
                "词法分析输出",
                "词法分析器处理 `\(expression)` 时，最先负责的是哪一步？",
                nil,
                ["把字符流切分成 token", "计算表达式结果", "生成机器码", "分配寄存器"],
                "把字符流切分成 token",
                "词法分析只识别数字、运算符等 token，不计算表达式，也不负责最终目标代码。"
            )
        case "proof":
            question = (
                "反例的作用",
                "要推翻一个全称命题 `∀x, P(x)`，最少需要什么？",
                nil,
                ["一个满足前提但不满足结论的反例", "任意一个例子", "一个证明", "更多测试数据"],
                "一个满足前提但不满足结论的反例",
                "反例只需一个合法对象即可推翻全称命题；测试数据本身不能替代证明或反例。"
            )
        case "induction":
            question = (
                "数学归纳结构",
                "数学归纳证明必须包含哪两部分？",
                nil,
                ["基础情况与归纳步骤", "一个随机样本", "一个反证例子", "复杂度分析"],
                "基础情况与归纳步骤",
                "基础情况保证起点成立，归纳步骤说明较小结构成立可推出更大结构成立。"
            )
        case "regular-language":
            question = (
                "正则语言边界",
                "语言 `{0ⁿ1ⁿ | n≥0}` 能否用有限自动机识别？",
                nil,
                ["不能，通常需要栈或更强模型", "能，用一个短正则表示", "只能用 NFA", "取决于字符串长度"],
                "不能，通常需要栈或更强模型",
                "有限自动机无法保存任意数量的 0 并配对相同数量的 1，需要上下文无关文法或下推自动机。"
            )
        default:
            question = fallbackQuestion(for: concept, allConcepts: allConcepts, rng: &rng)
        }

        let options = uniqueOptions(question.options, correct: question.correct, rng: &rng)
        return DynamicPracticeQuestion(
            id: "\(concept.id)-\(index)",
            conceptID: concept.id,
            conceptName: concept.name,
            title: question.title,
            prompt: question.prompt,
            code: question.code,
            options: options,
            correctIndex: options.firstIndex(of: question.correct) ?? 0,
            explanation: question.explanation,
            difficulty: difficulty
        )
    }

    private static func fallbackQuestion(
        for concept: Concept,
        allConcepts: [Concept],
        rng: inout SeededRandomNumberGenerator
    ) -> (title: String, prompt: String, code: String?, options: [String], correct: String, explanation: String) {
        let distractors = allConcepts
            .filter { $0.id != concept.id }
            .map(\.summary)
            .filter { !$0.isEmpty }
            .shuffled(using: &rng)
        var options = [concept.summary] + Array(distractors.prefix(3))
        while options.count < 4 {
            options.append("这个说法忽略了口令、边界或上下文。")
        }
        options = Array(options.prefix(4))
        let correct = concept.summary
        return (
            "概念辨别",
            "以下哪项最符合“\(concept.name)”的描述？",
            nil,
            options,
            correct,
            "正确选项来自概念定义：\(correct)"
        )
    }

    private static func uniqueOptions(
        _ rawOptions: [String],
        correct: String,
        rng: inout SeededRandomNumberGenerator
    ) -> [String] {
        var options = Array(NSOrderedSet(array: rawOptions)) as? [String] ?? rawOptions
        if !options.contains(correct) {
            options[0] = correct
        }
        if options.count > 4 {
            options = Array(options.prefix(4))
        }
        while options.count < 4 {
            options.append("以上都不正确")
        }
        if options.firstIndex(of: correct) == nil {
            options[0] = correct
        }
        options.shuffle(using: &rng)
        return options
    }
}
