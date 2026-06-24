"""Helper utilities for tensor operations."""

from __future__ import annotations

from typing import TYPE_CHECKING

from numpy.typing import ArrayLike

if TYPE_CHECKING:
    from tensor_forge.tensor import Tensor


def ensure_tensor(other: Tensor | ArrayLike, backend_title: str) -> Tensor:
    """Convert input to a tensor and align its backend.

    Args:
        other (Tensor | ArrayLike): Tensor or array-like input.
        backend_title (str): Target backend name.

    Returns:
        Tensor: Normalized tensor.
    """
    from tensor_forge.tensor import Tensor

    if isinstance(other, Tensor):
        other.change_backend(backend_title)
        return other

    return Tensor(other, backend_title=backend_title)
