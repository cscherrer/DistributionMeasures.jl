# This file is a part of BAT.jl, licensed under the MIT License (MIT).

using VariateTransformations
using Test

using Random, Statistics, LinearAlgebra
using Distributions, PDMats
using StableRNGs


@testset "standard_normal" begin
    stblrng() = StableRNG(789990641)

    @testset "StandardUvNormal" begin
        @test @inferred(Normal(VariateTransformations.StandardUvNormal())) isa Normal{Float64}
        @test @inferred(Normal(VariateTransformations.StandardUvNormal())) == Normal()
        @test @inferred(convert(Normal, VariateTransformations.StandardUvNormal())) == Normal()

        d = VariateTransformations.StandardUvNormal()
        dref = Normal()

        @test @inferred(minimum(d)) == minimum(dref)
        @test @inferred(maximum(d)) == maximum(dref)
        
        @test @inferred(params(d)) == params(dref)
        @test @inferred(partype(d)) == partype(dref)
        
        @test @inferred(location(d)) == location(dref)
        @test @inferred(scale(d)) == scale(dref)
        
        @test @inferred(eltype(typeof(d))) == eltype(typeof(dref))
        @test @inferred(eltype(d)) == eltype(dref)

        @test @inferred(length(d)) == length(dref)
        @test @inferred(size(d)) == size(dref)

        @test @inferred(mean(d)) == mean(dref)
        @test @inferred(median(d)) == median(dref)
        @test @inferred(mode(d)) == mode(dref)
        @test @inferred(modes(d)) ≈ modes(dref)
        
        @test @inferred(var(d)) == var(dref)
        @test @inferred(std(d)) == std(dref)
        @test @inferred(skewness(d)) == skewness(dref)
        @test @inferred(kurtosis(d)) == kurtosis(dref)
        
        @test @inferred(entropy(d)) == entropy(dref)
        
        for x in [-Inf, -1.3, 0.0, 1.3, +Inf]
            @test @inferred(gradlogpdf(d, x)) == gradlogpdf(dref, x)
            
            @test @inferred(logpdf(d, x)) == logpdf(dref, x)
            @test @inferred(pdf(d, x)) == pdf(dref, x)
            @test @inferred(logcdf(d, x)) == logcdf(dref, x)
            @test @inferred(cdf(d, x)) == cdf(dref, x)
            @test @inferred(logccdf(d, x)) == logccdf(dref, x)
            @test @inferred(ccdf(d, x)) == ccdf(dref, x)
        end

        for p in [0.0, 0.25, 0.75, 1.0]
            @test @inferred(quantile(d, p)) == quantile(dref, p)
            @test @inferred(cquantile(d, p)) == cquantile(dref, p)
        end

        for t in [-3, 0, 3]
            @test @inferred(mgf(d, t)) == mgf(dref, t)
            @test @inferred(cf(d, t)) == cf(dref, t)
        end

        @test @inferred(rand(stblrng(), d)) == rand(stblrng(), d)
        @test @inferred(rand(stblrng(), d, 5)) == rand(stblrng(), d, 5)

        @test @inferred(truncated(VariateTransformations.StandardUvNormal(), -2.2f0, 3.1f0)) isa Truncated{Normal{Float64}}
        @test truncated(VariateTransformations.StandardUvNormal(), -2.2f0, 3.1f0) == truncated(Normal(0.0f0, 1.0f0), -2.2f0, 3.1f0)

        @test @inferred(product_distribution(fill(VariateTransformations.StandardUvNormal(), 3))) isa VariateTransformations.StandardDist{Normal,1}
        @test product_distribution(fill(VariateTransformations.StandardUvNormal(), 3)) == VariateTransformations.StandardDist{Normal,1}(3)
    end


    @testset "StandardDist{Normal,1}" begin
        @test @inferred(VariateTransformations.StandardDist{Normal,1}(3)) isa VariateTransformations.StandardDist{Normal,1}
        @test @inferred(VariateTransformations.StandardDist{Normal,1}(3)) isa VariateTransformations.StandardDist{Normal,1}
        @test @inferred(VariateTransformations.StandardDist{Normal,1}(3)) isa VariateTransformations.StandardDist{Normal,1}

        @test @inferred(Distributions.Product(VariateTransformations.StandardDist{Normal,1}(3))) isa Distributions.Product{Continuous,VariateTransformations.StandardUvNormal}
        @test @inferred(Distributions.Product(VariateTransformations.StandardDist{Normal,1}(3))) isa Distributions.Product{Continuous,VariateTransformations.StandardUvNormal}
        @test @inferred(Distributions.Product(VariateTransformations.StandardDist{Normal,1}(3))) == Distributions.Product(Fill(VariateTransformations.StandardUvNormal(), 3))
        @test @inferred(convert(Product, VariateTransformations.StandardDist{Normal,1}(3))) == Distributions.Product(Fill(VariateTransformations.StandardUvNormal(), 3))

        @test @inferred(MvNormal(VariateTransformations.StandardDist{Normal,1}(3))) isa MvNormal{Float64}
        @test @inferred(MvNormal(VariateTransformations.StandardDist{Normal,1}(3))) == MvNormal(ScalMat(3, 1.0))
        @test @inferred(convert(MvNormal, VariateTransformations.StandardDist{Normal,1}(3))) == MvNormal(ScalMat(3, 1.0))

        d = VariateTransformations.StandardDist{Normal,1}(3)
        dref = MvNormal(ScalMat(3, 1.0))

        @test @inferred(eltype(typeof(d))) == eltype(typeof(dref))
        @test @inferred(eltype(d)) == eltype(dref)

        @test @inferred(length(d)) == length(dref)
        @test @inferred(size(d)) == size(dref)

        @test @inferred(view(VariateTransformations.StandardDist{Normal,1}(7), 3)) isa VariateTransformations.StandardUvNormal
        @test_throws BoundsError view(VariateTransformations.StandardDist{Normal,1}(7), 9)
        @test @inferred(view(VariateTransformations.StandardDist{Normal,1}(7), 2:4)) isa VariateTransformations.StandardDist{Normal,1}
        @test view(VariateTransformations.StandardDist{Normal,1}(7), 2:4) == VariateTransformations.StandardDist{Normal,1}(3)
        @test_throws BoundsError view(VariateTransformations.StandardDist{Normal,1}(7), 2:8)
        
        @test @inferred(params(d)) == params(dref)
        @test @inferred(partype(d)) == partype(dref)
        
        @test @inferred(mean(d)) == mean(dref)
        @test @inferred(var(d)) == var(dref)
        @test @inferred(cov(d)) == cov(dref)
        
        @test @inferred(mode(d)) == mode(dref)
        @test @inferred(modes(d)) == modes(dref)
        
        @test @inferred(invcov(d)) == invcov(dref)
        @test @inferred(logdetcov(d)) == logdetcov(dref)
        
        @test @inferred(entropy(d)) == entropy(dref)

        for x in fill.([-Inf, -1.3, 0.0, 1.3, +Inf], 3)
            @test @inferred(insupport(d, x)) == insupport(dref, x)
            @test @inferred(logpdf(d, x)) == logpdf(dref, x)
            @test @inferred(pdf(d, x)) == pdf(dref, x)
            @test @inferred(sqmahal(d, x)) == sqmahal(dref, x)
            @test @inferred(gradlogpdf(d, x)) == gradlogpdf(dref, x)
        end
            
        @test @inferred(rand(stblrng(), d)) == rand(stblrng(), d)
        @test @inferred(rand!(stblrng(), d, zeros(3))) == rand!(stblrng(), d, zeros(3))
        @test @inferred(rand!(stblrng(), d, zeros(3, 10))) == rand!(stblrng(), d, zeros(3, 10))
    end
end