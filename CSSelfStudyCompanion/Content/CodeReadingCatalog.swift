import Foundation

struct CodeReadingExercise: Identifiable {
    let id: String
    let title: String
    let focus: String
    let language: String
    let code: String
    let prompt: String
    let options: [String]
    let correctIndex: Int
    let explanation: String
}

enum CodeReadingCatalog {
    static let exercises: [CodeReadingExercise] = [
        CodeReadingExercise(
            id: "cr-pointer-swap",
            title: "指针参数为什么没有交换",
            focus: "C 指针",
            language: "c",
            code: """
            void swap(int a, int b) {
                int temp = a;
                a = b;
                b = temp;
            }
            int main(void) {
                int x = 1, y = 2;
                swap(x, y);
                printf("%d %d\\n", x, y);
            }
            """,
            prompt: "程序会输出什么，原因是什么？",
            options: ["1 2，因为 swap 只修改了参数副本", "2 1，因为 C 自动传递引用", "1 2，因为 printf 顺序相反", "编译失败，因为 swap 没有声明"],
            correctIndex: 0,
            explanation: "C 的参数默认按值传递。要修改调用者变量，需要传入 int *，并在函数内解引用。"
        ),
        CodeReadingExercise(
            id: "cr-array-bound",
            title: "数组越界的隐蔽错误",
            focus: "C 内存",
            language: "c",
            code: """
            int a[3] = {1, 2, 3};
            for (int i = 0; i <= 3; i++) {
                printf("%d ", a[i]);
            }
            """,
            prompt: "循环至少存在什么问题？",
            options: ["多访问一次 a[3]，造成越界读", "数组会自动扩展到 4 个元素", "printf 不能打印数组", "循环不会执行"],
            correctIndex: 0,
            explanation: "合法下标是 0 到 2。条件 i <= 3 会访问 a[3]，属于未定义行为。"
        ),
        CodeReadingExercise(
            id: "cr-strlen-null",
            title: "字符串终止符",
            focus: "C 字符串",
            language: "c",
            code: """
            char s[4] = {'t', 'e', 's', 't'};
            printf("%zu\\n", strlen(s));
            """,
            prompt: "这段代码为什么不可靠？",
            options: ["数组中没有 '\\0'，strlen 会继续越界读取", "strlen 只能用于 int 数组", "数组必须写成 char *s", "printf 不支持 %zu"],
            correctIndex: 0,
            explanation: "C 字符串必须以 '\\0' 结尾。这里四个字符刚好占满数组，没有终止符。"
        ),
        CodeReadingExercise(
            id: "cr-malloc-free",
            title: "释放后继续访问",
            focus: "C 内存",
            language: "c",
            code: """
            int *p = malloc(sizeof(int));
            *p = 42;
            free(p);
            printf("%d\\n", *p);
            """,
            prompt: "free 后的 printf 有什么风险？",
            options: ["use-after-free，结果未定义", "free 会把 p 自动设为 NULL", "printf 会自动重新分配内存", "没有风险，因为整数很小"],
            correctIndex: 0,
            explanation: "free 后指针值通常不会自动清空。继续解引用属于 use-after-free。"
        ),
        CodeReadingExercise(
            id: "cr-fork-order",
            title: "fork 创建了几个进程",
            focus: "Linux 进程",
            language: "c",
            code: """
            fork();
            fork();
            printf("A\\n");
            """,
            prompt: "正常情况下会打印几行 A？",
            options: ["4 行", "2 行", "3 行", "1 行"],
            correctIndex: 0,
            explanation: "第一次 fork 后有两个进程，第二次 fork 让每个进程再复制一次，共 4 个进程。"
        ),
        CodeReadingExercise(
            id: "cr-pipe-close",
            title: "管道 read 为什么一直阻塞",
            focus: "Linux IPC",
            language: "c",
            code: """
            int fd[2];
            pipe(fd);
            write(fd[1], "hi", 2);
            char buf[8];
            read(fd[0], buf, sizeof(buf));
            """,
            prompt: "单进程下 read 可能一直阻塞，关键原因是什么？",
            options: ["写端 fd[1] 仍然打开，read 认为以后还可能有数据", "pipe 不能在同一进程使用", "read 的缓冲区太小", "write 必须先 fork"],
            correctIndex: 0,
            explanation: "read 要等 EOF 或至少一个字节。EOF 只有在所有写端都关闭后才出现。"
        ),
        CodeReadingExercise(
            id: "cr-mutex-scope",
            title: "互斥锁保护范围",
            focus: "并发",
            language: "c",
            code: """
            pthread_mutex_lock(&mutex);
            int local = counter;
            pthread_mutex_unlock(&mutex);
            local++;
            counter = local;
            """,
            prompt: "这个实现为什么仍可能丢更新？",
            options: ["读取和写回没有被同一个临界区保护", "counter 必须是 double", "mutex 只能锁一次", "local 变量不能在线程中使用"],
            correctIndex: 0,
            explanation: "两个线程可能都读到相同的旧值，再分别写回，导致其中一个更新丢失。"
        ),
        CodeReadingExercise(
            id: "cr-shell-quote",
            title: "Shell 变量和空格",
            focus: "Shell",
            language: "bash",
            code: """
            file="a b.txt"
            rm $file
            """,
            prompt: "这段脚本可能发生什么？",
            options: ["rm 可能收到两个参数 a 和 b.txt", "Shell 会自动保留整个字符串", "rm 会拒绝未加引号的变量", "file 变量不会赋值"],
            correctIndex: 0,
            explanation: "未加引号的变量会发生词分割，应写成 rm -- \"$file\"。"
        ),
        CodeReadingExercise(
            id: "cr-grep-pipeline",
            title: "grep 管道的退出状态",
            focus: "Shell 管道",
            language: "bash",
            code: """
            grep -q error app.log | tee result.txt
            """,
            prompt: "为什么 tee 通常收不到内容？",
            options: ["grep -q 不输出内容，只设置退出状态", "tee 不能读取管道", "app.log 会被删除", "grep 只能处理一个文件"],
            correctIndex: 0,
            explanation: "-q 表示静默模式，只关心是否匹配，不输出匹配行。"
        ),
        CodeReadingExercise(
            id: "cr-sql-nplusone",
            title: "N+1 查询",
            focus: "数据库",
            language: "sql",
            code: """
            SELECT id, name FROM users;
            -- 对每一行再执行：
            SELECT * FROM orders WHERE user_id = ?;
            """,
            prompt: "这种访问模式叫什么？",
            options: ["N+1 查询问题", "全表死锁", "数据库逆范式", "索引覆盖"],
            correctIndex: 0,
            explanation: "一次查列表，再对 N 行执行 N 次关联查询。应使用 JOIN 或批量查询。"
        ),
        CodeReadingExercise(
            id: "cr-tcp-short-read",
            title: "TCP 一次 read 不一定收完整消息",
            focus: "网络",
            language: "c",
            code: """
            n = read(sock, buf, sizeof(buf));
            parse_message(buf, n);
            """,
            prompt: "这个服务器的核心问题是什么？",
            options: ["TCP 是字节流，应用层必须处理半包和粘包", "read 永远按行返回", "socket 必须使用 UDP", "sizeof(buf) 会导致死锁"],
            correctIndex: 0,
            explanation: "TCP 没有消息边界，需要长度前缀、分隔符或自描述协议处理半包和粘包。"
        ),
        CodeReadingExercise(
            id: "cr-recursion-base",
            title: "递归缺少终止条件",
            focus: "算法",
            language: "c",
            code: """
            int sum(int n) {
                return n + sum(n - 1);
            }
            """,
            prompt: "程序为什么会崩溃？",
            options: ["缺少 n <= 0 的基础情况，会无限递归", "sum 不能返回值", "递归只能运行两次", "n 必须使用指针"],
            correctIndex: 0,
            explanation: "递归必须在某个条件下停止，否则调用栈持续增长。"
        )
    ]
}
