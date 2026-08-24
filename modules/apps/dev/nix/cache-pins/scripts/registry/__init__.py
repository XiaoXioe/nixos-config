"""Registry package for managing cache-pins.nix storage, auditing usage, and adopting modules."""

from registry.adopt import adopt_module_pin, find_modules_referencing_pkg
from registry.audit import find_unused_pins
from registry.store import (
    delete_pin_entry,
    get_all_pin_keys,
    load_cache_pins,
    write_or_update_pin,
)

__all__ = [
    "adopt_module_pin",
    "delete_pin_entry",
    "find_modules_referencing_pkg",
    "find_unused_pins",
    "get_all_pin_keys",
    "load_cache_pins",
    "write_or_update_pin",
]
