using Callsite


@callsite typed function spirv(body, args)
    checked_arg_expr = check_and_convert_for_gpu(args)
    spirv = juliatyped2spirv(body)
    kernel = spirv2binary(spirv)
    quote
        # <- insert some setup here, maybe dependant on the args
        launch($kernel, $(checked_arg_expr.args...))
        # <- insert some teardown here, maybe dependant on the args
    end
end

#similarly
@callsite llvm function ptx(func_llvm::String)
    kernel = ptx2binary(llvmir2ptx(func_llvm))
    quote
        # <- insert some setup here, maybe dependant on the args
        launch($kernel, $(checked_arg_expr.args...))
        # <- insert some teardown here, maybe dependant on the args
    end
end


function map(f, a::CUDAArray, b::CUDAArray)
    _call(ptx, f, a, b)
end

function map(f, a::VulkanArray, b::VulkanArray)
    _call(spirv, f, a, b)
end
