with Particle;
with Vec3;

--  Störmer–Verlet (Velocity Verlet) symplectic integrator, 2nd-order.
--
--  The algorithm for a single time step Δt:
--
--    (1) Half-kick:   v(t + Δt/2) = v(t)        + (Δt/2) · F(t)/m
--    (2) Drift:       r(t + Δt)   = r(t)         + Δt    · v(t + Δt/2)
--    (3) Force eval:  F(t + Δt)   from r(t + Δt)
--    (4) Half-kick:   v(t + Δt)   = v(t + Δt/2) + (Δt/2) · F(t + Δt)/m
--
--  Being symplectic, the method conserves a modified Hamiltonian exactly,
--  so total energy oscillates around a fixed value (no secular drift).
--  Global energy error is O(Δt²); local truncation error is O(Δt³).
package Integrator is

   --  Advance all N particles by one step of size DT.
   --  Computes forces at the new positions internally (step 3 above).
   procedure Step
     (Particles : in out Particle.Array_Type;
      N         : Positive;
      DT        : Long_Float;
      B_Field   : Vec3.Vector);

   --  Courant-like criterion for an adaptive time step:
   --    Δt = η · min_i √(ε_soft / |a_i|)
   --  with safety factor η = 0.01.
   --  Result is clamped to [1e-25, 1e-10] seconds.
   function Adaptive_DT
     (Particles : Particle.Array_Type;
      N         : Positive) return Long_Float;

end Integrator;
