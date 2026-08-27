"""Core Nix evaluation engine: batch evaluation, dynamic scoping, and channel resolution."""

from core.eval.channels import (
    find_cache_pins_file,
    find_flake_dir,
    get_nix_env,
    normalize_channel_name,
    resolve_channel_input,
)
from core.eval.evaluator import (
    eval_nix_raw,
    evaluate_batch,
    evaluate_single_package,
    evaluate_upstream_package,
    resolve_target_to_store_path,
)
from core.eval.resolver import (
    build_nix_batch_eval_expression,
    compare_versions,
    extract_version_from_store_path,
    generate_candidate_names,
    is_path_in_nix_store,
)
from core.eval.system_eval import (
    evaluate_system_missing_paths,
    extract_missing_fods,
    get_system_hostname,
    get_system_toplevel_attr,
)

__all__ = [
    "find_flake_dir",
    "find_cache_pins_file",
    "get_nix_env",
    "resolve_channel_input",
    "normalize_channel_name",
    "extract_version_from_store_path",
    "is_path_in_nix_store",
    "compare_versions",
    "generate_candidate_names",
    "build_nix_batch_eval_expression",
    "eval_nix_raw",
    "evaluate_batch",
    "evaluate_single_package",
    "evaluate_upstream_package",
    "resolve_target_to_store_path",
    "get_system_hostname",
    "get_system_toplevel_attr",
    "evaluate_system_missing_paths",
    "extract_missing_fods",
]
