with Particle;
with Vec3;

--  Pairwise force engine: gravitational attraction + Coulomb electrostatics
--  + Lorentz magnetic force from an external uniform field.
--
--  Force on particle i from particle j with Plummer softening ε:
--
--    r_ij  = r_j − r_i
--    denom = (|r_ij|² + ε²)^(3/2)
--    F_grav =  G  m_i m_j  r_ij / denom     (always attractive)
--    F_em   = −Ke q_i q_j  r_ij / denom     (sign: like→repulsive, unlike→attractive)
--
--  Newton's 3rd law is exploited: only i < j pairs are evaluated, and the
--  reaction −F is accumulated simultaneously, halving the work to O(N²/2).
--
--  Magnetic Lorentz force (external field B, no self-field):
--    F_mag = q_i (v_i × B)
package Forces is

   --  Compute and accumulate forces for particles 1..N into each State.Force.
   --  Forces are zeroed before accumulation.
   procedure Compute_All
     (Particles : in out Particle.Array_Type;
      N         : Positive;
      B_Field   : Vec3.Vector);

   --  Force on Pi exerted by Pj (gravity + Coulomb, Plummer-softened).
   --  Exposed separately for unit testing and benchmarking.
   function Pair_Force (Pi, Pj : Particle.State) return Vec3.Vector;

end Forces;
