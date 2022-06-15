# This file is a part of BAT.jl, licensed under the MIT License (MIT).


"""
    struct StandardDist{D<:Distribution{Univariate,Continuous},N} <: Distributions.Distribution{ArrayLikeVariate{N},Continuous}

Represents `D()` or a product distribution of `D()` in a dispatchable fashion.

Constructor:
```
    StandardDist{Uniform}(size...)
    StandardDist{Normal}(size...)
```
"""
struct StandardDist{D<:Distribution{Univariate,Continuous},N} <: Distributions.Distribution{ArrayLikeVariate{N},Continuous}
    _size::Dims{N}
end
export StandardDist

const StandardUnivariateDist{D<:Distribution{Univariate,Continuous}} = StandardDist{D,0}
const StandardMultivariteDist{D<:Distribution{Multivariate,Continuous}} = StandardDist{D,1}


StandardDist{D,N}(dims::Vararg{Integer,N}) where {D<:Distribution{Univariate,Continuous},N} = StandardDist{D,N}(dims)
StandardDist{D}(dims::Vararg{Integer,N}) where {D<:Distribution{Univariate,Continuous},N} = StandardDist{D,N}(dims)
StandardDist{D}(dims::Vararg{Integer,N}) where {D<:Distribution{Univariate,Continuous},N} = StandardDist{D,Float64}(dims...)


function Base.show(io::IO, d::StandardDist{D}) where {D}
    print(io, nameof(typeof(d)), "{", D, "}")
    show(io, d._size)
end


@inline nonstddist(d::StandardDist{D,0}) where {D} = D(params(D())...)


(::Type{D}, d::StandardDist{D,0}) where {D<:Distribution{Univariate,Continuous}} = nonstddist(d)

# TODO: Replace `fill` by `FillArrays.Fill` once Distributions fully supports this:
(::Type{Distributions.Product})(d::StandardDist{D,1}) where {D} = Distributions.Product(fill(StandardDist{D}(), length(d)))

Base.convert(::Type{D}, d::StandardDist{D,0}) where {D<:Distribution{Univariate,Continuous}} = D(d)
Base.convert(::Type{Distributions.Product}, d::StandardDist{D,1}) where {D} = Distributions.Product(d)


function _checkvarsize(d::Distribution{ArrayLikeVariate{N}}, x::AbstractArray{<:Real,N}) where N
    size(d) == size(x) || throw(DimensionMismatch("Size of variate doesn't match distribution"))
end

function ChainRulesCore.rrule(::typeof(_checkvarsize), d::Distribution{ArrayLikeVariate{N}}, x::AbstractArray{<:Real,N}) where N
    _checkvarsize(d, x), _nogradient_pullback2
end



@inline Base.size(d::StandardDist) = d._size
@inline Base.length(d::StandardDist) = prod(size(d))

Base.eltype(::Type{StandardDist{D,N}}) where {D,N} = Float64

@inline Distributions.partype(d::StandardDist{D}) where {D} = Float64

@inline StatsBase.params(d::StandardDist) = ()

function Distributions.insupport(d::StandardDist{D,N}, x::AbstractArray{U,N}) where {D,N,U<:Real}
    _checkvarsize(d, x)
    all(xi -> insupport(StandardDist{D}(), xi), x)
end

for f in (
    :(Base.minimum),
    :(Base.maximum),
    :(Statistics.mean),
    :(Statistics.median),
    :(StatsBase.mode),
    :(Statistics.var),
    :(Statistics.std),
    :(StatsBase.skewness),
    :(StatsBase.kurtosis),
    :(Distributions.location),    
    :(Distributions.scale),    
)
    @eval begin
        ($f)(d::StandardDist{D,0}) where {D} = ($f)(nonstddist(d))
        ($f)(d::StandardDist{D,N}) where {D,N} = Fill(($f)(StandardDist{D}()), size(d)...)
    end
end

StatsBase.modes(d::StandardDist) = [mode(d)]

# ToDo: Define cov for N!=1?
Statistics.cov(d::StandardDist{D,1}) where {D} = Diagonal(var(d))
Distributions.invcov(d::StandardDist{D,1}) where {D} = Diagonal(Fill(inv(var(StandardDist{D}())), length(d)))
Distributions.logdetcov(d::StandardDist{D,1}) where {D} = log(var(StandardDist{D}())) + length(d)

StatsBase.entropy(d::StandardDist{D,0}) where {D} = entropy(nonstddist(d))
StatsBase.entropy(d::StandardDist{D,N}) where {D,N} = length(d) * entropy(StandardDist{D}())


Distributions.insupport(d::StandardDist{D,0}, x::Real) where {D} = insupport(nonstddist(d), x)

function Distributions.insupport(d::StandardDist{D,N}, x::AbstractArray{<:Real,N}) where {D,N}
    _checkvarsize(d, x)
    all(Base.Fix1(insupport, StandardDist{D}()), x)
end

@inline Distributions.logpdf(d::StandardDist{D,0}, x::U) where {D,U} = logpdf(nonstddist(d), x)

function Distributions.logpdf(d::StandardDist{D,1}, x::AbstractVector{U}) where {D,U<:Real}
    _checkvarsize(d, x)
    Distributions._logpdf(d, x)
end

function Distributions._logpdf(d::StandardDist{D,1}, x::AbstractVector{U}) where {D,U<:Real}
    sum(x_i -> logpdf(StandardDist{D,0}(), x_i), x)
end

function Distributions.logpdf(d::StandardDist{D,2}, x::AbstractMatrix{U}) where {D,U<:Real}
    _checkvarsize(d, x)
    Distributions._logpdf(d, x)
end

function Distributions._logpdf(d::StandardDist{D,2}, x::AbstractMatrix{U}) where {D,U<:Real}
    sum(x_i -> logpdf(StandardDist{D,0}(), x_i), x)
end

function Distributions.logpdf(d::StandardDist{D,N}, x::AbstractArray{U,N}) where {D,N,U<:Real}
    _checkvarsize(d, x)
    Distributions._logpdf(d, x)
end

function Distributions._logpdf(d::StandardDist{D,N}, x::AbstractArray{U,N}) where {D,N,U<:Real}
    sum(x_i -> logpdf(StandardDist{D,0}(), x_i), x)
end


Distributions.gradlogpdf(d::StandardDist{D,0}, x::Real) where {D} = gradlogpdf(nonstddist(d), x)

function Distributions.gradlogpdf(d::StandardDist{D,N}, x::AbstractArray{<:Real,N}) where {D,N}
    _checkvarsize(d, x)
    gradlogpdf.(StandardDist{D,0}(), x)
end


#@inline Distributions.pdf(d::StandardDist{D,0}, x::U) where {D,U} = pdf(nonstddist(d), x)

function Distributions.pdf(d::StandardDist{D,1}, x::AbstractVector{U}) where {D,U<:Real}
    _checkvarsize(d, x)
    Distributions._pdf(d, x)
end

function Distributions._pdf(d::StandardDist{D,1}, x::AbstractVector{U}) where {D,U<:Real}
    exp(Distributions._logpdf(d, x))
end

function Distributions.pdf(d::StandardDist{D,2}, x::AbstractMatrix{U}) where {D,U<:Real}
    _checkvarsize(d, x)
    Distributions._pdf(d, x)
end

function Distributions._pdf(d::StandardDist{D,2}, x::AbstractMatrix{U}) where {D,U<:Real}
    exp(Distributions._logpdf(d, x))
end

function Distributions.pdf(d::StandardDist{D,N}, x::AbstractArray{U,N}) where {D,N,U<:Real}
    _checkvarsize(d, x)
    Distributions._pdf(d, x)
end

function Distributions._pdf(d::StandardDist{D,N}, x::AbstractArray{U,N}) where {D,N,U<:Real}
    exp(Distributions._logpdf(d, x))
end


for f in (
    :(Distributions.logcdf),
    :(Distributions.cdf),
    :(Distributions.logccdf),
    :(Distributions.ccdf),
    :(Distributions.quantile),
    :(Distributions.cquantile),
    :(Distributions.invlogcdf),
    :(Distributions.invlogccdf),
    :(Distributions.mgf),
    :(Distributions.cf),
)
    @eval begin
        @inline ($f)(d::StandardDist, x::Real) = ($f)(nonstddist(d), x)
    end
end


Base.rand(rng::AbstractRNG, d::StandardDist{D,0}) where {D} = rand(rng, nonstddist(d))

function Distributions._rand!(rng::AbstractRNG, d::StandardDist{D,N}, A::AbstractArray{U,N}) where {D,N,U<:Real}
    broadcast!(() -> rand(rng, StandardDist{D,U}()), A)
end


Distributions.truncated(d::StandardDist{D,0}, l::Real, u::Real) where {D} = truncated(nonstddist(d), l, u)

Distributions.product_distribution(dists::AbstractVector{StandardDist{D,0}}) where {D} = StandardDist{D}(size(dists)...)
Distributions.product_distribution(dists::AbstractArray{StandardDist{D,0}}) where {D} = StandardDist{D}(size(dists)...)