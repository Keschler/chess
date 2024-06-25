from setuptools import setup
from Cython.Build import cythonize

setup(
    ext_modules=cythonize(["evaluation.pyx", "search.pyx", "main.pyx"], language_level="3"),
    zip_safe=False,
)
