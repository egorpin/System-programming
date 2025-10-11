#include <stdio.h>
#include <math.h>

int main() {
    int n;
    int sum = 0;

    scanf("%d", &n);

    for (int k = 1; k <= n; k++) {
        int sign = (k % 2 == 0) ? 1 : -1;

        sum += sign * k * (k + 1) * (3 * k + 1) * (3 * k + 2);
    }

    printf("%d\n", sum);

    return 0;
}
