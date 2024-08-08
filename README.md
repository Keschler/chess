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

## Example Usage

```plaintext
1 None e2e4 -inf 1.0999984741210938
2 e2e4 e2e4 -inf 0.0
3 e2e4 e2e4 -inf 1.0999985933303833
4 e2e4 e2e4 -inf -0.3999985456466675
Evaluation -0.3999985456466675 rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1 e2e4 4.7941575050354
Move: e5
1 None d2d4 -inf 1.0999985933303833
2 d2d4 g1f3 -inf -0.3999985456466675
3 g1f3 g1f3 -inf 1.3000022172927856
4 g1f3 d2d4 -inf -0.6000007390975952
Evaluation -0.6000007390975952 rnbqkbnr/pppp1ppp/8/4p3/4P3/8/PPPP1PPP/RNBQKBNR w KQkq - 0 2 d2d4 7.268377065658569
```
Chessboard is saved in chessboard.svg
![grafik](https://github.com/user-attachments/assets/986375be-651a-4630-aed5-5f13236ce3ca)
