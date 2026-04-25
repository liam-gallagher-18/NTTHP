# NTTHP
Supplement to my Master's thesis and IJHMT journal paper "A PARAMETRIC STUDY OF THE FEASIBILITY OF A SHAPE MEMORY ALLOY TORQUE TUBE HEAT PIPE FOR THERMAL TRANSPORT AND MECHANICAL ACTUATION."

Two codes were developed and made available in this repository. They are almost identical, but one assumes a cooling method of convection at the condenser end of the heat pipe, and the other assumes radiation as the cooling method.

As you step through either code, pay attention to each input value that should be changed, particularly before the loop, such as heat input (Q). There are several comments throughout each code which provide clarity on the most important parameters to be changed for your particular design.

Perhaps the most influential design decision you must make regarding input parameters is the heat pipe's working fluid selection. The codes require fluid properties in order to evaluate the NTTHP's limits. Working fluid properties vary with temperature. so you must upload a file with all relevant properties as they vary with temperature. 

The convection code assumes a working fluid of water and the radiation code assumes ammonia, because these are common choices for the environments modeled in each code. The convection case assumes a laboratory environment (ideal for water) and the radiation case assumes a space environment (ideal for ammonia). I developed the attached Excel files which respectively contain fluid properties of water and ammonia. These are references at the top of the code. If you intend to use my files, you must change the line:

waterProperties = readtable('xxx') or ammoniaProperties = readtable('xxx')

to make the 'xxx' match the location of the file on your machine.

If you'd like to test a different working fluid, you will need to capture its many relevant properties over a varying temperature range. I recommend downloading one of my provided Excel files, keeping the exact same format, but replacing all the values with the correct values for some other working fluid. Many properties for many working fluids can be found at the end of "Heat Pipes: Design, Theory, and Application" by Jouhara, et al and "Heat Pipe Science and Technology" by Faghri. You must pay attention to the ideal temperature range for your desired working fluid. If you assess an NTTHP at a temperature far outside of its working fluid's ideal temperature range, the code will extrapolate property values to that extreme temperature. These results CANNOT be trusted. For example, if you evaluate a water heat pipe at 4 K, it will extrapolate its vapor density to a negative value, which is non-physical. Thus, the results will either make no sense or will be entirely untrustworthy.
