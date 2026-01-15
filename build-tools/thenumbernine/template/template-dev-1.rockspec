package = 'template'
version = 'dev-1'
source = {
	url = 'git+https://github.com/thenumbernine/lua-template.git'
}
description = {
	summary = [[Here's an example of how it works.  Similar to PHP.  ]],
	detailed = [[Here's an example of how it works.  Similar to PHP.  ]],
	homepage = 'https://github.com/thenumbernine/lua-template',
	license = 'MIT',
}
dependencies = {
	'lua >= 5.1',
}
build = {
	type = 'builtin',
	modules = {
		['template.output'] = 'output.lua',
		['template.showcode'] = 'showcode.lua',
		['template'] = 'template.lua',
	}
}
