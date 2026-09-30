import Foundation

enum CatalogSystems {
    static let stages: [LearningStageSeed] = [
        LearningStageSeed(
            id: "stage-4",
            order: 6,
            title: "数据结构与算法",
            subtitle: "用复杂度和不变量选择结构，再用 C 亲手实现。",
            icon: "point.3.connected.trianglepath.dotted",
            themeHex: "E67E22",
            topics: [
                LearningTopicSeed(
                    id: "topic-dsa",
                    order: 1,
                    title: "从复杂度到图算法",
                    summary: "掌握链表、栈、队列、哈希、树、图、排序和查找。",
                    estimatedMinutes: 520,
                    tutorials: [
                        LearningTutorialSeed(
                            id: "tutorial-dsa",
                            order: 1,
                            title: "数据结构不是背图，而是维护不变量",
                            summary: "用大 O、操作成本和内存布局把常见数据结构连成一张选择表。",
                            markdown: #"""
# 为什么需要数据结构和算法

程序要处理的数据会增长。算法描述解决步骤，数据结构描述数据如何组织。好的选择让操作更快、代码更简单；坏的选择可能在数据量小时正常，数据量一大就卡死。分析性能先看增长趋势，而不是某台电脑上的具体秒数。大 O 描述输入规模趋于无穷时的上界，例如线性查找 O(n)，二分查找 O(log n)，冒泡排序 O(n²)，归并排序 O(n log n)。

复杂度不只看时间，也看额外空间。哈希表平均 O(1) 查找，但需要桶和负载因子；平衡树 O(log n)，但能保持有序；数组随机访问 O(1)，中间插入却要移动元素。选择结构时依次问：需要按索引访问吗？需要保持顺序吗？插入删除频繁吗？数据量多大？内存是否受限？

## 线性结构

数组元素连续，缓存友好，随机访问快。链表每个节点存数据和指针，插入删除只需改指针，但不支持 O(1) 随机访问，且节点分散在内存中。单链表只向后，双链表可双向移动。实现链表最容易错的是边界：空链表、头节点、尾节点和释放节点后继续访问。

栈是后进先出，适合括号匹配、函数调用、撤销；队列是先进先出，适合任务调度、广度优先搜索。环形队列能复用数组空间，但必须区分空和满，常见做法是浪费一个槽位或额外保存 count。

## 哈希表

哈希函数把键映射到桶。不同键可能碰撞，常见解决方式有链地址法和开放寻址。负载因子过高会显著增加碰撞，应扩容并重新插入。哈希表平均性能优秀，但最坏情况可能退化为 O(n)。哈希函数必须与相等判断一致：相等的键必须得到相同哈希值。

## 树与图

二叉树每个节点最多两个子节点，二叉搜索树保证左小右大，但普通 BST 可能退化成链表。AVL、红黑树通过旋转维持平衡。堆是完全二叉树，常用数组表示，支持 O(log n) 插入和删除，适合优先队列。图的表示有邻接矩阵和邻接表；稀疏图通常用邻接表更省空间。

图遍历中，BFS 按层扩展，适合无权最短路径；DFS 适合连通性、拓扑排序、回溯。拓扑排序要求有向无环图。带权图最短路根据条件选择 Dijkstra、Bellman-Ford 等算法，不能把“最短路”当成一种算法。

## 排序与查找

稳定排序保持相等元素的相对顺序。插入排序适合小规模或近乎有序数据；归并排序稳定但有额外空间；快速排序平均快但最坏 O(n²)；堆排序原地 O(n log n)。二分查找要求数据有序，边界写法必须统一，推荐使用左闭右开区间 `[left, right)`，循环条件 `left < right`。

## 学习方法

每学一种结构，先写不变量和操作复杂度，再写测试：空、一个元素、两个元素、重复元素、删除不存在元素。用 AddressSanitizer 或 Valgrind 检查越界和泄漏。算法题不要只看答案，先写下暴力解法，再找重复计算和可复用状态，最后优化。
"""#,
                            codeLanguage: "c",
                            code: #"""
// 哈希表链地址法的核心结构
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

typedef struct Node {
    char *key;
    int value;
    struct Node *next;
} Node;

#define BUCKET_COUNT 16

typedef struct {
    Node *buckets[BUCKET_COUNT];
} HashMap;

static unsigned hash_string(const char *text) {
    unsigned hash = 5381;
    while (*text != '\0') {
        hash = hash * 33u + (unsigned char)*text++;
    }
    return hash;
}

static int map_put(HashMap *map, const char *key, int value) {
    unsigned index = hash_string(key) % BUCKET_COUNT;
    for (Node *node = map->buckets[index]; node != NULL; node = node->next) {
        if (strcmp(node->key, key) == 0) {
            node->value = value;
            return 0;
        }
    }

    Node *node = malloc(sizeof(*node));
    if (node == NULL) return -1;
    node->key = strdup(key);
    if (node->key == NULL) {
        free(node);
        return -1;
    }
    node->value = value;
    node->next = map->buckets[index];
    map->buckets[index] = node;
    return 0;
}

static void map_free(HashMap *map) {
    for (int i = 0; i < BUCKET_COUNT; ++i) {
        Node *node = map->buckets[i];
        while (node != NULL) {
            Node *next = node->next;
            free(node->key);
            free(node);
            node = next;
        }
    }
}

int main(void) {
    HashMap map = {0};
    if (map_put(&map, "alice", 95) != 0 || map_put(&map, "bob", 88) != 0) {
        map_free(&map);
        return 1;
    }
    printf("哈希表写入成功\n");
    map_free(&map);
    return 0;
}
"""#,
                            secondCodeLanguage: "swift",
                            secondCode: #"""
// Swift 中用泛型描述栈的行为
struct Stack<Element> {
    private var storage: [Element] = []

    mutating func push(_ element: Element) {
        storage.append(element)
    }

    mutating func pop() -> Element? {
        storage.popLast()
    }

    var isEmpty: Bool { storage.isEmpty }
}

var stack = Stack<Int>()
stack.push(10)
stack.push(20)
print(stack.pop() ?? 0) // 输出 20
"""#,
                            commonMistakes: #"""
- 只记复杂度符号，不理解操作前提，例如对无序数组使用二分查找。
- 链表删除时先 free 再访问 next，导致释放后使用。
- 哈希表扩容时忘记重新分配所有键。
- 递归 DFS 在深图上造成栈溢出，需要改为显式栈或限制深度。
- 二分查找边界混用，导致死循环或漏查。
"""#
                        )
                    ],
                    exercises: [
                        LearningExerciseSeed(
                            id: "exercise-dsa-choice",
                            order: 1,
                            title: "选择数据结构",
                            kind: .multipleChoice,
                            question: "需要频繁取最小元素并插入新元素，优先选择哪种结构？",
                            options: ["普通数组", "最小堆", "单链表", "哈希表"],
                            answer: "最小堆",
                            explanation: "最小堆可在 O(log n) 时间插入和删除最小元素，根节点始终是最小值。"
                        ),
                        LearningExerciseSeed(
                            id: "exercise-dsa-code",
                            order: 2,
                            title: "反转单链表",
                            kind: .coding,
                            question: "实现 C 函数 `reverse_list`，原地反转单链表并返回新头节点。",
                            answer: #"""
#include <stddef.h>

typedef struct Node {
    int value;
    struct Node *next;
} Node;

Node *reverse_list(Node *head) {
    Node *previous = NULL;
    Node *current = head;

    while (current != NULL) {
        Node *next = current->next; // 先保存后继
        current->next = previous;   // 反转当前节点的指针
        previous = current;         // 前驱前移
        current = next;             // 当前前进
    }

    return previous;
}
"""#,
                            explanation: "使用三个指针依次反转。关键顺序是先保存 next，否则修改 current->next 后会丢失后续链表。",
                            starterCode: "#include <stddef.h>\n\ntypedef struct Node { int value; struct Node *next; } Node;\n\nNode *reverse_list(Node *head) {\n    // 完成原地反转\n    return head;\n}\n",
                            codeLanguage: "c"
                        )
                    ]
                )
            ]
        ),
        LearningStageSeed(
            id: "stage-5",
            order: 7,
            title: "计算机架构与汇编",
            subtitle: "看清 C 代码如何变成寄存器、栈帧和机器指令。",
            icon: "memorychip",
            themeHex: "2D98DA",
            topics: [
                LearningTopicSeed(
                    id: "topic-architecture",
                    order: 1,
                    title: "x86-64 汇编与程序运行",
                    summary: "掌握寄存器、栈帧、调用约定、编译链接和缓存。",
                    estimatedMinutes: 320,
                    tutorials: [
                        LearningTutorialSeed(
                            id: "tutorial-architecture",
                            order: 1,
                            title: "从 C 到机器指令",
                            summary: "读懂基础 x86-64 汇编，理解函数调用、栈帧、链接和缓存。",
                            markdown: #"""
# 为什么看汇编

C 是编译型语言。源代码经过预处理、编译、汇编、链接，最终变成可执行文件。阅读汇编能验证编译器如何传参、返回值放在哪里、局部变量是否真的在栈上，以及优化如何改变代码。初学不必手写大型汇编，但要能看懂编译器生成的片段。

## x86-64 寄存器

通用寄存器包括 `rax`、`rbx`、`rcx`、`rdx`、`rsi`、`rdi`、`r8` 到 `r15`。`rip` 保存下一条指令地址，`rsp` 指向栈顶，`rbp` 常作为栈帧指针，`rflags` 保存比较和运算状态。寄存器有不同位宽：`rax` 64 位，`eax` 32 位，`ax` 16 位，`al` 8 位。向 32 位寄存器写入会清零高 32 位，这是常见细节。

## 栈帧和调用约定

System V AMD64 ABI 规定前六个整数/指针参数依次放在 `rdi`、`rsi`、`rdx`、`rcx`、`r8`、`r9`，更多参数放栈上。整数返回值放 `rax`。函数入口常看到 `push rbp; mov rbp, rsp; sub rsp, 16`，这是建立栈帧和为局部变量留空间。离开时用 `leave` 或恢复 `rsp/rbp`，再 `ret`。栈从高地址向低地址增长，局部变量地址通常比调用者参数更小。

理解调用约定后，调试器里的寄存器值才有意义。GDB 命令 `disassemble /m function` 可混合显示源代码和汇编，`info registers` 查看寄存器，`x/8gx $rsp` 查看栈内容。

## 编译与链接

`clang -c hello.c -o hello.o` 只编译成目标文件；`nm` 查看符号，`objdump -d` 反汇编。目标文件包含代码、数据和重定位信息。链接器把多个目标文件、启动代码和库合并，解析函数地址。静态库在链接时复制；动态库在运行时加载，减小可执行文件体积但需要正确的库路径。

## 缓存与局部性

CPU 缓存按块读取，利用时间局部性（刚访问的数据还会访问）和空间局部性（附近数据会被访问）。二维数组按行遍历通常比按列快，因为 C 的行在内存中连续。结构体字段大小和顺序会影响内存占用与缓存命中。优化前先用 `perf` 测量，不要仅凭直觉重排代码。

## 实验方法

写一个带 `-O0 -g` 的简单函数，用 `objdump -d` 或 `clang -S` 查看汇编；再使用 `-O2` 比较。不要认为优化后汇编必须更短，编译器会内联、展开循环和向量化。重点是理解语义保持一致，而不是背某一条指令。
"""#,
                            codeLanguage: "c",
                            code: #"""
// 用于观察参数传递和返回值
#include <stdio.h>

long add_many(long a, long b, long c, long d, long e, long f, long g) {
    return a + b + c + d + e + f + g;
}

int main(void) {
    long result = add_many(1, 2, 3, 4, 5, 6, 7);
    printf("%ld\n", result);
    return 0;
}
"""#,
                            secondCodeLanguage: "bash",
                            secondCode: #"""
# 生成汇编和反汇编
clang -O0 -S -masm=intel add.c -o add.s
clang -g -O0 add.c -o add
objdump -d --no-show-raw-insn add | sed -n '/<add_many>/,/^$/p'

# GDB 中查看寄存器和栈
gdb ./add
# break add_many
# run
# info registers rdi rsi rdx rcx r8 r9
# x/8gx $rsp
"""#,
                            commonMistakes: #"""
- 把寄存器名当成变量名，不理解它们会随指令变化。
- 只看 `-O0` 汇编就推断编译器无法优化。
- 混淆 `mov eax, 1` 与 `mov rax, 1` 的高位清零规则。
- 用未定义行为的 C 代码推测汇编结果；不同优化级别可能完全不同。
"""#
                        )
                    ],
                    exercises: [
                        LearningExerciseSeed(
                            id: "exercise-architecture-choice",
                            order: 1,
                            title: "识别参数寄存器",
                            kind: .multipleChoice,
                            question: "System V AMD64 下，函数第一个整数参数通常放在哪个寄存器？",
                            options: ["rax", "rdi", "rsp", "rip"],
                            answer: "rdi",
                            explanation: "前六个整数参数依次是 rdi、rsi、rdx、rcx、r8、r9；rax 常用于返回值。"
                        ),
                        LearningExerciseSeed(
                            id: "exercise-architecture-code",
                            order: 2,
                            title: "观察结构体布局",
                            kind: .coding,
                            question: "写 C 程序输出结构体总大小和每个字段偏移，观察对齐填充。",
                            answer: #"""
#include <stddef.h>
#include <stdio.h>

struct Sample {
    char tag;
    int count;
    double value;
};

int main(void) {
    printf("size=%zu\n", sizeof(struct Sample));
    printf("tag=%zu count=%zu value=%zu\n",
           offsetof(struct Sample, tag),
           offsetof(struct Sample, count),
           offsetof(struct Sample, value));
    return 0;
}
"""#,
                            explanation: "编译器会为满足对齐要求插入填充字节，所以结构体大小不等于字段大小之和。字段顺序改变可能改变总大小。",
                            starterCode: "#include <stddef.h>\n#include <stdio.h>\n\nstruct Sample { char tag; int count; double value; };\n\nint main(void) { return 0; }\n",
                            codeLanguage: "c"
                        )
                    ]
                )
            ]
        ),
        LearningStageSeed(
            id: "stage-6",
            order: 8,
            title: "操作系统 + Linux 系统编程",
            subtitle: "把进程、线程、内存、文件和内核接口统一起来。",
            icon: "gearshape.2",
            themeHex: "C0392B",
            topics: [
                LearningTopicSeed(
                    id: "topic-os-systems",
                    order: 1,
                    title: "操作系统原理与 POSIX 实践",
                    summary: "理解调度、同步、虚拟内存、文件系统，并动手写系统调用程序。",
                    estimatedMinutes: 560,
                    tutorials: [
                        LearningTutorialSeed(
                            id: "tutorial-os-systems",
                            order: 1,
                            title: "操作系统如何组织一台机器",
                            summary: "从进程和线程到虚拟内存与文件系统，再进入 POSIX 与 socket、epoll。",
                            markdown: #"""
# 操作系统的抽象

操作系统把 CPU、内存、磁盘、网卡等资源抽象成进程、线程、虚拟地址、文件和 socket。用户程序通过系统调用进入内核。进程拥有独立虚拟地址空间和资源；线程共享同一地址空间，但有独立栈和寄存器上下文。进程切换需要更换页表和地址空间，线程切换通常更轻，但共享内存也带来同步问题。

## 调度与同步

调度器在多个可运行任务间分配 CPU。时间片轮转强调响应性，优先级调度关注重要性，现代 Linux 使用 CFS/EEVDF 等策略兼顾公平和延迟。线程过多会增加上下文切换和缓存失效。同步的基本问题是竞态：结果依赖不可预测的执行顺序。互斥锁保证临界区互斥，条件变量让线程等待状态变化，信号量可用于限制并发数量。使用锁时要缩小临界区，避免在持锁时执行慢 I/O 或调用可能回调用户的代码。

## 虚拟内存

每个进程看到连续的虚拟地址空间，内核和 MMU 把虚拟页映射到物理页。未访问的页可以先不分配。缺页异常发生时，内核从磁盘或 swap 读取。`mmap` 可以把文件映射到内存，也可以创建匿名共享内存。虚拟内存让隔离、按需分配和共享库成为可能。内存泄漏是分配后失去释放引用；越界是写入不属于自己的区域，两者都可能长时间不显现。

## 文件系统与 VFS

Linux 用 VFS 统一表示文件和目录，具体文件系统如 ext4、XFS、Btrfs 提供实现。inode 保存元数据和数据块索引，目录项把名字映射到 inode。文件描述符是进程打开文件表的索引，`open` 返回小整数，多个 fd 可以指向同一个打开文件。权限、硬链接、软链接、缓存和写回策略都属于文件系统的行为。

## POSIX 综合路线

先用 open/read/write 复制文件，再实现 fork/exec/wait 启动子进程；然后创建线程并用互斥锁保护计数器；接着用信号优雅退出；最后写 TCP 服务器并用 poll、select 或 epoll 管理连接。每完成一段，都用 GDB 看调用栈，用 strace 看系统调用，用 valgrind 检查内存。不要只复制代码，必须能够解释资源什么时候创建、谁负责释放、错误时如何回滚。

## 调试点

程序崩溃先看 `dmesg` 是否记录段错误，再用 `gdb` 的 `backtrace`。文件打不开先检查路径、权限和当前工作目录，再 `strace -e trace=file`。线程卡住用 `gdb` 的 `thread apply all bt`。内存异常用 AddressSanitizer 或 valgrind。调试的目标是获得证据，不是随机改代码。
"""#,
                            codeLanguage: "c",
                            code: #"""
// 线程 + 互斥锁：安全累加
#include <pthread.h>
#include <stdio.h>

#define THREAD_COUNT 4
#define ITERATIONS 100000

typedef struct {
    long *counter;
    pthread_mutex_t *mutex;
} WorkerArgs;

static void *worker(void *raw_args) {
    WorkerArgs *args = raw_args;
    for (int i = 0; i < ITERATIONS; ++i) {
        pthread_mutex_lock(args->mutex);
        (*args->counter)++;
        pthread_mutex_unlock(args->mutex);
    }
    return NULL;
}

int main(void) {
    pthread_t threads[THREAD_COUNT];
    pthread_mutex_t mutex = PTHREAD_MUTEX_INITIALIZER;
    long counter = 0;
    WorkerArgs args = {.counter = &counter, .mutex = &mutex};

    for (int i = 0; i < THREAD_COUNT; ++i) {
        if (pthread_create(&threads[i], NULL, worker, &args) != 0) {
            perror("pthread_create");
            return 1;
        }
    }
    for (int i = 0; i < THREAD_COUNT; ++i) {
        pthread_join(threads[i], NULL);
    }

    printf("counter=%ld\n", counter);
    pthread_mutex_destroy(&mutex);
    return 0;
}
"""#,
                            secondCodeLanguage: "c",
                            secondCode: #"""
// mmap 读取文件前 16 字节
#include <fcntl.h>
#include <stdio.h>
#include <sys/mman.h>
#include <sys/stat.h>
#include <unistd.h>

int main(int argc, char *argv[]) {
    if (argc != 2) return 1;
    int fd = open(argv[1], O_RDONLY);
    if (fd < 0) { perror("open"); return 1; }

    struct stat info;
    if (fstat(fd, &info) < 0) { perror("fstat"); close(fd); return 1; }

    size_t length = (size_t)(info.st_size < 16 ? info.st_size : 16);
    if (length == 0) { close(fd); return 0; }

    void *address = mmap(NULL, length, PROT_READ, MAP_PRIVATE, fd, 0);
    if (address == MAP_FAILED) { perror("mmap"); close(fd); return 1; }

    write(STDOUT_FILENO, address, length);
    munmap(address, length);
    close(fd);
    return 0;
}
"""#,
                            commonMistakes: #"""
- 只加锁一半或在不同路径提前返回时忘记解锁。
- 线程函数返回指向局部变量的指针。
- 忘记 `pthread_join`，程序可能提前退出或泄漏线程资源。
- mmap 长度超过文件大小后访问，可能触发 SIGBUS。
- 把线程安全和可重入当成同一个概念。
"""#
                        )
                    ],
                    exercises: [
                        LearningExerciseSeed(
                            id: "exercise-os-choice",
                            order: 1,
                            title: "理解线程共享",
                            kind: .multipleChoice,
                            question: "同一进程内多个线程默认共享哪一项？",
                            options: ["虚拟地址空间", "线程栈", "寄存器上下文", "线程 ID"],
                            answer: "虚拟地址空间",
                            explanation: "线程共享代码、堆和全局数据，但每个线程拥有自己的栈、寄存器和线程标识。"
                        ),
                        LearningExerciseSeed(
                            id: "exercise-os-code",
                            order: 2,
                            title: "安全递增计数器",
                            kind: .coding,
                            question: "使用 pthread 创建 4 个线程，每个线程把共享计数器增加 100000 次，并用互斥锁保证结果正确。",
                            answer: #"""
#include <pthread.h>
#include <stdio.h>

#define THREADS 4
#define LOOPS 100000

static pthread_mutex_t lock = PTHREAD_MUTEX_INITIALIZER;
static long counter = 0;

static void *run(void *unused) {
    (void)unused;
    for (int i = 0; i < LOOPS; ++i) {
        pthread_mutex_lock(&lock);
        ++counter;
        pthread_mutex_unlock(&lock);
    }
    return NULL;
}

int main(void) {
    pthread_t ids[THREADS];
    for (int i = 0; i < THREADS; ++i) pthread_create(&ids[i], NULL, run, NULL);
    for (int i = 0; i < THREADS; ++i) pthread_join(ids[i], NULL);
    printf("%ld\n", counter);
    pthread_mutex_destroy(&lock);
    return 0;
}
"""#,
                            explanation: "临界区只包含对 counter 的读改写，锁必须在所有正常路径释放，主线程 join 之后再打印。",
                            starterCode: "#include <pthread.h>\n#include <stdio.h>\n\nint main(void) {\n    // 创建 4 个线程并等待完成\n    return 0;\n}\n",
                            codeLanguage: "c"
                        )
                    ]
                )
            ]
        ),
        LearningStageSeed(
            id: "stage-7",
            order: 9,
            title: "计算机网络",
            subtitle: "从协议分层走向可运行的 C HTTP 服务器。",
            icon: "network",
            themeHex: "13A7A0",
            topics: [
                LearningTopicSeed(
                    id: "topic-networking",
                    order: 1,
                    title: "TCP/IP、HTTP 与 Socket",
                    summary: "理解 DNS、TCP/IP、Socket 编程、抓包和最小 HTTP 服务器。",
                    estimatedMinutes: 360,
                    tutorials: [
                        LearningTutorialSeed(
                            id: "tutorial-networking",
                            order: 1,
                            title: "一台服务器如何接收浏览器请求",
                            summary: "把 DNS、TCP/IP、HTTP 和 Socket 编程串成一次完整请求。",
                            markdown: #"""
# 网络分层与数据封装

应用数据从浏览器出发，HTTP 层添加请求方法、路径和头部，TCP 层添加端口和序号，IP 层添加源和目的地址，链路层再封装为帧。接收端逐层拆除头部，最终交回应用。分层让网络设备只关心自己的一层，但排错时要沿完整路径观察。

DNS 把域名解析为 IP。解析结果可能来自浏览器缓存、系统缓存、运营商 DNS 或权威服务器。`dig +trace example.com` 能看到递归查询过程。域名解析成功不代表服务器可访问，还要继续检查 TCP 端口、TLS 和 HTTP 状态码。

## TCP 与 Socket API

服务器流程是 `socket → bind → listen → accept → recv/send → close`。客户端是 `socket → connect → send/recv → close`。`bind` 指定监听地址和端口，`listen` 把 socket 变成被动连接队列，`accept` 返回新的已连接 fd。TCP 是字节流：一次 `recv` 可能收到半条消息，也可能一次收到两条消息，应用协议必须定义长度或分隔符。

`getaddrinfo` 统一处理 IPv4/IPv6 和域名解析，比手写 `sockaddr_in` 更可移植。每次系统调用都要检查返回值和 `errno`，`EINTR` 通常应重试。地址端口使用网络字节序，`htons`、`htonl` 负责转换。

## HTTP 最小实现

HTTP 请求第一行类似 `GET /hello HTTP/1.1`，头部以空行结束。服务器至少解析方法、路径和版本，返回状态行、`Content-Length`、`Content-Type`、空行和正文。`Content-Length` 必须与实际字节数一致，否则客户端可能一直等待。HTTP/1.1 默认持久连接，简单学习服务器可返回 `Connection: close` 后关闭连接。

## 抓包与安全

`tcpdump -i any -nn -A port 8080` 能查看明文 HTTP。HTTPS 经过 TLS 加密，抓包看不到正文，只能分析握手和连接。开发环境可以抓包，生产环境要避免记录密码、Cookie 和身份证等敏感数据。

构建服务器时，先实现单连接，再加入 `fork` 或线程，最后学习 `poll/epoll` 事件循环。不要一开始就写高并发框架。每增加一层，都用 `curl -v`、`ss -tulpn`、`tcpdump` 和日志验证行为。

## 最小服务器安全边界

学习服务器只监听 `127.0.0.1`，避免无意暴露到局域网；上线时再绑定实际地址并配置防火墙。限制请求头大小和正文长度，设置读写超时，防止慢连接长期占用线程。错误信息不要回显文件路径或内部实现，日志中也要避免记录密码、Cookie 与完整请求正文。
"""#,
                            codeLanguage: "c",
                            code: #"""
// 最小 TCP HTTP/1.0 服务器
#include <arpa/inet.h>
#include <stdio.h>
#include <string.h>
#include <sys/socket.h>
#include <unistd.h>

int main(void) {
    int server = socket(AF_INET, SOCK_STREAM, 0);
    if (server < 0) { perror("socket"); return 1; }

    int yes = 1;
    setsockopt(server, SOL_SOCKET, SO_REUSEADDR, &yes, sizeof(yes));

    struct sockaddr_in address = {0};
    address.sin_family = AF_INET;
    address.sin_addr.s_addr = htonl(INADDR_ANY);
    address.sin_port = htons(8080);

    if (bind(server, (struct sockaddr *)&address, sizeof(address)) < 0) {
        perror("bind"); close(server); return 1;
    }
    if (listen(server, 16) < 0) {
        perror("listen"); close(server); return 1;
    }

    printf("监听 http://127.0.0.1:8080\n");
    for (;;) {
        int client = accept(server, NULL, NULL);
        if (client < 0) { perror("accept"); continue; }

        char request[2048];
        ssize_t received = recv(client, request, sizeof(request) - 1, 0);
        if (received > 0) {
            request[received] = '\0';
            printf("请求首行: %.60s\n", request);
        }

        const char body[] = "Hello from C HTTP server\n";
        char response[512];
        int length = snprintf(response, sizeof(response),
            "HTTP/1.1 200 OK\r\n"
            "Content-Type: text/plain; charset=utf-8\r\n"
            "Content-Length: %zu\r\n"
            "Connection: close\r\n\r\n%s",
            strlen(body), body);
        send(client, response, (size_t)length, 0);
        close(client);
    }
}
"""#,
                            secondCodeLanguage: "bash",
                            secondCode: #"""
# 编译服务器并在另一个终端测试
clang -Wall -Wextra -g -o http_server http_server.c
./http_server

curl -v http://127.0.0.1:8080/
sudo tcpdump -i lo0 -nn -A port 8080
ss -tulpn | grep 8080
"""#,
                            commonMistakes: #"""
- 假设一次 `recv` 收到完整 HTTP 请求。
- 响应头 `Content-Length` 与正文长度不一致。
- 忘记网络字节序转换，端口监听结果异常。
- 不处理 `accept` 失败和 `EINTR`。
- 在 HTTP 正文中输出未经转义的用户输入，造成 XSS。
"""#
                        )
                    ],
                    exercises: [
                        LearningExerciseSeed(
                            id: "exercise-networking-choice",
                            order: 1,
                            title: "理解 accept",
                            kind: .multipleChoice,
                            question: "TCP 服务器调用 `accept` 后得到的文件描述符表示什么？",
                            options: ["监听 socket", "与某个客户端连接的新 socket", "DNS 记录", "进程 PID"],
                            answer: "与某个客户端连接的新 socket",
                            explanation: "监听 socket 继续等待新连接；accept 返回的是本次已建立连接专用的 fd，服务器用它读写该客户端。"
                        ),
                        LearningExerciseSeed(
                            id: "exercise-networking-code",
                            order: 2,
                            title: "返回当前连接信息",
                            kind: .coding,
                            question: "在最小 HTTP 服务器中加入 `getpeername`，把客户端 IP 和端口放入响应正文。",
                            answer: #"""
#include <arpa/inet.h>
#include <stdio.h>
#include <string.h>
#include <sys/socket.h>
#include <unistd.h>

// 假设 client 已由 accept 得到
void respond_with_peer(int client) {
    struct sockaddr_storage peer = {0};
    socklen_t length = sizeof(peer);
    char host[INET6_ADDRSTRLEN] = "unknown";
    char service[16] = "0";

    if (getpeername(client, (struct sockaddr *)&peer, &length) == 0) {
        getnameinfo((struct sockaddr *)&peer, length,
                    host, sizeof(host), service, sizeof(service),
                    NI_NUMERICHOST | NI_NUMERICSERV);
    }

    char body[256];
    snprintf(body, sizeof(body), "client=%s port=%s\n", host, service);
    char response[512];
    int n = snprintf(response, sizeof(response),
        "HTTP/1.1 200 OK\r\nContent-Type: text/plain\r\n"
        "Content-Length: %zu\r\nConnection: close\r\n\r\n%s",
        strlen(body), body);
    send(client, response, (size_t)n, 0);
}
"""#,
                            explanation: "getpeername 获取已连接 socket 的对端地址。sockaddr_storage 足够容纳 IPv4 或 IPv6，getnameinfo 安全地格式化数值地址。",
                            starterCode: "#include <arpa/inet.h>\n#include <sys/socket.h>\n\nvoid respond_with_peer(int client) {\n    // 获取客户端地址并返回正文\n}\n",
                            codeLanguage: "c"
                        )
                    ]
                )
            ]
        )
    ]
}
