return {
    files = {
        ["test.plume"] = [[
            a = $(1+1)
            a is $a.
        ]]
    },
    commands = {
        "./plume test.plume -o output.txt"
    },
    expected = {
        files = {
            ["output.txt"]= "a is 2."
        },
        output = "Output successfully written to 'output.txt'."
    }
}