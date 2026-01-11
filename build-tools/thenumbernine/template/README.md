[![Donate via Stripe](https://img.shields.io/badge/Donate-Stripe-green.svg)](https://buy.stripe.com/00gbJZ0OdcNs9zi288)<br>

This is the template function that was in my LuaJIT-driven HydroCL project.
I liked it so much I put it in its own project, so other projects could use it.

Here's an example of how it works.  Similar to PHP.  

The <? ?>'s wrap executed code and the <?= ?> wrap automatically printed code.

### Dependencies:

- [lua-ext](https://github.com/thenumbernine/lua-ext)

### Example:

``` Lua
local template = require 'template'
fields = {
	{a = 'int'},
	{b = 'const char*'},
	{c = 'double'},
}
print(template([[
typedef struct {
<? for _,name_ctype in ipairs(fields) do
	local name, ctype = next(name_ctype)
?>	<?=ctype?> <?=name?>;
<? end
?>} S;
]], {
	fields = fields,
}))
```

...produces...

``` C
typedef struct {
	int a;
	const char* b;
	double c;
} S;
```

...which fits perfectly inside a ffi.cdef() call.
