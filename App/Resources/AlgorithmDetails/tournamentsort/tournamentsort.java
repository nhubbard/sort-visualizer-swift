import java.util.Arrays;

public final class tournamentsort {
  // A ref is either a player leaf, encoded as -playerIndex (so ref <= 0), or another match
  // node's root offset into matches (so ref > 0).
  static boolean isPlayer(int ref) {
    return ref <= 0;
  }

  static int makePlayer(int index) {
    return -index;
  }

  static int getWinner(int[] matches, int root) {
    return matches[root];
  }

  static int getWinners(int[] matches, int root) {
    return matches[root + 1];
  }

  static int getLosers(int[] matches, int root) {
    return matches[root + 2];
  }

  static void setMatch(int[] matches, int root, int winner, int winners, int losers) {
    matches[root] = winner;
    matches[root + 1] = winners;
    matches[root + 2] = losers;
  }

  static int getPlayer(int[] array, int[] matches, int ref) {
    return isPlayer(ref) ? Math.abs(ref) : getWinner(matches, ref);
  }

  static int makeMatch(int[] array, int[] matches, int top, int bot, int root) {
    int topWinner = getPlayer(array, matches, top);
    int botWinner = getPlayer(array, matches, bot);
    if (array[topWinner] <= array[botWinner]) {
      setMatch(matches, root, topWinner, top, bot);
    } else {
      setMatch(matches, root, botWinner, bot, top);
    }
    return root;
  }

  static int knockout(int[] array, int[] matches, int i, int k, int root) {
    if (i == k) {
      return makePlayer(i);
    }
    int mid = (i + k) / 2;
    int leftRef = knockout(array, matches, i, mid, 2 * root);
    int rightRef = knockout(array, matches, mid + 1, k, 2 * root + 3);
    return makeMatch(array, matches, leftRef, rightRef, root);
  }

  static int rebuild(int[] array, int[] matches, int root) {
    if (isPlayer(getWinners(matches, root))) {
      return getLosers(matches, root);
    }
    matches[root + 1] = rebuild(array, matches, getWinners(matches, root));
    if (array[getPlayer(array, matches, getLosers(matches, root))]
        < array[getPlayer(array, matches, getWinners(matches, root))]) {
      matches[root] = getPlayer(array, matches, getLosers(matches, root));
      int previousLosers = getLosers(matches, root);
      matches[root + 2] = getWinners(matches, root);
      matches[root + 1] = previousLosers;
    } else {
      matches[root] = getPlayer(array, matches, getWinners(matches, root));
    }
    return root;
  }

  static void sort(int[] array) {
    int n = array.length;
    if (n <= 1) {
      return;
    }

    int[] matches = new int[6 * n];
    int tourney = knockout(array, matches, 0, n - 1, 3);

    int[] output = new int[n];
    for (int i = 0; i < n; i++) {
      output[i] = array[getPlayer(array, matches, tourney)];
      tourney = isPlayer(tourney) ? 0 : rebuild(array, matches, tourney);
    }
    System.arraycopy(output, 0, array, 0, n);
  }

  public static void main(String[] args) {
    int[] array = {0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56};
    sort(array);
    System.out.println(Arrays.toString(array));
  }
}
