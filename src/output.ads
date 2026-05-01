with Ada.Text_IO;
with Particle;
with Diagnostics;

--  Structured CSV output to trajectory.csv and energy.csv.
--
--  trajectory.csv columns:
--    step, time_s, id, x_m, y_m, z_m, vx_ms, vy_ms, vz_ms
--
--  energy.csv columns:
--    step, time_s, KE_J, PE_J, E_total_J,
--    px_kgms, py_kgms, pz_kgms, Lx, Ly, Lz, drift
package Output is

   procedure Open_Files (Prefix : String := "");
   procedure Close_Files;

   procedure Write_Trajectory
     (Step      : Natural;
      Time      : Long_Float;
      Particles : Particle.Array_Type;
      N         : Positive);

   procedure Write_Energy
     (Step : Natural;
      Time : Long_Float;
      S    : Diagnostics.Snapshot);

end Output;
