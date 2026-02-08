--[[This file is part of Plume

Plume🪶 is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, version 3 of the License.

Plume🪶 is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with Plume🪶.
If not, see <https://www.gnu.org/licenses/>.
]]

--- @opcode
--! inline
function STD_LEN(vm, arg1, arg2)
	local t = _STACK_POP(vm.mainStack).table[1]
	local tt = type(t)
    local result
	if tt == "table" then
        result = #t.table
    elseif tt == "string" then
        result = #t
    else
        _ERROR(vm, vm.plume.error.hasNoLen(tt))
    end
    _STACK_PUSH(vm.mainStack, result)
end

--- @opcode
--! inline
function STD_TYPE(vm, arg1, arg2)
    local t = _STACK_POP(vm.mainStack).table[1]
    _STACK_PUSH(vm.mainStack, _GET_TYPE(vm, t))
end

--- @opcode
--! inline
function STD_SEQ(vm, arg1, arg2)
    local args = _STACK_POP(vm.mainStack).table
    local start = args[1]
    local stop  = args[2]
    local step  = args[3] or 1

    if not stop then
        stop = start
        start = 1
    end

    start = tonumber(start)
    stop = tonumber(stop)

    _STACK_PUSH(vm.mainStack, {
        type = "stdIterator",
        start=start-step, --FOR_ITER increment state before using it
        stop=stop,
        step=step,
        flag = vm.flag.ITER_SEQ
    })
end

--- @opcode
--! inline
function STD_ITEMS(vm, arg1, arg2)
    local args = _STACK_POP(vm.mainStack).table

    ---------------------------------
    -- WILL BE REMOVED IN 1.0 (#228, #230)
    ---------------------------------
    if args.legacy then
        vm.plume.warning.deprecated(
                    "1.0",
                    "`?legacy` flag for macro items",
                    "Instead of \n```\nfor x in items(t, ?legacy)\n\tx.key -> x.value\nend\n```\ndo\n```\nfor key, value in items(t)\n\tkey -> value\nend\n```",
                    vm.runtime, vm.ip, 228
                )
    end
    ---------------------------------

    _STACK_PUSH(vm.mainStack, {
        type = "stdIterator",
        ref  = args[1],
        flag = vm.flag.ITER_ITEMS,
        named = args.named,
        ---------------------------------
        -- WILL BE REMOVED IN 1.0 (#228, #230)
        ---------------------------------
        legacy = args.legacy
        ---------------------------------
    })
end

--- @opcode
--! inline
function STD_ENUMERATE(vm, arg1, arg2)
    local args = _STACK_POP(vm.mainStack).table

    ---------------------------------
    -- WILL BE REMOVED IN 1.0 (#228, #230)
    ---------------------------------
    if args.legacy then
        vm.plume.warning.deprecated(
                    "1.0",
                    "`?legacy` flag for macro enumerate",
                    "Instead of \n```\nfor x in enumerate(t, ?legacy)\n\tx.index -> x.value\nend\n```\ndo\n```\nfor index, value in enumerate(t)\n\tindex -> value\nend\n```",
                    vm.runtime, vm.ip, 228
                )
    end
    ---------------------------------

    _STACK_PUSH(vm.mainStack, {
        type = "stdIterator",
        ref = args[1],
        flag = vm.flag.ITER_ENUMS,
        ---------------------------------
        -- WILL BE REMOVED IN 1.0 (#228, #230)
        ---------------------------------
        legacy = args.legacy
        ---------------------------------
    })
end

--- @opcode
--! inline
function STD_IMPORT(vm, arg1, arg2)
    local args = _STACK_POP(vm.mainStack)

    local firstFilename = vm.runtime.files[1].name
    local lastFilename  = vm.runtime.files[vm.fileStack[vm.fileStack.pointer]].name

    local filename, searchPaths = vm.plume.getFilenameFromPath(
        args.table[1],
        ---------------------------------
        -- WILL BE REMOVED IN 1.0 (#235, #230)
        ---------------------------------
        args.table.lua,
        ---------------------------------
        vm.runtime,
        firstFilename,
        lastFilename
    )

    if filename then
        ---------------------------------
        -- WILL BE REMOVED IN 1.0 (#235, #230)
        ---------------------------------
        if args.table.lua then
            local result = dofile(filename)(vm.plume)
            _STACK_PUSH(vm.mainStack, result or vm.empty)
        ---------------------------------
        else
            local success = true
            local err
            local chunk = vm.runtime.files[filename]
            if not chunk then
                chunk =  vm.plume.obj.macro(filename, vm.runtime)

                local f = io.open(filename)
                    local code = f:read("*a")
                f:close()
                success, err = pcall(vm.plume.compileFile, code, filename, chunk, vm.runtime)
                vm.runtime.files[filename] = chunk
            end
            if success then
                -- Add params to static
                for _, key in ipairs(args.keys) do
                    local offset = chunk.namedParamOffset[key]
                    if offset then
                        chunk.static[offset] = args.table[key]
                    end
                end

                -- prepare stack and jumps
                _STACK_PUSH(vm.fileStack, chunk.fileID)
                _STACK_PUSH(vm.macroStack, vm.ip + 1)
                -- ENTER_SCOPE is already the first file instruction
                _INJECTION_PUSH(vm, vm.plume.ops.JUMP, 0, chunk.offset)
            else
                _ERROR(vm, err)
            end
        end
    else
        _ERROR(vm, vm.plume.error.cannotOpenFile(args[1], searchPaths))
    end
end