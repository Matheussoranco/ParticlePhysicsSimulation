with Ada.Text_IO;    use Ada.Text_IO;
with Ada.Strings;    use Ada.Strings;
with Ada.Strings.Fixed;

package body Output is

   Traj_File   : File_Type;
   Energy_File : File_Type;

   --  Format a Long_Float without the leading space that 'Image inserts
   --  for non-negative values.
   function Fmt (X : Long_Float) return String is
      Raw : constant String := Long_Float'Image (X);
   begin
      if Raw (Raw'First) = ' ' then
         return Raw (Raw'First + 1 .. Raw'Last);
      end if;
      return Raw;
   end Fmt;

   procedure Open_Files (Prefix : String := "") is
   begin
      Create (Traj_File,   Out_File, Prefix & "trajectory.csv");
      Create (Energy_File, Out_File, Prefix & "energy.csv");
      Put_Line (Traj_File,
                "step,time_s,id,x_m,y_m,z_m,vx_ms,vy_ms,vz_ms");
      Put_Line (Energy_File,
                "step,time_s,KE_J,PE_J,E_total_J,"
                & "px_kgms,py_kgms,pz_kgms,Lx,Ly,Lz,drift");
   end Open_Files;

   procedure Close_Files is
   begin
      Close (Traj_File);
      Close (Energy_File);
   end Close_Files;

   procedure Write_Trajectory
     (Step      : Natural;
      Time      : Long_Float;
      Particles : Particle.Array_Type;
      N         : Positive)
   is
      P : Particle.State;
   begin
      for I in 1 .. N loop
         P := Particles (I);
         Put_Line (Traj_File,
                   Ada.Strings.Fixed.Trim (Natural'Image  (Step),  Left) & ","
                   & Fmt (Time) & ","
                   & Ada.Strings.Fixed.Trim (Positive'Image (P.ID), Left) & ","
                   & Fmt (P.Position.X) & ","
                   & Fmt (P.Position.Y) & ","
                   & Fmt (P.Position.Z) & ","
                   & Fmt (P.Velocity.X) & ","
                   & Fmt (P.Velocity.Y) & ","
                   & Fmt (P.Velocity.Z));
      end loop;
   end Write_Trajectory;

   procedure Write_Energy
     (Step : Natural;
      Time : Long_Float;
      S    : Diagnostics.Snapshot)
   is
   begin
      Put_Line (Energy_File,
                Ada.Strings.Fixed.Trim (Natural'Image (Step), Left) & ","
                & Fmt (Time)                            & ","
                & Fmt (S.Kinetic_Energy)                & ","
                & Fmt (S.Potential_Energy)              & ","
                & Fmt (S.Total_Energy)                  & ","
                & Fmt (S.Linear_Momentum.X)             & ","
                & Fmt (S.Linear_Momentum.Y)             & ","
                & Fmt (S.Linear_Momentum.Z)             & ","
                & Fmt (S.Angular_Momentum.X)            & ","
                & Fmt (S.Angular_Momentum.Y)            & ","
                & Fmt (S.Angular_Momentum.Z)            & ","
                & Fmt (S.Relative_Energy_Drift));
   end Write_Energy;

end Output;
