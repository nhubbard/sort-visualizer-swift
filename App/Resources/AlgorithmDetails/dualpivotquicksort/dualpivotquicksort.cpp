#include <cstdio>
#include <utility>

int array[16] = {0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56};

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

std::pair<int, int> partition(int arr[], int low, int high) {
  if (arr[low] > arr[high]) {
    std::swap(arr[low], arr[high]);
  }
  int j = low + 1;
  int g = high - 1;
  int k = low + 1;
  int p = arr[low];
  int q = arr[high];
  while (k <= g) {
    if (arr[k] < p) {
      std::swap(arr[k], arr[j]);
      j++;
    } else if (arr[k] >= q) {
      while (arr[g] > q && k < g) {
        g--;
      }
      std::swap(arr[k], arr[g]);
      g--;
      if (arr[k] < p) {
        std::swap(arr[k], arr[j]);
        j++;
      }
    }
    k++;
  }
  j--;
  g++;
  std::swap(arr[low], arr[j]);
  std::swap(arr[high], arr[g]);
  return {j, g};
}

void sort(int arr[], int low, int high) {
  if (low < high) {
    auto [j, g] = partition(arr, low, high);
    sort(arr, low, j - 1);
    sort(arr, j + 1, g - 1);
    sort(arr, g + 1, high);
  }
}

int main(int argc, char *argv[]) {
  int size = sizeof(array) / sizeof(array[0]);
  sort(array, 0, size - 1);
  printList(array, size);
  return 0;
}
