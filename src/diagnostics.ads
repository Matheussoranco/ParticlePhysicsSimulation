with Particle;
with Vec3;

--  Conserved-quantity diagnostics for an N-particle system.
--
--  Kinetic energy:      T   = Σ_i ½ m_i |v_i|²
--  Gravitational PE:    V_g = −Σ_{i<j} G m_i m_j / √(r_ij² + ε²)
--  Electrostatic PE:    V_e =  Σ_{i<j} Ke q_i q_j / √(r_ij² + ε²)
--  Total energy:        E   = T + V_g + V_e
--  Linear momentum:     p   = Σ_i m_i v_i
--  Angular momentum:    L   = Σ_i m_i (r_i × v_i)
--  Energy drift:        δ   = |E(t) − E₀| / |E₀|
package Diagnostics is

   type Snapshot is record
      Kinetic_Energy        : Long_Float    := 0.0;
      Potential_Energy      : Long_Float    := 0.0;
      Total_Energy          : Long_Float    := 0.0;
      Linear_Momentum       : Vec3.Vector   := Vec3.Zero;
      Angular_Momentum      : Vec3.Vector   := Vec3.Zero;
      COM_Position          : Vec3.Vector   := Vec3.Zero;
      Relative_Energy_Drift : Long_Float    := 0.0;
   end record;

   --  Full snapshot including drift relative to Initial_Energy.
   function Compute
     (Particles      : Particle.Array_Type;
      N              : Positive;
      Initial_Energy : Long_Float) return Snapshot;

   --  Individual components (useful for testing and initial-energy capture).
   function Kinetic_Energy   (Particles : Particle.Array_Type; N : Positive) return Long_Float;
   function Potential_Energy (Particles : Particle.Array_Type; N : Positive) return Long_Float;

end Diagnostics;
