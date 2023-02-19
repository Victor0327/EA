import numpy as np
import math
from welford import Welford


# Initialize Welford object
w = Welford()
# Input data samples sequentialy

n1 = 100
n2 = 110
n3 = 120

w.add_value(n1)
w.add_value(n2)

print('n1、n2的mean {0}'.format(w.get_mean()))
print('n1、n2的方差 {0}'.format(w.get_variance()))

n = 2
old_mean = float(w.get_mean())
old_v = float(w.get_variance())
new_data = n3

w.add_value(n3)

# output
print('n1、n2、n3的mean {0}'.format(w.get_mean()))  # mean --> [  1. 110.]
print('n1、n2、n3的方差 {0}'.format(w.get_variance()))  # population variance --> [ 0.6666 66.66]



