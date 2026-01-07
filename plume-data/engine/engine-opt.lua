return function (plume)
    require "plume-data/engine/vm/acc"
    require "plume-data/engine/vm/alu"
    require "plume-data/engine/vm/call"
    require "plume-data/engine/vm/core"
    require "plume-data/engine/vm/iter"
    require "plume-data/engine/vm/jump"
    require "plume-data/engine/vm/load"
    require "plume-data/engine/vm/meta"
    require "plume-data/engine/vm/others"
    require "plume-data/engine/vm/scope"
    require "plume-data/engine/vm/stack"
    require "plume-data/engine/vm/store"
    require "plume-data/engine/vm/table"
    require "plume-data/engine/vm/utils"
    function plume.run(chunk, arguments)
        local vm = _VM_INIT(plume, chunk, arguments)
        local op, arg1, arg2
        
        ::DISPATCH::
        if vm.err then 
            return false, vm.err, vm.ip, vm.chunk
        end
        if vm.serr then
            return false, unpack(vm.serr)
        end
        _VM_TICK(vm)
        op, arg1, arg2 = _VM_DECODE_CURRENT_INSTRUCTION(vm)
        if op == 1 then 
            goto LOAD_CONSTANT
        elseif  op == 2 then 
            goto LOAD_TRUE
        elseif  op == 3 then 
            goto LOAD_FALSE
        elseif  op == 4 then 
            goto LOAD_EMPTY
        elseif  op == 5 then 
            goto LOAD_LOCAL
        elseif  op == 6 then 
            goto LOAD_LEXICAL
        elseif  op == 7 then 
            goto LOAD_STATIC
        elseif  op == 8 then 
            goto STORE_LOCAL
        elseif  op == 9 then 
            goto STORE_LEXICAL
        elseif  op == 10 then 
            goto STORE_STATIC
        elseif  op == 11 then 
            goto STORE_VOID
        elseif  op == 12 then 
            goto TABLE_NEW
        elseif  op == 13 then 
            goto TABLE_ADD
        elseif  op == 14 then 
            goto TABLE_SET
        elseif  op == 15 then 
            goto TABLE_INDEX
        elseif  op == 16 then 
            goto TABLE_INDEX_ACC_SELF
        elseif  op == 17 then 
            goto TABLE_SET_META
        elseif  op == 18 then 
            goto TABLE_INDEX_META
        elseif  op == 19 then 
            goto TABLE_SET_ACC
        elseif  op == 20 then 
            goto TABLE_SET_ACC_META
        elseif  op == 21 then 
            goto TABLE_EXPAND
        elseif  op == 22 then 
            goto ENTER_SCOPE
        elseif  op == 23 then 
            goto LEAVE_SCOPE
        elseif  op == 24 then 
            goto BEGIN_ACC
        elseif  op == 25 then 
            goto ACC_TABLE
        elseif  op == 26 then 
            goto ACC_TEXT
        elseif  op == 27 then 
            goto ACC_EMPTY
        elseif  op == 28 then 
            goto ACC_CALL
        elseif  op == 29 then 
            goto ACC_CHECK_TEXT
        elseif  op == 30 then 
            goto JUMP_IF
        elseif  op == 31 then 
            goto JUMP_IF_NOT
        elseif  op == 32 then 
            goto JUMP_IF_NOT_EMPTY
        elseif  op == 33 then 
            goto JUMP
        elseif  op == 34 then 
            goto JUMP_IF_PEEK
        elseif  op == 35 then 
            goto JUMP_IF_NOT_PEEK
        elseif  op == 36 then 
            goto GET_ITER
        elseif  op == 37 then 
            goto FOR_ITER
        elseif  op == 38 then 
            goto OPP_ADD
        elseif  op == 39 then 
            goto OPP_MUL
        elseif  op == 40 then 
            goto OPP_SUB
        elseif  op == 41 then 
            goto OPP_DIV
        elseif  op == 42 then 
            goto OPP_NEG
        elseif  op == 43 then 
            goto OPP_MOD
        elseif  op == 44 then 
            goto OPP_POW
        elseif  op == 45 then 
            goto OPP_GTE
        elseif  op == 46 then 
            goto OPP_LTE
        elseif  op == 47 then 
            goto OPP_GT
        elseif  op == 48 then 
            goto OPP_LT
        elseif  op == 49 then 
            goto OPP_EQ
        elseif  op == 50 then 
            goto OPP_NEQ
        elseif  op == 51 then 
            goto OPP_AND
        elseif  op == 52 then 
            goto OPP_NOT
        elseif  op == 53 then 
            goto OPP_OR
        elseif  op == 54 then 
            goto DUPLICATE
        elseif  op == 55 then 
            goto SWITCH
        elseif  op == 56 then 
            goto END
        end
        
        ::LOAD_CONSTANT::
        LOAD_CONSTANT(vm, arg1, arg2)
        goto DISPATCH
        
        ::LOAD_TRUE::
        LOAD_TRUE(vm, arg1, arg2)
        goto DISPATCH
        
        ::LOAD_FALSE::
        LOAD_FALSE(vm, arg1, arg2)
        goto DISPATCH
        
        ::LOAD_EMPTY::
        LOAD_EMPTY(vm, arg1, arg2)
        goto DISPATCH
        
        ::LOAD_LOCAL::
        LOAD_LOCAL(vm, arg1, arg2)
        goto DISPATCH
        
        ::LOAD_LEXICAL::
        LOAD_LEXICAL(vm, arg1, arg2)
        goto DISPATCH
        
        ::LOAD_STATIC::
        LOAD_STATIC(vm, arg1, arg2)
        goto DISPATCH
        
        ::STORE_LOCAL::
        STORE_LOCAL(vm, arg1, arg2)
        goto DISPATCH
        
        ::STORE_LEXICAL::
        STORE_LEXICAL(vm, arg1, arg2)
        goto DISPATCH
        
        ::STORE_STATIC::
        STORE_STATIC(vm, arg1, arg2)
        goto DISPATCH
        
        ::STORE_VOID::
        STORE_VOID(vm, arg1, arg2)
        goto DISPATCH
        
        ::TABLE_NEW::
        TABLE_NEW(vm, arg1, arg2)
        goto DISPATCH
        
        ::TABLE_ADD::
        TABLE_ADD(vm, arg1, arg2)
        goto DISPATCH
        
        ::TABLE_SET::
        TABLE_SET(vm, arg1, arg2)
        goto DISPATCH
        
        ::TABLE_INDEX::
        TABLE_INDEX(vm, arg1, arg2)
        goto DISPATCH
        
        ::TABLE_INDEX_ACC_SELF::
        TABLE_INDEX_ACC_SELF(vm, arg1, arg2)
        goto DISPATCH
        
        ::TABLE_SET_META::
        TABLE_SET_META(vm, arg1, arg2)
        goto DISPATCH
        
        ::TABLE_INDEX_META::
        TABLE_INDEX_META(vm, arg1, arg2)
        goto DISPATCH
        
        ::TABLE_SET_ACC::
        TABLE_SET_ACC(vm, arg1, arg2)
        goto DISPATCH
        
        ::TABLE_SET_ACC_META::
        TABLE_SET_ACC_META(vm, arg1, arg2)
        goto DISPATCH
        
        ::TABLE_EXPAND::
        TABLE_EXPAND(vm, arg1, arg2)
        goto DISPATCH
        
        ::ENTER_SCOPE::
        ENTER_SCOPE(vm, arg1, arg2)
        goto DISPATCH
        
        ::LEAVE_SCOPE::
        LEAVE_SCOPE(vm, arg1, arg2)
        goto DISPATCH
        
        ::BEGIN_ACC::
        BEGIN_ACC(vm, arg1, arg2)
        goto DISPATCH
        
        ::ACC_TABLE::
        ACC_TABLE(vm, arg1, arg2)
        goto DISPATCH
        
        ::ACC_TEXT::
        ACC_TEXT(vm, arg1, arg2)
        goto DISPATCH
        
        ::ACC_EMPTY::
        ACC_EMPTY(vm, arg1, arg2)
        goto DISPATCH
        
        ::ACC_CALL::
        ACC_CALL(vm, arg1, arg2)
        goto DISPATCH
        
        ::ACC_CHECK_TEXT::
        ACC_CHECK_TEXT(vm, arg1, arg2)
        goto DISPATCH
        
        ::JUMP_IF::
        JUMP_IF(vm, arg1, arg2)
        goto DISPATCH
        
        ::JUMP_IF_NOT::
        JUMP_IF_NOT(vm, arg1, arg2)
        goto DISPATCH
        
        ::JUMP_IF_NOT_EMPTY::
        JUMP_IF_NOT_EMPTY(vm, arg1, arg2)
        goto DISPATCH
        
        ::JUMP::
        JUMP(vm, arg1, arg2)
        goto DISPATCH
        
        ::JUMP_IF_PEEK::
        JUMP_IF_PEEK(vm, arg1, arg2)
        goto DISPATCH
        
        ::JUMP_IF_NOT_PEEK::
        JUMP_IF_NOT_PEEK(vm, arg1, arg2)
        goto DISPATCH
        
        ::GET_ITER::
        GET_ITER(vm, arg1, arg2)
        goto DISPATCH
        
        ::FOR_ITER::
        FOR_ITER(vm, arg1, arg2)
        goto DISPATCH
        
        ::OPP_ADD::
        OPP_ADD(vm, arg1, arg2)
        goto DISPATCH
        
        ::OPP_MUL::
        OPP_MUL(vm, arg1, arg2)
        goto DISPATCH
        
        ::OPP_SUB::
        OPP_SUB(vm, arg1, arg2)
        goto DISPATCH
        
        ::OPP_DIV::
        OPP_DIV(vm, arg1, arg2)
        goto DISPATCH
        
        ::OPP_NEG::
        OPP_NEG(vm, arg1, arg2)
        goto DISPATCH
        
        ::OPP_MOD::
        OPP_MOD(vm, arg1, arg2)
        goto DISPATCH
        
        ::OPP_POW::
        OPP_POW(vm, arg1, arg2)
        goto DISPATCH
        
        ::OPP_GTE::
        OPP_GTE(vm, arg1, arg2)
        goto DISPATCH
        
        ::OPP_LTE::
        OPP_LTE(vm, arg1, arg2)
        goto DISPATCH
        
        ::OPP_GT::
        OPP_GT(vm, arg1, arg2)
        goto DISPATCH
        
        ::OPP_LT::
        OPP_LT(vm, arg1, arg2)
        goto DISPATCH
        
        ::OPP_EQ::
        OPP_EQ(vm, arg1, arg2)
        goto DISPATCH
        
        ::OPP_NEQ::
        OPP_NEQ(vm, arg1, arg2)
        goto DISPATCH
        
        ::OPP_AND::
        OPP_AND(vm, arg1, arg2)
        goto DISPATCH
        
        ::OPP_NOT::
        OPP_NOT(vm, arg1, arg2)
        goto DISPATCH
        
        ::OPP_OR::
        OPP_OR(vm, arg1, arg2)
        goto DISPATCH
        
        ::DUPLICATE::
        DUPLICATE(vm, arg1, arg2)
        goto DISPATCH
        
        ::SWITCH::
        SWITCH(vm, arg1, arg2)
        goto DISPATCH
        
        ::END::
        return true, _STACK_GET(vm.mainStack)
    end
end