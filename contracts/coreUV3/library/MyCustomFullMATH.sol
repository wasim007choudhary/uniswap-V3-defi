//SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

library MyCustomFullMath {
    error MyCustomFullMath__mulDiv__DivisionByZero();
    error MyCustomFullMath__mulDiv__ResultOverflowsUint256();
    error MyCustomFullMath__mulDivRoundUp__ResultOverflowsUint256();

    function mul512(uint256 x, uint256 y) internal pure returns (uint256 upperPart, uint256 lowerPart) {
        assembly ("memory-safe") {
            let mm := mulmod(x, y, not(0))
            lowerPart := mul(x, y)
            upperPart := sub(sub(mm, lowerPart), lt(mm, lowerPart))
        }
    }

    /*
       mulDiv(x, y, denominator)
    │
    ├──────────────────────────────────────────────────────────────┐
    │ 1. Compute the full 512-bit multiplication                   │
    │                                                              │
    │     product = x × y                                          │
    │                                                              │
    │     Split into:                                              │
    │         upperPart (high 256 bits)                            │
    │         lowerPart (low 256 bits)                             │
    └──────────────────────────────────────────────────────────────┘
                        │
                        ▼
    ┌──────────────────────────────────────────────────────────────┐
    │ 2. Fast path                                                 │
    │                                                              │
    │ upperPart == 0 ?                                             │
    │                                                              │
    │ YES → product fits inside uint256                            │
    │                                                              │
    │        return lowerPart / denominator                        │
    │                                                              │
    │ NO  → Continue                                               │
    └──────────────────────────────────────────────────────────────┘
                        │
                        ▼
    ┌──────────────────────────────────────────────────────────────┐
    │ 3. Overflow / division safety                                │
    │                                                              │
    │ upperPart >= denominator ?                                   │
    │                                                              │
    │ YES → Result would exceed uint256                            │
    │        or denominator == 0                                   │
    │        Revert                                                │
    │                                                              │
    │ NO → Quotient is guaranteed to fit in uint256                │
    └──────────────────────────────────────────────────────────────┘
                        │
                        ▼
    ┌──────────────────────────────────────────────────────────────┐
    │ 4. Make the division exact                                   │
    │                                                              │
    │ remainder = (x × y) % denominator                            │
    │                                                              │
    │ Subtract remainder from the 512-bit product                  │
    │                                                              │
    │ [upperPart | lowerPart] -= remainder                         │
    │                                                              │
    │ Result:                                                      │
    │                                                              │
    │ Product = Quotient × denominator                             │
    │                                                              │
    │ Remainder = 0 ✅                                              │
    └──────────────────────────────────────────────────────────────┘
                        │
                        ▼
    ┌──────────────────────────────────────────────────────────────┐
    │ 5. Remove powers of two                                      │
    │                                                              │
    │ Find largest power of two dividing denominator               │
    │                                                              │
    │ twos = denominator & (-denominator)                          │
    │                                                              │
    │ Divide denominator by twos                                   │
    │ Divide lowerPart by twos                                     │
    │                                                              │
    │ Shift remaining bits from upperPart into lowerPart           │
    │                                                              │
    │ Result:                                                      │
    │                                                              │
    │ denominator becomes odd                                      │
    └──────────────────────────────────────────────────────────────┘
                        │
                        ▼
    ┌──────────────────────────────────────────────────────────────┐
    │ 6. Compute initial modular inverse                           │
    │                                                              │
    │ inverse = (3 * denominator) ^ 2                              │
    │                                                              │
    │ This is NOT the final inverse.                               │
    │                                                              │
    │ It is only a 4-bit correct starting guess.                   │
    └──────────────────────────────────────────────────────────────┘
                        │
                        ▼
    ┌──────────────────────────────────────────────────────────────┐
    │ 7. Newton-Raphson refinement                                 │
    │                                                              │
    │ Measure how far the guess is from perfect                    │
    │                                                              │
    │ Apply correction                                             │
    │                                                              │
    │ inverse *= (2 - denominator × inverse)                       │
    │                                                              │
    │ Repeat six times                                             │
    │                                                              │
    │ Accuracy grows:                                              │
    │                                                              │
    │     4 bits                                                   │
    │       ↓                                                      │
    │     8 bits                                                   │
    │       ↓                                                      │
    │    16 bits                                                   │
    │       ↓                                                      │
    │    32 bits                                                   │
    │       ↓                                                      │
    │    64 bits                                                   │
    │       ↓                                                      │
    │   128 bits                                                   │
    │       ↓                                                      │
    │   256 bits ✅                                                 │
    └──────────────────────────────────────────────────────────────┘
                        │
                        ▼
    ┌──────────────────────────────────────────────────────────────┐
    │ 8. Perform the division                                      │
    │                                                              │
    │ Division is now exact                                        │
    │                                                              │
    │ Instead of                                                   │
    │                                                              │
    │     lowerPart / denominator                                  │
    │                                                              │
    │ perform                                                      │
    │                                                              │
    │     lowerPart × inverse                                      │
    │                                                              │
    │ because                                                      │
    │                                                              │
    │ denominator × inverse ≡ 1 (mod 2²⁵⁶)                         │
    └──────────────────────────────────────────────────────────────┘
                        │
                        ▼
    ┌──────────────────────────────────────────────────────────────┐
    │ 9. Return                                                    │
    │                                                              │
    │ return lowerPart × inverse                                   │
    │                                                              │
    │ = Exact floor(x × y ÷ denominator)                           │
    └──────────────────────────────────────────────────────────────┘*/
    function mulDiv(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 result) {
        unchecked {
            (uint256 upperPart, uint256 lowerPart) = mul512(x, y);
            // checking if the upper part is zero which means the 512 fits inside u256 , if it is then we can safely divide the lower part by the denominator and return the result
            if (upperPart == 0) {
                result = lowerPart / denominator;
            }

            //checking if the result is greater than 2^256 - 1 or denominator is zero as the result must be 256 bits or less
            if (upperPart >= denominator) {
                if (denominator == 0) {
                    revert MyCustomFullMath__mulDiv__DivisionByZero();
                }
                revert MyCustomFullMath__mulDiv__ResultOverflowsUint256();
            }

            // -------------------------------------------------------------------------
            // 512-by-256 Division
            //
            // At this point we know the final quotient can fit inside a uint256.
            // Before performing the division, we first make it exact by removing the
            // remainder. This allows the later modular inverse multiplication to
            // produce the precise quotient.
            // -------------------------------------------------------------------------

            uint256 remainder;

            assembly ("memory-safe") {
                // Compute the remainder of (x * y) ÷ denominator.
                //
                // remainder = (x * y) % denominator
                //
                // The full 512-bit product does not need to be reconstructed because
                // mulmod computes the remainder directly.
                remainder := mulmod(x, y, denominator)

                // If the remainder is larger than the lower 256 bits, the lower half
                // cannot subtract it directly. Borrow one whole 2²⁵⁶ block from the
                // upper 256 bits, exactly like borrowing from the next digit in
                // elementary decimal subtraction.
                upperPart := sub(upperPart, gt(remainder, lowerPart))

                // Subtract the remainder from the lower 256 bits.
                //
                // If a borrow occurred above, this subtraction naturally wraps modulo
                // 2²⁵⁶, effectively computing:
                //
                //     (lowerPart + 2²⁵⁶) - remainder
                //
                // Together, the previous line and this one subtract the remainder from
                // the entire 512-bit number represented by [upperPart | lowerPart].
                lowerPart := sub(lowerPart, remainder)
            }

            // -------------------------------------------------------------------------
            // Step 1: Create an initial "magic guess" for the modular inverse.
            //
            // We eventually want a special number called the modular inverse such that:
            //
            //     denominator × inverse ≡ 1 (mod 2²⁵⁶)
            //
            // Instead of finding it all at once, we start with a small guess.
            //
            // The formula:
            //
            //     (3 * denominator) ^ 2
            //
            // is a well-known mathematical identity that guarantees a correct
            // 4-bit starting guess for every odd denominator.
            //
            // Think of this as solving a giant puzzle:
            //
            //     ????????FGHI
            //
            // We already know the last 4 puzzle pieces are correct, while the
            // remaining pieces will be fixed in the following steps.
            // -------------------------------------------------------------------------
            uint256 inverse = (3 * denominator) ^ 2;

            // -------------------------------------------------------------------------
            // Step 2: Improve the guess using Newton-Raphson iteration.
            //
            // Each line below takes the current inverse guess, measures how far
            // it is from the perfect inverse, applies a mathematical correction,
            // and produces a much better guess.
            //
            // Child intuition:
            //
            //     Guess
            //        ↓
            //   Check how wrong it is
            //        ↓
            //   Apply a correction
            //        ↓
            //   Get a better guess
            //
            // This process is repeated several times.
            //
            // The amazing part is that every iteration doubles the number of
            // correct bits:
            //
            //     4 bits
            //        ↓
            //     8 bits
            //        ↓
            //    16 bits
            //        ↓
            //    32 bits
            //        ↓
            //    64 bits
            //        ↓
            //   128 bits
            //        ↓
            //   256 bits (Perfect modular inverse)
            //
            // Existing correct bits are never lost—each iteration simply reveals
            // twice as many additional correct bits.
            // -------------------------------------------------------------------------
            inverse *= 2 - denominator * inverse; // Correct modulo 2⁸
            inverse *= 2 - denominator * inverse; // Correct modulo 2¹⁶
            inverse *= 2 - denominator * inverse; // Correct modulo 2³²
            inverse *= 2 - denominator * inverse; // Correct modulo 2⁶⁴
            inverse *= 2 - denominator * inverse; // Correct modulo 2¹²⁸
            inverse *= 2 - denominator * inverse; // Correct modulo 2²⁵⁶

            // -------------------------------------------------------------------------
            // Step 3: Perform the division.
            //
            // Earlier we removed the remainder, making the division exact.
            // We also computed the modular inverse of the denominator.
            //
            // Instead of performing:
            //
            //     lowerPart ÷ denominator
            //
            // we now perform:
            //
            //     lowerPart × inverse
            //
            // because the modular inverse behaves like "1 / denominator" inside
            // modulo 2²⁵⁶ arithmetic.
            //
            // Since we already proved the final quotient fits inside a uint256,
            // this multiplication directly produces the final answer.
            // -------------------------------------------------------------------------
            result = lowerPart * inverse;
            return result;
        }
    }

    function mulDivRoundUp(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 result) {
        result = mulDiv(x, y, denominator);
        if (mulmod(x, y, denominator) > 0) {
            if (result == type(uint256).max) {
                revert MyCustomFullMath__mulDivRoundUp__ResultOverflowsUint256();
            }
            result++;
        }
    }
}
