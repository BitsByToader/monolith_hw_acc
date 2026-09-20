source $::env(SCRIPTS_DIR)/openroad/common/set_global_connections.tcl
set_global_connections

set secondary []
foreach vdd $::env(VDD_NETS) gnd $::env(GND_NETS) {
    if { $vdd != $::env(VDD_NET)} {
        lappend secondary $vdd

        set db_net [[ord::get_db_block] findNet $vdd]
        if {$db_net == "NULL"} {
            set net [odb::dbNet_create [ord::get_db_block] $vdd]
            $net setSpecial
            $net setSigType "POWER"
        }
    }

    if { $gnd != $::env(GND_NET)} {
        lappend secondary $gnd

        set db_net [[ord::get_db_block] findNet $gnd]
        if {$db_net == "NULL"} {
            set net [odb::dbNet_create [ord::get_db_block] $gnd]
            $net setSpecial
            $net setSigType "GROUND"
        }
    }
}

# core voltage domain
set_voltage_domain -name {CORE} -power {VDD} -ground {VSS}

# stdcell grid
define_pdn_grid -name stdcell_grid -voltage_domains {CORE}

add_pdn_ring \
	-grid stdcell_grid \
	-layers "$::env(FP_PDN_VERTICAL_LAYER) $::env(FP_PDN_HORIZONTAL_LAYER)" \
	-widths "$::env(FP_PDN_CORE_RING_VWIDTH) $::env(FP_PDN_CORE_RING_HWIDTH)" \
	-spacings "$::env(FP_PDN_CORE_RING_VSPACING) $::env(FP_PDN_CORE_RING_HSPACING)" \
	-core_offsets "$::env(FP_PDN_CORE_RING_VOFFSET) $::env(FP_PDN_CORE_RING_HOFFSET)" \
	-connect_to_pads

add_pdn_stripe \
	-grid stdcell_grid \
	-layer $::env(FP_PDN_RAIL_LAYER) \
	-width $::env(FP_PDN_RAIL_WIDTH) \
	-followpins \
    -starts_with POWER

add_pdn_stripe \
	-grid stdcell_grid \
	-layer $::env(FP_PDN_VERTICAL_LAYER) \
	-width $::env(FP_PDN_VWIDTH) \
	-pitch $::env(FP_PDN_VPITCH) \
	-offset $::env(FP_PDN_VOFFSET) \
    -spacing $::env(FP_PDN_VSPACING) \
	-starts_with POWER \
	-extend_to_core_ring

add_pdn_stripe \
	-grid stdcell_grid \
	-layer $::env(FP_PDN_HORIZONTAL_LAYER) \
	-width $::env(FP_PDN_HWIDTH) \
	-pitch $::env(FP_PDN_HPITCH) \
	-offset $::env(FP_PDN_HOFFSET) \
    -spacing $::env(FP_PDN_HSPACING) \
	-starts_with POWER \
	-extend_to_core_ring

add_pdn_connect -grid stdcell_grid -layers "$::env(FP_PDN_RAIL_LAYER) $::env(FP_PDN_VERTICAL_LAYER)"
add_pdn_connect -grid stdcell_grid -layers "$::env(FP_PDN_VERTICAL_LAYER) $::env(FP_PDN_HORIZONTAL_LAYER)"

# Concrete MatVec Mul Grid
define_pdn_grid \
    -macro \
    -instances "\
        core.hash.pre_round \
        core.hash.genblk1.*round.concrete" \
    -name concrete \
    -starts_with POWER

add_pdn_connect \
    -grid concrete \
    -layers "$::env(FP_PDN_VERTICAL_LAYER) $::env(FP_PDN_HORIZONTAL_LAYER)"
