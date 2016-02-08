---
layout: default
---
# Программирование с использованием MPI — начальный уровень
В настоящем документе содержася базовые сведения по использованию стандарта MPI в программах на языке C в объёме, достаточном для решения первой задачи Практикума на ЭВМ в шестом семестре. Для написания программ, предназначенных для использования в реальных программах рекомендуется изучить документацию и использовать развёрнутые учебные пособия — в особенности, с упором на асинхронную передачу сообщений (`MPI_Isend, MPI_Irecv`) и передачу сложных типов данных.

С вопросами, исправлениями и дополнениями по документу обращайтесь по адресу maxim.krivchikov@gmail.com

## Компиляция и запуск

Стандарт MPI предназначен для написания параллельных программ, выполняющихся в виде набора независимых процессов, которые могут обмениваться сообщениями. Существует несколько реализаций MPI, наиболее популярные — OpenMPI, MPICH, Intel MPI (последний работает, в частности, на ускорителях Xeon Phi).

Для работы с MPI во все файлы с исходным кодом, в которых используются функции или типы данных MPI, должен быть включён заголовочный файл `mpi.h`:
```c
#include <mpi.h>
```

Для компиляции используются обёртки над `gcc` и `g++` — `mpicc` и `mpicxx` соответственно. Вместо `ld` можно также использовать `mpicc`. Запуск осуществляется с использованием команды `mpirun`:
```bash
mpirun -np количество_процессов имя_программы аргументы_программы
```
например:
```bash
mpirun -np 4 ./a.out --formula 2 -n 2000
```
Аргументы `--formula 2` и `-n 2000` передаются в вашу программу (`./a.out`), аргумент `-np 4` не передаётся.

Под «всеми процессами» далее подразумеваются процессы, запущенные с помощью выполнения одной команды `mpirun`.

Команда `mpirun` запускает заданное количество абсолютно идентичных процессов, выполняющих заданную программу. Эти процессы различаются только по порядковому номеру, который можно получить с помощью функции `MPI_Comm_rank`. Каждый процесс начинает выполнение с функции `main`. Таким образом, если запустить с использованием `mpirun` на 6 процессов программу:
```c
#include <stdio.h>

int main(int argc, char **argv) {
  printf("A");
  return 0;
}
```
, то на экран будут выведены 6 букв `A`.

## Общая информация по API

Все функции MPI имеют название с префиксом `MPI`. Все функции MPI возвращают целое число типа `int` — код результата выполнения функции. В случае успешного завершения возвращаемое значение равняется константе `MPI_SUCCESS`. Полный список ошибок см. в [стандарте](http://www.mpi-forum.org/docs/mpi-2.2/mpi22-report/node192.htm).

В случае ошибки, аварийное завершение всех процессов выполняется с использованием функции `MPI_Abort`:

```c
int MPI_Abort(MPI_Comm comm, int errorcode);
```

где `comm` — коммуникатор (см. далее), `errorcode` — код, возвращаемый в командную оболочку (аналогично `return` в `main`). Функцию `MPI_Abort` достаточно вызвать в одном (любом) из процессов. Стандартом гарантируется, что функция `MPI_Abort` завершает как минимум все процессы, входящие в коммуникатор `comm`, но на практике во всех существующих реализациях

Коммуникатор (элемент типа `MPI_Comm`) — это обозначение какой-то выделенной группы процессов. Стандарт определяет коммуникатор `MPI_COMM_WORLD`, который обозначает все запущенные процессы текущей программы. Использование других коммуникаторов в рамках практикума не предполагается, поэтому можно считать, что в качестве аргумента типа `MPI_Comm` всегда подставляется `MPI_COMM_WORLD`.

## Инициализация и завершение

В начале программы, работающей с MPI, необходимо инициализировать библиотеку MPI с помощью функции `MPI_Init`; перед завершением — вызвать функцию завершения `MPI_Finalize`.

```c
int MPI_Init(int *argc, char*** argv);
int MPI_Finalize();
```

Аргументы `argc` и `argv` функции `MPI_Init` должны быть указателями на соответствующие аргументы функции `main`, см. пример далее. Функция `MPI_Finalize` не содержит аргументов.

Количество запущенных процессов не должно передаваться в программу в качестве отдельного аргумента командной строки, но определяется с использованием функций `MPI_Comm_size`. Номер, который автоматически присваивается процессу, может быть получен с помощью функции `MPI_Comm_rank`. Пример: при запуске `p` процессов, в каждом из результат выполнения `MPI_Comm_size` равен `p`, а результат выполнения `MPI_Comm_rank` — числам от `0` до `p-1`. Нулевой процесс обычно для простоты считают «главным» и выполняют из него весь ввод-вывод (при разработке допускается использовать отладочный `printf`-вывод во всех процессах).

```c
int MPI_Comm_rank(MPI_Comm comm, int *rank);
int MPI_Comm_size(MPI_Comm comm, int *total_procs);
```
<!--* -->

Далее под «номером процесса» будем понимать число, которое возвращает в переменной `rank` вызов функции `MPI_Comm_rank`.

## Пример минимальной программы

Программа в каждом процессе получает и выводит общее количество и номер текущего процесса.

```c
#include <stdio.h>
#include <mpi.h>

int main(int argc, char **argv) {
  int rank, size;

  MPI_Init(&argc, &argv);
  MPI_Comm_rank(MPI_COMM_WORLD, &rank);
  MPI_Comm_size(MPI_COMM_WORLD, &size);
  printf("Process #%d of %d\n", rank, size);
  MPI_Finalize();
  return 0;
}
```
<!--** -->

По-хорошему, нужно ещё проверять значения, возвращаемые каждой функцией.

## Типы данных

Для передачи данных между процессами, которые в общем случае могут выполняться на вычислительных устройствах различной архитектуры, библиотеке MPI необходима информация о типах данных, которые должны быть переданы. Язык C не поддерживает средства т.н. рефлексии или параметрического полиморфизма, которые могли бы упростить получение такой информации, поэтому при каждой пересылке тип должен быть указан явно в качестве одного из аргументов функции. Для передачи такой информации используется тип `MPI_Datatype`. Функции, выполняющие приём или передачу данных, как правило, принимают аргументы: `void *buf, int count, MPI_Datatype datatype`. Семантику этих аргументов можно неформально сформулировать следующим образом: «передаётся (принимается) область памяти, на начало которой указывает `buf` и которая содержит массив из `count` элементов типа `datatype`».

Следует отметить, что в качестве аргумента типа `void *` может быть использован любой указатель, при этом приведение типов будет неявным, т.е. писать явно `(void*)myArray` не нужно.

В следующей таблице приведены определённые в заголовочном файле `mpi.h` константы типа `MPI_Datatype`, соответствующие используемым в рамках практикума примитивным типам языка C.

Тип C       | Константа `MPI_Datatype`
------------|-------------------
`char`        | `MPI_CHAR`
`int`          | `MPI_INT`
`unsigned int` | `MPI_UNSIGNED`
`double`  | `MPI_DOUBLE`

Для полного списка см., например, http://linux.die.net/man/3/mpi_double, или `man mpi_double`.

Кроме того, MPI предоставляет возможность определения своих типов данных для передачи сложных структур. В рамках практикума это, скорее всего, не понадобится, но при необходимости можно начать смотреть, например, с презентации https://www.rc.colorado.edu/sites/default/files/Datatypes.pdf

## Передача данных «точка-точка»

В рамках стандарта MPI определяется два вида передачи данных «точка-точка» — блокирующий и неблокирующий. Блокирующие операции не возвращают управление в программу до конца передачи, неблокирующие возвращают управление сразу после вызова. Поэтому в случае с блокирующими операциями буферы приёма/передачи могут быть повторно использованы, а в случае с неблокирующими — только после завершения передачи. Для выполнения практикума используются блокирующие операции.

```c
int MPI_Send(const void *buf, int count, MPI_Datatype datatype,
              int dest, int tag, MPI_Comm comm);
int MPI_Recv(void *buf, int count, MPI_Datatype datatype, int source, int tag,
              MPI_Comm comm, MPI_Status *status);
int MPI_Sendrecv(const void *sendbuf, int sendcount, MPI_Datatype sendtype,
              int dest, int sendtag,
              void *recvbuf, int recvcount, MPI_Datatype recvtype,
              int source, int recvtag,
              MPI_Comm comm, MPI_Status *status);
int MPI_Sendrecv_replace(void *buf, int count, MPI_Datatype datatype,
              int dest, int sendtag, int source, int recvtag,
              MPI_Comm comm, MPI_Status *status);
```
<!--* -->

Функция `MPI_Send` выполняет передачу буфера `buf`, содержащего массив элементов типа `datatype` размером `count` в процесс с номером `dest`.

Функция `MPI_Recv` выполняет приём сообщения, содержащего массив элементов типа `datatype` размером `count` и записывает результат в буфер `buf`.

Функция `MPI_Sendrecv` выполняет одновременно приём и передачу сообщения в рамках одного коммуникатора и содержит наборы аргументов, соответствующие объединению наборов `MPI_Send` и `MPI_Recv`.

Функция `MPI_Sendrecv_replace` выполняет одновременный приём и передачу сообщений, содержащих одинаковое количество `count` одного типа `datatype`. Приём осуществляется в тот же буфер `buf`, из которого выполнялась передача.

Все рассматриваемые функции позволяют отправлять сообщения с метками — целыми числами `tag`. Например, функция `MPI_Recv` примет только сообщения от процесса `source`, для которых метка равняется `tag`. Если метки не используются, обычно ставится или одно и то же число (0), или, в случае `Recv` — константа `MPI_ANY_TAG`.

Функции приёма позволяют получить дополнительную информацию с помощью аргумента `status`. Обычно в функции, использующей MPI, определяется одна переменная типа `MPI_Status`, указатель на которую передаётся далее во всех вызовах.

## Пример программы, выполняющей передачу данных «точка-точка»

Сначала один из массивов пересылается от первого процесса второму, затем — в цикле "каждый следующему" и обратно "каждый предыдущему".

```c
#include <stdio.h>
#include <mpi.h>

#define PRINT_BUF print_buf(rank, size, buf1, buf2)

void print_buf(int rank, int size, double *buf1, double *buf2) {
  printf("[%d/%d]\tbuf1\t%lf\t%lf\tbuf2\t%lf\t%lf\n", rank, size,
    buf1[0], buf1[1], buf2[0], buf2[1]);
}

int main(int argc, char **argv) {
  int rank, size, dest;
  double *buf1, *buf2;
  MPI_Status status;

  MPI_Init(&argc, &argv);
  MPI_Comm_rank(MPI_COMM_WORLD, &rank);
  MPI_Comm_size(MPI_COMM_WORLD, &size);
  printf("Process #%d of %d\n", rank, size);

  if (size < 2) {
    printf("Too few processes\n");
    MPI_Abort(MPI_Comm_world, 1);
  }

  buf1 = calloc(2, sizeof(double));
  buf2 = calloc(2, sizeof(double));

  buf1[0] = (double)rank;
  buf1[1] = -2.;
  buf2[0] = -1.;
  buf2[0] = -3.;

  PRINT_BUF;

  if (rank == 0) {
    MPI_Send(buf1, /* count */ 1, /* datatype */ MPI_DOUBLE,
        /* dest - process N. 1 */ 1, /* tag */ 0, MPI_COMM_WORLD);

  } else if (rank == 1) {
    MPI_Recv(buf2, 1, MPI_DOUBLE, /* source - process N. 0 */ 0, MPI_ANY_TAG,
        MPI_COMM_WORLD, &status);
  }
  if (rank < 2) {
    PRINT_BUF;
  }

  // Send in cycle: 1 -> 2 -> 3 -> ... -> (p-1) -> 1
  // (size + rank - 1) % size - to be non-negative
  MPI_Sendrecv(buf1, 2, MPI_DOUBLE, (rank + 1) % size, 0,
    buf2, 2, MPI_DOUBLE, (size + rank - 1)%size, 0,
    MPI_COMM_WORLD, &status);

  PRINT_BUF;

  MPI_Sendrecv_replace(buf2, 2, MPI_DOUBLE,
    (size + rank - 1)%size, 0,
    (rank + 1) % size, 0,
    MPI_COMM_WORLD, &status);

  PRINT_BUF;

  MPI_Finalize();
  return 0;
}

```

<!--* -->

.


## Групповые операции

В рамках используемого стандарта MPI версии 2 определяются только блокирующие групповые операции. Стандарт MPI версии 3 вводит неблокирующие групповые операции, но, поскольку принят он был совсем недавно (в 2012 году), такие функции могут быть доступны не везде. Как и в случае с операциями «точка-точка», в рамках практикума рассматриваются только блокирующие операции.

Картинки-иллюстрации взяты с сайта http://mpitutorial.com/tutorials/mpi-scatter-gather-and-allgather/

```c
int MPI_Bcast( void *buffer, int count, MPI_Datatype datatype, int root, MPI_Comm comm );
```

<!--* -->

`MPI_Bcast` — переслать данные из процесса `root` всем процессам в коммуникаторе `comm`. Функцию необходимо вызывать во всех процессах коммуникатора.

<p><img src="data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAR8AAAFUCAMAAAAqFsjQAAABYlBMVEX////8/Pz09PRYWFj/AAAA
AAD+/v7///////9VVVUA//8AAP8A/wCpyXTDw8Tz9+vQ0NDe3t7l5eVlZmZiYmLZ2dnq6urv7++C
g4TV5bzO4bC10Yejo6P8/frI3ab39/dra2vi7tChxGevr6+RkZGnp6i9vb19fn+Zmpqav1y91ZSW
lpakx233+vF3d3fu9OO2trZ7e3tfX19wcG+jxWrIyMjC2Z1cXFydnZ7q8t6tzHvs7OywzoDh4eHd
6smysrK0Xl5zdHTn8Nj5+/W5046GtLTb3NyMjIyzaWmHh4ja6MPmEBC6uroaGtnLy8s+REurq6vT
1dQxOUEkJCQQEBD6/PeLkJRYXmWzcnKzUVEbGxs6OjrMvb0U4BSGhrOJs4owMDC7n58g09NPT0+5
Skr4BQXSJCSVZ2JES1KvhITQxcVobnPEOztbZJ0h0SFcsrJas1pbk2VUVLQS4uJNVFovL73lV5M7
AAAACHRSTlOm////////FI4wgckAABV7SURBVHja7J3fV+JYEscnYcipPBAxYkBAlAYQEVVRbRHV
VT1263pEO0F7yTwwh92zPdP7OP//2eLnJd7QF4wDneR+HxIToIQPdavq3uRQvwDXD/QL58P5cD6c
D+fD+XA+nA/nw8X5vBefZhK6SjZxE2zLMJP4FxD1zjfMHIxWzJt8gma1s9f0IHSpSNG8fvSaDwCs
qArCHG3Io3w2brtf/26fD2qnacMH9aT7j09UF3An6KdDfDRjBJ8mQM5slFUASJpGI6ABZHDgtW4g
iPIkH4hkcPfYgiE+WdOGj6DlzXM4aBxpsRZAoXkfVT7iH8EMqLemd/0HFBN3Zn7AR9IyjZ3XfLra
E6H1qRfX810/g2De2+MLoPkEYR3/6nPQWwdg4z+S+lCLga5AV6Jyf6Hj+dXWjrLiaT7ZBYhke3yo
cGs5UptgRKGjcEOPJG/wvCg3gsaTl/lUDdWIjsVHNMA8gI7MI9y0+bR3Wd3LfCBgLsBYfPI1iGWh
o4aKm0LvvIT7oORZPvlgeAw+krijK3CgP1ZvZYC98s1poZ3SWzEVMrhvPCx6lQ+UgcWnrUYt3/YZ
vVHWALQt3ajl8VmnH/Ug5njYaBh8fsrn75zP+Ar2xflw/+HifDgfzofz4Xw4H87n/SWIoihwPraS
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
jgIAAAAASUVORK5CYII="></p>

```c
int MPI_Scatter(const void *sendbuf, int sendcount, MPI_Datatype sendtype,
               void *recvbuf, int recvcount, MPI_Datatype recvtype, int root,
               MPI_Comm comm);
```

<!--* -->

`MPI_Scatter` — разбить данные из `sendbuf` на последовательные части размером `send_count` и разослать соответствующие части про процессам. Аргументы `send...` могут иметь любое значение при вызове в процессах-получателях (всех процессах, кроме `root`). Буфер `sendbuf` должен иметь размер `sendcount * <MPI_Comm_size(comm)>`. На практике лучше передавать `sendtype = recvtype`, `sendcount = recvcount`.

```c
int MPI_Gather(void *send_data, int send_count, MPI_Datatype send_datatype,
    void *recv_data, int recv_count, MPI_Datatype recv_datatype,
    int root, MPI_Comm communicator);
```

<!--* -->
<p><img src="data:image/png;base64,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"></p>

`MPI_Gather` — обратная к `MPI_Scatter` операция — собрать в процессе `root` массив из частей, распределённых по процессам. Для процессов кроме `root` аргументы `recv_data`, `recv_count`, `recv_datatype` могут иметь любое значение. Как и в случае `MPI_Scatter`, безопасными значениями аргументов в `root` являются `send_datatype = recv_datatype` и `send_count = recv_count`.

```c
int MPI_Allgather(const void *sendbuf, int sendcount, MPI_Datatype sendtype,
                  void *recvbuf, int recvcount, MPI_Datatype recvtype,
                  MPI_Comm comm);
```

<!--* -->

<p><img src="data:image/png;base64,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
nAAAAABJRU5ErkJggg=="></p>

Аналогично `MPI_Gather`, но массив рассылается по всем процессам коммуникатора `comm`. При этом, в отличие от `MPI_Gather`, аргументы `recv...` должны иметь корректные значения во всех процессах коммуникатора.

```c
int MPI_Reduce(void* sendbuf, void* recvbuf, int count, MPI_Datatype datatype,
               MPI_Op op, int root, MPI_Comm comm);
```

<p><img src="data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAfkAAADeCAMAAAAJtonsAAAAw1BMVEX///9YWFqYyJhtbnH/////
//8LoUv///////////8AAADtHCRjsm7K4cfw8PGanJ8mJie0trjyZUjR0tT7yLSAgYSTlZiNj5Kn
qaxHR0l0dXjf4OFiY2VmZ2khISImpVKfoaSkzaO7vb/z8/THyMrExcfV1tjo6umHiYzh4uP19fV8
fX9UVVd3eHusrrH2lnn+6d/wUDmFvonuMSvNztButnb1hGf2rJL81cSx0bBBqVn6u6QXo09cgmFE
k1TEUDkpKiq6BmwXAAAACnRSTlPA////IP//QIBg40vmzAAAETlJREFUeNrsnQ132jgWhkfjVXeP
0pWlurYlf1AWMJBA0rTNtLPb7e7//1eDbNo7GIGcVEpguO85bU6wzCv58b2SbNn55W9/R12kfvkH
RV2kkDySRyF5FJJHIXkUkkcheRSSRyF5FJJHIXkUkkcheRSSR50EeclYQ1uVjOWUFqyVVpRSIigo
Zp3qhO5LEIo6P/IpbRVvyRuyvGZqj3xMzRYiSrojJH+u5PWWr9ZAnnKh7eRpsym1IyR/ruRzprZE
gXxL3U4+YQXdEZI/V/JS13SjVCSDyMv2Z6wZq03aT2rGiBTkO/3C7KMIYzqmUA51kuRjZtCIIhmS
7ROtuTlNFC2J5rRhNadS75KPWd79B+VQp0i+NEwVk4ljhLcVNz1DbAqJlBLdfcmfyXPRJpFaUCiH
OkXytNbU/EuOzOog5g3gnJUtW12yDupOzEtT0gjKUdRJklesKTfUIeY72fv5lDWbQluZXYzIn8nH
TNJWUA7T/WmSpyKNWTKQvGKK5t9R8r2YJ6It0Z4iZY7IT5x8KgihTvIwtpddVGtCieDf+3ltyHNh
+vmi2/qjHM75TpV8w1g8lHxjftZCtXm/G9snuuv8JeW16Mb23VYohzpN8lQLPpR8yYj5TTBWy+18
XitBul5dqEJsZ/FEUiiHwnt1qDMhT9hWGLcY8ygkj0LyKCSPQvIoJI9C8igkj0LyKCSPQvIoJI9C
8igkj0LyKCSPQvIoJI9C8qgnk583cqNmfkOfQ8lEbTRJpuj2ouQXk2X0Q0tV0qBayFvyQ7djdHsx
8vM86imfB4yIlPSUJuj2EuQXW+5pLjfK0y37MlBMbI9NlKqN0mh7fNDt+clPijbDNwu61U3TnQqS
BpCs2iw4+eE2nXSHS6HbM5Mf25L7ov009j/Wy2wJcNF+upyi2zOSvzHhXcwtXX9qEoFn9FMTAlVi
6R4jEyxTdPNJ3h3xuZXvzdigh9///esh/fb648Fti72oSKfW42Y23aKbw80febWhOz52VsDG16+e
on/ufCEhJDuWKzN0c7j5Ij8HtofQN1DfQ+fjf1/9dmDLf3bqm0D7Dx2eCbo53PyQv0kdXXkeRcX3
7a8Per979S/ak22faeTo7lJCqim62d38kpcbsIujp0ZhcoKn+ipCqqNu04qQDN0Ckgeuzjl7E0XR
wk99p5VzXjshhKDbM5CfRFHqmralUaT81FcSErmmNhEhY3QLTz5tQ94Z9MXj6luyxFrfqA0LZ2BU
/T15yhhLuc2tLGCTBzdX22LNWFH6dlNMWtyg2QHIl1EU7YZ8a9YrVUTRvOfdsFbSTj63ky8JIf2w
UIL2VBGS9PbUQsJrdXfdtE5ooskQt6RmTMROt5h1Eha3mMWUm4q43eQwNyOubeSh2V7JQ7LPdz6o
N2ZS1HszO9nzjsWRmE+ZnbwkJKU9EWGZ/ajdPRWLu9e07bspplogjdstYaSEttndQIkoLG0TNVTE
5VZzqlg6xK0mNvLQ7BDk416yl61NzGQ/3ec975QcJF8wdoD8ci8hljUTlpSYwp6QQjizsIhZ0lXb
7ZayBE4SuxuIa2JpW8Ly7v8hbmUbSNTtpkRjIw/NDkE+N3l8r74lS/t9QtHzJumxfj62k0+7XAcS
kFRBJSGVraUNS/tu4CfdbkTAue10q0VJrTHffYXbrRYA77hbKeLERh6aHYI8TNigvl0D+8V63qIW
jNXJ48jDpAZUAHkKxWwtrZmyu5kU7nSDqimHGyRaaz9v6A12qwV3utWEWslDswORt/W6gjjIN6wu
aUJY81jy9Knkec16+RfMmFBONxhMlQPctD6QzwjbaIAbnCgut5gldvLQ7FMhDypZ/VzklWD1/qwO
Dk88zC3RLHW6AbG+G9daDncrGCOJy60UObWSh2afHHkoHp58zVhuYwExOsgtZwa8mzwRfN8Nugot
BsZ8QljicKs1tZOHZocif/OUfl7FTyQ/fRL52kzIrCyIhoq43ErChHK7QS6zj7ZNMHOHG8ztUocb
YVvxnhs0Owj55RPG9jBD4qJ4FPlbQhILeefYXgIJcIMKb6SJ241r8zUONxjfHYt57XTjLO1+1E63
QzEPzQ40n588ZT6fmB6srEU5jDzMeaWFvHM+X7DkEPnEDDXLmjVutxwy5wE3KNnY3SjR0lRHud20
hgsANjc3eWh2oGt4ca/nTmhiuYanet6yZoylJX0UeUnI0k0+I2S8u6dmnfJdN6hInTjcgIXbzWTZ
8gB5nhs3OcAtZoX5UHOL2zDy0OwXvW7/4OEOk/W6fWG7bj8L4FayrWRQN0BP4HaLB7cQ9+oar/fq
QPb7WRMPd888us1O1C08eRlF6YBLvJ7uKitCIue5SEiGbuHJLyJn0D/4W5OzMIsQnWFB0C0oeRi9
FTeOJZr+1uFlsAixL1jGmKFbWPKwEC93nRoLb+tTKzOtsQoOH7qFJg8LLMdH532R9LdKfHJ8Tbok
hCh0C7/eHh6jOXZe5D6fDMnshweOXWp3e0fePaPb/76FbRv/BgbD5Zv8zfIwegWPVLqeBvv27eOQ
p8Gmt4cPzxgeO9x3I1Xv2bOQbmT5a0i3uSYfX/i5OkC/LG2vUwDwbmWj6JoeFRyeW5tbevR5U762
HNNAbrMRpzScWzYav/yztPAYdTRe9D6VEYAfIr5kSz7wUWOS9dymilhRgOajCe0rkFsFJ5l/t/l6
PT+dd2aoqGX/AJ88jIv2IwA/QNfRoLN5TIyyGYUgy6r2I0Bh0WRkOWL+3SDkg7hlLDup9+TM06hV
ruRkImVeREbpw2NdZ2s9IDKTiLRKx0pKpdKKGEUzV3+ythDx7wYh79/tGgL+hcmDmjTqKZ08xfdO
V7MhNwlJT5EcspCEWuTbbQ4h79ttPMpO7q1okOA7FZD6HymejVauoR4kwU6VSY9u8fWS2uTXbQV0
/LpdV3p2qu/ALB+kHI+lbMqfseYrlvEhbjOlskypidMNwvGOWuXR7boX8t7cxqMl/8u/9/a6CjRx
mY2Cd5OrFQ0hHunZRbzxeLYO09Cx5oFPWnZNA2hiAv4CyBvdjap5iJCszjDkeWQuRlwEeRjqeROM
8s4u5CejiF/W++2vV6OMe//S0d15hTxfmYC/DPKgeeWf04zNw+Wp0bX36uqI00siDw3XM+8jiGCH
MvMd8nwJs5zLIQ9DPc+BtFqfS8jPNLT98shTnrGV3yhdrwKFfOX5+yDgL4J8+KEeH92FCXmvHdN8
vb7Gv101q7RPWHM2P+GQh/ux+FfLNpro9czn4OH6hEMeFmAgeaOxz6Heas29189jyMP9WCTfDfWW
/HRHeXrm746VnsNvSL5dr+UtFrgee559egh5+/1YJO93qDf3OxKnvurF9xdgIHlYr3V6o7w7HfJ+
LJKHpfketFzzUwt5Hh3MREgelub/tKqVx5APfj8WycPS/J8V15m/kA+/AAPJu5bm33/5/Gag/u8s
Ef6L3n+5H3w/FskfGep9+XB1dnrzlvLlsJsJSP7Aeq3fDfc379+ej76+f2OqvB56gRLJW5fmf/10
9en9PT0z3X++uvr0Ow2l8yfvXpr/9erqw1lxh1QVDv35k3cvzb//dPWZnqfuPwQ7Z8+fvHtp/pur
D/Ts5OesvUTyMNR7e/Xpnp6pTO2vPNT+ksjDeq0/2jsD3jZxMAwfZ32Vzt0wNPUIELRcb5BeOrWt
WrU7VZru//+qw5DlW4DEqaPpMH0faZ1SMynr09cxYL7v4vyOPOZiBKFn8/5QLVL30ASy4JLNIc1k
SxZ2u1W1xbED1ZYg54YFodwelsqAnHh1+KyCecOL+08ukDKnhqg1n7VtYIKueWVehZnM+ubTbfvN
gNx4PH/78h7ma+7cJ/sg3fidy5TN107nP5vnNhyBzLvmU1mSQUdR4DzdX9KbgfnTzAdFG9kizdi8
sW7+9Pv+xcmsaz6J2qFIO5t/dvkPwPyJ5udNZHOpDpqfSX7VNa+jdtIonc3fwfz/YJ4i3fZRyfbM
9tw1N0jmQ+ZLOW/biMG8X+abyKYBZQdXeKQCaVB985QWZtJIYN4z8yaypVSU7TmrY+ZJatT3zCuZ
m0kD5j0zbyKro5Az39I338ou6oP0rvlcqqbz3Qlr+1d6KzDfnM9fnGDeRDbK6LB5XUs2hDLgVpSF
DBvzVKSlVCeYf8D5vBv3J1zDC8iYlLHF/FwmvK4P2k6LoTHdmJ/LIgrdzX87f6S3A/NNZl7czZvs
pmQxT4HUYdNfIqz1R0Fcfw2ifGOeIpmRu/lnXLd3n+4f793Nm0AfNM9r+7T9Vp7ImiSnH+a1jF3N
m8i7XcKDeRN6To2Pb/6CRoCf5i/Pf4n6WG4IyB37XP+IPTnuvLB6v7i/OGGuh/lW/cOlh2+73jL8
Qs7AfLPtunZ/d3lP3vDt9fmhfs/fyB2YN9zf1e594/GOTgLmt4/VeWT/4eL5lU4G5h2q5rt1vLlN
PXk+FuYHq+a79zVc3PryQDzBfP8pTPe+hl/Soyo8jCTwMM+lVO1hrdwjz/WKxxJ4mLdXzbf3NeQ+
lPYC5eMB5o+umi8WRCf0oay4QPlYgHmumm/reOMe+U9jDDzMc9V8h443HHlLveIxAvO81HPoa8it
Zy0FykcIzB9VSnWZhg6tZ/8eeeBh/oiq+TcLS+tZS4HycQLz9qr54deb45vSccPo8QPzXDXfssqz
96HkAuU+APO2qvmVrI6PfCj8CTzM81LP0tfQHvkrvwIP85aq+TdfLZH39n4swfzhqvm8yuM+lJ7f
j2VgnqvmW/oafrqxNIz2DJg/UDW/kl8skecC5f7xjs3nVbU6XDX/lnV/Wkzjfux7N5/HSSYatLpa
8VJvuK8h96HsN4z2iXdvfh1rscN1uXe/1uKGI+/1/ViYr71noiVLErFBP3HV/G5fQ458r2G0N8A8
UdXmXZX55vXVtTAka66a3+9ruFx4fT8W5omumoRf1ZqZ1VLUZDlvze+t8vh7Xm7AgHlqHMdr6rBS
oqbkrfmdvoa3C6/vx8J8I/46pwHKjNWbpd4/H5lFkSp+9efvYsGju/xFYwTmKTbi1zRInpkJn/dr
fT/b8jn99+w4PtIYgfmKxe9Rr7ej388+7OFs78hnmB8na83ih8iFEEvacHZGHewjH2B+bPBcn9vW
/RXMT451JkRMB0mESGB+OnDk9RELgRzmp0bWnLVZQ7+E+YnxJES2PuagXb+p2nauKmIe4SFDHiUw
P1rmmzgzWkqp+xNDtfXLJVBL2RTDLrcjPGQoJMyPl6Q72RdRTHFU0A5KiJ+TrSKp2mOpJip4pB1q
USkyP2KEECvawJFVMu6e2KmteSVrVOM84K9mhIeauT6G+fGyrs135vrcWJO6u7pPiDjZM8686VnH
I+1QQ5ARzI8QVnpNTCPTEBXd63h6wHwpC/Mv8iHzKgphfqxwmJlgYz7ofSgMmCctazQNmC+lIpgf
KaebL8xfiSwGzAcBwfwoYfPabp4/FNg89ybVsuyZV3IG8yOGw9z/nLet8PjUXcm4Zz6RG2KYHymZ
ELl9bR8Lseybn/3I/GxobY/Mj5tEiCv7+bwyR3XNG+fKHKsJ5j2C06w6H/QzmkVF76w/HzBPKm0a
V8G8h+TmIp7tun0phMa9uqmhhYiPOGYO81OjtN+mLc28APPTgXdjLa1bNJfYjTUlONFPtucwVjA/
QRIhsvzwb0aMXddTZMXPUuwRf81+d8EzNn7zJDj1Q+KzNcxPD9ZbUp/1kn8pJgfMb9SLZEUdnjTE
T9w8VZmoWVZETJkIftZyisC8Ya2EQS/Lqla9qq5UJgwxvXfY/FSptOixXNG7h81Pl0rtaM/m8M7m
J876KU6ujfRExTmBjXkA8wDmAcwDmAcwD2AewDyAeQDzAOYBzAOYBzAPYB7APIB58GvM//EbeJf8
B7Bo7yLteMS3AAAAAElFTkSuQmCC"></p>

Выполняет операцию `op` над данными из `sendbuf` — операция применяется к элементам с одинаковым индексам в каждом из процессов. Массив результатов применения операции размера `count` сохраняется в буфере `recvbuf` в процессе `root`. В других процессах допустимо любое значение `recvbuf`.

Список основных операций:

Операция   |   Значение
-----------|---------------
`MPI_MAX`  |   Максимум
`MPI_MIN`  |   Минимум
`MPI_SUM`  |    Сумма
`MPI_PROD` |   Произведение
`MPI_LAND` |   Логическое «и»

Полный список предопределённых операций: https://www.open-mpi.org/doc/v1.8/man3/MPI_Reduce.3.php
MPI опускает определение пользовательских операций для Reduce, см. документацию по [`MPI_Op_create`](https://www.open-mpi.org/doc/v1.8/man3/MPI_Op_create.3.php) и [`MPI_Op_free`](https://www.open-mpi.org/doc/v1.8/man3/MPI_Op_free.3.php)

<p><img src="data:image/png;base64,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
Z32AXY04FwAAAABJRU5ErkJggg=="></p>
