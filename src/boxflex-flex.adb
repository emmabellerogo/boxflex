package body Boxflex.Flex with SPARK_Mode is

   --  Sums over many items can exceed Coord. Accumulate in units of
   --  Coord'Small in a wide integer instead.
   type Units is range -2 ** 62 .. 2 ** 62 - 1;

   Length_Unit : constant Length := Length'Small;
   Coord_Unit : constant Coord := Coord'Small;
   Ratio_Unit : constant Ratio := Ratio'Small;
   --  One step of each fixed-point type, used to convert to and from Units.

   function To_Units (L : Length) return Units is
     (Units (L / Length_Unit));

   function Grow_Units (R : Ratio) return Units is
      (Units (R / Ratio_Unit));
   --  A Ratio as a whole number of its 1/1024 steps (1.0 is 1024).

   function To_Length (U : Units) return Length is
     (Length_Unit * Integer (U))
       with Pre => U >= 0 and then U <= To_Units (Length'Last);
   --  Units back to a Length. The caller guarantees it fits.

   function Clamp (V, Lo, Hi : Length) return Length is
     (if V < Lo then Lo elsif Hi >= Lo and then V > Hi then Hi else V);

   -----------------------
   -- Hypothetical_Main --
   -----------------------

   function Hypothetical_Main (I : Item) return Length is
     (Clamp ((if I.Basis_Definite then I.Basis else I.Content_Main),
             I.Min_Main, I.Max_Main));

   ----------------
   -- Form_Lines --
   ----------------

   procedure Form_Lines
     (C     : Container;
      Items : Item_Array;
      Lines : out Line_Array;
      Count : out Natural)
   is
      Limit : constant Units := To_Units (C.Main);
      Gap   : constant Units := To_Units (C.Main_Gap);
      Used  : Units := 0;
      Outer : Units;
   begin
      Lines := [others => (First => 0, Last => 0)];
      Count := 0;

      for K in Items'Range loop
         pragma Loop_Invariant (Count <= K - Items'First);
         pragma Loop_Invariant (Count = 0 or else Lines (Count).Last = K - 1);
         pragma Loop_Invariant (Used >= 0);

         Outer := To_Units (Items (K).Margin_Main_Start)
                  + To_Units (Hypothetical_Main (Items (K)))
                  + To_Units (Items (K).Margin_Main_End);

         if Count = 0
           or else (C.Wrap /= No_Wrap and then Used + Gap + Outer > Limit)
         then
            --  Open a new line. A line always takes at least one item.
            Count := Count + 1;
            Lines (Count) := (First => K, Last => K);
            Used := Outer;
         else
            Lines (Count).Last := K;
            Used := Used + Gap + Outer;
         end if;
      end loop;
   end Form_Lines;

   ---------------------
   -- Distribute_Grow --
   ---------------------

   procedure Distribute_Grow (C : Container; Items : in out Item_Array) is
      Used : Units := 0;
      Total_Grow : Units := 0;
      Free : Units;
      Given : Units := 0;
      Share : Units;
   begin
      --  1. How much of the line is already taken, and how much grow is there?
      for K in Items'Range loop
         Used := Used + To_Units (Items (K).Margin_Main_Start)
                        + To_Units (Items (K).Main)
                        + To_Units (Items (K).Margin_Main_End);
         if K > Items'First then
            Used := Used + To_Units (C.Main_Gap);
         end if;
         Total_Grow := Total_Grow + Grow_Units (Items (K).Grow);
      end loop;
      Free := To_Units (C.Main) - Used;
      --  Nothing to share, or nobody wants it.
      if Free <= 0 or else Total_Grow = 0 then
         return;
      end if;
      --  2. Each item gets Free * Grow / Total_Grow (integer division
      --     rounds down, so a few units may be left over).
      for K in Items'Range loop
         Share := Free * Grow_Units (Items (K).Grow) / Total_Grow;
         Items (K).Main := To_Length (To_Units (Items (K).Main) + Share);
         Given := Given + Share;
      end loop;
      --  3. Hand out the leftover units one at a time, first growing item
      --    first, until the line is filled exactly.
      for K in Items'Range loop
         exit when Given = Free;
         if Items (K).Grow > 0.0 then
            Items (K).Main := To_Length (To_Units (Items (K).Main) + 1);
            Given := Given + 1;
         end if;
      end loop;
   end Distribute_Grow;

   -------------------
   -- Cross helpers --
   -------------------

   function Effective_Align (C : Container; I : Item) return Align_Self is
      (if I.Self /= Auto then I.Self
       else (case C.Align is
               when Stretch => Stretch,
               when Flex_Start   => Flex_Start,
               when Flex_End     => Flex_End,
               when Center  => Center,
               when Baseline => Baseline));
   --  The item's own Self wins over the container's Align, except that Auto is ignored.

   function Room (C : Container; I : Item) return Units is
      (To_Units (C.Cross) - To_Units (I.Margin_Cross_Start)
                          - To_Units (I.Margin_Cross_End));
   --  Cross space left for the item once its cross margins are taken
   --  Can be negative if the margins are bigger than the container.

   -------------
   -- Resolve --
   -------------

   --  Steps 1, 3 (grow only) and 7. Still missing: shrink, wrap,
   --  justify, align, reversed directions.

   procedure Resolve (C : Container; Items : in out Item_Array) is
      Cursor : Units := 0;
      Gap    : constant Units := To_Units (C.Main_Gap);
      Max_U : constant Units := To_Units (Length'Last);
      --   Max_Pos = Coord'Last - Length'Last, and Length'Last = 2**22
      --   so a position of at most Length'Last (as a Coord) is safe

      function Pos (U : Units) return Coord is
         (if U > Max_U then Max_Pos else Coord_Unit * Integer (U))
         with Pre => U >= 0;
      --   Units to Coord, saturating at Max_Pos.

   begin
   --  Step 1: every items starts at its hypothetical main size.
      for K in Items'Range loop
         Items (K).Main := Hypothetical_Main (Items (K));
         Items (K).Cross :=
            Clamp (Items (K).Content_Cross, Items (K).Min_Cross, Items (K).Max_Cross);
      end loop;

      --   Step 3: Share free space by Grow (single line only for now)
      if C.Wrap = No_Wrap then
         Distribute_Grow (C, Items);
      end if;

      --  Step 4: Stretch. No declared cross size + Stretch = fill the line.
      for K in Items'Range loop
         if Effective_Align (C, Items (K)) = Stretch
         and then not Items (K).Cross_Definite
         then
            declare
               R : constant Units := Room (C, Items (K));
            begin
               Items (K).Cross :=
                  Clamp ((if R <= 0 then 0.0 else To_Length (R)),
                         Items (K).Min_Cross, Items (K).Max_Cross);
            end;
         end if;
      end loop;

      --  Step 7: place items one after the other along the main axis.
      for K in Items'Range loop
         pragma Loop_Invariant (Cursor >= 0);
         pragma Loop_Invariant
            (for all J in Items'First .. K - 1 => Placed_In_Range (Items (J)));

         Cursor := Cursor + To_Units (Items (K).Margin_Main_Start);
         Items (K).Pos_Main := Pos (Cursor);
         Items (K).Pos_Cross := Pos (To_Units (Items (K).Margin_Cross_Start));

         Cursor := Cursor + To_Units (Items (K).Main)
                           + To_Units (Items (K).Margin_Main_End) + Gap;
      end loop;
   end Resolve;

end Boxflex.Flex;