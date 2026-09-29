import SwiftUI

struct InteractiveLabView: View {
    let labID: String

    var body: some View {
        Group {
            switch labID {
            case "bits": BitLabView()
            case "memory": MemoryLabView()
            case "tcp": TCPHandshakeLabView()
            case "hash": HashLabView()
            default: ContentUnavailableView("实验不存在", systemImage: "testtube.2")
            }
        }
        .navigationTitle(labTitle)
    }

    private var labTitle: String {
        LabCatalog.labs.first { $0.id == labID }?.title ?? "互动实验室"
    }
}

private struct BitLabView: View {
    @State private var value = 5

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text("点击每一位，让它变成 0 或 1。位权从高到低是 128、64、32、16、8、4、2、1。")
                    .foregroundStyle(.secondary)

                HStack(spacing: 8) {
                    ForEach((0..<8).reversed(), id: \.self) { bit in
                        bitButton(bit)
                    }
                }

                HStack {
                    metric("十进制", "\(value)")
                    metric("十六进制", String(format: "0x%02X", value))
                    metric("二进制", String(value, radix: 2))
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("权限解释")
                        .font(.headline)
                    Text("READ = \(value & 1)   WRITE = \((value >> 1) & 1)   EXECUTE = \((value >> 2) & 1)")
                        .font(.system(.body, design: .monospaced))
                    Text("计算机常用位标志在一个整数中保存多个开关，按位与用于检查某个开关是否打开。")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .learningCard()
            }
            .padding()
            .learningPageWidth()
        }
        .background(Color.appBackground)
    }

    private func bitButton(_ bit: Int) -> some View {
        let isOn = (value & (1 << bit)) != 0

        return Button {
            value ^= (1 << bit)
        } label: {
            VStack(spacing: 5) {
                Text(isOn ? "1" : "0")
                    .font(.title.bold().monospacedDigit())
                Text("1<<\(bit)")
                    .font(.caption2.monospaced())
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                isOn ? Color.indigo : Color.secondary.opacity(0.1),
                in: RoundedRectangle(cornerRadius: 12)
            )
            .foregroundStyle(isOn ? Color.white : Color.primary)
        }
        .buttonStyle(.plain)
    }

    private func metric(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title).font(.caption).foregroundStyle(.secondary)
            Text(value).font(.headline.monospaced())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(.indigo.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
    }
}

private struct MemoryLabView: View {
    private let segments = [
        ("代码段", "只读指令和常量", "可执行、只读", "text"),
        ("全局/静态区", "全局变量和静态变量", "程序启动到结束", "globe"),
        ("堆", "malloc/calloc 动态分配", "程序员显式释放", "arrow.up.and.down"),
        ("栈", "局部变量、参数、返回地址", "函数调用期间", "square.stack.3d.up")
    ]

    @State private var selected = 3

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text("进程地址空间是理解 C、指针、递归和系统编程的底层地图。点击区域查看生命周期。")
                    .foregroundStyle(.secondary)

                VStack(spacing: 8) {
                    ForEach(Array(segments.enumerated()), id: \.offset) { index, segment in
                        Button {
                            selected = index
                        } label: {
                            HStack {
                                Image(systemName: segment.3)
                                    .frame(width: 28)
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(segment.0).font(.headline)
                                    Text(segment.1).font(.caption).foregroundStyle(.secondary)
                                }
                                Spacer()
                                Text(index == selected ? "查看中" : "")
                                    .font(.caption.weight(.bold))
                            }
                            .padding(14)
                            .background(index == selected ? Color.teal.opacity(0.15) : Color.secondary.opacity(0.06), in: RoundedRectangle(cornerRadius: 13))
                        }
                        .buttonStyle(.plain)
                    }
                }

                let current = segments[selected]
                VStack(alignment: .leading, spacing: 8) {
                    Text(current.0).font(.title3.bold())
                    Text(current.1).foregroundStyle(.secondary)
                    Text("生命周期：\(current.2)")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.teal)
                }
                .learningCard()
            }
            .padding()
            .learningPageWidth()
        }
        .background(Color.appBackground)
    }
}

private struct TCPHandshakeLabView: View {
    @State private var step = 0
    private let steps = [
        ("客户端", "服务器", "SYN", "客户端请求建立连接，并发送自己的初始序号。"),
        ("服务器", "客户端", "SYN-ACK", "服务器同意连接，同时发送自己的初始序号并确认客户端序号。"),
        ("客户端", "服务器", "ACK", "客户端确认服务器序号，连接进入 ESTABLISHED。")
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("逐帧观察 TCP 三次握手。实际网络还会受延迟、丢包、重传和超时影响。")
                    .foregroundStyle(.secondary)

                HStack(spacing: 40) {
                    endpoint("客户端", icon: "laptopcomputer")
                    Image(systemName: step < 3 ? "arrow.right" : "checkmark.circle.fill")
                        .font(.largeTitle)
                        .foregroundStyle(step < 3 ? .blue : .green)
                    endpoint("服务器", icon: "server.rack")
                }
                .frame(maxWidth: .infinity)

                if step < steps.count {
                    let item = steps[step]
                    VStack(alignment: .leading, spacing: 10) {
                        Text("第 \(step + 1) 步 · \(item.2)")
                            .font(.title3.bold())
                        Text("\(item.0) → \(item.1)")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.blue)
                        Text(item.3)
                            .foregroundStyle(.secondary)
                    }
                    .learningCard()
                } else {
                    Label("连接已建立", systemImage: "checkmark.seal.fill")
                        .font(.headline)
                        .foregroundStyle(.green)
                        .learningCard()
                }

                Button {
                    if step < steps.count { step += 1 } else { step = 0 }
                } label: {
                    Label(step < steps.count ? "发送下一帧" : "重新演示", systemImage: "play.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.blue)
            }
            .padding()
            .learningPageWidth()
        }
        .background(Color.appBackground)
    }

    private func endpoint(_ name: String, icon: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon).font(.system(size: 42)).foregroundStyle(.blue)
            Text(name).font(.headline)
        }
    }
}

private struct HashLabView: View {
    @State private var keys: [String] = ["apple", "banana", "cherry"]

    private let candidates = ["date", "elder", "fig", "grape", "kiwi", "lemon"]

    private func bucket(_ key: String) -> Int {
        key.unicodeScalars.reduce(0) { ($0 + Int($1.value)) % 5 }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text("哈希函数把键映射到桶。不同键落到同一个桶就叫碰撞，链地址法用链表保存它们。")
                    .foregroundStyle(.secondary)

                VStack(spacing: 8) {
                    ForEach(0..<5, id: \.self) { index in
                        let bucketKeys = keys.filter { bucket($0) == index }
                        HStack {
                            Text("桶 \(index)")
                                .font(.headline.monospacedDigit())
                                .frame(width: 52, alignment: .leading)
                            if bucketKeys.isEmpty {
                                Text("空").foregroundStyle(.secondary)
                            } else {
                                ForEach(bucketKeys, id: \.self) { key in
                                    Text(key)
                                        .font(.subheadline.weight(.semibold))
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 7)
                                        .background(.orange.opacity(0.12), in: Capsule())
                                    Image(systemName: "arrow.right").font(.caption)
                                }
                            }
                            Spacer()
                        }
                        .padding(12)
                        .background(.secondary.opacity(0.06), in: RoundedRectangle(cornerRadius: 12))
                    }
                }

                HStack {
                    Text("元素：\(keys.count) · 桶：5 · 负载因子：\(String(format: "%.1f", Double(keys.count) / 5.0))")
                        .font(.subheadline)
                    Spacer()
                    Button("加入键") {
                        let next = candidates[keys.count % candidates.count]
                        keys.append(next)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.orange)
                }
                .learningCard()
            }
            .padding()
            .learningPageWidth()
        }
        .background(Color.appBackground)
    }
}
