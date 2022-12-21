---
title: The case for StrEnum in Python 3.11
date: 2022-12-21
image: images/python-strenum.png
description: 'A subtle change of how Enums behave and why you should probably use StrEnum instead'
tags: ['python', 'enum', 'strenum', 'pep-663']
---

With the update to Python 3.11, we ran into a subtle change in how Enum's behave. This is thanks to [PEP 663 - Standardizing Enum str(), repr(), and format() behaviors](https://peps.python.org/pep-0663/).

## Before Python 3.11

Before Python 3.11, a string enum as shown below would return the value of an entry in the enum when used via format or an f-string but not when implicitly calling `__str__()`.

```python
# Python 3.10

from enum import Enum

class Foo(str, Enum):
    BAR = "bar"

x = Foo.BAR

x               # Outputs <Foo.BAR: 'bar'>
f"{x}"          # Outputs 'bar'
"{}".format(x)  # Outputs 'bar'
str(x)          # Outputs 'Foo.BAR'
x.value         # Outputs 'bar'
```

## Python 3.11

In Python 3.11, the difference in using an Enum entry in a string context was changed, so now it returns the stringified reference instead. In our codebase, we had to change the use of enum entries to explicitly call `Foo.BAR.value` wherever we had used an enum entry in a format context.

```python
# Python 3.11

from enum import Enum

class Foo(str, Enum):
    BAR = "bar"

x = Foo.BAR

x               # Outputs <Foo.BAR: 'bar'>
f"{x}"          # Outputs 'Foo.BAR'
"{}".format(x)  # Outputs 'Foo.BAR'
str(x)          # Outputs 'Foo.BAR'
x.value         # Outputs 'bar'
```

## StrEnum to the rescue

In Python 3.11, [StrEnum](https://pypi.org/project/StrEnum/) was added to the standard library. Using that instead of the aforementioned style of enums makes for more obvious behaviour.

```python
# Python 3.11

from enum import StrEnum, auto

class Foo(StrEnum):
    BAR = auto()

x = Foo.BAR

x               # Outputs <Foo.BAR: 'bar'>
f"{x}"          # Outputs 'bar'
"{}".format(x)  # Outputs 'bar'
str(x)          # Outputs 'bar'
x.value         # Outputs 'bar'
```

Thanks to [Lucy Linder](https://dev.to/derlin) for [making me aware](https://dev.to/derlin/7-python-311-new-features-11pk) of the addition of `StrEnum` to the standard library in 3.11.
