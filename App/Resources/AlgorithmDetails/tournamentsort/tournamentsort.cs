using System;

class TournamentSort
{
  // A `ref` is either a player leaf, encoded as `-playerIndex` (so `ref <= 0`), or another
  // match node's root offset into `matches` (so `ref > 0`).
  static bool IsPlayer(int reference) => reference <= 0;
  static int MakePlayer(int index) => -index;

  static int GetWinner(int[] matches, int root) => matches[root];
  static int GetWinners(int[] matches, int root) => matches[root + 1];
  static int GetLosers(int[] matches, int root) => matches[root + 2];

  static void SetMatch(int[] matches, int root, int winner, int winners, int losers)
  {
    matches[root] = winner;
    matches[root + 1] = winners;
    matches[root + 2] = losers;
  }

  static int GetPlayer(int[] array, int[] matches, int reference) =>
    IsPlayer(reference) ? Math.Abs(reference) : GetWinner(matches, reference);

  static int MakeMatch(int[] array, int[] matches, int top, int bot, int root)
  {
    int topWinner = GetPlayer(array, matches, top);
    int botWinner = GetPlayer(array, matches, bot);
    if (array[topWinner] <= array[botWinner])
    {
      SetMatch(matches, root, topWinner, top, bot);
    }
    else
    {
      SetMatch(matches, root, botWinner, bot, top);
    }
    return root;
  }

  static int Knockout(int[] array, int[] matches, int i, int k, int root)
  {
    if (i == k)
      return MakePlayer(i);
    int mid = (i + k) / 2;
    int leftRef = Knockout(array, matches, i, mid, 2 * root);
    int rightRef = Knockout(array, matches, mid + 1, k, 2 * root + 3);
    return MakeMatch(array, matches, leftRef, rightRef, root);
  }

  static int Rebuild(int[] array, int[] matches, int root)
  {
    if (IsPlayer(GetWinners(matches, root)))
    {
      return GetLosers(matches, root);
    }
    matches[root + 1] = Rebuild(array, matches, GetWinners(matches, root));
    if (array[GetPlayer(array, matches, GetLosers(matches, root))] <
        array[GetPlayer(array, matches, GetWinners(matches, root))])
    {
      matches[root] = GetPlayer(array, matches, GetLosers(matches, root));
      int previousLosers = GetLosers(matches, root);
      matches[root + 2] = GetWinners(matches, root);
      matches[root + 1] = previousLosers;
    }
    else
    {
      matches[root] = GetPlayer(array, matches, GetWinners(matches, root));
    }
    return root;
  }

  static void Sort(int[] array)
  {
    int n = array.Length;
    if (n <= 1)
      return;

    int[] matches = new int[6 * n];
    int tourney = Knockout(array, matches, 0, n - 1, 3);

    int[] output = new int[n];
    for (int i = 0; i < n; i++)
    {
      output[i] = array[GetPlayer(array, matches, tourney)];
      tourney = IsPlayer(tourney) ? 0 : Rebuild(array, matches, tourney);
    }
    Array.Copy(output, array, n);
  }

  static void Main()
  {
    int[] array = { 0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56 };
    Sort(array);
    Console.WriteLine("[" + string.Join(", ", array) + "]");
  }
}