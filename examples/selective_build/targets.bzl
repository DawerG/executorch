load("@fbsource//xplat/executorch/build:runtime_wrapper.bzl", "get_oss_build_kwargs", "runtime")
load("@fbsource//xplat/executorch/codegen:codegen.bzl", "et_operator_library", "executorch_generated_lib")

def define_common_targets():
    """Defines targets that should be shared between fbcode and xplat.

    The directory containing this targets.bzl file should also contain both
    TARGETS and BUCK files that call this function.
    """

    # Select all ops: register all the ops in portable/functions.yaml
    et_operator_library(
        name = "select_all_ops",
        include_all_operators = True,
    )

    executorch_generated_lib(
        name = "select_all_lib",
        functions_yaml_target = "//executorch/kernels/portable:functions.yaml",
        deps = [
            "//executorch/kernels/portable:operators",
            ":select_all_ops",
        ],
    )

    # Select a list of operators: defined in `ops`
    et_operator_library(
        name = "select_ops_in_list",
        ops = [
            "aten::add.out",
            "aten::mm.out",
        ],
    )

    executorch_generated_lib(
        name = "select_ops_in_list_lib",
        functions_yaml_target = "//executorch/kernels/portable:functions.yaml",
        deps = [
            "//executorch/kernels/portable:operators",
            ":select_ops_in_list",
        ],
    )

    # Select all ops from a yaml file
    et_operator_library(
        name = "select_ops_from_yaml",
        ops_schema_yaml_target = "//executorch/examples/portable/custom_ops:custom_ops.yaml",
    )

    executorch_generated_lib(
        name = "select_ops_from_yaml_lib",
        custom_ops_yaml_target = "//executorch/examples/portable/custom_ops:custom_ops.yaml",
        deps = [
            "//executorch/examples/portable/custom_ops:custom_ops_1",
            "//executorch/examples/portable/custom_ops:custom_ops_2",
            ":select_ops_from_yaml",
        ],
    )

    # Select all ops from a given model
    # TODO(larryliu0820): Add this

    # ~~~ Test binary for selective build ~~~
    select_ops = native.read_config("executorch", "select_ops", None)
    lib = []
    if select_ops == "all":
        lib.append(":select_all_lib")
    elif select_ops == "list":
        lib.append(":select_ops_in_list_lib")
    elif select_ops == "yaml":
        lib.append(":select_ops_from_yaml_lib")
    runtime.cxx_binary(
        name = "selective_build_test",
        srcs = [],
        deps = [
            "//executorch/examples/portable/executor_runner:executor_runner_lib",
        ] + lib,
        define_static_target = True,
        **get_oss_build_kwargs()
    )
