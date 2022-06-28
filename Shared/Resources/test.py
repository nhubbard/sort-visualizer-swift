import os
import shutil
import sys
import subprocess
import logging
import coloredlogs

algorithms = sorted([
    "quicksort",
    "mergesort",
    "heapsort",
    "bubblesort",
    "selectionsort",
    "insertionsort",
    "gnomesort",
    "shakersort",
    "oddevensort",
    "pancakesort",
    "bitonicsort",
    "radixsort",
    "shellsort",
    "combsort"
])
extensions = ["c", "cpp", "cs", "go", "java", "js", "kt", "py", "rb", "swift"]
standard_expected = "[0, 14, 21, 23, 32, 39, 51, 56, 62, 68, 69, 77, 81, 83, 90, 91]"
go_expected = standard_expected.replace(",", "")
success = []
logger = logging.getLogger()
logger.setLevel(logging.INFO)
coloredlogs.install(
    level="INFO", logger=logger, fmt="%(asctime)s %(levelname)s %(message)s"
)


def test_c(filename: str) -> bool:
    logger.debug(f"Testing {filename}")
    outfile = filename.replace(".c", "")
    logger.debug(f"Compiling {filename} into {outfile}")
    try:
        compiler = subprocess.run(
            " ".join(["clang", "-o", '"' + outfile + '"', '"' + filename + '"']),
            shell=True,
            check=True,
            capture_output=True,
        )
        compile_stdout = compiler.stdout.decode("utf-8")
        if compile_stdout != "":
            logger.debug(f"Compiler stdout:\n{compile_stdout}")
    except subprocess.CalledProcessError as e:
        logger.error(
            f"Compilation of {filename} failed! See next entry for error message."
        )
        logger.error(e.output.decode("utf-8").strip())
        sys.exit(1)
    logger.debug(f"Running ./{outfile}")
    output = (
        subprocess.run([f"./{outfile}"], shell=True, check=True, capture_output=True)
        .stdout.decode("utf-8")
        .strip()
    )
    if standard_expected != output:
        logger.error(
            f"{filename}: Failed! Expected {standard_expected}, found {output}"
        )
        if os.path.exists(outfile):
            logger.debug(f"Deleting {outfile}")
            os.remove(outfile)
        return False
    else:
        logger.info(f"{filename}: Passed!")
        if os.path.exists(outfile):
            logger.debug(f"Deleting {outfile}")
            os.remove(outfile)
        return True


def test_cpp(filename: str) -> bool:
    logger.debug(f"Testing {filename}")
    outfile = filename.replace(".cpp", "")
    logger.debug(f"Compiling {filename} into {outfile}")
    try:
        compiler = subprocess.run(
            " ".join(["clang++", "-o", f'"{outfile}"', f'"{filename}"']),
            shell=True,
            check=True,
            capture_output=True,
        )
        compile_stdout = compiler.stdout.decode("utf-8")
        if compile_stdout != "":
            logger.debug(f"Compiler stdout:\n{compile_stdout}")
    except subprocess.CalledProcessError as e:
        logger.error(
            f"Compilation of {filename} failed! See next entry for error message."
        )
        logger.error(e.output.decode("utf-8").strip())
        sys.exit(1)
    logger.debug(f"Running ./{outfile}")
    output = (
        subprocess.run([f"./{outfile}"], shell=True, check=True, capture_output=True)
        .stdout.decode("utf-8")
        .strip()
    )
    if standard_expected != output:
        logger.error(
            f"{filename}: Failed! Expected {standard_expected}, found {output}"
        )
        if os.path.exists(outfile):
            logger.debug(f"Deleting {outfile}")
            os.remove(outfile)
        return False
    else:
        logger.info(f"{filename}: Passed!")
        if os.path.exists(outfile):
            logger.debug(f"Deleting {outfile}")
            os.remove(outfile)
        return True


def test_cs(filename: str) -> bool:
    logger.debug(f"Testing {filename}")
    outfile = filename.replace(".cs", ".exe")
    logger.debug(f"Compiling {filename} into {outfile}")
    try:
        subprocess.run(
            " ".join(["csc", f'-out:"{outfile}"', f'"{filename}"']),
            shell=True,
            check=True,
            capture_output=True,
        )
    except subprocess.CalledProcessError as e:
        logger.error(
            f"Compilation of {filename} failed! See next entry for error message."
        )
        logger.error(e.output.decode("utf-8").strip())
        sys.exit(1)
    logger.debug(f"Running ./{outfile}")
    output = (
        subprocess.run(
            " ".join(["mono", outfile]), shell=True, check=True, capture_output=True
        )
        .stdout.decode("utf-8")
        .strip()
    )
    if standard_expected != output:
        logger.error(
            f"{filename}: Failed! Expected {standard_expected}, found {output}"
        )
        if os.path.exists(outfile):
            logger.debug(f"Deleting {outfile}")
            os.remove(outfile)
        return False
    else:
        logger.info(f"{filename}: Passed!")
        if os.path.exists(outfile):
            logger.debug(f"Deleting {outfile}")
            os.remove(outfile)
        return True


def test_go(filename: str) -> bool:
    logger.debug(f"Running ./{filename}")
    try:
        output = (
            subprocess.run(
                " ".join(["go", "run", filename]),
                shell=True,
                check=True,
                capture_output=True,
            )
            .stdout.decode("utf-8")
            .strip()
        )
        if go_expected != output:
            logger.error(f"{filename}: Failed! Expected {go_expected}, found {output}")
            return False
        else:
            logger.info(f"{filename}: Passed!")
            return True
    except subprocess.CalledProcessError as e:
        logger.error(f"Failed to execute {filename}! See next entry for error message.")
        logger.error(e.output.decode("utf-8").strip())
        sys.exit(1)


def test_java(filename: str) -> bool:
    logger.debug(f"Testing {filename}")
    classpath = '"' + filename.split("/")[0] + '/"'
    outfile = filename.replace(".java", ".class")
    logger.debug(f"Compiling {filename} into {outfile}")
    try:
        compiler = subprocess.run(
            " ".join(["javac", filename]), shell=True, check=True, capture_output=True
        )
        compile_stdout = compiler.stdout.decode("utf-8")
        if compile_stdout != "":
            logger.debug(f"Compiler stdout:\n{compile_stdout}")
    except subprocess.CalledProcessError as e:
        logger.error(
            f"Compilation of {filename} failed! See next entry for error message."
        )
        logger.error(e.output.decode("utf-8").strip())
        sys.exit(1)
    logger.debug(f"Running ./{outfile}")
    output = (
        subprocess.run(
            " ".join(
                ["java", "-cp", classpath, filename.split("/")[1].replace(".java", "")]
            ),
            shell=True,
            check=True,
            capture_output=True,
        )
        .stdout.decode("utf-8")
        .strip()
    )
    if standard_expected != output:
        logger.error(
            f"{filename}: Failed! Expected {standard_expected}, found {output}"
        )
        if os.path.exists(outfile):
            logger.debug(f"Deleting {outfile}")
            os.remove(outfile)
        return False
    else:
        logger.info(f"{filename}: Passed!")
        if os.path.exists(outfile):
            logger.debug(f"Deleting {outfile}")
            os.remove(outfile)
        return True


def test_js(filename: str) -> bool:
    logger.debug(f"Running {filename}")
    try:
        output = (
            subprocess.run(
                " ".join(["node", filename]),
                shell=True,
                check=True,
                capture_output=True,
            )
            .stdout.decode("utf-8")
            .strip()
        )
        if standard_expected != output:
            logger.error(
                f"{filename}: Failed! Expected {standard_expected}, found {output}"
            )
            return False
        else:
            logger.info(f"{filename}: Passed!")
            return True
    except subprocess.CalledProcessError as e:
        logger.error(f"Failed to run {filename}! See next entry for error message.")
        logger.error(e.output.decode("utf-8").strip())
        sys.exit(1)


def test_kt(filename: str) -> bool:
    logger.debug(f"Testing {filename}")
    outfile = filename.split("/")[1].capitalize().replace(".kt", "Kt")
    classfile = outfile + ".class"
    metafolder = os.path.abspath("./META-INF")
    logger.debug(f"Compiling {filename} into {outfile}")
    try:
        compiler = subprocess.run(
            " ".join(["kotlinc", filename]), shell=True, check=True, capture_output=True
        )
        compile_stdout = compiler.stdout.decode("utf-8")
        if compile_stdout != "":
            logger.debug(f"Compiler stdout:\n{compile_stdout}")
    except subprocess.CalledProcessError as e:
        logger.error(
            f"Compilation of {filename} failed! See next entry for error message."
        )
        logger.error(e.output.decode("utf-8").strip())
        sys.exit(1)
    logger.debug(f"Running ./{outfile}")
    output = (
        subprocess.run(
            " ".join(["kotlin", outfile]), shell=True, check=True, capture_output=True
        )
        .stdout.decode("utf-8")
        .strip()
    )
    if standard_expected != output:
        logger.error(
            f"{filename}: Failed! Expected {standard_expected}, found {output}"
        )
        if os.path.exists(classfile):
            logger.debug(f"Deleting {classfile}")
            os.remove(classfile)
        if os.path.exists(metafolder) and os.path.isdir(metafolder):
            logger.debug("Deleting META-INF")
            shutil.rmtree(metafolder)
        return False
    else:
        logger.info(f"{filename}: Passed!")
        if os.path.exists(classfile):
            logger.debug(f"Deleting {classfile}")
            os.remove(classfile)
        if os.path.exists(metafolder) and os.path.isdir(metafolder):
            logger.debug("Deleting META-INF")
            shutil.rmtree(metafolder)
        return True


def test_py(filename: str) -> bool:
    logger.debug(f"Running {filename}")
    try:
        output = (
            subprocess.run(
                " ".join(["python3", filename]),
                shell=True,
                check=True,
                capture_output=True,
            )
            .stdout.decode("utf-8")
            .strip()
        )
        if standard_expected != output:
            logger.error(
                f"{filename}: Failed! Expected {standard_expected}, found {output}"
            )
            return False
        else:
            logger.info(f"{filename}: Passed!")
            return True
    except subprocess.CalledProcessError as e:
        logger.error(f"Failed to run {filename}! See next entry for error message.")
        logger.error(e.output.decode("utf-8").strip())
        sys.exit(1)


def test_rb(filename: str) -> bool:
    logger.debug(f"Running {filename}")
    try:
        output = (
            subprocess.run(
                " ".join(["/opt/homebrew/opt/ruby/bin/ruby", filename]),
                shell=True,
                check=True,
                capture_output=True,
            )
            .stdout.decode("utf-8")
            .strip()
        )
        if standard_expected != output:
            logger.error(
                f"{filename}: Failed! Expected {standard_expected}, found {output}"
            )
            return False
        else:
            logger.info(f"{filename}: Passed!")
            return True
    except subprocess.CalledProcessError as e:
        logger.error(f"Failed to run {filename}! See next entry for error message.")
        logger.error(e.output.decode("utf-8").strip())
        sys.exit(1)


def test_swift(filename: str) -> bool:
    logger.debug(f"Testing {filename}")
    outfile = filename.split("/")[1].replace(".swift", "")
    logger.debug(f"Compiling {filename} into {outfile}")
    try:
        compiler = subprocess.run(
            " ".join(["swiftc", filename]), shell=True, check=True, capture_output=True
        )
        compile_stdout = compiler.stdout.decode("utf-8")
        if compile_stdout != "":
            logger.debug(f"Compiler stdout:\n{compile_stdout}")
    except subprocess.CalledProcessError as e:
        logger.error(
            f"Compilation of {filename} failed! See next entry for error message."
        )
        logger.error(e.output.decode("utf-8").strip())
        sys.exit(1)
    logger.debug(f"Running ./{outfile}")
    output = (
        subprocess.run(f"./{outfile}", shell=True, check=True, capture_output=True)
        .stdout.decode("utf-8")
        .strip()
    )
    if standard_expected != output:
        logger.error(
            f"{filename}: Failed! Expected {standard_expected}, found {output}"
        )
        if os.path.exists(outfile):
            logger.debug(f"Deleting {outfile}")
            os.remove(outfile)
        return False
    else:
        logger.info(f"{filename}: Passed!")
        if os.path.exists(outfile):
            logger.debug(f"Deleting {outfile}")
            os.remove(outfile)
        return True


if __name__ == "__main__":
    # Create list of files to test
    files = []
    if len(sys.argv) > 1:
        algorithm = sys.argv[1]
        for extension in extensions:
            files.append(f"{algorithm}.bundle/{algorithm}.{extension}")
    else:
        for algorithm in algorithms:
            for extension in extensions:
                files.append(f"{algorithm}.bundle/{algorithm}.{extension}")
    # Loop over each file
    for file in files:
        ext = file.split(".")[-1]
        if ext == "c":
            success.append(test_c(file))
        elif ext == "cpp":
            success.append(test_cpp(file))
        elif ext == "cs":
            success.append(test_cs(file))
        elif ext == "go":
            success.append(test_go(file))
        elif ext == "java":
            success.append(test_java(file))
        elif ext == "js":
            success.append(test_js(file))
        elif ext == "kt":
            success.append(test_kt(file))
        elif ext == "py":
            success.append(test_py(file))
        elif ext == "rb":
            success.append(test_rb(file))
        elif ext == "swift":
            success.append(test_swift(file))
    # Loop over success results.
    if all(success):
        logger.info("All files compiled and/or run successfully with correct outputs.")
    else:
        logger.error("One or more files compiled and/or run unsuccessfully. Check the log for errors.")