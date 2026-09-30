import Foundation

enum CatalogTheory {
    static let stages: [LearningStageSeed] = [
        mathStage,
        theoryStage
    ]

    private static let mathStage = LearningStageSeed(
        id: "stage-math",
        order: 4,
        title: "数学基础",
        subtitle: "用离散数学、证明、线性代数、概率和信息论建立可验证的计算机科学语言。",
        icon: "function",
        themeHex: "5E5CE6",
        topics: [
            LearningTopicSeed(
                id: "topic-math-discrete",
                order: 1,
                title: "离散数学与证明",
                summary: "掌握集合、关系、图、逻辑、归纳和反例，把程序问题写成可证明的数学对象。",
                estimatedMinutes: 480,
                tutorials: [discreteTutorial, proofTutorial],
                exercises: [discreteChoice, discreteCode, proofChoice, proofCode]
            ),
            LearningTopicSeed(
                id: "topic-math-linear",
                order: 2,
                title: "线性代数与矩阵思维",
                summary: "从向量、矩阵、线性变换到秩和特征值，理解图形、机器学习和数值计算共同的表示方式。",
                estimatedMinutes: 300,
                tutorials: [linearTutorial],
                exercises: [linearChoice, linearCode]
            ),
            LearningTopicSeed(
                id: "topic-math-probability",
                order: 3,
                title: "概率、统计与信息论",
                summary: "理解随机性、条件概率、期望、方差、熵和编码，为算法分析、网络和机器学习打基础。",
                estimatedMinutes: 420,
                tutorials: [probabilityTutorial, informationTutorial],
                exercises: [probabilityChoice, probabilityCode, informationChoice, informationCode]
            )
        ]
    )

    private static let theoryStage = LearningStageSeed(
        id: "stage-theory",
        order: 5,
        title: "计算理论",
        subtitle: "从状态机、形式语言到可计算性、复杂度、算法范式和程序语义，理解计算机能做什么以及为什么。",
        icon: "circle.hexagongrid.fill",
        themeHex: "AF52DE",
        topics: [
            LearningTopicSeed(
                id: "topic-theory-automata",
                order: 1,
                title: "自动机与形式语言",
                summary: "用状态、转移和接受条件描述正则语言、语法分析和协议。",
                estimatedMinutes: 300,
                tutorials: [automataTutorial],
                exercises: [automataChoice, automataCode]
            ),
            LearningTopicSeed(
                id: "topic-theory-computability",
                order: 2,
                title: "可计算性与复杂度",
                summary: "理解停机问题、归约、P/NP、NP 完全和近似，认识算法能力的理论边界。",
                estimatedMinutes: 420,
                tutorials: [computabilityTutorial],
                exercises: [computabilityChoice, computabilityCode]
            ),
            LearningTopicSeed(
                id: "topic-theory-algorithms",
                order: 3,
                title: "算法设计范式与下界",
                summary: "从分治、动态规划、贪心到递推分解，比较正确性证明、复杂度和适用条件。",
                estimatedMinutes: 360,
                tutorials: [algorithmTheoryTutorial],
                exercises: [algorithmChoice, algorithmCode]
            ),
            LearningTopicSeed(
                id: "topic-theory-semantics",
                order: 4,
                title: "类型、不变量与程序语义",
                summary: "把程序看成状态机，用前置条件、后置条件和类型系统证明行为。",
                estimatedMinutes: 300,
                tutorials: [semanticsTutorial],
                exercises: [semanticsChoice, semanticsCode]
            )
        ]
    )

    private static let discreteTutorial = LearningTutorialSeed(
        id: "tutorial-math-discrete",
        order: 1,
        title: "集合、关系与图：给程序建立数学模型",
        summary: "把用户、文件、任务和依赖关系抽象成集合、关系与图，并理解它们如何进入类型、数据库和算法。",
        markdown: #"""
# 为什么计算机科学需要离散数学

计算机处理的是离散对象：整数、字符串、节点、状态、消息和权限。连续数学描述曲线和变化率，离散数学描述“有限步骤中的对象与关系”。当你说一个用户属于管理员集合、一个文件依赖另一个文件、一个任务必须在另一个任务之前完成时，你已经在使用集合、关系和图。

数学建模的关键不是使用更复杂的符号，而是把模糊需求变成可检查对象。先定义对象集合，再定义对象之间的关系，最后定义允许的操作和必须保持的性质。任何程序错误都可以转换成一句话：某个对象不在预期集合中，某个关系不满足，或者某次操作破坏了不变量。

## 集合与函数

集合是无序、不重复元素的整体。并集 `A ∪ B` 表示属于 A 或 B 的元素，交集 `A ∩ B` 表示同时属于两者，差集表示属于前者但不属于后者。程序中的去重、权限合并、标签筛选都是集合操作。

函数把每个输入映射到唯一输出。输入集合叫定义域，输出集合叫陪域。程序函数不一定是数学函数：如果它读取时间、文件或网络，同样输入可能产生不同输出。要获得可预测性，必须把外部状态显式作为输入，或者限制副作用。

## 关系、等价关系与偏序

关系是笛卡尔积的子集。等号是等价关系，满足自反、对称、传递；它把对象划分成等价类。版本兼容、文件去重和状态归并都需要明确“什么算相同”。

偏序满足自反、反对称、传递，不一定任意两个元素可比较。任务依赖、文件包含和继承层次都是偏序。拓扑排序只能在无环偏序上工作。遇到“先做 A 才能做 B”，先问：是否存在环？如果没有环，能否构造合法顺序？

## 图与程序结构

图由顶点和边组成。有向图适合依赖、状态机和网络路径；无向图适合朋友关系、连通区域和物理连接。邻接表适合稀疏图，邻接矩阵适合稠密且频繁查询边是否存在的场景。

图算法不是背公式。BFS 求无权最短路，DFS 求连通分量和环，拓扑排序求依赖顺序，Dijkstra 求非负权最短路。每个算法都依赖前提：是否有向、是否带权、权是否非负、图是否连通。

## 把模型变成代码

下面的 C 程序用位集合表示最多八种权限。每一位代表一个集合元素，按位或合并集合，按位与求交集。它把集合运算直接映射到硬件支持的位运算，适合小规模、固定范围的标志集合。
"""#,
        codeLanguage: "c",
        code: #"""
// 用位集合表示权限集合
#include <stdint.h>
#include <stdio.h>

#define PERM_READ    (1u << 0)
#define PERM_WRITE   (1u << 1)
#define PERM_EXECUTE (1u << 2)

static void print_binary(uint8_t value) {
    for (int bit = 7; bit >= 0; --bit) {
        putchar((value & (1u << bit)) ? '1' : '0');
    }
}

int main(void) {
    uint8_t user = PERM_READ | PERM_WRITE;
    uint8_t required = PERM_READ | PERM_EXECUTE;
    uint8_t common = user & required;

    printf("user     = ");
    print_binary(user);
    printf("\nrequired = ");
    print_binary(required);
    printf("\ncommon   = ");
    print_binary(common);
    printf("\nhas read = %s\n", (user & PERM_READ) ? "yes" : "no");
    return 0;
}
"""#,
        secondCodeLanguage: "swift",
        secondCode: #"""
import Foundation

// Swift Set 适合元素数量不固定、需要动态增删的集合。
let user: Set<String> = ["read", "write"]
let required: Set<String> = ["read", "execute"]

print("common =", user.intersection(required).sorted())
print("has read =", user.contains("read"))
print("missing =", required.subtracting(user).sorted())
"""#,
        commonMistakes: #"""
- 只给对象命名，不定义对象满足的约束。
- 把偏序当成全序，错误地认为任意两个任务都可比较。
- 用图算法前不检查有向、带权、非负权和环等前提。
- 把“相等”当成自然事实，没有定义等价关系。
"""#
    )

    private static let proofTutorial = LearningTutorialSeed(
        id: "tutorial-math-proof",
        order: 2,
        title: "证明、归纳与反例：让结论可被检验",
        summary: "掌握命题、量词、直接证明、反证、数学归纳、循环不变量和反例，并把这些方法用于代码正确性。",
        markdown: #"""
# 证明不是数学课的形式主义

程序中的证明回答三个问题：程序应该满足什么条件？每一步为什么保持条件？结束时为什么得到正确结果？如果不写清楚，代码可能通过少量测试，却在边界输入上失败。测试寻找反例，证明解释所有合法输入。

## 命题与逻辑

命题是可以判断真假的陈述。“输入非空”是命题，“输入很大”不是，除非定义阈值。逻辑连接词包括与、或、非、蕴含和等价。最容易出错的是蕴含：`P → Q` 只在 P 真而 Q 假时为假。P 为假时，整个蕴含为真，这叫虚真。

量词顺序不能交换。`∀x ∃y, y > x` 与 `∃y ∀x, y > x` 含义完全不同。程序接口中的“对每个请求存在一个响应”和“存在一个响应适用于所有请求”是两种系统需求。

## 直接证明与反证

直接证明从已知条件出发，经过允许的推理得到结论。反证假设结论不成立，推出矛盾。反例证明一个全称命题为假：只要给出一个合法输入不满足结论即可。反例不需要覆盖所有情况，一个就足够。

算法证明常见结构是：前置条件、循环不变量、终止条件和后置条件。循环不变量在初始化时成立，每次迭代后仍成立，循环结束时与终止条件共同推出结果。

## 数学归纳与结构归纳

普通归纳证明自然数性质：基础情况成立；假设 n 成立能推出 n+1 成立。强归纳假设所有小于 n 的情况成立。结构归纳把自然数换成树、链表或语法表达式：基础结构成立，组合结构由子结构成立推出父结构成立。

递归算法与结构归纳天然对应。若函数对空树正确，并假设左右子树结果正确时合并结果也正确，就证明了整棵树。如果证明中某个条件说不清，通常就是代码边界没有处理。

## 用不变量检查求和

下面的程序计算数组和并维护不变量：循环开始前 `sum` 等于前 `i` 个元素之和。初始化 `i = 0` 时为空和；每轮先加入 `a[i]` 再递增 `i`，不变量保持；结束时 `i == n`，所以 `sum` 是全部元素之和。
"""#,
        codeLanguage: "c",
        code: #"""
// 循环不变量：sum 始终等于前 i 个元素之和
#include <assert.h>
#include <stddef.h>
#include <stdio.h>

static long sum_array(const int *values, size_t count) {
    long sum = 0;
    for (size_t i = 0; i < count; ++i) {
        // 进入循环体前：sum == values[0] + ... + values[i-1]
        sum += values[i];
        // 退出本轮后：sum == values[0] + ... + values[i]
    }
    // 循环结束时 i == count，因此 sum 是全部元素之和
    return sum;
}

int main(void) {
    int values[] = {3, 1, 4, 1, 5};
    long result = sum_array(values, 5);
    assert(result == 14);
    printf("sum=%ld\n", result);
    return 0;
}
"""#,
        secondCodeLanguage: "swift",
        secondCode: #"""
import Foundation

// precondition 把调用者必须满足的条件写在接口边界。
func average(_ values: [Double]) -> Double {
    precondition(!values.isEmpty, "平均值需要至少一个元素")
    let total = values.reduce(0, +)
    let result = total / Double(values.count)
    assert(abs(result * Double(values.count) - total) < 0.000_001)
    return result
}

print(average([2, 4, 6]))
"""#,
        commonMistakes: #"""
- 把“测试通过几次”当成对所有输入成立。
- 交换全称量词和存在量词，错误理解接口要求。
- 归纳证明中基础情况和归纳步骤缺一不可。
- 循环不变量写得无法验证，只是在重复代码含义。
"""#
    )

    private static let linearTutorial = LearningTutorialSeed(
        id: "tutorial-math-linear",
        order: 1,
        title: "向量与矩阵：从坐标到变换",
        summary: "用向量、线性组合、矩阵乘法、秩和特征值理解图形、搜索、数据压缩和机器学习。",
        markdown: #"""
# 为什么程序员要学线性代数

图形渲染把顶点从模型坐标变换到屏幕坐标；机器学习把样本表示成向量；推荐系统计算向量相似度；图算法可以用邻接矩阵表达连接关系。线性代数研究“线性组合”和“可预测变换”，为这些领域提供共同语言。

## 向量、基与线性组合

向量既可以理解为带方向的箭头，也可以理解为坐标列表。向量加法对应分量相加，数乘对应每个分量缩放。一组向量能通过数乘和加法生成的所有向量构成张成空间。如果其中一个向量能由其他向量表示，它们线性相关；如果没有冗余，它们线性无关，构成基。

同一对象可以换基。坐标不是对象本身，只是相对于某组基的表示。理解这一点，就不会把矩阵元素当成脱离坐标系的绝对事实。

## 矩阵就是线性变换

矩阵乘向量会把向量变换到新空间。矩阵的列向量说明基向量分别被映射到哪里。矩阵乘法不满足交换律：先旋转再缩放，通常不等于先缩放再旋转。转置交换行列，逆矩阵在变换可逆时恢复原向量，行列式描述面积或体积的缩放倍率。

矩阵乘法复杂度可以通过分块、Strassen 和硬件并行改善。稀疏矩阵不应使用二维数组存储所有零，而应使用邻接表或压缩稀疏格式。

## 秩、投影与特征值

秩是线性无关列的最大数量，也是变换保留的维度数量。低秩矩阵意味着信息冗余，适合压缩和降维。投影用于最小二乘、PCA 和信号分解。特征向量经过矩阵变换后方向不变，只被缩放；特征值就是缩放倍率。

这些概念不需要一次全部掌握。先能解释点积、矩阵乘法和秩，再用小矩阵手算，最后通过代码验证。

## 用 Swift 实现最小向量

下面的实现包含向量点积和二维矩阵乘法。点积衡量两个向量的方向一致性；矩阵乘法组合两个线性变换。代码使用固定数组来保持示例简单，真实数值库还要处理维度检查、浮点误差和性能。
"""#,
        codeLanguage: "swift",
        code: #"""
import Foundation

struct Vector: Equatable {
    let values: [Double]

    func dot(_ other: Vector) -> Double {
        precondition(values.count == other.values.count, "维度必须相同")
        return zip(values, other.values).reduce(0) { $0 + $1.0 * $1.1 }
    }

    var magnitude: Double {
        sqrt(dot(self))
    }
}

struct Matrix2D {
    let rows: [[Double]]

    func multiply(_ vector: Vector) -> Vector {
        precondition(rows.allSatisfy { $0.count == vector.values.count }, "矩阵列数必须等于向量维度")
        return Vector(values: rows.map { row in
            zip(row, vector.values).reduce(0) { $0 + $1.0 * $1.1 }
        })
    }
}

let v = Vector(values: [3, 4])
print("dot =", v.dot(Vector(values: [1, 0])))
print("length =", v.magnitude)

let rotation = Matrix2D(rows: [[0, -1], [1, 0]])
print("rotated =", rotation.multiply(v).values)
"""#,
        secondCodeLanguage: "c",
        secondCode: #"""
// 用数组存储 2x2 矩阵，验证矩阵向量乘法
#include <stdio.h>

int main(void) {
    double matrix[2][2] = {{1, 2}, {3, 4}};
    double vector[2] = {5, 6};
    double result[2] = {0, 0};

    for (int row = 0; row < 2; ++row) {
        for (int column = 0; column < 2; ++column) {
            result[row] += matrix[row][column] * vector[column];
        }
    }

    printf("%.1f %.1f\n", result[0], result[1]);
    return 0;
}
"""#,
        commonMistakes: #"""
- 混淆向量对象与它在某组基下的坐标。
- 认为矩阵乘法可以交换顺序。
- 忽略维度检查，越界读取数据。
- 把行列式当成所有矩阵都可逆的证明；行列式为零时逆矩阵不存在。
"""#
    )

    private static let probabilityTutorial = LearningTutorialSeed(
        id: "tutorial-math-probability",
        order: 1,
        title: "概率与期望：在不确定中做决策",
        summary: "从样本空间、条件概率和 Bayes 公式到随机变量、期望、方差与蒙特卡洛实验。",
        markdown: #"""
# 不确定并不等于无法推理

随机算法、哈希碰撞、网络延迟、缓存命中、机器学习和安全攻击都涉及不确定性。概率不是“运气好坏”的模糊描述，而是在明确实验、样本空间和事件后计算长期频率或信念程度。

## 样本空间与事件

一次实验所有可能结果组成样本空间，事件是样本空间的子集。概率满足非负、全空间为 1、互斥事件可加。公平硬币的样本空间是正面和反面，连续均匀随机变量不是给每个点分配正概率，而要使用概率密度。

条件概率 `P(A|B)` 表示已知 B 发生时 A 的概率，定义是 `P(A∩B)/P(B)`，要求 B 概率非零。独立要求 `P(A∩B)=P(A)P(B)`。互斥与独立不是一回事：两个非零概率事件如果互斥，就不独立。

## Bayes 与基础率错误

Bayes 公式把先验概率和证据似然结合得到后验概率。医学检测、垃圾邮件过滤和故障诊断都容易出现基础率错误：疾病很罕见时，即使检测很灵敏，阳性结果也可能大部分是假阳性。看到条件概率必须写出分母。

## 随机变量、期望与方差

随机变量把结果映射为数值。期望是概率加权平均，不等于最常出现的值；方差描述波动。期望具有线性性，即使变量不独立也成立。方差通常需要协方差或独立性信息。

大数定律说明样本均值在重复试验中趋于总体期望，但不会说明一次试验的结果。中心极限定理描述大量独立同分布变量和的标准化的趋势，不保证所有分布都很快收敛。

## 用蒙特卡洛验证概率

下面的程序重复投掷两颗骰子，估计点数之和为 7 的频率。实验结果不会精确等于理论值 `6/36`，但样本量增大后通常靠近它。随机模拟用于验证推导，不能替代概率模型。
"""#,
        codeLanguage: "c",
        code: #"""
// 蒙特卡洛：估计两颗骰子点数和为 7 的概率
#include <stdio.h>
#include <stdlib.h>

int main(void) {
    const long trials = 1000000;
    long successes = 0;
    srand(20260930u);

    for (long i = 0; i < trials; ++i) {
        int first = rand() % 6 + 1;
        int second = rand() % 6 + 1;
        if (first + second == 7) {
            successes++;
        }
    }

    double estimate = (double)successes / (double)trials;
    printf("estimate=%.5f theoretical=%.5f\n", estimate, 6.0 / 36.0);
    return 0;
}
"""#,
        secondCodeLanguage: "swift",
        secondCode: #"""
import Foundation

// 用条件概率计算：已知至少一颗骰子是 6，点数和为 8 的概率。
let outcomes = (1...6).flatMap { a in
    (1...6).map { b in (a, b) }
}
let atLeastOneSix = outcomes.filter { $0.0 == 6 || $0.1 == 6 }
let sumEight = atLeastOneSix.filter { $0.0 + $0.1 == 8 }
print(Double(sumEight.count) / Double(atLeastOneSix.count))
"""#,
        commonMistakes: #"""
- 把互斥事件当成独立事件。
- 忽略基础率，只使用检测灵敏度解释阳性概率。
- 把期望当成必然结果或最大值。
- 用一次随机实验的波动否定理论推导。
"""#
    )

    private static let informationTutorial = LearningTutorialSeed(
        id: "tutorial-math-information",
        order: 2,
        title: "熵与编码：信息如何量化",
        summary: "理解 bit、熵、交叉熵、KL 散度和 Huffman 编码，把压缩、日志和模型损失放到同一框架。",
        markdown: #"""
# 信息量不是消息长度

一条消息的不确定性越低，提供的新信息越少。“明天太阳升起”接近必然，信息量低；“随机数等于 42”概率很低，信息量高。信息论用概率描述不确定性，用 bit 作为编码单位。一个发生概率为 p 的事件信息量可写为 `-log2(p)`。

## 熵与联合分布

熵是随机变量平均信息量，也是最优前缀码平均长度的下界。均匀分布熵最大；某个结果概率为 1 时熵为 0。联合熵描述两个变量共同的不确定性，条件熵描述已知一个变量后另一个变量的剩余不确定性。

互信息等于熵的减少量，衡量两个变量相关性。互信息为零不一定意味着完全独立，它主要衡量平均线性或非线性信息依赖，实际计算要使用合适估计。

## 交叉熵与 KL 散度

机器学习分类常用交叉熵损失。真实分布 p 与预测分布 q 的交叉熵是 `-Σ p log q`。当 q 越接近 p，交叉熵越接近 p 的熵。KL 散度 `D(p||q)` 是交叉熵减去 p 的熵，非负且不对称，不是距离度量。

压缩、语言模型和推荐系统都在做概率预测。模型给出错误的高置信度时，对数损失会放大惩罚；这解释了为什么概率校准很重要。

## Huffman 与错误纠正

Huffman 编码给高频符号短码、低频符号长码，并保证没有码字是另一个码字前缀。它适用于已知符号频率的场景，不保证单个符号最短，而是优化平均长度。错误纠正码加入冗余，使接收端能检测或修正传输错误；冗余不是浪费，而是换取可靠性。

## 用代码计算经验熵

下面的 Swift 程序统计字符串中字符的出现概率，再计算经验熵。它演示了概率、对数与 bit 单位的连接。真实压缩器还要考虑上下文、编码格式、字典和字节对齐。
"""#,
        codeLanguage: "swift",
        code: #"""
import Foundation

func entropy(of text: String) -> Double {
    let values = Array(text)
    guard !values.isEmpty else { return 0 }
    let counts = Dictionary(grouping: values, by: { $0 }).mapValues(\.count)
    return counts.values.reduce(0) { result, count in
        let probability = Double(count) / Double(values.count)
        return result - probability * log2(probability)
    }
}

let samples = [
    "aaaaaaaa",
    "abababab",
    "abcdefgh"
]

for sample in samples {
    print(sample, String(format: "%.3f bit/char", entropy(of: sample)))
}
"""#,
        secondCodeLanguage: "c",
        secondCode: #"""
// 计算 8 个符号的频率，并观察均匀分布熵最大
#include <math.h>
#include <stdio.h>

int main(void) {
    double probabilities[8];
    for (int i = 0; i < 8; ++i) probabilities[i] = 1.0 / 8.0;

    double h = 0.0;
    for (int i = 0; i < 8; ++i) {
        h -= probabilities[i] * log2(probabilities[i]);
    }
    printf("entropy=%.3f bits\n", h);
    return 0;
}
"""#,
        commonMistakes: #"""
- 把消息字节数当成信息熵。
- 认为 KL 散度对称或满足三角不等式。
- 只追求压缩率，忽略解码速度和格式边界。
- 把错误纠正码当成加密机制。
"""#
    )

    private static let automataTutorial = LearningTutorialSeed(
        id: "tutorial-theory-automata",
        order: 1,
        title: "状态机、正则与语法：机器如何识别语言",
        summary: "从 DFA、NFA、正则表达式到上下文无关文法，理解词法分析、协议和输入校验的理论基础。",
        markdown: #"""
# 从状态理解识别过程

自动机是抽象机器：读取输入符号，根据当前状态和转移规则进入新状态，最后判断是否接受。它把“某个字符串是否合法”变成“从起始状态出发，输入结束后是否到达接受状态”。状态图适合描述协议、词法器、按钮交互和工作流。

## DFA、NFA 与正则

确定性有限自动机在每个状态、每个输入符号最多有一个转移；非确定有限自动机可以同时有多条路径。两者识别能力相同，都能描述正则语言。NFA 可以通过子集构造转换为 DFA，DFA 也常被最小化以减少状态。

正则表达式是正则语言的紧凑表示。`*` 表示重复零次或多次，`+` 表示一次或多次，`?` 表示零次或一次。正则表达式不能计数任意深度的括号，也不能表达“n 个 a 后跟 n 个 b”；超过正则能力时需要使用上下文无关文法或更复杂模型。

## 文法与词法分析

上下文无关文法用产生式描述嵌套结构。编译器词法分析器通常使用有限状态机识别 token，语法分析器再根据文法构造语法树。这里体现了分层：词法阶段处理字符，语法阶段处理 token 关系。

协议解析同样如此。HTTP 请求行用简单规则识别，头部可以按键值解析，正文长度则由头部控制。把不同层次混在一个正则中，会导致难以调试和性能风险。

## Pumping Lemma 的作用

Pumping Lemma 用于证明某个语言不是正则语言，不能直接证明一个语言是正则。证明模板是假设语言正则，取足够长的字符串，按引理分解后寻找矛盾。理解它有助避免“所有文本都可以用一个正则解决”的错误。

## 实现 DFA

下面的 C 程序识别二进制字符串是否以 `01` 结尾。状态 0 表示没有匹配前缀，状态 1 表示刚读到一个 0，状态 2 表示已经读到 01。程序按状态转移表执行，最后只看状态 2。
"""#,
        codeLanguage: "c",
        code: #"""
// DFA：接受以 01 结尾的二进制字符串
#include <stdio.h>
#include <string.h>

enum State { START = 0, SAW_ZERO = 1, ACCEPT = 2 };

static int accepts(const char *input) {
    int state = START;
    for (size_t i = 0; input[i] != '\0'; ++i) {
        char symbol = input[i];
        if (symbol != '0' && symbol != '1') return 0;

        switch (state) {
            case START:
                state = symbol == '0' ? SAW_ZERO : START;
                break;
            case SAW_ZERO:
                state = symbol == '1' ? ACCEPT : SAW_ZERO;
                break;
            case ACCEPT:
                state = symbol == '0' ? SAW_ZERO : START;
                break;
        }
    }
    return state == ACCEPT;
}

int main(void) {
    const char *samples[] = {"01", "101", "100", "1101", "10"};
    for (size_t i = 0; i < sizeof(samples) / sizeof(samples[0]); ++i) {
        printf("%s -> %s\n", samples[i], accepts(samples[i]) ? "accept" : "reject");
    }
    return 0;
}
"""#,
        secondCodeLanguage: "swift",
        secondCode: #"""
import Foundation

enum TrafficState {
    case red, green, yellow
}

struct TrafficLight {
    private(set) var state: TrafficState = .red

    mutating func next() {
        switch state {
        case .red: state = .green
        case .green: state = .yellow
        case .yellow: state = .red
        }
    }
}

var light = TrafficLight()
for _ in 0..<4 {
    print(light.state)
    light.next()
}
"""#,
        commonMistakes: #"""
- 认为所有文本模式都能用正则表达式安全解决。
- 忘记 NFA 的“任意路径接受”语义，只追踪一条路径。
- 将有限状态机和栈机混为一谈。
- 状态机没有覆盖输入结束后如何判断接受。
"""#
    )

    private static let computabilityTutorial = LearningTutorialSeed(
        id: "tutorial-theory-computability",
        order: 1,
        title: "停机问题、P/NP 与归约：算法能力的边界",
        summary: "理解图灵机、可判定性、归约、P、NP、NP 完全和近似算法，知道哪些问题不应该继续寻找精确多项式解。",
        markdown: #"""
# 计算不是无限能力

程序可以处理非常大的输入，但并非所有问题都存在能在有限时间内给出答案的算法。计算理论区分“一个问题有形式定义”“存在算法”“算法效率可接受”三件事。理解边界可以避免错误的工程承诺。

## 图灵机与可计算性

图灵机用有限状态、无限纸带和读写头模拟机械计算。Church-Turing 论题认为可有效计算的函数与图灵机可计算函数一致。停机问题问：给定程序 P 和输入 x，P 是否最终停止？图灵证明不存在对所有程序和输入都正确的通用判定程序。

不可判定不等于完全无用。实际工程可以通过限制程序结构、设置超时、人工审查或近似分析获得有用结果，但不能宣称解决所有输入。

## 归约与难度传递

归约把问题 A 的实例转换成问题 B 的实例，使 A 的解可以由 B 的解恢复。如果 A 已知很难，而 B 能解决 A，则 B 也不容易。归约是复杂度证明的核心工具，也是算法设计中的问题转换方法。

NP 表示解可以在多项式时间内验证的问题。P 表示可以在多项式时间内求解的问题。P ⊆ NP 很明确，P 是否等于 NP 尚未解决。NP 完全问题既属于 NP，又能让所有 NP 问题归约到它，例如 SAT、旅行商判定版本和子集和。

## 面对 NP 完全问题

遇到 NP 完全问题时，不应假装找到了通用精确解。可选策略包括：限制输入规模、使用分支限界、整数规划、近似算法、随机算法、参数化算法或启发式。必须说明解的性质：最优、近似比、期望时间还是只在实际数据上有效。

## 暴力验证子集和

下面的程序用枚举验证小规模子集和问题。时间复杂度约为 `O(2^n * n)`，规模稍大就不可接受。它的价值是帮助你区分“小样例可计算”和“问题整体属于 NP 完全”。
"""#,
        codeLanguage: "c",
        code: #"""
// 小规模子集和：枚举所有子集并寻找目标和
#include <stdio.h>

static int subset_sum(const int *values, int count, int target) {
    unsigned long total = 1UL << count;
    for (unsigned long mask = 0; mask < total; ++mask) {
        int sum = 0;
        for (int i = 0; i < count; ++i) {
            if (mask & (1UL << i)) sum += values[i];
        }
        if (sum == target) return 1;
    }
    return 0;
}

int main(void) {
    int values[] = {3, 7, 1, 8, 4};
    printf("target 12: %s\n", subset_sum(values, 5, 12) ? "yes" : "no");
    printf("target 20: %s\n", subset_sum(values, 5, 20) ? "yes" : "no");
    return 0;
}
"""#,
        secondCodeLanguage: "swift",
        secondCode: #"""
import Foundation

// 用归约思维观察：求最长路径可以归约到判定“是否存在长度至少 k 的简单路径”。
func hasSimplePath(
    graph: [[Int]],
    current: Int,
    target: Int,
    visited: Set<Int>,
    remainingEdges: Int
) -> Bool {
    if remainingEdges == 0 { return current == target }
    for next in graph[current] where !visited.contains(next) {
        if hasSimplePath(
            graph: graph,
            current: next,
            target: target,
            visited: visited.union([next]),
            remainingEdges: remainingEdges - 1
        ) {
            return true
        }
    }
    return false
}

let graph = [[1, 2], [0, 3], [0, 3], [1, 2]]
print(hasSimplePath(graph: graph, current: 0, target: 3, visited: [0], remainingEdges: 3))
"""#,
        commonMistakes: #"""
- 把“我没有找到多项式算法”当成“证明不存在”。
- 混淆问题的判定版本和优化版本。
- 声称用启发式算法解决了所有 NP 完全实例。
- 忽略归约方向，反着证明难度。
"""#
    )

    private static let algorithmTheoryTutorial = LearningTutorialSeed(
        id: "tutorial-theory-algorithms",
        order: 1,
        title: "分治、动态规划与贪心：算法范式如何选择",
        summary: "用重叠子问题、最优子结构和交换论证比较分治、动态规划与贪心，并掌握递推和复杂度分析。",
        markdown: #"""
# 算法范式是问题结构的回答

同一个问题可能有多种算法。选择范式前，先判断问题是否可分解、子问题是否重叠、局部最优是否能产生全局最优、约束是否允许近似。背下模板很容易，识别适用条件才是核心能力。

## 分治

分治把问题拆成规模更小的同类子问题，分别求解后合并。归并排序把数组分成两半，排序后在线性时间合并；二分搜索只保留一半；快速选择平均线性时间找到第 k 小元素。分治复杂度常写成递推式，例如 `T(n)=2T(n/2)+O(n)`，可用主定理或递归树分析。

子问题独立是分治的优势，也让并行化更容易。代价是递归调用、数据复制和合并成本。

## 动态规划

动态规划适合具有重叠子问题和最优子结构的问题。先定义状态含义，再写转移，最后确定初始条件和计算顺序。状态定义错误时，转移再漂亮也没有意义。

背包问题中，状态 `dp[i][capacity]` 表示只考虑前 i 个物品、容量为 capacity 时的最大价值。每个物品可以选择或不选，因此转移取两种结果的最大值。空间可以压缩，但必须保证计算顺序不会覆盖还需要的数据。

## 贪心与交换论证

贪心每一步选择当前局部最优，只有能证明局部选择不会破坏全局最优时才正确。交换论证通常假设最优解与贪心解第一次不同，交换元素后仍不劣，从而推出矛盾。区间调度按结束时间排序是经典贪心；一般背包问题不能简单按价值或重量比贪心得到最优。

## 动态规划实现 0/1 背包

下面程序使用二维表展示状态含义。输入规模很小时便于观察；工程中还要处理容量上限、内存占用和数值溢出。
"""#,
        codeLanguage: "c",
        code: #"""
// 0/1 背包：dp[i][capacity]
#include <stdio.h>

#define MAX(a, b) ((a) > (b) ? (a) : (b))

static int knapsack(const int *weights, const int *values, int count, int capacity) {
    int dp[32][32] = {0};
    if (count > 31 || capacity > 31) return -1;

    for (int i = 1; i <= count; ++i) {
        for (int c = 0; c <= capacity; ++c) {
            dp[i][c] = dp[i - 1][c];
            if (weights[i - 1] <= c) {
                dp[i][c] = MAX(dp[i][c], dp[i - 1][c - weights[i - 1]] + values[i - 1]);
            }
        }
    }
    return dp[count][capacity];
}

int main(void) {
    int weights[] = {2, 3, 4, 5};
    int values[] = {3, 4, 5, 8};
    printf("max value=%d\n", knapsack(weights, values, 4, 7));
    return 0;
}
"""#,
        secondCodeLanguage: "swift",
        secondCode: #"""
import Foundation

// 分治：归并排序的一部分，展示合并步骤
func merge(_ left: [Int], _ right: [Int]) -> [Int] {
    var result: [Int] = []
    var i = 0, j = 0
    while i < left.count && j < right.count {
        if left[i] <= right[j] {
            result.append(left[i]); i += 1
        } else {
            result.append(right[j]); j += 1
        }
    }
    result.append(contentsOf: left[i...])
    result.append(contentsOf: right[j...])
    return result
}

print(merge([1, 4, 6], [2, 3, 7]))
"""#,
        commonMistakes: #"""
- 不定义状态含义就开始写动态规划转移。
- 贪心算法只看反例不够，需要证明或使用交换论证。
- 把平均复杂度当成最坏复杂度。
- 忽略整数溢出、容量上限和递归深度。
"""#
    )

    private static let semanticsTutorial = LearningTutorialSeed(
        id: "tutorial-theory-semantics",
        order: 1,
        title: "类型、不变量与程序语义：代码为什么正确",
        summary: "用状态、前置后置条件、不变量、Hoare 逻辑和类型系统解释程序行为，连接数学证明与工程测试。",
        markdown: #"""
# 程序语义是行为的精确描述

源代码只是文本，程序的意义来自它如何从初始状态产生最终状态。输入、内存、文件、网络和输出共同构成状态。操作改变状态，类型和断言限制哪些状态转换是合法的。没有语义，测试只能观察有限输入，无法解释为什么所有合法输入都正确。

## 操作语义、指称语义与公理语义

操作语义把程序看成抽象机器的执行步骤，适合解释递归、栈和并发。指称语义把程序映射为数学函数或关系，适合比较组合结构。公理语义使用前置条件、后置条件和推理规则证明程序事实。三种视角互补，不以一种替代另一种。

例如交换两个变量。操作语义描述读取和写入顺序；指称语义描述状态映射；公理语义写出输入 x=a、y=b 与输出 x=b、y=a。

## 不变量与 Hoare 逻辑

Hoare 三元组 `{P} S {Q}` 表示如果前置条件 P 在语句 S 前成立，且 S 正常终止，则后置条件 Q 成立。循环不变量是连接多次迭代的关键。对于并发程序，不变量还要考虑其他线程可以在何时观察和修改状态。

不变量不是注释摆设。把不变量写成可执行断言、测试属性或类型约束，机器才能帮助检查。属性测试可以生成大量输入寻找反例，但不能替代证明。

## 类型系统

类型系统限制程序可以如何组合，目标是更早发现错误。静态类型在运行前检查，动态类型在运行时检查。强类型不等于静态类型，脚本语言也可以是强类型；弱类型也不等于动态类型。

类型规则包含前提和结论。函数应用要求参数类型匹配返回类型，泛型保留类型关系，代数数据类型要求穷尽分支。类型系统的能力可以用可靠性、表达力和可推断性衡量，不能只看“宽松”或“严格”。

## 用状态机表达不变量

下面的 Swift 枚举把订单状态限制在合法集合中。`canTransition` 明确允许的状态转换，编译器检查 switch 是否穷尽。真实系统还要处理重复消息、并发和持久化，但先把状态空间写清楚。
"""#,
        codeLanguage: "swift",
        code: #"""
import Foundation

enum OrderState: String, CaseIterable {
    case created
    case paid
    case shipped
    case cancelled
}

enum OrderEvent {
    case pay
    case ship
    case cancel
}

func transition(_ state: OrderState, event: OrderEvent) -> OrderState? {
    switch (state, event) {
    case (.created, .pay): return .paid
    case (.paid, .ship): return .shipped
    case (.created, .cancel), (.paid, .cancel): return .cancelled
    default: return nil
    }
}

let states = OrderState.allCases
for state in states {
    for event in [OrderEvent.pay, .ship, .cancel] {
        print(state.rawValue, "->", String(describing: transition(state, event: event)))
    }
}
"""#,
        secondCodeLanguage: "c",
        secondCode: #"""
// 用 assert 记录前置条件；Release 构建中 assert 可能被移除。
#include <assert.h>
#include <stdio.h>

static int checked_divide(int numerator, int denominator) {
    assert(denominator != 0);
    int result = numerator / denominator;
    assert(result * denominator + (numerator % denominator) == numerator);
    return result;
}

int main(void) {
    printf("%d\n", checked_divide(17, 5));
    return 0;
}
"""#,
        commonMistakes: #"""
- 把头文件声明、文档注释和运行时断言混为一谈。
- 认为类型正确的程序一定满足业务不变量。
- 用测试替代所有证明，或反过来完全不运行实现。
- 并发程序仍按单线程状态转换推理。
"""#
    )

    private static let discreteChoice = LearningExerciseSeed(
        id: "exercise-math-discrete-choice",
        order: 1,
        title: "识别偏序关系",
        kind: .multipleChoice,
        question: "下面哪组关系最适合建模为偏序？",
        options: ["任意两人的年龄大小", "任务依赖关系", "两个随机数是否相等", "文件是否可读"],
        answer: "任务依赖关系",
        explanation: "任务依赖满足自反、反对称和传递，并且不要求任意两个任务可比较，因此是偏序。年龄通常可比较，更适合全序。",
        starterCode: "",
        codeLanguage: "c"
    )

    private static let discreteCode = LearningExerciseSeed(
        id: "exercise-math-discrete-code",
        order: 2,
        title: "实现集合运算",
        kind: .coding,
        question: "用位运算实现集合的交集、并集和差集，分别打印结果。",
        answer: #"""
#include <stdint.h>
#include <stdio.h>

int main(void) {
    uint8_t a = 0b1011;
    uint8_t b = 0b0110;
    printf("union=%u intersect=%u difference=%u\n", a | b, a & b, a & ~b);
    return 0;
}
"""#,
        explanation: "位运算适合固定范围的幂集表示。元素数量超过机器字长时，应使用位图数组或多个字。",
        starterCode: "#include <stdint.h>\n#include <stdio.h>\n\nint main(void) {\n    // 实现集合运算\n    return 0;\n}\n",
        codeLanguage: "c"
    )

    private static let proofChoice = LearningExerciseSeed(
        id: "exercise-math-proof-choice",
        order: 1,
        title: "正确理解蕴含",
        kind: .multipleChoice,
        question: "命题 `P → Q` 在什么情况下为假？",
        options: ["P 真且 Q 假", "P 假且 Q 真", "P 假且 Q 假", "只要 P 和 Q 都真"],
        answer: "P 真且 Q 假",
        explanation: "蕴含只禁止“前提为真、结论为假”的情况。前提为假时，蕴含为真。",
        starterCode: "",
        codeLanguage: "c"
    )

    private static let proofCode = LearningExerciseSeed(
        id: "exercise-math-proof-code",
        order: 2,
        title: "用断言记录循环不变量",
        kind: .coding,
        question: "写一个循环计算数组和，并在每轮记录 sum 等于前 i 个元素之和。",
        answer: #"""
#include <assert.h>
#include <stddef.h>
#include <stdio.h>

static long prefix_sum(const int *values, size_t end) {
    long result = 0;
    for (size_t i = 0; i < end; ++i) result += values[i];
    return result;
}

int main(void) {
    int values[] = {2, 3, 5, 7};
    long sum = 0;
    for (size_t i = 0; i < 4; ++i) {
        sum += values[i];
        // 每轮结束后，sum 等于前 i + 1 个元素之和
        assert(sum == prefix_sum(values, i + 1));
    }
    printf("%ld\n", sum);
    return 0;
}
"""#,
        explanation: "辅助函数让不变量可以直接比较。证明关注所有循环轮次，测试只负责寻找实现或假设的错误。",
        starterCode: "#include <stddef.h>\n#include <stdio.h>\n\nint main(void) {\n    // 记录循环不变量\n    return 0;\n}\n",
        codeLanguage: "c"
    )

    private static let linearChoice = LearningExerciseSeed(
        id: "exercise-math-linear-choice",
        order: 1,
        title: "矩阵乘法顺序",
        kind: .multipleChoice,
        question: "先旋转再缩放与先缩放再旋转通常是否相同？",
        options: ["相同，矩阵乘法满足交换律", "不同，矩阵乘法通常不满足交换律", "只有当矩阵是单位矩阵时才不同", "取决于向量维度"],
        answer: "不同，矩阵乘法通常不满足交换律",
        explanation: "线性变换的作用顺序会影响结果，因此矩阵乘法一般不交换。",
        starterCode: "",
        codeLanguage: "swift"
    )

    private static let linearCode = LearningExerciseSeed(
        id: "exercise-math-linear-code",
        order: 2,
        title: "实现向量点积",
        kind: .coding,
        question: "实现二维向量点积、模长和单位向量。",
        answer: #"""
import Foundation

struct Vector2 {
    let x: Double
    let y: Double

    func dot(_ other: Vector2) -> Double { x * other.x + y * other.y }
    var length: Double { sqrt(dot(self)) }
    var normalized: Vector2 { Vector2(x: x / length, y: y / length) }
}

let v = Vector2(x: 3, y: 4)
print(v.dot(Vector2(x: 1, y: 0)), v.length, v.normalized)
"""#,
        explanation: "单位向量要求非零模长；真实代码应先检查长度，避免除零。矩阵运算库还要处理维度和数值稳定性。",
        starterCode: "import Foundation\n\nstruct Vector2 {\n    let x: Double\n    let y: Double\n}\n",
        codeLanguage: "swift"
    )

    private static let probabilityChoice = LearningExerciseSeed(
        id: "exercise-math-probability-choice",
        order: 1,
        title: "条件概率",
        kind: .multipleChoice,
        question: "`P(A|B)` 的定义是什么？",
        options: ["P(A∩B)/P(B)", "P(A)+P(B)", "P(A)·P(B)", "P(B|A)"],
        answer: "P(A∩B)/P(B)",
        explanation: "条件概率是在已知 B 发生的条件下重新归一化。要求 P(B) 大于 0。",
        starterCode: "",
        codeLanguage: "c"
    )

    private static let probabilityCode = LearningExerciseSeed(
        id: "exercise-math-probability-code",
        order: 2,
        title: "模拟随机实验",
        kind: .coding,
        question: "模拟 10000 次掷两枚公平硬币，估计至少出现一次正面的频率。",
        answer: #"""
#include <stdio.h>
#include <stdlib.h>

int main(void) {
    int hits = 0;
    for (int i = 0; i < 10000; ++i) {
        int a = rand() % 2;
        int b = rand() % 2;
        if (a == 1 || b == 1) hits++;
    }
    printf("%.4f\n", hits / 10000.0);
    return 0;
}
"""#,
        explanation: "理论概率是 3/4。模拟值会波动，样本量越大通常越接近理论值。",
        starterCode: "#include <stdio.h>\n#include <stdlib.h>\n\nint main(void) {\n    // 完成模拟\n    return 0;\n}\n",
        codeLanguage: "c"
    )

    private static let informationChoice = LearningExerciseSeed(
        id: "exercise-math-information-choice",
        order: 1,
        title: "熵最大的分布",
        kind: .multipleChoice,
        question: "在有限个等可能结果中，哪种分布熵最大？",
        options: ["均匀分布", "只有一个结果概率为 1", "两个结果概率相差很大", "无法比较"],
        answer: "均匀分布",
        explanation: "在固定结果数量下，均匀分布的期望不确定性最大。",
        starterCode: "",
        codeLanguage: "c"
    )

    private static let informationCode = LearningExerciseSeed(
        id: "exercise-math-information-code",
        order: 2,
        title: "统计字符频率并计算熵",
        kind: .coding,
        question: "读取一组字符统计频率，并计算经验熵。",
        answer: #"""
import Foundation

let text = "abracadabra"
let counts = Dictionary(grouping: text, by: { $0 }).mapValues(\.count)
let total = Double(text.count)
let entropy = counts.values.reduce(0.0) { result, count in
    let p = Double(count) / total
    return result - p * log2(p)
}
print(entropy)
"""#,
        explanation: "经验熵只反映当前样本，不代表真实来源分布。空输入需要单独处理。",
        starterCode: "import Foundation\n\n// 统计字符频率并计算经验熵\n",
        codeLanguage: "swift"
    )

    private static let automataChoice = LearningExerciseSeed(
        id: "exercise-theory-automata-choice",
        order: 1,
        title: "识别语言能力",
        kind: .multipleChoice,
        question: "语言 `{ 0^n 1^n | n≥0 }` 是否属于正则语言？",
        options: ["不属于，通常需要栈或更强模型", "属于，可以用一个短正则表示", "只属于 DFA", "取决于字符串长度"],
        answer: "不属于，通常需要栈或更强模型",
        explanation: "正则语言无法计数任意数量的 0 和 1，需要用上下文无关文法或下推自动机。",
        starterCode: "",
        codeLanguage: "c"
    )

    private static let automataCode = LearningExerciseSeed(
        id: "exercise-theory-automata-code",
        order: 2,
        title: "实现一个 DFA",
        kind: .coding,
        question: "实现识别二进制字符串是否以 `01` 结尾的 DFA。",
        answer: #"""
#include <stddef.h>
#include <stdio.h>

int accepts(const char *s) {
    int state = 0;
    for (size_t i = 0; s[i]; ++i) {
        if (s[i] == '0') state = state == 1 || state == 2 ? 1 : 1;
        else if (s[i] == '1') state = state == 1 ? 2 : 0;
        else return 0;
    }
    return state == 2;
}

int main(void) {
    printf("%d %d\n", accepts("01"), accepts("10"));
    return 0;
}
"""#,
        explanation: "实现状态机时要先写转移表，再写代码；不要用 if 堆叠代替状态设计。",
        starterCode: "#include <stdio.h>\n\nint main(void) {\n    // 实现 DFA\n    return 0;\n}\n",
        codeLanguage: "c"
    )

    private static let computabilityChoice = LearningExerciseSeed(
        id: "exercise-theory-computability-choice",
        order: 1,
        title: "NP 的含义",
        kind: .multipleChoice,
        question: "NP 最准确的含义是什么？",
        options: ["解可以在多项式时间验证", "没有多项式算法", "一定不能在多项式时间求解", "所有随机算法的集合"],
        answer: "解可以在多项式时间验证",
        explanation: "NP 是可由非确定图灵机在多项式时间接受的问题，也等价于解能在多项式时间验证。P 是否等于 NP 是未解决问题。",
        starterCode: "",
        codeLanguage: "c"
    )

    private static let computabilityCode = LearningExerciseSeed(
        id: "exercise-theory-computability-code",
        order: 2,
        title: "枚举小规模子集和",
        kind: .coding,
        question: "用位掩码枚举 n≤10 的子集，判断是否存在目标和。",
        answer: #"""
#include <stdbool.h>
#include <stdio.h>

bool subset_sum(const int *a, int n, int target) {
    for (unsigned mask = 0; mask < (1u << n); ++mask) {
        int sum = 0;
        for (int i = 0; i < n; ++i) if (mask & (1u << i)) sum += a[i];
        if (sum == target) return true;
    }
    return false;
}

int main(void) {
    int a[] = {3, 1, 4, 2};
    printf("%d\n", subset_sum(a, 4, 6));
    return 0;
}
"""#,
        explanation: "位掩码枚举只适合很小规模。面对一般子集和问题，不能把指数算法包装成通用精确解。",
        starterCode: "#include <stdbool.h>\n#include <stdio.h>\n\nint main(void) {\n    return 0;\n}\n",
        codeLanguage: "c"
    )

    private static let algorithmChoice = LearningExerciseSeed(
        id: "exercise-theory-algorithms-choice",
        order: 1,
        title: "选择动态规划",
        kind: .multipleChoice,
        question: "什么时候最适合优先考虑动态规划？",
        options: ["子问题重叠且具有最优子结构", "每一步局部最优都能证明全局最优", "输入只有一个元素", "算法必须随机运行"],
        answer: "子问题重叠且具有最优子结构",
        explanation: "动态规划用状态保存重叠子问题的结果，并通过最优子结构组合答案。",
        starterCode: "",
        codeLanguage: "c"
    )

    private static let algorithmCode = LearningExerciseSeed(
        id: "exercise-theory-algorithms-code",
        order: 2,
        title: "写出一维背包动态规划",
        kind: .coding,
        question: "把 0/1 背包从二维表压缩为一维数组，并说明逆序更新的原因。",
        answer: #"""
#include <stdio.h>

int main(void) {
    int weights[] = {2, 3, 4, 5};
    int values[] = {3, 4, 5, 8};
    int dp[8] = {0};
    for (int i = 0; i < 4; ++i) {
        for (int c = 7; c >= weights[i]; --c) {
            int candidate = dp[c - weights[i]] + values[i];
            if (candidate > dp[c]) dp[c] = candidate;
        }
    }
    printf("%d\n", dp[7]);
    return 0;
}
"""#,
        explanation: "逆序遍历容量可以避免同一物品在当前轮被重复使用；二维表的每一行对应一个物品决策。",
        starterCode: "#include <stdio.h>\n\nint main(void) {\n    // 一维背包\n    return 0;\n}\n",
        codeLanguage: "c"
    )

    private static let semanticsChoice = LearningExerciseSeed(
        id: "exercise-theory-semantics-choice",
        order: 1,
        title: "类型正确与业务正确",
        kind: .multipleChoice,
        question: "一个函数所有参数类型正确，是否一定满足业务不变量？",
        options: ["不一定，类型只约束表示和组合", "一定，类型系统能证明所有业务规则", "只有 Swift 能保证", "只有运行时才能确定"],
        answer: "不一定，类型只约束表示和组合",
        explanation: "类型系统可以发现一部分错误，但业务不变量仍需用前置条件、断言、测试或形式化证明表达。",
        starterCode: "",
        codeLanguage: "swift"
    )

    private static let semanticsCode = LearningExerciseSeed(
        id: "exercise-theory-semantics-code",
        order: 2,
        title: "为订单状态机写转移",
        kind: .coding,
        question: "用 Swift 实现 created、paid、shipped、cancelled 的合法转换。",
        answer: #"""
enum State { case created, paid, shipped, cancelled }
enum Event { case pay, ship, cancel }

func next(_ state: State, _ event: Event) -> State? {
    switch (state, event) {
    case (.created, .pay): return .paid
    case (.paid, .ship): return .shipped
    case (.created, .cancel), (.paid, .cancel): return .cancelled
    default: return nil
    }
}
"""#,
        explanation: "状态机把合法转换写成可检查的数据和分支，便于测试和并发协议设计。",
        starterCode: "enum State { case created, paid, shipped, cancelled }\n",
        codeLanguage: "swift"
    )
}
