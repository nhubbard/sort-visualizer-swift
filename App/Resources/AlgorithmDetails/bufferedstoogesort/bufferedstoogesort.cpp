#include <cstdio>
#include <utility>

int array[16] = {0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56};

void printList(int items[], int size) {
  for (int i = 0; i < size; i++) {
    if (i == 0) {
      printf("[%d, ", items[i]);
    } else if (i != size - 1) {
      printf("%d, ", items[i]);
    } else {
      printf("%d]", items[i]);
    }
  }
}

void bufferedStoogeSort(int arr[], int start, int stop) {
  if (stop - start > 1) {
    if (stop - start == 2 && arr[start] > arr[stop - 1]) {
      std::swap(arr[start], arr[stop - 1]);
    }
    if (stop - start > 2) {
      int width = stop - start;
      int third = (width + 2) / 3 + start;
      int twoThird = (2 * width + 2) / 3 + start;
      if (twoThird - third < third) {
        twoThird--;
      }
      if ((width - 2) % 3 == 0) {
        twoThird--;
      }

      bufferedStoogeSort(arr, third, twoThird);
      bufferedStoogeSort(arr, twoThird, stop);

      int left = third;
      int right = twoThird;
      int bufferStart = start;
      while (left < twoThird && right < stop) {
        if (arr[left] > arr[right]) {
          std::swap(arr[bufferStart], arr[right]);
          right++;
        } else {
          std::swap(arr[bufferStart], arr[left]);
          left++;
        }
        bufferStart++;
      }
      while (right < stop) {
        std::swap(arr[bufferStart], arr[right]);
        right++;
        bufferStart++;
      }

      bufferedStoogeSort(arr, twoThird, stop);

      left = twoThird - 1;
      right = stop - 1;
      while (right > left && left >= start) {
        if (arr[left] > arr[right]) {
          for (int i = left; i < right; i++) {
            std::swap(arr[i], arr[i + 1]);
          }
          left--;
        }
        right--;
      }
    }
  }
}

void sort(int arr[], int n) { bufferedStoogeSort(arr, 0, n); }

int main(int argc, char *argv[]) {
  int size = sizeof(array) / sizeof(array[0]);
  sort(array, size);
  printList(array, size);
  return 0;
}