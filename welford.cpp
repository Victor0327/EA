class Welford {
public:
    Welford() : n(0), mean(0.0), M2(0.0) {}

    void AddValue(double x) {
        n++;
        double delta = x - mean;
        mean += delta / n;
        M2 += delta * (x - mean);
    }

    double GetMean() const {
        return mean;
    }

    double GetVariance() const {
        if (n < 2) {
            return 0.0;
        }
        return M2 / n;
    }

    double GetStandardDeviation() const {
        return sqrt(GetVariance());
    }

private:
    size_t n;
    double mean, M2;
};
