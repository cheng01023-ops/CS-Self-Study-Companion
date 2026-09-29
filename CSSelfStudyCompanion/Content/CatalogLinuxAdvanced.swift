import Foundation

enum CatalogLinuxAdvanced {
    static let topics: [LearningTopicSeed] = [
        LearningTopicSeed(
            id: "linux-l5",
            order: 6,
            title: "L5 网络与服务：TCP/IP、HTTP、Nginx、防火墙、tcpdump",
            summary: "从数据包到 Web 服务，理解一次浏览器请求经过的每层。",
            estimatedMinutes: 300,
            tutorials: [
                LearningTutorialSeed(
                    id: "tutorial-linux-l5",
                    order: 1,
                    title: "从 TCP/IP 到 Nginx 反向代理",
                    summary: "理解 TCP/IP、HTTP、DNS，部署 Nginx，并用防火墙与抓包工具排错。",
                    markdown: #"""
# 分层理解网络

浏览器访问网站时，应用层使用 HTTP/HTTPS，DNS 把域名解析成 IP，传输层使用 TCP 或 UDP，网络层用 IP 负责路由，链路层负责局域网传输。分层不是装饰：每一层只关心自己的地址和协议，上层可以复用下层能力。HTTP/1.1、HTTP/2、HTTP/3 的传输方式不同，但请求方法、状态码和头部语义大体延续。

## TCP、UDP 与 HTTP

TCP 面向连接、可靠、有序，建立连接需要三次握手，断开通常四次挥手。UDP 无连接、开销小，但不保证到达和顺序，适合实时音视频、DNS 查询等场景。HTTP 是请求-响应协议：客户端发方法、路径、头部、可选正文；服务器返回状态码、头部和正文。常见状态码：200 成功，301/302 重定向，400 请求错误，401 未认证，403 禁止，404 不存在，500 服务器错误。

HTTPS 在 HTTP 和 TCP 之间加入 TLS，保护机密性和完整性，并通过证书验证服务器身份。证书过期、域名不匹配、系统时间错误都会导致 TLS 握手失败。

## DNS 与排错顺序

DNS 把域名转为 IP。`dig example.com` 查看解析，`cat /etc/resolv.conf` 查看 DNS 配置。排错从下到上：`ip addr` 检查地址，`ip route` 检查路由，`ping 网关` 检查局域网，`ping 1.1.1.1` 检查互联网，`dig` 检查域名，`curl -v` 检查 TCP/TLS/HTTP。不要一上来就重启网络。

## Nginx 入门

Nginx 是高性能 Web 服务器和反向代理。配置文件常位于 `/etc/nginx/nginx.conf`，站点配置在 `/etc/nginx/sites-available`，通过 `sites-enabled` 中的符号链接启用。`server` 块定义监听端口和域名，`location` 定义路径如何转发。静态文件使用 `root` 或 `alias`，动态服务常通过 `proxy_pass http://127.0.0.1:3000` 转发到应用。修改后先 `sudo nginx -t`，再 `systemctl reload nginx`。

## 防火墙与抓包

Ubuntu 常用 UFW 管理 iptables/nftables 规则。先 `sudo ufw allow OpenSSH`，再 `sudo ufw enable`，否则可能断开 SSH。`tcpdump -i 任意接口 -nn port 80` 查看数据包，可以加 `-A` 查看 HTTP 文本，加 `-w capture.pcap` 保存后用 Wireshark 分析。抓包需要权限，生产环境要避免记录敏感数据。
"""#,
                    codeLanguage: "bash",
                    code: #"""
# 网络分层排错
ip addr show
ip route
ping -c 3 1.1.1.1
dig example.com
curl -v http://example.com
curl -I https://example.com

# 端口和抓包
sudo ss -tulpn
sudo tcpdump -i any -nn port 80
"""#,
                    secondCodeLanguage: "bash",
                    secondCode: #"""
# /etc/nginx/sites-available/demo
server {
    listen 80;
    server_name study.example.com;

    location / {
        proxy_pass http://127.0.0.1:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}

# 启用配置
sudo ln -s /etc/nginx/sites-available/demo /etc/nginx/sites-enabled/demo
sudo nginx -t
sudo systemctl reload nginx
"""#,
                    commonMistakes: #"""
- 只改 Nginx 配置不执行 `nginx -t`，重载失败影响服务。
- 启用 UFW 前不允许 SSH，导致无法登录远程主机。
- 用 ping 判断所有网络问题；很多服务器禁 ICMP，但 TCP 可正常。
- 把 `proxy_pass` 后端只监听 127.0.0.1 与防火墙规则混为一谈。
"""#
                )
            ],
            exercises: [
                LearningExerciseSeed(
                    id: "exercise-linux-l5-choice",
                    order: 1,
                    title: "判断 HTTP 状态码",
                    kind: .multipleChoice,
                    question: "客户端请求成功但服务器内部程序抛出异常，最常见返回哪个状态码？",
                    options: ["200", "301", "404", "500"],
                    answer: "500",
                    explanation: "5xx 表示服务器端错误；500 Internal Server Error 是服务器处理请求时发生未预期错误的通用状态。"
                ),
                LearningExerciseSeed(
                    id: "exercise-linux-l5-code",
                    order: 2,
                    title: "用 curl 检查服务",
                    kind: .coding,
                    question: "写 bash 脚本：检查 `http://127.0.0.1:8080/health`，要求 HTTP 状态码为 200，否则输出状态码并以 1 退出。",
                    answer: #"""
#!/usr/bin/env bash
set -euo pipefail

url='http://127.0.0.1:8080/health'
code=$(curl --silent --output /dev/null --write-out '%{http_code}' "$url")
if [[ "$code" != '200' ]]; then
    printf '健康检查失败: HTTP %s\n' "$code" >&2
    exit 1
fi
printf '服务健康\n'
"""#,
                    explanation: "`--output /dev/null` 丢弃正文，`--write-out` 只输出状态码。脚本在非 200 时以失败退出，便于监控系统识别。",
                    starterCode: "#!/usr/bin/env bash\nset -euo pipefail\n# 检查健康接口\n",
                    codeLanguage: "bash"
                )
            ]
        ),
        LearningTopicSeed(
            id: "linux-l6",
            order: 7,
            title: "L6 内核与性能：/proc、/sys、内核模块、perf、strace",
            summary: "深入观察内核暴露的接口，定位 CPU、内存、系统调用和 I/O 问题。",
            estimatedMinutes: 280,
            tutorials: [
                LearningTutorialSeed(
                    id: "tutorial-linux-l6",
                    order: 1,
                    title: "观察内核与性能瓶颈",
                    summary: "用 /proc、/sys、perf、strace 和 dmesg 建立从现象到证据的排错流程。",
                    markdown: #"""
# /proc 和 /sys

Linux 把很多内核状态暴露成虚拟文件。`/proc/cpuinfo` 显示 CPU，`/proc/meminfo` 显示内存，`/proc/<PID>/status` 显示进程状态，`/proc/<PID>/fd` 列出打开的文件描述符，`/proc/interrupts` 显示中断。`/sys` 组织设备、驱动和内核对象，例如 `/sys/class/net/` 下有网卡信息。它们不是磁盘上的普通文件，读取时由内核动态生成，写入某些文件会改变内核配置，操作前必须查文档。

## 内核模块

内核模块是可在运行时加载的代码，用于驱动、文件系统或网络功能。`lsmod` 查看模块，`modinfo` 查看信息，`sudo modprobe 模块` 加载，`sudo rmmod 模块` 卸载。初学不要随便卸载正在使用的模块。`dmesg -T` 常能看到驱动初始化错误和硬件事件。

## perf 与 strace

`perf stat ./program` 统计 CPU 周期、指令数、缓存未命中等硬件事件；`perf record` 采样后用 `perf report` 查看热点函数。符号信息需要编译时带 `-g`。`strace -f -tt -e trace=file,network ./program` 记录系统调用和耗时，适合定位“卡在哪个调用”。不要在生产环境长时间无过滤地 strace 所有进程，开销和磁盘占用都可能很大。

## 性能排错顺序

先量化：问题发生在 CPU、内存、磁盘、网络还是锁竞争？用 `top`/`pidstat` 看 CPU，`free` 和 `vmstat` 看内存与换页，`iostat` 看磁盘，`ss` 看连接。再用 `perf` 看函数热点，用 `strace` 看系统调用，用 `lsof` 看文件描述符。每次只改一个变量，记录改动前后数据。

## 安全与内核日志

`dmesg` 可能包含地址、设备名等信息，分享日志前先脱敏。内核参数可通过 `/proc/sys` 或 `sysctl` 查看和修改；临时修改重启失效，持久化配置放 `/etc/sysctl.d/`。不要从网上复制未知 sysctl 参数，尤其不要随意关闭地址随机化或打开危险调试接口。

## 先建立性能基线

没有基线的“变快了”通常只是感觉。运行新版本前记录系统版本、编译参数、数据规模、CPU 使用率、内存峰值和延迟分位数；改动后再用相同负载比较。平均延迟会掩盖少量极慢请求，至少同时观察 P50、P95 和最大值。只有数据支持，才值得保留优化。
"""#,
                    codeLanguage: "bash",
                    code: #"""
# 查看内核与进程状态
uname -a
cat /proc/meminfo | head
cat /proc/cpuinfo | grep -m1 'model name'
ls -l /proc/$$/fd
sudo dmesg -T | tail -n 30

# 性能观察
perf stat -e cycles,instructions,cache-misses ./demo
strace -f -tt -e trace=file,network ./demo
"""#,
                    secondCodeLanguage: "c",
                    secondCode: #"""
// 制造一段时间消耗，供 perf/strace 观察
#include <stdio.h>
#include <time.h>

static volatile unsigned long sink;

int main(void) {
    for (unsigned long i = 0; i < 50000000UL; ++i) {
        sink += i;
    }
    printf("result: %lu\n", sink);
    return 0;
}
"""#,
                    commonMistakes: #"""
- 直接写入 `/proc` 或 `/sys` 而不了解参数含义，可能导致系统不稳定。
- 把 strace 输出当成全部 CPU 性能数据；系统调用只是其中一层。
- 没有符号信息就期待 perf 显示函数名，编译时需加 `-g`。
- 删除内核模块前不检查是否正在使用。
"""#
                )
            ],
            exercises: [
                LearningExerciseSeed(
                    id: "exercise-linux-l6-choice",
                    order: 1,
                    title: "选择系统调用跟踪",
                    kind: .multipleChoice,
                    question: "程序启动后打开文件失败，想查看它尝试了哪些路径，优先使用哪个工具？",
                    options: ["strace -e trace=file", "top", "dig", "crontab -e"],
                    answer: "strace -e trace=file",
                    explanation: "strace 能记录 open/openat/stat 等文件系统调用及其返回值，适合确认程序实际访问的路径。"
                ),
                LearningExerciseSeed(
                    id: "exercise-linux-l6-code",
                    order: 2,
                    title: "采集基础性能快照",
                    kind: .coding,
                    question: "写 bash 脚本，将时间、负载、内存、磁盘和监听端口保存到 `/tmp/health-时间戳.txt`。",
                    answer: #"""
#!/usr/bin/env bash
set -euo pipefail

output="/tmp/health-$(date +%Y%m%d-%H%M%S).txt"
{
    date
    uptime
    free -h
    df -h
    ss -tulpn
} > "$output"

printf '已保存: %s\n' "$output"
"""#,
                    explanation: "用花括号把多条命令的输出合并到一个文件。时间戳避免每次覆盖；正式监控应使用 Prometheus 等系统而不是无限生成文件。",
                    starterCode: "#!/usr/bin/env bash\nset -euo pipefail\n# 保存健康快照\n",
                    codeLanguage: "bash"
                )
            ]
        ),
        LearningTopicSeed(
            id: "linux-l7",
            order: 8,
            title: "L7 容器与云：Docker、namespace、cgroup、Kubernetes 入门",
            summary: "理解容器不是轻量虚拟机，而是内核隔离能力和镜像分发的组合。",
            estimatedMinutes: 280,
            tutorials: [
                LearningTutorialSeed(
                    id: "tutorial-linux-l7",
                    order: 1,
                    title: "Docker 背后的 namespace 与 cgroup",
                    summary: "会用 Docker，也能解释容器如何隔离视图和限制资源，并了解 Kubernetes 的角色。",
                    markdown: #"""
# 镜像与容器

镜像包含文件系统层和启动配置，容器是镜像的一次运行实例。Dockerfile 描述构建过程：`FROM` 选基础镜像，`WORKDIR` 设目录，`COPY` 复制文件，`RUN` 构建时执行，`CMD` 或 `ENTRYPOINT` 指定启动命令。镜像层可复用，容器写入层是临时的；删除容器后数据会丢失，需要持久化时使用 volume。

## namespace 做了什么

Linux namespace 隔离不同资源视图：PID namespace 让容器只看到自己的进程，mount namespace 隔离挂载点，network namespace 隔离网卡和端口，UTS 隔离主机名，user namespace 映射用户 ID。容器进程仍然使用宿主机内核，所以内核漏洞和资源竞争需要认真对待。`unshare --pid --fork --mount-proc bash` 可以亲手进入新的 PID namespace。

## cgroup 限制什么

控制组 cgroup 负责 CPU、内存、I/O 和进程数量限制。它不隔离“看到什么”，而限制“能用多少”。Docker 的 `--memory`、`--cpus` 最终会翻译成 cgroup 配置。容器里的 `free` 可能显示宿主机内存，这是常见困惑；要结合 cgroup 限制和 runtime 行为判断。

## Docker 常用流程

`docker build -t demo:1 .` 构建镜像，`docker run --rm -p 8080:80 demo:1` 运行并映射端口，`docker ps` 查看容器，`docker logs` 看日志，`docker exec -it 容器 bash` 进入容器排错。不要把密码写进 Dockerfile；使用环境变量、secret 或运行时配置。生产容器尽量最小化、非 root 运行、只读文件系统，并固定依赖版本。

## Kubernetes 入门

Kubernetes 管理多台机器上的容器，核心对象包括 Pod、Deployment、Service、ConfigMap 和 Ingress。Deployment 维持期望副本数，Service 提供稳定访问入口，Pod 是最小调度单元。初学只记住三件事：声明期望状态，控制器持续收敛；容器进程必须正确处理信号；日志输出到 stdout/stderr，便于集中收集。不要在单机学习阶段过早堆叠 CNI、Ingress、Operator 等概念。

## 镜像不是永久存储

容器可写层随容器生命周期存在，删除容器时也会消失。需要保存数据库、上传文件或证书时，应挂载 volume 或绑定宿主目录，并提前验证权限与备份。镜像只保存只读应用层和启动配置，不承担运行数据的持久化职责。
"""#,
                    codeLanguage: "docker",
                    code: #"""
# 用一个最小镜像练习 Docker
FROM ubuntu:24.04
RUN apt-get update && apt-get install -y --no-install-recommends gcc libc6-dev
WORKDIR /app
COPY hello.c .
RUN gcc -Wall -o hello hello.c
CMD ["./hello"]

# 构建、运行和查看日志
docker build -t cs-hello:1 .
docker run --rm cs-hello:1
docker image ls
"""#,
                    secondCodeLanguage: "bash",
                    secondCode: #"""
# 观察隔离边界
hostname
unshare --pid --fork --mount-proc sh -c 'echo 容器内 PID: $$; ps -ef'

# 运行带资源限制的容器
docker run --rm -it --memory=128m --cpus=0.5 ubuntu:24.04 bash
# 容器内查看环境和 cgroup
cat /proc/1/cgroup
"""#,
                    commonMistakes: #"""
- 把容器当虚拟机，期待它拥有独立内核。
- 容器停止后才发现数据只写在可写层；应使用 volume。
- Dockerfile 中复制密钥和密码，导致镜像层永久泄露。
- 以 root 运行所有容器且不限制资源。
- 学习 Kubernetes 时跳过 Docker、网络和存储基础。
"""#
                )
            ],
            exercises: [
                LearningExerciseSeed(
                    id: "exercise-linux-l7-choice",
                    order: 1,
                    title: "区分 namespace 与 cgroup",
                    kind: .multipleChoice,
                    question: "限制容器最多使用 512 MB 内存，主要依赖哪项 Linux 能力？",
                    options: ["PID namespace", "cgroup", "DNS", "SSH"],
                    answer: "cgroup",
                    explanation: "namespace 负责改变进程看到的资源视图，cgroup 负责限制和统计资源使用。"
                ),
                LearningExerciseSeed(
                    id: "exercise-linux-l7-code",
                    order: 2,
                    title: "编写多阶段 Dockerfile",
                    kind: .coding,
                    question: "为 C 程序写一个 Dockerfile：构建阶段编译，运行阶段只保留可执行文件，容器启动时运行程序。",
                    answer: #"""
FROM gcc:14 AS builder
WORKDIR /src
COPY hello.c .
RUN gcc -Wall -Wextra -O2 -o hello hello.c

FROM debian:bookworm-slim
WORKDIR /app
COPY --from=builder /src/hello /app/hello
USER nobody
ENTRYPOINT ["/app/hello"]
"""#,
                    explanation: "多阶段构建让最终镜像不包含编译器，减小体积和攻击面。固定基础镜像标签便于复现，生产还应固定 digest。",
                    starterCode: "# 构建阶段\n# 运行阶段\n",
                    codeLanguage: "docker"
                )
            ]
        ),
        LearningTopicSeed(
            id: "linux-l8",
            order: 9,
            title: "L8 安全：SSH 密钥、防火墙、SELinux/AppArmor",
            summary: "用最小权限、分层防御和可审计配置保护 Linux 主机。",
            estimatedMinutes: 220,
            tutorials: [
                LearningTutorialSeed(
                    id: "tutorial-linux-l8",
                    order: 1,
                    title: "服务器安全的第一道边界",
                    summary: "配置 SSH 密钥、防火墙和强制访问控制，理解安全不是关闭服务，而是限制能力。",
                    markdown: #"""
# 安全目标

系统安全通常追求机密性、完整性和可用性。对个人服务器而言，最重要的事情是减少暴露面、使用强身份认证、及时更新、保留日志，并假设单层防护会失败。不要使用“关闭防火墙”“允许所有来源”来换方便。

## SSH 密钥与服务器加固

生成 ed25519 密钥后，私钥留在客户端，权限 600；公钥写入服务器 `~/.ssh/authorized_keys`，权限 600，`.ssh` 目录权限 700。确认密钥登录成功后再修改 `/etc/ssh/sshd_config`：禁止 root 直接登录、按需关闭密码认证、限制用户或来源。修改后先用 `sshd -t` 检查配置，并保留一个已登录会话，防止把自己锁在服务器外。

SSH 代理转发 `AgentForwarding` 有风险，非必要关闭。不要复制他人私钥，也不要把私钥放进 Git。更好的服务器访问方式是跳板机、短期证书或云 IAM，但初学阶段先把密钥权限和最小暴露掌握好。

## 防火墙

UFW 只是 iptables/nftables 的前端。默认拒绝入站、允许出站，只开放 SSH、HTTP、HTTPS 等服务端口。规则应按来源和目的尽量精确，例如只允许管理网段访问 22。修改远程主机防火墙时，先确认当前 SSH 会话不会断开，并准备控制台救援方案。查看规则用 `sudo ufw status verbose`。

## SELinux 与 AppArmor

传统 Unix 权限看用户、组和其他人；强制访问控制 MAC 还会根据策略限制进程能读哪些文件、监听哪些端口。SELinux 常用模式是 enforcing、permissive、disabled；Ubuntu 通常默认使用 AppArmor。查看 AppArmor 状态用 `sudo aa-status`，查看某个进程限制用 `cat /proc/<PID>/attr/current`。不要为了排错直接永久禁用安全模块，先读日志、调整策略或为应用配置正确路径。

## 日志与更新

`journalctl -p warning` 查看警告，`sudo lastb` 查看失败登录，`sudo ufw status` 查看规则。自动安全更新适合个人服务器，但要了解重启要求。软件漏洞往往来自未更新依赖；容器镜像和宿主机内核都需要维护。

最后，安全检查要有清单：谁能登录、开放了哪些端口、哪些进程以 root 运行、密钥如何轮换、日志保留多久、备份是否能恢复。能回答这些问题，比安装一个“安全脚本”更可靠。

## 最小权限不是少用命令

最小权限意味着每个进程、用户和服务只获得完成工作所需的能力。应用不要以 root 运行，能只读就不写，能访问单个目录就不要访问整个文件系统，能限制来源就不要允许全网。权限变化后要重新测试部署和更新流程，否则安全加固可能让正常服务中断。
"""#,
                    codeLanguage: "bash",
                    code: #"""
# 密钥登录与配置检查
chmod 700 ~/.ssh
chmod 600 ~/.ssh/authorized_keys
sudo sshd -t
sudo systemctl reload ssh

# UFW 最小开放
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow OpenSSH
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw enable
sudo ufw status verbose
"""#,
                    secondCodeLanguage: "bash",
                    secondCode: #"""
# 安全状态检查
sudo aa-status | head
cat /proc/$$/attr/current
journalctl -p warning --since '24 hours ago' --no-pager | tail -n 50
sudo lastb | head
"""#,
                    commonMistakes: #"""
- 先关闭密码或修改 SSH 端口再测试密钥，导致自己无法登录。
- 私钥权限为 644 或被同步到公开仓库。
- 直接禁用 SELinux/AppArmor，而不是分析拒绝日志。
- 防火墙开放 0.0.0.0/0 的全部端口。
- 有备份文件但不定期验证恢复流程。
"""#
                )
            ],
            exercises: [
                LearningExerciseSeed(
                    id: "exercise-linux-l8-choice",
                    order: 1,
                    title: "安全的 SSH 顺序",
                    kind: .multipleChoice,
                    question: "远程服务器上配置密钥登录时，最安全的修改顺序是？",
                    options: ["先关闭密码登录再测试密钥", "先配置并验证密钥，再逐步关闭密码登录", "把私钥上传服务器", "永久关闭 sshd"],
                    answer: "先配置并验证密钥，再逐步关闭密码登录",
                    explanation: "保留可用登录路径并逐步收紧配置，可以在出错时恢复；先关闭密码会让自己失去入口。"
                ),
                LearningExerciseSeed(
                    id: "exercise-linux-l8-code",
                    order: 2,
                    title: "编写权限检查脚本",
                    kind: .coding,
                    question: "写脚本检查 `~/.ssh` 和 `authorized_keys` 权限，不符合 700/600 时输出修复命令。",
                    answer: #"""
#!/usr/bin/env bash
set -euo pipefail

ssh_dir="$HOME/.ssh"
keys="$ssh_dir/authorized_keys"

if [[ -e "$ssh_dir" ]]; then
    mode=$(stat -c '%a' "$ssh_dir")
    if [[ "$mode" != '700' ]]; then
        printf '修复: chmod 700 %q\n' "$ssh_dir"
    fi
fi

if [[ -e "$keys" ]]; then
    mode=$(stat -c '%a' "$keys")
    if [[ "$mode" != '600' ]]; then
        printf '修复: chmod 600 %q\n' "$keys"
    fi
fi
"""#,
                    explanation: "`stat -c '%a'` 在 Linux 上输出八进制权限。脚本只报告，不自动修改，避免误操作；确认路径后再执行修复命令。",
                    starterCode: "#!/usr/bin/env bash\nset -euo pipefail\n# 检查 ~/.ssh 权限\n",
                    codeLanguage: "bash"
                )
            ]
        )
    ]
}
