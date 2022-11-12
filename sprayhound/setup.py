# Author:
#  Romain Bentz (pixis - @hackanddo)
# Website:
#  https://beta.hackndo.com

import pathlib

from setuptools import setup, find_packages

HERE = pathlib.Path(__file__).parent
README = (HERE / "README.md").read_text()

setup(
    name="sprayhound",
    version="0.0.3",
    author="Pixis",
    author_email="hackndo@gmail.com",
    description="Password spraying with BloodHound integration",
    long_description=README,
    long_description_content_type="text/markdown",
    packages=find_packages(exclude=["assets", "cme"]),
    include_package_data=True,
    url="https://github.com/hackanddo/sprayhound",
    zip_safe = True,
    license="MIT",
    install_requires=[
        'neo4j',
        'python-ldap'
    ],
    python_requires='>=3.6',
    classifiers=(
        "Programming Language :: Python :: 3.6",
        "Programming Language :: Python :: 3.7",
        "Programming Language :: Python :: 3.8",
        "Programming Language :: Python :: 3.9",
        "License :: OSI Approved :: MIT License",
        "Operating System :: OS Independent",
    ),
    entry_points={
        'console_scripts': [
            'sprayhound = sprayhound.core:run',
        ],
    },
    test_suite='tests.tests'
)
