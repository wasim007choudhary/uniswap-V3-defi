# Why Uniswap V3 `TickMath` Uses `uint256` Instead of `uint24`

## A Very Simple Explanation

### The Question

A natural question is:

> **If Uniswap V3 ticks only need an `int24`, and the absolute tick fits easily inside `uint24`, why does TickMath use `uint256` for `absTick`?**

At first glance, `uint24` seems like the obvious optimization.

A valid Uniswap V3 tick is bounded by:

```text
MIN_TICK = -887272
MAX_TICK =  887272
```

And:

```text
2²⁴ = 16,777,216
```

So `uint24` has more than enough numerical capacity.

But numerical capacity is **not the same thing as EVM execution cost**.

---

# The Child-Friendly Answer

Imagine the EVM gives every number a **256-seat bus**.

Now suppose your number only needs **24 seats**.

You might think:

> "Why don't we use a 24-seat bus? It is smaller, so surely it is cheaper."

But the EVM does not have a special 24-seat bus.

Its stack operations naturally work with **256-bit words**.

So when Solidity sees:

```solidity
uint24
```

it still has to represent that value inside the EVM's 256-bit world while preserving the rule:

> "Only the lowest 24 bits are valid."

That can require additional type-handling, masking, and conversions.

Now imagine that the number is used only once.

That extra work may be small.

But in `TickMath`, `absTick` is used **again and again**:

```solidity
absTick & 0x1
absTick & 0x2
absTick & 0x4
absTick & 0x8
absTick & 0x10
...
```

So keeping it as `uint24` throughout the whole function can make the generated code less efficient.

---

# What We Actually Tested

This was not just a theory. We tested three implementations.

## 1. Original `uint256`

```solidity
uint256 absTick = tick < 0
    ? uint256(-int256(tick))
    : uint256(int256(tick));
```

## 2. Persistent `uint24`

```solidity
uint24 absTick = tick < 0
    ? uint24(-tick)
    : uint24(tick);
```

## 3. Hybrid

```solidity
uint24 absTick24 = tick < 0
    ? uint24(-tick)
    : uint24(tick);

uint256 absTick = uint256(absTick24);
```

---

# The Full-Function Result

After correcting the benchmark so the caller contract was deployed once rather than inside every gas test, we measured:

```text
Original uint256:   7584 gas
Hybrid:             7591 gas
Persistent uint24:  7677 gas
```

So:

```text
Persistent uint24 - Original
7677 - 7584
= 93 gas more
```

The supposedly "smaller" `uint24` version was therefore **more expensive**.

The hybrid was only:

```text
7591 - 7584
= 7 gas more
```

So almost all of the original performance was recovered simply by converting back to `uint256`.

---

# Why This Makes Sense

Think about the three designs like this.

## Original

```text
tick
 ↓
absolute value
 ↓
uint256
 ↓
all remaining TickMath operations
```

The value is already in the EVM's natural 256-bit domain.

---

## Persistent `uint24`

```text
tick
 ↓
absolute value
 ↓
uint24
 ↓
keep uint24 for the whole function
 ↓
many later operations
```

Now the compiler must preserve the narrower type throughout the larger computation.

---

## Hybrid

```text
tick
 ↓
absolute value
 ↓
uint24
 ↓
convert once
 ↓
uint256
 ↓
all remaining TickMath operations
```

The expensive part of the algorithm can once again operate in the normal 256-bit domain.

---

# The Important EVM Lesson

The EVM does not have a special:

```text
24-bit AND
24-bit MUL
24-bit stack slot
```

Instead, the underlying stack word is 256 bits.

So:

```text
uint24
```

does **not** automatically mean:

```text
cheaper EVM operation
```

This is the fundamental reason the optimization intuition can fail.

---

# Why Our Small Tests Initially Looked Different

This was one of the most interesting parts of the investigation.

When we tested only the `absTick` calculation, the `uint24` version was cheaper:

```text
Original:   471 gas
uint24:     425 gas
```

Saving:

```text
46 gas
```

So the `uint24` idea was genuinely cheaper in the isolated experiment.

As we progressively added TickMath logic, the advantage kept shrinking:

```text
through 0x2   → 36 gas saved
through 0x4   → 30 gas saved
through 0x8   → 24 gas saved
through 0x10  → 18 gas saved
through 0x20  → 12 gas saved
through 0x40  →  6 gas saved
```

Then we compiled and measured the **complete function**.

The result reversed:

```text
Original    7584
uint24      7677
```

This is not a contradiction.

It demonstrates:

> **Gas is not safely additive at the Solidity-source level.**

The compiler sees the complete function and can optimize the entire program as a unit.

A small code fragment may be cheaper when compiled alone but interact differently with the surrounding code when the entire function is compiled together.

---

# Why `TickMath` Is a Good Example

`absTick` is not a temporary number that disappears immediately.

It feeds a long sequence of checks:

```solidity
if (absTick & 0x2 != 0)
    ...

if (absTick & 0x4 != 0)
    ...

if (absTick & 0x8 != 0)
    ...

// ...
```

Then the function potentially performs many 256-bit multiplications and eventually:

```solidity
if (tick > 0)
    ratio = type(uint256).max / ratio;
```

followed by the final conversion to `uint160`.

So the type of `absTick` interacts with a large amount of downstream code.

---

# What the Compiler Output Showed

The optimized assembly for the narrow-type implementation showed explicit type-related masking around the `uint24` value.

For the bound check, for example, the generated code contained:

```text
0xffffff
and
...
0xffffff
and
gt
iszero
```

This is consistent with preserving the `uint24` semantics.

But importantly, the compiler did **not** leave an extra `0xffffff AND` before every single bit test.

The bit tests themselves could still become ordinary operations such as:

```text
dup3
and
iszero
jumpi
```

This is why we should not oversimplify the explanation to:

> "Every `uint24` operation adds an extra mask."

That is not what the final optimized assembly shows.

The real issue is the **overall generated code and type handling across the entire function**.

---

# The Hybrid Was the Key Experiment

The hybrid experiment was especially valuable because it answered a very specific question.

We used:

```solidity
uint24 absTick24 = tick < 0
    ? uint24(-tick)
    : uint24(tick);

uint256 absTick = uint256(absTick24);
```

and got:

```text
Original: 7584
Hybrid:   7591
```

Only 7 gas apart.

Compare that with:

```text
Persistent uint24: 7677
```

This strongly supports the interpretation that:

> **The expensive part is not merely creating a `uint24`; keeping the value as `uint24` throughout the larger TickMath computation is what hurts the complete function's gas efficiency.**

---

# So Why Did Uniswap Choose `uint256`?

The safest answer is:

> **Because `uint256` matches the EVM's natural 256-bit execution model, and `absTick` is subsequently used throughout a 256-bit arithmetic-heavy routine. A mathematically smaller type is not automatically a computationally cheaper type on the EVM.**

And our benchmark supports that answer for this implementation.

---

# The One-Sentence Explanation for a Non-Technical Person

> **Uniswap uses `uint256` not because the tick is that big, but because the EVM works naturally with 256-bit numbers, and using a tiny type like `uint24` everywhere can require extra handling that can actually make the code more expensive.**

---

# The Deeper Research Lesson

This is the real lesson behind the experiment:

```text
"Smaller Solidity type"
        ≠
"Cheaper EVM execution"
```

And the correct optimization workflow is:

```text
Hypothesis
    ↓
Correctness test
    ↓
Full-function gas benchmark
    ↓
Micro-benchmarks
    ↓
Compiler IR
    ↓
Optimized assembly
    ↓
Final conclusion
```

The key is to **measure the generated execution**, not just reason from the apparent size of the Solidity type.

---

# Final Verdict

For the tested TickMath implementation:

```text
Original uint256     → 7584 gas
Hybrid uint24→256   → 7591 gas
Persistent uint24   → 7677 gas
```

Therefore:

**`uint256` is the better choice for the complete function.**

The `uint24` idea was not stupid or mathematically wrong. In fact, it was a valid optimization hypothesis and it **did win locally**.

But once the entire function was compiled together, the EVM/compiler-level reality was different.

That is exactly the kind of thing that makes gas optimization interesting:

> **You do not optimize the Solidity source code. You optimize what the EVM ultimately has to execute.**

---

# 28. What If `absTick` Were a State Variable Instead?

This is a **different optimization problem** from the one we investigated in `TickMath`.

Our actual `absTick` is a **local variable** inside a function:

```solidity
function getSqrtRatioAtTick(int24 tick) internal pure returns (uint160) {
    uint256 absTick = ...;
}
```

A local variable is handled during function execution. It is not stored persistently in contract storage.

If, instead, we wrote:

```solidity
uint24 public absTick;
```

then `absTick` would become a **state variable**, and the important question would change from primarily:

```text
"Is uint24 cheaper in the EVM's stack execution?"
```

to:

```text
"Can uint24 help us use storage more efficiently?"
```

---

# 29. Local Variable vs. State Variable

## Local variable

Think of a local variable as a number you are holding in your hand while doing a calculation.

```text
local variable
      ↓
function execution
      ↓
EVM stack / transient computation
```

For our TickMath experiment, this is the relevant case.

The EVM naturally works with 256-bit stack words, so changing a local variable from `uint256` to `uint24` does **not** automatically produce a cheaper operation.

---

## State variable

A state variable is more like a number you put into a filing cabinet.

```text
state variable
      ↓
contract storage
      ↓
storage slots
```

EVM storage is organized into **32-byte slots**.

This means smaller state variables can become useful for a different reason: **storage packing**.

---

# 30. Storage Packing

Suppose a contract contains:

```solidity
uint128 a;
uint128 b;
```

These values can potentially share one 32-byte storage slot.

Likewise, suitably sized variables such as:

```solidity
uint24 absTick;
uint32 foo;
uint64 bar;
```

can potentially be packed together into a single storage slot when the compiler's storage-layout rules permit it.

This can reduce the number of storage slots occupied by a contract and can therefore reduce storage-related costs in situations where packing changes the number of slots accessed or written.

By contrast:

```solidity
uint256 absTick;
```

occupies the entire 32-byte slot by itself.

---

# 31. Important Caveat: `uint24` Does Not Make `SSTORE` 8× Cheaper

A common misconception would be:

```text
uint24 = 3 bytes
uint256 = 32 bytes

therefore
uint24 storage = 1/10 the SSTORE cost
```

That is **not how EVM storage works**.

A storage slot is still a 32-byte slot.

The major benefit of a smaller state variable is that it can allow **multiple variables to share a slot**.

So:

```solidity
uint24 a;
uint32 b;
uint64 c;
```

may be much more interesting from a storage-layout perspective than a lone:

```solidity
uint24 a;
```

The question becomes:

> **Can multiple values fit into fewer storage slots?**

---

# 32. Child-Friendly Analogy

Imagine a storage cupboard with fixed-size compartments.

Each compartment can hold one full 32-byte slot.

### Large object

A `uint256` is like an object that fills the whole compartment:

```text
┌────────────────────────────┐
│          uint256            │
└────────────────────────────┘
```

Nothing else can fit beside it.

### Small objects

A `uint24` is much smaller:

```text
┌───┬─────────────────────────┐
│24 │       free space        │
└───┴─────────────────────────┘
```

Now another suitably small variable may fit beside it.

That is the usefulness of a small **state-variable** type.

---

# 33. Why This Is Different From Our TickMath Experiment

Our TickMath variable is not stored in the contract:

```solidity
uint256 absTick = ...;
```

It exists only while `getSqrtRatioAtTick()` is executing.

Therefore, there is **no storage slot to save** by making it `uint24`.

The relevant question is instead:

```text
How does Solidity compile this value into EVM operations?
```

That is why our investigation focused on:

- EVM stack words
- type conversion
- compiler code generation
- optimized assembly
- whole-function gas

If `absTick` were a state variable, we would additionally care about:

- storage slot layout
- storage packing
- `SLOAD`
- `SSTORE`
- cold vs. warm storage access
- whether packing actually reduces the number of slots accessed

That is a fundamentally different optimization analysis.

---

# 34. The Rule to Remember

There are two separate ideas:

```text
LOCAL VARIABLE
    ↓
EVM execution / stack
    ↓
smaller Solidity integer
    ≠ automatically cheaper
```

and:

```text
STATE VARIABLE
    ↓
storage slots
    ↓
smaller types can enable packing
    ↓
potential storage-layout savings
```

So when someone asks:

> **"Why didn't Uniswap just use `uint24`?"**

the answer must first identify **where the variable lives**.

For our actual `TickMath` `absTick`, it is a local variable. Storage packing is irrelevant.

For a hypothetical state variable, `uint24` could be valuable primarily because it might let other state variables share the same storage slot.

---

# 35. Final Distinction

The simplest way to remember the whole investigation is:

```text
LOCAL:
"How cheaply can I calculate with this value?"

STATE:
"How efficiently can I store this value?"
```

For `TickMath`, we were solving the first problem.

If `absTick` were persistent contract state, we would be solving the second problem as well.


---

# 🧒 Extra Simple Mental Models

## 🚌 `uint24` vs. `uint256` — The Bus Analogy

Imagine the EVM gives every number a **256-seat bus**.

Your tick only needs 24 seats.

You might think:

> "Let's use a 24-seat bus!"

But the EVM does not have a special 24-seat bus. It works naturally with 256-bit words.

```text
uint24
   ↓
small number

BUT

EVM
   ↓
256-bit world
```

So:

> **A smaller Solidity type does not automatically mean a cheaper EVM operation.**

### 🧠 Remember

```text
Small number
    ≠
Small EVM cost
```

---

## 🪑 The EVM Stack — The Desk Analogy

Imagine solving a maths problem at a desk.

You put numbers on the desk, use them, change them, and remove them.

That is a simple mental model for local values during execution.

```text
Local variable
      ↓
   EVM stack
      ↓
Temporary calculation
```

For `absTick`, the question is therefore:

> **"How cheaply can the machine calculate with this value?"**

---

## ✋ Local Variable — Holding a Number in Your Hand

A local variable is like holding a number while doing a calculation.

```text
function starts
      ↓
hold number
      ↓
use number
      ↓
function ends
      ↓
number is gone
```

For example:

```solidity
uint256 absTick = ...;
```

`absTick` is not permanent blockchain storage.

That is why storage packing is irrelevant to our actual TickMath experiment.

---

## 🗄️ State Variable — The Filing Cabinet

A state variable is different.

Imagine putting a number into a filing cabinet.

```text
State variable
      ↓
Blockchain storage
      ↓
Storage slot
```

Now the question becomes:

> **"How efficiently can I store this number?"**

This is where smaller integer types can become useful for a different reason.

---

## 📦 Storage Packing — Putting Toys in One Box

Imagine a storage compartment with a fixed size.

A `uint256` can fill the whole compartment:

```text
┌────────────────────────────┐
│           uint256           │
└────────────────────────────┘
```

Several smaller variables can potentially share one slot:

```text
┌──────┬────────┬────────────┐
│ 24   │   32   │     64     │
└──────┴────────┴────────────┘
```

That is **storage packing**.

So:

```text
Smaller state variables
        ↓
More variables may fit in one slot
        ↓
Potentially fewer storage slots
```

### ⚠️ Important

This does **not** mean:

```text
uint24 SSTORE = 1/10 of uint256 SSTORE
```

A storage slot is still a fixed-size slot.

The important benefit is:

> **Several small state variables may share one slot.**

---

## 🤖 The Compiler — The Translator

You write:

```solidity
uint24 absTick;
```

But the EVM does not directly execute Solidity source code.

Think of the compiler as a translator:

```text
Solidity
   ↓
Compiler
   ↓
EVM instructions
```

Two Solidity implementations that look almost identical can therefore produce different machine-level code.

---

## 📝 IR — The Translator's Rough Draft

IR is like the compiler's rough draft.

```text
Solidity
   ↓
IR
```

It lets us see how the compiler represents the program internally.

But we should **not count every IR helper as one EVM instruction**.

The optimizer may later:

```text
remove it
combine it
inline it
replace it
```

---

## ✨ Optimized IR — The Cleaned-Up Draft

Think of optimized IR as the compiler saying:

> "I can simplify this."

```text
IR
 ↓
remove unnecessary work
 ↓
combine operations
 ↓
optimized IR
```

It is closer to the final machine code, but it is still an intermediate representation.

---

## ⚙️ Assembly — The Machine's Instruction List

Assembly is closer to the instructions the EVM will actually execute.

Think of it as a machine recipe:

```text
1. Take number
2. AND it
3. Compare it
4. Jump
5. Multiply
6. Shift
```

That is why assembly became useful in our investigation.

We wanted to know:

> **"What did Solidity actually turn this source code into?"**

---

## ⏱️ Gas Benchmark — A Stopwatch

Imagine two people doing the same job.

Give both a stopwatch:

```text
Person A → 7584
Person B → 7677
```

The smaller number means less measured gas for that benchmark.

That is the basic idea of a gas benchmark.

---

## 🧱 Micro-Benchmark — One LEGO Piece

When we tested only:

```solidity
uint256 absTick = ...;
```

we were testing one small LEGO piece.

That is a **micro-benchmark**.

It asks:

> **"Is this tiny part cheaper?"**

In our experiment, the `uint24` version initially looked cheaper.

---

## 🏗️ Full-Function Benchmark — The Whole LEGO Model

TickMath is the whole LEGO model.

It contains:

```text
absTick
   ↓
require
   ↓
many bit tests
   ↓
many possible multiplications
   ↓
possible inversion
   ↓
final scaling
   ↓
uint160 result
```

The full-function benchmark asks:

> **"Is the complete model actually cheaper?"**

That is where the answer changed.

---

## 🔀 Local Optimization vs. Global Optimization

Imagine you find a shortcut that makes one road faster:

```text
Road A
   ↓
10 minutes
```

Great.

But then the shortcut connects badly to the next roads:

```text
Road A
   ↓
shortcut
   ↓
extra traffic
   ↓
whole journey becomes slower
```

That is similar to our TickMath experiment.

The `uint24` version was cheaper in a small isolated test:

```text
Original   471
uint24     425
```

But the complete function was:

```text
Original   7584
uint24     7677
```

So:

> **A shortcut can make one small section faster while making the whole journey slower.**

---

## 📏 Why "Smaller" Does Not Mean "Cheaper"

Imagine a tiny suitcase.

You might think:

> "Tiny suitcase = easier."

But imagine the airport machines are designed around one standard suitcase size.

The tiny suitcase may need special handling.

The important question is not only:

```text
How big is the suitcase?
```

but also:

```text
How does the whole system handle it?
```

That is a useful mental model for Solidity integer types and the EVM.

---

## 🔄 The Hybrid — Small Box, Then Standard Box

The hybrid was:

```solidity
uint24 absTick24 = ...;
uint256 absTick = uint256(absTick24);
```

Think:

```text
calculate
   ↓
small box
   ↓
immediately move the value
   ↓
standard box
   ↓
continue normally
```

That gave:

```text
Original   7584
Hybrid     7591
```

Only a 7-gas difference.

So the experiment strongly suggests that **keeping the value narrow for the entire function is the problematic part**, rather than the initial narrowing itself.

---

# 🧒 The Whole Story in 30 Seconds

We saw:

```text
absTick <= 887272
```

and thought:

> "Why not use `uint24`?"

We tested it.

### Tiny test

```text
uint24 → cheaper ✅
```

### Bigger test

```text
advantage gets smaller
```

### Whole function

```text
uint24 → more expensive ❌
```

### Hybrid

```text
uint24 → uint256 → almost the same as original
```

So we learned:

> **The EVM does not automatically become cheaper just because Solidity says a number is smaller.**

That is why:

```text
uint256
```

can be the better choice even when:

```text
uint24
```

is mathematically large enough.

---

# 🧠 The Big Memory Map

When you forget the details, remember this:

```text
                 ┌─────────────────────┐
                 │     Solidity        │
                 └──────────┬──────────┘
                            ↓
                    "uint24 is smaller"
                            ↓
                 ┌─────────────────────┐
                 │      Compiler       │
                 └──────────┬──────────┘
                            ↓
                    generated EVM code
                            ↓
                 ┌─────────────────────┐
                 │        EVM          │
                 └──────────┬──────────┘
                            ↓
                 256-bit execution world
                            ↓
             smaller type ≠ cheaper execution
```

And for storage:

```text
Local variable
    ↓
EVM execution
    ↓
think about computation

State variable
    ↓
Storage slots
    ↓
think about packing
```

---

# 🎯 Final Child-Friendly Rule

> **Do not ask only, "How small can I make the number?"**
>
> Ask:
>
> **"What does the machine have to do with that number after I make it smaller?"**
>
> That is the heart of this entire TickMath investigation.
