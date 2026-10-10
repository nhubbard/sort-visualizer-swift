#include <stdio.h>
#define CAPACITY 64

typedef struct { int *values; int buffer[CAPACITY]; } RotateSort;
static int lowerBound(RotateSort *s, int start, int end, int value) {
  while (start < end) {
    int middle = start + (end - start) / 2;
    if (s->values[middle] < value) start = middle + 1;
    else end = middle;
  }
  return start;
}
static int upperBound(RotateSort *s, int start, int end, int value) {
  while (start < end) {
    int middle = start + (end - start) / 2;
    if (s->values[middle] <= value) start = middle + 1;
    else end = middle;
  }
  return start;
}
static void reverse(RotateSort *s, int start, int end) {
  end--;
  while (start < end) {
    int value = s->values[start];
    s->values[start++] = s->values[end];
    s->values[end--] = value;
  }
}
static void rotate(RotateSort *s, int start, int middle, int end) {
  if (start >= middle || middle >= end) return;
  int left = middle - start, right = end - middle;
  if (left <= CAPACITY) {
    for (int i = 0; i < left; i++) s->buffer[i] = s->values[start + i];
    for (int i = middle; i < end; i++) s->values[i - left] = s->values[i];
    for (int i = 0; i < left; i++) s->values[end - left + i] = s->buffer[i];
  } else if (right <= CAPACITY) {
    for (int i = 0; i < right; i++) s->buffer[i] = s->values[middle + i];
    for (int i = middle - 1; i >= start; i--) s->values[i + right] = s->values[i];
    for (int i = 0; i < right; i++) s->values[start + i] = s->buffer[i];
  } else {
    reverse(s, start, middle);
    reverse(s, middle, end);
    reverse(s, start, end);
  }
}
static void bufferedMerge(RotateSort *s, int start, int middle, int end) {
  int leftLength = middle - start, rightLength = end - middle;
  if (leftLength <= rightLength) {
    for (int i = 0; i < leftLength; i++) s->buffer[i] = s->values[start + i];
    int left = 0, right = middle, destination = start;
    while (left < leftLength && right < end) {
      if (s->values[right] < s->buffer[left]) s->values[destination] = s->values[right++];
      else s->values[destination] = s->buffer[left++];
      destination++;
    }
    while (left < leftLength) s->values[destination++] = s->buffer[left++];
  } else {
    for (int i = 0; i < rightLength; i++) s->buffer[i] = s->values[middle + i];
    int left = middle - 1, right = rightLength - 1, destination = end - 1;
    while (left >= start && right >= 0) {
      if (s->values[left] > s->buffer[right]) s->values[destination] = s->values[left--];
      else s->values[destination] = s->buffer[right--];
      destination--;
    }
    while (right >= 0) s->values[destination--] = s->buffer[right--];
  }
}
static void merge(RotateSort *s, int start, int middle, int end) {
  if (start >= middle || middle >= end || s->values[middle - 1] <= s->values[middle]) return;
  int leftLength = middle - start, rightLength = end - middle;
  if ((leftLength < rightLength ? leftLength : rightLength) <= CAPACITY) {
    bufferedMerge(s, start, middle, end);
    return;
  }
  int leftSplit, rightSplit;
  if (leftLength >= rightLength) {
    leftSplit = start + leftLength / 2;
    rightSplit = lowerBound(s, middle, end, s->values[leftSplit]);
  } else {
    rightSplit = middle + rightLength / 2;
    leftSplit = upperBound(s, start, middle, s->values[rightSplit]);
  }
  rotate(s, leftSplit, middle, rightSplit);
  int newMiddle = leftSplit + rightSplit - middle;
  merge(s, start, leftSplit, newMiddle);
  merge(s, newMiddle, rightSplit, end);
}
static void insertion(RotateSort *s, int start, int end) {
  for (int index = start + 1; index < end; index++) {
    int value = s->values[index];
    int destination = upperBound(s, start, index, value);
    for (int cursor = index; cursor > destination; cursor--)
      s->values[cursor] = s->values[cursor - 1];
    s->values[destination] = value;
  }
}
void sort(int values[], int count) {
  if (count < 2) return;
  RotateSort s = { .values = values, .buffer = {0} };
  for (int start = 0; start < count; start += 32) {
    int end = start + 32 < count ? start + 32 : count;
    insertion(&s, start, end);
  }
  for (int run = 32; run < count; run *= 2)
    for (int start = 0; start + run < count; start += 2 * run) {
      int end = start + 2 * run < count ? start + 2 * run : count;
      merge(&s, start, start + run, end);
    }
}
int main(void) {
  int array[] = {0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56};
  int count = sizeof(array) / sizeof(array[0]);
  sort(array, count);
  printf("[");
  for (int i = 0; i < count; i++) printf(i ? ", %d" : "%d", array[i]);
  puts("]");
  return 0;
}
