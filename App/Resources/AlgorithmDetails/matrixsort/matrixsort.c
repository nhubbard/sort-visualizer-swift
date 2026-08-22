#include <math.h>
#include <stdio.h>
#include <stdlib.h>

int array[25] = {15, 3,  22, 8,  19, 1,  24, 11, 6,  20, 9,  17, 2,
                 14, 23, 5,  18, 0,  12, 21, 7,  16, 4,  13, 10};

typedef struct {
  int width;
  int insertLast;
} MatrixShape;

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

int dirCompareVal(int left, int right, int dir) {
  int res;
  if (left > right) {
    res = 1;
  } else if (left < right) {
    res = -1;
  } else {
    res = 0;
  }
  return dir ? res : -res;
}

void gapReverse(int arr[], int start, int end, int gap) {
  int i = start, j = end;
  while (i < j) {
    swap(&arr[i], &arr[j - gap]);
    i += gap;
    j -= gap;
  }
}

int insertLast(int arr[], int a, int b, int gap, int dir) {
  int did = 0;
  int key = arr[b];
  int j = b - gap;
  while (j >= a && dirCompareVal(key, arr[j], dir) < 0) {
    arr[j + gap] = arr[j];
    did = 1;
    j -= gap;
  }
  arr[j + gap] = key;
  return did;
}

MatrixShape getMatrixDims(int length) {
  int dim = (int)sqrt((double)length);
  int insertLastFlag = (dim * dim == length - 1);
  while (length % dim != 0) {
    dim -= 1;
  }
  int width = dim;
  int height = length / dim;
  int unbalanced = (width == 1) != (height == 1);
  MatrixShape shape;
  shape.width = width;
  shape.insertLast = unbalanced || insertLastFlag;
  return shape;
}

int matrixSort(int arr[], int start, int end, int gap, int dir) {
  int length = (end - start) / gap;
  if (length < 2) {
    return 0;
  } else if (length <= 16) {
    int did = 0;
    int i = start;
    while (i < end) {
      did = insertLast(arr, start, i, gap, dir) || did;
      i += gap;
    }
    return did;
  } else {
    MatrixShape matShape = getMatrixDims(length);
    if (matShape.insertLast) {
      int did1 = matrixSort(arr, start, end - gap, gap, dir);
      int did2 = insertLast(arr, start, end - gap, gap, dir);
      return did1 || did2;
    }

    int i = start + matShape.width * gap;
    while (i < end) {
      gapReverse(arr, i, i + matShape.width * gap, gap);
      i += 2 * matShape.width * gap;
    }

    int did = 0;
    int newdid = 1;
    while (newdid) {
      newdid = 0;
      int curdir = dir;
      i = start;
      while (i < end) {
        newdid =
            matrixSort(arr, i, i + matShape.width * gap, gap, curdir) || newdid;
        did = did || newdid;
        curdir = !curdir;
        i += matShape.width * gap;
      }

      newdid = 0;
      for (int k = 0; k < matShape.width; k++) {
        newdid = matrixSort(arr, start + k * gap, end + k * gap,
                            gap * matShape.width, dir) ||
                 newdid;
        did = did || newdid;
      }
    }
    i = start + matShape.width * gap;
    while (i < end) {
      gapReverse(arr, i, i + matShape.width * gap, gap);
      i += 2 * matShape.width * gap;
    }

    return did;
  }
}

void sort(int arr[], int n) { matrixSort(arr, 0, n, 1, 1); }

int main(int argc, char *argv[]) {
  int size = sizeof(array) / sizeof(array[0]);
  sort(array, size);
  printList(array, size);
  return 0;
}
