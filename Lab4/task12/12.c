#include <stdio.h>
#include <math.h>

int main() {
    int n;

    int result = 0;

    scanf("%d", &n);

    int prev = n % 10;

    while (n > 0){
        n /= 10;

        if (n % 10 > prev){
            printf("Цифры не в неубывающем порядке\n");
            return 0;
        }
        prev = n % 10;
    }

    printf("Цифры в неубывающем порядке\n");

    return 0;
}
