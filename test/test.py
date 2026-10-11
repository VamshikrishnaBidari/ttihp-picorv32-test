
# SPDX-FileCopyrightText: © 2024 Tiny Tapeout
# SPDX-License-Identifier: Apache-2.0

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles


@cocotb.test()
async def test_project(dut):
    dut._log.info("Starting PicoRV32 test")

    clock = Clock(dut.clk, 10, unit="us")
    cocotb.start_soon(clock.start())

    # Initialize inputs and reset the CPU.
    dut.ena.value = 1
    dut.ui_in.value = 0
    dut.uio_in.value = 0
    dut.rst_n.value = 0

    await ClockCycles(dut.clk, 10)
    dut.rst_n.value = 1

    # The program should write 1, 2, 3, ... to the output register.
    # Wait until the CPU performs its first observable write.
    dut._log.info("Waiting for the CPU to update the output")

    for _ in range(500):
        await ClockCycles(dut.clk, 1)
        value = int(dut.uo_out.value)
        if value != 0:
            break
    else:
        assert False, "CPU did not update the output register"

    first_value = value
    dut._log.info(f"First observed output: {first_value}")

    # The program loops and increments the output.
    # Verify that a later write changes the output.
    for _ in range(500):
        await ClockCycles(dut.clk, 1)
        value = int(dut.uo_out.value)
        if value != first_value:
            break
    else:
        assert False, "CPU output did not change; program may not be looping"

    dut._log.info(f"Updated output: {value}")
    assert value == ((first_value + 1) & 0xFF), (
        f"Expected output to increment from {first_value}, got {value}"
    )


# # SPDX-FileCopyrightText: © 2024 Tiny Tapeout
# # SPDX-License-Identifier: Apache-2.0

# import cocotb
# from cocotb.clock import Clock
# from cocotb.triggers import ClockCycles


# @cocotb.test()
# async def test_project(dut):
#     dut._log.info("Start")

#     # Set the clock period to 10 us (100 KHz)
#     clock = Clock(dut.clk, 10, unit="us")
#     cocotb.start_soon(clock.start())

#     # Reset
#     dut._log.info("Reset")
#     dut.ena.value = 1
#     dut.ui_in.value = 0
#     dut.uio_in.value = 0
#     dut.rst_n.value = 0
#     await ClockCycles(dut.clk, 10)
#     dut.rst_n.value = 1

#     dut._log.info("Test project behavior")

#     # Set the input values you want to test
#     dut.ui_in.value = 20
#     dut.uio_in.value = 30

#     # Wait for one clock cycle to see the output values
#     await ClockCycles(dut.clk, 1)

#     # The following assersion is just an example of how to check the output values.
#     # Change it to match the actual expected output of your module:
#     assert dut.uo_out.value == 50

#     # Keep testing the module by changing the input values, waiting for
#     # one or more clock cycles, and asserting the expected output values.
