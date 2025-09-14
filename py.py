import random as rd
import pandas as pd
import math

Variant = 21
rd.seed(Variant)

set_operations = ['-','+','*','/']
set_operands = ['a', 'b', 'c']
count_operations = rd.randint(3,5)

expression = set_operands[rd.randint(0,len(set_operands)-1)]
for i in range(count_operations):
    current_operation = set_operations[rd.randint(0,len(set_operations)-1)]
    current_operand = set_operands[rd.randint(0,len(set_operands)-1)]
    expression = "(" + expression + current_operation + current_operand + ")"
print(expression)
"""
   Задание                    Параметры
0        1  S=QLQGaThNTMUkUIfNqqbSWtpNV
1        2      [$, N=55, M =5, K = 11]
2        3                            -
3        4                 N=2980480801
4        5                            -
"""
#(((b/c)*b)+b)
