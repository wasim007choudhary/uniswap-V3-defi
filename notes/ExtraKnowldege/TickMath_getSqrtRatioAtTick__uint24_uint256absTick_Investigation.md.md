# Uniswap V3 `TickMath` — `uint24` Gas Optimization Investigation

## Research Report

> **Core question:** If Uniswap V3's valid ticks never exceed `887272`, and `uint24` can represent that value, can we save gas by changing `absTick` from `uint256` to `uint24`?

---

## Executive Summary

This investigation tested a proposed Solidity micro-optimization in a Uniswap V3-style `TickMath` implementation the function  `getSqrtRatioAtTick()`.

The original implementation stores the absolute tick as:

```solidity
uint256 absTick = tick < 0
    ? uint256(-int256(tick))
    : uint256(int256(tick));
```

The proposed optimization stores it as:

```solidity
uint24 absTick = tick < 0
    ? uint24(-tick)
    : uint24(tick);
```

The idea is mathematically reasonable:

```text
MAX_TICK = 887272
2^24     = 16777216

887272 < 16777216
```

Therefore, every valid absolute tick fits comfortably inside `uint24`.

However, the EVM does not have native 24-bit stack arithmetic. Solidity's narrower integer types have to be represented using 256-bit EVM words while preserving the type's semantics.

Three implementations were therefore compared:

1. **Original:** `absTick` remains `uint256`.
2. **Persistent `uint24`:** `absTick` remains `uint24` throughout the function.
3. **Hybrid:** calculate/narrow through `uint24`, then immediately convert back to `uint256`.

The most important full-function benchmark was:

| Implementation | Gas | Delta vs. Original |
|---|---:|---:|
| **Original `uint256`** | **7,584** | baseline |
| **Hybrid `uint24 → uint256`** | **7,591** | **+7** |
| **Persistent `uint24`** | **7,677** | **+93** |

### Final conclusion

> **Keeping `absTick` as `uint24` for the entire TickMath calculation is not a gas optimization under the tested compiler/configuration.**

The hybrid version comes very close to the original, which indicates that the main problem is **not the initial narrowing itself**, but the consequences of keeping `absTick` as a narrow type throughout the larger computation.

The investigation also demonstrated a broader optimization principle:

> **A local micro-optimization can be cheaper in isolation and still make the complete function more expensive after compiler optimization.**

---

# 1. The Original Code Path

The relevant original logic is:

```solidity
uint256 absTick = tick < 0
    ? uint256(-int256(tick))
    : uint256(int256(tick));

require(absTick <= uint256(int256(MAX_TICK)), "T");

uint256 ratio = absTick & 0x1 != 0
    ? 0xfffcb933bd6fad37aa2d162d1a594001
    : 0x100000000000000000000000000000000;

if (absTick & 0x2 != 0)
    ratio = (ratio * 0xfff97272373d413259a46990580e213a) >> 128;

if (absTick & 0x4 != 0)
    ratio = (ratio * 0xfff2e50f5f656932ef12357cf3c7fdcc) >> 128;

// ...continues through all remaining tick-bit constants...

if (tick > 0)
    ratio = type(uint256).max / ratio;

sqrtPriceX96 = uint160(
    (ratio >> 32) +
    (ratio % (1 << 32) == 0 ? 0 : 1)
);
```

The important characteristic is that `absTick` becomes a `uint256` and stays in the `uint256` domain for the main body of the algorithm.

---

# 2. The Proposed Optimization

The proposed change was:

```solidity
uint24 absTick = tick < 0
    ? uint24(-tick)
    : uint24(tick);
```

The reasoning was:

```text
Valid tick range:
-887272 <= tick <= 887272

Absolute value:
abs(tick) <= 887272

uint24 capacity:
0 <= value <= 16777215
```

So mathematically the type is sufficient.

The mistake would be to assume that mathematical width automatically determines EVM gas.

---

# 3. Three Versions Were Tested

## 3.1 Original

```solidity
uint256 absTick = tick < 0
    ? uint256(-int256(tick))
    : uint256(int256(tick));
```

Conceptual flow:

```text
int24 tick
   ↓
absolute value
   ↓
uint256
   ↓
all remaining TickMath operations
```

---

## 3.2 Persistent `uint24`

```solidity
uint24 absTick = tick < 0
    ? uint24(-tick)
    : uint24(tick);
```

Conceptual flow:

```text
int24 tick
   ↓
absolute value
   ↓
uint24
   ↓
keep uint24 alive throughout TickMath
```

---

## 3.3 Hybrid

The hybrid experiment was:

```solidity
uint24 absTick24 = tick < 0
    ? uint24(-tick)
    : uint24(tick);

uint256 absTick = uint256(absTick24);
```

Conceptual flow:

```text
int24 tick
   ↓
absolute value
   ↓
uint24
   ↓
immediately widen to uint256
   ↓
all remaining TickMath operations
```

This version was deliberately introduced to separate two questions:

> Is narrowing itself expensive?

versus:

> Is keeping the variable narrow throughout the function expensive?

---

# 4. Why `uint24` Looked Promising at First

The first experiment isolated only the absolute-value computation.

### Original

```solidity
uint256 absTick =
    tick < 0
        ? uint256(-int256(tick))
        : uint256(int256(tick));
```

### Proposed

```solidity
uint24 absTick =
    tick < 0
        ? uint24(-tick)
        : uint24(tick);
```

Measured gas:

| Version | Gas |
|---|---:|
| Original | 471 |
| `uint24` | 425 |

Difference:

```text
471 - 425 = 46 gas
```

So the `uint24` version was **46 gas cheaper in that isolated experiment**.

This was a legitimate measurement.

It was therefore reasonable to investigate further.

---

# 5. Adding the Bound Check

The next experiment included the TickMath bound check.

The measured result was:

| Version | Gas |
|---|---:|
| Original | 447 |
| `uint24` | 399 |

Difference:

```text
447 - 399 = 48 gas
```

Again, the narrower representation appeared cheaper.

This made the optimization hypothesis look increasingly attractive.

---

# 6. Progressive Construction of TickMath

The function was then rebuilt experimentally by adding its bit-selection and multiplication stages one at a time.

For each additional stage, the same input was used for both implementations.

The measured relative advantage evolved approximately as follows:

| TickMath portion included | `uint24` advantage |
|---|---:|
| `absTick` | 46 gas |
| `absTick + require` | 48 gas |
| through `0x2` | 36 gas |
| through `0x4` | 30 gas |
| through `0x8` | 24 gas |
| through `0x10` | 18 gas |
| through `0x20` | 12 gas |
| through `0x40` | 6 gas |

For example, with progressively larger bit patterns:

```text
tick = 10   -> 1010₂
tick = 14   -> 1110₂
tick = 15   -> 1111₂
tick = 31   -> 11111₂
tick = 63   -> 111111₂
tick = 127  -> 1111111₂
```

this allowed the specific bit-controlled branches to be exercised.

The important observation was:

> **The local `uint24` advantage was being consumed as the function became more complete.**

---

# 7. Positive and Negative Ticks

The investigation also compared positive and negative ticks.

For:

```text
tick = +127
```

the measured result was:

```text
Original    2441 gas
Optimized   2435 gas
```

So:

```text
6 gas saved
```

For:

```text
tick = -127
```

the measured result was:

```text
Original    2554 gas
Optimized   2556 gas
```

So:

```text
2 gas more expensive
```

This demonstrated that sign-specific execution paths can also affect the relative result.

The negative path uses:

```solidity
uint24(-tick)
```

while the positive path uses:

```solidity
uint24(tick)
```

Therefore, the gas behavior is not necessarily identical for positive and negative ticks.

---

# 8. The Critical Full-Function Experiment

At this point, the isolated measurements could have led to the conclusion:

> "The `uint24` version is cheaper."

That conclusion would have been wrong.

The complete functions were benchmarked in a proper caller contract, with deployment moved to `setUp()` so deployment gas did not contaminate each benchmark.

The resulting measurements were:

```text
Original    7584 gas
Hybrid      7591 gas
Optimized   7677 gas
```

Therefore:

```text
Hybrid - Original
7591 - 7584
= +7 gas
```

and:

```text
Optimized - Original
7677 - 7584
= +93 gas
```

### Full-function winner

```text
Original uint256
```

The persistent `uint24` version was **93 gas more expensive**.

---

# 9. Why the Earlier Small Tests and the Full Function Disagreed

This is the central lesson of the entire investigation.

The earlier tests and the full-function benchmark were not contradictory.

They were measuring different compilation contexts.

A Solidity compiler does not necessarily optimize these two programs in the same way:

```text
Program A:
absTick calculation
```

and:

```text
Program B:
absTick calculation
+ require
+ 20 bit tests
+ 20 potential multiplications
+ inversion
+ final scaling
+ return
```

When the compiler sees the complete function, it can optimize:

- variable lifetimes
- stack placement
- conversions
- branching
- common operations
- control flow
- type cleanup

as a whole.

Therefore:

> **You cannot safely extrapolate whole-function gas from isolated micro-benchmarks.**

The isolated tests are still useful — but as **diagnostic experiments**, not final optimization proof.

---

# 10. The Hybrid Experiment Was the Turning Point

The hybrid version was introduced:

```solidity
uint24 absTick24 = tick < 0
    ? uint24(-tick)
    : uint24(tick);

uint256 absTick = uint256(absTick24);
```

Its full-function gas was:

```text
7591 gas
```

while the original was:

```text
7584 gas
```

Only:

```text
+7 gas
```

This is dramatically closer than the persistent `uint24` version:

```text
7677 gas
```

The result strongly indicates:

> **The problem is not simply "casting to uint24 is expensive."**

Instead, keeping `absTick` as `uint24` for the rest of the function changes how the compiler has to represent and manipulate that variable.

The hybrid immediately returns to the `uint256` domain for the long computation and consequently recovers almost all of the original performance.

---

# 11. EVM Reality: No Native `uint24` Stack

This is the conceptual foundation.

Solidity supports:

```solidity
uint8
uint16
uint24
uint32
...
uint256
```

But the EVM stack is fundamentally 256-bit.

The EVM does not have a special instruction such as:

```text
AND_UINT24
ADD_UINT24
MUL_UINT24
```

Instead, Solidity must preserve the semantic width of a narrower value where necessary.

This can involve masking and conversion logic.

Thus:

```text
uint24
```

does not automatically imply:

```text
cheaper EVM arithmetic
```

---

# 12. Optimized Assembly Evidence

The optimized assembly revealed exactly the kind of type machinery we expected.

For the `uint24` implementation, the generated assembly contained:

```text
0xffffff
and
```

around the narrow-type handling and comparison.

For example, the optimized assembly showed:

```text
0xffffff
and

...

0xffffff
and
gt
iszero
```

for the `uint24(MAX_TICK)` comparison.

This is visible in the benchmark's assembly output around the optimized implementation's bound check.

The same generated assembly then proceeds into ordinary EVM `AND` operations for the bit tests.

For example:

```text
0x02
dup3
and
iszero
jumpi
```

for:

```solidity
if (absTick & 0x2 != 0)
```

The corresponding pattern repeats for higher masks.

---

# 13. Important Distinction: IR vs. Final Assembly

Earlier IR contained helper functions such as:

```text
cleanup_t_uint24(...)
convert_t_int24_to_t_uint24(...)
```

It would be incorrect to simply count those helper calls as additional EVM gas.

IR is an intermediate representation.

The optimizer may:

- inline helpers
- remove them
- combine them
- simplify them

before producing final assembly/bytecode.

This investigation therefore moved from:

```text
IR
```

to:

```text
optimized assembly
```

before making conclusions about the generated code.

That distinction is essential in compiler-level gas analysis.

---

# 14. Why the Bit Tests Are Not Automatically Cheaper

Consider:

```solidity
absTick & 0x40
```

Whether `absTick` is declared as:

```solidity
uint24
```

or:

```solidity
uint256
```

does not provide a smaller EVM `AND`.

The EVM still executes:

```text
AND
```

on its 256-bit stack words.

The assembly confirms this.

The hybrid and the original paths use ordinary stack operations for the bit tests rather than gaining some special "24-bit AND" instruction.

Therefore:

> **Making `absTick` narrower does not make the fundamental EVM bitwise operation narrower.**

---

# 15. The Child-Friendly Explanation

Imagine you have two boxes.

### Big box

```text
256-bit box
```

### Small box

```text
24-bit box
```

You think:

> "The small box should be cheaper."

But the warehouse only has machinery built for 256-bit boxes.

So when you keep using the small box everywhere, the warehouse repeatedly has to make sure:

```text
"Is this still a valid 24-bit value?"
```

Sometimes that requires additional handling.

Now imagine you use the small box only briefly:

```text
small box
   ↓
immediately move number into big box
```

Then all the warehouse machinery can work normally.

That is approximately what the hybrid version does.

---

# 16. Why the Hybrid Is Interesting but Not Yet an Optimization

The hybrid result:

```text
Original   7584
Hybrid     7591
```

means the hybrid is only **7 gas more expensive**.

That is a very small regression.

But it is still a regression.

Therefore the scientifically correct statement is:

> **The hybrid nearly recovers the original gas cost but does not beat the original in the measured benchmark.**

We should not label it an optimization unless a controlled test demonstrates a net gas reduction.

---

# 17. Benchmark Methodology

The final gas tests used a caller contract and deployed it once in `setUp()`.

The structure was effectively:

```solidity
TickMathCaller caller;

function setUp() public {
    caller = new TickMathCaller();
}

function testGasOriginal() public {
    caller.original(0);
}

function testGasOptimized() public {
    caller.optimized(0);
}

function testGasHybrid() public {
    caller.hybrid(0);
}
```

This corrected an earlier benchmarking mistake where the caller was deployed inside every test:

```solidity
TickMathCaller caller = new TickMathCaller();
caller.original(0);
```

That produced values around:

```text
~993k gas
```

because deployment cost was included.

After moving deployment into `setUp()`, the benchmark produced the meaningful values around:

```text
7584
7591
7677
```

### General benchmarking lesson

> **Remove unrelated setup/deployment costs when trying to compare a small execution path.**

---

# 18. Fuzz Testing Was Used Separately for Correctness

The gas benchmark and the correctness test serve different purposes.

The fuzz test was configured to run:

```text
270 cases
```

and the test constrained:

```text
-887272 <= tick <= 887272
```

The important invariant was:

```solidity
assertEq(
    TickMath.getSqrtRatioAtTick(tick),
    TickMath.getOptimzedSqrtRatioAtTick(tick)
);
```

The fuzz campaign completed successfully:

```text
270 runs
0 failures
```

That establishes that the tested optimized implementation matched the original implementation across the generated valid ticks in that fuzz campaign.

### Important distinction

```text
Fuzz test
    ↓
"Do the implementations return the same answer?"

Gas test
    ↓
"Which implementation consumes less gas?"
```

A function can be:

```text
correct
```

and still be:

```text
more expensive
```

That is exactly what happened here.

---

# 19. Why `tick = 0` and `tick = 1` Matter

Special low-complexity inputs are useful for understanding code paths.

### `tick = 0`

```text
absTick = 0
```

Therefore, none of the higher mask-controlled multiplications execute.

This is close to an early-path benchmark.

### `tick = 1`

Binary representation:

```text
1 = ...0001
```

So the first bit path is selected while the higher masks remain unset.

These values are useful because they reduce the number of executed arithmetic stages and can reveal overhead associated with:

- type handling
- branching
- initialization
- finalization

However, even such small-input benchmarks should not replace whole-function testing across representative execution paths.

---

# 20. What the Experiment Actually Proved

The evidence supports the following conclusions.

## Finding 1

`uint24` is mathematically large enough for Uniswap V3's valid absolute tick range.

## Finding 2

A narrower Solidity integer does not automatically produce cheaper EVM execution.

## Finding 3

The isolated `uint24` absolute-value computation was cheaper.

Measured:

```text
425 vs 471 gas
```

## Finding 4

That local saving did not survive whole-function compilation.

## Finding 5

Keeping `absTick` as `uint24` through the complete TickMath calculation was measured as:

```text
7677 gas
```

versus:

```text
7584 gas
```

for the original.

## Finding 6

The hybrid:

```solidity
uint24 absTick24 = ...;
uint256 absTick = uint256(absTick24);
```

measured:

```text
7591 gas
```

which is only 7 gas above the original.

## Finding 7

The optimized assembly confirms that the narrower type changes generated code around type preservation and conversion, while the core bit tests still use ordinary EVM stack operations.

---

# 21. What This Does NOT Prove

It does **not** prove:

> "`uint24` is always worse than `uint256`."

That would be too broad.

Gas behavior depends on:

- Solidity compiler version
- optimizer settings
- optimizer runs
- `via-ir`
- surrounding code
- variable lifetime
- type conversions
- control flow
- whether a value is stored or passed
- generated bytecode

The correct conclusion is limited to:

> **This TickMath implementation, compiled under the tested configuration, does not benefit from keeping `absTick` as `uint24` throughout the function.**

---

# 22. The Broader Research Lesson

This experiment demonstrates a general smart-contract optimization principle:

## Source-level intuition is only a hypothesis

A developer might reason:

```text
uint24 < uint256
therefore
uint24 < gas
```

But this is not reliable.

The actual pipeline is:

```text
Solidity source
      ↓
Solidity compiler
      ↓
IR
      ↓
optimizer
      ↓
assembly
      ↓
bytecode
      ↓
EVM execution
      ↓
gas
```

The final question is always:

```text
"What instructions did the EVM actually execute?"
```

---

# 23. Proper Optimization Workflow for Future Work

This investigation suggests a disciplined workflow for future Uniswap V3 reverse-engineering and optimization.

### Step 1 — Form a hypothesis

Example:

```text
"absTick never exceeds 2²⁴, therefore uint24 may be cheaper."
```

### Step 2 — Establish correctness

Run fuzz/property tests.

### Step 3 — Create a clean gas benchmark

Make sure setup and deployment costs are not polluting the measurement.

### Step 4 — Measure the full function

Do not rely on a single micro-benchmark.

### Step 5 — Test representative execution paths

Use:

```text
0
1
small positive
small negative
large positive
large negative
max valid
min valid
```

### Step 6 — Perform targeted micro-benchmarks

Use isolated components to identify where differences originate.

### Step 7 — Inspect compiler output

Compare:

```text
IR
IR optimized
assembly optimized
```

### Step 8 — Change one thing at a time

Do not simultaneously alter:

- type width
- arithmetic
- control flow
- branching
- unchecked blocks
- constants

### Step 9 — Re-run correctness

An optimization that changes the answer is not an optimization.

### Step 10 — Re-run whole-function gas

The final decision must be made on the actual target function.

---

# 24. Final Result

## Original

```solidity
uint256 absTick = tick < 0
    ? uint256(-int256(tick))
    : uint256(int256(tick));
```

### Full benchmark

```text
7584 gas
```

**Current winner.**

---

## Persistent `uint24`

```solidity
uint24 absTick = tick < 0
    ? uint24(-tick)
    : uint24(tick);
```

### Full benchmark

```text
7677 gas
```

**93 gas more expensive.**

---

## Hybrid

```solidity
uint24 absTick24 = tick < 0
    ? uint24(-tick)
    : uint24(tick);

uint256 absTick = uint256(absTick24);
```

### Full benchmark

```text
7591 gas
```

**7 gas more expensive than the original.**

---

# 25. Final Research Verdict

> ### The proposed `uint24 absTick` optimization is not a valid gas optimization for the complete TickMath implementation under the tested compilation configuration.
>
> Although the narrower type produces a measurable saving in isolated micro-benchmarks, that advantage disappears when the complete function is compiled and optimized. Retaining `absTick` as `uint24` throughout the function results in higher gas consumption, while narrowing once and immediately converting back to `uint256` nearly recovers the original performance but still does not beat it.
>
> The experiment demonstrates why Solidity gas optimization must ultimately be evaluated at the level of generated EVM execution rather than inferred from source-level type width.

---

# 26. The One Rule to Keep

```text
Smaller Solidity type
        ≠
Smaller EVM cost
```

Or even more practically:

```text
Hypothesis
   ↓
Correctness
   ↓
Benchmark
   ↓
Compiler output
   ↓
Benchmark again
   ↓
Conclusion
```

**That is the reliable way to perform smart-contract gas optimization research.**
