#include <stdio.h>
#include <stdlib.h>

//(((b/c)*b)+b)
int main(int argc, char *argv[]) {
    int a = atoi(argv[1]);
    int b = atoi(argv[2]);
    int c = atoi(argv[3]);

    int res = ((b / c) * b) + b;

    printf("%d\n", res);
    return 0;
}
