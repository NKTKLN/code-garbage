"""Custom exception types for tensor and backend operations."""


class TensorError(Exception):
    """Base class for all tensor-related errors."""


class BackendError(TensorError):
    """Base class for backend-related errors."""


class CuPyNotInstalledError(BackendError, RuntimeError):
    """Raised when CuPy is required but not available."""

    TYPE_CHECKING_MSG = "CuPy type checking is enabled, but CuPy is not installed."
    BACKEND_MSG = "CuPy backend requested, but CuPy is not installed."
    DEFAULT_MSG = "CuPy is required, but not installed."

    def __init__(self, message: str | None = None) -> None:
        """Initialize error.

        Args:
            message: Optional custom message. Defaults to DEFAULT_MSG.
        """
        super().__init__(message or self.DEFAULT_MSG)


class UnsupportedBackendError(BackendError, ValueError):
    """Raised when an unknown backend is requested."""

    def __init__(
        self,
        backend: str,
        supported: tuple[str, ...] = ("numpy", "cupy"),
    ) -> None:
        """Initialize error.

        Args:
            backend: Requested backend name.
            supported: Allowed backend names.
        """
        supported_str = ", ".join(repr(name) for name in supported)
        message = f"Unsupported backend {backend!r}. Expected one of: {supported_str}."
        super().__init__(message)


class ShapeMismatchError(TensorError, ValueError):
    """Raised when tensor shapes are incompatible."""

    def __init__(self, grad_shape: object, tensor_shape: object) -> None:
        """Initialize error.

        Args:
            grad_shape: Gradient shape.
            tensor_shape: Target tensor shape.
        """
        message = (
            f"Gradient shape {grad_shape} does not match tensor shape {tensor_shape}."
        )
        super().__init__(message)


class InvalidMatmulDimensionError(TensorError, ValueError):
    """Raised when matmul is called with unsupported dimensions.

    Only 1D and 2D tensors are supported.
    """

    def __init__(self, a_ndim: int, b_ndim: int) -> None:
        """Initialize error.

        Args:
            a_ndim: ndim of the left operand.
            b_ndim: ndim of the right operand.
        """
        message = f"matmul supports only 1D or 2D tensors, got {a_ndim}D and {b_ndim}D."
        super().__init__(message)


class InvalidInitializerNameError(ValueError):
    """Raised when initializer name format is invalid."""

    def __init__(self, name: str) -> None:
        """Initialize error.

        Args:
            name: Invalid initializer name provided by the user.
                Expected format is '<strategy>_<distribution>'.
        """
        message = (
            f"Invalid initializer name {name!r}. "
            "Expected format '<strategy>_<distribution>'."
        )
        super().__init__(message)


class UnknownInitializationStrategyError(TensorError, ValueError):
    """Raised when an unknown initialization strategy is used."""

    def __init__(
        self,
        strategy: str,
        supported: tuple[str, ...] = ("random", "xavier", "kaiming"),
    ) -> None:
        """Initialize error.

        Args:
            strategy: Initialization strategy name that was provided.
            supported: Tuple of supported initialization strategies.
        """
        supported_str = ", ".join(repr(s) for s in supported)
        message = (
            f"Unknown initialization strategy {strategy!r}. "
            f"Expected one of: {supported_str}."
        )
        super().__init__(message)


class UnknownDistributionError(TensorError, ValueError):
    """Raised when an unknown distribution is used."""

    def __init__(
        self,
        dist: str,
        supported: tuple[str, ...] = ("normal", "uniform"),
    ) -> None:
        """Initialize error.

        Args:
            dist: Distribution name that was provided.
            supported: Tuple of supported distributions.
        """
        supported_str = ", ".join(repr(d) for d in supported)
        message = f"Unknown distribution {dist!r}. Expected one of: {supported_str}."
        super().__init__(message)
