# Chess Engine

This repository contains a chess engine written in Python using Cython for improved performance. The engine implements various chess algorithms and techniques, including bitboards, Zobrist hashing, and piece-square tables for evaluation.

## Project Structure

- `main.pyx`: The main file to run the chess engine.
- `bitboards.pyx`: Contains the bitboard implementation for efficient board representation and manipulation.
- `constants.pyx`: Holds the piece-square tables and other constant values used in evaluations.
- `evaluation.pyx`: Implements the evaluation function for the chess positions.
- `search.pyx`: Implements the search algorithms including minimax and iterative deepening.

## Installation

1. Clone the repository:
    ```sh
    git clone https://github.com/keschler/chess.git
    cd chess
    ```

2. Install dependencies:
    ```sh
    pip install -r requirements.txt
    ```

3. Build the Cython files:
    ```sh
    python setup.py build_ext --inplace
    ```

## Usage

To start the chess engine, run:
```sh
python run.py
```
