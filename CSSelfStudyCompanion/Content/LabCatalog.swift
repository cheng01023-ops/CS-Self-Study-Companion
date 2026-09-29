import Foundation

struct LearningLab: Identifiable {
    let id: String
    let title: String
    let summary: String
    let icon: String
    let themeHex: String
}

enum LabCatalog {
    static let labs: [LearningLab] = [
        LearningLab(id: "bits", title: "二进制与位运算", summary: "切换 8 个二进制位，观察十进制、十六进制和权限标志。", icon: "number.square.fill", themeHex: "4F7CFF"),
        LearningLab(id: "memory", title: "内存布局", summary: "点击栈、堆、全局数据和代码段，理解对象生命周期。", icon: "memorychip.fill", themeHex: "16A085"),
        LearningLab(id: "tcp", title: "TCP 三次握手", summary: "一步一步发送 SYN、SYN-ACK、ACK，观察连接建立过程。", icon: "arrow.left.arrow.right.circle.fill", themeHex: "2D98DA"),
        LearningLab(id: "hash", title: "哈希碰撞", summary: "向少量桶中加入键，观察碰撞、链地址法和负载因子。", icon: "square.grid.3x3.fill", themeHex: "D35400")
    ]
}
