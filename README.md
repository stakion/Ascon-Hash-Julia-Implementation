# Ascon-Hash-Julia-Implementation
> **Lightweight Cryptography · Sponge-Based Hashing · NIST Standard 2023**  
> Implementation of the Ascon-Hash algorithm in Julia, validated against Python and VHDL reference implementations.


## 📌 Overview
The **Ascon** family of algorithms are authenticated encryption and hashing algorithms designed to be lightweight and easy to implement — including built-in resistance to side-channel attacks. They were selected as the primary option for lightweight authenticated encryption/hashing, advancing to the final round of the **CAESAR competition (2014–2019)** and becoming the new standard in the **NIST Lightweight Cryptography competition (2019–2023)**.

This repository contains a Julia implementation of **Ascon-Hash**, built and validated in parallel with an existing Python reference and a VHDL hardware implementation.
<br>


## ✨ Key Features of the Ascon Family
| Feature | Description |
|---------|-------------|
| 🧽 **Sponge-based** | SPN-based custom permutation with sponge construction |
| 🔒 **Provable security** | Key-finalized secure mode for additional robustness |
| ⚡ **Lightweight** | Small state, simple permutation — designed for constrained devices |
| 🖥️ **SW & HW efficient** | Pipelineable, bit-sliced 5-bit S-box for 64-bit architectures |
| 🔑 **Scalable security** | Key size = tag size = security level (128 bits recommended) |
| 🛡️ **Side-channel resistant** | S-box optimized for countermeasures; no table lookups or additions |
| 📦 **Zero overhead** | Ciphertext length = plaintext length |
| 🔄 **Single-pass** | Online (encryption and decryption), nonce-based, non-invertible |
<br>


## 🧮 Algorithm Description
The core operation of the Ascon family — used in both encryption and hash generation — is the **Ascon Permutation**. It operates on a **320-bit state** (built from five 64-bit words: `x₀ … x₄`) and consists of three stages:

### Permutation Stages
**`pC` — Constant Addition Layer**  
Directly affects the third 64-bit word (`x₂`) by XOR-ing a round-dependent constant at each round of the permutation.
<br>

**`pS` — Substitution Layer (S-Box)**  
A non-linear substitution box applied vertically across all five 64-bit words. It takes 1 bit from each word as input and produces 5 bits of output, repeating the process 64 times. Can be implemented via logical expression or a look-up table.
<br>

**`pL` — Linear Layer**  
Applies horizontal diffusion to each of the five 64-bit words using circular right-rotations and XOR operations. Each word is rotated by two different offsets and XOR-ed with itself.
<br>

> Full permutation: `p = pL ∘ pS ∘ pC`

### Ascon-Hash Pseudocode
```
Input:  Message M ∈ {0,1}*
        Output size (bits): ℓ ≤ h, or ℓ arbitrary if h = 0
Output: Hash H ∈ {0,1}^ℓ

Initialization:
  S ← p^a(IV_{h,r,a,b} ‖ 0^c)

Message Absorption:
  M₁ … Mₛ ← M ‖ 1 ‖ 0*
  for i = 1, …, s do
    S ← p^b((S_r ⊕ Mᵢ) ‖ S_c)
  S_r ← S_r ⊕ Mₛ

Squeezing:
  S ← p^a(S)
  for i = 1, …, t = ⌈ℓ/r⌉ do
    Hᵢ ← S_r
    S ← p^b(S)
  return ⌊H₁ ‖ … ‖ Hₜ⌋_ℓ  (truncated to ℓ bits)
```
<br>


## 🗂️ Project Structure
```
Ascon_12.jl
├── Utility Functions
│   ├── zero_bytes(n)
│   ├── to_bytes(l)
│   ├── bytes_to_int(b_bytes)
│   ├── int_to_bytes(integer, nbytes)
│   ├── vector_byte_to_state(a_bytes)
│   ├── NS_HEX(SS, n)
│   ├── RR_64(x, n)
│   ├── Concatenate_Array(aux_array_00)
│   └── Print_state_S(aux_S, aux_message)
├── Permutation Layers
│   ├── Ascon_Sbox_00(S)       ← logical expression
│   ├── Ascon_S_box_01(...)    ← look-up table (LUT)
│   ├── Ascon_Sbox_02(S)       ← decomposed logical expression
│   └── Ascon_Linear_Layer(S)
├── Core Algorithm
│   ├── Ascon_Permutation(S, rounds)
│   └── Ascon_HASH(message, variant, hashlength)
└── Test Vectors
    └── HOLAA · HOLAe · HOLAI · HOLAo
```


## 🔧 Function Reference
### Utility Functions
| Function | Description |
|---|---|
| `zero_bytes(n)` | Returns a vector of `n` zero-initialized `UInt8` bytes |
| `to_bytes(l)` | Converts each element of a list to `UInt8` and collects into a `Vector{UInt8}` |
| `bytes_to_int(b_bytes)` | Converts an 8-element byte array into a 64-bit unsigned integer (big-endian) |
| `int_to_bytes(integer, nbytes)` | Converts an integer to its byte representation with `nbytes` bytes |
| `vector_byte_to_state(a_bytes)` | Converts a 40-byte vector to a 5-word × 64-bit Ascon state |
| `NS_HEX(SS, n)` | Normalizes hex string output to `n/4` characters per element (debug utility) |
| `RR_64(x, n)` | Circular right rotation of a 64-bit word by `n` positions |
| `Concatenate_Array(aux_array_00)` | Concatenates array elements into a single hex string |
| `Print_state_S(aux_S, aux_message)` | Prints all five state words with a debug message label |

### Permutation & Hash Functions
| Function | Description |
|---|---|
| `Ascon_Sbox_00(S)` | S-Box via logical expression (compact form) |
| `Ascon_S_box_01(b0,b1,b2,b3,b4)` | S-Box via 5-bit look-up table (LUT) |
| `Ascon_Sbox_02(S)` | S-Box via decomposed logical operations (most explicit form) |
| `Ascon_Linear_Layer(S)` | Linear diffusion layer using dual-rotation XOR per word |
| `Ascon_Permutation(S, rounds)` | Full Ascon permutation: `pC → pS → pL`, iterated `rounds` times |
| `Ascon_HASH(message, variant, hashlength)` | Complete Ascon-Hash with initialization, absorption, and squeezing |


## 🚀 Usage
### Requirements
- [Julia](https://julialang.org/) `>= 1.6`
- No external packages required — uses only Julia's standard library

### Running
```bash
julia Ascon_12.jl
```

### Example
```julia
# Compute the Ascon-Hash of a message
Ascon_HASH("HOLAA")

# Using explicit variant and output length
Ascon_HASH("HOLAA", "Ascon-Hash", 32)
```

### Debug Flags
Three global flags control verbose output:
```julia
debug_variables = true    # Prints internal initialization values
debug           = true    # Prints state S at each major phase
debugpermutation = false  # Prints state S at every permutation round
```
<br>


## ✅ Test Vectors
All outputs were validated against a Python reference implementation and a VHDL hardware simulation using Vivado.
| Input | Ascon-Hash (256-bit output) |
|---|---|
| `HOLAA` | `137a059ca5a46d3f806b23fa60c658d0e6419cbe8fe2c974002480328b1b7b76` |
| `HOLAe` | `b7d5c92906480321dd7433b9d415bbf082f376a8dd53217def036a93a25d375c` |
| `HOLAI` | `58364b614dbce490ea3af3151df7eafde616e340705496835b959441a7c0e301` |
| `HOLAo` | `3f60d0bb7de7d1e124c986083d22223e81c24a314d583cd43b0fd74aa119629d` |
<br>


## 🔬 Implementation Notes
- The S-Box is implemented in three ways (`Sbox_00`, `S_box_01`, `Sbox_02`) to allow comparison between logical expressions and look-up table approaches. The active implementation in the permutation uses `Ascon_Sbox_02` (decomposed logical form).
- The linear layer uses dual circular right-rotation offsets per word: `(19, 28)`, `(61, 39)`, `(1, 6)`, `(10, 17)`, `(7, 41)` for words `x₀–x₄` respectively.
- Padding follows the Ascon specification: the message is padded with `0x80` followed by zero bytes to fill the current rate-block.
- For `Ascon-Hash` and `Ascon-Hasha`, the tag specification value is `256`; for XOF variants it is `0`.
- The parameters used are: `a = 12`, `b = 12` (matching the VHDL hardware implementation), `rate = 8 bytes`.
<br>


## 📖 References
1. Ascon Team — *Ascon Lightweight Authenticated Encryption & Hashing* — https://ascon.iaik.tugraz.at
2. Dobraunig et al. — *Ascon Specification (Round 2)* — NIST Lightweight Cryptography
3. Dobraunig et al. — *Ascon Specification (Final Round)* — NIST Lightweight Cryptography
4. Chad Boutin — *NIST Selects 'Lightweight Cryptography' Algorithms to Protect Small Devices* (2023)
5. Eichlseder et al. — *Ascon: A Family of Authenticated Encryption Algorithms* — https://github.com/ascon
6. Hashing Tools — *Ascon Hash Family* — https://hashing.tools/ascon
7. Tezcan — *Lightweight Cryptography for IoT* (2022)
<br>


## 👤 Author
**Sebastian Joel Rivett Macias**  
*MCC Student — INAOE (Instituto Nacional de Astrofísica, Óptica y Electrónica)*  
📧 sebas_mario@yahoo.com.mx
<br>


<div align="center">
*Part of a broader project comparing software and hardware implementations of Ascon — Julia (software) · VHDL (hardware, Vivado)*
</div>

