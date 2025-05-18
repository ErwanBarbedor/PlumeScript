return {
    commands = {
        "./plume -s \"\\$print(foo)\""
    },
    expected = {
        output = "foo\nExecuted with sucess."
    }
}