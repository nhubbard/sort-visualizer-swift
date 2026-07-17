import ast
import functools
import os
import re
import shutil
import sys
import subprocess
import logging
import coloredlogs

from concurrent.futures import ThreadPoolExecutor, as_completed

root = os.path.dirname(os.path.abspath(__file__))
algorithms = sorted(
    entry.name
    for entry in os.scandir(root)
    if entry.is_dir()
    and entry.name != "template"
    and entry.name != "__pycache__"
    and not entry.name.startswith(".")
)
extensions = ["c", "cpp", "cs", "go", "java", "js", "kt", "py", "rb", "swift"]
logger = logging.getLogger()
logger.setLevel(logging.INFO)
coloredlogs.install(
    level="INFO", logger=logger, fmt="%(asctime)s %(levelname)s %(message)s"
)


@functools.lru_cache(maxsize=None)
def get_expected(algorithm: str) -> str:
    """Derives the expected sorted-output string for an algorithm from the literal
    `array = [...]` declared in that algorithm's own Python reference implementation.

    Some algorithms (mostly bogosort-family combinatorial ones) use a shortened
    input array so they finish in reasonable time, so there's no single expected
    output shared across all algorithms; each one's expected value is whatever its
    own array sorts to.
    """
    py_path = os.path.join(root, algorithm, f"{algorithm}.py")
    with open(py_path) as fp:
        source = fp.read()
    match = re.search(r"array\s*=\s*(\[[^\]]*\])", source)
    if not match:
        raise ValueError(f"Could not find an `array = [...]` literal in {py_path}")
    values = ast.literal_eval(match.group(1))
    return "[" + ", ".join(str(v) for v in sorted(values)) + "]"


def test_c(filename: str) -> bool:
    algorithm, basename = filename.split("/")
    algo_dir = os.path.join(root, algorithm)
    outfile = basename.replace(".c", "")
    outpath = os.path.join(algo_dir, outfile)
    logger.debug(f"Testing {filename}")
    logger.debug(f"Compiling {filename} into {outfile}")
    try:
        compiler = subprocess.run(
            ["clang", "-o", outfile, basename],
            cwd=algo_dir,
            check=True,
            capture_output=True,
        )
        compile_stdout = compiler.stdout.decode("utf-8")
        if compile_stdout != "":
            logger.debug(f"Compiler stdout:\n{compile_stdout}")
    except subprocess.CalledProcessError as e:
        logger.error(
            f"Compilation of {filename} failed! See next entry for error message(s)."
        )
        logger.error(e.stdout.decode("utf-8").strip())
        logger.error(e.stderr.decode("utf-8").strip())
        return False
    logger.debug(f"Running ./{outfile}")
    try:
        output = (
            subprocess.run(
                [f"./{outfile}"], cwd=algo_dir, check=True, capture_output=True
            )
            .stdout.decode("utf-8")
            .strip()
        )
    except subprocess.CalledProcessError as e:
        logger.error(f"Failed to run {filename}! See next entry for error message.")
        logger.error(e.stdout.decode("utf-8").strip())
        logger.error(e.stderr.decode("utf-8").strip())
        if os.path.exists(outpath):
            os.remove(outpath)
        return False
    expected = get_expected(algorithm)
    if expected != output:
        logger.error(f"{filename}: Failed! Expected {expected}, found {output}")
        passed = False
    else:
        logger.info(f"{filename}: Passed!")
        passed = True
    if os.path.exists(outpath):
        logger.debug(f"Deleting {outfile}")
        os.remove(outpath)
    return passed


def test_cpp(filename: str) -> bool:
    algorithm, basename = filename.split("/")
    algo_dir = os.path.join(root, algorithm)
    outfile = basename.replace(".cpp", "")
    outpath = os.path.join(algo_dir, outfile)
    logger.debug(f"Testing {filename}")
    logger.debug(f"Compiling {filename} into {outfile}")
    try:
        compiler = subprocess.run(
            ["clang++", "-o", outfile, basename],
            cwd=algo_dir,
            check=True,
            capture_output=True,
        )
        compile_stdout = compiler.stdout.decode("utf-8")
        if compile_stdout != "":
            logger.debug(f"Compiler stdout:\n{compile_stdout}")
    except subprocess.CalledProcessError as e:
        logger.error(
            f"Compilation of {filename} failed! See next entry for error message(s)."
        )
        logger.error(e.stdout.decode("utf-8").strip())
        logger.error(e.stderr.decode("utf-8").strip())
        return False
    logger.debug(f"Running ./{outfile}")
    try:
        output = (
            subprocess.run(
                [f"./{outfile}"], cwd=algo_dir, check=True, capture_output=True
            )
            .stdout.decode("utf-8")
            .strip()
        )
    except subprocess.CalledProcessError as e:
        logger.error(f"Failed to run {filename}! See next entry for error message.")
        logger.error(e.stdout.decode("utf-8").strip())
        logger.error(e.stderr.decode("utf-8").strip())
        if os.path.exists(outpath):
            os.remove(outpath)
        return False
    expected = get_expected(algorithm)
    if expected != output:
        logger.error(f"{filename}: Failed! Expected {expected}, found {output}")
        passed = False
    else:
        logger.info(f"{filename}: Passed!")
        passed = True
    if os.path.exists(outpath):
        logger.debug(f"Deleting {outfile}")
        os.remove(outpath)
    return passed


def test_cs(filename: str) -> bool:
    algorithm, basename = filename.split("/")
    algo_dir = os.path.join(root, algorithm)
    logger.debug(f"Testing {filename}")
    try:
        output = (
            subprocess.run(
                ["dotnet", "run", "--file", basename],
                cwd=algo_dir,
                check=True,
                capture_output=True,
            )
            .stdout.decode("utf-8")
            .strip()
        )
    except subprocess.CalledProcessError as e:
        logger.error(f"Failed to run {filename}! See next entry for error message.")
        logger.error(e.stdout.decode("utf-8").strip())
        logger.error(e.stderr.decode("utf-8").strip())
        return False
    expected = get_expected(algorithm)
    if expected != output:
        logger.error(f"{filename}: Failed! Expected {expected}, found {output}")
        return False
    else:
        logger.info(f"{filename}: Passed!")
        return True


def test_go(filename: str) -> bool:
    algorithm, basename = filename.split("/")
    algo_dir = os.path.join(root, algorithm)
    logger.debug(f"Running ./{filename}")
    try:
        output = (
            subprocess.run(
                ["go", "run", basename], cwd=algo_dir, check=True, capture_output=True
            )
            .stdout.decode("utf-8")
            .strip()
        )
    except subprocess.CalledProcessError as e:
        logger.error(f"Failed to execute {filename}! See next entry for error message.")
        logger.error(e.stdout.decode("utf-8").strip())
        logger.error(e.stderr.decode("utf-8").strip())
        return False
    expected = get_expected(algorithm).replace(",", "")
    if expected != output:
        logger.error(f"{filename}: Failed! Expected {expected}, found {output}")
        return False
    else:
        logger.info(f"{filename}: Passed!")
        return True


def test_java(filename: str) -> bool:
    algorithm, basename = filename.split("/")
    algo_dir = os.path.join(root, algorithm)
    classname = basename.replace(".java", "")
    outpath = os.path.join(algo_dir, classname + ".class")
    logger.debug(f"Testing {filename}")
    logger.debug(f"Compiling {filename} into {classname}.class")
    try:
        compiler = subprocess.run(
            ["javac", basename], cwd=algo_dir, check=True, capture_output=True
        )
        compile_stdout = compiler.stdout.decode("utf-8")
        if compile_stdout != "":
            logger.debug(f"Compiler stdout:\n{compile_stdout}")
    except subprocess.CalledProcessError as e:
        logger.error(
            f"Compilation of {filename} failed! See next entry for error message(s)."
        )
        logger.error(e.stdout.decode("utf-8").strip())
        logger.error(e.stderr.decode("utf-8").strip())
        return False
    logger.debug(f"Running {classname}")
    try:
        output = (
            subprocess.run(
                ["java", "-cp", ".", classname],
                cwd=algo_dir,
                check=True,
                capture_output=True,
            )
            .stdout.decode("utf-8")
            .strip()
        )
    except subprocess.CalledProcessError as e:
        logger.error(f"Failed to run {filename}! See next entry for error message.")
        logger.error(e.stdout.decode("utf-8").strip())
        logger.error(e.stderr.decode("utf-8").strip())
        if os.path.exists(outpath):
            os.remove(outpath)
        return False
    expected = get_expected(algorithm)
    if expected != output:
        logger.error(f"{filename}: Failed! Expected {expected}, found {output}")
        passed = False
    else:
        logger.info(f"{filename}: Passed!")
        passed = True
    if os.path.exists(outpath):
        logger.debug(f"Deleting {classname}.class")
        os.remove(outpath)
    return passed


def test_js(filename: str) -> bool:
    algorithm, basename = filename.split("/")
    algo_dir = os.path.join(root, algorithm)
    logger.debug(f"Running {filename}")
    try:
        output = (
            subprocess.run(
                ["node", basename], cwd=algo_dir, check=True, capture_output=True
            )
            .stdout.decode("utf-8")
            .strip()
        )
    except subprocess.CalledProcessError as e:
        logger.error(f"Failed to run {filename}! See next entry for error message.")
        logger.error(e.stdout.decode("utf-8").strip())
        logger.error(e.stderr.decode("utf-8").strip())
        return False
    expected = get_expected(algorithm)
    if expected != output:
        logger.error(f"{filename}: Failed! Expected {expected}, found {output}")
        return False
    else:
        logger.info(f"{filename}: Passed!")
        return True


def test_kt(filename: str) -> bool:
    algorithm, basename = filename.split("/")
    algo_dir = os.path.join(root, algorithm)
    # kotlinc writes .class files and a META-INF/ folder into its cwd, so we run it
    # with cwd=algo_dir to keep each algorithm's build artifacts isolated from every
    # other algorithm's concurrently-running kotlinc/kotlin invocation.
    outfile = basename.capitalize().replace(".kt", "Kt")
    classpath = os.path.join(algo_dir, outfile + ".class")
    bogo_extra_path = os.path.join(algo_dir, "BogosortKt$isSorted$1.class")
    metafolder = os.path.join(algo_dir, "META-INF")

    def cleanup():
        if os.path.exists(classpath):
            logger.debug(f"Deleting {outfile}.class")
            os.remove(classpath)
        # Bogosort impl produces 2 class files for whatever reason.
        if os.path.exists(bogo_extra_path):
            logger.debug("Deleting BogosortKt$isSorted$1.class")
            os.remove(bogo_extra_path)
        if os.path.exists(metafolder) and os.path.isdir(metafolder):
            logger.debug("Deleting META-INF")
            shutil.rmtree(metafolder)

    logger.debug(f"Testing {filename}")
    logger.debug(f"Compiling {filename} into {outfile}")
    try:
        compiler = subprocess.run(
            ["kotlinc", basename], cwd=algo_dir, check=True, capture_output=True
        )
        compile_stdout = compiler.stdout.decode("utf-8")
        if compile_stdout != "":
            logger.debug(f"Compiler stdout:\n{compile_stdout}")
    except subprocess.CalledProcessError as e:
        logger.error(
            f"Compilation of {filename} failed! See next entry for error message(s)."
        )
        logger.error(e.stdout.decode("utf-8").strip())
        logger.error(e.stderr.decode("utf-8").strip())
        cleanup()
        return False
    logger.debug(f"Running {outfile}")
    try:
        output = (
            subprocess.run(
                ["kotlin", outfile], cwd=algo_dir, check=True, capture_output=True
            )
            .stdout.decode("utf-8")
            .strip()
        )
    except subprocess.CalledProcessError as e:
        logger.error(f"Failed to run {filename}! See next entry for error message.")
        logger.error(e.stdout.decode("utf-8").strip())
        logger.error(e.stderr.decode("utf-8").strip())
        cleanup()
        return False
    expected = get_expected(algorithm)
    if expected != output:
        logger.error(f"{filename}: Failed! Expected {expected}, found {output}")
        passed = False
    else:
        logger.info(f"{filename}: Passed!")
        passed = True
    cleanup()
    return passed


def test_py(filename: str) -> bool:
    algorithm, basename = filename.split("/")
    algo_dir = os.path.join(root, algorithm)
    logger.debug(f"Running {filename}")
    try:
        output = (
            subprocess.run(
                ["python3", basename], cwd=algo_dir, check=True, capture_output=True
            )
            .stdout.decode("utf-8")
            .strip()
        )
    except subprocess.CalledProcessError as e:
        logger.error(f"Failed to run {filename}! See next entry for error message.")
        logger.error(e.stdout.decode("utf-8").strip())
        logger.error(e.stderr.decode("utf-8").strip())
        return False
    expected = get_expected(algorithm)
    if expected != output:
        logger.error(f"{filename}: Failed! Expected {expected}, found {output}")
        return False
    else:
        logger.info(f"{filename}: Passed!")
        return True


def test_rb(filename: str) -> bool:
    algorithm, basename = filename.split("/")
    algo_dir = os.path.join(root, algorithm)
    logger.debug(f"Running {filename}")
    try:
        output = (
            subprocess.run(
                ["/opt/homebrew/opt/ruby/bin/ruby", basename],
                cwd=algo_dir,
                check=True,
                capture_output=True,
            )
            .stdout.decode("utf-8")
            .strip()
        )
    except subprocess.CalledProcessError as e:
        logger.error(f"Failed to run {filename}! See next entry for error message.")
        logger.error(e.stdout.decode("utf-8").strip())
        logger.error(e.stderr.decode("utf-8").strip())
        return False
    expected = get_expected(algorithm)
    if expected != output:
        logger.error(f"{filename}: Failed! Expected {expected}, found {output}")
        return False
    else:
        logger.info(f"{filename}: Passed!")
        return True


def test_swift(filename: str) -> bool:
    algorithm, basename = filename.split("/")
    algo_dir = os.path.join(root, algorithm)
    outfile = basename.replace(".swift", "")
    outpath = os.path.join(algo_dir, outfile)
    logger.debug(f"Testing {filename}")
    logger.debug(f"Compiling {filename} into {outfile}")
    try:
        compiler = subprocess.run(
            ["swiftc", "-o", outfile, basename],
            cwd=algo_dir,
            check=True,
            capture_output=True,
        )
        compile_stdout = compiler.stdout.decode("utf-8")
        if compile_stdout != "":
            logger.debug(f"Compiler stdout:\n{compile_stdout}")
    except subprocess.CalledProcessError as e:
        logger.error(
            f"Compilation of {filename} failed! See next entry for error message(s)."
        )
        logger.error(e.stdout.decode("utf-8").strip())
        logger.error(e.stderr.decode("utf-8").strip())
        return False
    logger.debug(f"Running ./{outfile}")
    try:
        output = (
            subprocess.run(
                [f"./{outfile}"], cwd=algo_dir, check=True, capture_output=True
            )
            .stdout.decode("utf-8")
            .strip()
        )
    except subprocess.CalledProcessError as e:
        logger.error(f"Failed to run {filename}! See next entry for error message.")
        logger.error(e.stdout.decode("utf-8").strip())
        logger.error(e.stderr.decode("utf-8").strip())
        if os.path.exists(outpath):
            os.remove(outpath)
        return False
    expected = get_expected(algorithm)
    if expected != output:
        logger.error(f"{filename}: Failed! Expected {expected}, found {output}")
        passed = False
    else:
        logger.info(f"{filename}: Passed!")
        passed = True
    if os.path.exists(outpath):
        logger.debug(f"Deleting {outfile}")
        os.remove(outpath)
    return passed


TESTERS = {
    "c": test_c,
    "cpp": test_cpp,
    "cs": test_cs,
    "go": test_go,
    "java": test_java,
    "js": test_js,
    "kt": test_kt,
    "py": test_py,
    "rb": test_rb,
    "swift": test_swift,
}


def run_algorithm_tests(algorithm: str) -> list[bool]:
    """Runs every extension's test for a single algorithm, in order.

    This must stay sequential *within* an algorithm: the C, C++, and Swift files
    for one algorithm all compile to the same output filename in that algorithm's
    directory, so running two of them at once would let one clobber the other's
    binary mid-run. Parallelism is applied across algorithms instead, since each
    algorithm's directory is otherwise self-contained.
    """
    return [
        TESTERS[extension](f"{algorithm}/{algorithm}.{extension}")
        for extension in extensions
    ]


if __name__ == "__main__":
    target_algorithms = [sys.argv[1]] if len(sys.argv) > 1 else algorithms
    max_workers = min(12, os.cpu_count() or 4)

    success = []
    with ThreadPoolExecutor(max_workers=max_workers) as executor:
        futures = {
            executor.submit(run_algorithm_tests, algorithm): algorithm
            for algorithm in target_algorithms
        }
        for future in as_completed(futures):
            algorithm = futures[future]
            try:
                success.extend(future.result())
            except Exception:
                logger.exception(f"Unhandled exception while testing {algorithm}")
                success.append(False)

    if all(success):
        logger.info("All files compiled and/or run successfully with correct outputs.")
    else:
        logger.error(
            "One or more files compiled and/or run unsuccessfully. Check the log for errors."
        )
        sys.exit(1)
