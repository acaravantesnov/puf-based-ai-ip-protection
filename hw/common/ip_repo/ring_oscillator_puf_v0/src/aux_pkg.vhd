--=================================================================================================
-- Title       : Auxiliary Package
-- File        : aux_pkg.vhd
-- Author      : Alberto Caravantes Arranz
-- Date        : 06/04/2025
--=================================================================================================

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package aux_pkg is

    type natural_array is array(0 to 1) of natural;

    function ceil_log2(x: integer) return integer;

end package aux_pkg;

package body aux_pkg is

    -- Function Definition
    function ceil_log2(x: integer) return integer is
        variable result: integer := 0;
        variable value: integer := x;
    begin
        while value > 1 loop
            value := value / 2;
            result := result + 1;
        end loop;

        -- Round up if necessary
        if (2**result < x) then
            result := result + 1;
        end if;

        return result;
    end function ceil_log2;

end package body aux_pkg;
