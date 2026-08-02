#include <stdio.h>
#include <stdlib.h>

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

typedef struct {
  int top;
  int pileIndex;
} HeapEntry;

typedef struct {
  HeapEntry *data;
  int size;
} MinHeap;

void heapPush(MinHeap *heap, HeapEntry entry) {
  int i = heap->size++;
  heap->data[i] = entry;
  while (i > 0) {
    int parent = (i - 1) / 2;
    if (heap->data[parent].top <= heap->data[i].top)
      break;
    HeapEntry tmp = heap->data[parent];
    heap->data[parent] = heap->data[i];
    heap->data[i] = tmp;
    i = parent;
  }
}

HeapEntry heapPopMin(MinHeap *heap) {
  HeapEntry result = heap->data[0];
  heap->size--;
  heap->data[0] = heap->data[heap->size];
  int i = 0;
  while (1) {
    int left = (2 * i) + 1;
    int right = (2 * i) + 2;
    int smallest = i;
    if (left < heap->size && heap->data[left].top < heap->data[smallest].top)
      smallest = left;
    if (right < heap->size && heap->data[right].top < heap->data[smallest].top)
      smallest = right;
    if (smallest == i)
      break;
    HeapEntry tmp = heap->data[smallest];
    heap->data[smallest] = heap->data[i];
    heap->data[i] = tmp;
    i = smallest;
  }
  return result;
}

void sort(int arr[], int n) {
  int *piles = malloc(sizeof(int) * n * n);
  int *pileLen = malloc(sizeof(int) * n);
  int *tops = malloc(sizeof(int) * n);
  int pileCount = 0;

  for (int k = 0; k < n; k++) {
    int x = arr[k];
    /* binary search: leftmost pile whose top is >= x */
    int lo = 0;
    int hi = pileCount;
    while (lo < hi) {
      int mid = (lo + hi) / 2;
      if (tops[mid] >= x) {
        hi = mid;
      } else {
        lo = mid + 1;
      }
    }
    if (lo == pileCount) {
      piles[(lo * n) + 0] = x;
      pileLen[lo] = 1;
      tops[lo] = x;
      pileCount++;
    } else {
      piles[(lo * n) + pileLen[lo]] = x;
      pileLen[lo]++;
      tops[lo] = x;
    }
  }

  MinHeap heap;
  heap.data = malloc(sizeof(HeapEntry) * pileCount);
  heap.size = 0;
  for (int i = 0; i < pileCount; i++) {
    HeapEntry entry;
    entry.top = tops[i];
    entry.pileIndex = i;
    heapPush(&heap, entry);
  }

  int *result = malloc(sizeof(int) * n);
  int resultIndex = 0;
  while (heap.size > 0) {
    HeapEntry entry = heapPopMin(&heap);
    int pileIndex = entry.pileIndex;
    int value = piles[(pileIndex * n) + pileLen[pileIndex] - 1];
    pileLen[pileIndex]--;
    result[resultIndex++] = value;
    if (pileLen[pileIndex] > 0) {
      HeapEntry newEntry;
      newEntry.top = piles[(pileIndex * n) + pileLen[pileIndex] - 1];
      newEntry.pileIndex = pileIndex;
      heapPush(&heap, newEntry);
    }
  }

  for (int i = 0; i < n; i++) {
    arr[i] = result[i];
  }

  free(piles);
  free(pileLen);
  free(tops);
  free(heap.data);
  free(result);
}

int main(int argc, char *argv[]) {
  int size = sizeof(array) / sizeof(array[0]);
  sort(array, size);
  printList(array, size);
  return 0;
}