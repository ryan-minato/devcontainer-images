import pathlib

from invoke import task

from utils import (
    convert_str_to_dict,
    get_image_src_path,
    get_image_test_path,
    get_test_image_path,
)

NAME_SPACE = "ryanminato"


@task(iterable=["build_args"])
def build(
    c,
    image_name,
    force_name=None,
    tag="latest",
    stage: str | None = None,
    namespace=NAME_SPACE,
    build_args: list[str] | None = None,
    platform: str | None = None,
    extra_args: str | None = None,
    *,
    verbose: bool = False
):
    source_path = get_image_src_path(image_name)
    image_tag = force_name or f"{namespace}/{image_name}:{tag}"

    build_arg_dict = {}
    if build_args:
        build_arg_dict.update(convert_str_to_dict(build_args))
    build_args_str = " ".join(f"--build-arg {key}={value}" for key, value in build_arg_dict.items())

    c.run(
        f"docker buildx build "
        f"-t {image_tag} "
        f"{f'--target {stage}' if stage else ''} "
        f"{f'--platform {platform}' if platform else ''} "
        f"--build-arg VERBOSE={1 if verbose else 0} "
        f"{build_args_str} "
        f"{extra_args if extra_args else ''} "
        f"{source_path}"
        )


@task
def test(
    c, image_name,  force_name=None, tag="latest", namespace=NAME_SPACE, verbose=False
):
    image_test_path = get_image_test_path(image_name)
    test_image_path = get_test_image_path()

    image_tag = force_name or f"{namespace}/{image_name}:{tag}"

    c.run(
        "docker buildx build "
        "--output type=cacheonly "
        f"--build-arg IMAGE={image_tag} "
        f"--build-arg VERBOSE={1 if verbose else 0} "
        f"--build-context test_root={image_test_path.absolute()} "
        f"{test_image_path}"
    )


@task
def lock(c, in_file: str, out_file: str | None = None):
    in_file_path = pathlib.Path(in_file)
    if not in_file_path.exists() or not in_file_path.is_file():
        err = f"File not found: {in_file}"
        raise FileNotFoundError(err)

    if not in_file_path.suffix == ".in":
        err = f"Invalid file type: {in_file}"
        raise ValueError(err)

    out_file_path = (
        pathlib.Path(out_file) if out_file else in_file_path.with_suffix(".txt")
    )

    c.run(f"uv pip compile {in_file!s} -o {out_file_path!s}")


@task
def lock_deps(c, image_name: str):
    image_src_path = get_image_src_path(image_name)
    lock_files = image_src_path.glob("**/*.in")

    for lock_file in lock_files:
        lock(c, str(lock_file.absolute()))
