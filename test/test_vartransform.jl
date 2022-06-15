# This file is a part of DistributionMeasures.jl, licensed under the MIT License (MIT).

using DistributionMeasures
using Test

using LinearAlgebra
using InverseFunctions, ChangesOfVariables
using Distributions, ArraysOfArrays
import ForwardDiff, Zygote

using DistributionMeasures: _trafo_cdf, _trafo_quantile


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

    stduvuni = StandardDist{Uniform,0}()
    stduvnorm = StandardDist{Uniform,0}()

    uniform1 = Uniform(-5.0, -0.01)
    uniform2 = Uniform(0.01, 5.0)

    normal1 = Normal(-10, 1)
    normal2 = Normal(10, 5)

    stdmvnorm1 = StandardDist{Normal}(1)
    stdmvnorm2 = StandardDist{Normal}(2)

    stdmvuni2 = StandardDist{Uniform}(2)

    standnorm2_reshaped = ReshapedDist(stdmvnorm2, varshape(stdmvnorm2))

    mvnorm = MvNormal([0.3, -2.9], [1.7 0.5; 0.5 2.3])
    beta = Beta(3,1)
    gamma = Gamma(0.1,0.7)
    dirich = Dirichlet([0.1,4])

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

    @testset "Custom cdf and quantile for dual numbers" begin
        Dual = ForwardDiff.Dual

        @test _trafo_cdf(Normal(Dual(0, 1, 0, 0), Dual(1, 0, 1, 0)), Dual(0.5, 0, 0, 1)) == cdf(Normal(Dual(0, 1, 0, 0), Dual(1, 0, 1, 0)), Dual(0.5, 0, 0, 1))
        @test _trafo_cdf(Normal(0, 1), Dual(0.5, 1)) == cdf(Normal(0, 1), Dual(0.5, 1))

        @test _trafo_quantile(Normal(0, 1), Dual(0.5, 1)) == quantile(Normal(0, 1), Dual(0.5, 1))
        @test _trafo_quantile(Normal(Dual(0, 1, 0, 0), Dual(1, 0, 1, 0)), Dual(0.5, 0, 0, 1)) == quantile(Normal(Dual(0, 1, 0, 0), Dual(1, 0, 1, 0)), Dual(0.5, 0, 0, 1))
    end

    @testset "trafo autodiff pullbacks" begin
        x = [0.6, 0.7, 0.8, 0.9]
        f = inverse(vartransform(Uniform, Dirichlet([3.0, 4.0, 5.0, 6.0, 7.0])))
        @test isapprox(ForwardDiff.jacobian(f, x), Zygote.jacobian(f, x)[1], rtol = 10^-4)
        f = inverse(vartransform(Normal, Dirichlet([3.0, 4.0, 5.0, 6.0, 7.0])))
        @test isapprox(ForwardDiff.jacobian(f, x), Zygote.jacobian(f, x)[1], rtol = 10^-4)
    end
end
