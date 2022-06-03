//
//  common.h
//  Sort2
//
//  Created by Nicholas Hubbard on 6/3/22.
//
//  Contains the list of random numbers to be used by the C/C++ algorithm implementations.

#ifndef common
#define common
int items[100] = {35, 95, 74, 71, 72, 30, 96, 53, 9, 0, 52, 37, 70, 77, 40, 80, 59, 89, 54, 1, 11, 26, 41, 20, 33, 68, 8, 97, 24, 86, 47, 14, 82, 76, 7, 38, 45, 92, 94, 87, 36, 34, 3, 99, 19, 43, 6, 51, 81, 90, 69, 93, 25, 42, 5, 56, 66, 28, 79, 64, 85, 57, 27, 58, 17, 22, 63, 83, 23, 32, 61, 62, 16, 15, 44, 98, 49, 4, 67, 55, 46, 13, 88, 29, 10, 78, 21, 73, 65, 18, 2, 39, 31, 91, 12, 84, 75, 48, 50, 60};

void swap(int *a, int *b) {
  int t = *a;
  *a = *b;
  *b = t;
}

void printList(int items[], int size) {
  for (int i = 0; i < size; i++) {
    // First item
    if (i == 0) {
      printf("[%d, ", items[i]);
    // Any other item
    } else if (i != size - 1) {
      printf("%d, ", items[i]);
    // Last item
    } else {
      printf("%d]", items[i]);
    }
  }
}
#endif /* common */
