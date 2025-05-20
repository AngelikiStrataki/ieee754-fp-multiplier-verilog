# ieee754-fp-multiplier-verilog
# IEEE 754 Single-Precision Floating Point Multiplier – SystemVerilog Project

## Overview
This project implements and verifies a 32-bit **IEEE 754 compliant single-precision floating point multiplier**, written in **SystemVerilog**. It includes a top-level multiplier module along with supporting submodules for **normalization**, **rounding**, and **exception handling**, as well as full verification through testbenches.

> 📘 **Note:** The accompanying project report is written in Greek.

---

## 🧱 Modules Included

### ✅ `fp_mult.sv`
Main top-level multiplier unit:
- Integrates the submodules `normalize_mult`, `round_mult`, and `exception_mult`.
- Accepts two 32-bit floating point operands and outputs the product with status flags.

### 🔁 `normalize_mult.sv`
- Normalizes the intermediate mantissa product.
- Adjusts the exponent accordingly to maintain IEEE 754 compliance.

### 🔄 `round_mult.sv`
- Rounds the normalized mantissa based on the rounding mode (`rnd` input).
- Handles rounding to nearest, zero, +∞, or −∞ depending on IEEE rounding rules.

### ⚠️ `exception_mult.sv`
- Detects and handles exceptional cases:
  - Overflow
  - Underflow
  - NaN
  - Infinity
- Sets appropriate status flags for each condition.

---

## 🧪 Verification

### 🧾 `1.sv`
- Main testbench for `fp_mult`.
- Initializes signals, generates clock, and applies a combination of random and edge-case test vectors.
- Simulations were run in **ModelSim** and confirmed functional correctness across all tested cases.

### ⚙️ `2.sv`
- Includes additional test modules:
  - `test_dut`
  - `test_status_bits`
  - `test_status_z_combinations`
- Modules are connected using **SystemVerilog `bind`** constructs.
- Contains known bugs; some expected outputs were not produced correctly.

---

## 🧰 Tools Used

- Language: SystemVerilog
- Simulation: ModelSim
- Testbench Style: Procedural + Modular bind-based verification
- Precision Standard: IEEE 754 (single-precision)

---

## 📂 File Summary

| File              | Description                                         |
|-------------------|-----------------------------------------------------|
| `fp_mult.sv`       | Top-level floating point multiplier                |
| `normalize_mult.sv`| Normalization module                               |
| `round_mult.sv`    | Rounding logic module                              |
| `exception_mult.sv`| Exception handler module                           |
| `1.sv`             | Main testbench with full signal setup              |
| `2.sv`             | Advanced testbench using bind constructs (WIP)     |
| `STRATAKI_10523.pdf` | Project report (in Greek)                        |

---

## 👩‍💻 Author

- Angeliki Strataki  
- AEM: 10523  
- Course: Digital Systems – Low-Level Hardware II  
- Institution: Aristotle University of Thessaloniki (AUTH)  
- Semester: Spring 2024  

---

## 📄 License

This project is intended for academic and educational use only.
