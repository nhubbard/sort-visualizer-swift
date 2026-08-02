#include <stdio.h>
#include <stdlib.h>

int array[16] = {0, 39, 21, 62, 91, 77, 14, 23,
                 90, 69, 51, 81, 68, 83, 32, 56};

void swap(int *a, int *b) {
  int t = *a;
  *a = *b;
  *b = t;
}

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

void reverseRange(int arr[], int lo, int hi) {
  while (lo < hi) {
    swap(&arr[lo], &arr[hi]);
    lo++;
    hi--;
  }
}

int twinSwap(int arr[], int nmemb) {
  int index = 0;
  int end = nmemb - 2;
  while (index <= end) {
    if (arr[index] <= arr[index + 1]) {
      index += 2;
      continue;
    }
    int start = index;
    index += 2;
    while (1) {
      if (index > end) {
        if (start == 0 && (nmemb % 2 == 0 || arr[index - 1] > arr[index])) {
          end = nmemb - 1;
          reverseRange(arr, start, end);
          return 1;
        }
        break;
      }
      if (arr[index] > arr[index + 1]) {
        if (arr[index - 1] > arr[index]) {
          index += 2;
          continue;
        }
        swap(&arr[index], &arr[index + 1]);
      }
      break;
    }
    end = index - 1;
    reverseRange(arr, start, end);
    end = nmemb - 2;
    index += 2;
  }
  return 0;
}

void tailMerge(int arr[], int buf[], int nmemb, int block) {
  int s = 0;
  while (block < nmemb) {
    int offset = 0;
    while (offset + block < nmemb) {
      int a = offset;
      int e = a + block - 1;
      if (arr[e] <= arr[e + 1]) {
        offset += block * 2;
        continue;
      }
      int cMax, dMax;
      if (offset + block * 2 <= nmemb) {
        cMax = s + block;
        dMax = a + block * 2;
      } else {
        cMax = s + nmemb - (offset + block);
        dMax = nmemb;
      }
      int d = dMax - 1;
      while (arr[e] <= arr[d]) {
        dMax--;
        d--;
        cMax--;
      }
      int c = s;
      d = a + block;
      while (c < cMax) {
        buf[c] = arr[d];
        c++;
        d++;
      }
      c--;
      d = a + block - 1;
      e = dMax - 1;
      if (arr[a] <= arr[a + block]) {
        arr[e] = arr[d]; e--; d--;
        while (c >= s) {
          while (arr[d] > buf[c]) {
            arr[e] = arr[d]; e--; d--;
          }
          arr[e] = buf[c]; e--; c--;
        }
      } else {
        arr[e] = arr[d]; e--; d--;
        while (d >= a) {
          while (arr[d] <= buf[c]) {
            arr[e] = buf[c]; e--; c--;
          }
          arr[e] = arr[d]; e--; d--;
        }
        while (c >= s) {
          arr[e] = buf[c]; e--; c--;
        }
      }
      offset += block * 2;
    }
    block *= 2;
  }
}

void twinsort(int arr[], int nmemb) {
  if (twinSwap(arr, nmemb) == 0) {
    int *buf = (int *)malloc(sizeof(int) * (nmemb / 2));
    tailMerge(arr, buf, nmemb, 2);
    free(buf);
  }
}

void sort(int arr[], int n) {
  twinsort(arr, n);
}

int main(int argc, char *argv[]) {
  int size = sizeof(array) / sizeof(array[0]);
  sort(array, size);
  printList(array, size);
  return 0;
}
