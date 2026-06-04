# SPDX-FileCopyrightText: 2024 Jerson Quintero
# SPDX-License-Identifier: Apache-2.0
import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles

@cocotb.test()
async def test_reset(dut):
    """Test reset behavior"""
    dut._log.info("Start")
    clock = Clock(dut.clk, 10, unit="us")
    cocotb.start_soon(clock.start())

    # Reset
    dut._log.info("Reset")
    dut.ena.value = 1
    dut.ui_in.value = 0
    dut.uio_in.value = 0
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 10)
    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 10)

    # After reset CS# should be high (inactive)
    dut._log.info("Check CS# is high after reset")
    assert dut.uo_out.value[6] == 1, "CS# should be high after reset"
    dut._log.info("Reset test passed")

@cocotb.test()
async def test_play_button(dut):
    """Test play button activates SPI"""
    dut._log.info("Start play button test")
    clock = Clock(dut.clk, 10, unit="us")
    cocotb.start_soon(clock.start())

    # Reset
    dut.ena.value = 1
    dut.ui_in.value = 0
    dut.uio_in.value = 0
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 10)
    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 10)

    # Press play button
    dut._log.info("Press PLAY button")
    dut.ui_in.value = 1  # btn_play high
    await ClockCycles(dut.clk, 50)
    dut.ui_in.value = 0
    await ClockCycles(dut.clk, 100)

    dut._log.info("Play button test passed")