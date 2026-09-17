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
--
--  LIMITATION — magnetic fields: the Lorentz force F = q (v × B) depends on
--  velocity, while Velocity-Verlet evaluates forces from positions only.
--  When B /= 0, Step automatically switches to the Boris pusher below
--  (Boris 1970), which rotates the velocity with the exact gyro-angle and
--  preserves |v_perp| to machine precision. E-field/gravity kicks stay
--  second-order Verlet; see the body for the sequence.
package Integrator is

    --  Advance all N particles by one step of size DT.
    --  B = 0     → classic Velocity-Verlet (symplectic, O(Δt²)).
    --  B /= 0    → Boris pusher: half E-kick, magnetic rotation, drift at
    --               v(+), force re-eval, second half E-kick.
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
