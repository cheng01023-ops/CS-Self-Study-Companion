import Foundation

enum CatalogFoundation {
    static let stages: [LearningStageSeed] = [
        LearningStageSeed(
            id: "stage-0",
            order: 0,
            title: "Mac 终端与开发工具",
            subtitle: "先让电脑成为学习工具：终端、Homebrew、Git、编译器和编辑器。",
            icon: "macbook.and.iphone",
            themeHex: "4F7CFF",
            topics: [
                LearningTopicSeed(
                    id: "topic-terminal-tools",
                    order: 1,
                    title: "从 Finder 走进终端",
                    summary: "认识目录、路径、权限，并完成第一套 Mac 开发工具链。",
                    estimatedMinutes: 150,
                    tutorials: [
                        LearningTutorialSeed(
                            id: "tutorial-mac-terminal",
                            order: 1,
                            title: "终端、文件权限与第一套工具链",
                            summary: "理解命令行为什么重要，并独立编译、运行、编辑和提交一个 C 程序。",
                            markdown: #"""
# 为什么要学终端

图形界面适合浏览文件，终端适合精确、可重复地执行操作。以后安装编译器、连接服务器、运行测试、查看日志，都离不开终端。它看起来只有文字，但每个命令都遵循“程序名 + 参数 + 目标”的结构，理解之后并不可怕。

## 一、启动终端并认识路径

在 macOS 打开“访达 → 应用程序 → 实用工具 → 终端”，也可以按 `Command + Space` 搜索“终端”。打开后看到的 `%` 或 `$` 是提示符，表示 Shell 已准备好接收命令。可以用 `pwd` 查看当前位置，用 `ls -lah` 查看文件。`/` 是根目录，`~` 是当前用户主目录，`.` 是当前目录，`..` 是上一级目录。绝对路径从 `/` 开始；相对路径从当前位置开始。

`cd 路径` 用于切换目录，`mkdir -p` 用于创建多层目录，`touch` 创建空文件，`cp` 复制，`mv` 移动或改名，`rm` 删除。`rm` 不会默认放到废纸篓，练习删除时先使用 `rm -i`。输入 `man 命令名` 可以查看手册，按 `q` 退出。

## 二、理解权限

`ls -l` 左边类似 `-rw-r--r--`。第一个字符表示类型，后九位分成三组：所有者、用户组、其他人，每组依次是读、写、执行权限。`r=4`、`w=2`、`x=1`，所以 `chmod 644 file.c` 表示所有者可读写，其他人只读；`chmod 755 script.sh` 表示所有者可读写执行，其他人可读执行。不要为了省事长期执行 `chmod 777`，它会让所有人都能修改文件。

## 三、安装 Homebrew 与工具

Homebrew 是 macOS 常用包管理器。安装完成后，使用 `brew install git gcc` 安装 Git 和 GCC。macOS 自带 Clang，也可以直接使用 `clang`。推荐安装 VS Code，并在终端执行 `code hello.c` 打开当前目录中的文件。编辑器的终端、文件树和调试器只是工具表层；真正需要掌握的是保存、编译、运行、观察错误这四个循环。

## 四、编译和 Git 最小闭环

C 源文件不能直接双击运行。先写代码，再用编译器生成可执行文件。编译时加上 `-Wall -Wextra -g`：前两项打开警告，`-g` 保留调试信息。若出现错误，先读第一条错误所在文件和行号，修复后重新编译，不要被后续连锁错误吓到。

Git 用来记录代码历史。第一次使用时设置用户名和邮箱，然后依次执行 `git init`、`git status`、`git add`、`git commit`。提交信息描述“完成了什么”，例如“打印三个整数并验证参数顺序”。每天至少提交一次，让版本历史成为学习日志。

## 五、建议练习流程

1. 创建 `~/Code/cs-study/day01`。
2. 在该目录写一个 C 程序，输出姓名和今天学习的命令。
3. 使用警告选项编译并运行。
4. 初始化 Git 仓库并完成第一次提交。
5. 故意删除一个分号，观察编译器报错，再恢复。

命令行能力来自重复操作，不来自背表格。先能完成小任务，再逐步记住常用参数。
"""#,
                            codeLanguage: "c",
                            code: #"""
// 第一个可编译的 C 程序：输出欢迎信息
#include <stdio.h>

int main(void) {
    printf("欢迎开始 CS 自学！\n");
    printf("今天先掌握终端、编译器和 Git。\n");
    return 0;
}
"""#,
                            secondCodeLanguage: "bash",
                            secondCode: #"""
mkdir -p ~/Code/cs-study/day01
cd ~/Code/cs-study/day01
touch hello.c
# 把上面的 C 代码保存到 hello.c 后执行：
clang -Wall -Wextra -g -o hello hello.c
./hello

git init
git add hello.c
git commit -m "完成第一个 C 程序"
"""#,
                            commonMistakes: #"""
- 把 `clang` 当成运行命令：它只负责编译，成功后还要执行 `./hello`。
- 在错误的目录创建文件：先 `pwd`，必要时再 `cd`。
- 为所有文件执行 `chmod 777`：权限过宽，容易造成安全风险。
- Git 提交前不执行 `git status`：可能漏掉文件或提交不相关内容。
"""#
                        )
                    ],
                    exercises: [
                        LearningExerciseSeed(
                            id: "exercise-terminal-choice",
                            order: 1,
                            title: "定位编译错误",
                            kind: .multipleChoice,
                            question: "执行 `clang -Wall -Wextra -o hello hello.c` 后，终端最可能生成哪个文件？",
                            options: ["hello.c", "名为 hello 的可执行文件",  "自动打开浏览器", "hello.zip"],
                            answer: "名为 hello 的可执行文件",
                            explanation: "`-o hello` 指定输出文件名。编译成功后用 `./hello` 运行；源文件 hello.c 不会被替换。"
                        ),
                        LearningExerciseSeed(
                            id: "exercise-first-c",
                            order: 2,
                            title: "编写并编译问候程序",
                            kind: .coding,
                            question: "编写 C 程序：接收一个由 `argv[1]` 传入的名字，输出 `你好，名字！`。如果未提供参数，输出用法提示并返回 1。",
                            answer: #"""
#include <stdio.h>

int main(int argc, char *argv[]) {
    if (argc != 2) {
        fprintf(stderr, "用法: %s 名字\n", argv[0]);
        return 1;
    }

    printf("你好，%s！\n", argv[1]);
    return 0;
}
"""#,
                            explanation: "`argc` 是参数个数，程序名算第一个；用户输入的名字位于 `argv[1]`。错误信息输出到 stderr，退出码 1 表示失败。",
                            starterCode: #"""
#include <stdio.h>

int main(int argc, char *argv[]) {
    // 在这里判断参数并输出问候
    return 0;
}
"""#,
                            codeLanguage: "c"
                        )
                    ]
                )
            ]
        ),
        LearningStageSeed(
            id: "stage-1",
            order: 1,
            title: "计算机通识",
            subtitle: "从 0 和 1 出发，理解数据如何被表示、运算和存储。",
            icon: "cpu",
            themeHex: "16A085",
            topics: [
                LearningTopicSeed(
                    id: "topic-computer-basics",
                    order: 1,
                    title: "二进制、硬件与操作系统",
                    summary: "掌握进制、位运算、CPU/内存/存储和操作系统的基本职责。",
                    estimatedMinutes: 140,
                    tutorials: [
                        LearningTutorialSeed(
                            id: "tutorial-computer-basics",
                            order: 1,
                            title: "计算机到底在做什么",
                            summary: "用直观模型串起二进制、位运算、CPU、内存、存储和操作系统。",
                            markdown: #"""
# 为什么是二进制

计算机内部用高低电平表示信息，稳定地区分两种状态比精确区分十种电压容易，因此采用二进制。一个二进制位叫 bit，八个 bit 组成 byte。十进制 13 写成二进制是 `1101`，因为 `8 + 4 + 0 + 1 = 13`。十六进制每四位二进制对应一位，所以 `1101` 是 `D`，它常用于简洁表示内存地址和字节。

整数在有限位宽中存储。无符号 8 位可表示 0 到 255；有符号整数通常用补码表示负数。`-1` 的 8 位补码是全 1。补码让加法和减法共用同一套电路，但溢出仍然可能发生，例如 8 位有符号的 127 加 1 会回到 -128。

## 位运算

`&` 是按位与，`|` 是按位或，`^` 是异或，`~` 按位取反，`<<` 和 `>>` 是移位。它们常用于权限标志、底层协议和高效集合。例如用第 0、1、2 位表示读、写、执行：`READ | WRITE` 得到 3，再用 `flags & READ` 检查读权限。C 中操作无符号整数更安全，右移负数属于实现相关行为。

## CPU、内存和存储

CPU 负责取指令、译码和执行。寄存器速度最快但数量很少；缓存位于 CPU 和内存之间；内存（RAM）存放正在运行的程序和数据，断电后丢失；SSD/HDD 持久保存数据，但速度慢得多。程序运行时，CPU 按地址访问内存，操作系统负责把虚拟地址映射到物理页。缓存命中率高时程序更快，这也是顺序访问数组通常比随机跳转链表更快的原因。

## 操作系统做什么

操作系统不是某个窗口程序，而是管理硬件资源的核心软件。它负责进程调度、内存管理、文件系统、设备驱动、网络和权限。应用程序不能随意控制硬件，需要通过系统调用请求内核提供服务，例如打开文件、创建进程、发送网络数据。用户态与内核态分离，既保证安全，也让程序可以在不同硬件上运行。

## 观察实践

在 macOS 可使用 `sysctl -n machdep.cpu.brand_string` 查看 CPU 名称，使用 `vm_stat` 观察内存页，使用 `df -h` 查看磁盘。不要急着记住所有数字，先建立层次：寄存器 < 缓存 < 内存 < SSD < 网络/磁盘。越靠近 CPU 越快、越贵、容量越小。性能优化常从减少数据搬运和改善访问局部性开始。

最后要形成一种思维方式：看到 `int`、指针、文件或网络连接时，都继续追问“它占多少字节、地址在哪里、由谁管理、速度如何”。这就是计算机通识对后续 C、Linux 和系统编程的价值。

## 把概念连起来

看到一个数值时，继续追问：它是否可能为负、范围多大、需要多少位、在内存里占几个字节。看到一个程序时，追问它使用哪块存储、是否频繁分配、访问是否连续。二进制、位运算、CPU、内存和存储并不是孤立知识，而是同一条“表示、搬运、计算、保存”的链路。
"""#,
                            codeLanguage: "c",
                            code: #"""
// 观察整数表示、位运算和字节大小
#include <stdio.h>
#include <stdint.h>

static void print_binary(uint8_t value) {
    for (int bit = 7; bit >= 0; --bit) {
        putchar((value & (1u << bit)) ? '1' : '0');
    }
}

int main(void) {
    uint8_t flags = (1u << 0) | (1u << 2); // 第 0、2 位设为 1
    printf("flags = %u, binary = ", flags);
    print_binary(flags);
    printf("\nread? %s\n", (flags & (1u << 0)) ? "yes" : "no");
    printf("int: %zu 字节, 指针: %zu 字节\n", sizeof(int), sizeof(void *));
    return 0;
}
"""#,
                            secondCodeLanguage: "bash",
                            secondCode: #"""
# macOS 上观察机器的基本资源
sysctl -n machdep.cpu.brand_string
vm_stat
df -h
"""#,
                            commonMistakes: #"""
- 把十进制数值与它的字符串表示混为一谈：`printf("%d", 13)` 输出字符 1 和 3，但内存中是数值 13。
- 忽略整数位宽和溢出：先确认类型能表示的范围。
- 认为内存越大程序一定越快：访问模式、缓存和算法复杂度同样重要。
- 把操作系统等同于桌面界面：Linux 服务器通常没有图形桌面，但仍有完整操作系统。
"""#
                        )
                    ],
                    exercises: [
                        LearningExerciseSeed(
                            id: "exercise-binary-choice",
                            order: 1,
                            title: "读取二进制",
                            kind: .multipleChoice,
                            question: "二进制 `101101` 对应的十进制是多少？",
                            options: ["37", "45", "53", "61"],
                            answer: "45",
                            explanation: "32 + 8 + 4 + 1 = 45。从左到右的位权依次是 32、16、8、4、2、1。"
                        ),
                        LearningExerciseSeed(
                            id: "exercise-bit-flags",
                            order: 2,
                            title: "实现权限标志检查",
                            kind: .coding,
                            question: "定义 READ=1、WRITE=2、EXECUTE=4，输入一个整数 flags，分别输出是否拥有三种权限。",
                            answer: #"""
#include <stdio.h>

enum Permission {
    READ = 1u << 0,
    WRITE = 1u << 1,
    EXECUTE = 1u << 2
};

int main(void) {
    unsigned flags = 0;
    if (scanf("%u", &flags) != 1) {
        return 1;
    }

    printf("read=%s\n", (flags & READ) ? "yes" : "no");
    printf("write=%s\n", (flags & WRITE) ? "yes" : "no");
    printf("execute=%s\n", (flags & EXECUTE) ? "yes" : "no");
    return 0;
}
"""#,
                            explanation: "每一位表示一种独立权限，使用按位与可以只检查目标位，而不会受其他位影响。",
                            starterCode: "#include <stdio.h>\n\nint main(void) {\n    unsigned flags = 0;\n    scanf(\"%u\", &flags);\n    // 检查三种权限\n    return 0;\n}\n",
                            codeLanguage: "c"
                        )
                    ]
                )
            ]
        ),
        LearningStageSeed(
            id: "stage-2",
            order: 2,
            title: "C 语言基础",
            subtitle: "用 C 建立变量、控制流、函数、内存和文件操作的完整基础。",
            icon: "chevron.left.forwardslash.chevron.right",
            themeHex: "8E44AD",
            topics: [
                LearningTopicSeed(
                    id: "topic-c-foundation",
                    order: 1,
                    title: "C 语言核心语法",
                    summary: "覆盖变量、类型、控制流、函数、数组、字符串、指针、结构体和文件。",
                    estimatedMinutes: 520,
                    tutorials: [
                        LearningTutorialSeed(
                            id: "tutorial-c-foundation",
                            order: 1,
                            title: "从一行 C 代码到指针与文件",
                            summary: "沿着“数据、控制、组合、地址、持久化”的主线学完 C 基础。",
                            markdown: #"""
# 为什么学习 C

C 接近机器，却仍有清晰的抽象。它能让你看见类型大小、地址、内存和系统调用，是理解操作系统、Linux 和汇编的重要桥梁。学习 C 的关键不是堆语法，而是始终追踪三件事：数据是什么类型、它放在哪里、谁负责释放。

## 变量、类型和表达式

变量是带名称的存储位置。`int` 常用来存整数，`double` 存小数，`char` 存一个字节，`sizeof` 可查看类型大小。声明时应初始化，因为局部变量的初值不确定。`printf` 的格式符必须与参数类型匹配：`%d` 对应 int，`%zu` 对应 size_t，`%f` 对应 double，`%s` 对应字符串。编译器警告能发现大量类型错误，所以要习惯 `-Wall -Wextra`。

运算符有优先级。`*`、`/` 先于 `+`、`-`，比较运算低于算术运算，赋值最低。整数除法会截断小数部分：`5 / 2` 是 2。需要小数时应写成 `5.0 / 2`。自增 `++i` 和 `i++` 在独立语句中通常没区别，放进复杂表达式容易产生阅读和求值顺序问题，不建议炫技。

## 控制流和函数

`if/else` 让程序分支，`for` 适合已知次数循环，`while` 适合条件驱动循环，`switch` 适合离散分支。每个分支要覆盖边界，例如空输入、0、负数、最大值。函数把一段逻辑命名，参数负责输入，返回值负责输出。函数声明放在头文件或调用之前，定义负责实现。按值传递会复制参数；传入指针后函数才能修改调用者的对象。

## 数组、字符串和指针

数组元素在内存中连续排列，索引从 0 开始。`int a[5]` 合法索引是 0 到 4，越界不会自动报错，却可能破坏其他数据。C 字符串是以 `\0` 结尾的 char 数组，`strlen` 计算结尾之前字符数，`strcpy` 不会检查目标容量，初学阶段优先使用 `strncpy`、`snprintf` 并显式补 `\0`。

指针保存地址。`&x` 取得 x 的地址，`*p` 解引用访问该地址的值。数组名在表达式中常退化为首元素地址，所以 `a[i]` 等价于 `*(a + i)`。指针算术按元素大小移动，不是按字节。理解“地址、类型、长度”三个信息，大多数指针问题都能拆开。不要把未初始化指针解引用，也不要返回局部数组地址。

## 结构体、动态内存和文件

结构体把相关字段组合成新类型，例如 `struct Student { char name[32]; int score; };`。访问字段用 `.`，通过指针访问用 `->`。动态内存用 `malloc`/`calloc` 分配，用 `free` 释放；每个成功分配都要有明确释放路径。常见错误是重复释放、越界写入和忘记释放。

文件操作通过 `FILE *` 完成。`fopen` 打开文件，失败返回 `NULL`；`fprintf`/`fputs` 写，`fgets` 逐行读；最后必须 `fclose`。文本文件通常以行组织，读取缓冲区要预留 `\0` 位置。程序处理文件时，要区分“文件不存在”“权限不足”“磁盘写满”，而不是所有错误都返回“失败”。

## 推荐学习闭环

每个主题都按四步做：手写最小示例，制造一个错误，用编译器和调试器定位，再从空文件重写。能运行不等于掌握；能解释每一行为什么存在，并能修改需求，才是真正理解。
"""#,
                            codeLanguage: "c",
                            code: #"""
// 综合示例：结构体数组、查找和文件写入
#include <stdio.h>
#include <string.h>

#define STUDENT_COUNT 3

typedef struct {
    char name[32];
    int score;
} Student;

static const Student *find_student(const Student *items, size_t count, const char *name) {
    for (size_t i = 0; i < count; ++i) {
        if (strcmp(items[i].name, name) == 0) {
            return &items[i];
        }
    }
    return NULL;
}

int main(void) {
    Student students[STUDENT_COUNT] = {
        {"Ada", 95},
        {"Linus", 88},
        {"Grace", 92}
    };

    const Student *found = find_student(students, STUDENT_COUNT, "Grace");
    if (found != NULL) {
        printf("%s 的分数：%d\n", found->name, found->score);
    }

    FILE *file = fopen("scores.txt", "w");
    if (file == NULL) {
        perror("fopen");
        return 1;
    }

    for (size_t i = 0; i < STUDENT_COUNT; ++i) {
        fprintf(file, "%s %d\n", students[i].name, students[i].score);
    }
    fclose(file);
    return 0;
}
"""#,
                            secondCodeLanguage: "c",
                            secondCode: #"""
// 动态数组：分配、初始化、释放
#include <stdio.h>
#include <stdlib.h>

int main(void) {
    int *numbers = calloc(5, sizeof(*numbers));
    if (numbers == NULL) {
        fprintf(stderr, "内存分配失败\n");
        return 1;
    }

    for (int i = 0; i < 5; ++i) {
        numbers[i] = i * i;
        printf("%d ", numbers[i]);
    }
    putchar('\n');

    free(numbers); // 释放后不要再访问 numbers
    return 0;
}
"""#,
                            commonMistakes: #"""
- 字符串数组容量没有给结尾 `\0` 留位置。
- 使用未初始化指针，或 `free` 后继续访问。
- `scanf("%d", value)` 少写 `&`，正确写法是 `&value`。
- 用 `==` 比较字符串内容；C 字符串应使用 `strcmp`。
- 忘记检查 `malloc`、`fopen` 的返回值。
"""#
                        )
                    ],
                    exercises: [
                        LearningExerciseSeed(
                            id: "exercise-c-pointer",
                            order: 1,
                            title: "判断指针行为",
                            kind: .multipleChoice,
                            question: "已有 `int a[3] = {10, 20, 30}; int *p = a;`，表达式 `*(p + 2)` 的值是多少？",
                            options: ["10", "20", "30", "不确定"],
                            answer: "30",
                            explanation: "`p` 指向 a[0]，`p + 2` 指向 a[2]，解引用得到 30。指针加法按元素类型移动。"
                        ),
                        LearningExerciseSeed(
                            id: "exercise-c-average",
                            order: 2,
                            title: "计算文件中的平均分",
                            kind: .coding,
                            question: "读取一行整数：第一个数是数量 n，后面有 n 个分数。输出平均值，保留两位小数；n 小于等于 0 时返回 1。",
                            answer: #"""
#include <stdio.h>

int main(void) {
    int count = 0;
    if (scanf("%d", &count) != 1 || count <= 0) {
        return 1;
    }

    double sum = 0.0;
    for (int i = 0; i < count; ++i) {
        int score = 0;
        if (scanf("%d", &score) != 1) {
            return 1;
        }
        sum += score;
    }

    printf("%.2f\n", sum / count);
    return 0;
}
"""#,
                            explanation: "把输入校验、累加和输出分开处理。sum 使用 double，避免整数除法丢失小数。",
                            starterCode: "#include <stdio.h>\n\nint main(void) {\n    int count = 0;\n    scanf(\"%d\", &count);\n    // 读取 count 个分数并求平均\n    return 0;\n}\n",
                            codeLanguage: "c"
                        )
                    ]
                )
            ]
        )
    ]
}
