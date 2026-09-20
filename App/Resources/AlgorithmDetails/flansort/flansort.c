#include <stdint.h>
#include <stdio.h>

int array[16] = {0, 39, 21, 62, 91, 77, 14, 23,
                 90, 69, 51, 81, 68, 83, 32, 56};

void swap(int *a, int *b) {
  int t = *a;
  *a = *b;
  *b = t;
}

void printList(int items[], int size) {
  printf("[");
  if (size > 0) {
    printf("%d", items[0]);
    for (int i = 1; i < size; i++) {
      printf(", %d", items[i]);
    }
  }
  printf("]");
}

static void flanSort(int *a, int n);

void sort(int *a, int n) {
  flanSort(a, n);
}

enum { GAP = 14, RATIO = 4 };
typedef struct {
  int *a;
  int position[GAP + 2], heap[GAP + 2];
  uint64_t random;
} Flan;
static int minimum(int x, int y);
static int maximum(int x, int y);
static void exchange(Flan *s, int i, int j);
static int choice(Flan *s, int count);
static int median(Flan *s, int i, int m, int j);
static int ninther(Flan *s, int first, int last);
static int pivot(Flan *s, int first, int last);
static int binarySearch(Flan *s, int first, int last, int value, int backward);
static void insert(Flan *s, int value, int from, int to);
static void insertion(Flan *s, int first, int last);
static int blockSearch(Flan *s, int first, int last, int value, int right);
static void retrieve(Flan *s, int finish, int scratch, int pEnd, int boundary,
                     int backward);
static void librarySort(Flan *s, int first, int last, int scratch, int boundary,
                        int backward);
static int less(Flan *s, int x, int y);
static void sift(Flan *s, int item, int first, int size);
static void merge(Flan *s, int runLength, int finish, int destination,
                  int count);

static void flanSort(int *a, int n) {
  if (n < 2)
    return;
  Flan s = {0};
  s.a = a;
  s.random = UINT64_C(0x9e3779b97f4a7c15);
  for (int i = 0; i < n; i++)
    s.random =
        (s.random ^ (uint64_t)(int64_t)a[i]) * UINT64_C(0xbf58476d1ce4e5b9) +
        UINT64_C(0x94d049bb133111eb);
  int first = 0, finish = n;
  while (finish - first >= 32) {
    int value = a[pivot(&s, first, finish)];
    int before = first, i = first - 1, j = finish, after = finish;
    while (1) {
      i++;
      while (i < j) {
        if (a[i] == value) {
          exchange(&s, before, i);
          before++;
        } else if (a[i] < value)
          break;
        i++;
      }
      j--;
      while (j > i) {
        if (a[j] == value) {
          after--;
          exchange(&s, after, j);
        } else if (a[j] > value)
          break;
        j--;
      }
      if (i < j)
        exchange(&s, i, j);
      else {
        if (before == finish)
          return;
        if (j < i)
          j++;
        while (before > first) {
          i--;
          before--;
          exchange(&s, i, before);
        }
        while (after < finish) {
          exchange(&s, j, after);
          j++;
          after++;
        }
        break;
      }
    }
    int left = i - first, right = finish - j, count = 0;
    if (left <= right) {
      int move = finish - left;
      left = maximum((right + 1) / (GAP + 1), 16);
      for (int k = first; k < i; k += left) {
        librarySort(&s, k, minimum(k + left, i), j, value, 1);
        s.position[count++] = k;
      }
      merge(&s, left, i, move, count);
      if (j - i < move - j) {
        while (i < j) {
          move--;
          exchange(&s, i, move);
          i++;
        }
        finish = move;
      } else {
        while (move > j) {
          move--;
          exchange(&s, i, move);
          i++;
        }
        finish = i;
      }
    } else {
      int move = first + right;
      right = maximum((left + 1) / (GAP + 1), 16);
      for (int k = j; k < finish; k += right) {
        librarySort(&s, k, minimum(k + right, finish), first, value, 0);
        s.position[count++] = k;
      }
      merge(&s, right, finish, first, count);
      if (i - move < j - i) {
        while (move < i) {
          j--;
          exchange(&s, move, j);
          move++;
        }
        first = j;
      } else {
        while (j > i) {
          j--;
          exchange(&s, move, j);
          move++;
        }
        first = move;
      }
    }
  }
  insertion(&s, first, finish);
}

static int minimum(int x, int y) {
  return x < y ? x : y;
}
static int maximum(int x, int y) {
  return x > y ? x : y;
}
static void exchange(Flan *s, int i, int j) {
  int item = s->a[i];
  s->a[i] = s->a[j];
  s->a[j] = item;
}
static int choice(Flan *s, int count) {
  s->random ^= s->random >> 12;
  s->random ^= s->random << 25;
  s->random ^= s->random >> 27;
  return (int)((s->random * UINT64_C(0x2545f4914f6cdd1d)) % (uint64_t)count);
}
static int median(Flan *s, int i, int m, int j) {
  if (s->a[m] > s->a[i]) {
    if (s->a[m] < s->a[j])
      return m;
    return s->a[i] > s->a[j] ? i : j;
  }
  if (s->a[m] > s->a[j])
    return m;
  return s->a[i] < s->a[j] ? i : j;
}
static int ninther(Flan *s, int first, int last) {
  int step = (last - first) / 9;
  return median(
      s, median(s, first, first + step, first + 2 * step),
      median(s, first + 3 * step, first + 4 * step, first + 5 * step),
      median(s, first + 6 * step, first + 7 * step, first + 8 * step));
}
static int pivot(Flan *s, int first, int last) {
  int step = (last - first) / 3;
  return median(s, ninther(s, first, first + step),
                ninther(s, first + step, first + 2 * step),
                ninther(s, first + 2 * step, last));
}
static int binarySearch(Flan *s, int first, int last, int value, int backward) {
  while (first < last) {
    int middle = first + (last - first) / 2;
    int found = backward ? s->a[middle] < value : s->a[middle] > value;
    if (found)
      last = middle;
    else
      first = middle + 1;
  }
  return first;
}
static void insert(Flan *s, int value, int from, int to) {
  while (from > to) {
    from--;
    s->a[from + 1] = s->a[from];
  }
  s->a[to] = value;
}
static void insertion(Flan *s, int first, int last) {
  for (int i = first + 1; i < last; i++) {
    int value = s->a[i];
    insert(s, value, i, binarySearch(s, first, i, value, 0));
  }
}
static int blockSearch(Flan *s, int first, int last, int value, int right) {
  while (first < last) {
    int middle = first + ((last - first) / (GAP + 1) / 2) * (GAP + 1);
    int found = right ? s->a[middle] > value : s->a[middle] >= value;
    if (found)
      last = middle;
    else
      first = middle + GAP + 1;
  }
  return first;
}
static void retrieve(Flan *s, int finish, int scratch, int pEnd, int boundary,
                     int backward) {
  int destination = finish - 1, block = pEnd - (GAP + 1);
  while (block > scratch + GAP) {
    int item = binarySearch(s, block - GAP, block, boundary, backward) - 1;
    block -= GAP + 1;
    while (item >= block) {
      exchange(s, destination, item);
      destination--;
      item--;
    }
  }
  int item = binarySearch(s, scratch, scratch + GAP, boundary, backward) - 1;
  while (item >= scratch) {
    exchange(s, destination, item);
    destination--;
    item--;
  }
}
static void librarySort(Flan *s, int first, int last, int scratch, int boundary,
                        int backward) {
  int length = last - first;
  if (length < 32) {
    insertion(s, first, last);
    return;
  }
  int count = length;
  while (count >= 32)
    count = (count - 1) / RATIO + 1;
  int i = first + count, trigger = first + RATIO * count;
  int pEnd = scratch + (count + 1) * (GAP + 1) + GAP;
  insertion(s, first, i);
  for (int k = 0; k < count; k++)
    exchange(s, first + k, scratch + k * (GAP + 1) + GAP);
  while (i < last) {
    if (i == trigger) {
      retrieve(s, i, scratch, pEnd, boundary, backward);
      count = i - first;
      pEnd = scratch + (count + 1) * (GAP + 1) + GAP;
      trigger = first + (trigger - first) * RATIO;
      for (int k = 0; k < count; k++)
        exchange(s, first + k, scratch + k * (GAP + 1) + GAP);
    }
    int value = s->a[i];
    int block = blockSearch(s, scratch + GAP, pEnd - (GAP + 1), value, 0);
    if (s->a[block] == value) {
      int afterEqual =
          blockSearch(s, block + GAP + 1, pEnd - (GAP + 1), value, 1);
      block += choice(s, (afterEqual - block) / (GAP + 1)) * (GAP + 1);
    }
    int loc = binarySearch(s, block - GAP, block, boundary, backward);
    if (loc == block) {
      do {
        block += GAP + 1;
      } while (block < pEnd && binarySearch(s, block - GAP, block, boundary,
                                            backward) == block);
      if (block == pEnd) {
        retrieve(s, i, scratch, pEnd, boundary, backward);
        count = i - first;
        pEnd = scratch + (count + 1) * (GAP + 1) + GAP;
        trigger = first + (trigger - first) * RATIO;
        for (int k = 0; k < count; k++)
          exchange(s, first + k, scratch + k * (GAP + 1) + GAP);
      } else {
        int firstItem = binarySearch(s, block - GAP, block, boundary, backward);
        int distance = block - maximum(firstItem, block - GAP / 2);
        int source = block - distance, destination = block;
        while (source > loc - distance) {
          source--;
          destination--;
          exchange(s, destination, source);
        }
      }
    } else {
      int displaced = s->a[loc];
      s->a[i] = displaced;
      i++;
      insert(s, value, loc, binarySearch(s, block - GAP, loc, value, 0));
    }
  }
  retrieve(s, last, scratch, pEnd, boundary, backward);
}
static int less(Flan *s, int x, int y) {
  int left = s->a[s->position[x]], right = s->a[s->position[y]];
  return left < right || (left == right && x < y);
}
static void sift(Flan *s, int item, int first, int size) {
  int root = first;
  while (2 * root + 2 < size) {
    int left = 2 * root + 1,
        child = less(s, s->heap[left], s->heap[left + 1]) ? left : left + 1;
    if (!less(s, s->heap[child], item))
      break;
    s->heap[root] = s->heap[child];
    root = child;
  }
  int last = 2 * root + 1;
  if (last < size && less(s, s->heap[last], item)) {
    s->heap[root] = s->heap[last];
    root = last;
  }
  s->heap[root] = item;
}
static void merge(Flan *s, int runLength, int finish, int destination,
                  int count) {
  if (count < 2) {
    if (count == 1)
      while (s->position[0] < finish) {
        exchange(s, destination, s->position[0]);
        destination++;
        s->position[0]++;
      }
    return;
  }
  int first = s->position[0];
  for (int i = 0; i < count; i++)
    s->heap[i] = i;
  for (int i = (count - 1) / 2; i >= 0; i--)
    sift(s, s->heap[i], i, count);
  int size = count;
  while (size > 0) {
    int run = s->heap[0];
    exchange(s, destination, s->position[run]);
    destination++;
    s->position[run]++;
    if (s->position[run] == minimum(first + (run + 1) * runLength, finish)) {
      size--;
      sift(s, s->heap[size], 0, size);
    } else
      sift(s, s->heap[0], 0, size);
  }
}

int main(void) {
  int n = (int)(sizeof(array) / sizeof(array[0]));
  sort(array, n);
  printList(array, n);
  return 0;
}
