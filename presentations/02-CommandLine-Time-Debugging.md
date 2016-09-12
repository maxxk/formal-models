# Добрый день, группа 312!
<style type="text/css">
div.sourceCode {
  font-size: 1.2em;
}
section.slide > pre {
  font-size: 0.8em;
}

.reveal pre {
  width: 99%;
}
.reveal pre code {
  font-size: 1.2em;
}
.yellow-box {
  background-color: #afa;
}
.sparse-matrix img {
  height: 450px;
}
.twocolumn {
  -moz-column-count: 2;
  -webkit-column-count: 2;
}
</style>

## План занятия
- стиль написания программ
- разбор аргументов командной строки
- измерение времени выполнения функции
- отладка

Материалы к занятиям: https://maxxk.github.io/programming-semester-5/
email: [maxim.krivchikov@gmail.com](mailto:maxim.krivchikov@gmail.com)

В дисплейных классах рекомендуется просматривать в браузере Firefox.
В нём установлено расширение [NoScript](http://www.our-firefox.ru/kak-v-mozilla-firefox/noscript-dlya-firefox-nastrojjka.html), обратите внимание на инструкцию, иначе значительная часть сайтов не будет работать.


# Стиль написания

Приоритеты:

1. Корректная работа
2. Минимальная достаточная производительность
3. Понятность кода
4. Краткость кода
5. Более, чем достаточная производительность

# Стиль написания
- выделяйте функции, которые выполняют некоторое отдельное действие в предметной области (например, умножение матриц, или умножение вектора на матрицу, или разбор аргументов)
- функция не должна быть больше 200 строк, оптимально — от одного экрана до 100 строк
- если вы несколько раз повторяете в программе одни и те же 5-10 строк, их тоже имеет смысл выделить в функцию
- предельный размер одного файла — 500-1000 строк
- разделяйте тело функции на «абзацы» — группы похожих по смыслу команд, разделённые пустыми строками
- оформляйте код однородно (условные операторы, циклы, положение фигурных скобок, отступы)

# Стиль написания
Рекомендации из Mozilla Style Guide:
```c
if (...) {
  ...
} else if (...) {
} else {
}

while (...) {
}

do {
} while (...);

for (...; ...; ...) {
}
```

# Стиль написания
```c
int a = 0,
    b = 3;
int i, j, k;
double* d;

switch (...) {
  case 1: {
    // When you need to declare a variable in a switch, put the block in braces
    int var;
    break;
  }
  case 2:
    ...
    break;
  default:
    break;
}
```

# Разбор аргументов командной строки
`./myprog -n 10 -f abs_i-j -v`
Функция `getopt`:
```c
#include <unistd.h>

extern char *optarg;
extern int optind;
extern int optopt;
extern int opterr;
extern int optreset;

int
getopt(int argc, char * const argv[], const char *optstring);
```

`optstring`: строка с последовательностью букв — имён аргументов командной строки. Если после имени указано двоеточие, соответствующий аргумент командной строки имеет параметр; если нет — это просто флаг.

# Разбор аргументов командной строки
`./myprog -n 10 -f abs_i-j -v`
```c
#include <unistd.h>

struct Params {
  int size; // размер массива
  char* formula; // формула заполнения
  char verbose; // отладочный вывод
}

int main(int argc, char** argv) {
  struct Params params;
  int opt;
  while ((opt = getopt(argc, argv, "vn:f:")) != -1) {
    switch (opt) {
      ...
    }
  }
}
```

# Разбор аргументов командной строки
```c
case 'n': {
  char *next;
  params.size = strtol(optarg, &next, 10);
}
```
Подробнее про `getopt`:
1. `man 3 getopt` в консоли
2. https://www.ibm.com/developerworks/ru/library/au-unix-getopt/#toggle
3. http://www.firststeps.ru/linux/r.php?10


# Измерение времени работы функции
Не следует использовать:
- `time()` — «календарное» время; точность — 1 секунда; между двумя измерениями может измениться произвольным образом, вплоть до перехода назад (переход на зимнее время; перевод часов вручную)
- `clock()` — точность — 1 микросекунда; 32-битный счётчик, переполняется за час с небольшим.
- `gettimeofday` — «календарное» время, может идти назад

Нужно использовать:
**`clock_gettime(CLOCK_MONOTONIC)`{.c}**
— таймер с наносекундным разрешением; предназначен именно для измерения промежутков времени в программе с высокой точностью (специфичен для Linux).

# Время работы с clock_gettime
`#include <unistd.h>`{.c}
Прототип:
```c
struct timespec {
    time_t tv_sec;  // секунды
    long tv_nsec;   // наносекунды
}  // Объявлено в unistd.h
```

`int clock_gettime(clockid_t clk_id, struct timespec *tp)`{.c}

Значения `clockid_t`:

- `CLOCK_MONOTONIC` — реальное время от произвольной точки отсчёта (можно использовать только как разность);
- `CLOCK_PROCESS_CPUTIME_ID` — использование процессорного времени;
- `CLOCK_THREAD_CPUTIME_ID` — использование процессорного времени потоком

Последние два значения понядобятся в третьей задаче.

# Пример использования (C++ или GNU90 С)
Компилировать лучше с `-std=c99`, т.к. в стандартах C89 и C90 нет типа `long long`{.c}. [Источник](https://github.com/olekristensen/LongingFastForward/blob/
1201aec0f10f39fc21af4b3de9a98ecd306643dc/Experiments/lffCinderCapture/lib/libjp4/clock.h), там же есть реализация для Mac OS X.

```c
#include <time.h>

unsigned long long currentTimeNano() {
  struct timespec t;
  clock_gettime(CLOCK_MONOTONIC, &t);
  return t.tv_sec*1000000000 + t.tv_nsec;
}

unsigned long long currentTimeMillis() {
  struct timespec t;
  clock_gettime(CLOCK_MONOTONIC, &t);
  return t.tv_sec*1000 + t.tv_nsec/1000000;
}

long long time = 0;
time = currentTimeNano();
Solve(n, a, b, tmp_double, tmp_int, debug);
time = currentTimeNano() - time;
CheckAnswer(n, a, b);
```

# Пример использования (C89)
Этот пример должен собираться в дисплейных классах с параметрами компилятора по умолчанию. [Источник](https://github.com/EverlastingFire/informatica/blob/128519be92eb34b9c09859272d0187252506da5b/c/euclide/timediff.c)
```c
#include <time.h>

struct timespec diff(struct timespec start, struct timespec end)
{
    struct timespec temp;
    if ((end.tv_nsec-start.tv_nsec)<0) {
        temp.tv_sec = end.tv_sec-start.tv_sec-1;
        temp.tv_nsec = 1000000000+end.tv_nsec-start.tv_nsec;
    } else {
        temp.tv_sec = end.tv_sec-start.tv_sec;
        temp.tv_nsec = end.tv_nsec-start.tv_nsec;
    }
    return temp;
}

struct timespec time_start, time_end;
clock_gettime(CLOCK_MONOTONIC, &time_start);
Solve(n, a, b, tmp_double, tmp_int, debug);
clock_gettime(CLOCK_MONOTONIC, &time_end);
time_end = diff(time_start, time_end);
```

# Отладчик

Сценарии использования отладчика:

1. Программа падает:
    - при выполнении какой строки?
    - из какой функции была вызвана текущая?
    - какие значения переменных?

2. Программа работает не так, как надо:
    - чему равны значения переменных?
    - в какой момент вызывается тот или иной фрагмент кода (срабатывает условие, выход из цикла и т.п.)?
    - в каком месте программа уходит в бесконечный цикл?

# Вызов отладчика GDB

Для отладки программу нужно скомпилировать с отладочной информацией (ключ `-g`) без оптимизации (`g++` — аналогично):
    `gcc -g myprog.c main.c`
Запуск отладчика
  - программа без аргументов
```bash
gdb ./a.out
# Вместо ./a.out
```

# Вызов отладчика GDB
  - аргументы при запуске
```bash
gdb --args ./a.out -f 2 -n 1000
# Вместо ./a.out --formula 2 -s 1000
```
После запуска отображается командная строка gdb.

Аргументы можно изменить в командной строке gdb:
```bash
set args -f 1 -n 500
show args    # Показать текущие аргументы
```
# Команды отладчика GDB
- `run` (`r`) — запустить программу; в случае исключения выполнение останавливается на строке, на которой исключение произошло:
```
(gdb) r
Program received signal SIGFPE, Arithmetic exception.
0x08048681 in divint(int, int) (a=3, b=0) at crash.c:21
21        return a / b;
```

- `quit` (`q`) — выйти из отладчика (если выполнение программы было прервано, отладчик запросит подтверждение)
- `list` (`l`) — напечатать «окрестность» текущей строки  исходного кода
- `print <expression>` (`p <expr>`) — вывести значение выражения (можно использовать арифметические операторы, получение элемента массива, по-моему даже вызовы функций)

# Команды отладчика GDB (II)
- `where` (`backtrace`, `bt`) — показать стек вызовов функций:
```
(gdb) where
#0  0x08048681 in divint(int, int) (a=3, b=0) at crash.c:21
#1  0x08048654 in main () at crash.c:13
```
- `frame <n>` (`up`) — перейти на указанный уровень в стеке вызовов (чтобы посмотреть значения переменных в вызывающей функции)

- при нажатии Ctrl+C выполнение программы приостанавливается

# Команды отладчика GDB (III)
- `break <location>` (`b <loc>`) — установить точку останова в указанной локации:
    * *function* — на входе в функцию *function* в текущем файле
    * *filename:line* — на строке *line* в файле *filename*
    * *filename:function* — на входе в функцию *function* в файле *filename*
- `delete` — удалить все точки останова
- `clear <location>` — удалить точку останова в указанной локации
- `next` (`n`) — выполнить до следующей строки программы
- `step` (`s`) — выполнить одну строку, «проваливаясь» в вызываемые функции
- `continue` (`c`) — продолжить выполнение программы (до следующей точки останова или исключения)


# Valgrind

[Valgrind](http://valgrind.org) — средство динамического (= во время выполнения) анализа программ.

Позволяет анализировать, в частности, следующие показатели:
- **ошибки доступа к памяти** (доступ по неинициализированному указателю, выход за границы массива, использование неинициализированных переменных, копирование «внахлёст», утечки памяти)
- частота не-попаданий в кэш (L1, L2)
- источники взаимных блокировок в многопоточной программе

# Запуск Valgrind

```bash
# Вместо ./a.out --fun 1 --size 2
valgrind ./a.out --fun 1 --size 2
```
```
==19182== Invalid write of size 4
==19182==    at 0x804838F: f (example.c:6)
==19182==    by 0x80483AB: main (example.c:11)
==19182==  Address 0x1BA45050 is 0 bytes after a block of size 40 alloc'd
==19182==    at 0x1B8FF5CD: malloc (vg_replace_malloc.c:130)
==19182==    by 0x8048385: f (example.c:5)
==19182==    by 0x80483AB: main (example.c:11)
# ...
==19182== 40 bytes in 1 blocks are definitely lost in loss record 1 of 1
==19182==    at 0x1B8FF5CD: malloc (vg_replace_malloc.c:130)
==19182==    by 0x8048385: f (a.c:5)
==19182==    by 0x80483AB: main (a.c:11)
```



# Задания
1. Дописать разбор параметров командной строки:
  - `-n` (размер матрицы, число)
  - `-f` (имя формулы, строка);
  - `-i` (имя входного файла, строка);
  - `-o` (имя выходного файла, строка);
  - `-v` (отладочный вывод, флаг).
Программа должна:
- обрабатывать аргументы командной строки;
- сохранять их в структуру;
- проверять их корректность (имя формулы — одна из заданных строк; если задано имя формулы, размер матрицы должен быть задан и должен быть больше 0, кроме того не должен быть задан входной файл; если задан входной файл, он должен существовать; если не заданы входной и выходной файлы, то по умолчанию это — `stdin` и `stdout`, соответственно)

# Задания
- если аргументы некорректны, то нужно выводить в терминал краткую справку с описанием доступных аргументов;
- если аргументы корректны и задан флаг отладочного вывода, выводить обработанные аргументы в следующем виде:
```
Formula: ... (или "no")
Matrix size: ...(или "from file")
Input file: ... (или "stdin")
Output file: ... (или "stdout")
Verbose mode: ...
```
2. Добавить измерение времени, затраченного на разбор аргументов командной строки. Время должно выводиться в конце программы.
