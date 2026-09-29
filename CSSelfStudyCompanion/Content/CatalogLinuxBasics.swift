import Foundation

enum CatalogLinuxBasics {
    static let topics: [LearningTopicSeed] = [
        LearningTopicSeed(
            id: "linux-l0",
            order: 1,
            title: "L0 环境搭建：UTM、Docker、云服务器与 SSH",
            summary: "选择适合自己的 Linux 运行环境，完成 Ubuntu LTS 安装和首次 SSH 登录。",
            estimatedMinutes: 180,
            tutorials: [
                LearningTutorialSeed(
                    id: "tutorial-linux-l0",
                    order: 1,
                    title: "把 Linux 跑起来并连上去",
                    summary: "从虚拟机、Docker、云服务器三条路线中选一条，理解 Ubuntu LTS 与 SSH。",
                    markdown: #"""
# 为什么先搭建环境

学习 Linux 不能只看命令截图。你必须拥有一台可以随时破坏、随时重装的 Linux。Mac 上没有可直接运行的 Linux 内核，因此常用三种方式：UTM 虚拟机适合完整体验系统；Docker 适合快速练习命令但默认不运行 systemd；云服务器最接近真实生产环境，但需要网络和账号。零基础优先选择 UTM 或 Ubuntu 云服务器，不要在主力 Mac 上直接分区安装。

## 选择 Ubuntu LTS

LTS 表示长期支持版，通常提供五年安全更新，适合学习。下载 Ubuntu Server 作为纯命令行环境，或 Desktop 版体验图形界面。服务器版启动后需要设置用户名、密码和网络。虚拟机的 CPU、内存建议至少 2 核、4 GB。第一次登录后执行 `cat /etc/os-release`、`uname -a`、`ip addr`，确认系统版本、内核与网络地址。

## 云服务器的安全底线

购买最小规格的 Ubuntu 实例即可。安全组至少开放 22 端口用于 SSH，Web 服务需要时再开放 80/443。不要开放数据库端口，不要使用密码登录，不要把私钥发给任何人。默认用户常是 `ubuntu`，首次通过控制台或平台提供的密钥登录。

## SSH 是什么

SSH 是加密的远程登录协议。客户端命令格式是 `ssh 用户@主机`。第一次连接会提示保存服务器指纹，确认来源后再输入 `yes`。如果使用密钥，私钥保存在 Mac 的 `~/.ssh`，权限应为 600；公钥内容追加到服务器的 `~/.ssh/authorized_keys`。可以用 `ssh-keygen -t ed25519 -C "说明"` 生成密钥，用 `ssh-copy-id` 上传公钥。

生成密钥后，在 `~/.ssh/config` 写主机别名，可以简化登录：`Host study`、`HostName 服务器IP`、`User ubuntu`、`IdentityFile ~/.ssh/id_ed25519`。之后只需 `ssh study`。`scp` 和 `rsync` 也使用同一套 SSH 身份。

## 第一次登录后的检查

执行 `sudo apt update && sudo apt upgrade` 更新系统；安装 `build-essential`、`git`、`curl`、`vim`。用 `whoami` 确认用户，用 `hostname` 确认主机，用 `df -h` 看磁盘，用 `free -h` 看内存。不要急着安装桌面环境，先用命令行完成创建目录、编辑文件、安装软件和退出登录。

## Docker 路线的边界

`docker run --rm -it ubuntu:24.04 bash` 能在几秒内进入 Ubuntu 容器。容器与宿主机共享内核，适合练习编译、文件和网络命令；但 PID 1、systemd、内核模块等系统管理内容受限。要学习这些主题时切换到虚拟机或云服务器。工具没有绝对好坏，关键是知道自己正在观察哪一层。
"""#,
                    codeLanguage: "bash",
                    code: #"""
# 在 Mac 上生成 SSH 密钥并查看公钥
ssh-keygen -t ed25519 -C "cs-study"
chmod 600 ~/.ssh/id_ed25519
cat ~/.ssh/id_ed25519.pub
ssh ubuntu@服务器地址

# 登录后确认 Ubuntu 环境
cat /etc/os-release
uname -a
sudo apt update
sudo apt install -y build-essential git curl
"""#,
                    secondCodeLanguage: "bash",
                    secondCode: #"""
# ~/.ssh/config 示例
Host study
    HostName 192.0.2.10
    User ubuntu
    IdentityFile ~/.ssh/id_ed25519
    ServerAliveInterval 30

# 保存后直接登录
ssh study
"""#,
                    commonMistakes: #"""
- 把私钥上传服务器或发给别人；只能分享 `.pub` 公钥。
- 私钥权限过宽，SSH 会拒绝使用；执行 `chmod 600 ~/.ssh/id_ed25519`。
- 云安全组开放全部端口，或允许 root 密码登录。
- 在 Docker 容器中学习 systemd 后误以为容器坏了：容器默认没有完整 init 系统。
"""#
                )
            ],
            exercises: [
                LearningExerciseSeed(
                    id: "exercise-linux-l0-choice",
                    order: 1,
                    title: "选择运行环境",
                    kind: .multipleChoice,
                    question: "你想练习 `systemctl` 管理服务并加载自定义内核模块，最合适的环境是？",
                    options: ["默认 Ubuntu Docker 容器", "UTM 虚拟机或云服务器", "macOS 终端直接运行", "浏览器书签"],
                    answer: "UTM 虚拟机或云服务器",
                    explanation: "容器共享宿主机内核且默认不一定运行 systemd，不适合完整练习服务管理和内核模块。"
                ),
                LearningExerciseSeed(
                    id: "exercise-linux-l0-code",
                    order: 2,
                    title: "检查 Linux 环境",
                    kind: .coding,
                    question: "编写一个 Shell 脚本，检查当前用户、内核版本、发行版、磁盘和内存，并输出分隔标题。",
                    answer: #"""
#!/usr/bin/env bash
set -euo pipefail

printf '用户: %s\n' "$(whoami)"
printf '内核: %s\n' "$(uname -r)"
printf '发行版: %s\n' "$(. /etc/os-release && printf '%s' "$PRETTY_NAME")"
printf '\n磁盘:\n'
df -h /
printf '\n内存:\n'
free -h
"""#,
                    explanation: "`set -euo pipefail` 让脚本遇到错误、未定义变量或管道失败时尽快退出，适合学习脚本的基本安全习惯。",
                    starterCode: "#!/usr/bin/env bash\n# 输出用户、内核、发行版、磁盘和内存\n",
                    codeLanguage: "bash"
                )
            ]
        ),
        LearningTopicSeed(
            id: "linux-l1",
            order: 2,
            title: "L1 基础命令：目录、文件、权限、用户、包管理",
            summary: "形成文件系统地图，掌握日常操作和最小权限原则。",
            estimatedMinutes: 220,
            tutorials: [
                LearningTutorialSeed(
                    id: "tutorial-linux-l1",
                    order: 1,
                    title: "文件系统与权限的日常操作",
                    summary: "熟练操作目录文件，并安全管理用户、权限和 Ubuntu 软件包。",
                    markdown: #"""
# Linux 文件系统是一棵树

Linux 没有 Windows 的 C 盘、D 盘概念，所有内容从根目录 `/` 开始。`/home` 放普通用户主目录，`/etc` 放系统配置，`/var` 放经常变化的数据和日志，`/usr` 放系统程序与库，`/tmp` 放临时文件，`/dev` 表示设备，`/proc` 与 `/sys` 暴露内核信息。挂载可以理解为把一块磁盘接到树的某个目录。

定位文件先使用 `pwd`，查看目录用 `ls -lah`，切换目录用 `cd`。创建目录 `mkdir -p a/b/c`，创建文件 `touch note.txt`，查看内容 `cat`、`less`、`head`、`tail`。复制文件 `cp`，复制目录 `cp -R`，移动和改名 `mv`，删除 `rm`。`rm -rf` 很危险，执行前先 `pwd` 和 `ls`，不要在不确定变量内容时使用通配符。

## 权限、所有者与用户

`ls -l` 输出 `-rw-r--r-- 1 alice dev 120 Sep 1 note.txt`。首个字符是文件类型，随后是所有者、组、其他人的权限。数字权限使用 4/2/1 相加。`chmod 640 note.txt` 表示所有者 rw、组 r、其他人无权限；`chown alice:dev note.txt` 修改所有者和组，通常需要 sudo。目录的执行权限 `x` 表示可以进入目录。

用户信息存在 `/etc/passwd`，密码哈希在受保护的 `/etc/shadow`。用 `id` 查看当前 UID、GID 和组；用 `sudo adduser learner` 交互创建用户；用 `sudo usermod -aG sudo learner` 加入 sudo 组。不要直接手动编辑 passwd 文件。

## Ubuntu 包管理

Ubuntu 使用 APT 管理 `.deb` 软件。安装前执行 `sudo apt update` 更新软件索引，`sudo apt upgrade` 安装更新，`sudo apt install 包名` 安装。搜索可用 `apt search`，查看信息用 `apt show`，卸载用 `sudo apt remove`。不要把互联网上的任意安装脚本直接通过管道交给 root Shell，至少先下载并阅读。

## 实践任务

创建 `/tmp/cs-l1`，在其中建立 `src`、`docs`、`bin` 三个目录。写一个文本文件并调整权限为 640。创建用户 `learner`，查看其 UID。用 apt 安装 `tree`，然后运行 `tree /tmp/cs-l1`。最后删除测试文件和用户前，先记录每一步使用的命令。
"""#,
                    codeLanguage: "bash",
                    code: #"""
# 建立目录结构并检查权限
mkdir -p /tmp/cs-l1/{src,docs,bin}
printf 'hello linux\n' > /tmp/cs-l1/docs/note.txt
chmod 640 /tmp/cs-l1/docs/note.txt
ls -l /tmp/cs-l1/docs/note.txt

# 用户与软件包
sudo adduser learner
id learner
sudo apt update
sudo apt install -y tree
tree /tmp/cs-l1
"""#,
                    secondCodeLanguage: "bash",
                    secondCode: #"""
# 只读检查常用系统信息，不需要 root
whoami
id
ls -lah /etc | head
find /etc -maxdepth 1 -type f -name '*.conf' | head
stat /etc/hostname
"""#,
                    commonMistakes: #"""
- 不确认当前位置就执行 `rm -rf *`，可能删除整个项目。
- 给私钥、配置文件设置 777；权限过宽会泄露敏感信息。
- 修改系统文件前不备份，也不理解配置格式。
- 混淆“删除软件包”和“清理配置”；卸载前查看 apt 提示。
"""#
                )
            ],
            exercises: [
                LearningExerciseSeed(
                    id: "exercise-linux-l1-choice",
                    order: 1,
                    title: "理解权限数字",
                    kind: .multipleChoice,
                    question: "`chmod 640 file` 表示什么？",
                    options: ["所有人可读写", "所有者读写，组只读，其他人无权限", "仅所有者可执行", "所有者和组都可写"],
                    answer: "所有者读写，组只读，其他人无权限",
                    explanation: "6=4+2 表示读写，4 表示只读，0 表示无权限。顺序是所有者、组、其他人。"
                ),
                LearningExerciseSeed(
                    id: "exercise-linux-l1-code",
                    order: 2,
                    title: "批量整理文件",
                    kind: .coding,
                    question: "编写 Shell 命令：在当前目录查找所有 `.log` 文件，把 7 天前的文件移动到 `archive` 目录。",
                    answer: #"""
mkdir -p archive
find . -maxdepth 1 -type f -name '*.log' -mtime +7 -print -exec mv -i {} archive/ \;
"""#,
                    explanation: "`-maxdepth 1` 限制当前目录，`-mtime +7` 表示修改时间超过 7 天，`-print -exec` 可先观察再执行。生产环境应先备份并用 `-exec ... +` 提高效率。",
                    starterCode: "mkdir -p archive\n# 查找并移动 7 天前的日志\n",
                    codeLanguage: "bash"
                )
            ]
        ),
        LearningTopicSeed(
            id: "linux-l2",
            order: 3,
            title: "L2 Shell 与文本处理",
            summary: "用 bash 变量、条件、循环、函数组织自动化，并掌握 grep、sed、awk、find 与管道。",
            estimatedMinutes: 260,
            tutorials: [
                LearningTutorialSeed(
                    id: "tutorial-linux-l2",
                    order: 1,
                    title: "Shell 脚本与文本流水线",
                    summary: "从简单脚本到日志统计，理解管道、重定向和文本工具的组合方式。",
                    markdown: #"""
# Shell 是命令语言

Shell 读取命令、处理变量和通配符、启动程序并管理管道。bash 脚本第一行 `#!/usr/bin/env bash` 指定解释器；执行前用 `chmod +x script.sh` 增加执行权限。变量赋值不能有空格：`name="Alice"`，使用时写 `$name` 或更安全的 `${name}`。命令替换 `$(命令)` 把输出嵌入另一条命令。

## 条件、循环与函数

`if [ "$count" -gt 0 ]; then ... fi` 中，`[` 实际是 test 命令，变量加引号可避免空值和空格问题。现代 bash 可使用 `[[ ... ]]`。数值比较用 `-eq -ne -lt -gt`，字符串比较用 `=`、`!=`。`for file in *.c; do ...; done` 遍历文件，`while read -r line; do ...; done < file` 逐行读取。函数写成 `backup() { ...; }`，用 `"$1"` 接收第一参数。正式脚本推荐 `set -euo pipefail`。

## 管道与重定向

`command > output.txt` 覆盖标准输出，`>>` 追加，`2> error.txt` 重定向错误，`2>&1` 合并错误到输出。管道 `|` 把前一个程序的标准输出交给后一个程序的标准输入。例如 `ps aux | grep ssh` 搜索进程。`tee` 可以同时输出到屏幕和文件：`命令 | tee log.txt`。

## 文本工具四件套

`grep` 按行搜索文本，`-R` 递归，`-I` 忽略二进制，`-n` 显示行号，`-E` 使用扩展正则。`sed` 擅长替换：`sed 's/old/new/g' file` 只输出结果，加 `-i` 才修改文件。`awk` 按字段处理：`awk '{sum += $3} END {print sum}' data.txt` 统计第三列。`find` 按文件属性查找，`-exec` 对结果执行命令。四个工具都不需要一次背完，先从真实日志任务倒推参数。

## 一个日志分析任务

假设 `access.log` 每行包含 IP、时间、路径、状态码。统计每个 IP 的请求数：`awk '{print $1}' access.log | sort | uniq -c | sort -nr`。找出状态码 500：`awk '$4 == 500' access.log` 或 `grep ' 500 '`。查看访问量最高的 10 条路径：`awk '{print $3}' access.log | sort | uniq -c | sort -nr | head`。`xargs` 把输入变成参数，处理文件名时使用 `find ... -print0 | xargs -0` 避免空格导致误拆分。

## 可维护性

脚本要处理失败：检查参数数量、文件存在、命令退出码。错误消息输出到 stderr。变量和函数使用清晰名称，不要把复杂逻辑塞在一行。先写能工作的小版本，再用 `set -x` 跟踪，最后删除调试输出。
"""#,
                    codeLanguage: "bash",
                    code: #"""
#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
    printf '用法: %s 文件\n' "$0" >&2
    exit 1
fi

file=$1
[[ -r "$file" ]] || { printf '无法读取: %s\n' "$file" >&2; exit 2; }

printf '总行数: '
wc -l < "$file"

printf '\n状态码统计:\n'
awk '{count[$4]++} END {for (code in count) print code, count[code]}' "$file" | sort

printf '\n访问最多的 IP:\n'
awk '{print $1}' "$file" | sort | uniq -c | sort -nr | head -n 5
"""#,
                    secondCodeLanguage: "bash",
                    secondCode: #"""
# 安全替换：先预览，再原地修改
grep -n 'localhost' config.txt
sed 's/localhost/127.0.0.1/g' config.txt > config.txt.new
diff -u config.txt config.txt.new
mv config.txt.new config.txt

# 递归查找 C 文件并显示行号
find . -type f -name '*.c' -print0 | xargs -0 grep -n 'main'
"""#,
                    commonMistakes: #"""
- 变量赋值写成 `name = value`，Shell 会把 name 当命令。
- 对未加引号的变量使用 rm；空变量可能让命令变成 `rm -rf /` 等危险形式。
- 直接使用 `sed -i` 修改重要配置且不备份。
- 用 `for` 遍历 find 输出会导致含空格文件名被拆分；使用 `-print0`。
"""#
                )
            ],
            exercises: [
                LearningExerciseSeed(
                    id: "exercise-linux-l2-choice",
                    order: 1,
                    title: "选择管道",
                    kind: .multipleChoice,
                    question: "哪条命令最适合统计文件中每个单词出现次数并倒序展示？",
                    options: ["cat file | sort -u", "tr ' ' '\\n' < file | sort | uniq -c | sort -nr", "grep file", "chmod 644 file"],
                    answer: "tr ' ' '\\n' < file | sort | uniq -c | sort -nr",
                    explanation: "先把空格变行，再排序让相同单词相邻，uniq -c 计数，最后按次数倒序。"
                ),
                LearningExerciseSeed(
                    id: "exercise-linux-l2-code",
                    order: 2,
                    title: "编写日志统计脚本",
                    kind: .coding,
                    question: "编写 bash 脚本：接收日志文件，输出行数和访问次数最多的前 3 个 IP。要求检查参数、文件和读取权限。",
                    answer: #"""
#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
    printf '用法: %s 日志文件\n' "$0" >&2
    exit 1
fi

log=$1
if [[ ! -r "$log" ]]; then
    printf '文件不存在或不可读: %s\n' "$log" >&2
    exit 2
fi

printf '行数: '
wc -l < "$log"
printf 'Top IP:\n'
awk '{print $1}' "$log" | sort | uniq -c | sort -nr | head -n 3
"""#,
                    explanation: "脚本先检查参数和读取权限，再执行统计。`set -euo pipefail` 可以避免错误被悄悄忽略。",
                    starterCode: "#!/usr/bin/env bash\nset -euo pipefail\n# 输出行数和 Top 3 IP\n",
                    codeLanguage: "bash"
                )
            ]
        ),
        LearningTopicSeed(
            id: "linux-l3",
            order: 4,
            title: "L3 系统管理：进程、systemd、日志、磁盘、网络、cron",
            summary: "从“会用命令”进入“能观察并维护一台服务器”。",
            estimatedMinutes: 260,
            tutorials: [
                LearningTutorialSeed(
                    id: "tutorial-linux-l3",
                    order: 1,
                    title: "进程、服务与系统运行状态",
                    summary: "使用 systemctl、journalctl、ps、ss、df 和 cron 完成日常运维。",
                    markdown: #"""
# 进程是运行中的程序

可执行文件在磁盘上只是静态数据；启动后才变成进程，拥有 PID、内存、打开文件和权限。`ps aux` 显示进程快照，`top` 或 `htop` 实时观察资源，`pgrep` 按名字找 PID，`kill -TERM PID` 请求进程退出，`kill -KILL PID` 强制杀死。优先使用 TERM 让程序保存状态和清理资源，不要一开始就 KILL。

前台进程会占用当前终端，`Ctrl+C` 发送中断信号。`&` 把命令放到后台，`jobs` 查看当前 Shell 的任务，`fg %1` 拉回前台。`nohup` 可以忽略挂断信号，但长期服务应交给 systemd。

## systemd 管理服务

`systemctl status nginx` 查看状态，`start`、`stop`、`restart`、`reload` 控制服务，`enable` 设置开机启动。自定义服务放在 `/etc/systemd/system/myapp.service`，核心字段包括 `ExecStart`、`WorkingDirectory`、`User`、`Restart`。修改后执行 `sudo systemctl daemon-reload` 再启动。服务日志用 `journalctl -u myapp -f` 实时查看，`--since "10 minutes ago"` 限制时间。

## 日志、磁盘和网络

系统日志由 journald 收集，内核日志可用 `dmesg -T`。磁盘空间用 `df -h`，目录大小用 `du -sh * | sort -h`。删除日志前先确认文件归属，不要用 `rm -rf /var/log/*`。网络接口用 `ip addr`，路由用 `ip route`，监听端口用 `ss -tulpn`，连通性用 `ping`，HTTP 调试用 `curl -i`。`ss` 比旧版 `netstat` 更现代。

## cron 定时任务

`crontab -e` 编辑当前用户任务。五个时间字段依次是分钟、小时、日期、月份、星期。`0 3 * * * /home/dev/backup.sh` 表示每天 03:00 执行。脚本要使用绝对路径，因为 cron 的 PATH 很小；输出可以重定向到日志文件。先让脚本手动运行成功，再放进 cron，并用 `journalctl -u cron` 排错。

## 稳定排错顺序

先确认影响范围：是一台机器还是整个服务，是所有用户还是单个用户。再看资源与进程，接着查 systemd 状态和近十分钟日志，最后检查端口、路由与配置是否发生变化。每次只修改一个变量并记录结果，避免同时重启服务、换配置和删缓存，否则无法判断哪一步真正解决了问题。
"""#,
                    codeLanguage: "bash",
                    code: #"""
# 查找并观察进程
pgrep -a ssh
ps -o pid,ppid,stat,cmd -p "$$"

# 服务状态与日志
sudo systemctl status ssh
journalctl -u ssh --since '30 minutes ago' --no-pager

# 资源与网络
df -h
free -h
ip addr show
ip route
ss -tulpn
"""#,
                    secondCodeLanguage: "bash",
                    secondCode: #"""
# /etc/systemd/system/demo.service
[Unit]
Description=CS study demo service
After=network.target

[Service]
Type=simple
User=learner
WorkingDirectory=/home/learner/demo
ExecStart=/home/learner/demo/server
Restart=on-failure
RestartSec=3

[Install]
WantedBy=multi-user.target
"""#,
                    commonMistakes: #"""
- 修改 systemd 单元后忘记 `daemon-reload`。
- 盲目执行 `kill -9`，导致程序来不及保存状态。
- 只看 `df` 不看 inode：`df -i` 可判断 inode 是否耗尽。
- cron 中依赖交互式 Shell 的环境变量，脚本无法找到命令。
- 删除日志却不检查是否有点阵文件被进程继续占用。
"""#
                )
            ],
            exercises: [
                LearningExerciseSeed(
                    id: "exercise-linux-l3-choice",
                    order: 1,
                    title: "选择日志命令",
                    kind: .multipleChoice,
                    question: "要实时查看名为 `demo` 的 systemd 服务日志，哪个命令正确？",
                    options: ["journalctl -u demo -f", "cat /var/log", "ps demo", "df -h demo"],
                    answer: "journalctl -u demo -f",
                    explanation: "`-u` 按系统单元过滤，`-f` 实时跟随新日志。"
                ),
                LearningExerciseSeed(
                    id: "exercise-linux-l3-code",
                    order: 2,
                    title: "编写健康检查脚本",
                    kind: .coding,
                    question: "写脚本检查根分区使用率是否超过 85%，超过时输出警告并把结果写入 `/tmp/disk-warning.log`。",
                    answer: #"""
#!/usr/bin/env bash
set -euo pipefail

usage=$(df -P / | awk 'NR == 2 {gsub(/%/, "", $5); print $5}')
if (( usage > 85 )); then
    message="警告: 根分区使用率 ${usage}%"
    printf '%s\n' "$message" | tee -a /tmp/disk-warning.log >&2
    exit 1
fi

printf '根分区使用率 %s%%，状态正常\n' "$usage"
"""#,
                    explanation: "`df -P` 输出稳定格式，awk 提取第二行第五列并去掉百分号。`tee -a` 同时写日志和显示警告。",
                    starterCode: "#!/usr/bin/env bash\nset -euo pipefail\n# 检查根分区使用率\n",
                    codeLanguage: "bash"
                )
            ]
        ),
        LearningTopicSeed(
            id: "linux-l4",
            order: 5,
            title: "L4 系统编程：POSIX、文件 I/O、进程、线程、信号、IPC、socket、epoll",
            summary: "从 C 程序视角调用内核接口，理解现代服务端程序的基础设施。",
            estimatedMinutes: 420,
            tutorials: [
                LearningTutorialSeed(
                    id: "tutorial-linux-l4",
                    order: 1,
                    title: "POSIX 系统编程全景",
                    summary: "用 C 调用文件、进程、线程、信号、IPC 和 socket；建立错误处理与资源生命周期意识。",
                    markdown: #"""
# 系统编程是调用内核

POSIX 定义了一组类 Unix 系统接口。C 标准库中的 `fopen` 有用户态缓冲；Linux 系统调用 `open`、`read`、`write`、`close` 更接近内核。系统调用成功通常返回非负值，失败返回 -1 并设置 `errno`。错误处理必须紧跟调用，`perror` 能输出可读原因。

## 文件 I/O

`open(path, O_RDONLY)` 得到文件描述符 fd，`read` 把字节读入缓冲区，`write` 写出，最后 `close`。`read` 的返回值可能小于请求长度，这不是错误，必须循环直到真正 EOF 或写满。`O_CREAT | O_TRUNC` 创建并清空文件，权限由 `mode` 指定。`fsync` 强制落盘。不要假设一次 `read` 能读完整个文件。

## 进程与 exec

`fork()` 创建子进程，父进程得到子 PID，子进程得到 0。子进程常调用 `execve` 载入新程序；exec 成功不返回，失败返回 -1。父进程用 `waitpid` 回收子进程，否则会留下僵尸进程。`getpid`、`getppid` 观察身份。Shell 的管道和重定向正是 fork、dup2、exec 的组合。

## 线程、同步与信号

POSIX 线程用 `pthread_create` 创建，`pthread_join` 等待。多个线程共享地址空间，因此同一块数据可能被并发修改。互斥锁 `pthread_mutex_lock`/`unlock` 保护临界区；条件变量用于等待状态变化。不要忘记初始化属性、检查返回码、释放线程资源。

信号是异步通知，`SIGINT` 常由 Ctrl+C 触发，`SIGTERM` 请求退出，`SIGKILL` 无法捕获。处理函数应尽量短，只设置 `volatile sig_atomic_t` 标志，由主循环决定如何退出。信号处理函数中调用 printf、malloc 等非异步安全函数是常见错误。

## IPC 与 socket

管道适合父子进程单向通信，命名管道 FIFO 可用于无亲缘进程。消息队列、共享内存、信号量各有用途。网络编程中，服务器调用 `socket`、`bind`、`listen`、`accept`，客户端调用 `connect`。TCP 是字节流，不保留消息边界；应用层需要长度字段或分隔符。`socket` 返回的也是 fd，因此网络 I/O 与文件 I/O 有统一抽象。

## select、poll、epoll

一个线程管理多个连接时，不能让 `read` 阻塞在单个 fd。`select` 有 fd 数量限制，`poll` 使用数组，`epoll` 是 Linux 特有的高效接口：`epoll_create1` 建实例，`epoll_ctl` 增删关注，`epoll_wait` 等待事件。事件触发模式有 level-triggered 和 edge-triggered；后者必须一次读完直到 `EAGAIN`，否则可能永远不再收到通知。

## 调试工具

编译时加 `-g`，用 `gdb ./program` 设置断点、单步、查看变量和调用栈。`strace -f -e trace=file ./program` 观察文件和进程系统调用，`valgrind ./program` 检查内存错误和泄漏（需安装）。先让编译器发现静态错误，再用日志缩小范围，最后用调试器观察运行时。
"""#,
                    codeLanguage: "c",
                    code: #"""
// 文件复制：正确处理部分读写和错误
#include <errno.h>
#include <fcntl.h>
#include <stdio.h>
#include <unistd.h>

int main(int argc, char *argv[]) {
    if (argc != 3) {
        fprintf(stderr, "用法: %s 源文件 目标文件\n", argv[0]);
        return 1;
    }

    int input = open(argv[1], O_RDONLY);
    if (input < 0) {
        perror("open input");
        return 1;
    }

    int output = open(argv[2], O_WRONLY | O_CREAT | O_TRUNC, 0644);
    if (output < 0) {
        perror("open output");
        close(input);
        return 1;
    }

    char buffer[4096];
    ssize_t count;
    while ((count = read(input, buffer, sizeof(buffer))) > 0) {
        ssize_t offset = 0;
        while (offset < count) {
            ssize_t written = write(output, buffer + offset, (size_t)(count - offset));
            if (written < 0) {
                if (errno == EINTR) continue;
                perror("write");
                close(input);
                close(output);
                return 1;
            }
            offset += written;
        }
    }

    if (count < 0) {
        perror("read");
        close(input);
        close(output);
        return 1;
    }

    close(input);
    close(output);
    return 0;
}
"""#,
                    secondCodeLanguage: "c",
                    secondCode: #"""
// fork + exec + waitpid 最小示例
#include <stdio.h>
#include <sys/wait.h>
#include <unistd.h>

int main(void) {
    pid_t pid = fork();
    if (pid < 0) {
        perror("fork");
        return 1;
    }

    if (pid == 0) {
        execlp("printf", "printf", "子进程执行成功\n", (char *)NULL);
        perror("execlp");
        _exit(127); // exec 失败时使用 _exit，避免刷新父进程缓冲
    }

    int status = 0;
    if (waitpid(pid, &status, 0) < 0) {
        perror("waitpid");
        return 1;
    }
    printf("子进程退出状态: %d\n", WEXITSTATUS(status));
    return 0;
}
"""#,
                    commonMistakes: #"""
- 忘记检查 `read`/`write` 部分完成和 `EINTR`。
- fork 后子进程直接 `exit`，可能重复刷新父进程缓冲区；使用 `_exit`。
- 忘记 waitpid，产生僵尸进程。
- 在信号处理函数中调用非异步安全函数。
- 把 TCP 当消息协议，假设一次 recv 正好对应一次 send。
"""#
                )
            ],
            exercises: [
                LearningExerciseSeed(
                    id: "exercise-linux-l4-choice",
                    order: 1,
                    title: "判断并发 I/O",
                    kind: .multipleChoice,
                    question: "Linux 上要同时管理大量网络连接，哪种接口通常扩展性最好？",
                    options: ["select", "epoll", "阻塞式 read 单连接", "sleep"],
                    answer: "epoll",
                    explanation: "epoll 把关注集合放在内核中，不随 fd 数量线性复制，适合大量连接；select 有 fd 上限且每次要重建集合。"
                ),
                LearningExerciseSeed(
                    id: "exercise-linux-l4-code",
                    order: 2,
                    title: "实现带信号处理的睡眠程序",
                            kind: .coding,
                    question: "编写 C 程序：捕获 SIGINT，第一次收到时输出“准备退出”，主循环检测标志后正常退出。",
                    answer: #"""
#include <signal.h>
#include <stdio.h>
#include <unistd.h>

static volatile sig_atomic_t should_exit = 0;

static void handle_sigint(int signo) {
    (void)signo;
    should_exit = 1;
}

int main(void) {
    struct sigaction action = {0};
    action.sa_handler = handle_sigint;
    sigemptyset(&action.sa_mask);
    action.sa_flags = 0;

    if (sigaction(SIGINT, &action, NULL) == -1) {
        perror("sigaction");
        return 1;
    }

    puts("按 Ctrl+C 退出");
    while (!should_exit) {
        pause();
    }

    puts("准备退出");
    return 0;
}
"""#,
                    explanation: "信号处理函数只修改 `sig_atomic_t` 标志，主循环负责打印和退出，避免在异步信号中调用不安全函数。",
                    starterCode: "#include <signal.h>\n#include <stdio.h>\n#include <unistd.h>\n\nint main(void) {\n    // 捕获 SIGINT 并正常退出\n    return 0;\n}\n",
                    codeLanguage: "c"
                )
            ]
        )
    ]
}
