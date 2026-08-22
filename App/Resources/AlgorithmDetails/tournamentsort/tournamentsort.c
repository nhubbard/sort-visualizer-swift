#include <stdio.h>
#include <stdlib.h>

int array[16] = {0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56};

/* A `ref` is either a player leaf, encoded as `-playerIndex` (so `ref <= 0`),
 * or another match node's root offset into `matches` (so `ref > 0`). */
int isPlayer(int ref) { return ref <= 0; }
int makePlayer(int index) { return -index; }

int getWinner(int *matches, int root) { return matches[root]; }
int getWinners(int *matches, int root) { return matches[root + 1]; }
int getLosers(int *matches, int root) { return matches[root + 2]; }

void setMatch(int *matches, int root, int winner, int winners, int losers) {
  matches[root] = winner;
  matches[root + 1] = winners;
  matches[root + 2] = losers;
}

int getPlayer(int *arr, int *matches, int ref) {
  return isPlayer(ref) ? abs(ref) : getWinner(matches, ref);
}

int makeMatch(int *arr, int *matches, int top, int bot, int root) {
  int topWinner = getPlayer(arr, matches, top);
  int botWinner = getPlayer(arr, matches, bot);
  if (arr[topWinner] <= arr[botWinner]) {
    setMatch(matches, root, topWinner, top, bot);
  } else {
    setMatch(matches, root, botWinner, bot, top);
  }
  return root;
}

int knockout(int *arr, int *matches, int i, int k, int root) {
  if (i == k)
    return makePlayer(i);
  int mid = (i + k) / 2;
  int leftRef = knockout(arr, matches, i, mid, 2 * root);
  int rightRef = knockout(arr, matches, mid + 1, k, 2 * root + 3);
  return makeMatch(arr, matches, leftRef, rightRef, root);
}

int rebuild(int *arr, int *matches, int root) {
  if (isPlayer(getWinners(matches, root))) {
    return getLosers(matches, root);
  }
  matches[root + 1] = rebuild(arr, matches, getWinners(matches, root));
  if (arr[getPlayer(arr, matches, getLosers(matches, root))] <
      arr[getPlayer(arr, matches, getWinners(matches, root))]) {
    matches[root] = getPlayer(arr, matches, getLosers(matches, root));
    int previousLosers = getLosers(matches, root);
    matches[root + 2] = getWinners(matches, root);
    matches[root + 1] = previousLosers;
  } else {
    matches[root] = getPlayer(arr, matches, getWinners(matches, root));
  }
  return root;
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

void sort(int arr[], int n) {
  if (n <= 1)
    return;

  int *matches = calloc(6 * n, sizeof(int));
  int tourney = knockout(arr, matches, 0, n - 1, 3);

  int *output = malloc(n * sizeof(int));
  for (int i = 0; i < n; i++) {
    output[i] = arr[getPlayer(arr, matches, tourney)];
    tourney = isPlayer(tourney) ? 0 : rebuild(arr, matches, tourney);
  }
  for (int i = 0; i < n; i++) {
    arr[i] = output[i];
  }

  free(output);
  free(matches);
}

int main(int argc, char *argv[]) {
  int size = sizeof(array) / sizeof(array[0]);
  sort(array, size);
  printList(array, size);
  return 0;
}
