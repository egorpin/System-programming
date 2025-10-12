import random as rd

Variant = 21
rd.seed(Variant)


colors = ['COLOR_BLACK', 'COLOR_RED', 'COLOR_GREEN', 'СOLOR_YELLOW', 'COLOR_BLUE', 'COLOR_MAGENTA', 'COLOR_CYAN', 'COLOR_WHITE']
buttons = ['q', 'w', 'e', 'r', 't', 'y', 'u', 'i', 'o', 'p', 'a', 's', 'd', 'f', 'g', 'h', 'j','k','l','z','x','c','v','b','n','m']
print("Алгоритм: " , rd.sample([1,2,3,4,5,6,7,8],1))
print("Цвета заполнения: " , rd.sample(colors,2))
print("Кнопки выхода, изменения скорости: " , rd.sample(buttons,2))
"""
   Задание                    Параметры
0        1  S=QLQGaThNTMUkUIfNqqbSWtpNV
1        2      [$, N=55, M =5, K = 11]
2        3                            -
3        4                 N=2980480801
4        5                            -
"""
#(((b/c)*b)+b)
# 3 7 12
# [3, 7]
"""
Алгоритм:  [3]
Цвета заполнения:  ['COLOR_CYAN', 'COLOR_MAGENTA']
Кнопки выхода, изменения скорости:  ['f', 'x']
"""
