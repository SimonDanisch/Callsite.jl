module Callsite

# sketch of a call site macro, which support different stages
#so stuff could look like this:
function remove_slots(slot::Slot)
    sym = symbol("_$(slot.id)")
    if slot.typ == Any
        return sym
    else
        return Expr(:(::), sym, slot.typ)
    end
end
remove_slots(no_slot) = no_slot
function remove_slots(expressions::Vector)
    out = []
    for elem in expressions
        if isa(elem, Expr)
            args = remove_slots(elem.args)
            expr = Expr(elem.head); expr.args = args
            push!(out, expr)
        else
            push!(out, remove_slots(elem))
        end
    end
    out
end
callsite_typed(transformation, f, types) = callsite_lambda(code_typed, transformation, f, types)
callsite_lowered(transformation, f, types) = callsite_lambda(code_lowered, transformation, f, types)
function callsite_lambda(stage, transformation, f, types)
    names = [symbol("_$(i+1)") for i=1:length(types)]
    lam = stage(f, types)[1]
    typenames = [Expr(:(::), name, typ) for (name, typ) in zip(names, types)]

    u_code = Base.uncompressed_ast(lam)
    body = transformation(u_code, typenames)
    funbody = Expr(:block);
    renamed_args = [:($(names[i])::$(types[i]) = types[$i]::$(types[i])) for i=1:length(types)]
    append!(funbody.args, renamed_args)
    append!(funbody.args, remove_slots(body))
    funbody
end
function callsite_llvm(transformation, f, types)
    io = IOBuffer
    ir = takebuf_string(code_llvm(io, f.instance, types))
    expr = transformation(ir, types) # this should rather return IR?
end

callsite_stage_dict = Dict{Any, Function}()

macro callsite(stage, func)
    @assert func.head == :function
    @assert stage == :typed || stage == :lowered || stage == :llvm
    esc(quote
        $func
        Callsite.callsite_stage_dict[typeof($(func.args[1].args[1]))] = Callsite.$(symbol("callsite_$stage"))
    end)
end

@generated function _call{N}(transformation, f, types::NTuple{N}) # this needs to be _1, _2 for inline to actually work
    stage = callsite_stage_dict[transformation]
    stage(transformation.instance, f.instance, tuple(types.parameters...))
end


export _call, @callsite


end # module
