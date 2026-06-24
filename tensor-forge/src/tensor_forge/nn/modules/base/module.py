from __future__ import annotations

from abc import ABC, abstractmethod
from collections.abc import Iterator
from typing import Any

from numpy.typing import ArrayLike

from tensor_forge.tensor import Tensor


class Module(ABC):
    def __init__(self) -> None:
        """Инициализирует базовый слой."""
        self.is_train = True

    @abstractmethod
    def forward(self, x: Tensor | ArrayLike) -> Tensor:
        """Выполняет прямой проход слоя.

        Args:
            x (Tensor | ArrayLike): Входные данные слоя.

        Returns:
            Tensor: Результат преобразования входных данных.
        """
        pass

    @abstractmethod
    def backward(self, grad: Tensor | ArrayLike) -> Tensor:
        """Выполняет обратное распространение градиента через слой.

        Args:
            grad (Array): Градиент функции потерь по выходу слоя.

        Returns:
            Tensor: Градиент функции потерь по входу слоя.
        """
        pass

    def to(self, backend: str) -> Module:
        for param in self.parameters():
            param.change_backend(backend)
        return self

    def parameters(self) -> Iterator[Tensor]:
        for value in self.__dict__.values():
            yield from self._iter_parameters(value)

    def grad_parameters(self) -> Iterator[Tensor]:
        for value in self.__dict__.values():
            for tensor_value in self._iter_parameters(value):
                if tensor_value.requires_grad:
                    yield tensor_value

    def _iter_parameters(self, value: Any) -> Iterator[Tensor]:
        if isinstance(value, Tensor):
            yield value
            return

        if isinstance(value, Module):
            yield from value.parameters()
            return

    def train(self) -> None:
        """Переводит слой в режим обучения."""
        self.is_train = True

    def eval(self) -> None:
        """Переводит слой в режим инференса."""
        self.is_train = False
