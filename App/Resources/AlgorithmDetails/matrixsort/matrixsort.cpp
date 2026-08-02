#include <cmath>
#include <cstdio>
#include <utility>

int array[25] = {15, 3,  22, 8,  19, 1,  24, 11, 6,  20, 9,  17, 2,
                 14, 23, 5,  18, 0,  12, 21, 7,  16, 4,  13, 10};

struct MatrixShape {
  int width;
  bool insertLast;
};

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

int dirCompareVal(int left, int right, bool dir) {
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
    std::swap(arr[i], arr[j - gap]);
    i += gap;
    j -= gap;
  }
}

bool insertLast(int arr[], int a, int b, int gap, bool dir) {
  bool did = false;
  int key = arr[b];
  int j = b - gap;
  while (j >= a && dirCompareVal(key, arr[j], dir) < 0) {
    arr[j + gap] = arr[j];
    did = true;
    j -= gap;
  }
  arr[j + gap] = key;
  return did;
}

MatrixShape getMatrixDims(int length) {
  int dim = static_cast<int>(std::sqrt(static_cast<double>(length)));
  bool insertLastFlag = (dim * dim == length - 1);
  while (length % dim != 0) {
    dim -= 1;
  }
  int width = dim;
  int height = length / dim;
  bool unbalanced = (width == 1) != (height == 1);
  return MatrixShape{width, unbalanced || insertLastFlag};
}

bool matrixSort(int arr[], int start, int end, int gap, bool dir) {
  int length = (end - start) / gap;
  if (length < 2) {
    return false;
  } else if (length <= 16) {
    bool did = false;
    int i = start;
    while (i < end) {
      did = insertLast(arr, start, i, gap, dir) || did;
      i += gap;
    }
    return did;
  } else {
    MatrixShape matShape = getMatrixDims(length);
    if (matShape.insertLast) {
      bool did1 = matrixSort(arr, start, end - gap, gap, dir);
      bool did2 = insertLast(arr, start, end - gap, gap, dir);
      return did1 || did2;
    }

    int i = start + matShape.width * gap;
    while (i < end) {
      gapReverse(arr, i, i + matShape.width * gap, gap);
      i += 2 * matShape.width * gap;
    }

    bool did = false;
    bool newdid = true;
    while (newdid) {
      newdid = false;
      bool curdir = dir;
      i = start;
      while (i < end) {
        newdid =
            matrixSort(arr, i, i + matShape.width * gap, gap, curdir) || newdid;
        did = did || newdid;
        curdir = !curdir;
        i += matShape.width * gap;
      }

      newdid = false;
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

void sort(int arr[], int n) { matrixSort(arr, 0, n, 1, true); }

int main(int argc, char *argv[]) {
  int size = sizeof(array) / sizeof(array[0]);
  sort(array, size);
  printList(array, size);
  return 0;
}
