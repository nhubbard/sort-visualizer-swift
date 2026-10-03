#include <stdbool.h>
#include <stdio.h>

static int *items;
static int count;

static void circ_swap(int a, int b) {
  int temp = items[a % count];
  items[a % count] = items[b % count];
  items[b % count] = temp;
}

static void shift_fw(int a, int middle, int end) {
  while (middle < end) {
    circ_swap(a++, middle++);
  }
}

static void shift_bw(int start, int middle, int end) {
  while (middle > start) {
    circ_swap(--end, --middle);
  }
}

static void insertion(int start, int end) {
  for (int first = start + 1; first < end; first++) {
    int i = first;
    while (i > start && items[(i - 1) % count] > items[i % count]) {
      circ_swap(i, i - 1);
      i--;
    }
  }
}

static void multi_swap(int a, int b, int length) {
  for (int i = 0; i < length; i++) {
    circ_swap(a + i, b + i);
  }
}

static void rotate(int start, int middle, int end) {
  int left = middle - start;
  int right = end - middle;
  while (left > 0 && right > 0) {
    if (right < left) {
      multi_swap(middle - right, middle, right);
      end -= right;
      middle -= right;
      left -= right;
    } else {
      multi_swap(start, middle, left);
      start += left;
      middle += left;
      right -= left;
    }
  }
}

static void in_place_merge(int start, int middle, int end) {
  int i = start;
  while (i < middle && middle < end) {
    if (items[i % count] > items[middle % count]) {
      int k = middle + 1;
      while (k < end && items[i % count] > items[k % count]) {
        k++;
      }
      rotate(i, middle, k);
      i += k - middle;
      middle = k;
    } else {
      i++;
    }
  }
}

static int merge(int p, int start, int middle, int end, bool full) {
  int i = start;
  int j = middle;
  while (i < middle && j < end) {
    if (items[i % count] <= items[j % count]) {
      circ_swap(p++, i++);
    } else {
      circ_swap(p++, j++);
    }
  }
  if (i < middle) {
    if (i > p) {
      shift_fw(p, i, middle);
    }
  } else if (full) {
    shift_fw(p, j, end);
  }
  return i < middle ? i : j;
}

static bool block_less(int a, int b, int length) {
  if (items[a % count] != items[b % count]) {
    return items[a % count] < items[b % count];
  }
  return items[(a + length - 1) % count] < items[(b + length - 1) % count];
}

static void block_merge(int start, int middle, int end, int length) {
  int b1 = end - (end - middle - 1) % length - 1;
  if (b1 <= middle) {
    merge(start - length, start, middle, end, true);
    return;
  }
  int b2 = b1;
  for (int i = middle - length; i > start && block_less(b1, i, length);
       i -= length) {
    b2 -= length;
  }
  for (int j = start; j < b1 - length; j += length) {
    int minimum = j;
    for (int i = j + length; i < b1; i += length) {
      if (block_less(i, minimum, length)) {
        minimum = i;
      }
    }
    if (minimum != j) {
      multi_swap(j, minimum, length);
    }
  }
  int frontier = start;
  for (int i = start + length; i < b2; i += length) {
    frontier = merge(frontier - length, frontier, i, i + length, false);
    if (frontier < i) {
      shift_bw(frontier, i, i + length);
      frontier += length;
    }
  }
  merge(frontier - length, frontier, b1, end, true);
}

static void sort(int array[], int size) {
  items = array;
  count = size;
  if (count < 2) {
    return;
  }
  if (count <= 16) {
    insertion(0, count);
    return;
  }
  int block = 1;
  while (block * block < count) {
    block *= 2;
  }
  int i = block;
  int run = 1;
  int rolling = count - block;
  int end = count;
  while (run <= block) {
    while (i + 2 * run < end) {
      merge(i - run, i, i + run, i + 2 * run, true);
      i += 2 * run;
    }
    if (i + run < end) {
      merge(i - run, i, i + run, end, true);
    } else {
      shift_fw(i - run, i, end);
    }
    i = end + block - run;
    end = i + rolling;
    run *= 2;
  }
  while (run < rolling) {
    while (i + 2 * run < end) {
      block_merge(i, i + run, i + 2 * run, block);
      i += 2 * run;
    }
    if (i + run < end) {
      block_merge(i, i + run, end, block);
    } else {
      shift_fw(i - block, i, end);
    }
    i = end;
    end += rolling;
    run *= 2;
  }
  insertion(i - block, i);
  in_place_merge(i - block, i, end);
  rotate(0, (i - block) % count, count);
}

int main(void) {
  int array[] = {0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56};
  int size = (int)(sizeof(array) / sizeof(array[0]));
  sort(array, size);
  printf("[");
  for (int i = 0; i < size; i++) {
    printf(i == 0 ? "%d" : ", %d", array[i]);
  }
  printf("]");
  return 0;
}
