"""Backend type definitions and backend selection utilities."""

from __future__ import annotations

from enum import Enum
from typing import TYPE_CHECKING, Any, Protocol

import numpy as np
from numpy.typing import NDArray

from tensor_forge.errors import CuPyNotInstalledError, UnsupportedBackendError

if TYPE_CHECKING:
    try:
        import cupy as cp  # type: ignore

        type CuPyArray = cp.ndarray
    except ImportError as e:
        raise CuPyNotInstalledError("type_checking") from e
else:
    type CuPyArray = Any

type NumPyArray = NDArray[np.float64]
type Array = NumPyArray | CuPyArray


class Backend(Protocol):
    """Protocol describing an array backend."""

    float32: Any
    float64: Any

    def array(self, x: Any, dtype: Any = None) -> Array:
        """Create an array from input data."""
        ...

    def asarray(self, x: Any, dtype: Any = None) -> Array:
        """Convert input to an array."""
        ...

    def zeros_like(self, x: Any, dtype: Any = None) -> Array:
        """Create a zero-filled array with the same shape."""
        ...

    def ones_like(self, x: Any, dtype: Any = None) -> Array:
        """Create a one-filled array with the same shape."""
        ...

    def expand_dims(self, a: Array, axis: int | tuple[int, ...]) -> Array:
        """Expand array dimensions."""
        ...

    def broadcast_to(self, array: Array, shape: tuple[int, ...]) -> Array:
        """Broadcast an array to a target shape."""
        ...

    def reshape(self, a: Array, shape: tuple[int, ...]) -> Array:
        """Reshape an array."""
        ...

    def abs(self, x: Array) -> Array:
        """Compute absolute values."""
        ...

    def sign(self, x: Array) -> Array:
        """Compute elementwise signs."""
        ...

    def sqrt(self, x: Array) -> Array:
        """Compute square roots."""
        ...

    def log(self, x: Array) -> Array:
        """Compute natural logarithms."""
        ...

    def log1p(self, x: Array) -> Array:
        """Compute log(1 + x)."""
        ...

    def exp(self, x: Array) -> Array:
        """Compute exponentials."""
        ...

    def cos(self, x: Array) -> Array:
        """Compute cosines."""
        ...

    def sin(self, x: Array) -> Array:
        """Compute sines."""
        ...

    def tan(self, x: Array) -> Array:
        """Compute tangents."""
        ...

    def cosh(self, x: Array) -> Array:
        """Compute hyperbolic cosines."""
        ...

    def sinh(self, x: Array) -> Array:
        """Compute hyperbolic sines."""
        ...

    def tanh(self, x: Array) -> Array:
        """Compute hyperbolic tangents."""
        ...

    def arcsin(self, x: Array) -> Array:
        """Compute inverse sines."""
        ...

    def arccos(self, x: Array) -> Array:
        """Compute inverse cosines."""
        ...

    def arctan(self, x: Array) -> Array:
        """Compute inverse tangents."""
        ...

    def sum(
        self, x: Array, axis: int | tuple[int, ...] | None, keepdims: bool
    ) -> Array:
        """Sum array elements over given axes."""
        ...

    def mean(
        self, x: Array, axis: int | tuple[int, ...] | None, keepdims: bool
    ) -> Array:
        """Compute mean over given axes."""
        ...

    def max(
        self, x: Array, axis: int | tuple[int, ...] | None, keepdims: bool
    ) -> Array:
        """Compute maximum over given axes."""
        ...

    def min(
        self, x: Array, axis: int | tuple[int, ...] | None, keepdims: bool
    ) -> Array:
        """Compute minimum over given axes."""
        ...

    def matmul(self, x1: Array, x2: Array) -> Array:
        """Multiply arrays using matrix multiplication."""
        ...

    def outer(self, a: Array, b: Array) -> Array:
        """Compute the outer product."""
        ...

    def maximum(self, x1: Any, x2: Any) -> Array:
        """Compute elementwise maximum."""
        ...

    def where(self, condition: Any, x: Any, y: Any) -> Array:
        """Select values based on a condition."""
        ...


class DType(Enum):
    """Supported data types."""

    float32 = "float32"
    float64 = "float64"


def get_dtype(backend: Backend, dtype: DType) -> Any:
    """Get backend dtype object from enum.

    Args:
        backend (Backend): Backend module.
        dtype (DType): Data type enum.

    Returns:
        Any: Backend-specific dtype.
    """
    return getattr(backend, dtype.value)


def get_backend(title: str) -> Backend:
    """Return backend module by name.

    Args:
        title (str): Backend name.

    Returns:
        Backend: Selected backend module.

    Raises:
        RuntimeError: If CuPy backend is requested but CuPy is not installed.
        ValueError: If the backend name is not supported.
    """
    if title == "numpy":
        return np

    if title == "cupy":
        try:
            import cupy as cp  # type: ignore
        except ImportError as e:
            raise CuPyNotInstalledError("backend") from e
        return cp

    raise UnsupportedBackendError(title)
