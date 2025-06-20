return {
    files = {
        ["test.plume"] = [[
Dir\: $_DIR, File\: $_FILE
        ]]
    },
    commands = {
        "./plume test.plume -o output.txt --no-cache"
    },
    expected = {
        files = {
            ["output.txt"]= "Dir: ., File: test.plume"
        },
        output = "Output successfully written to 'output.txt'."
    }
}