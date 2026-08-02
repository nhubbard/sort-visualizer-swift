import java.util.Arrays;

public class simplisticgravitysort {
  private static void transferTo(int[] arr, int[] aux, int minValue, int index) {
    int pointer = 0;
    while (arr[index] > minValue) {
      arr[index]--;
      aux[pointer]++;
      pointer++;
    }
  }

  private static void transferFrom(int[] arr, int[] aux, int auxLength, int index) {
    int pointer = 0;
    while (pointer < auxLength && aux[pointer] != 0) {
      arr[index]++;
      aux[pointer]--;
      pointer++;
    }
  }

  public static void sort(int[] arr) {
    int n = arr.length;
    if (n == 0) {
      return;
    }

    int minValue = arr[0];
    int maxValue = arr[0];
    for (int i = 1; i < n; i++) {
      if (arr[i] < minValue) {
        minValue = arr[i];
      }
      if (arr[i] > maxValue) {
        maxValue = arr[i];
      }
    }
    int auxLength = maxValue - minValue;
    int[] aux = new int[auxLength];

    for (int i = 0; i < n; i++) {
      transferTo(arr, aux, minValue, i);
    }
    for (int i = n - 1; i >= 0; i--) {
      transferFrom(arr, aux, auxLength, i);
    }
  }

  public static void main(String[] args) {
    int[] array = new int[] {0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56};
    sort(array);
    System.out.println(Arrays.toString(array));
  }
}
