from setuptools import setup, Extension
from Cython.Build import cythonize

extensions = [
    Extension("constants", ["constants.pyx"]),
    Extension("evaluation", ["evaluation.pyx"]),
    Extension("search", ["search.pyx"]),
    Extension("main", ["main.pyx"]),
]

setup(
    ext_modules=cythonize(extensions, language_level="3"),
    zip_safe=False,
)
