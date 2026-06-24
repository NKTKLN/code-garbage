"""Weight initialization utilities for neural networks."""

import numpy as np
from numpy.random import Generator as RandomGenerator
from numpy.typing import NDArray

from tensor_forge.errors import (
    InvalidInitializerNameError,
    UnknownDistributionError,
    UnknownInitializationStrategyError,
)


class WeightInitializer:
    """Weight initializer based on strategy and distribution."""

    def __init__(self, random: int | RandomGenerator | None = None):
        """Initialize random number generator.

        Args:
            random (int | RandomGenerator | None): Seed or generator.

        """
        self._EXPECTED_PARTS = 2

        self._rng: RandomGenerator

        if isinstance(random, int):
            self._rng = np.random.default_rng(random)
        elif isinstance(random, RandomGenerator):
            self._rng = random
        else:
            self._rng = np.random.default_rng()

    def _parse_name(self, name: str) -> tuple[str, str]:
        """Split initializer name into strategy and distribution.

        Args:
            name (str): Name in format ``<strategy>_<distribution>``.

        Returns:
            tuple[str, str]: Strategy and distribution.

        Raises:
            ValueError: If format is invalid.
        """
        parts = name.split("_")

        if len(parts) != self._EXPECTED_PARTS:
            raise InvalidInitializerNameError(name)

        return tuple(parts)

    def _normal(self, var: float, shape: tuple[int, int]) -> NDArray[np.float64]:
        """Sample weights from a normal distribution.

        Args:
            var (float): Variance scale.
            shape (tuple[int, int]): Output shape.

        Returns:
            NDArray[np.float64]: Weight matrix.
        """
        return self._rng.normal(0, var, shape)

    def _uniform(self, var: float, shape: tuple[int, int]) -> NDArray[np.float64]:
        """Sample weights from a uniform distribution.

        Args:
            var (float): Variance scale.
            shape (tuple[int, int]): Output shape.

        Returns:
            NDArray[np.float64]: Weight matrix.
        """
        bound = np.sqrt(3 * var)
        return self._rng.uniform(-bound, bound, shape)

    def __call__(self, name: str, shape: tuple[int, int]) -> NDArray[np.float64]:
        """Generate weights using a given initializer.

        Args:
            name (str): Initializer name ``<strategy>_<distribution>``.
            shape (tuple[int, int]): Weight shape ``(fan_in, fan_out)``.

        Returns:
            NDArray[np.float64]: Initialized weights.

        Raises:
            ValueError: If strategy or distribution is unsupported.
        """
        fan_in, fan_out = shape
        strategy, dist = self._parse_name(name)

        match strategy:
            case "random":
                var = 1 / fan_in
            case "xavier":
                var = 2 / (fan_in + fan_out)
            case "kaiming":
                var = 2 / fan_in
            case _:
                raise UnknownInitializationStrategyError(strategy)

        match dist:
            case "normal":
                return self._normal(var, shape)
            case "uniform":
                return self._uniform(var, shape)
            case _:
                raise UnknownDistributionError(dist)
