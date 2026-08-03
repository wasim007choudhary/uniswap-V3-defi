# Getting the Spot Price from Uniswap V3: `slot0`

Before learning how to calculate the spot price, we first need to know **where the current price information is stored.**

Unlike Uniswap V2, where the spot price was derived from the pool reserves, Uniswap V3 stores dedicated values that allow us to determine the current spot price.

---

# Uniswap V2 vs Uniswap V3

## Uniswap V2

In Uniswap V2, the Pool (Pair) contract stores:

```text
reserve0

reserve1
```

The current spot price is then calculated as:

```text
price = reserve1 / reserve0
```

The protocol does **not** explicitly store the current price.

Instead, it stores the reserves, and the price is **derived** from them.

---

## Uniswap V3

Uniswap V3 takes a different approach.

Instead of storing reserves and deriving the price every time,

the protocol stores information that directly represents the current price.

This information is stored inside the `UniswapV3Pool` contract.

---

# Where Is the Spot Price Stored?

Inside every `UniswapV3Pool` contract is a state variable called:

```solidity
slot0
```

This variable stores a struct named `Slot0`.

```solidity
struct Slot0 {
    uint160 sqrtPriceX96;
    int24 tick;
    uint16 observationIndex;
    uint16 observationCardinality;
    uint16 observationCardinalityNext;
    uint8 feeProtocol;
    bool unlocked;
}

Slot0 public override slot0;
```

Although this struct contains several values,

the two most important ones for determining the current spot price are:

- `tick`
- `sqrtPriceX96`

Knowing **either one** of these values is enough to calculate the current spot price.

The remaining variables are used for other protocol features such as oracle observations, protocol fees, and pool state.

---

# Understanding `Slot0`

Notice that the lesson says there is a **struct** called `Slot0`.

A struct is simply a way to group related pieces of data together.

Instead of declaring several independent state variables like:

```solidity
uint160 sqrtPriceX96;
int24 tick;
uint16 observationIndex;
...
```

Uniswap groups them into one structure:

```solidity
struct Slot0
```

Think of a struct as a folder.

Instead of leaving papers scattered across a desk,

you place all related papers into a single folder.

That is exactly what `Slot0` does.

---

# Why Are `tick` and `sqrtPriceX96` Both Stored?

The lesson states:

> Knowing either `tick` or `sqrtPriceX96` is enough to calculate the spot price.

This means both values represent the **same market price**, just in different forms.

For example:

```text
Tick
    │
    ▼
 Spot Price
```

and

```text
sqrtPriceX96
        │
        ▼
   Spot Price
```

Both ultimately describe the same current price.

A simple analogy is temperature.

These two values:

```text
25°C
```

and

```text
77°F
```

look different,

but they represent the same temperature.

Similarly,

`tick` and `sqrtPriceX96` are simply two different representations of the same spot price.

We'll learn how to convert each of them into the actual price in the following lessons.

---

# Why Is It Called `slot0`?

The name comes from the Ethereum Virtual Machine (EVM).

Every smart contract stores its state variables inside **storage slots**.

Each storage slot can store:

```text
32 Bytes

=

256 Bits
```

Imagine contract storage as an apartment building.

```text
Storage

Room 0

Room 1

Room 2

Room 3
```

Each room can store:

```text
32 Bytes
```

When Solidity lays out storage,

it places state variables into these storage slots.

---

# Why Does `Slot0` Fit Into One Storage Slot?

Let's add the sizes together.

```text
uint160  = 20 Bytes
int24    =  3 Bytes
uint16   =  2 Bytes
uint16   =  2 Bytes
uint16   =  2 Bytes
uint8    =  1 Byte
bool      = 1 Byte
-----------------------
Total    = 31 Bytes
```

One storage slot can hold:

```text
32 Bytes
```

Since the entire struct is only **31 Bytes**,

everything fits inside a single storage slot.

Therefore,

the entire struct is stored in:

```text
Storage Slot 0
```

---

# Is `slot0` a Special Solidity Keyword?

No.

`slot0` is **not** a predefined Solidity keyword.

It is simply the variable name chosen by the Uniswap developers.

For example, these would all be valid:

```solidity
Slot0 public poolState;
```

```solidity
Slot0 public currentState;
```

```solidity
Slot0 public state;
```

The developers chose the name:

```solidity
Slot0 public slot0;
```

because the variable is stored inside **Storage Slot 0**.

Notice the difference:

```solidity
struct Slot0
```

- `Slot0` (capital **S**) → The **struct type**.

```solidity
Slot0 public slot0;
```

- First `Slot0` → The struct type.
- Second `slot0` → The state variable.

This is similar to writing:

```solidity
struct Person {
    string name;
}

Person public person;
```

where:

- `Person` is the type.
- `person` is the variable.

An important point:

The name **does not** determine where it is stored.

It is stored in **Storage Slot 0** because it is the first state variable in the contract's storage layout and the entire struct fits into a single storage slot.

The developers simply named it `slot0` because it accurately describes where it lives.

---

# Why Pack Everything Into One Storage Slot?

The main reason is:

> **Gas Optimization**

Reading from contract storage is expensive.

Suppose every variable inside `Slot0` were stored in a separate storage slot.

Reading:

- `tick`
- `sqrtPriceX96`
- `feeProtocol`

would require multiple storage reads.

Instead,

the EVM reads one 32-byte storage slot and immediately has access to all of these values.

Fewer storage reads

↓

Lower gas costs.

This optimization is called **Storage Packing**, and it is a common Solidity optimization—not something unique to Uniswap.

---

# Real-World Example

Reading `slot0()` from the WETH/USDT Uniswap V3 Pool returns values similar to:

```text
tick = -195301

sqrtPriceX96 = 4551852809367933182694918
```

Don't worry about these numbers yet.

The important point is that these values are the current state stored by the Pool.

In the next lessons, we'll learn how to convert:

- `tick`
- `sqrtPriceX96`

into the actual spot price.

---

# Key Takeaways

- Uniswap V3 stores the current price information inside the `UniswapV3Pool` contract.
- The Pool exposes this information through the `slot0` state variable.
- `slot0` is a struct that groups together several frequently accessed values.
- The two most important values for determining the current spot price are:
  - `tick`
  - `sqrtPriceX96`
- Either `tick` or `sqrtPriceX96` is sufficient to calculate the current spot price.
- `slot0` is named after **Storage Slot 0**, where the packed struct is stored.
- `slot0` is **not** a Solidity keyword; it is simply the variable name chosen by the Uniswap developers.
- The struct fits into one 32-byte storage slot through **storage packing**, reducing gas costs.
- The next step is learning how `tick` and `sqrtPriceX96` are converted into the actual market price.