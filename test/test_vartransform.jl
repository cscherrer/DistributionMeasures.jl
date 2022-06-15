# This file is a part of BAT.jl, licensed under the MIT License (MIT).

using DistributionMeasures
using Test

using LinearAlgebra
using InverseFunctions, ChangesOfVariables
using Distributions, ArraysOfArrays
import ForwardDiff, Zygote

@testset "test_distribution_transform" begin
    function test_back_and_forth(trg, src)
        @testset "transform $(typeof(trg).name) <-> $(typeof(src).name)" begin
            x = rand(src)
            y = vartransform_def(trg, src, x)
            src_v_reco = vartransform_def(src, trg, y)

            @test x ≈ src_v_reco

            let vs_trg = varshape(trg), vs_src = varshape(src)
                f = unshaped_x -> inverse(vs_trg)(vartransform_def(trg, src, vs_src(unshaped_x)))
                ref_ladj = logpdf(src, x) - logpdf(trg, y)
                @test ref_ladj ≈ logabsdet(ForwardDiff.jacobian(f, inverse(vs_src)(x)))[1]
            end
        end
    end

    function get_trgxs(trg, src, X)
        return (x -> vartransform_def(trg, src, x)).(nestedview(X))
    end

    function get_trgxs(trg, src::Distribution{Univariate}, X)
        return (x -> vartransform_def(trg, src, x)).(X)
    end

    function test_dist_trafo_moments(trg, src)
        @testset "check moments of trafo $(typeof(trg).name) <- $(typeof(src).name)" begin
            X = flatview(rand(src, 10^5))
            trgxs = get_trgxs(trg, src, X)
            unshaped_trgxs = broadcast(unshaped, trgxs, Ref(varshape(trg)))
            @test isapprox(mean(unshaped_trgxs), mean(unshaped(trg)), atol = 0.1)
            @test isapprox(cov(unshaped_trgxs), cov(unshaped(trg)), rtol = 0.1)
        end
    end

    stduvuni = BAT.StandardUvUniform()
    stduvnorm = BAT.StandardUvNormal()

    uniform1 = Uniform(-5.0, -0.01)
    uniform2 = Uniform(0.01, 5.0)

    normal1 = Normal(-10, 1)
    normal2 = Normal(10, 5)

    stdmvnorm1 = BAT.StandardMvNormal(1)
    stdmvnorm2 = BAT.StandardMvNormal(2)

    stdmvuni2 = BAT.StandardMvUniform(2)

    standnorm2_reshaped = ReshapedDist(stdmvnorm2, varshape(stdmvnorm2))

    mvnorm = MvNormal([0.3, -2.9], [1.7 0.5; 0.5 2.3])
    beta = Beta(3,1)
    gamma = Gamma(0.1,0.7)
    dirich = Dirichlet([0.1,4])

    ntdist = NamedTupleDist(
        a = uniform1,
        b = mvnorm,
        c = [4.2, 3.7],
        x = beta,
        y = gamma
    )

    test_back_and_forth(stduvuni, stduvuni)
    test_back_and_forth(stduvnorm, stduvnorm)
    test_back_and_forth(stduvuni, stduvnorm)
    test_back_and_forth(stduvnorm, stduvuni)

    test_back_and_forth(stdmvuni2, stdmvuni2)
    test_back_and_forth(stdmvnorm2, stdmvnorm2)
    test_back_and_forth(stdmvuni2, stdmvnorm2)
    test_back_and_forth(stdmvnorm2, stdmvuni2)

    test_back_and_forth(beta, stduvnorm)
    test_back_and_forth(gamma, stduvnorm)

    test_dist_trafo_moments(normal2, normal1)
    test_dist_trafo_moments(uniform2, uniform1)

    test_dist_trafo_moments(beta, gamma)

    test_dist_trafo_moments(beta, stduvnorm)
    test_dist_trafo_moments(gamma, stduvnorm)

    test_dist_trafo_moments(mvnorm, stdmvnorm2)
    test_dist_trafo_moments(dirich, stdmvnorm1)

    test_dist_trafo_moments(mvnorm, stdmvuni2)
    test_dist_trafo_moments(stdmvuni2, mvnorm)

    test_dist_trafo_moments(stdmvnorm2, stdmvuni2)

    test_dist_trafo_moments(mvnorm, standnorm2_reshaped)
    test_dist_trafo_moments(standnorm2_reshaped, mvnorm)
    test_dist_trafo_moments(stdmvnorm2, standnorm2_reshaped)
    test_dist_trafo_moments(standnorm2_reshaped, standnorm2_reshaped)
    
    test_back_and_forth(ntdist, BAT.StandardMvNormal(5))
    test_back_and_forth(ntdist, BAT.StandardMvUniform(5))

    let
        mvuni = product_distribution([Uniform(), Uniform()])

        x = rand()
        @test_throws ArgumentError vartransform_def(stduvnorm, mvnorm, x)
        @test_throws ArgumentError vartransform_def(stduvnorm, stdmvnorm1, x)
        @test_throws ArgumentError vartransform_def(stduvnorm, stdmvnorm2, x)

        x = rand(2)
        @test_throws ArgumentError vartransform_def(mvuni, mvnorm, x)
        @test_throws ArgumentError vartransform_def(mvnorm, mvuni, x)
        @test_throws ArgumentError vartransform_def(stduvnorm, mvnorm, x)
        @test_throws ArgumentError vartransform_def(stduvnorm, stdmvnorm1, x)
        @test_throws ArgumentError vartransform_def(stduvnorm, stdmvnorm2, x)
    end

    let
        primary_dist = NamedTupleDist(x = Normal(2), c = 5)
        f = x -> NamedTupleDist(y = Normal(x.x, 3), z = MvNormal([1.3 0.5; 0.5 2.2]))
        trg = @inferred(HierarchicalDistribution(f, primary_dist))
        src = BAT.StandardMvNormal(totalndof(varshape(trg)))
        test_back_and_forth(trg, src)
        test_dist_trafo_moments(trg, src)
    end


    #=
    using Cuba
    function integrate_over_unit(density::AbstractDensity)
        vs = varshape(density)
        f_cuba(source_x, y) = y[1] = exp(logdensityof(density)(vs(source_x)))
        Cuba.vegas(f_cuba, 1, 1).integral[1]
    end
    =#

    @testset "Custom cdf and quantile for dual numbers" begin
        Dual = ForwardDiff.Dual

        @test BAT._trafo_cdf(Normal(Dual(0, 1, 0, 0), Dual(1, 0, 1, 0)), Dual(0.5, 0, 0, 1)) == cdf(Normal(Dual(0, 1, 0, 0), Dual(1, 0, 1, 0)), Dual(0.5, 0, 0, 1))
        @test BAT._trafo_cdf(Normal(0, 1), Dual(0.5, 1)) == cdf(Normal(0, 1), Dual(0.5, 1))

        @test BAT._trafo_quantile(Normal(0, 1), Dual(0.5, 1)) == quantile(Normal(0, 1), Dual(0.5, 1))
        @test BAT._trafo_quantile(Normal(Dual(0, 1, 0, 0), Dual(1, 0, 1, 0)), Dual(0.5, 0, 0, 1)) == quantile(Normal(Dual(0, 1, 0, 0), Dual(1, 0, 1, 0)), Dual(0.5, 0, 0, 1))
    end

    for VT in (NamedTuple, ShapedAsNT)
        src_dist = unshaped(NamedTupleDist(VT, a = Weibull(), b = MvNormal([1.3 0.6; 0.6 2.4])))
        f = vartransform(Normal, src_dist)
        x = rand(src_dist)
        InverseFunctions.test_inverse(f, x)
        ChangesOfVariables.test_with_logabsdet_jacobian(f, x, ForwardDiff.jacobian)
    end

    @testset "trafo broadcasting" begin
        dist = NamedTupleDist(a = Weibull(), b = Exponential())
        smpls = bat_sample(dist, IIDSampling(nsamples = 100)).result
        trafo = vartransform(Normal, dist)
        @inferred(broadcast(trafo, smpls)) isa DensitySampleVector
        smpls_tr = trafo.(smpls)
        smpls_tr_cmp = [trafo(s) for s in smpls]
        @test smpls_tr == smpls_tr_cmp
	    @test @inferred(varshape(trafo)) == varshape(trafo.source_dist)
	    @test @inferred(trafo(varshape(trafo))) == varshape(trafo.target_dist)
    end

    @testset "trafo composition" begin
        dist1 = @inferred(NamedTupleDist(a = Normal(), b = Uniform(), c = Cauchy()))
        dist2 = @inferred(NamedTupleDist(a = Exponential(), b = Weibull(), c = Beta()))
        normal1 = Normal()
        normal2 = Normal(2)

        trafo = @inferred(vartransform(dist1, dist2))
        inv_trafo = @inferred(inverse(trafo))

        composed_trafo = @inferred(∘(trafo, inv_trafo))
        @test composed_trafo.source_dist == composed_trafo.target_dist == dist1
        @test composed_trafo ∘ trafo == trafo
        @test_throws ArgumentError  trafo ∘ composed_trafo

        trafo = @inferred(vartransform(normal1, normal2))
        @test_throws ArgumentError trafo ∘ trafo
    end

    @testset "full density transform" begin
        likelihood = NamedTupleDist(a = Normal(), b = Exponential())
        prior = NamedTupleDist(a = Normal(), b = Gamma())
        posterior_density = PosteriorDensity(likelihood, prior)

        posterior_density_trafod = @inferred(bat_transform(PriorToUniform(), posterior_density, FullDensityTransform()))

        @test posterior_density_trafod.result.orig.likelihood.dist == likelihood
        @test posterior_density_trafod.result.orig.prior.dist == prior

        @test posterior_density_trafod.result.trafo.target_dist isa BAT.StandardMvUniform

        lower_bounds = Float32.([-10, -10, -10])
        upper_bounds = Float32.([10, 10, 10])
        rect_bounds = @inferred(BAT.HyperRectBounds(lower_bounds, upper_bounds))
            mvn = @inferred(product_distribution(Normal.(randn(3))))
        dist_density = @inferred(BAT.DistributionDensity(mvn, rect_bounds))

        dist_density_trafod = @inferred(bat_transform(PriorToUniform(), dist_density, FullDensityTransform()))

        @test dist_density_trafod.trafo.target_dist isa BAT.StandardMvUniform
        @test dist_density_trafod.result.orig == dist_density
        @test dist_density_trafod.trafo.source_dist == dist_density_trafod.result.trafo.source_dist == mvn

        @test dist_density_trafod.trafo(varshape(dist_density_trafod.trafo)) == @inferred(varshape(dist_density))

        dist_density_trafod = @inferred(bat_transform(PriorToGaussian(), dist_density, FullDensityTransform()))

        @test dist_density_trafod.trafo.target_dist isa BAT.StandardMvNormal
        @test dist_density_trafod.result.orig == dist_density
        @test dist_density_trafod.trafo.source_dist == dist_density_trafod.result.trafo.source_dist == mvn

        @test dist_density_trafod.trafo(varshape(dist_density_trafod.trafo)) == @inferred(varshape(dist_density))
    end

    @testset "trafo autodiff pullbacks" begin
        # ToDo: Test for type stability and fix where necessary.

        xs = rand(5)
        @test Zygote.jacobian(BAT._pushfront, xs, 42)[1] ≈ ForwardDiff.jacobian(xs -> BAT._pushfront(xs, 1), xs)
        @test Zygote.jacobian(BAT._pushfront, xs, 42)[2] ≈ vec(ForwardDiff.jacobian(x -> BAT._pushfront(xs, x[1]), [42]))
        @test Zygote.jacobian(BAT._pushback, xs, 42)[1] ≈ ForwardDiff.jacobian(xs -> BAT._pushback(xs, 1), xs)
        @test Zygote.jacobian(BAT._pushback, xs, 42)[2] ≈ vec(ForwardDiff.jacobian(x -> BAT._pushback(xs, x[1]), [42]))
        @test Zygote.jacobian(BAT._rev_cumsum, xs)[1] ≈ ForwardDiff.jacobian(BAT._rev_cumsum, xs)
        @test Zygote.jacobian(BAT._exp_cumsum_log, xs)[1] ≈ ForwardDiff.jacobian(BAT._exp_cumsum_log, xs) ≈ ForwardDiff.jacobian(cumprod, xs)

        x = [0.6, 0.7, 0.8, 0.9]
        f = inverse(vartransform(Uniform, DistributionsAD.TuringDirichlet([3.0, 4.0, 5.0, 6.0, 7.0])))
        @test isapprox(ForwardDiff.jacobian(f, x), Zygote.jacobian(f, x)[1], rtol = 10^-4)
        f = inverse(vartransform(Uniform, Dirichlet([3.0, 4.0, 5.0, 6.0, 7.0])))
        @test isapprox(ForwardDiff.jacobian(f, x), Zygote.jacobian(f, x)[1], rtol = 10^-4)
        f = inverse(vartransform(Normal, Dirichlet([3.0, 4.0, 5.0, 6.0, 7.0])))
        @test isapprox(ForwardDiff.jacobian(f, x), Zygote.jacobian(f, x)[1], rtol = 10^-4)
    end
end


@testset "bat_transform_defaults" begin
    mvn = @inferred(product_distribution([Normal(-1), Normal(), Normal(1)]))
    uniform_prior = @inferred(product_distribution([Uniform(-3, 1), Uniform(-2, 2), Uniform(-1, 3)]))

    posterior_uniform_prior = @inferred(PosteriorDensity(mvn, uniform_prior))
    posterior_gaussian_prior = @inferred(PosteriorDensity(mvn, mvn))

    @test @inferred(bat_transform(PriorToGaussian(), posterior_uniform_prior)).result.prior.dist == @inferred(BAT.StandardMvNormal(3))
    @test @inferred(bat_transform(PriorToUniform(), posterior_gaussian_prior)).result.prior.dist == @inferred(BAT.StandardMvUniform(3))
    @test @inferred(bat_transform(NoDensityTransform(), posterior_uniform_prior)).result.prior.dist == uniform_prior
    pd = @inferred(product_distribution([Uniform() for i in 1:3]))
    density = @inferred(BAT.DistributionDensity(pd))
    @test @inferred(bat_transform(NoDensityTransform(), density)).result.dist == density.dist

    # ToDo: Improve comparison for bounds so `.dist` is not required here:
    @inferred(bat_transform(PriorToUniform(), convert(AbstractDensity, BAT.StandardUvUniform()))).result.dist == convert(AbstractDensity, BAT.StandardUvUniform()).dist
    @inferred(bat_transform(PriorToUniform(), convert(AbstractDensity, BAT.StandardMvUniform(4)))).result.dist == convert(AbstractDensity, BAT.StandardMvUniform(4)).dist
    @inferred(bat_transform(PriorToGaussian(), convert(AbstractDensity, BAT.StandardUvNormal()))).result.dist == convert(AbstractDensity, BAT.StandardUvNormal()).dist
    @inferred(bat_transform(PriorToGaussian(), convert(AbstractDensity, BAT.StandardMvNormal(4)))).result.dist == convert(AbstractDensity, BAT.StandardMvNormal(4)).dist
end