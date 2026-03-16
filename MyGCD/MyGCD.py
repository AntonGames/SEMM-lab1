import sys
a = int(sys.argv[1])
b = int(sys.argv[2])
while a != b:
    if a > b: a -= b
    else: b -= a
print(a)
# $ python MyGCD.py 18 12
# 6
