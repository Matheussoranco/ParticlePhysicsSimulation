# Particle Physics Simulator

A state-of-the-art classical N-body particle simulator written in Ada (GNAT/Ada 2012).
Models gravitational and electromagnetic interactions between subatomic particles using
a symplectic Störmer–Verlet integrator with Plummer softening, producing CSV trajectory
and energy-conservation diagnostics.

---

## Table of Contents

1. [Physical Model](#1-physical-model)
2. [Numerical Methods](#2-numerical-methods)
3. [Force Kernel](#3-force-kernel)
4. [Integrator Theory](#4-integrator-theory)
5. [Energy Diagnostics](#5-energy-diagnostics)
6. [Built-in Scenarios](#6-built-in-scenarios)
7. [Software Architecture](#7-software-architecture)
8. [Building](#8-building)
9. [Running](#9-running)
10. [Output Format](#10-output-format)
11. [References](#11-references)

---

## 1. Physical Model

### 1.1 Degrees of Freedom

The system consists of N classical point particles, each characterised by:

| Symbol | Quantity | SI Unit |
|--------|----------|---------|
| r_i(t) | position | m |
| v_i(t) | velocity | m/s |
| m_i | rest mass | kg |
| q_i | electric charge | C |

### 1.2 Equations of Motion

Newtonian mechanics with all pairwise interactions plus an optional uniform
external magnetic field B (Lorentz force term):

    m_i * r_i'' = SUM_{j != i} F_ij  +  q_i * (v_i x B)

### 1.3 Physical Constants (CODATA 2018)

| Constant | Symbol | Value |
|----------|--------|-------|
| Gravitational constant | G | 6.67430e-11 m^3 kg^-1 s^-2 |
| Coulomb constant | k_e = 1/(4*pi*eps_0) | 8.9875517923e+9 N m^2 C^-2 |
| Speed of light | c | 2.99792458e+8 m/s |
| Elementary charge | e | 1.602176634e-19 C |
| Electron mass | m_e | 9.1093837015e-31 kg |
| Proton mass | m_p | 1.67262192369e-27 kg |
| Bohr radius | a_0 | 5.29177210903e-11 m |
| Bohr velocity | v_0 = alpha*c | 2.18769126277e+6 m/s |
| Fine-structure constant | alpha | 7.2973525693e-3 |

All floating-point arithmetic uses `Long_Float` (IEEE 754 binary64) throughout,
giving 15–17 significant decimal digits and machine epsilon ~2.22e-16.

### 1.4 Validity and Approximations

This is a **classical non-relativistic** simulation:

- Relativity is neglected; valid for v << c. At v = v_0 ≈ 0.0073c the relativistic
  correction to kinetic energy is (gamma - 1 - beta^2/2) * m*c^2 / E_k ≈ 2.7e-5.
- Quantum mechanics is absent: no wave-function, no Pauli exclusion, no tunnelling.
- Radiation reaction neglected (Larmor formula): the classical spiral-in time for
  the hydrogen atom is ~16 ps.
- No strong nuclear force: proton–neutron interactions are gravitational and
  electromagnetic only.
- Each particle's self-field is excluded.

---

## 2. Numerical Methods

### 2.1 Floating-Point Precision

`Long_Float` = IEEE 754 binary64:
- Machine epsilon: eps_mach = 2^{-52} ≈ 2.22e-16
- Range: ~5e-324 to 1.8e+308

### 2.2 Plummer Softening

The bare 1/r^2 Newtonian and Coulomb forces diverge as r → 0. Plummer (1911)
softening replaces the singular kernel:

    1/r^n  →  1/(r^2 + eps^2)^{n/2}

The softened potential and force on particle i from j become:

    Phi_soft(r)   = -G m_i m_j / sqrt(r^2 + eps^2)
    F_soft(r_ij)  = -G m_i m_j * r_ij / (|r_ij|^2 + eps^2)^{3/2}

The softening length eps = 1e-15 m (1 fm, nuclear scale) is small enough to
leave all atomic-scale physics unaffected.

---

## 3. Force Kernel

### 3.1 Pairwise Force

Net force on particle i from particle j (gravity + Coulomb, Plummer-softened):

    F_ij = [ G*m_i*m_j - k_e*q_i*q_j ] * r_ij / (|r_ij|^2 + eps^2)^{3/2}

where r_ij = r_j - r_i.

Sign convention:
- Gravity (G*m*m > 0): force along +r_ij → attractive. ✓
- Like charges (q*q > 0): k_e*q*q > 0 → force along -r_ij → repulsive. ✓
- Unlike charges (q*q < 0): k_e*q*q < 0 → force along +r_ij → attractive. ✓

### 3.2 Newton's Third Law Optimisation

Because F_{ji} = -F_{ij}, the inner loop is restricted to j > i, halving the work:

    Work = N*(N-1)/2 pair evaluations,  O(N^2)

Each pair evaluation costs ~20 FLOP: 3 subtractions (displacement), 4 multiply-adds
(dot product), 1 sqrt, 1 multiply (r*sqrt(r) = r^{3/2}), 4 multiply-adds
(coefficient + scale).

### 3.3 Lorentz Magnetic Force

For an external uniform field B:

    F_mag,i = q_i * (v_i x B)

Cross product:

    v x B = ( v_y*B_z - v_z*B_y,  v_z*B_x - v_x*B_z,  v_x*B_y - v_y*B_x )

The magnetic force does no work (F_mag · v = 0) so it cannot change kinetic energy
— a useful conservation check.

---

## 4. Integrator Theory

### 4.1 Störmer–Verlet (Velocity Verlet) Algorithm

Given state (r^n, v^n) and accelerations a^n = F^n/m, one step of size dt:

    (1)  v^{n+1/2} = v^n        +  (dt/2) * a^n         [half-kick]
    (2)  r^{n+1}   = r^n        +  dt     * v^{n+1/2}    [drift]
    (3)  a^{n+1}   = F(r^{n+1}) / m                      [force eval]
    (4)  v^{n+1}   = v^{n+1/2}  +  (dt/2) * a^{n+1}     [half-kick]

One force evaluation per step. Equivalent to the leapfrog scheme in synchronised form.

### 4.2 Symplecticity and Energy Conservation

The Velocity Verlet map Phi_dt: (r, p) → (r', p') is symplectic:

    J_Phi^T * omega * J_Phi = omega,   omega = [ 0  I ; -I  0 ]

Consequence: the method conserves a **modified Hamiltonian**
H_tilde = H + O(dt^2) exactly (to machine precision), so total energy
oscillates around a fixed value with no secular drift. This makes Velocity
Verlet far superior to non-symplectic methods (Euler, RK4) for long-time
simulations.

### 4.3 Accuracy Comparison

| Method | Local error | Global error | Symplectic | Force evals/step |
|--------|-------------|--------------|------------|-----------------|
| Euler | O(dt^2) | O(dt) | No | 1 |
| Velocity Verlet | O(dt^3) | O(dt^2) | **Yes** | **1** |
| RK4 | O(dt^5) | O(dt^4) | No | 4 |
| Forest-Ruth (4th order symplectic) | O(dt^5) | O(dt^4) | **Yes** | 3 |

RK4 achieves higher formal order but is not symplectic; energy drifts secularly.
Velocity Verlet has bounded energy error for all time.

### 4.4 Adaptive Time Step

Courant-like criterion based on local acceleration magnitude:

    dt_adapt = eta * min_i sqrt(eps_soft / |a_i|)

with safety factor eta = 0.01. This ensures no particle travels more than
~eta * eps_soft per step. Result is clamped to [1e-25, 1e-10] seconds.

---

## 5. Energy Diagnostics

### 5.1 Conserved Quantities (isolated system)

    E = T + V        (total mechanical energy)
    p = SUM m_i v_i  (linear momentum)
    L = SUM m_i (r_i x v_i)  (angular momentum)

### 5.2 Kinetic Energy

    T = SUM_{i=1}^N  (1/2) m_i |v_i|^2

Relativistic correction (informational, not used in EOM):

    T_rel = SUM (gamma_i - 1) m_i c^2,   gamma_i = 1/sqrt(1 - v_i^2/c^2)
    T_rel = T + (3/8) m v^4/c^2 + O(v^6/c^6)

### 5.3 Potential Energy (Plummer-softened)

    V = SUM_{i<j} [ -G*m_i*m_j + k_e*q_i*q_j ] / sqrt(r_{ij}^2 + eps^2)

### 5.4 Relative Energy Drift

    delta(t) = |E(t) - E_0| / |E_0|

A well-tuned Velocity Verlet run of the hydrogen atom achieves delta < 1e-5
over 10^4 orbital periods.

---

## 6. Built-in Scenarios

### 6.1 Hydrogen Atom (`hydrogen`)

Classical circular electron orbit about a stationary proton.

| Quantity | Value | Formula |
|----------|-------|---------|
| Orbital radius | a_0 = 5.292e-11 m | Bohr radius |
| Electron speed | v_0 = 2.188e+6 m/s | sqrt(k_e e^2 / m_e a_0) = alpha*c |
| Orbital period | T_0 = 1.520e-16 s | 2*pi*a_0 / v_0 |
| Total energy | E_0 = -2.180e-18 J | -k_e e^2 / (2 a_0) = -Ry |
| Time step | dt = 5e-19 s | T_0 / 304 |

The proton recoil velocity per orbit is ~v_0 * m_e/m_p ≈ 1190 m/s, introducing a
relative error of ~5e-4 in the orbital radius compared to the fixed-proton ideal.

### 6.2 Electron–Positron Pair (`ep`)

Symmetric circular orbit of e^- and e^+ about their common centre of mass.

    Separation d = 2 a_0;  reduced mass mu = m_e/2
    Centripetal condition: mu*v^2 / (d/2) = k_e*e^2 / d^2
    => v = v_0 / 2 ≈ 1.094e+6 m/s

    Period: T = 4*pi*a_0 / v_0 ≈ 6.079e-16 s

Classical angular momentum of each particle:

    L = m_e * v * a_0 = m_e * (alpha*c/2) * a_0 = hbar/2

Equal to one half of hbar — coincidentally the quantum spin eigenvalue.

### 6.3 Cyclotron Motion (`cyclotron`)

Single electron in uniform axial field B = B_0 * z_hat, B_0 = 1 T.

    Larmor radius:       r_L = m_e * v_0 / (e * B_0) ≈ 5.69e-12 m
    Cyclotron frequency: omega_c = e*B_0 / m_e ≈ 1.759e+11 rad/s
    Cyclotron period:    T_c = 2*pi*m_e / (e*B_0) ≈ 3.571e-11 s

Diagnostic: |v_i| must remain constant to machine precision since the magnetic
force does no work. Any change is pure integrator error.

### 6.4 Rutherford Alpha Scattering (`alpha`)

Alpha particle (A=4, Z=2) approaching gold nucleus (A=197, Z=79).

Initial conditions:
- Alpha starts at x = -300 fm, y = b = 10 fm, vx = +1.43e+7 m/s
  (kinetic energy ~4.27 MeV, matching typical ^238U alpha decay)
- Gold nucleus at origin (essentially stationary: M_Au/M_alpha ≈ 49)

Classical closest approach (head-on, b=0):

    r_min = k_e * Z_1 * Z_2 * e^2 / E_k ≈ 53 fm

Rutherford scattering formula (Coulomb potential only):

    cot(theta/2) = 2*E_k*b / (k_e * Z_1 * Z_2 * e^2)

For b = 10 fm, E_k = 6.84e-13 J: predicted theta ≈ 61 degrees.

### 6.5 Random N-Body (`nbody`)

N particles (alternating proton / electron) placed uniformly in a sphere of
radius 50 a_0 with random velocities up to 0.1 v_0. Initial conditions generated
by a deterministic xorshift32 PRNG (seed 20240101) for reproducibility.

---

## 7. Software Architecture

```
particle_sim/
├── src/
│   ├── constants.ads        Physical constants (CODATA 2018)
│   ├── vec3.ads / .adb      3D vector algebra (Long_Float record type)
│   ├── particle.ads / .adb  Particle state record + factory functions
│   ├── forces.ads / .adb    Pairwise force kernel (gravity + Coulomb + Lorentz)
│   ├── integrator.ads/.adb  Störmer-Verlet integrator + adaptive time step
│   ├── diagnostics.ads/.adb Energy, momentum, angular momentum
│   ├── output.ads / .adb    CSV file writer (trajectory + energy)
│   ├── scenarios.ads / .adb Initial conditions for all built-in scenarios
│   ├── simulator.ads / .adb Main time-loop orchestrator
│   └── main.adb             CLI entry point
├── obj/                     GNAT compiled objects (auto-created)
├── particle_sim.gpr         GNAT project file
└── README.md
```

Package dependency graph (no circular dependencies):

```
constants
    └── vec3
            └── particle
                    ├── forces
                    │     └── integrator (calls forces internally)
                    ├── diagnostics
                    ├── output
                    └── scenarios
                              └── simulator
                                        └── main
```

### Design Rationale

| Decision | Rationale |
|----------|-----------|
| `Long_Float` throughout | IEEE 754 binary64; 2x the significant digits of `Float` |
| Plummer softening | Regularises singularity without event detection or adaptive collision handling |
| Newton's 3rd law pair loop | Exactly halves force evaluation cost |
| Velocity Verlet over RK4 | Symplectic: bounded energy error for all time; 1 force eval/step vs. 4 |
| Fixed-size Array_Type(1..512) | Avoids heap allocation; Ada safety-critical style |
| Scenario factory pattern | Clean separation of physics setup from integration machinery |

---

## 8. Building

### Requirements

- GNAT FSF GCC >= 12 (or GNAT Community / Pro)
- `gprbuild` (bundled with GNAT)

### Build with gprbuild (recommended)

```bash
gprbuild -P particle_sim.gpr
```

Produces `./particle_sim` (Linux/macOS) or `particle_sim.exe` (Windows).

### Build with gnatmake

```bash
mkdir -p obj
gnatmake -O2 -gnat2012 -gnata -gnatwa \
         -I src -D obj \
         src/main.adb -o particle_sim
```

---

## 9. Running

```
./particle_sim [scenario] [N]

Scenarios:
  hydrogen        Classical H atom (default)
  ep              Electron-positron pair orbit
  cyclotron       Electron in 1 T axial magnetic field
  alpha           Rutherford alpha scattering off gold
  nbody [N]       Random N-body mixed plasma (default N=20)
```

---

## 10. Output Format

### trajectory.csv

One row per particle per output stride:

| Column | Description | Unit |
|--------|-------------|------|
| step | step index | — |
| time_s | simulation time | s |
| id | particle ID | — |
| x_m, y_m, z_m | position | m |
| vx_ms, vy_ms, vz_ms | velocity | m/s |

### energy.csv

One row per output stride:

| Column | Description | Unit |
|--------|-------------|------|
| step | step index | — |
| time_s | simulation time | s |
| KE_J | kinetic energy | J |
| PE_J | potential energy | J |
| E_total_J | total energy | J |
| px/py/pz_kgms | linear momentum components | kg m/s |
| Lx/Ly/Lz | angular momentum components | kg m^2/s |
| drift | relative energy drift |E(t)-E0|/|E0| | — |

### Quick Python visualisation

```python
import pandas as pd, matplotlib.pyplot as plt

traj = pd.read_csv("trajectory.csv")
eng  = pd.read_csv("energy.csv")

# Orbital trajectory — electron (id=2)
e = traj[traj.id == 2]
plt.figure(); plt.plot(e.x_m, e.y_m, lw=0.3)
plt.xlabel("x [m]"); plt.ylabel("y [m]")
plt.title("Electron orbit — Hydrogen atom"); plt.axis("equal"); plt.show()

# Energy conservation
plt.figure(); plt.semilogy(eng.time_s, eng.drift)
plt.xlabel("t [s]"); plt.ylabel("|dE|/|E0|")
plt.title("Relative energy drift (Velocity Verlet)"); plt.show()
```

---

## 11. References

1. Störmer, C. (1907). Sur les trajectoires des corpuscules électrisés.
   *Archives des sciences physiques et naturelles*, 24, 5–18.

2. Verlet, L. (1967). Computer "Experiments" on Classical Fluids.
   *Physical Review*, 159(1), 98–103.

3. Leimkuhler, B. & Reich, S. (2004). *Simulating Hamiltonian Dynamics*.
   Cambridge University Press.

4. Hairer, E., Lubich, C. & Wanner, G. (2006). *Geometric Numerical Integration*,
   2nd ed. Springer.

5. Plummer, H.C. (1911). On the Problem of Distribution in Globular Star Clusters.
   *Monthly Notices of the Royal Astronomical Society*, 71, 460–470.

6. CODATA 2018 recommended values. NIST.
   https://physics.nist.gov/cuu/Constants/

7. Rutherford, E. (1911). The Scattering of alpha and beta Particles by Matter
   and the Structure of the Atom. *Philosophical Magazine*, 21(125), 669–688.

8. Barnes, J. & Hut, P. (1986). A hierarchical O(N log N) force-calculation
   algorithm. *Nature*, 324, 446–449. (Future extension: Barnes-Hut octree.)

---

## Licence

MIT — see `LICENSE`.
