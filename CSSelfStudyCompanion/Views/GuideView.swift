import SwiftUI

struct GuideView: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 18) {
                hero
                quickStart
                ForEach(GuideContent.sections) { section in
                    GuideSectionCard(section: section)
                }
                troubleshooting
            }
            .padding()
            .learningPageWidth()
        }
        .background(Color.appBackground)
        .navigationTitle("使用指南")
    }

    private var hero: some View {
        ZStack(alignment: .topTrailing) {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "263B8F"), Color(hex: "7357C8"), Color(hex: "16A6A0")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Image(systemName: "book.pages.fill")
                .font(.system(size: 88, weight: .bold))
                .foregroundStyle(.white.opacity(0.1))
                .offset(x: -18, y: 58)

            VStack(alignment: .leading, spacing: 10) {
                Text("从第一次打开开始")
                    .font(.title2.bold())
                    .foregroundStyle(.white)
                Text("这款 App 不是让你从第一页翻到最后一页。正确方式是：选阶段、按步骤学习、动手运行、完成练习、进入复习，再用项目验收。")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.82))
                    .lineSpacing(4)
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .shadow(color: .purple.opacity(0.18), radius: 14, y: 7)
    }

    private var quickStart: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("5 分钟快速上手", systemImage: "flag.checkered")
                .font(.title3.bold())

            ViewThatFits(in: .horizontal) {
                HStack(alignment: .top, spacing: 10) {
                    ForEach(Array(GuideContent.quickSteps.enumerated()), id: \.offset) { index, step in
                        quickStep(index: index, step: step)
                    }
                }

                VStack(alignment: .leading, spacing: 10) {
                    ForEach(Array(GuideContent.quickSteps.enumerated()), id: \.offset) { index, step in
                        quickStep(index: index, step: step)
                    }
                }
            }
        }
        .learningCard()
    }

    private func quickStep(index: Int, step: GuideItem) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Text("\(index + 1)")
                .font(.headline.monospacedDigit())
                .foregroundStyle(.white)
                .frame(width: 30, height: 30)
                .background(.indigo.gradient, in: Circle())
            Text(step.title)
                .font(.subheadline.bold())
            Text(step.detail)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(dynamicTypeSize.isAccessibilitySize ? nil : 4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(.indigo.opacity(0.07), in: RoundedRectangle(cornerRadius: 14))
        .accessibilityElement(children: .combine)
    }

    private var troubleshooting: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("遇到问题怎么办", systemImage: "wrench.and.screwdriver.fill")
                .font(.title3.bold())
            FAQRow(question: "不知道从哪里开始？", answer: "回到首页，点击“今日建议”或“自适应路线”。系统会结合概念依赖、教程完成度、练习和复习掌握度，推荐下一步以及需要优先补桥的前置内容。")
            FAQRow(question: "教程太长怎么办？", answer: "在教程页切换“快速 / 标准 / 深度”。快速模式只保留核心理解和基础实验，深度模式再展开全部内容。")
            FAQRow(question: "可验证实验课怎么完成？", answer: "按“目标、预测、准备、执行、验证、复盘”六步前进。执行阶段保存原始输出和退出码，验证阶段逐条勾选验收清单，复盘阶段写根因和收获；未通过时可以一键加入复习。")
            FAQRow(question: "代码运行失败？", answer: "先看标准错误，从第一条错误开始修复。macOS 会直接编译运行；iPhone 会连接同一局域网内正在运行的 Mac，由 Mac 在沙盒中编译并把输出返回手机。")
            FAQRow(question: "项目太多不知道怎么选？", answer: "打开“项目作品集”，先按轨道筛选，再使用“推荐下一项工程”。推荐项会按工程阶梯顺序选择第一个尚未验收的项目。若前置条件未满足，先回到对应阶段教程。")
            FAQRow(question: "数学和计算理论怎么学？", answer: "阶段 4 先学集合、证明、线性代数、概率和信息论；阶段 5 再进入自动机、可计算性、复杂度、算法范式和程序语义。每个教程都可以运行代码、完成练习，并配套逻辑真值表、自动机、概率实验和复杂度增长互动实验室。")
            FAQRow(question: "开源源码看不懂？", answer: "不要直接从仓库第一行开始。进入“代码阅读训练 → 开源阅读阶梯”，从 L0 单文件入口开始，按仓库地图、入口、追踪任务、证据和复盘六步推进，并记录阅读日期，因为仓库会持续变化。")
            FAQRow(question: "答错了怎么办？", answer: "选择题会自动进入错题本，并按 1、3、7、30 天安排复习。编程题可以手动加入错题本。")
            FAQRow(question: "换设备后数据怎么办？", answer: "优先让 Mac 和 iPhone 连接同一 Wi-Fi 自动增量同步；也可以使用“数据与备份”导出普通或 AES-GCM 加密备份。App 升级会使用版本化 SwiftData Schema 自动迁移。")
        }
        .learningCard()
    }
}

private struct GuideSectionCard: View {
    let section: GuideSection

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(section.title, systemImage: section.icon)
                .font(.title3.bold())
                .foregroundStyle(section.tint)

            ForEach(Array(section.items.enumerated()), id: \.offset) { _, item in
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.subheadline)
                        .foregroundStyle(section.tint)
                        .padding(.top, 2)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(item.title)
                            .font(.subheadline.bold())
                        Text(item.detail)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineSpacing(3)
                    }
                }
            }
        }
        .learningCard()
    }
}

private struct FAQRow: View {
    let question: String
    let answer: String

    var body: some View {
        DisclosureGroup {
            Text(answer)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineSpacing(3)
                .padding(.top, 6)
        } label: {
            Text(question)
                .font(.subheadline.bold())
        }
    }
}

struct GuideLink: View {
    var body: some View {
        NavigationLink {
            GuideView()
        } label: {
            Label("使用指南", systemImage: "book.pages")
        }
    }
}

private struct GuideItem {
    let title: String
    let detail: String
}

private struct GuideSection: Identifiable {
    let id: String
    let title: String
    let icon: String
    let tint: Color
    let items: [GuideItem]
}

private enum GuideContent {
    static let quickSteps: [GuideItem] = [
        GuideItem(title: "确定起点", detail: "完成首次入学诊断，系统会推荐起始阶段。"),
        GuideItem(title: "进入主题", detail: "查看教程、练习和预计时间。"),
        GuideItem(title: "分步学习", detail: "先理解，再运行，再完成练习。"),
        GuideItem(title: "安排复习", detail: "错题和回忆内容自动进入复习。"),
        GuideItem(title: "做项目", detail: "用里程碑和交付物完成结业。")
    ]

    static let sections: [GuideSection] = [
        GuideSection(
            id: "roadmap",
            title: "学习路线怎么用",
            icon: "point.topleft.down.to.point.bottomright.curvepath",
            tint: .indigo,
            items: [
                GuideItem(title: "阶段顺序", detail: "阶段 0 到 12 按基础依赖排序：数学与计算理论位于 Linux 之后、数据结构与系统课程之前。建议完成当前阶段的必修内容，再进入下一阶段。"),
                GuideItem(title: "今日建议", detail: "首页会优先推荐到期复习、掌握度较低的概念，以及下一个未完成阶段。"),
                GuideItem(title: "今日三步计划", detail: "系统根据复习、薄弱概念和下一课自动生成约 60 分钟的三步任务。"),
                GuideItem(title: "阶段卡片", detail: "卡片显示主题数量、预计时间和完成百分比，点击进入阶段详情。"),
                GuideItem(title: "数学与理论主线", detail: "阶段 4 覆盖离散数学、证明、线性代数、概率和信息论；阶段 5 覆盖自动机、可计算性、复杂度、算法范式和程序语义。两条阶段会自动进入教程、实验、练习和复习闭环。"),
                GuideItem(title: "自适应路线", detail: "首页和阶段页会显示就绪度，区分“可开始”“建议复习”和“需要补桥”。系统只调整推荐顺序，不会锁住教程，你仍然可以自由学习。")
            ]
        ),
        GuideSection(
            id: "tutorial",
            title: "教程页怎么用",
            icon: "book.pages.fill",
            tint: .blue,
            items: [
                GuideItem(title: "可验证实验课", detail: "每篇教程顶部都有六步实验：目标、预测、准备、执行、验证、复盘。实验证据会持久化保存，验收清单和复习状态随学习数据同步。"),
                GuideItem(title: "学习模式", detail: "快速模式只看核心理解与基础实验；标准模式覆盖实践、工程和巩固；深度模式展开全部大师挑战。"),
                GuideItem(title: "阶段导航", detail: "教程分为开始、理解、实践、进阶、巩固、强化、融会、大师八个阶段。"),
                GuideItem(title: "教回去", detail: "在阅读正文前按“结论—原因—例子—边界”讲清楚。系统会从概念覆盖、因果、例子、结构和完整程度五个维度评估，并保存反馈。"),
                GuideItem(title: "关联概念", detail: "步骤中出现的术语会显示为概念标签，点击可以查看定义、前置知识和相关教程。"),
                GuideItem(title: "收藏与笔记", detail: "右上角可以收藏当前步骤或写笔记，退出教程后仍会保留。")
            ]
        ),
        GuideSection(
            id: "resources",
            title: "配套资源怎么用",
            icon: "link.circle.fill",
            tint: .cyan,
            items: [
                GuideItem(title: "应用内阅读", detail: "点击资源卡片上的“阅读”，可以直接在 App 内打开网页并返回原教程位置。"),
                GuideItem(title: "链接检查", detail: "资源卡片上的“检查链接”会显示 HTTP 状态，帮助判断网站是否可访问。"),
                GuideItem(title: "资源笔记", detail: "每份资源都可以单独写笔记，记录重点、疑问和实验结论。"),
                GuideItem(title: "学习状态", detail: "资源可以标记“稍后看”或“已完成”，状态会随学习数据一起同步。"),
                GuideItem(title: "收藏资源", detail: "点击书签图标即可收藏资源，取消后自动移除。"),
                GuideItem(title: "外部浏览器", detail: "如果网页需要登录或复杂交互，可以点击“浏览器”交给系统浏览器打开。")
            ]
        ),
        GuideSection(
            id: "exercise",
            title: "练习与代码工作台",
            icon: "hammer.fill",
            tint: .orange,
            items: [
                GuideItem(title: "选择题", detail: "选择答案后立即显示正误和解析。答错会自动加入错题本。"),
                GuideItem(title: "代码工作台", detail: "编辑代码、填写测试输入、编译运行，并查看标准输出、标准错误和退出码。"),
                GuideItem(title: "自动判题", detail: "配置了测试用例的题目会自动比较输出。Command + Return 可以快速运行。"),
                GuideItem(title: "Mac 伴生运行", detail: "iPhone 与 Mac 连接同一 Wi-Fi 并同时打开 App 后，iPhone 会把代码发送到 Mac 编译，再接收标准输出和错误。"),
                GuideItem(title: "代码安全", detail: "Mac 使用原生资源限制启动器和 sandbox-exec：禁用网络、限制 4 秒 CPU、256 MB 内存、2 MB 文件和输出、64 个文件描述符和进程数，并禁止用户程序调用 shell 或 fork。每个客户端每分钟最多远程执行 10 次。"),
                GuideItem(title: "Mac 菜单栏代理", detail: "Mac 版关闭主窗口后仍会留在菜单栏，显示同步状态、远程运行摘要，并提供立即同步、打开主窗口和关闭远程代码执行开关。")
            ]
        ),
        GuideSection(
            id: "code-reading",
            title: "代码阅读训练",
            icon: "doc.text.magnifyingglass",
            tint: .teal,
            items: [
                GuideItem(title: "进入入口", detail: "首页的“代码阅读”同时提供短代码推理题和六级开源源码阅读阶梯。"),
                GuideItem(title: "代码推理题", detail: "先阅读代码、预测输出、定位错误，再选择答案并查看解释；错误题目会自动进入复习。"),
                GuideItem(title: "开源阅读阶梯", detail: "从 coreutils 单文件入口，逐步进入 Git、curl、Redis、SQLite、Nginx、Linux、LLVM 和 Swift 等真实仓库。"),
                GuideItem(title: "六步阅读法", detail: "每条路线按目标、仓库地图、入口路径、追踪任务、证据和复盘推进，并要求保存源码位置、调用链和真实输出。"),
                GuideItem(title: "错题复习", detail: "完成不充分或需要巩固的阅读任务可以加入复习，下一次重新说明调用链和证据。")
            ]
        ),
        GuideSection(
            id: "review",
            title: "复习中心怎么用",
            icon: "brain.head.profile",
            tint: .teal,
            items: [
                GuideItem(title: "今日复习", detail: "处理所有已经到期的内容。到期条目会显示具体复习阶段。"),
                GuideItem(title: "错题本", detail: "保存选择题错误、编程题和需要重做的内容。"),
                GuideItem(title: "间隔计划", detail: "内容会根据回答结果在 1、3、7、30 天之间推进，答错会重置。"),
                GuideItem(title: "记忆状态", detail: "系统记录难度、稳定度、答题耗时和正确次数，连续失败会标记为顽固卡点。")
            ]
        ),
        GuideSection(
            id: "knowledge",
            title: "知识中心怎么用",
            icon: "magnifyingglass",
            tint: .purple,
            items: [
                GuideItem(title: "全局搜索", detail: "可以搜索教程正文、章节、概念、命令、收藏和笔记。"),
                GuideItem(title: "概念网络", detail: "概念按类别组织，并显示前置知识，避免跳过必要基础。"),
                GuideItem(title: "回到原文", detail: "从收藏或笔记可以回到对应的教程步骤，而不是重新查找。"),
                GuideItem(title: "命令速查", detail: "命令页支持平台筛选、分类筛选、搜索和一键复制。")
            ]
        ),
        GuideSection(
            id: "projects",
            title: "项目和互动实验",
            icon: "shippingbox.fill",
            tint: .green,
            items: [
                GuideItem(title: "工程阶梯", detail: "项目按 C/Linux、系统并发、网络服务、数据存储、编译器和 Apple 平台六条轨道排列，从 CLI 工具逐步进入服务器和存储引擎。"),
                GuideItem(title: "工程档案", detail: "每个项目都有预计工时、前置条件、仓库地图、分阶段里程碑、质量门禁、发布清单和配套开源阅读。"),
                GuideItem(title: "开始项目", detail: "先复制 README 草案建立仓库骨架，再逐项完成阶段；每个里程碑可以单独写工程证据，通过标准需要源码、测试或运行结果支持。"),
                GuideItem(title: "工程验收工作台", detail: "在项目详情中打开工作台并选择项目目录，系统会检查仓库结构、README、许可证、测试入口、Git 状态、代码卫生和可用构建命令。macOS 可以直接运行构建与测试，iOS 只执行静态验收。"),
                GuideItem(title: "验收报告", detail: "工作台会计算静态得分并生成 Markdown 报告，可复制、分享或保存到项目证据。构建命令通过后，构建门禁会更新为通过。"),
                GuideItem(title: "项目作品集", detail: "作品集按轨道展示推荐下一项工程、项目完成度、质量门禁和 Markdown 导出报告。"),
                GuideItem(title: "互动实验室", detail: "位运算、内存布局、TCP 握手和哈希碰撞可以通过操作观察原理，不要只看结论。")
            ]
        ),
        GuideSection(
            id: "progress",
            title: "进度和掌握度",
            icon: "chart.bar.xaxis",
            tint: .pink,
            items: [
                GuideItem(title: "完成度", detail: "完成教程和练习会更新阶段、主题和总进度。"),
                GuideItem(title: "掌握度", detail: "主动回忆、练习、代码判题和复习都会改变概念掌握分数。"),
                GuideItem(title: "薄弱概念", detail: "低于掌握阈值的概念会出现在优先加强列表。"),
                GuideItem(title: "动态训练", detail: "练习页会根据薄弱概念动态生成题目，并混排不同主题。答错会立即进入复习，答对后进入正常间隔训练。"),
                GuideItem(title: "掌握热力图", detail: "按概念类别显示掌握度颜色；灰色表示还没有练习或复习证据，点击方块可以进入概念详情。"),
                GuideItem(title: "推荐下一步", detail: "系统会优先安排到期复习和薄弱概念，再推荐继续阶段。"),
                GuideItem(title: "每日提醒", detail: "进度页可以开启每天固定时间的学习提醒，并可随时修改时间或关闭。"),
                GuideItem(title: "性能与稳定性", detail: "查看数据库大小、打开耗时、同步耗时和运行指标。"),
                GuideItem(title: "发布就绪", detail: "检查版本、深链接、本地网络权限、图标和签名状态，并查看正式分发限制。")
            ]
        ),
        GuideSection(
            id: "backup",
            title: "数据备份与跨设备",
            icon: "externaldrive.fill",
            tint: .cyan,
            items: [
                GuideItem(title: "导出数据", detail: "可以导出普通 JSON，也可以设置密码生成 AES-GCM 加密备份。"),
                GuideItem(title: "迁移方法", detail: "在 Mac 导出文件，通过 AirDrop、文件 App 或 iCloud Drive 发到 iPhone，再在 iPhone 导入。"),
                GuideItem(title: "CloudKit 可选同步", detail: "配置付费 Apple Developer 账号的 iCloud Container 后，可以手动上传云端备份并下载合并。未配置时不会影响现有局域网同步。"),
                GuideItem(title: "课程包与更新", detail: "在“数据与备份 → 课程包与更新”中可以导出课程 JSON、导入本地课程包，或通过 HTTPS 下载新课程。课程使用稳定 ID 更新，不会重置学习进度。"),
                GuideItem(title: "更新历史", detail: "课程更新会记录版本、时间和新增/更新数量，最多保留最近 20 条。"),
                GuideItem(title: "增量同步", detail: "同一 Wi-Fi 下只需在数据发生变化时发送增量指纹，不再每 6 秒重复发送完整备份；进度、收藏、笔记、复习、代码草稿、掌握度和资源状态会自动合并。"),
                GuideItem(title: "自动迁移", detail: "课程数据使用版本化 SwiftData Schema。App 升级后会自动执行迁移，避免更新丢失学习记录。"),
                GuideItem(title: "迁移内容", detail: "包括进度、收藏、笔记、错题、复习计划、代码草稿和掌握度。"),
                GuideItem(title: "恢复原则", detail: "导入会按记录合并；建议在覆盖大量数据前先导出一份当前备份。"),
                GuideItem(title: "Spotlight 与 Handoff", detail: "教程和命令会进入 Spotlight 搜索；同一 Apple ID 设备可以使用 Handoff 继续当前教程。"),
                GuideItem(title: "深链接", detail: "支持 csxuexi://tutorial、stage、project、lab、code-reading 等地址。"),
                GuideItem(title: "无障碍", detail: "支持 VoiceOver、动态字体、高对比度、减少颜色差异化和更明确的按钮朗读标签。")
            ]
        )
    ]
}
