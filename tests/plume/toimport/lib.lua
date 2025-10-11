return function (plume)
	return plume.obj.luaFunction ("double", function(args)
		local x = args.table[1]
		return 2*x
	end)
end