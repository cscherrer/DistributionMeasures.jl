var documenterSearchIndex = {"docs":
[{"location":"","page":"Home","title":"Home","text":"CurrentModule = DistributionMeasures","category":"page"},{"location":"#DistributionMeasures","page":"Home","title":"DistributionMeasures","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"Documentation for DistributionMeasures.","category":"page"},{"location":"","page":"Home","title":"Home","text":"DistributionMeasures provides conversions between Distributions.jl distributions and MeasureBase.jl/MeasureTheory.jl measures.","category":"page"},{"location":"","page":"Home","title":"Home","text":"","category":"page"},{"location":"","page":"Home","title":"Home","text":"Modules = [DistributionMeasures]","category":"page"},{"location":"#DistributionMeasures.DistributionMeasure","page":"Home","title":"DistributionMeasures.DistributionMeasure","text":"struct DistributionMeasure <: AbstractMeasure\n\nWraps a Distributions.Distribution as a MeasureBase.AbstractMeasure.\n\nAvoid calling DistributionMeasure(d::Distribution) directly. Instead, use AbstractMeasure(d::Distribution) to allow for specialized Distribution to AbstractMeasure conversions.\n\nUse convert(Distribution, m::DistributionMeasure) or Distribution(m::DistributionMeasure) to convert back to a Distribution.\n\n\n\n\n\n","category":"type"},{"location":"#DistributionMeasures.StandardDist","page":"Home","title":"DistributionMeasures.StandardDist","text":"struct StandardDist{D<:Distribution{Univariate,Continuous},N} <: Distributions.Distribution{ArrayLikeVariate{N},Continuous}\n\nRepresents D() or a product distribution of D() in a dispatchable fashion.\n\nConstructor:\n\n    StandardDist{Uniform}(size...)\n    StandardDist{Normal}(size...)\n\n\n\n\n\n","category":"type"},{"location":"#DistributionMeasures.StandardNormal","page":"Home","title":"DistributionMeasures.StandardNormal","text":"const StandardNormal{N} = StandardDist{Normal,N}\n\nThe univariate standard normal distribution.\n\n\n\n\n\n","category":"type"},{"location":"#DistributionMeasures.StandardUniform","page":"Home","title":"DistributionMeasures.StandardUniform","text":"const StandardUniform{N} = StandardDist{Uniform,N}\n\nThe univariate standard uniform distribution.\n\n\n\n\n\n","category":"type"},{"location":"#DistributionMeasures.convert_realtype","page":"Home","title":"DistributionMeasures.convert_realtype","text":"convert_realtype(::Type{T}, x) where {T<:Real}\n\nConvert x to use T as it's underlying type for real numbers.\n\n\n\n\n\n","category":"function"},{"location":"#DistributionMeasures.firsttype","page":"Home","title":"DistributionMeasures.firsttype","text":"DistributionMeasures.firsttype(::Type{T}, ::Type{U}) where {T<:Real,U<:Real}\n\nReturn the first type, but as a dual number type if the second one is dual.\n\nIf U <: ForwardDiff.Dual{tag,<:Real,N}, returns ForwardDiff.Dual{tag,T,N}, otherwise returns T\n\n\n\n\n\n","category":"function"}]
}
