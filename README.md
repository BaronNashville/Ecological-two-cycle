# Spatially inhomogenous two-cycles in ecological integrodifference equations
This code was submitted as a part of the the masters thesis titled Spatially inhomogenous two-cycles in ecological integrodifference equations.

This READ_ME describes how to reproduce the proofs presented in the thesis above.

To begin, you will need the following julia packages and their dependencies added to your julia environment.

	RadiiPolynomial.jl
	IntervalArthmetic.jl
	DifferentialEquations.jl
	GLMakie.jl
	ApproxFun.jl
	
Once these are added to your julia environment, you will need to open the main.jl file. The first few lines give you the option to produce either a proof or simply a numerical computation of the two-cycle of IDE (1). Then you have the option to choose which plots will be created and if you want to save them or not. The current plot options are

	__manif_plot__: Plot the approximate manifolds of the four-dimensional ODE (5)
	__rescaled_bvp_plot: Plot the approximate solution of the rescaled BVP (6)
	__original_bvp_plot: Plot the approximate solution of the BVP (6)
	__N_M_plot__: Plot the construction of \bar{N}, \bar{M}
	__combined_plot__: Plot the connecting orbit in the four-dimensional ODE (5) along with its corresponding two-cycle of IDE (1)

Afterwards, you have the option to play with the parameter values of \sigma and r along with the number of coefficients you use for the computation and proof of the two-cycle along with the value of \nu for the space of Chebyshev coefficients. All the parameters have already been set to the ones featured in the thesis.

Once all the parameters have been selected, simply run the file and it will compute everything it needs to and output the desired plots in different windows.

	




 
