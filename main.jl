###########################################################
# When one runs this file, they compute and prove the     #
# existence of a connecting orbit in (1). Along the way   #
# they rigorously compute stable and unstable manifolds   #
# about both fixed points and rigorously solve a BVP. As  #
# code runs, some important information about the proofs  #
# will be printing to the screen. This includes Taylor    #
# and Chebyshev coefficients, along with numerical values #
# Y₀, Z₀, Z₁, Z₂ in both proofs.                          #
###########################################################

include("./float_functions.jl")
include("./helpers.jl")
include("./interval_functions.jl")
include("./proof_functions.jl")

using RadiiPolynomial, GLMakie

import ApproxFun.Fun

# Do you want to prove the result?
__proof__ = true

# Do you want the plots saved and where
__save__ = false
__save_location__ = "../Logistic Figures/"


# Which plots do you want shown
__manif_plot__ = true
__rescaled_bvp_plot__ = true
__original_bvp_plot__ = true
__N_M_plot__ = true
__combined_plot__ = true


# Setting up the equation parameters
σ::Float64 = 10;
r::Float64 = 2.2;

# Setting up the numerics parameters
N_manif_compute = [18,11];  # Number of Taylor coefficients for the computation of the manifold parameterization
N_cheb_compute = 20; # Number of Chebyshev coefficients for the computation of the connecting orbit

N_manif_proof = [30,30];  # Number of Taylor coefficients for the proof of the manifold parameterization
N_cheb_proof = 500; # Number of Chebyshev coefficients for the proof of the connecting orbit

ν::Float64 = 1.05
weights::Vector{Float64} = [σ,1,1,σ,1,σ,1]
r_star::Float64 = 1e-5

manifold_range::Matrix{Float64} = [-1 1; -1 1];  # How long in time we grow the manifolds
manifold_num_points::Vector{Int64} = [1000,1000]; # How many points in time are we using

vector_length::Vector{Float64} = [1, 1];    # Length of eigenvectors for parameterization method

if r <= 2 || r >= sqrt(5)
    error("Chosen r does not satisfy the requirements")
end

# Two cycle of the logistic map where n₋ < n₊
n₋ = (r+2 - sqrt(r^2 -4))/(2*r);
n₊ = (r+2 + sqrt(r^2 -4))/(2*r);

println("n₋ = " * string(n₋)  * "\nn₊ = " * string(n₊));

# Evaluating the derivative of the logistic map at n₋ and n₊
n₋_prime = logistic_prime(n₋, r);
n₊_prime = logistic_prime(n₊, r);    

println("n₋_prime = " * string(n₋_prime) * "\nn₊_prime = " * string(n₊_prime));
println();

# Stable manifold
equilibrium₂ = [n₊; 0; n₋; 0];

A₁ = Df(equilibrium₂, σ, r);

λ₁ = -sqrt(σ^2*(1-sqrt(n₋_prime*n₊_prime)));
ξ₁ = [(-sqrt(Complex(n₋_prime))/(sqrt(complex(n₊_prime))*λ₁)).re; -sqrt(n₋_prime/n₊_prime); 1/λ₁; 1];
ξ₁ = (vector_length[1] / norm(ξ₁)) * ξ₁;

println("λ₁ = " * string(λ₁) * "\nξ₁ = " * string(ξ₁));
println("||A₁*ξ₁ - λ₁*ξ₁|| = " * string(norm(A₁*ξ₁ - λ₁*ξ₁)));
println();

λ₂ = -sqrt(σ^2*(1+sqrt(n₋_prime*n₊_prime)));
ξ₂ = [(sqrt(Complex(n₋_prime))/(sqrt(Complex(n₊_prime))*λ₂)).re; sqrt(n₋_prime/n₊_prime); 1/λ₂; 1];
ξ₂ = (vector_length[2] / norm(ξ₂)) * ξ₂;

println("λ₂ = " * string(λ₂) * "\nξ₂ = " * string(ξ₂));
println("||A₁*ξ₂ - λ₂*ξ₂|| = " * string(norm(A₁*ξ₂ - λ₂*ξ₂)));
println();


S_manif_compute = (Taylor(N_manif_compute[1]) ⊗ Taylor(N_manif_compute[2]))^4; # 2-index Taylor sequence space
S_manif_proof = (Taylor(N_manif_proof[1]) ⊗ Taylor(N_manif_proof[2]))^4; # 2-index Taylor sequence space

a = zeros(S_manif_compute);

a, = newton!((F, DF, a) -> (F_manif!(F, a, N_manif_compute, σ, r, equilibrium₂, λ₁, λ₂, ξ₁, ξ₂), DF_manif!(DF, a, N_manif_compute, σ, r, equilibrium₂, λ₁, λ₂, ξ₁, ξ₂)), a, tol = 1e-15)

a₁ = component(a,1)
a₂ = component(a,2)
a₃ = component(a,3)
a₄ = component(a,4)

println("a₁(N₁,0) = " * string(a₁[(N_manif_compute[1],0)]) * ", a₁(0,N₂) = " * string(a₁[(0,N_manif_compute[2])]))
println("a₂(N₁,0) = " * string(a₂[(N_manif_compute[1],0)]) * ", a₂(0,N₂) = " * string(a₂[(0,N_manif_compute[2])]))
println("a₃(N₁,0) = " * string(a₃[(N_manif_compute[1],0)]) * ", a₃(0,N₂) = " * string(a₃[(0,N_manif_compute[2])]))
println("a₄(N₁,0) = " * string(a₄[(N_manif_compute[1],0)]) * ", a₄(0,N₂) = " * string(a₄[(0,N_manif_compute[2])]))
println()


manifold_data = generate_manifold_data(a, manifold_range, manifold_num_points)
reflected_manifold_data = reflection_data(manifold_data)

distance, location = distance_from_fixed_points(manifold_data)

θ = get_theta(a, manifold_range, manifold_num_points, location)

θ,L = candidate_finder([θ[1],θ[2],0], a, σ, r)

println("L = " * string(L))
println("θ = " * string(θ))
println()

#Numerically integrating the candidate solution
numerical_orbit_data, numerical_orbit_time = integrate_point(a(θ[1],θ[2]), σ, r, (L,0.0))

S_orbit_compute = ParameterSpace() × ParameterSpace()^2 × Chebyshev(N_cheb_compute)^4
S_orbit_proof = ParameterSpace() × ParameterSpace()^2 × Chebyshev(N_cheb_proof)^4
X = zeros(S_orbit_compute)

chebyshev_multiplier = [1;1/2 * ones(N_cheb_compute,1)]

X.coefficients[:] = [L/2;θ;
    chebyshev_multiplier .* Fun(t -> interpolation(t, numerical_orbit_data[1,:], collect(LinRange(-1,1, length(numerical_orbit_data[1,:])))), N_cheb_compute+1).coefficients;
    chebyshev_multiplier .* Fun(t -> interpolation(t, numerical_orbit_data[2,:], collect(LinRange(-1,1, length(numerical_orbit_data[1,:])))), N_cheb_compute+1).coefficients;
    chebyshev_multiplier .* Fun(t -> interpolation(t, numerical_orbit_data[3,:], collect(LinRange(-1,1, length(numerical_orbit_data[1,:])))), N_cheb_compute+1).coefficients;
    chebyshev_multiplier .* Fun(t -> interpolation(t, numerical_orbit_data[4,:], collect(LinRange(-1,1, length(numerical_orbit_data[1,:])))), N_cheb_compute+1).coefficients;
    ]

X, = newton!((F, DF, X) -> (F_orbit!(F, X, a, N_cheb_compute, σ, r), DF_orbit!(DF, X, a, N_cheb_compute, σ, r)), X, tol = 1e-15)

L = component(X,1)[1]
θ = component(X,2)[1:2]

u₁ = component(component(X,3),1)
u₂ = component(component(X,3),2)
u₃ = component(component(X,3),3)
u₄ = component(component(X,3),4)

println("L = " * string(L))
println("θ = " * string(θ))
println("u₁(N_cheb) = " * string(u₁[N_cheb_compute]))
println("u₂(N_cheb) = " * string(u₂[N_cheb_compute]))
println("u₃(N_cheb) = " * string(u₃[N_cheb_compute]))
println("u₄(N_cheb) = " * string(u₄[N_cheb_compute]))
println()

if __proof__
    a = project(a, S_manif_proof)
    X = project(X, S_orbit_proof)

    println("Beginning Manifold Proof")
    r_min, r_max = manif_proof(a, N_manif_proof);

    println("Beginning Connecting Orbit Proof")
    orbit_proof(X, a, weights, N_cheb_proof, ν, r_min, r_star)
    #orbit_proof(X, a, weights, N_cheb_proof, ν, 1e-11, r_star)
end

# Plotting using GLMakie
bvp_data = connection_data(collect(LinRange(0, 2L, 1000)), λ₁, λ₂, a, X)
m_data = connection_data(collect(LinRange(2L, 2, 1000)), λ₁, λ₂, a, X)
c_data = connection_data(collect(LinRange(-2, 2, 1000)), λ₁, λ₂, a, X)

# Plot of manifolds
if __manif_plot__
    manif_plot = Figure(size = (1000, 600))

    manif_ax = Axis3(manif_plot[1,1],
        title = L"Stable and unstable manifolds attached to \tilde{x}^{(\pm)} of (5) with parameters $σ = 10$ and $r = 2.2$",
        titlesize = 20,
        xlabel = L"$x_1$",
        xlabelsize = 20,
        ylabel = L"$x_3$",
        ylabelsize = 20,
        zlabel = L"$x_2$",
        zlabelsize = 20   
    )

    # Stable manifold
    stable = GLMakie.surface!(manif_ax,
        reshape(manifold_data[1,:], manifold_num_points[2], manifold_num_points[1]),
        reshape(manifold_data[3,:], manifold_num_points[2], manifold_num_points[1]),
        reshape(manifold_data[2,:], manifold_num_points[2], manifold_num_points[1]),
        color = reshape(manifold_data[4,:], manifold_num_points[2], manifold_num_points[1]),
        colorrange = (-3,1.5),
        transparency = true
    )

    # Unstable manifold
    unstable = GLMakie.surface!(manif_ax,
        reshape(reflected_manifold_data[1,:], manifold_num_points[2], manifold_num_points[1]),
        reshape(reflected_manifold_data[3,:], manifold_num_points[2], manifold_num_points[1]),
        reshape(reflected_manifold_data[2,:], manifold_num_points[2], manifold_num_points[1]),
        color = reshape(reflected_manifold_data[4,:], manifold_num_points[2], manifold_num_points[1]),
        colorrange = (-3,1.5),
        transparency = true
    )

    x⁺ = GLMakie.scatter!(manif_ax,
        n₊,
        n₋,
        0,
        color = :red,
        markersize = 15,
        label = L"\tilde{x}^{(+)}"
    )

    x⁻ = GLMakie.scatter!(manif_ax,
        n₋,
        n₊,
        0,
        color = :blue,
        markersize = 15,
        label = L"\tilde{x}^{(-)}"
    )

    Colorbar(manif_plot[1,2], limits = (-3,1.5), label = L"x_4", labelsize = 20)
    axislegend("Legend", position = :rt)
    display(GLMakie.Screen(), manif_plot)

    if __save__
        save(string(__save_location__, "manif.png"), manif_plot, px_per_unit = 8)
    end
end

if __rescaled_bvp_plot__
    # Plot of rescaled BVP solution
    rescaled_bvp_plot = Figure(size = (1000, 600))

    rescaled_bvp_ax = Axis(rescaled_bvp_plot[1,1],
        title = L"\text{Solution to rescaled projected BVP (6) with parameters $σ = 10$ and $r = 2.2$}",
        titlesize = 20,
        xlabel = L"$t$",
        xlabelsize = 20,
    )

    GLMakie.lines!(rescaled_bvp_ax,
        collect(LinRange(-1, 1, 1000)),
        reverse(bvp_data[1,:]),
        color = :red,
        label = L"\bar{y}_1(t)"
    )

    GLMakie.lines!(rescaled_bvp_ax,
        collect(LinRange(-1, 1, 1000)),
        reverse(bvp_data[2,:]),
        color = :green,
        label = L"\bar{y}_2(t)"
    )

    GLMakie.lines!(rescaled_bvp_ax,
        collect(LinRange(-1, 1, 1000)),
        reverse(bvp_data[3,:]),
        color = :blue,
        label = L"\bar{y}_3(t)"
    )

    GLMakie.lines!(rescaled_bvp_ax,
        collect(LinRange(-1, 1, 1000)),
        reverse(bvp_data[4,:]),
        color = :orange,
        label = L"\bar{y}_4(t)"
    )

    rescaled_bvp_plot[1,2] = Legend(rescaled_bvp_plot, rescaled_bvp_ax, "Legend", position = :rt)
    display(GLMakie.Screen(), rescaled_bvp_plot)

    if __save__
        save(string(__save_location__, "rescaled_bvp.png"), rescaled_bvp_plot, px_per_unit = 8)
    end
end

if __original_bvp_plot__
    # Plot of original BVP solution
    original_bvp_plot = Figure(size = (1000, 600))

    original_bvp_ax = Axis(original_bvp_plot[1,1],
        title = L"\text{Solution to projected BVP (6) with parameters $σ = 10$ and $r = 2.2$}",
        titlesize = 20,
        xlabel = L"$t$",
        xlabelsize = 20,
    )

    GLMakie.lines!(original_bvp_ax,
        collect(LinRange(0, 2L, 1000)),
        bvp_data[1,:],
        color = :red,
        label = L"\bar{\Gamma}_1(t)"
    )

    GLMakie.lines!(original_bvp_ax,
        collect(LinRange(0, 2L, 1000)),
        bvp_data[2,:],
        color = :green,
        label = L"\bar{\Gamma}_2(t)"
    )

    GLMakie.lines!(original_bvp_ax,
        collect(LinRange(0, 2L, 1000)),
        bvp_data[3,:],
        color = :blue,
        label = L"\bar{\Gamma}_3(t)"
    )

    GLMakie.lines!(original_bvp_ax,
        collect(LinRange(0, 2L, 1000)),
        bvp_data[4,:],
        color = :orange,
        label = L"\bar{\Gamma}_4(t)"
    )

    original_bvp_plot[1,2] = Legend(original_bvp_plot, original_bvp_ax, "Legend", position = :rt)
    display(GLMakie.Screen(), original_bvp_plot)

    if __save__
        save(string(__save_location__, "original_bvp.png"), original_bvp_plot, px_per_unit = 8)
    end
end

if __N_M_plot__
    # Plot of N,M
    N_M_plot = Figure(size = (1000, 600))

    n_m_ax = Axis(N_M_plot[1,1],
        title = L"Construction of $\bar{N}(t)$ and $\bar{M}(t)$ for $t \ge 0$ with parameters $σ = 10$ and $r = 2.2$",
        titlesize = 20,
        xlabel = L"$t$",
        xlabelsize = 20,
    )

    GLMakie.lines!(n_m_ax,
        collect(LinRange(0, 2L, 1000)),
        bvp_data[1,:],
        color = :red,
        label = L"\bar{x}_1(t)"
    )

    GLMakie.lines!(n_m_ax,
        collect(LinRange(2L, 2, 1000)),
        m_data[1,:],
        color = :green,
        label = L"\bar{\Gamma}_1(t)"
    )

    GLMakie.lines!(n_m_ax,
        collect(LinRange(0, 2L, 1000)),
        bvp_data[3,:],
        color = :blue,
        label = L"\bar{x}_3(t)",
        linestyle = :dot
    )

    GLMakie.lines!(n_m_ax,
        collect(LinRange(2L, 2, 1000)),
        m_data[3,:],
        color = :orange,
        label = L"\bar{\Gamma}_3(t)",
        linestyle = :dot
    )

    N_M_plot[1,2] = Legend(N_M_plot, n_m_ax, "Legend", position = :rt)
    display(GLMakie.Screen(), N_M_plot)

    if __save__
        save(string(__save_location__, "N_M.png"), N_M_plot, px_per_unit = 8)
    end
end

if __combined_plot__
    # Plot of manifolds and connecting orbit
    combined_plot = Figure(size = (1600, 600))

    ODEax = Axis3(combined_plot[1,1],
        title = L"\text{Connecting orbit between \tilde{x}^{(\pm)} in ODE (5) with parameters $σ = 10$ and $r = 2.2$}",
        titlesize = 20,
        xlabel = L"$x_1$",
        xlabelsize = 20,
        ylabel = L"$x_3$",
        ylabelsize = 20,
        zlabel = L"$x_2$",
        zlabelsize = 20   
    )

    # # Stable manifold
    # stable = GLMakie.surface!(ODEax,
    #     reshape(manifold_data[1,:], manifold_num_points[2], manifold_num_points[1]),
    #     reshape(manifold_data[3,:], manifold_num_points[2], manifold_num_points[1]),
    #     reshape(manifold_data[2,:], manifold_num_points[2], manifold_num_points[1]),
    #     color = reshape(manifold_data[4,:], manifold_num_points[2], manifold_num_points[1]),
    #     colorrange = (-3,1.5),
    #     transparency = true,
    # )

    # # Unstable manifold
    # unstable = GLMakie.surface!(ODEax,
    #     reshape(reflected_manifold_data[1,:], manifold_num_points[2], manifold_num_points[1]),
    #     reshape(reflected_manifold_data[3,:], manifold_num_points[2], manifold_num_points[1]),
    #     reshape(reflected_manifold_data[2,:], manifold_num_points[2], manifold_num_points[1]),
    #     color = reshape(reflected_manifold_data[4,:], manifold_num_points[2], manifold_num_points[1]),
    #     colorrange = (-3,1.5),
    #     transparency = true,
    # )


    # Connecting orbit

    orbit = GLMakie.lines!(ODEax,
        c_data[1,:],
        c_data[3,:],
        c_data[2,:],
        color = c_data[4,:],
        colorrange = (-3,1.5),
        label = "Connecting Orbit"
    )


    fp1 = GLMakie.scatter!(ODEax,
        n₊,
        n₋,
        0,
        color = :red,
        markersize = 15,
        label = L"\tilde{x}^{(+)}"
    )

    fp2 = GLMakie.scatter!(ODEax,
        n₋,
        n₊,
        0,
        color = :blue,
        markersize = 15,
        label = L"\tilde{x}^{(-)}"
    )

    Colorbar(combined_plot[1,2], limits = (-3,1.5), label = L"x_4", labelsize = 20)
    axislegend("Legend", position = :rt)


    IDEax = Axis(combined_plot[1,3],
        title = L"Two-cycle of IDE (1) with parameters $σ = 10$ and $r = 2.2$",
        titlesize = 20,
        xlabel = L"$t$",
        xlabelsize = 20,
        limits = (nothing, (0.6, 1.3))  
    )

    GLMakie.lines!(IDEax,
        collect(LinRange(-2, 2, 1000)),
        c_data[1,:],
        color = :red,
        label = L"\bar{N}(t)"
    )

    GLMakie.lines!(IDEax,
        collect(LinRange(-2, 2, 1000)),
        c_data[3,:],
        color = :blue,
        label = L"\bar{M}(t)"
    )


    GLMakie.lines!(IDEax,
    collect(LinRange(-2, 2, 1000)),
        n₋*ones(1000,1)[:],
        color = :black,
        label = L"n_-"
    )

    GLMakie.lines!(IDEax,
        collect(LinRange(-2, 2, 1000)),
        n₊*ones(1000,1)[:],
        color = :black,
        label = L"n_+"
    )
    axislegend("Legend", position = :rt)


    display(GLMakie.Screen(), combined_plot)

    if __save__
        save(string(__save_location__, "two-cycle.png"), combined_plot, px_per_unit = 8)
    end
end





