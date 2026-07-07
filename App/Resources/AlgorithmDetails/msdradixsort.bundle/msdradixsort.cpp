#include <cstdio>
#include <vector>

int array[16] = {0, 39, 21, 62, 91, 77, 14, 23,
                 90, 69, 51, 81, 68, 83, 32, 56};

void printList(int arr[], int n) {
  for (int i = 0; i < n; i++) {
    if (i == 0) {
      printf("[%d, ", arr[i]);
    } else if (i != n - 1) {
      printf("%d, ", arr[i]);
    } else {
      printf("%d]", arr[i]);
    }
  }
}

int intPow(int base, int exponent) {
  int result = 1;
  for (int i = 0; i < exponent; i++) {
    result *= base;
  }
  return result;
}

int getDigit(int value, int power, int radix) {
  return (value / intPow(radix, power)) % radix;
}

void radixMSD(int arr[], int low, int high, int radix, int power) {
  if (low >= high || power < 0) {
    return;
  }

  std::vector<std::vector<int>> buckets(radix);
  for (int i = low; i < high; i++) {
    buckets[getDigit(arr[i], power, radix)].push_back(arr[i]);
  }

  int index = low;
  for (auto &bucket : buckets) {
    for (int value : bucket) {
      arr[index++] = value;
    }
  }

  int start = low;
  for (auto &bucket : buckets) {
    radixMSD(arr, start, start + (int) bucket.size(), radix, power - 1);
    start += (int) bucket.size();
  }
}

void sort(int arr[], int n) {
  if (n <= 1) {
    return;
  }
  int radix = 4;
  int maxValue = arr[0];
  for (int i = 1; i < n; i++) {
    if (arr[i] > maxValue) {
      maxValue = arr[i];
    }
  }
  int highestPower = 0;
  int probe = radix;
  while (probe <= maxValue) {
    highestPower++;
    probe *= radix;
  }
  radixMSD(arr, 0, n, radix, highestPower);
}

int main(int argc, char *argv[]) {
  int size = sizeof(array) / sizeof(array[0]);
  sort(array, size);
  printList(array, size);
  return 0;
}
