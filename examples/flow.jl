using Callsite

# Variant of https://github.com/MikeInnes/Flow.jl, that works with arbitrary generic functions

function var(xs)
  mean = sum(xs)/length(xs)
  meansqr = sumabs2(xs)/length(xs)
  return meansqr - mean^2
end

@callsite typed function flow(body, args)
    graph = make_flow_graph(body) # makes a flow graph
    optimized_graph = optimize_graph(graph) # e.g. removes temporaries
    compile(optimized_graph, :Julia) # compile to julia code, or spark ??!
end

_call(flow, var, rand(10))
