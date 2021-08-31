[![Build Status](https://travis-ci.com/pulp-platform/riscv.svg?branch=master)](https://travis-ci.com/pulp-platform/riscv)

# OpenHW Group CORE-V CV32E41P RISC-V IP

CV32E41P is a small and efficient, 32-bit, in-order RISC-V core with a 4-stage pipeline that implements
the RV32IM\[F,Zfinx\]C\[Zce\] instruction set architecture, and the Xpulp custom extensions for achieving
higher code density, performance, and energy efficiency \[[1](https://doi.org/10.1109/TVLSI.2017.2654506)\], \[[2](https://doi.org/10.1109/PATMOS.2017.8106976)\].
It started its life as a fork of the CV32E40P core to implement the official RISC-V [Zfinx](https://github.com/riscv/riscv-zfinx/blob/main/zfinx-spec-20210511-0.41.pdf) and [Zce](https://github.com/riscv/riscv-code-size-reduction/blob/master/ISA%20proposals/Huawei/Zce_spec.adoc) ISA extensions.

A first implementation of the Zce ISA extensions has been explored in \[[3](https://www.research-collection.ethz.ch/bitstream/handle/20.500.11850/461404/1/CARRV2020_paper_12_Perotti.pdf)\] to investigate code reduction benefits.

## Documentation

The CV32E41P user manual can be found in the _docs_ folder and it is
captured in reStructuredText, rendered to html using [Sphinx](https://docs.readthedocs.io/en/stable/intro/getting-started-with-sphinx.html).
These documents are viewable using readthedocs and can be viewed [here](https://docs.openhwgroup.org/projects/openhw-group-cv32e41p/).

## Verification
The verification environment for the CV32E41P is _not_ in this Repository.  There is a small, simple testbench here which is
useful for experimentation only and should not be used to validate any changes to the RTL prior to pushing to the master
branch of this repo.

The verification environment for this core as well as other cores in the OpenHW Group CORE-V family is at the
[core-v-verif](https://github.com/openhwgroup/core-v-verif) repository on GitHub.

The Makefiles supported in the **core-v-verif** project automatically clone the appropriate version of the **cv32e41p**  RTL sources.

## Constraints
Example synthesis constraints for the CV32E41P are provided.

## Contributing

We highly appreciate community contributions. We are currently using the lowRISC contribution guide.
To ease our work of reviewing your contributions,
please:

* Create your own fork to commit your changes and then open a Pull Request.
* Split large contributions into smaller commits addressing individual changes or bug fixes. Do not
  mix unrelated changes into the same commit!
* Write meaningful commit messages. For more information, please check out the [the Ibex contribution
  guide](https://github.com/lowrisc/ibex/blob/master/CONTRIBUTING.md).
* If asked to modify your changes, do fixup your commits and rebase your branch to maintain a
  clean history.

When contributing SystemVerilog source code, please try to be consistent and adhere to [the lowRISC Verilog
coding style guide](https://github.com/lowRISC/style-guides/blob/master/VerilogCodingStyle.md).

To get started, please check out the ["Good First Issue"
 list](https://github.com/openhwgroup/cv32e40p/issues?q=is%3Aissue+is%3Aopen+-label%3Astatus%3Aresolved+label%3A%22good+first+issue%22).

The RTL code has been formatted with ["Verible"](https://github.com/google/verible) v0.0-1149-g7eae750.

## Issues and Troubleshooting

If you find any problems or issues with CV32E41P or the documentation, please check out the [issue
 tracker](https://github.com/openhwgroup/cv32e40p/issues) and create a new issue if your problem is
not yet tracked.

## References

1. [Gautschi, Michael, et al. "Near-Threshold RISC-V Core With DSP Extensions for Scalable IoT Endpoint Devices."
 in IEEE Transactions on Very Large Scale Integration (VLSI) Systems, vol. 25, no. 10, pp. 2700-2713, Oct. 2017](https://doi.org/10.1109/TVLSI.2017.2654506)

2. [Schiavone, Pasquale Davide, et al. "Slow and steady wins the race? A comparison of
 ultra-low-power RISC-V cores for Internet-of-Things applications."
 _27th International Symposium on Power and Timing Modeling, Optimization and Simulation
 (PATMOS 2017)_](https://doi.org/10.1109/PATMOS.2017.8106976)
 
3. [Perotti, Matteo, et al. "HW/SW approaches for RISC-V code size reduction."
 Workshop on Computer Architecture Research with RISC-V (CARRV 2020). 2020.](https://www.research-collection.ethz.ch/bitstream/handle/20.500.11850/461404/1/CARRV2020_paper_12_Perotti.pdf)
 
  
