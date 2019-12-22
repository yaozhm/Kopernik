# fvp test

import os
import sys
import subprocess

FVP_BINARY = os.path.join(
        "/home/puck/work/github/fvp/Base_RevC_AEMv8A_pkg/models",
        "Linux64_GCC-6.4",
        "FVP_Base_RevC-2xAEMv8A"
)

start_data = os.path.join(
        "/home/puck/work/github/arm-trusted-firmware/build/fvp/release",
        "bl31.bin"
)

uart0_log_path = os.path.join(
        "/home/puck/work/github/Kopernik/out",
        "uart0.log"
)

uart1_log_path = os.path.join(
        "/home/puck/work/github/Kopernik/out",
        "uart1.log"
)

run_log = os.path.join(
        "/home/puck/work/github/Kopernik/out",
        "run.log"
)

def read_file(path):
    with open(path, "r") as f:
        return f.read()

def write_file(path, to_write, append=False):
    with open(path, "a" if append else "w") as f:
        f.write(to_write)

def append_file(path, to_write):
    write_file(path, to_write, append=True)

def exec_logged(exec_args):
        """Run a subprocess on behalf of a Driver subclass and append its
        stdout and stderr to the main log."""
        with open(run_log, "a") as f:
                f.write("$ {}\r\n".format(" ".join(exec_args)))
                f.flush()
                ret_code = subprocess.call(exec_args, stdout=f, stderr=f)

def gen_fvp_args(start_data, uart0_path, uart1_path):
        time_limit = "3s"
        fvp_args = [
            "timeout", "--foreground", time_limit,
            FVP_BINARY,
            "-C", "pctl.startup=0.0.0.0",
            "-C", "bp.secure_memory=0",
            "-C", "cluster0.NUM_CORES=4",
            "-C", "cluster1.NUM_CORES=4",
            "-C", "cache_state_modelled=0",
            "-C", "bp.vis.disable_visualisation=true",
            "-C", "bp.vis.rate_limit-enable=false",
            "-C", "bp.terminal_0.start_telnet=false",
            "-C", "bp.terminal_1.start_telnet=false",
            "-C", "bp.terminal_2.start_telnet=false",
            "-C", "bp.terminal_3.start_telnet=false",
            "-C", "bp.pl011_uart0.untimed_fifos=1",
            "-C", "bp.pl011_uart0.unbuffered_output=1",
            "-C", "bp.pl011_uart0.out_file=" + uart0_path,
            "-C", "bp.pl011_uart1.out_file=" + uart1_path,
            "-C", "cluster0.cpu0.RVBAR=0x04020000",
            "-C", "cluster0.cpu1.RVBAR=0x04020000",
            "-C", "cluster0.cpu2.RVBAR=0x04020000",
            "-C", "cluster0.cpu3.RVBAR=0x04020000",
            "-C", "cluster1.cpu0.RVBAR=0x04020000",
            "-C", "cluster1.cpu1.RVBAR=0x04020000",
            "-C", "cluster1.cpu2.RVBAR=0x04020000",
            "-C", "cluster1.cpu3.RVBAR=0x04020000",
            "-C", "cluster0.has_pointer_authentication=2",
            "-C", "cluster1.has_pointer_authentication=2",
            "-C", "cluster0.has_secure_el2=2",
            "-C", "cluster1.has_secure_el2=2",
            "-C", "cluster0.has_branch_target_exception=2",
            "-C", "cluster1.has_branch_target_exception=2",
            "-C", "cluster0.memory_tagging_support_level=2",
            "-C", "cluster1.memory_tagging_support_level=2",
            "-C", "cluster0.has_arm_v8-1=1",
            "-C", "cluster1.has_arm_v8-1=1",
            "-C", "cluster0.has_arm_v8-2=1",
            "-C", "cluster1.has_arm_v8-2=1",
            "-C", "cluster0.has_arm_v8-3=1",
            "-C", "cluster1.has_arm_v8-3=1",
            "-C", "cluster0.has_arm_v8-4=1",
            "-C", "cluster1.has_arm_v8-4=1",
            "-C", "cluster0.has_arm_v8-5=1",
            "-C", "cluster1.has_arm_v8-5=1",
            "-C", "cluster0.has_arm_v8-6=1",
            "-C", "cluster1.has_arm_v8-6=1",
            "--data", "cluster0.cpu0=" + start_data + "@0x04020000",
            "-C", "bp.ve_sysregs.mmbSiteDefault=0",
            "-C", "bp.ve_sysregs.exit_on_shutdown=1",
        ]
        return fvp_args

def run():
        fvp_args = gen_fvp_args(start_data, uart0_log_path, uart1_log_path)
        exec_logged(fvp_args)

if __name__ == "__main__":
        for arg in sys.argv:
                print arg
        run()