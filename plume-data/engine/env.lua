return function(plume)
	plume.env = {}
	plume.env.plume_path = os.getenv("PLUME_PATH")
end