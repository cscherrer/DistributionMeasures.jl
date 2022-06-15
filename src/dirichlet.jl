# This file is a part of DistributionMeasures.jl, licensed under the MIT License (MIT).


MeasureBase.effndof(d::Dirichlet) = length(d) - 1

MeasureBase.vartransform_origin(trg::Dirichlet) = StandardDist{Uniform,1}(effndof(trg))

function MeasureBase.from_origin(trg::Dirichlet, x::AbstractVector{<:Real})
    to_dirichlet(trg.alpha, src, x)
end

function _dirichlet_beta_trafo(α::Real, β::Real, x::Real)
    R = float(promote_type(typeof(α), typeof(β), typeof(x)))
    convert(R, vartransform(Beta(α, β), StandardUvUniform(), x))::R
end

_a_times_one_minus_b(a::Real, b::Real) = a * (1 - b)

function to_dirichlet(alpha::AbstractVector{<:Real}, src::StandardDist{Uniform,1}, x::AbstractVector{<:Real})
    # See M. J. Betancourt, "Cruising The Simplex: Hamiltonian Monte Carlo and the Dirichlet Distribution",
    # https://arxiv.org/abs/1010.3436

    @_adignore @argcheck length(trg) == length(src) + 1
    αs = _dropfront(_rev_cumsum(trg.alpha))
    βs = _dropback(trg.alpha)
    beta_v = fwddiff(_dirichlet_beta_trafo).(αs, βs, x)
    beta_v_cp = _exp_cumsum_log(_pushfront(beta_v, 1))
    beta_v_ext = _pushback(beta_v, 0)
    fwddiff(_a_times_one_minus_b).(beta_v_cp, beta_v_ext)
end
