using Callsite

@callsite lowered function inline(body, args)
    out = Any[Expr(:meta, :inline)]
    for elem in body
        elem != Expr(:meta, :noinline) && push!(out, elem)
    end
    return out
end


@noinline function kernel(a,b)
    x = sqrt(a^2+b^2)
    y = a*b
    (x+y)
end
function test(a, b)
    return _call(inline, kernel, (a, b))
end
function test2(a, b)
    return kernel(a, b)
end
@show test(1.0, 3.0)
@code_llvm test(1.0, 3.0)
@show test2(1.0, 3.0)
@code_llvm test2(1.0, 3.0)
