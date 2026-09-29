import Foundation

struct TeachBackDimension: Identifiable {
    let id: String
    let title: String
    let score: Double
    let detail: String
}

struct TeachBackEvaluation {
    let score: Double
    let summary: String
    let strengths: [String]
    let gaps: [String]
    let dimensions: [TeachBackDimension]

    var passed: Bool { score >= 0.6 }

    var noteBody: String {
        var lines = [
            "评分：\(Int(score * 100))%",
            summary,
            "",
            "维度反馈："
        ]
        lines += dimensions.map { "\($0.title)：\(Int($0.score * 100))% · \($0.detail)" }
        if !strengths.isEmpty {
            lines += ["", "做得好的地方："] + strengths.map { "· \($0)" }
        }
        if !gaps.isEmpty {
            lines += ["", "下一次补充："] + gaps.map { "· \($0)" }
        }
        return lines.joined(separator: "\n")
    }
}

enum TeachBackService {
    static func evaluate(
        answer: String,
        stepTitle: String,
        reference: String,
        concepts: [Concept]
    ) -> TeachBackEvaluation {
        let normalized = answer.lowercased()
        let terms = conceptTerms(stepTitle: stepTitle, concepts: concepts)
        let hits = terms.filter { term in
            !term.isEmpty && normalized.contains(term.lowercased())
        }
        let coverage = terms.isEmpty ? min(1, Double(normalized.count) / 120) : Double(hits.count) / Double(terms.count)

        let reasoningMarkers = ["因为", "所以", "如果", "因此", "意味着", "例如", "比如", "首先", "然后", "但是", "区别"]
        let reasoningHits = reasoningMarkers.filter { normalized.contains($0) }.count
        let reasoning = min(1, Double(reasoningHits) / 4)

        let exampleMarkers = ["例如", "比如", "代码", "命令", "输出", "printf", "int ", "ls ", "gcc", "clang"]
        let example = exampleMarkers.contains(where: { normalized.contains($0) }) ? 1.0 : 0.0

        let meaningfulLength = normalized.replacingOccurrences(of: "\\s", with: "", options: .regularExpression).count
        let lengthScore = min(1, Double(meaningfulLength) / 160)
        let structureSignals = answer
            .components(separatedBy: CharacterSet(charactersIn: "。！？!?;；\n"))
            .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            .count
        let structure = min(1, Double(structureSignals) / 4 * 0.7 + lengthScore * 0.3)

        let referenceCoverage = min(1, Double(meaningfulLength) / max(160, Double(reference.count) * 0.12))
        let completeness = referenceCoverage * 0.6 + coverage * 0.4

        let dimensions = [
            TeachBackDimension(
                id: "coverage",
                title: "概念覆盖",
                score: coverage,
                detail: coverage >= 0.7 ? "核心术语基本覆盖" : "还有核心概念没有讲到"
            ),
            TeachBackDimension(
                id: "reasoning",
                title: "原因与因果",
                score: reasoning,
                detail: reasoning >= 0.6 ? "解释了为什么" : "多说明原因、条件和结果"
            ),
            TeachBackDimension(
                id: "example",
                title: "例子与实验",
                score: example,
                detail: example > 0 ? "给出了具体例子" : "补充一个代码或命令示例"
            ),
            TeachBackDimension(
                id: "structure",
                title: "表达结构",
                score: structure,
                detail: structure >= 0.65 ? "层次比较清楚" : "尝试按“结论—原因—例子”组织"
            ),
            TeachBackDimension(
                id: "completeness",
                title: "完整程度",
                score: completeness,
                detail: completeness >= 0.65 ? "内容达到独立复述水平" : "还可以补充边界和细节"
            )
        ]

        let score = min(
            1,
            coverage * 0.32
                + reasoning * 0.20
                + example * 0.14
                + structure * 0.14
                + completeness * 0.20
        )

        var strengths: [String] = []
        var gaps: [String] = []
        for dimension in dimensions {
            if dimension.score >= 0.7 {
                strengths.append("\(dimension.title)：\(dimension.detail)")
            } else {
                gaps.append("\(dimension.title)：\(dimension.detail)")
            }
        }

        let summary: String
        switch score {
        case 0.8...:
            summary = "你已经能够脱离原文解释核心内容，可以尝试给他人讲一遍。"
        case 0.6..<0.8:
            summary = "基本理解已经形成，再补齐原因和一个具体例子会更稳。"
        case 0.4..<0.6:
            summary = "已经抓住部分内容，但还有一些因果关系和术语缺口。"
        default:
            summary = "当前解释比较简略，建议重新阅读后再完整复述。"
        }

        return TeachBackEvaluation(
            score: score,
            summary: summary,
            strengths: Array(strengths.prefix(3)),
            gaps: Array(gaps.prefix(3)),
            dimensions: dimensions
        )
    }

    private static func conceptTerms(stepTitle: String, concepts: [Concept]) -> [String] {
        var terms = concepts.flatMap { [$0.name] + $0.aliases }
        terms += stepTitle
            .components(separatedBy: CharacterSet(charactersIn: "：:，,。.、与和()（）"))
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        return Array(Set(terms.filter { $0.count >= 2 }))
    }
}
