#include <stdio.h>
#include <math.h>

int main() {
    int n;

    int result = 0;

    scanf("%d", &n);

    while (n > 0){
        result *= 10;
        result += n % 10;
        n /= 10;
    }

    printf("%d\n", result);

    return 0;
}
