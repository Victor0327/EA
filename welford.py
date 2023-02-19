import math

class Welford:
    def __init__(self):
        self.n = 0
        self.mean = 0.0
        self.M2 = 0.0

    def add_value(self, x):
        self.n += 1
        delta = x - self.mean
        self.mean += delta / self.n
        self.M2 += delta * (x - self.mean)

    def get_mean(self):
        return self.mean

    def get_variance(self):
        if self.n < 2:
            return 0.0
        return self.M2 / self.n

    def get_standard_deviation(self):
        return math.sqrt(self.get_variance())
