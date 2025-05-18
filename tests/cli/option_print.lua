return {
    commands = {
        "./plume -p -s \"\\$(1+1)\""
    },
    expected = {
        output = "2"
    }
}